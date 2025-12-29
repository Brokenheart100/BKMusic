<template>
    <div class="song-container">
        <el-card shadow="never">
            <!-- 1. 操作栏 -->
            <div class="toolbar">
                <h3 class="title">歌曲列表</h3>
                <div class="actions">
                    <el-button :icon="Refresh" circle @click="fetchData" />
                    <el-button type="primary" :icon="Plus" @click="openDialog">发布新歌</el-button>
                </div>
            </div>

            <!-- 2. 数据表格 -->
            <el-table v-loading="listLoading" :data="tableData" border stripe style="width: 100%">
                <el-table-column label="封面" width="80" align="center">
                    <template #default="{ row }">
                        <el-image :src="row.coverUrl" class="cover-img" :preview-src-list="[row.coverUrl]" fit="cover">
                            <template #error>
                                <div class="image-slot"><el-icon>
                                        <Picture />
                                    </el-icon></div>
                            </template>
                        </el-image>
                    </template>
                </el-table-column>
                <el-table-column prop="title" label="歌名" min-width="150" show-overflow-tooltip />
                <el-table-column prop="artist" label="歌手" width="150" show-overflow-tooltip />
                <el-table-column prop="album" label="专辑" width="150" show-overflow-tooltip />
                <el-table-column label="播放地址" min-width="200" show-overflow-tooltip>
                    <template #default="{ row }">
                        <el-link type="primary" :href="row.url" target="_blank" :underline="false">
                            {{ row.url }}
                        </el-link>
                    </template>
                </el-table-column>
                <el-table-column label="状态" width="100" align="center">
                    <template #default>
                        <el-tag type="success" effect="dark">已发布</el-tag>
                    </template>
                </el-table-column>
                <el-table-column label="操作" width="150" align="center">
                    <template #default="{ row }">
                        <el-button type="danger" size="small" :icon="Delete" @click="handleDelete(row)">
                            删除
                        </el-button>
                    </template>
                </el-table-column>
            </el-table>
        </el-card>

        <!-- 3. 上传/新增 弹窗 -->
        <el-dialog v-model="dialogVisible" title="发布新歌" width="500px" :close-on-click-modal="false" @close="resetForm">
            <el-form ref="uploadFormRef" :model="uploadForm" :rules="uploadRules" label-width="80px">
                <el-form-item label="歌名" prop="title">
                    <el-input v-model="uploadForm.title" placeholder="留空则自动从文件读取" />
                </el-form-item>
                <el-form-item label="歌手" prop="artist">
                    <el-input v-model="uploadForm.artist" placeholder="留空则自动从文件读取" />
                </el-form-item>
                <el-form-item label="专辑" prop="album">
                    <el-input v-model="uploadForm.album" placeholder="留空则自动从文件读取" />
                </el-form-item>
                <el-form-item label="封面URL" prop="coverUrl">
                    <el-input v-model="uploadForm.coverUrl" placeholder="留空则自动从文件提取封面" />
                </el-form-item>

                <!-- 音频文件 -->
                <el-form-item label="音频文件" required>
                    <el-upload class="upload-demo" action="#" drag :auto-upload="false" :limit="1"
                        :on-change="handleFileChange" :on-remove="handleFileRemove" accept=".mp3,.flac,.wav">
                        <el-icon class="el-icon--upload">
                            <UploadFilled />
                        </el-icon>
                        <div class="el-upload__text">拖拽文件到此处或 <em>点击选择</em></div>
                    </el-upload>
                </el-form-item>

                <!-- 歌词文件 -->
                <el-form-item label="歌词(.lrc)">
                    <el-upload class="upload-demo" action="#" drag :auto-upload="false" :limit="1"
                        :on-change="handleLyricChange" :on-remove="handleLyricRemove" accept=".lrc,.txt">
                        <el-icon class="el-icon--upload">
                            <Document />
                        </el-icon>
                        <div class="el-upload__text">拖拽 LRC 文件或 <em>点击上传</em></div>
                    </el-upload>
                </el-form-item>
            </el-form>

            <template #footer>
                <span class="dialog-footer">
                    <el-button @click="dialogVisible = false">取消</el-button>
                    <el-button type="primary" :loading="submitLoading" @click="handleUpload">
                        {{ submitLoading ? '上传处理中...' : '开始上传' }}
                    </el-button>
                </span>
            </template>
        </el-dialog>
    </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue';
import { Refresh, Plus, Picture, UploadFilled, Delete, Document } from '@element-plus/icons-vue';
import { ElMessage, type UploadFile, type FormInstance, type FormRules, ElMessageBox } from 'element-plus';
import { getSongs, createSong, deleteSong, updateSongLyric, type SongDto, type CreateSongRequest } from '../../api/catalog';
import { initUpload, uploadToMinio, confirmUpload } from '../../api/media';

