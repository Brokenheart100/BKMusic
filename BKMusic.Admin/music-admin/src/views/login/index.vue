<template>
    <div class="login-wrapper">
        <el-card class="login-card">
            <template #header>
                <h2 class="title">BKMusic 管理后台</h2>
            </template>

            <el-form ref="formRef" :model="form" :rules="rules" label-width="0" size="large" @keyup.enter="handleLogin">
                <el-form-item prop="email">
                    <el-input v-model="form.email" placeholder="请输入邮箱" :prefix-icon="User" />
                </el-form-item>
                <el-form-item prop="password">
                    <el-input v-model="form.password" type="password" placeholder="请输入密码" :prefix-icon="Lock"
                        show-password />
                </el-form-item>

                <el-button type="primary" class="w-100" :loading="loading" @click="handleLogin">
                    登 录
                </el-button>
            </el-form>
        </el-card>
    </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue';
import { useRouter } from 'vue-router';
import { User, Lock } from '@element-plus/icons-vue';
import { ElMessage, type FormInstance, type FormRules } from 'element-plus';
import { useUserStore } from '../../store/user';
import { login } from '../../api/auth';

const router = useRouter();
const userStore = useUserStore();
const formRef = ref<FormInstance>();
const loading = ref(false);

const form = reactive({
    email: 'user@example.com', // 默认值方便调试
    password: '123456'
});

const rules = reactive<FormRules>({
    email: [
        { required: true, message: '请输入邮箱', trigger: 'blur' },
        { type: 'email', message: '邮箱格式不正确', trigger: 'blur' }
    ],
    password: [
        { required: true, message: '请输入密码', trigger: 'blur' },
        { min: 6, message: '密码长度不能小于6位', trigger: 'blur' }
    ]
});

const handleLogin = async () => {
    if (!formRef.value) return;

    await formRef.value.validate(async (valid) => {
        if (valid) {
            loading.value = true;
            try {
                const res = await login(form);

                // request 拦截器已经解包了 response.data
                // 根据 api.d.ts 定义，res 是 ApiResponse<AuthResponse>
                if (res.isSuccess && res.value) {
                    const { accessToken, refreshToken } = res.value;
                    userStore.setLoginState(accessToken, refreshToken);
                    // userStore.setUserInfo('Admin'); // 实际应从 Token 解析或单独调 API

                    ElMessage.success('登录成功');
                    router.push('/');
                } else {
                    // 业务逻辑失败 (如密码错误)
                    ElMessage.error(res.error?.description || '登录失败');
                }
            } finally {
                loading.value = false;
            }
        }
    });
};
</script>

<style scoped>
.login-wrapper {
    height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
    background-color: #2d3a4b;
    background-image: linear-gradient(135deg, #2d3a4b 0%, #1c232d 100%);
}

.login-card {
    width: 400px;
    border-radius: 8px;
}

.title {
    text-align: center;
    margin: 0;
    color: #333;
}

.w-100 {
    width: 100%;
}
</style>