# MD文件命名规范和数据交互架构

## 文件命名规范

### 1. 基础格式
```
{模块类型}_{小说ID}_{具体类型}_{序号/ID}.md
```

### 2. 模块类型前缀
- `novel_` - 小说基础信息
- `chapter_` - 章节内容
- `character_` - 人物设定
- `worldview_` - 世界观设定
- `plot_` - 情节规划
- `foreshadow_` - 伏笔设置
- `ai_conv_` - AI对话记录

### 3. 具体命名示例

#### 小说基础信息
- `novel_{novel_id}_info.md` - 小说基本信息
- `novel_{novel_id}_outline.md` - 小说大纲
- `novel_{novel_id}_config.md` - 小说配置

#### 章节内容
- `chapter_{novel_id}_{chapter_num}.md` - 章节正文
- `chapter_{novel_id}_{chapter_num}_outline.md` - 章节大纲
- `chapter_{novel_id}_{chapter_num}_notes.md` - 章节笔记

#### 人物设定
- `character_{novel_id}_{character_id}_profile.md` - 人物档案
- `character_{novel_id}_{character_id}_development.md` - 人物发展
- `character_{novel_id}_{character_id}_relationships.md` - 人物关系

#### 世界观设定
- `worldview_{novel_id}_general.md` - 总体世界观
- `worldview_{novel_id}_magic_system.md` - 魔法体系
- `worldview_{novel_id}_geography.md` - 地理设定
- `worldview_{novel_id}_history.md` - 历史背景

#### 情节规划
- `plot_{novel_id}_main_arc.md` - 主线情节
- `plot_{novel_id}_sub_arc_{arc_id}.md` - 支线情节
- `plot_{novel_id}_timeline.md` - 时间线

#### 伏笔设置
- `foreshadow_{novel_id}_{foreshadow_id}.md` - 伏笔内容
- `foreshadow_{novel_id}_index.md` - 伏笔索引

#### AI对话记录
- `ai_conv_{novel_id}_{session_id}.md` - AI对话会话
- `ai_conv_{novel_id}_summary.md` - AI对话总结

## MD文件标准格式

### 文件头信息 (YAML Front Matter)
```yaml
---
file_type: "chapter" | "character" | "worldview" | "plot" | "foreshadow" | "novel" | "ai_conv"
novel_id: "小说唯一ID"
created_at: "2025-07-11T00:00:00Z"
updated_at: "2025-07-11T00:00:00Z"
version: 1
author: "用户ID"
status: "draft" | "published" | "archived"
related_files: ["相关文件列表"]
tags: ["标签1", "标签2"]
---
```

### 章节文件格式
```markdown
---
file_type: "chapter"
novel_id: "novel_001"
chapter_number: 1
title: "第一章 开始"
word_count: 0
status: "draft"
created_at: "2025-07-11T00:00:00Z"
updated_at: "2025-07-11T00:00:00Z"
related_characters: ["char_001", "char_002"]
related_worldview: ["worldview_001"]
related_plots: ["plot_001"]
---

# 第一章 开始

## 章节大纲
- 主要事件1
- 主要事件2

## 正文内容
这里是章节的正文内容...

## 写作笔记
- 注意事项1
- 注意事项2
```

### 人物文件格式
```markdown
---
file_type: "character"
novel_id: "novel_001"
character_id: "char_001"
name: "角色名称"
status: "active"
created_at: "2025-07-11T00:00:00Z"
updated_at: "2025-07-11T00:00:00Z"
related_chapters: ["chapter_001", "chapter_002"]
---

# 角色名称

## 基础信息
- **姓名**: 角色全名
- **年龄**: XX岁
- **性别**: 男/女
- **职业**: 职业描述

## 外貌特征
描述角色的外貌...

## 性格特点
描述角色的性格...

## 背景故事
角色的背景历史...

## 角色发展
在故事中的成长轨迹...
```

## 数据交互逻辑

### 1. 模块间数据读取
- 每个模块根据文件名前缀读取对应的MD文件
- 通过YAML Front Matter获取结构化元数据
- 通过Markdown内容获取详细描述信息

### 2. 数据更新机制
- 单个模块更新时，自动更新相关文件的关联信息
- 维护文件间的引用关系
- 版本控制和变更跟踪

### 3. AI智能交互
- AI可以读取所有相关MD文件作为上下文
- 根据用户需求生成或更新对应的MD文件
- 自动维护文件间的一致性和关联性

## 实现优势

1. **统一数据格式**: 所有数据都是MD文件，便于版本控制和编辑
2. **模块解耦**: 各模块独立运作，通过文件名约定进行数据交互
3. **可读性强**: MD格式便于人类阅读和编辑
4. **扩展性好**: 易于添加新的模块和文件类型
5. **AI友好**: LLM可以直接理解和生成MD格式内容
