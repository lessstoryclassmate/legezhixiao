<template>
  <div class="md-file-explorer">
    <div class="explorer-header">
      <h3 class="explorer-title">
        <i class="icon">📁</i>
        MD文件管理器
      </h3>
      <div class="explorer-actions">
        <button 
          @click="createNewFile" 
          class="btn-icon"
          title="新建文件"
        >
          <i class="icon">➕</i>
        </button>
        <button 
          @click="refreshFiles" 
          class="btn-icon"
          title="刷新"
        >
          <i class="icon">🔄</i>
        </button>
      </div>
    </div>

    <div class="file-tree">
      <div class="file-group" v-for="group in groupedFiles" :key="group.type">
        <div 
          class="group-header"
          @click="toggleGroup(group.type)"
          :class="{ collapsed: collapsedGroups.has(group.type) }"
        >
          <i class="group-icon">{{ group.icon }}</i>
          <span class="group-title">{{ group.title }}</span>
          <span class="file-count">({{ group.files.length }})</span>
        </div>
        
        <div 
          class="group-files"
          v-show="!collapsedGroups.has(group.type)"
        >
          <div 
            v-for="file in group.files" 
            :key="file.id"
            class="file-item"
            :class="{ 
              active: activeFileId === file.id,
              modified: file.modified
            }"
            @click="selectFile(file)"
            @dblclick="openFile(file)"
          >
            <i class="file-icon">📄</i>
            <span class="file-name">{{ file.name }}</span>
            <span v-if="file.modified" class="modified-indicator">●</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 新建文件对话框 -->
    <div v-if="showNewFileDialog" class="modal-overlay" @click.self="closeNewFileDialog">
      <div class="modal">
        <div class="modal-header">
          <h3>新建MD文件</h3>
          <button @click="closeNewFileDialog" class="btn-close">×</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>文件类型:</label>
            <select v-model="newFile.type">
              <option value="novel">小说信息</option>
              <option value="chapter">章节内容</option>
              <option value="character">人物设定</option>
              <option value="worldview">世界观</option>
              <option value="plot">情节规划</option>
              <option value="foreshadow">伏笔设置</option>
              <option value="ai_conv">AI对话</option>
            </select>
          </div>
          <div class="form-group">
            <label>文件名称:</label>
            <input 
              v-model="newFile.name" 
              type="text" 
              placeholder="请输入文件名称"
              @keyup.enter="confirmCreateFile"
            />
          </div>
          <div class="form-group">
            <label>小说ID:</label>
            <input 
              v-model="newFile.novelId" 
              type="text" 
              placeholder="请输入小说ID"
            />
          </div>
        </div>
        <div class="modal-footer">
          <button @click="closeNewFileDialog" class="btn-secondary">取消</button>
          <button @click="confirmCreateFile" class="btn-primary">创建</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, computed, onMounted } from 'vue'

interface MDFile {
  id: string
  name: string
  type: string
  novelId: string
  path: string
  content: string
  modified: boolean
  createdAt: string
  updatedAt: string
}

interface FileGroup {
  type: string
  title: string
  icon: string
  files: MDFile[]
}

