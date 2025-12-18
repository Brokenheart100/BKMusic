using BKMusic.SearchService.Dtos;
using Typesense;
using Typesense.Setup;
using Wolverine;
using Wolverine.RabbitMQ;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

var typesenseUrl = builder.Configuration.GetConnectionString("typesense") ?? "http://localhost:8108";
//1.配置 Typesense
builder.Services.AddTypesenseClient(config =>
 {
     config.ApiKey = builder.Configuration["Typesense:ApiKey"];
     if (string.IsNullOrEmpty(config.ApiKey))
     {
         throw new InvalidOperationException("Typesense API Key is missing. Check AppHost configuration.");
     }
     var uri = new Uri(typesenseUrl);
     config.Nodes = new List<Node> { new Node(uri.Host, uri.Port.ToString(), "http") };
 });

// 2. Wolverine
builder.Host.UseWolverine(opts =>
{
    var rabbitConn = builder.Configuration.GetConnectionString("messaging");
    opts.UseRabbitMq(rabbitConn).AutoProvision().UseConventionalRouting();
    // 扫描 Handlers
    opts.Discovery.IncludeAssembly(typeof(Program).Assembly);
});

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

app.MapDefaultEndpoints();
// 3. 初始化 Schema (建表)
// 实际生产中应放在 Worker 或 Migration 中，这里简化放在启动时
using (var scope = app.Services.CreateScope())
{
    var client = scope.ServiceProvider.GetRequiredService<ITypesenseClient>();
    try
    {
        await client.RetrieveCollection("songs");
    }
    catch
    {
        var schema = new Schema(
            "songs",
            new List<Field>
            {
                new Field("id", FieldType.String, false),
                new Field("title", FieldType.String, true), // facet=true 用于聚合
                new Field("artist", FieldType.String, true),
                new Field("album", FieldType.String, true),
                new Field("coverUrl", FieldType.String, false),
                new Field("url", FieldType.String, false)
            }
            //"title" // 默认排序字段
        );
        await client.CreateCollection(schema);
    }
}

// 4. 注册搜索 API
app.MapGet("/api/search", async (string q, ITypesenseClient client) =>
{
    var query = new SearchParameters(q, "title,artist,album");
    var result = await client.Search<SongIndex>("songs", query);
    // 转换为前端统一格式
    return Results.Ok(new { IsSuccess = true, Value = result.Hits.Select(h => h.Document) });
});

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
