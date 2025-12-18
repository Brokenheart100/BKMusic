using System.Security.Claims;
using BKMusic.CatalogService.Data;
using BKMusic.CatalogService.Domain;
using BKMusic.Shared.Messaging;
using BKMusic.Shared.Results;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.OutputCaching;
using Microsoft.EntityFrameworkCore;
using Wolverine;

namespace BKMusic.CatalogService.Features;

public static class SongEndpoints
{
    public static void MapSongEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/songs");

        // 1. 创建歌曲
        group.MapPost("/", CreateSong);

        // 2. 获取歌曲列表 (允许匿名)
        group.MapGet("/", GetSongs)
            .CacheOutput(x => x.Expire(TimeSpan.FromMinutes(1)).Tag("songs"))
            .AllowAnonymous();

        // 3. 获取单曲详情 (允许匿名)
        group.MapGet("/{id}", GetSongDetail)
            .AllowAnonymous();

        group.MapDelete("/{id}", DeleteSong);
    }
    public record CreatePlaylistRequest(string Name, string? Description);
    public record PlaylistDto(Guid Id, string Name, string? CoverUrl, int SongCount);
    public record PlaylistDetailDto(Guid Id, string Name, List<SongEndpoints.SongDto> Songs);
    public record AddSongRequest(Guid SongId);

    private static async Task<IResult> RemoveSongFromPlaylist(
        Guid id,
        Guid songId,
        ClaimsPrincipal user,
        CatalogDbContext db)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var playlist = await db.Playlists
            .Include(p => p.Items)
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);

        if (playlist == null) return Results.NotFound(Result.Failure(new Error("Playlist.NotFound", "Playlist not found")));

        playlist.RemoveSong(songId);
        await db.SaveChangesAsync();
        return Results.Ok(Result.Success());
    }

    private static async Task<IResult> CreatePlaylist(
       [FromBody] CreatePlaylistRequest req,
       ClaimsPrincipal user, // 从 Token 自动解析
       CatalogDbContext db)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var playlist = Playlist.Create(req.Name, userId, req.Description);

        db.Playlists.Add(playlist);
        await db.SaveChangesAsync();

        return Results.Ok(Result.Success(playlist.Id));
    }

    // 2. 获取我的歌单列表
    private static async Task<IResult> GetMyPlaylists(
        ClaimsPrincipal user,
        CatalogDbContext db)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var playlists = await db.Playlists
            .Where(p => p.UserId == userId)
            .Select(p => new PlaylistDto(p.Id, p.Name, p.CoverUrl, p.Items.Count))
            .ToListAsync();

        return Results.Ok(Result.Success(playlists));
    }

    // 3. 往歌单加歌
    private static async Task<IResult> AddSongToPlaylist(
        Guid id,
        [FromBody] AddSongRequest req,
        ClaimsPrincipal user,
        CatalogDbContext db)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // 必须查 UserId，确保是自己的歌单
        var playlist = await db.Playlists
            .Include(p => p.Items)
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);

        if (playlist == null) return Results.NotFound(Result.Failure(new Error("Playlist.NotFound", "Playlist not found")));

        playlist.AddSong(req.SongId);
        await db.SaveChangesAsync();

        return Results.Ok(Result.Success());
    }

    // 4. 获取详情 (包含歌曲)
    private static async Task<IResult> GetPlaylistDetail(
        Guid id,
        CatalogDbContext db,
        IConfiguration config)
    {
        // 详情页暂不校验 UserId，允许看别人的公开歌单（未来可加 IsPublic）
        var playlist = await db.Playlists
            .Include(p => p.Items)
            .ThenInclude(ps => ps.Song) // 级联加载 Song
            .FirstOrDefaultAsync(p => p.Id == id);

        if (playlist == null) return Results.NotFound();

        var minioHost = config["MinIO:PublicHost"] ?? "http://localhost:9000";

        var songDtos = playlist.Items.Select(item => {
            var s = item.Song;
            // 复用之前的 URL 拼接逻辑 (建议提取为扩展方法)
            var bucket = s.HlsStorageKey?.EndsWith(".m3u8") == true ? "music-hls" : "music-raw";
            var url = $"{minioHost}/{bucket}/{s.HlsStorageKey}";
            return new SongEndpoints.SongDto(s.Id, s.Title, s.ArtistName, url, s.CoverUrl);
        }).ToList();

        return Results.Ok(Result.Success(new PlaylistDetailDto(playlist.Id, playlist.Name, songDtos)));
    }

    // DTOs
    public record CreateSongRequest(string Title, string Artist, string Album, string? CoverUrl);
    public record SongDto(Guid Id, string Title, string Artist, string Url, string? CoverUrl);

    // --- Handlers ---

    private static async Task<IResult> DeleteSong(
        Guid id,
        CatalogDbContext db,
        IMessageBus bus, // 注入 Wolverine
        ILogger<Program> logger)
    {
        var song = await db.Songs.FindAsync(id);
        if (song == null)
        {
            return Results.NotFound(Result.Failure(new Error("Song.NotFound", "Song not found")));
        }

        // 1. 从数据库移除
        db.Songs.Remove(song);

        // 2. 发布删除事件 (Outbox 模式保证事务一致性)
        await bus.PublishAsync(new SongDeletedEvent(id));

        // 3. 提交事务
        await db.SaveChangesAsync();

        logger.LogInformation("Deleted song metadata: {SongId}", id);

        return Results.Ok(Result.Success());
    }

    private static async Task<IResult> CreateSong(
        [FromBody] CreateSongRequest req,
        CatalogDbContext db,
        // 【注入 Logger】泛型参数通常是当前类或功能名称
        ILogger<Program> logger)
    {
        // 2. 记录日志 (支持结构化参数)
        logger.LogInformation("正在创建歌曲: {Title} - {Artist}", req.Title, req.Artist);

        var song = Song.Create(req.Title, req.Artist, req.Album, req.CoverUrl);
        db.Songs.Add(song);
        await db.SaveChangesAsync();

        logger.LogInformation("歌曲创建成功，ID: {SongId}", song.Id);

        return Results.Ok(Result.Success(song.Id));
    }

    private static async Task<IResult> GetSongs(CatalogDbContext db, IConfiguration config)
    {
        var songs = await db.Songs
            .Where(s => s.Status == SongStatus.Ready)
            .OrderByDescending(s => s.Id)
            .ToListAsync();

        var minioHost = config["MinIO:PublicHost"] ?? "http://localhost:9000";

        // 【修正点 1】将 URL 处理逻辑放入 Select 内部
        var dtos = songs.Select(s =>
        {
            // 拼接封面图地址：如果是 http 开头则不变，否则拼上 MinIO 地址
            var fullCoverUrl = !string.IsNullOrEmpty(s.CoverUrl) && !s.CoverUrl.StartsWith("http")
                ? $"{minioHost}/music-covers/{s.CoverUrl}"
                : s.CoverUrl;

            var bucketName = s.HlsStorageKey!.EndsWith(".m3u8", StringComparison.OrdinalIgnoreCase)
                ? "music-hls"
                : "music-raw";

            var songUrl = $"{minioHost}/{bucketName}/{s.HlsStorageKey}";


            return new SongDto(
                s.Id,
                s.Title,
                s.ArtistName,
                  //$"{minioHost}/music-hls/{s.HlsStorageKey}", // 拼接音频 HLS 地址
                songUrl,
                fullCoverUrl // 使用处理后的封面地址
            );
        });

        return Results.Ok(Result.Success(dtos));
    }

    private static async Task<IResult> GetSongDetail(Guid id, CatalogDbContext db, IConfiguration config)
    {
        var song = await db.Songs.FindAsync(id);
        if (song is null || song.Status != SongStatus.Ready)
            return Results.NotFound(Result.Failure(new Error("Song.NotFound", "Song not found or not ready")));

        var minioHost = config["MinIO:PublicHost"] ?? "http://localhost:9000";
        var hlsUrl = $"{minioHost}/music-hls/{song.HlsStorageKey}";

        // 【修正点 2】单曲详情也要处理封面 URL
        var fullCoverUrl = !string.IsNullOrEmpty(song.CoverUrl) && !song.CoverUrl.StartsWith("http")
            ? $"{minioHost}/music-covers/{song.CoverUrl}"
            : song.CoverUrl;

        var bucketName = song.HlsStorageKey!.EndsWith(".m3u8", StringComparison.OrdinalIgnoreCase)
            ? "music-hls"
            : "music-raw";

        var songUrl = $"{minioHost}/{bucketName}/{song.HlsStorageKey}";

        return Results.Ok(Result.Success(new SongDto(
            song.Id,
            song.Title,
            song.ArtistName,
            //hlsUrl,
            songUrl,
            fullCoverUrl // 使用处理后的封面地址
        )));
    }
}