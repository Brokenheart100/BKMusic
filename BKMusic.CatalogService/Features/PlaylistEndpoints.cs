using System.Security.Claims;
using BKMusic.CatalogService.Data;
using BKMusic.CatalogService.Domain;
using BKMusic.Shared.Results;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BKMusic.CatalogService.Features;

public static class PlaylistEndpoints
{
    public static void MapPlaylistEndpoints(this IEndpointRouteBuilder app)
    {
        // 【核心修复】路由前缀必须是 /api/playlists，避免与 /api/songs 冲突
        // RequireAuthorization() 确保所有接口都需要 JWT Token
        var group = app.MapGroup("/api/playlists").RequireAuthorization();

        group.MapPost("/", CreatePlaylist);
        group.MapGet("/", GetMyPlaylists);
        group.MapGet("/{id}", GetPlaylistDetail);
        group.MapPost("/{id}/songs", AddSongToPlaylist);
        group.MapDelete("/{id}/songs/{songId}", RemoveSongFromPlaylist);
    }

    // --- DTOs ---
    public record CreatePlaylistRequest(string Name, string? Description);
    public record PlaylistDto(Guid Id, string Name, string? CoverUrl, int SongCount);
    // 详情页包含歌曲列表
    public record PlaylistDetailDto(Guid Id, string Name, string? Description, List<SongEndpoints.SongDto> Songs);
    public record AddSongRequest(Guid SongId);

    // --- Handlers ---

    // 1. 创建歌单
    private static async Task<IResult> CreatePlaylist(
        [FromBody] CreatePlaylistRequest req,
        ClaimsPrincipal user,
        CatalogDbContext db)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // 创建领域实体
        var playlist = Playlist.Create(req.Name, userId, req.Description);

        db.Playlists.Add(playlist);
        await db.SaveChangesAsync();

        return Results.Ok(Result.Success(playlist.Id));
    }

    // 2. 获取“我”的歌单列表
    private static async Task<IResult> GetMyPlaylists(
        ClaimsPrincipal user,
        CatalogDbContext db,
        IConfiguration config)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var minioHost = config["MinIO:PublicHost"] ?? "http://localhost:9000";

        var playlists = await db.Playlists
            .Where(p => p.UserId == userId)
            .OrderByDescending(p => p.CreatedAt)
            .Select(p => new PlaylistDto(
                p.Id,
                p.Name,
                // 如果歌单没有封面，暂时留空，前端可以用默认图或第一首歌的封面
                !string.IsNullOrEmpty(p.CoverUrl) && !p.CoverUrl.StartsWith("http")
                    ? $"{minioHost}/music-covers/{p.CoverUrl}"
                    : p.CoverUrl,
                p.Items.Count))
            .ToListAsync();

        return Results.Ok(Result.Success(playlists));
    }

    // 3. 往歌单添加歌曲
    private static async Task<IResult> AddSongToPlaylist(
        Guid id,
        [FromBody] AddSongRequest req,
        ClaimsPrincipal user,
        CatalogDbContext db)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // 必须校验 UserId，确保只能修改自己的歌单
        var playlist = await db.Playlists
            .Include(p => p.Items)
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);

        if (playlist == null)
        {
            return Results.NotFound(Result.Failure(new Error("Playlist.NotFound", "Playlist not found or access denied")));
        }

        // 调用领域方法添加（内部会自动去重）
        playlist.AddSong(req.SongId);
        await db.SaveChangesAsync();

        return Results.Ok(Result.Success());
    }

    // 4. 获取歌单详情 (包含歌曲列表)
    private static async Task<IResult> GetPlaylistDetail(
        Guid id,
        CatalogDbContext db,
        IConfiguration config)
    {
        // 这里暂不校验 UserId，允许查看（未来可扩展 Public/Private 属性）
        var playlist = await db.Playlists
            .Include(p => p.Items)
            .ThenInclude(ps => ps.Song) // 级联加载歌曲信息
            .FirstOrDefaultAsync(p => p.Id == id);

        if (playlist == null) return Results.NotFound(Result.Failure(new Error("Playlist.NotFound", "Playlist not found")));

        var minioHost = config["MinIO:PublicHost"] ?? "http://localhost:9000";

        // 转换歌曲列表 DTO
        var songDtos = playlist.Items.Select(item =>
        {
            var s = item.Song;

            // 1. 处理音频 URL (HLS vs Raw)
            var bucket = s.HlsStorageKey?.EndsWith(".m3u8") == true ? "music-hls" : "music-raw";
            var songUrl = $"{minioHost}/{bucket}/{s.HlsStorageKey}";

            // 2. 处理封面 URL
            var fullCoverUrl = !string.IsNullOrEmpty(s.CoverUrl) && !s.CoverUrl.StartsWith("http")
                ? $"{minioHost}/music-covers/{s.CoverUrl}"
                : s.CoverUrl;

            return new SongEndpoints.SongDto(s.Id, s.Title, s.ArtistName, songUrl, fullCoverUrl);
        }).ToList();

        return Results.Ok(Result.Success(new PlaylistDetailDto(
            playlist.Id,
            playlist.Name,
            playlist.Description,
            songDtos
        )));
    }

    // 5. 从歌单移除歌曲
    private static async Task<IResult> RemoveSongFromPlaylist(
        Guid id,      // 歌单ID
        Guid songId,  // 歌曲ID
        ClaimsPrincipal user,
        CatalogDbContext db)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var playlist = await db.Playlists
            .Include(p => p.Items)
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);

        if (playlist == null)
        {
            return Results.NotFound(Result.Failure(new Error("Playlist.NotFound", "Playlist not found or access denied")));
        }

        playlist.RemoveSong(songId);
        await db.SaveChangesAsync();

        return Results.Ok(Result.Success());
    }
}