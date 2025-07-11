"""
MD 文件管理系统 API
支持基于 MD 文件的统一数据交互和模块间数据传递
使用 MongoDB 作为统一数据库
"""

from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Query
from typing import List, Dict, Any, Optional
import os
import json
import re
from datetime import datetime
from pathlib import Path
from bson import ObjectId

from app.database import users_collection, md_files_collection
from app.routes.auth import get_current_user
from app.models.user_model import UserResponse
from app.core.config import settings

router = APIRouter()

# MD 文件存储目录
MD_FILES_DIR = Path(settings.UPLOAD_DIR) / "md_files"
MD_FILES_DIR.mkdir(parents=True, exist_ok=True)

# MD 文件类型定义
MD_FILE_TYPES = {
    'novel': '小说主文件',
    'chapter': '章节内容',
    'character': '人物设定',
    'world': '世界构建',
    'plot': '情节设定',
    'analysis': '分析报告',
    'style': '风格模板',
    'template': '模板文件'
}

# MD 文件命名规范
class MDFileNaming:
    """MD 文件命名规范类"""
    
    @staticmethod
    def novel(novel_id: str) -> str:
        """小说主文件命名"""
        return f"novel-{novel_id}-main.md"
    
    @staticmethod
    def chapter(novel_id: str, chapter_number: int) -> str:
        """章节文件命名"""
        return f"novel-{novel_id}-chapter-{chapter_number:03d}.md"
    
    @staticmethod
    def character(novel_id: str, character_name: str) -> str:
        """人物设定文件命名"""
        safe_name = re.sub(r'[^\w\-_]', '_', character_name)
        return f"novel-{novel_id}-character-{safe_name}.md"
    
    @staticmethod
    def world(novel_id: str, world_name: str) -> str:
        """世界构建文件命名"""
        safe_name = re.sub(r'[^\w\-_]', '_', world_name)
        return f"novel-{novel_id}-world-{safe_name}.md"
    
    @staticmethod
    def plot(novel_id: str, plot_name: str) -> str:
        """情节设定文件命名"""
        safe_name = re.sub(r'[^\w\-_]', '_', plot_name)
        return f"novel-{novel_id}-plot-{safe_name}.md"
    
    @staticmethod
    def analysis(novel_id: str, analysis_type: str, timestamp: str = None) -> str:
        """分析报告文件命名"""
        if not timestamp:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        return f"novel-{novel_id}-analysis-{analysis_type}-{timestamp}.md"
    
    @staticmethod
    def style(style_name: str) -> str:
        """风格模板文件命名"""
        safe_name = re.sub(r'[^\w\-_]', '_', style_name)
        return f"style-{safe_name}-template.md"
    
    @staticmethod
    def template(template_type: str, template_name: str) -> str:
        """通用模板文件命名"""
        safe_type = re.sub(r'[^\w\-_]', '_', template_type)
        safe_name = re.sub(r'[^\w\-_]', '_', template_name)
        return f"template-{safe_type}-{safe_name}.md"

