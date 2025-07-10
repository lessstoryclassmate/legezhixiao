<template>
  <div class="characters-container">
    <div class="page-header">
      <div class="header-content">
        <h1>人物管理</h1>
        <p>管理您小说中的人物角色</p>
      </div>
      <div class="header-actions">
        <button class="btn btn-primary" @click="showCreateModal = true">
          <span class="btn-icon">👤</span>
          创建人物
        </button>
      </div>
    </div>

    <div class="characters-grid">
      <div
        v-for="character in characters"
        :key="character.id"
        class="character-card"
        @click="editCharacter(character)"
      >
        <div class="character-avatar">
          <img :src="character.avatar || '/default-avatar.png'" :alt="character.name" />
        </div>
        <div class="character-info">
          <h3 class="character-name">{{ character.name }}</h3>
          <p class="character-role">{{ character.role }}</p>
          <p class="character-description">{{ character.description }}</p>
        </div>
      </div>
    </div>

    <div v-if="characters.length === 0" class="empty-state">
      <div class="empty-icon">👥</div>
      <h3>还没有创建人物</h3>
      <p>开始创建您的第一个人物角色吧！</p>
      <button class="btn btn-primary" @click="showCreateModal = true">
        创建人物
      </button>
    </div>

    <!-- 创建人物模态框 -->
    <div v-if="showCreateModal" class="modal-overlay" @click="showCreateModal = false">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h2>创建新人物</h2>
          <button class="close-btn" @click="showCreateModal = false">×</button>
        </div>
        <form @submit.prevent="createCharacter" class="modal-form">
          <div class="form-group">
            <label for="name">人物姓名</label>
            <input
              id="name"
              v-model="newCharacter.name"
              type="text"
              required
              placeholder="请输入人物姓名"
              class="form-input"
            />
          </div>
          <div class="form-group">
            <label for="role">角色定位</label>
            <select id="role" v-model="newCharacter.role" class="form-select">
              <option value="">请选择角色定位</option>
              <option value="主角">主角</option>
              <option value="配角">配角</option>
              <option value="反派">反派</option>
              <option value="路人">路人</option>
            </select>
          </div>
          <div class="form-group">
            <label for="description">人物描述</label>
            <textarea
              id="description"
              v-model="newCharacter.description"
              rows="4"
              placeholder="请输入人物描述"
              class="form-textarea"
            ></textarea>
          </div>
          <div class="modal-actions">
            <button type="button" class="btn btn-outline" @click="showCreateModal = false">
              取消
            </button>
            <button type="submit" class="btn btn-primary">
              创建人物
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const characters = ref([
  {
    id: 1,
    name: '张三',
    role: '主角',
    description: '故事的主人公，勇敢善良，有着强烈的正义感。',
    avatar: null
  },
  {
    id: 2,
    name: '李四',
    role: '配角',
    description: '主角的好友，聪明机智，在关键时刻总能提供帮助。',
    avatar: null
  }
])

const showCreateModal = ref(false)
const newCharacter = ref({
  name: '',
  role: '',
  description: ''
})

const createCharacter = () => {
  const character = {
    id: Date.now(),
    name: newCharacter.value.name,
    role: newCharacter.value.role,
    description: newCharacter.value.description,
    avatar: null
  }
  
  characters.value.push(character)
  showCreateModal.value = false
  
  // 重置表单
  newCharacter.value = {
    name: '',
    role: '',
    description: ''
  }
}

const editCharacter = (character: any) => {
  console.log('编辑人物:', character)
  // 这里可以实现编辑功能
}
</script>

<style scoped>
.characters-container {
  padding: 2rem;
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.header-content h1 {
  font-size: 2rem;
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.header-content p {
  color: #666;
  font-size: 1rem;
}

.btn {
  padding: 0.8rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.3s;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  text-decoration: none;
}

.btn-primary {
  background: #409eff;
  color: white;
}

.btn-primary:hover {
  background: #337ecc;
  transform: translateY(-2px);
}

.btn-outline {
  background: transparent;
  border: 1px solid #409eff;
  color: #409eff;
}

.btn-outline:hover {
  background: #409eff;
  color: white;
}

.btn-icon {
  font-size: 1.1rem;
}

.characters-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 2rem;
}

.character-card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  padding: 1.5rem;
  cursor: pointer;
  transition: all 0.3s;
}

.character-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}

.character-avatar {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  margin: 0 auto 1rem;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2rem;
  color: white;
}

.character-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 50%;
}

.character-info {
  text-align: center;
}

.character-name {
  font-size: 1.3rem;
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.character-role {
  color: #409eff;
  font-weight: 500;
  margin-bottom: 0.5rem;
}

.character-description {
  color: #666;
  font-size: 0.9rem;
  line-height: 1.6;
}

.empty-state {
  text-align: center;
  padding: 4rem 2rem;
  color: #666;
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.empty-state h3 {
  font-size: 1.5rem;
  margin-bottom: 0.5rem;
  color: #2c3e50;
}

.empty-state p {
  margin-bottom: 2rem;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 12px;
  width: 90%;
  max-width: 500px;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 2rem;
  border-bottom: 1px solid #e1e8ed;
}

.modal-header h2 {
  font-size: 1.5rem;
  color: #2c3e50;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #666;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.3s;
}

.close-btn:hover {
  background: #f5f5f5;
}

.modal-form {
  padding: 2rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  color: #333;
  font-weight: 500;
}

.form-input,
.form-textarea,
.form-select {
  width: 100%;
  padding: 0.8rem;
  border: 2px solid #e1e8ed;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.3s;
  box-sizing: border-box;
}

.form-input:focus,
.form-textarea:focus,
.form-select:focus {
  outline: none;
  border-color: #409eff;
}

.form-textarea {
  resize: vertical;
  min-height: 100px;
}

.modal-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
}

@media (max-width: 768px) {
  .characters-container {
    padding: 1rem;
  }
  
  .page-header {
    flex-direction: column;
    gap: 1rem;
    align-items: flex-start;
  }
  
  .characters-grid {
    grid-template-columns: 1fr;
  }
  
  .modal-content {
    width: 95%;
  }
  
  .modal-form {
    padding: 1.5rem;
  }
  
  .modal-actions {
    flex-direction: column;
  }
}
</style>