export default defineComponent({
  name: 'MDFileExplorer',
  emits: ['file-selected', 'file-opened', 'file-created'],
  setup(_, { emit }) {
    const files = ref<MDFile[]>([])
    const activeFileId = ref<string>('')
    const collapsedGroups = ref(new Set<string>())
    const showNewFileDialog = ref(false)
    
    const newFile = ref({
      type: 'chapter',
      name: '',
      novelId: 'novel_001'
    })

    const fileTypeConfig = {
      novel: { title: '小说信息', icon: '📚' },
      chapter: { title: '章节内容', icon: '📖' },
      character: { title: '人物设定', icon: '👤' },
      worldview: { title: '世界观', icon: '🌍' },
      plot: { title: '情节规划', icon: '📋' },
      foreshadow: { title: '伏笔设置', icon: '🔗' },
      ai_conv: { title: 'AI对话', icon: '🤖' }
    }

    const groupedFiles = computed(() => {
      const groups: { [key: string]: MDFile[] } = {}
      
      files.value.forEach(file => {
        if (!groups[file.type]) {
          groups[file.type] = []
        }
        groups[file.type].push(file)
      })

      return Object.entries(groups).map(([type, fileList]) => ({
        type,
        title: fileTypeConfig[type as keyof typeof fileTypeConfig]?.title || type,
        icon: fileTypeConfig[type as keyof typeof fileTypeConfig]?.icon || '📄',
        files: fileList.sort((a, b) => a.name.localeCompare(b.name))
      }))
    })

    const toggleGroup = (groupType: string) => {
      if (collapsedGroups.value.has(groupType)) {
        collapsedGroups.value.delete(groupType)
      } else {
        collapsedGroups.value.add(groupType)
      }
    }

    const selectFile = (file: MDFile) => {
      activeFileId.value = file.id
      emit('file-selected', file)
    }

    const openFile = (file: MDFile) => {
      activeFileId.value = file.id
      emit('file-opened', file)
    }

    const createNewFile = () => {
      newFile.value = {
        type: 'chapter',
        name: '',
        novelId: 'novel_001'
      }
      showNewFileDialog.value = true
    }

    const closeNewFileDialog = () => {
      showNewFileDialog.value = false
    }

    const confirmCreateFile = () => {
      if (!newFile.value.name.trim()) {
        alert('请输入文件名称')
        return
      }

      const fileName = generateFileName(newFile.value.type, newFile.value.novelId, newFile.value.name)
      const file: MDFile = {
        id: Date.now().toString(),
        name: fileName,
        type: newFile.value.type,
        novelId: newFile.value.novelId,
        path: fileName,
        content: generateFileTemplate(newFile.value.type, newFile.value.novelId, newFile.value.name),
        modified: false,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      }

      files.value.push(file)
      emit('file-created', file)
      closeNewFileDialog()
      openFile(file)
    }

    const generateFileName = (type: string, novelId: string, name: string) => {
      const sanitizedName = name.replace(/[^a-zA-Z0-9\u4e00-\u9fa5]/g, '_')
      return `${type}_${novelId}_${sanitizedName}.md`
    }

    const generateFileTemplate = (type: string, novelId: string, name: string) => {
      const now = new Date().toISOString()
      const frontMatter = `---
file_type: "${type}"
novel_id: "${novelId}"
title: "${name}"
created_at: "${now}"
updated_at: "${now}"
version: 1
status: "draft"
related_files: []
tags: []
---

`

      const templates = {
        novel: `# ${name}

## 小说基本信息
- **标题**: ${name}
- **作者**: 
- **类型**: 
- **字数**: 0

## 故事简介


## 主要角色


## 创作笔记

`,
        chapter: `# ${name}

## 章节大纲


## 正文内容


## 写作笔记

`,
        character: `# ${name}

## 基础信息
- **姓名**: ${name}
- **年龄**: 
- **性别**: 
- **职业**: 

## 外貌特征


## 性格特点


## 背景故事


## 角色发展

`,
        worldview: `# ${name}

## 概述


## 详细设定


## 相关规则

`,
        plot: `# ${name}

## 情节概述


## 主要事件


## 发展脉络

`,
        foreshadow: `# ${name}

## 伏笔内容


## 揭示时机


## 相关情节

`,
        ai_conv: `# ${name}

## 对话记录


## 重要信息


## 待办事项

`
      }

      return frontMatter + (templates[type as keyof typeof templates] || templates.chapter)
    }

    const refreshFiles = async () => {
      // TODO: 从API加载文件列表
      console.log('刷新文件列表...')
    }

    onMounted(() => {
      refreshFiles()
    })

    return {
      files,
      activeFileId,
      collapsedGroups,
      groupedFiles,
      showNewFileDialog,
      newFile,
      toggleGroup,
      selectFile,
      openFile,
      createNewFile,
      closeNewFileDialog,
      confirmCreateFile,
      refreshFiles
    }
  }
})
</script>

<style scoped>
.md-file-explorer {
  height: 100%;
  display: flex;
  flex-direction: column;
  background-color: var(--vscode-sideBar-background);
  color: var(--vscode-sideBar-foreground);
  border-right: 1px solid var(--vscode-sideBar-border);
}

