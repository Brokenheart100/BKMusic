<template>
    <el-container class="layout-container">
        <el-header class="header">
            <div class="logo">
                <el-icon class="icon">
                    <Headset />
                </el-icon>
                <span>BKMusic Admin</span>
            </div>
            <div class="user-info">
                <span class="nickname">Admin User</span>
                <el-button type="danger" size="small" plain @click="handleLogout">
                    退出登录
                </el-button>
            </div>
        </el-header>

        <el-main class="main-content">
            <!-- 路由出口：显示具体的子页面 -->
            <router-view v-slot="{ Component }">
                <transition name="fade" mode="out-in">
                    <component :is="Component" />
                </transition>
            </router-view>
        </el-main>
    </el-container>
</template>

<script setup lang="ts">
import { Headset } from '@element-plus/icons-vue';
import { useUserStore } from '../store/user';
import { ElMessageBox } from 'element-plus';

const userStore = useUserStore();

const handleLogout = () => {
    ElMessageBox.confirm('确定要退出登录吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
    }).then(() => {
        userStore.logout();
    });
};
</script>

<style scoped lang="scss">
.layout-container {
    height: 100vh;
    display: flex;
    flex-direction: column;
}

.header {
    background-color: #2b303b;
    color: #fff;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0 20px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);

    .logo {
        display: flex;
        align-items: center;
        font-size: 20px;
        font-weight: bold;

        .icon {
            margin-right: 10px;
            font-size: 24px;
        }
    }

    .user-info {
        display: flex;
        align-items: center;

        .nickname {
            margin-right: 15px;
            font-size: 14px;
        }
    }
}

.main-content {
    background-color: #f0f2f5;
    padding: 20px;
}

/* 简单的淡入淡出动画 */
.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
    opacity: 0;
}
</style>