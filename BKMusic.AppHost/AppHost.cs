using Aspire.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

// ==========================================
// 1. 基础设施层 (Infrastructure)
// ==========================================

// --- Redis ---
var redis = builder.AddRedis("redis")
    .WithDataVolume()
    .WithRedisCommander();

// --- RabbitMQ ---
var rabbitmq = builder.AddRabbitMQ("messaging")
    .WithDataVolume()
    .WithManagementPlugin();



var typesenseApiKey = "xyz"; // 生产环境请使用 Secret
var typesense = builder.AddContainer("typesense", "typesense/typesense:29.0")
    .WithArgs("--data-dir", "/data", "--api-key","xyz" ,"--enable-cors")
    .WithHttpEndpoint(port: 8108, targetPort: 8108, name: "typesense")
    .WithHttpHealthCheck("/health", statusCode: 200, endpointName: "typesense")
    .WithVolume("typesense-data", "/data");


// --- PostgreSQL ---
var postgres = builder.AddPostgres("postgres")
    //.WithEndpoint(port: 55000, targetPort: 5432, name: "datagrip", isExternal:true,scheme:"http")
    .WithDataVolume("pgsql_data")
    .WithPgAdmin();

var catalogDb = postgres.AddDatabase("catalog-db");
var mediaDb = postgres.AddDatabase("media-db");
var identityDb = postgres.AddDatabase("identity-db");

// --- MinIO ---
var minioUser = builder.AddParameter("minio-user", "minioadmin");
var minioPass = builder.AddParameter("minio-pass", "minioadmin");

var minio = builder.AddContainer("minio", "minio/minio")
    .WithArgs("server", "/data", "--console-address", ":9001")
    .WithEnvironment("MINIO_ROOT_USER", minioUser)
    .WithEnvironment("MINIO_ROOT_PASSWORD", minioPass)
    .WithHttpEndpoint(port: 9000, targetPort: 9000, name: "api")
    .WithHttpEndpoint(port: 9001, targetPort: 9001, name: "console")
    .WithVolume("minio-data", "/data");

// ==========================================
// 2. 微服务层 (Microservices)
// ==========================================

var jwtKey = builder.Configuration["Jwt:Key"] ?? "SuperSecretKey1234567890_MustBeLongEnough";
var jwtIssuer = "BKMusic_Identity";
var jwtAudience = "BKMusic_Client";

// --- Identity Service ---
var identitySvc = builder.AddProject<Projects.BKMusic_IdentityService>("identity-svc")
    .WithReference(identityDb)
    .WithReference(rabbitmq)
    .WithEnvironment("Jwt__Key", jwtKey)
    .WithEnvironment("Jwt__Issuer", jwtIssuer)
    .WithEnvironment("Jwt__Audience", jwtAudience)
    .WaitFor(rabbitmq)    // 等待 MQ
    .WaitFor(identityDb); // 等待 DB



var minioApiEndpoint = minio.GetEndpoint("api");
// --- Media Service (合并修复版) ---
var mediaSvc = builder.AddProject<Projects.BKMusic_MediaService>("media-svc")
    .WithReference(mediaDb)
    .WithReference(rabbitmq)
    .WithReference(minioApiEndpoint)
    .WithEnvironment("ConnectionStrings:minio", minioApiEndpoint)
    .WithEnvironment("Jwt__Key", jwtKey)
    .WithEnvironment("Jwt__Issuer", jwtIssuer)
    .WithEnvironment("Jwt__Audience", jwtAudience)
    .WaitFor(rabbitmq)
    .WaitFor(mediaDb);

// --- Catalog Service ---
var catalogSvc = builder.AddProject<Projects.BKMusic_CatalogService>("catalog-svc")
    .WithReference(catalogDb)
    .WithReference(rabbitmq)
    .WithReference(redis)
    .WithEnvironment("MinIO__PublicHost", "http://localhost:9000")
    .WithEnvironment("Jwt__Key", jwtKey)
    .WithEnvironment("Jwt__Issuer", jwtIssuer)
    .WithEnvironment("Jwt__Audience", jwtAudience)
    .WaitFor(rabbitmq)
    .WaitFor(catalogDb)
    .WaitFor(redis);

// --- Transcoding Worker ---
//var worker = builder.AddProject<Projects.BKMusic_TranscodingWorker>("transcoding-worker")
//   .WithReference(rabbitmq)
//   .WithEnvironment("ConnectionStrings:minio", minio.GetEndpoint("api"))
//   .WaitFor(rabbitmq);


builder.AddDockerfile("transcoding-worker", "..", "BKMusic.TranscodingWorker/Dockerfile")
     .WithReference(rabbitmq)
     .WithEnvironment("ConnectionStrings:minio", minioApiEndpoint)
     //.WithVolume("worker")
     .WaitFor(rabbitmq);

// ==========================================
// 3. 网关层 (Gateway)
// ==========================================





var searchSvc = builder.AddProject<Projects.BKMusic_SearchService>("search-svc")
    .WithReference(rabbitmq)
    .WithReference(typesense.GetEndpoint("typesense"))
    .WithEnvironment("Typesense__ApiKey", typesenseApiKey)
    .WaitFor(typesense)
    .WaitFor(rabbitmq);


var gateway = builder.AddProject<Projects.BKMusic_Gateway>("gateway")
    .WithReference(identitySvc)
    .WithReference(mediaSvc)
    .WithReference(catalogSvc)
    .WithReference(searchSvc)
    .WithExternalHttpEndpoints();


builder.Build().Run();