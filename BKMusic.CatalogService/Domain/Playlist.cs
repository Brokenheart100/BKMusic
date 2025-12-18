using BKMusic.Shared.Domain;

namespace BKMusic.CatalogService.Domain;

public class Playlist : Entity<Guid>
{
    public string Name { get; private set; }
    public string? Description { get; private set; }
    public string? CoverUrl { get; private set; }

    // 关键：所属用户 ID (从 Token 获取)
    public Guid UserId { get; private set; }

    public DateTime CreatedAt { get; private set; }

    // 导航属性：歌单里有哪些歌
    public List<PlaylistSong> Items { get; private set; } = new();

    private Playlist(Guid id) : base(id) { }

    public static Playlist Create(string name, Guid userId, string? description = null, string? coverUrl = null)
    {
        return new Playlist(Guid.NewGuid())
        {
            Name = name,
            UserId = userId,
            Description = description,
            CoverUrl = coverUrl,
            CreatedAt = DateTime.UtcNow
        };
    }

    public void AddSong(Guid songId)
    {
        if (Items.Any(x => x.SongId == songId)) return; // 防止重复
        Items.Add(new PlaylistSong(Id, songId));
    }

    public void RemoveSong(Guid songId)
    {
        var item = Items.FirstOrDefault(x => x.SongId == songId);
        if (item != null) Items.Remove(item);
    }
}

// 关联实体 (多对多拆解)
public class PlaylistSong
{
    public Guid PlaylistId { get; private set; }
    public Guid SongId { get; private set; }

    // 导航属性 (用于 Include 查询)
    public Song Song { get; set; } = null!;
    public DateTime AddedAt { get; private set; }

    public PlaylistSong(Guid playlistId, Guid songId)
    {
        PlaylistId = playlistId;
        SongId = songId;
        AddedAt = DateTime.UtcNow;
    }
}