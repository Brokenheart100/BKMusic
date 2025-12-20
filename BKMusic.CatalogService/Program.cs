using System.Text;
using BKMusic.CatalogService.Data;
using BKMusic.CatalogService.Features;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using Wolverine;
using Wolverine.RabbitMQ;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

// 1. 数据库
builder.AddNpgsqlDbContext<CatalogDbContext>("catalog-db");

// 2. Redis 缓存 (Aspire)
builder.AddRedisOutputCache("cache");

// 3. Wolverine (RabbitMQ)
builder.Host.UseWolverine(opts =>
{
    var rabbitConn = builder.Configuration.GetConnectionString("messaging");
    opts.UseRabbitMq(rabbitConn)
        .AutoProvision()
        .UseConventionalRouting();

});

builder.Services.AddControllers();
builder.Services.AddOpenApi();


builder.Services.AddEndpointsApiExplorer();

// 5. 注册 Swagger 生成器
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "BKMusic Catalog Service API",
        Version = "v1",
        Description = "负责管理歌曲元数据和查询"
    });
});



builder.Services.AddAuthentication(options =>
    {
        // 1. 设置默认验证方案为 JWT
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        // 2. 设置默认挑战方案为 JWT (处理 401)
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
            // 必须确保 Catalog Service 能读取到这个 Key (从 AppHost 注入)
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();

app.MapDefaultEndpoints();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwagger();
    // 启用 Swagger UI 网页
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Catalog Service v1");
        // 设置为空，这样直接访问根路径 http://localhost:xxxx/ 就能看到 Swagger
        // c.RoutePrefix = string.Empty; 
    });
}
// 4. 确保建表
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<CatalogDbContext>();
    //db.Database.EnsureCreated();
    db.Database.Migrate();
}

// 5. 注册路由
app.MapSongEndpoints();
app.MapPlaylistEndpoints();
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapFavoriteEndpoints();

app.MapControllers();

app.Run();
