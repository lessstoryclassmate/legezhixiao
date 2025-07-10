<template>
  <div class="about">
    <h1>关于我们</h1>
    <p>AI小说内容编辑器 - 让创作更智能</p>
    <button class="btn primary" @click="goBack">返回首页</button>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'

const router = useRouter()

const goBack = () => {
  router.push('/')
}
</script>

<style scoped>
.about {
  padding: 2rem;
  text-align: center;
}

.btn {
  padding: 12px 24px;
  border: none;
  border-radius: 6px;
  font-size: 1rem;
  cursor: pointer;
  background: #f5f5f5;
  color: #333;
  transition: all 0.3s;
}

.btn:hover {
  transform: translateY(-2px);
}

.btn.primary {
  background: #409eff;
  color: white;
}

.btn.primary:hover {
  background: #337ecc;
}
</style>