# MD 文件解析器
class MDFileParser:
    """MD 文件解析器"""
    
    @staticmethod
    def parse_metadata(content: str) -> Dict[str, Any]:
        """解析 MD 文件中的元数据"""
        metadata = {}
        
        # 解析 YAML Front Matter
        yaml_match = re.match(r'^---\s*\n(.*?)\n---\s*\n', content, re.DOTALL)
        if yaml_match:
            try:
                import yaml
                metadata = yaml.safe_load(yaml_match.group(1))
            except:
                pass
        
        # 解析标题
        title_match = re.search(r'^# (.+)$', content, re.MULTILINE)
        if title_match:
            metadata['title'] = title_match.group(1).strip()
        
        # 解析标签
        tags_match = re.search(r'^## 标签\s*\n(.+)', content, re.MULTILINE | re.DOTALL)
        if tags_match:
            tags_text = tags_match.group(1).strip()
            metadata['tags'] = [tag.strip() for tag in tags_text.split(',') if tag.strip()]
        
        # 解析基本信息
        info_match = re.search(r'^## 基本信息\s*\n(.*?)(?=\n## |\n# |\Z)', content, re.MULTILINE | re.DOTALL)
        if info_match:
            info_text = info_match.group(1)
            for line in info_text.split('\n'):
                if ':' in line:
                    key, value = line.split(':', 1)
                    key = key.strip('- ').strip()
                    value = value.strip()
                    if key and value:
                        metadata[key.lower()] = value
        
        return metadata
    
    @staticmethod
    def extract_content_sections(content: str) -> Dict[str, str]:
        """提取内容各个部分"""
        sections = {}
        
        # 按二级标题分割
        parts = re.split(r'^## (.+)$', content, flags=re.MULTILINE)
        
        current_section = None
        for i, part in enumerate(parts):
            if i == 0:
                sections['header'] = part.strip()
            elif i % 2 == 1:
                current_section = part.strip()
            else:
                if current_section:
                    sections[current_section] = part.strip()
        
        return sections
    
    @staticmethod
    def get_word_count(content: str) -> int:
        """获取字数统计"""
        # 移除 Markdown 标记
        text = re.sub(r'[#*`_\[\]()]+', '', content)
        text = re.sub(r'!\[.*?\]\(.*?\)', '', text)
        text = re.sub(r'\[.*?\]\(.*?\)', '', text)
        
        # 统计中文字符和英文单词
        chinese_chars = len(re.findall(r'[\u4e00-\u9fff]', text))
        english_words = len(re.findall(r'\b[a-zA-Z]+\b', text))
        
        return chinese_chars + english_words

