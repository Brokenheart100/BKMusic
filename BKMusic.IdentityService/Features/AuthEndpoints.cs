using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using BKMusic.IdentityService.Domain;
using BKMusic.IdentityService.Services;
using BKMusic.Shared.Messaging; // 引用集成事件
using BKMusic.Shared.Results;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Wolverine;

namespace BKMusic.IdentityService.Features;

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth");
        group.MapPost("/register", Register);
        group.MapPost("/login", Login);
        group.MapPost("/refresh", Refresh);
    }

    // DTOs
    public record RegisterRequest(string Email, string Password, string Nickname, string? AvatarUrl);
    public record LoginRequest(string Email, string Password);
    public record AuthResponse(
        string AccessToken,
        string RefreshToken,
        string Nickname,      // 【新增】
        string? AvatarUrl     // 【新增】
    );
    public record RefreshRequest(string AccessToken, string RefreshToken);

    // 1. 注册
    private static async Task<IResult> Register(
        [FromBody] RegisterRequest req,
        UserManager<ApplicationUser> userManager,
        IMessageBus bus)
    {
        var user = new ApplicationUser
        {
            UserName = req.Email,
            Email = req.Email,
            Nickname = req.Nickname,
            AvatarUrl = req.AvatarUrl
        };

        var result = await userManager.CreateAsync(user, req.Password);

        if (!result.Succeeded)
        {
            var errors = string.Join(", ", result.Errors.Select(e => e.Description));
            return Results.BadRequest(Result.Failure(new Error("Auth.RegisterFailed", errors)));
        }

        await bus.PublishAsync(new UserRegisteredEvent(
            Guid.Parse(user.Id),
            user.Email,
            user.Nickname,
            user.AvatarUrl // 【新增】
        ));

        return Results.Ok(Result.Success());
    }

    // 2. 登录
    private static async Task<IResult> Login(
        [FromBody] LoginRequest req,
        UserManager<ApplicationUser> userManager,
        TokenService tokenService)
    {
        var user = await userManager.FindByEmailAsync(req.Email);
        if (user == null || !await userManager.CheckPasswordAsync(user, req.Password))
        {
            return Results.Unauthorized();
        }

        var roles = await userManager.GetRolesAsync(user);
        var accessToken = tokenService.GenerateAccessToken(user, roles);
        var refreshToken = tokenService.GenerateRefreshToken();

        // 保存 Refresh Token 到数据库
        user.RefreshToken = refreshToken;
        user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(7); // 7天有效期
        await userManager.UpdateAsync(user);

        return Results.Ok(Result.Success(new AuthResponse(
            accessToken,
            refreshToken,
            user.Nickname ?? "User", // 处理空值
            user.AvatarUrl
        )));
    }

    // 3. 刷新 Token (轮换机制)
    private static async Task<IResult> Refresh(
        [FromBody] RefreshRequest req,
        UserManager<ApplicationUser> userManager,
        TokenService tokenService)
    {
        // 从旧的 AccessToken 中提取用户信息（即使用户已过期）
        var principal = tokenService.GetPrincipalFromExpiredToken(req.AccessToken);
        var userId = principal.FindFirstValue(JwtRegisteredClaimNames.Sub); // 获取 Sub (UserId)

        if (userId == null) return Results.BadRequest("Invalid token");

        var user = await userManager.FindByIdAsync(userId);
        if (user == null || user.RefreshToken != req.RefreshToken || user.RefreshTokenExpiryTime <= DateTime.UtcNow)
        {
            return Results.BadRequest("Invalid or expired refresh token");
        }

        // 颁发新的一对 Token
        var roles = await userManager.GetRolesAsync(user);
        var newAccessToken = tokenService.GenerateAccessToken(user, roles);
        var newRefreshToken = tokenService.GenerateRefreshToken();

        // 轮换：废弃旧的，保存新的
        user.RefreshToken = newRefreshToken;
        user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(7);
        await userManager.UpdateAsync(user);

        return Results.Ok(Result.Success(new AuthResponse(
            newAccessToken,
            newRefreshToken,
            user.Nickname ?? "User",
            user.AvatarUrl
        )));
    }
}