using BKMusic.CatalogService.Domain;
using Microsoft.EntityFrameworkCore;

namespace BKMusic.CatalogService.Data;

public class CatalogDbContext : DbContext
{
    public CatalogDbContext(DbContextOptions<CatalogDbContext> options) : base(options) { }

    public DbSet<Song> Songs { get; set; }
    public DbSet<Playlist> Playlists { get; set; }
    public DbSet<PlaylistSong> PlaylistSongs { get; set; }
    public DbSet<UserFavorite> Favorites { get; set; }
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.Entity<Song>().HasKey(x => x.Id);
        modelBuilder.Entity<PlaylistSong>()
            .HasKey(ps => new { ps.PlaylistId, ps.SongId });

        // 配置关系
        modelBuilder.Entity<Playlist>()
            .HasMany(p => p.Items)
            .WithOne()
            .HasForeignKey(ps => ps.PlaylistId)
            .OnDelete(DeleteBehavior.Cascade); // 删歌单，关联记录也删

        modelBuilder.Entity<UserFavorite>()
            .HasKey(f => new { f.UserId, f.SongId }); // 联合主键

        modelBuilder.Entity<UserFavorite>()
            .HasOne(f => f.Song)
            .WithMany()
            .HasForeignKey(f => f.SongId);
    }
}