# MD 文件模型
class MDFileModel:
    """MD 文件数据模型"""
    
    def __init__(self, file_path: Path):
        self.file_path = file_path
        self.filename = file_path.name
        self.file_type = self._parse_file_type()
        self.content = self._read_content()
        self.metadata = MDFileParser.parse_metadata(self.content)
        self.sections = MDFileParser.extract_content_sections(self.content)
        self.word_count = MDFileParser.get_word_count(self.content)
        self.created_at = datetime.fromtimestamp(file_path.stat().st_ctime)
        self.updated_at = datetime.fromtimestamp(file_path.stat().st_mtime)
    
    def _parse_file_type(self) -> str:
        """解析文件类型"""
        if self.filename.startswith('novel-') and self.filename.endswith('-main.md'):
            return 'novel'
        elif self.filename.startswith('novel-') and '-chapter-' in self.filename:
            return 'chapter'
        elif self.filename.startswith('novel-') and '-character-' in self.filename:
            return 'character'
        elif self.filename.startswith('novel-') and '-world-' in self.filename:
            return 'world'
        elif self.filename.startswith('novel-') and '-plot-' in self.filename:
            return 'plot'
        elif self.filename.startswith('novel-') and '-analysis-' in self.filename:
            return 'analysis'
        elif self.filename.startswith('style-') and self.filename.endswith('-template.md'):
            return 'style'
        elif self.filename.startswith('template-'):
            return 'template'
        else:
            return 'unknown'
    
    def _read_content(self) -> str:
        """读取文件内容"""
        try:
            with open(self.file_path, 'r', encoding='utf-8') as f:
                return f.read()
        except:
            return ""
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典"""
        return {
            'id': self.filename,
            'name': self.filename,
            'type': self.file_type,
            'content': self.content,
            'path': str(self.file_path),
            'metadata': self.metadata,
            'sections': self.sections,
            'word_count': self.word_count,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat(),
            'tags': self.metadata.get('tags', [])
        }

# API 端点
@router.get("/files", response_model=List[Dict[str, Any]])
async def get_files(
    user_id: str = Query(None, description="用户 ID"),
    novel_id: str = Query(None, description="小说 ID"),
    file_type: str = Query(None, description="文件类型"),
    current_user: UserResponse = Depends(get_current_user)
):
    """获取文件列表"""
    try:
        # 构建查询条件
        query = {"user_id": current_user.id}
        
        if novel_id:
            query["novel_id"] = novel_id
        
        if file_type:
            query["file_type"] = file_type
        
        # 从MongoDB获取文件列表
        cursor = md_files_collection.find(query)
        files = []
        
        async for file_doc in cursor:
            file_data = {
                "id": str(file_doc["_id"]),
                "name": file_doc.get("filename", ""),
                "type": file_doc.get("file_type", ""),
                "content": file_doc.get("content", ""),
                "path": file_doc.get("file_path", ""),
                "metadata": file_doc.get("metadata", {}),
                "sections": file_doc.get("sections", {}),
                "word_count": file_doc.get("word_count", 0),
                "created_at": file_doc.get("created_at", datetime.utcnow()).isoformat(),
                "updated_at": file_doc.get("updated_at", datetime.utcnow()).isoformat(),
                "tags": file_doc.get("tags", [])
            }
            files.append(file_data)
        
        # 按更新时间排序
        files.sort(key=lambda x: x['updated_at'], reverse=True)
        
        return files
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取文件失败: {str(e)}")

@router.post("/files", response_model=Dict[str, Any])
async def create_file(
    file_data: Dict[str, Any],
    current_user: UserResponse = Depends(get_current_user)
):
    """创建新文件"""
    try:
        # 解析文件信息
        file_type = file_data.get('type', 'novel')
        filename = file_data.get('name', 'untitled.md')
        content = file_data.get('content', '')
        novel_id = file_data.get('novel_id', '')
        
        if not filename.endswith('.md'):
            filename += '.md'
        
        # 解析文件内容
        metadata = MDFileParser.parse_metadata(content)
        sections = MDFileParser.extract_content_sections(content)
        word_count = MDFileParser.get_word_count(content)
        
        # 创建MongoDB文档
        file_doc = {
            "user_id": current_user.id,
            "filename": filename,
            "file_type": file_type,
            "novel_id": novel_id,
            "content": content,
            "file_path": f"/users/{current_user.id}/{filename}",
            "metadata": metadata,
            "sections": sections,
            "word_count": word_count,
            "tags": file_data.get('tags', []),
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        # 保存到MongoDB
        result = await md_files_collection.insert_one(file_doc)
        file_doc["_id"] = result.inserted_id
        
        # 返回文件信息
        return {
            "id": str(file_doc["_id"]),
            "name": file_doc["filename"],
            "type": file_doc["file_type"],
            "content": file_doc["content"],
            "path": file_doc["file_path"],
            "metadata": file_doc["metadata"],
            "sections": file_doc["sections"],
            "word_count": file_doc["word_count"],
            "created_at": file_doc["created_at"].isoformat(),
            "updated_at": file_doc["updated_at"].isoformat(),
            "tags": file_doc["tags"]
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"创建文件失败: {str(e)}")

@router.put("/files/{file_id}", response_model=Dict[str, Any])
async def update_file(
    file_id: str,
    file_data: Dict[str, Any],
    current_user: UserResponse = Depends(get_current_user)
):
    """更新文件"""
    try:
        # 查找文件
        file_doc = await md_files_collection.find_one({
            "_id": ObjectId(file_id),
            "user_id": current_user.id
        })
        
        if not file_doc:
            raise HTTPException(status_code=404, detail="文件不存在")
        
        # 更新文件内容
        content = file_data.get('content', file_doc.get('content', ''))
        
        # 重新解析文件内容
        metadata = MDFileParser.parse_metadata(content)
        sections = MDFileParser.extract_content_sections(content)
        word_count = MDFileParser.get_word_count(content)
        
        # 更新文档
        update_data = {
            "content": content,
            "metadata": metadata,
            "sections": sections,
            "word_count": word_count,
            "updated_at": datetime.utcnow()
        }
        
        # 如果有其他字段需要更新
        if 'tags' in file_data:
            update_data['tags'] = file_data['tags']
        
        await md_files_collection.update_one(
            {"_id": ObjectId(file_id)},
            {"$set": update_data}
        )
        
        # 返回更新后的文件信息
        updated_doc = await md_files_collection.find_one({"_id": ObjectId(file_id)})
        
        return {
            "id": str(updated_doc["_id"]),
            "name": updated_doc["filename"],
            "type": updated_doc["file_type"],
            "content": updated_doc["content"],
            "path": updated_doc["file_path"],
            "metadata": updated_doc["metadata"],
            "sections": updated_doc["sections"],
            "word_count": updated_doc["word_count"],
            "created_at": updated_doc["created_at"].isoformat(),
            "updated_at": updated_doc["updated_at"].isoformat(),
            "tags": updated_doc.get("tags", [])
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"更新文件失败: {str(e)}")

@router.delete("/files/{file_id}")
async def delete_file(
    file_id: str,
    current_user: UserResponse = Depends(get_current_user)
):
    """删除文件"""
    try:
        # 查找并删除文件
        result = await md_files_collection.delete_one({
            "_id": ObjectId(file_id),
            "user_id": current_user.id
        })
        
        if result.deleted_count == 0:
            raise HTTPException(status_code=404, detail="文件不存在")
        
        return {"message": "文件删除成功"}
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"删除文件失败: {str(e)}")

@router.get("/files/{file_id}/content")
async def get_file_content(
    file_id: str,
    current_user: UserResponse = Depends(get_current_user)
):
    """获取文件内容"""
    try:
        file_doc = await md_files_collection.find_one({
            "_id": ObjectId(file_id),
            "user_id": current_user.id
        })
        
        if not file_doc:
            raise HTTPException(status_code=404, detail="文件不存在")
        
        return {
            "content": file_doc.get("content", ""),
            "metadata": file_doc.get("metadata", {}),
            "sections": file_doc.get("sections", {}),
            "word_count": file_doc.get("word_count", 0)
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取文件内容失败: {str(e)}")

@router.post("/files/{file_id}/analyze")
async def analyze_file(
    file_id: str,
    analysis_type: str,
    current_user: UserResponse = Depends(get_current_user)
):
    """分析文件内容"""
    try:
        file_doc = await md_files_collection.find_one({
            "_id": ObjectId(file_id),
            "user_id": current_user.id
        })
        
        if not file_doc:
            raise HTTPException(status_code=404, detail="文件不存在")
        
        content = file_doc.get("content", "")
        
        # 执行分析
        analysis_result = await perform_analysis_content(content, analysis_type)
        
        # 保存分析结果
        if file_doc.get("file_type") == "novel" and file_doc.get("novel_id"):
            analysis_filename = MDFileNaming.analysis(file_doc["novel_id"], analysis_type)
            
            # 创建分析报告文档
            analysis_doc = {
                "user_id": current_user.id,
                "filename": analysis_filename,
                "file_type": "analysis",
                "novel_id": file_doc.get("novel_id"),
                "content": analysis_result,
                "file_path": f"/users/{current_user.id}/{analysis_filename}",
                "metadata": {"analysis_type": analysis_type, "source_file_id": file_id},
                "sections": MDFileParser.extract_content_sections(analysis_result),
                "word_count": MDFileParser.get_word_count(analysis_result),
                "tags": [analysis_type, "analysis"],
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            }
            
            await md_files_collection.insert_one(analysis_doc)
        
        return {
            "analysis_type": analysis_type,
            "result": analysis_result,
            "file_id": file_id
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"分析文件失败: {str(e)}")

@router.get("/files/by-novel/{novel_id}")
async def get_files_by_novel(
    novel_id: str,
    current_user: UserResponse = Depends(get_current_user)
):
    """获取小说相关的所有文件"""
    try:
        # 查询小说相关文件
        cursor = md_files_collection.find({
            "user_id": current_user.id,
            "novel_id": novel_id
        })
        
        files = []
        total_word_count = 0
        
        async for file_doc in cursor:
            file_data = {
                "id": str(file_doc["_id"]),
                "name": file_doc.get("filename", ""),
                "type": file_doc.get("file_type", ""),
                "content": file_doc.get("content", ""),
                "path": file_doc.get("file_path", ""),
                "metadata": file_doc.get("metadata", {}),
                "sections": file_doc.get("sections", {}),
                "word_count": file_doc.get("word_count", 0),
                "created_at": file_doc.get("created_at", datetime.utcnow()).isoformat(),
                "updated_at": file_doc.get("updated_at", datetime.utcnow()).isoformat(),
                "tags": file_doc.get("tags", [])
            }
            files.append(file_data)
            total_word_count += file_data["word_count"]
        
        # 按文件类型和创建时间排序
        type_order = {'novel': 0, 'chapter': 1, 'character': 2, 'world': 3, 'plot': 4, 'analysis': 5}
        files.sort(key=lambda x: (type_order.get(x['type'], 999), x['created_at']))
        
        return {
            "files": files,
            "novel_id": novel_id,
            "total_count": len(files),
            "word_count": total_word_count
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取小说文件失败: {str(e)}")

@router.post("/files/generate")
async def generate_file_from_module(
    generation_request: Dict[str, Any],
    current_user: UserResponse = Depends(get_current_user)
):
    """从模块生成文件"""
    try:
        module_type = generation_request.get('module_type')
        novel_id = generation_request.get('novel_id')
        content_data = generation_request.get('content_data', {})
        
        # 根据模块类型生成相应的 MD 文件
        if module_type == 'character':
            filename = MDFileNaming.character(novel_id, content_data.get('name', '未命名角色'))
            content = generate_character_md(content_data)
        elif module_type == 'world':
            filename = MDFileNaming.world(novel_id, content_data.get('name', '未命名世界'))
            content = generate_world_md(content_data)
        elif module_type == 'plot':
            filename = MDFileNaming.plot(novel_id, content_data.get('name', '未命名情节'))
            content = generate_plot_md(content_data)
        else:
            raise HTTPException(status_code=400, detail="不支持的模块类型")
        
        # 解析文件内容
        metadata = MDFileParser.parse_metadata(content)
        sections = MDFileParser.extract_content_sections(content)
        word_count = MDFileParser.get_word_count(content)
        
        # 创建文档
        file_doc = {
            "user_id": current_user.id,
            "filename": filename,
            "file_type": module_type,
            "novel_id": novel_id,
            "content": content,
            "file_path": f"/users/{current_user.id}/{filename}",
            "metadata": metadata,
            "sections": sections,
            "word_count": word_count,
            "tags": content_data.get('tags', [module_type]),
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        # 保存到MongoDB
        result = await md_files_collection.insert_one(file_doc)
        file_doc["_id"] = result.inserted_id
        
        return {
            "id": str(file_doc["_id"]),
            "name": file_doc["filename"],
            "type": file_doc["file_type"],
            "content": file_doc["content"],
            "path": file_doc["file_path"],
            "metadata": file_doc["metadata"],
            "sections": file_doc["sections"],
            "word_count": file_doc["word_count"],
            "created_at": file_doc["created_at"].isoformat(),
            "updated_at": file_doc["updated_at"].isoformat(),
            "tags": file_doc["tags"]
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"生成文件失败: {str(e)}")

# 辅助函数
async def perform_analysis_content(content: str, analysis_type: str) -> str:
    """执行文件内容分析"""
    if analysis_type == "plot":
        return analyze_plot(content)
    elif analysis_type == "character":
        return analyze_character(content)
    elif analysis_type == "style":
        return analyze_style(content)
    elif analysis_type == "structure":
        return analyze_structure(content)
    else:
        return f"# 分析报告\n\n分析类型: {analysis_type}\n\n暂不支持此类型分析"

def analyze_plot(content: str) -> str:
    """情节分析"""
    word_count = MDFileParser.get_word_count(content)
    sections = MDFileParser.extract_content_sections(content)
    
    return f"""# 情节分析报告

