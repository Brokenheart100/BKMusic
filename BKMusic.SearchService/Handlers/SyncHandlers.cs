using BKMusic.Shared.Messaging;
using Typesense;
using Wolverine;
using Wolverine.Attributes;

namespace BKMusic.SearchService.Handlers; // 注意命名空间是 SearchService

// 1. 确保定义了 SongIndex (文档结构)
public record SongIndex(string Id, string Title, string Artist, string Album, string CoverUrl, string Url);

[WolverineHandler]
public class SyncHandlers
{
    private readonly ITypesenseClient _client;

    public SyncHandlers(ITypesenseClient client)
    {
        _client = client;
    }

    // 新增/更新索引
    public async Task Handle(MediaProcessedEvent @event)
    {
        var doc = new SongIndex(
            @event.SongId.ToString(),
            @event.Title ?? "Unknown",
            @event.Artist ?? "Unknown",
            @event.Album ?? "Unknown",
            @event.CoverStorageKey ?? "", // 这里简化处理，实际可能需要拼完整URL
            @event.HlsUrl
        );

        // 使用 Upsert (不存在则创建，存在则更新)
        await _client.UpsertDocument<SongIndex>("songs", doc);
    }

    // 删除索引
    public async Task Handle(SongDeletedEvent @event)
    {
        // 【核心修复】这里必须加 <SongIndex>
        await _client.DeleteDocument<SongIndex>("songs", @event.SongId.ToString());
    }
}