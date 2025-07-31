import React, { useState, useEffect } from 'react'
import { Layout, Tabs, Row, Col, Typography, Space, Button, message, Tag } from 'antd'
import {
  EditOutlined,
  BookOutlined,
  UserOutlined,
  BarChartOutlined,
  SaveOutlined,
  RobotOutlined
} from '@ant-design/icons'
import { useParams, useNavigate } from 'react-router-dom'
import ChapterEditor from '../components/Writing/ChapterEditor'
import OutlineManager from '../components/Writing/OutlineManager'
import CharacterManager from '../components/Writing/CharacterManager'
import WritingStats from '../components/Writing/WritingStats'
import AIConversationPanel from '../components/AI/AIConversationPanel'
import { useAppStore } from '../store/appStore'
import { useAI } from '../contexts/AIContext'
import type { Chapter } from '../types'

const { Content, Sider } = Layout
const { Title, Text } = Typography

const NovelWorkspace: React.FC = () => {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { projects, currentProject, setCurrentProject, updateProject } = useAppStore()
  const { setProjectContext } = useAI()
  const [activeTab, setActiveTab] = useState('editor')
  const [selectedChapter, setSelectedChapter] = useState<Chapter | null>(null)
  const [siderCollapsed, setSiderCollapsed] = useState(false)

  // 加载小说
  useEffect(() => {
    if (id && projects.length > 0) {
      const project = projects.find(p => p.id === id)
      if (project) {
        setCurrentProject(project)
        // 设置AI上下文到当前小说
        setProjectContext(project.id)
        // 自动选择第一个章节
        if (project.chapters && project.chapters.length > 0) {
          setSelectedChapter(project.chapters[0])
        }
      } else {
        message.error('小说不存在')
        navigate('/projects')
      }
    }
  }, [id, projects, setCurrentProject, setProjectContext, navigate])

  const handleChapterSelect = (chapter: Chapter) => {
    setSelectedChapter(chapter)
    setActiveTab('editor')
    // 更新AI上下文到当前章节
    if (currentProject) {
      setProjectContext(currentProject.id, chapter.id)
    }
  }

  const handleChapterSave = async (content: string) => {
    if (!selectedChapter || !currentProject) return

    const updatedChapter = {
      ...selectedChapter,
      content,
      wordCount: content.replace(/\s+/g, '').length,
      updatedAt: new Date()
    }

    const updatedChapters = currentProject.chapters.map(ch =>
      ch.id === selectedChapter.id ? updatedChapter : ch
    )

    updateProject(currentProject.id, { chapters: updatedChapters })
    setSelectedChapter(updatedChapter)
  }

  const handleContentChange = (content: string) => {
    if (selectedChapter) {
      setSelectedChapter({
        ...selectedChapter,
        content,
        wordCount: content.replace(/\s+/g, '').length
      })
    }
  }

  if (!currentProject) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh' 
      }}>
        <Text>加载中...</Text>
      </div>
    )
  }

  return (
    <Layout style={{ height: '100vh' }}>
      {/* 左侧工具栏 */}
      <Sider
        width={400}
        collapsed={siderCollapsed}
        onCollapse={setSiderCollapsed}
        theme="light"
        style={{
          borderRight: '1px solid #f0f0f0',
          overflow: 'auto'
        }}
      >
        <div style={{ padding: '16px 16px 0' }}>
          <Space direction="vertical" style={{ width: '100%' }}>
            <div>
              <Title level={4} style={{ margin: 0, marginBottom: 8 }}>
                {currentProject.title}
              </Title>
              <Space wrap>
                {Array.isArray(currentProject.genre) ? 
                  currentProject.genre.map((genre, index) => (
                    <Tag key={index} color="blue">{genre}</Tag>
                  )) :
                  <Tag color="blue">{currentProject.genre}</Tag>
                }
              </Space>
            </div>
            
            <Tabs
              activeKey={activeTab}
              onChange={setActiveTab}
              size="small"
              items={[
                {
                  key: 'outline',
                  label: (
                    <span>
                      <BookOutlined />
                      大纲
                    </span>
                  ),
                  children: (
                    <OutlineManager
                      projectId={currentProject.id}
                      onChapterSelect={handleChapterSelect}
                    />
                  )
                },
                {
                  key: 'characters',
                  label: (
                    <span>
                      <UserOutlined />
                      角色
                    </span>
                  ),
                  children: (
                    <CharacterManager projectId={currentProject.id} />
                  )
                },
                {
                  key: 'ai',
                  label: (
                    <span>
                      <RobotOutlined />
                      AI助手
                    </span>
                  ),
                  children: (
                    <AIConversationPanel
                      defaultProject={currentProject.id}
                      defaultChapter={selectedChapter?.id}
                      style={{ height: 'calc(100vh - 200px)', overflow: 'hidden' }}
                    />
                  )
                },
                {
                  key: 'stats',
                  label: (
                    <span>
                      <BarChartOutlined />
                      统计
                    </span>
                  ),
                  children: (
                    <WritingStats
                      wordCount={currentProject.currentWords}
                      targetWords={currentProject.targetWords}
                      sessionTime={0}
                    />
                  )
                }
              ]}
            />
          </Space>
        </div>
      </Sider>

      {/* 主编辑区域 */}
      <Layout>
        <Content style={{ padding: 0, overflow: 'hidden' }}>
          {selectedChapter ? (
            <div style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
              {/* 章节标题栏 */}
              <div style={{
                padding: '16px 24px',
                borderBottom: '1px solid #f0f0f0',
                background: '#fff'
              }}>
                <Row justify="space-between" align="middle">
                  <Col>
                    <Space>
                      <EditOutlined />
                      <Title level={4} style={{ margin: 0 }}>
                        {selectedChapter.title}
                      </Title>
                      <Text type="secondary">
                        {selectedChapter.wordCount || 0} 字
                      </Text>
                    </Space>
                  </Col>
                  <Col>
                    <Button
                      type="primary"
                      icon={<SaveOutlined />}
                      onClick={() => handleChapterSave(selectedChapter.content)}
                    >
                      保存
                    </Button>
                  </Col>
                </Row>
              </div>

              {/* 编辑器 */}
              <div style={{ flex: 1, padding: '24px' }}>
                <ChapterEditor
                  chapterId={selectedChapter.id}
                  projectId={currentProject.id}
                  initialContent={selectedChapter.content}
                  onSave={handleChapterSave}
                  onContentChange={handleContentChange}
                />
              </div>
            </div>
          ) : (
            <div style={{
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'center',
              alignItems: 'center',
              height: '100%',
              color: '#999'
            }}>
              <BookOutlined style={{ fontSize: 64, marginBottom: 16 }} />
              <Title level={3} style={{ color: '#999' }}>
                选择一个章节开始写作
              </Title>
              <Text>
                在左侧大纲中选择章节，或者创建新的章节
              </Text>
            </div>
          )}
        </Content>
      </Layout>
    </Layout>
  )
}

export default NovelWorkspace