## 基本统计
- 总字数: {word_count}
- 段落数: {len(sections)}
- 分析时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## 情节结构
{chr(10).join(f"- {section}" for section in sections.keys())}

## 情节要素
- 开端: {'已识别' if '开端' in content or '开始' in content else '未明确'}
- 发展: {'已识别' if '发展' in content or '过程' in content else '未明确'}
- 高潮: {'已识别' if '高潮' in content or '冲突' in content else '未明确'}
- 结局: {'已识别' if '结局' in content or '结束' in content else '未明确'}

## 建议
- 情节推进节奏{'适中' if 500 <= word_count <= 2000 else '需要调整'}
- 建议增加更多细节描述
- 可以考虑增加人物心理描写
"""

def analyze_character(content: str) -> str:
    """人物分析"""
    return f"""# 人物分析报告

## 人物设定完整性
- 基本信息: {'完整' if '姓名' in content and '年龄' in content else '待完善'}
- 外貌描述: {'已描述' if '外貌' in content or '长相' in content else '待补充'}
- 性格特点: {'已描述' if '性格' in content or '特点' in content else '待补充'}
- 背景故事: {'已描述' if '背景' in content or '经历' in content else '待补充'}

## 人物深度
- 内在动机: {'明确' if '动机' in content or '目标' in content else '需要完善'}
- 成长弧线: {'设定' if '成长' in content or '变化' in content else '需要设计'}
- 人物关系: {'已建立' if '关系' in content else '待建立'}

