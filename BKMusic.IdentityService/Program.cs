using BKMusic.IdentityService.Data;
using BKMusic.IdentityService.Domain;
using BKMusic.IdentityService.Features;
using BKMusic.IdentityService.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Wolverine;
using Wolverine.RabbitMQ;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

// 1. 数据库
builder.AddNpgsqlDbContext<AppIdentityDbContext>("identity-db");

// 2. 配置 ASP.NET Core Identity
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
    {
        options.Password.RequireDigit = false;
        options.Password.RequireLowercase = false;
        options.Password.RequireNonAlphanumeric = false;
        options.Password.RequireUppercase = false;
        options.Password.RequiredLength = 6; // 开发环境设简单点
        options.User.RequireUniqueEmail = true;
    })
    .AddEntityFrameworkStores<AppIdentityDbContext>()
    .AddDefaultTokenProviders();

// 3. 注册 Token 服务
builder.Services.AddScoped<TokenService>();

// 4. 配置 JWT 验证 (为了将来可能的自身验证需求)
builder.Services.AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
        };
    });

// 5. Wolverine (仅发送消息，不做 Outbox 复杂配置以简化 Identity 集成)
builder.Host.UseWolverine(opts =>
{
    var rabbitConn = builder.Configuration.GetConnectionString("messaging");
    opts.UseRabbitMq(rabbitConn)
        .AutoProvision()
        .UseConventionalRouting();
});

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

app.MapDefaultEndpoints();


// 6. 自动迁移数据库 (Identity 的表很多)
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppIdentityDbContext>();
    db.Database.EnsureCreated(); // 这会创建 AspNetUsers 等表
    //db.Database.Migrate(); // <--- 就是这行代码
}


// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

// 【新增】必须在 Authorization 之前！
// 否则系统只知道鉴权规则，却不知道你是谁（没解析 Token）
app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();
app.MapAuthEndpoints(); // 这行位置是对的


app.Run();
