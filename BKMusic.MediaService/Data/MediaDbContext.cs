using BKMusic.MediaService.Domain;
using Microsoft.EntityFrameworkCore;
using Wolverine.EntityFrameworkCore;

namespace BKMusic.MediaService.Data;
public class MediaDbContext : DbContext
{
    public MediaDbContext(DbContextOptions<MediaDbContext> options) : base(options) { }

    public DbSet<MediaFile> MediaFiles { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        // 配置实体
        modelBuilder.Entity<MediaFile>().HasKey(m => m.Id);
        modelBuilder.Entity<MediaFile>().Property(m => m.Status).HasConversion<string>();
        modelBuilder.MapWolverineEnvelopeStorage();
    }
}