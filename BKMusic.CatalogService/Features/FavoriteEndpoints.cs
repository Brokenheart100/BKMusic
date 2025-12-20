using System.Security.Claims;
using BKMusic.CatalogService.Data;
using BKMusic.CatalogService.Domain;
using BKMusic.Shared.Results;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BKMusic.CatalogService.Features;

public static class FavoriteEndpoints
{
    public static void MapFavoriteEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/favorites").RequireAuthorization();

        // 1. 获取我的收藏列表
        group.MapGet("/", GetMyFavorites);

        // 2. 切换收藏状态 (点赞/取消)
        group.MapPost("/{songId}/toggle", ToggleFavorite);

        // 3. 获取我收藏的所有歌曲ID (用于前端快速判断是否红心)
        group.MapGet("/ids", GetMyFavoriteIds);
    }

    // 【核心修复】补全了方法的返回值
    private static async Task<IResult> GetMyFavorites(
        ClaimsPrincipal user,
        CatalogDbContext db,
        IConfiguration config)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var minioHost = config["MinIO:PublicHost"] ?? "http://localhost:9000";

        // 1. 查询数据库
        var songs = await db.Favorites
            .Where(f => f.UserId == userId)
            .Include(f => f.Song)
            .OrderByDescending(f => f.LikedAt)
            .Select(f => f.Song)
            .ToListAsync();

        // 2. 转换为 DTO (处理播放地址和封面地址)
        var dtos = songs.Select(s =>
        {
            // 处理音频 URL
            var bucket = s.HlsStorageKey?.EndsWith(".m3u8") == true ? "music-hls" : "music-raw";
            var url = $"{minioHost}/{bucket}/{s.HlsStorageKey}";

            // 处理封面 URL
            var fullCoverUrl = !string.IsNullOrEmpty(s.CoverUrl) && !s.CoverUrl.StartsWith("http")
                ? $"{minioHost}/music-covers/{s.CoverUrl}"
                : s.CoverUrl;

            return new SongEndpoints.SongDto(s.Id, s.Title, s.ArtistName, url, fullCoverUrl);
        }).ToList();

        // 3. 【修复 CS0161】必须返回结果
        return Results.Ok(Result.Success(dtos));
    }

    private static async Task<IResult> ToggleFavorite(
        Guid songId, ClaimsPrincipal user, CatalogDbContext db)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var existing = await db.Favorites.FindAsync(userId, songId);
        bool isLiked;

        if (existing != null)
        {
            db.Favorites.Remove(existing);
            isLiked = false;
        }
        else
        {
            // 确保歌曲存在才收藏
            var songExists = await db.Songs.AnyAsync(s => s.Id == songId);
            if (!songExists) return Results.NotFound(Result.Failure(new Error("Song.NotFound", "Song not found")));

            db.Favorites.Add(new UserFavorite(userId, songId));
            isLiked = true;
        }

        await db.SaveChangesAsync();
        return Results.Ok(Result.Success(isLiked));
    }

    private static async Task<IResult> GetMyFavoriteIds(ClaimsPrincipal user, CatalogDbContext db)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var ids = await db.Favorites.Where(f => f.UserId == userId).Select(f => f.SongId).ToListAsync();
        return Results.Ok(Result.Success(ids));
    }
}