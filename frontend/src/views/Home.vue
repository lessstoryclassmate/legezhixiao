<template>
  <div class="home">
    <div class="hero">
      <h1>AI小说内容编辑器</h1>
      <p>基于SiliconFlow API的智能小说创作平台</p>
      <div class="actions">
        <button class="btn primary" @click="goToNovels">
          开始创作
        </button>
        <button class="btn" @click="goToAbout">
          了解更多
        </button>
      </div>
    </div>
    
    <div class="features">
      <h2>核心功能</h2>
      <div class="feature-grid">
        <div class="feature-card">
          <h3>智能创作</h3>
          <p>AI辅助创作，提供灵感和建议</p>
        </div>
        <div class="feature-card">
          <h3>章节管理</h3>
          <p>结构化章节管理，剧情DNA分析</p>
        </div>
        <div class="feature-card">
          <h3>人物设定</h3>
          <p>立体化角色建模，关系网络分析</p>
        </div>
        <div class="feature-card">
          <h3>协作编辑</h3>
          <p>多人协作，实时同步</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'

const router = useRouter()

const goToNovels = () => {
  router.push('/novels')
}

const goToAbout = () => {
  router.push('/about')
}
</script>

<style scoped>
.home {
  min-height: 100vh;
  padding: 2rem;
}

.hero {
  text-align: center;
  padding: 4rem 0;
}

.hero h1 {
  font-size: 3rem;
  margin-bottom: 1rem;
  color: #2c3e50;
}

.hero p {
  font-size: 1.2rem;
  color: #666;
  margin-bottom: 2rem;
}

.actions {
  display: flex;
  gap: 1rem;
  justify-content: center;
  align-items: center;
  flex-wrap: wrap;
  margin-top: 2rem;
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
  min-width: 120px;
  text-align: center;
  white-space: nowrap;
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

.features {
  max-width: 1200px;
  margin: 0 auto;
  padding: 4rem 0;
}

.features h2 {
  text-align: center;
  font-size: 2rem;
  margin-bottom: 3rem;
  color: #2c3e50;
}

.feature-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 2rem;
}

.feature-card {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
  text-align: center;
}

.feature-card h3 {
  font-size: 1.5rem;
  margin-bottom: 1rem;
  color: #409eff;
}

.feature-card p {
  color: #666;
  line-height: 1.6;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .hero h1 {
    font-size: 2rem;
  }
  
  .hero p {
    font-size: 1rem;
  }
  
  .actions {
    flex-direction: column;
    align-items: center;
    gap: 0.8rem;
  }
  
  .btn {
    width: 200px;
    padding: 14px 24px;
  }
  
  .home {
    padding: 1rem;
  }
}
</style>