## 优化建议
- 可以增加更多细节描述
- 建议完善人物的内心世界
- 可以设计更多人物冲突
"""

def analyze_style(content: str) -> str:
    """风格分析"""
    return f"""# 风格分析报告

## 文本特征
- 句式风格: 分析中...
- 用词特点: 分析中...
- 语言风格: 分析中...

## 写作技巧
- 描写手法: 分析中...
- 修辞手法: 分析中...
- 叙述视角: 分析中...

## 风格建议
- 保持一致的文风
- 可以尝试更多修辞手法
- 注意语言的节奏感
"""

def analyze_structure(content: str) -> str:
    """结构分析"""
    sections = MDFileParser.extract_content_sections(content)
    
    return f"""# 结构分析报告

## 文档结构
- 总段落数: {len(sections)}
- 主要章节: {', '.join(list(sections.keys())[:5])}

## 结构完整性
- 开头: {'完整' if any(key in ['简介', '概述', '开头'] for key in sections.keys()) else '待完善'}
- 主体: {'完整' if len(sections) > 2 else '待完善'}
- 结尾: {'完整' if any(key in ['结尾', '总结', '结论'] for key in sections.keys()) else '待完善'}

## 优化建议
- 建议完善文档结构
- 可以增加更多章节
- 注意章节之间的逻辑关系
"""

def generate_character_md(data: Dict[str, Any]) -> str:
    """生成人物设定 MD 文件"""
    name = data.get('name', '未命名角色')
    return f"""# {name}

