using BKMusic.IdentityService.Domain;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace BKMusic.IdentityService.Data;

// 继承自 IdentityDbContext 这里的泛型是 ApplicationUser
public class AppIdentityDbContext : IdentityDbContext<ApplicationUser>
{
    public AppIdentityDbContext(DbContextOptions<AppIdentityDbContext> options) : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
        // 这里可以自定义表名，默认是 AspNetUsers 等
    }
}