using BKMusic.Shared.Domain;

namespace BKMusic.CatalogService.Domain;

// 关联表：用户ID - 歌曲ID
public class UserFavorite
{
    public Guid UserId { get; private set; }
    public Guid SongId { get; private set; }
    public DateTime LikedAt { get; private set; }

    // 导航属性
    public Song Song { get; private set; } = null!;

    public UserFavorite(Guid userId, Guid songId)
    {
        UserId = userId;
        SongId = songId;
        LikedAt = DateTime.UtcNow;
    }
}