.explorer-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  border-bottom: 1px solid var(--vscode-sideBar-border);
  background-color: var(--vscode-sideBarSectionHeader-background);
}

.explorer-title {
  margin: 0;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  color: var(--vscode-sideBarSectionHeader-foreground);
  display: flex;
  align-items: center;
  gap: 6px;
}

.explorer-actions {
  display: flex;
  gap: 4px;
}

.btn-icon {
  width: 22px;
  height: 22px;
  border: none;
  background: transparent;
  color: var(--vscode-sideBarSectionHeader-foreground);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 2px;
  font-size: 12px;
}

.btn-icon:hover {
  background-color: var(--vscode-toolbar-hoverBackground);
}

.file-tree {
  flex: 1;
  overflow-y: auto;
  padding: 4px 0;
}

.file-group {
  margin-bottom: 2px;
}

.group-header {
  display: flex;
  align-items: center;
  padding: 4px 12px;
  cursor: pointer;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  background-color: var(--vscode-sideBarSectionHeader-background);
  color: var(--vscode-sideBarSectionHeader-foreground);
  border-bottom: 1px solid var(--vscode-sideBar-border);
}

.group-header:hover {
  background-color: var(--vscode-list-hoverBackground);
}

.group-header.collapsed .group-icon::before {
  content: '▶';
}

.group-icon {
  margin-right: 6px;
  font-size: 12px;
}

.group-icon::before {
  content: '▼';
  margin-right: 4px;
  font-size: 8px;
}

.group-title {
  flex: 1;
}

.file-count {
  opacity: 0.6;
  font-size: 10px;
}

.group-files {
  padding-left: 8px;
}

.file-item {
  display: flex;
  align-items: center;
  padding: 3px 12px;
  cursor: pointer;
  font-size: 13px;
  color: var(--vscode-list-inactiveSelectionForeground);
}

.file-item:hover {
  background-color: var(--vscode-list-hoverBackground);
}

.file-item.active {
  background-color: var(--vscode-list-activeSelectionBackground);
  color: var(--vscode-list-activeSelectionForeground);
}

.file-icon {
  margin-right: 6px;
  font-size: 12px;
  opacity: 0.8;
}

.file-name {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.modified-indicator {
  color: var(--vscode-gitDecoration-modifiedResourceForeground);
  margin-left: 4px;
  font-size: 16px;
  line-height: 1;
}

/* 模态框样式 */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background-color: var(--vscode-editor-background);
  border: 1px solid var(--vscode-contrastBorder);
  border-radius: 4px;
  width: 400px;
  max-width: 90vw;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-bottom: 1px solid var(--vscode-contrastBorder);
}

.modal-header h3 {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
}

.btn-close {
  border: none;
  background: transparent;
  font-size: 18px;
  cursor: pointer;
  color: var(--vscode-foreground);
  padding: 0;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-body {
  padding: 16px;
}

.form-group {
  margin-bottom: 12px;
}

.form-group label {
  display: block;
  margin-bottom: 4px;
  font-size: 12px;
  font-weight: 600;
}

.form-group input,
.form-group select {
  width: 100%;
  padding: 6px 8px;
  border: 1px solid var(--vscode-input-border);
  background-color: var(--vscode-input-background);
  color: var(--vscode-input-foreground);
  border-radius: 2px;
  font-size: 13px;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  padding: 12px 16px;
  border-top: 1px solid var(--vscode-contrastBorder);
}

.btn-primary,
.btn-secondary {
  padding: 6px 14px;
  border: none;
  border-radius: 2px;
  cursor: pointer;
  font-size: 12px;
  font-weight: 500;
}

.btn-primary {
  background-color: var(--vscode-button-background);
  color: var(--vscode-button-foreground);
}

.btn-primary:hover {
  background-color: var(--vscode-button-hoverBackground);
}

.btn-secondary {
  background-color: var(--vscode-button-secondaryBackground);
  color: var(--vscode-button-secondaryForeground);
}

.btn-secondary:hover {
  background-color: var(--vscode-button-secondaryHoverBackground);
}
</style>
