using System.Text;
using CliWrap;

namespace BKMusic.TranscodingWorker.Services;

public interface IFfmpegService
{
    /// <summary>
    /// 将输入的音频文件转码为 HLS 格式。
    /// </summary>
    /// <param name="inputFile">输入文件路径。</param>
    /// <param name="outputDir">HLS 文件输出目录。</param>
    /// <returns>成功返回 true，失败返回 false。</returns>
    Task<bool> ConvertToHlsAsync(string inputFile, string outputDir);
}

public class FfmpegService : IFfmpegService
{
    private readonly ILogger<FfmpegService> _logger;
    private readonly IConfiguration _configuration;

    public FfmpegService(ILogger<FfmpegService> logger, IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
    }

    public async Task<bool> ConvertToHlsAsync(string inputFile, string outputDir)
    {
        Directory.CreateDirectory(outputDir);

        // m3u8 索引文件路径
        var outputPath = Path.Combine(outputDir, "index.m3u8");
        // ts 切片文件命名规则 (例如: seg_001.ts, seg_002.ts)
        var segmentPath = Path.Combine(outputDir, "seg_%03d.ts");

        // 从配置读取设置，如果没有则使用默认的高音质参数
        var ffmpegPath = _configuration["Ffmpeg:Path"] ?? "ffmpeg";
        var bitrate = _configuration["Ffmpeg:HlsBitrate"] ?? "192k"; // 192k 对 AAC 来说是透明音质

        var stdErrBuffer = new StringBuilder();

        var command = Cli.Wrap(ffmpegPath)
            .WithArguments(args => args
                // --- 输入 ---
                .Add("-i").Add(inputFile)
                .Add("-y") // 覆盖输出

                // --- 音频编码参数 (针对内置 aac 的优化) ---
                .Add("-c:a").Add("aac")           // 使用内置 AAC 编码器
                .Add("-b:a").Add(bitrate)         // 码率
                .Add("-ar").Add("44100")          // 采样率 44.1kHz (标准)
                .Add("-ac").Add("2")              // 双声道立体声
                .Add("-aac_coder").Add("twoloop") // 【关键】启用高质量编码算法
                .Add("-profile:a").Add("aac_low") // LC-AAC 兼容性最好

                // --- 映射设置 ---
                .Add("-map").Add("0:a")           // 仅提取音频流

                // --- HLS 切片参数 (企业级优化) ---
                .Add("-f").Add("hls")                         // 输出格式 HLS
                .Add("-hls_time").Add("10")                   // 每个切片约 10 秒
                .Add("-hls_list_size").Add("0")               // 0 表示保留所有切片（VOD点播模式），非直播
                .Add("-hls_segment_type").Add("mpegts")       // 使用标准的 MPEG-TS 容器
                .Add("-hls_flags").Add("independent_segments")// 【关键】每个切片可独立解码，极大提升 Seek 速度
                .Add("-hls_segment_filename").Add(segmentPath)// 规范切片文件名

                // --- 输出 ---
                .Add(outputPath))
            .WithValidation(CommandResultValidation.None)
            .WithStandardErrorPipe(PipeTarget.ToStringBuilder(stdErrBuffer));

        _logger.LogInformation("  🎞️ [Worker] 执行 FFmpeg 命令: {Command}", command.ToString());

        try
        {
            var result = await command.ExecuteAsync();

            if (result.ExitCode != 0)
            {
                // 【核心】如果失败，打印 FFmpeg 的详细错误日志
                _logger.LogError(
                    "  ❌ [Worker] FFmpeg failed with exit code {ExitCode}.\nError Output:\n{StdErr}",
                    result.ExitCode,
                    stdErrBuffer.ToString()
                );
                return false;
            }

            _logger.LogInformation("  🎞️ [Worker] FFmpeg executed successfully.");
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "  ❌ [Worker] An exception occurred while executing FFmpeg.");
            return false;
        }
    }
}