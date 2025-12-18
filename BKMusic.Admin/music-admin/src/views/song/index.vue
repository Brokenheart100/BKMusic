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
                <!-- 在 el-table 内部添加一列 -->
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
                <!-- 歌名 -->
                <el-form-item label="歌名" prop="title">
                    <el-input v-model="uploadForm.title" placeholder="留空则自动从文件读取" />
                </el-form-item>

                <!-- 歌手 -->
                <el-form-item label="歌手" prop="artist">
                    <el-input v-model="uploadForm.artist" placeholder="留空则自动从文件读取" />
                </el-form-item>

                <!-- 专辑 -->
                <el-form-item label="专辑" prop="album">
                    <el-input v-model="uploadForm.album" placeholder="留空则自动从文件读取" />
                </el-form-item>

                <!-- 封面 -->
                <el-form-item label="封面URL" prop="coverUrl">
                    <el-input v-model="uploadForm.coverUrl" placeholder="留空则自动从文件提取封面" />
                </el-form-item>

                <!-- 核心：音频文件选择器 -->
                <el-form-item label="音频文件" required>
                    <el-upload class="upload-demo" action="#" drag :auto-upload="false" :limit="1"
                        :on-change="handleFileChange" :on-remove="handleFileRemove" accept=".mp3,.flac,.wav">
                        <el-icon class="el-icon--upload">
                            <UploadFilled />
                        </el-icon>
                        <div class="el-upload__text">
                            拖拽文件到此处或 <em>点击选择</em>
                        </div>
                        <template #tip>
                            <div class="el-upload__tip">支持 mp3/flac/wav 格式，无损音质最佳</div>
                        </template>
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
import { Refresh, Plus, Picture, UploadFilled, Delete } from '@element-plus/icons-vue';
import { ElMessage, type UploadFile, type FormInstance, type FormRules, ElMessageBox } from 'element-plus';
import { getSongs, createSong, type SongDto } from '../../api/catalog';
import { initUpload, uploadToMinio, confirmUpload } from '../../api/media';
import { deleteSong } from '../../api/catalog';

// --- 列表逻辑 ---
const tableData = ref<SongDto[]>([]);
const listLoading = ref(false);

const fetchData = async () => {
    listLoading.value = true;
    try {
        const res = await getSongs();
        if (res.isSuccess && res.value) {
            tableData.value = res.value;
        }
        console.log("API Response:", res);
    } catch (error) {
        console.error(error);
    } finally {
        listLoading.value = false;
    }
};

onMounted(fetchData);

// --- 表单与上传逻辑 ---
const dialogVisible = ref(false);
const submitLoading = ref(false);
const uploadFormRef = ref<FormInstance>();
const selectedFile = ref<File | null>(null);

const uploadForm = reactive({
    title: '',
    artist: '',
    album: '',
    coverUrl: '' // 默认占位图
});

const uploadRules: FormRules = {
    // title: [{ required: true, message: '必填', trigger: 'blur' }],
    // artist: [{ required: true, message: '必填', trigger: 'blur' }],
    // album: [{ required: true, message: '必填', trigger: 'blur' }],
};

const handleDelete = (row: SongDto) => {
    ElMessageBox.confirm(
        `确定要删除歌曲 "${row.title}" 吗？此操作不可恢复，且会同步删除音频文件。`,
        '警告',
        {
            confirmButtonText: '确定删除',
            cancelButtonText: '取消',
            type: 'warning',
            confirmButtonClass: 'el-button--danger'
        }
    ).then(async () => {
        try {
            const res = await deleteSong(row.id);
            if (res.isSuccess) {
                ElMessage.success('删除成功');
                // 重新加载列表
                fetchData();
            } else {
                ElMessage.error(res.error?.description || '删除失败');
            }
        } catch (error) {
            console.error(error);
        }
    }).catch(() => {
        // 用户点击取消，不做操作
    });
};

const openDialog = () => {
    dialogVisible.value = true;
};

const handleFileChange = (file: UploadFile) => {
    if (file.raw) selectedFile.value = file.raw;
};

const handleFileRemove = () => {
    selectedFile.value = null;
};

const resetForm = () => {
    if (uploadFormRef.value) uploadFormRef.value.resetFields();
    selectedFile.value = null;
    // 清理 upload 组件的文件列表 (这里简化处理，实际需要 ref 到 upload 组件调用 clearFiles)
};

// 【⭐⭐⭐ 核心业务：全链路上传 ⭐⭐⭐】
const handleUpload = async () => {
    if (!uploadFormRef.value) return;
    if (!selectedFile.value) {
        ElMessage.warning('请选择音频文件');
        return;
    }

    await uploadFormRef.value.validate(async (valid) => {
        if (valid) {
            submitLoading.value = true;
            try {
                // Step 1: 在 Catalog Service 创建元数据
                const metaRes = await createSong(uploadForm);
                if (!metaRes.isSuccess || !metaRes.value) {
                    throw new Error(metaRes.error?.description || '元数据创建失败');
                }
                const songId = metaRes.value; // 把 ID 存下来
                // Step 2: 向 Media Service 申请上传链接
                const initRes = await initUpload({
                    songId: songId, // 【核心修改】
                    fileName: selectedFile.value!.name,
                    contentType: selectedFile.value!.type || 'audio/mpeg'
                });

                if (!initRes.isSuccess || !initRes.value) throw new Error('获取上传链接失败');

                const { uploadId, uploadUrl } = initRes.value;

                // Step 3: 直传 MinIO (PUT)
                await uploadToMinio(uploadUrl, selectedFile.value!);

                // Step 4: 确认上传 (触发转码)
                await confirmUpload(uploadId);

                ElMessage.success('发布成功！后台正在转码，请稍候...');
                dialogVisible.value = false;

                // 自动刷新列表 (稍微延迟一下，虽然转码是异步的，但元数据已经有了)
                setTimeout(fetchData, 1000);

            } catch (error: any) {
                console.error(error);
                ElMessage.error(error.message || '上传流程发生错误');
            } finally {
                submitLoading.value = false;
            }
        }
    });
};
</script>

<style scoped lang="scss">
.song-container {
    .toolbar {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 20px;

        .title {
            margin: 0;
            font-size: 18px;
            border-left: 4px solid #409eff;
            padding-left: 10px;
        }
    }

    .cover-img {
        width: 50px;
        height: 50px;
        border-radius: 4px;
        background-color: #f5f7fa;
    }
}
</style>