## 基本信息
- 姓名: {name}
- 性别: {data.get('gender', '')}
- 年龄: {data.get('age', '')}
- 职业: {data.get('profession', '')}

## 外貌特征
{data.get('appearance', '')}

## 性格特点
{data.get('personality', '')}

## 背景故事
{data.get('background', '')}

## 人物关系
{data.get('relationships', '')}

## 标签
{', '.join(data.get('tags', []))}
"""

def generate_world_md(data: Dict[str, Any]) -> str:
    """生成世界构建 MD 文件"""
    name = data.get('name', '未命名世界')
    return f"""# {name}

## 世界设定
- 世界名称: {name}
- 世界类型: {data.get('world_type', '')}
- 时代背景: {data.get('era', '')}
- 地理环境: {data.get('geography', '')}

## 社会结构
{data.get('society', '')}

## 魔法/科技体系
{data.get('magic_tech', '')}

## 历史背景
{data.get('history', '')}

## 重要地点
{data.get('locations', '')}

## 标签
{', '.join(data.get('tags', []))}
"""

def generate_plot_md(data: Dict[str, Any]) -> str:
    """生成情节设定 MD 文件"""
    name = data.get('name', '未命名情节')
    return f"""# {name}

## 情节概述
{data.get('summary', '')}

## 关键事件
{data.get('key_events', '')}

## 人物冲突
{data.get('conflicts', '')}

## 情节发展
{data.get('development', '')}

## 伏笔设置
{data.get('foreshadowing', '')}

## 标签
{', '.join(data.get('tags', []))}
"""
