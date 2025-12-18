using Microsoft.AspNetCore.Identity;

namespace BKMusic.IdentityService.Domain;

public class ApplicationUser : IdentityUser
{
    public string? Nickname { get; set; }
    public string? AvatarUrl { get; set; }
    public string? RefreshToken { get; set; }
    public DateTime RefreshTokenExpiryTime { get; set; }
}