// --- 状态定义 ---
const tableData = ref<SongDto[]>([]);
const listLoading = ref(false);
const dialogVisible = ref(false);
const submitLoading = ref(false);
const uploadFormRef = ref<FormInstance>();
const selectedFile = ref<File | null>(null);
const selectedLyricFile = ref<File | null>(null);

const uploadForm = reactive<CreateSongRequest>({
    title: '',
    artist: '',
    album: '',
    coverUrl: ''
});

const uploadRules: FormRules = {};

// --- API 调用 ---
const fetchData = async () => {
    listLoading.value = true;
    try {
        const res = await getSongs();
        if (res.isSuccess && res.value) {
            tableData.value = res.value;
        }
    } catch (error) {
        console.error(error);
    } finally {
        listLoading.value = false;
    }
};

onMounted(fetchData);

// --- 交互逻辑 ---
const openDialog = () => dialogVisible.value = true;

const handleFileChange = (file: UploadFile) => {
    if (file.raw) selectedFile.value = file.raw;
};
const handleFileRemove = () => selectedFile.value = null;

const handleLyricChange = (file: UploadFile) => {
    if (file.raw) selectedLyricFile.value = file.raw;
};
const handleLyricRemove = () => selectedLyricFile.value = null;

const resetForm = () => {
    if (uploadFormRef.value) uploadFormRef.value.resetFields();
    selectedFile.value = null;
    selectedLyricFile.value = null;
};

const handleDelete = (row: SongDto) => {
    ElMessageBox.confirm(
        `确定要删除 "${row.title}" 吗？此操作不可恢复。`,
        '警告',
        { confirmButtonText: '删除', cancelButtonText: '取消', type: 'warning' }
    ).then(async () => {
        const res = await deleteSong(row.id);
        if (res.isSuccess) {
            ElMessage.success('删除成功');
            fetchData();
        }
    });
};

// 【核心：歌词上传流程】
const processLyricUpload = async (songId: string, file: File) => {
    const contentType = 'text/plain'; // 强制指定类型

    // 1. 申请链接 (category='lyrics')
    const initRes = await initUpload({
        songId: songId, // 这里可以传 songId，也可以为 null，看后端实现，通常 lyrics 需要关联
        fileName: file.name,
        contentType: contentType,
        category: 'lyrics'
    });

    if (!initRes.isSuccess || !initRes.value) throw new Error("歌词 Init 失败");
    const { uploadUrl, uploadId, key } = initRes.value;

    // 2. 物理上传
    await uploadToMinio(uploadUrl, file, contentType);

    // 3. 确认上传 (Media Service)
    await confirmUpload(uploadId);

    // 4. 关联到歌曲 (Catalog Service)
    await updateSongLyric(songId, key);
};

// 【核心：主上传流程】
const handleUpload = async () => {
    if (!uploadFormRef.value) return;
    if (!selectedFile.value) return ElMessage.warning('请选择音频文件');

    await uploadFormRef.value.validate(async (valid) => {
        if (valid) {
            submitLoading.value = true;
            try {
                // 1. 创建元数据
                const metaRes = await createSong(uploadForm);
                if (!metaRes.isSuccess || !metaRes.value) throw new Error('元数据创建失败');
                const songId = metaRes.value;

                // 2. 音频上传流程
                const audioContentType = selectedFile.value!.type || 'application/octet-stream';

                const audioInitRes = await initUpload({
                    songId: songId,
                    fileName: selectedFile.value!.name,
                    contentType: audioContentType
                });

                if (!audioInitRes.isSuccess || !audioInitRes.value) throw new Error('音频 Init 失败');

                // 【修复】传递 contentType
                await uploadToMinio(audioInitRes.value.uploadUrl, selectedFile.value!, audioContentType);
                await confirmUpload(audioInitRes.value.uploadId);

                // 3. 歌词上传流程 (可选)
                if (selectedLyricFile.value) {
                    try {
                        await processLyricUpload(songId, selectedLyricFile.value!);
                        console.log("歌词上传成功");
                    } catch (lyricErr) {
                        console.error("歌词上传失败:", lyricErr);
                        ElMessage.warning('音频成功，但歌词上传失败');
                    }
                }

                ElMessage.success('发布成功！');
                dialogVisible.value = false;
                setTimeout(fetchData, 1000);

            } catch (error: any) {
                console.error(error);
                ElMessage.error(error.message || '上传失败');
            } finally {
                submitLoading.value = false;
            }
        }
    });
};
</script>

<style scoped>
.toolbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
}

.title {
    margin: 0;
    font-size: 18px;
    border-left: 4px solid #409eff;
    padding-left: 10px;
}

.cover-img {
    width: 50px;
    height: 50px;
    border-radius: 4px;
    background: #f5f7fa;
}
</style>