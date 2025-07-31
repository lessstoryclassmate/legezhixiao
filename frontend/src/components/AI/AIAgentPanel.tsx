import React, { useState, useEffect, useRef } from 'react'
import { 
  Card, 
  Button, 
  Input, 
  List, 
  Avatar, 
  Tag, 
  Spin, 
  Space, 
  Divider, 
  Tooltip, 
  Timeline, 
  Collapse,
  Typography,
  Alert,
  Tabs,
  Progress,
  Statistic,
  Row,
  Col,
  notification
} from 'antd'
import { 
  SendOutlined, 
  UserOutlined, 
  RobotOutlined, 
  BulbOutlined,
  HistoryOutlined,
  ClearOutlined,
  SettingOutlined,
  ThunderboltOutlined,
  ClockCircleOutlined,
  CheckCircleOutlined,
  ExclamationCircleOutlined,
  LoadingOutlined,
  EyeOutlined,
  EyeInvisibleOutlined,
  BarChartOutlined,
  EditOutlined,
  PaperClipOutlined,
  EnvironmentOutlined,
  BookOutlined,
  FireOutlined,
  TrophyOutlined,
  AimOutlined
} from '@ant-design/icons'
import { aiAgentService, AIAgentExecutedAction, AIAgentProcess, AIAgentStep } from '../../services/aiAgentService'
import { useAppStore } from '../../store/appStore'
import UnifiedFileUpload from '../Upload/UnifiedFileUpload'
import './AIAgentPanel.css'

const { TextArea } = Input

interface ConversationMessage {
  id: string
  role: 'user' | 'assistant'
  content: string
  timestamp: Date
  actions?: AIAgentExecutedAction[]
  process?: AIAgentProcess
  loading?: boolean
}

interface WritingStats {
  currentWordCount: number
  totalWordCount: number
  targetWordCount: number
  sessionTime: number
  todayWordCount: number
  weekWordCount: number
  writingStreak: number
  dailyGoal: number
}

interface AISuggestion {
  type: 'plot' | 'character' | 'style' | 'dialog'
  title: string
  content: string
  priority: 'high' | 'medium' | 'low'
}

interface AIAgentPanelProps {
  currentWordCount?: number
  totalWordCount?: number
  targetWordCount?: number
  sessionTime?: number
}

export const AIAgentPanel: React.FC<AIAgentPanelProps> = ({
  currentWordCount = 0,
  totalWordCount = 12500,
  targetWordCount = 50000,
  sessionTime = 45
}) => {
  const [messages, setMessages] = useState<ConversationMessage[]>([])
  const [inputValue, setInputValue] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [suggestions, setSuggestions] = useState<string[]>([])
  const [showProcessDetails, setShowProcessDetails] = useState(true)
  const [activeTab, setActiveTab] = useState('chat')
  const [fileUploadVisible, setFileUploadVisible] = useState(false)
  const messagesEndRef = useRef<HTMLDivElement>(null)

  // 写作统计状态
  const [writingStats, setWritingStats] = useState<WritingStats>({
    currentWordCount,
    totalWordCount,
    targetWordCount,
    sessionTime,
    todayWordCount: 1250,
    weekWordCount: 5800,
    writingStreak: 12,
    dailyGoal: 1000
  })

  // AI建议状态
  const [aiSuggestions, setAiSuggestions] = useState<AISuggestion[]>([
    {
      type: 'plot',
      title: '情节发展建议',
      content: '当前章节可以加入更多冲突元素，增强戏剧张力',
      priority: 'high'
    },
    {
      type: 'character',
      title: '角色发展',
      content: '主角的内心独白可以更深入一些，展现其心理变化',
      priority: 'medium'
    },
    {
      type: 'style',
      title: '写作风格',
      content: '建议增加环境描写，让场景更加生动',
      priority: 'low'
    }
  ])

  const { currentProject, currentChapter, addProject, updateProject, setCurrentProject, setCurrentChapter } = useAppStore()
  const characters = currentProject?.characters || []

  // 更新写作统计当props变化时
  useEffect(() => {
    setWritingStats(prev => ({
      ...prev,
      currentWordCount,
      totalWordCount,
      targetWordCount,
      sessionTime
    }))
  }, [currentWordCount, totalWordCount, targetWordCount, sessionTime])

  useEffect(() => {
    // 更新AI Agent上下文
    aiAgentService.updateContext({
      currentProject: currentProject || undefined,
      currentChapter: currentChapter || undefined,
      currentCharacters: characters
    })
  }, [currentProject, currentChapter, characters])

  useEffect(() => {
    scrollToBottom()
  }, [messages])

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }

  // 同步AI Agent操作结果到全局状态
  const syncAIAgentResultsToStore = (response: any) => {
    if (!response.actions || response.actions.length === 0) return

    response.actions.forEach((action: any) => {
      if (!action.success) return

      switch (action.actionType) {
        case 'create_project':
          if (action.result.project) {
            // 添加新项目到store
            addProject(action.result.project)
            // 设置为当前项目
            setCurrentProject(action.result.project)
          }
          break

        case 'switch_project':
          if (action.result.project) {
            // 切换当前项目
            setCurrentProject(action.result.project)
          }
          break

        case 'create_chapter':
          if (action.result.chapter && currentProject) {
            // 更新项目的章节列表
            const updatedChapters = [...(currentProject.chapters || []), action.result.chapter]
            updateProject(currentProject.id, { chapters: updatedChapters })
            // 设置为当前章节
            setCurrentChapter(action.result.chapter)
          }
          break

        case 'create_character':
          if (action.result.character && currentProject) {
            // 更新项目的角色列表
            const updatedCharacters = [...(currentProject.characters || []), action.result.character]
            updateProject(currentProject.id, { characters: updatedCharacters })
          }
          break

        case 'write_content':
        case 'continue_writing':
          if (action.result && currentChapter && currentProject) {
            // 更新章节内容
            const updatedChapter = {
              ...currentChapter,
              content: action.result.newContent ? 
                currentChapter.content + '\n\n' + action.result.newContent : 
                currentChapter.content + (action.result.content || ''),
              wordCount: action.result.totalWords || currentChapter.wordCount,
              updatedAt: new Date()
            }
            
            // 更新项目中的章节
            const updatedChapters = (currentProject.chapters || []).map(chapter => 
              chapter.id === updatedChapter.id ? updatedChapter : chapter
            )
            updateProject(currentProject.id, { chapters: updatedChapters })
            // 更新当前章节
            setCurrentChapter(updatedChapter)
          }
          break

        default:
          // 其他动作类型的处理
          break
      }
    })

    // 更新AI Agent上下文，确保状态同步
    const updatedContext = aiAgentService.getContext()
    if (updatedContext.currentProject && updatedContext.currentProject !== currentProject) {
      setCurrentProject(updatedContext.currentProject)
    }
    if (updatedContext.currentChapter && updatedContext.currentChapter !== currentChapter) {
      setCurrentChapter(updatedContext.currentChapter)
    }
  }

  const handleSendMessage = async (customMessage?: string) => {
    const messageToSend = customMessage || inputValue
    if (!messageToSend.trim() || isLoading) return

    const userMessage: ConversationMessage = {
      id: `msg_${Date.now()}`,
      role: 'user',
      content: messageToSend,
      timestamp: new Date()
    }

    setMessages(prev => [...prev, userMessage])
    setInputValue('')
    setIsLoading(true)

    try {
      const response = await aiAgentService.processUserInput(inputValue)
      
      const assistantMessage: ConversationMessage = {
        id: `msg_${Date.now() + 1}`,
        role: 'assistant',
        content: response.message,
        timestamp: new Date(),
        actions: response.actions,
        process: response.process
      }

      setMessages(prev => [...prev, assistantMessage])
      setSuggestions(response.suggestions || [])
      
      // 同步AI Agent操作结果到全局状态
      syncAIAgentResultsToStore(response)
    } catch (error) {
      const errorMessage: ConversationMessage = {
        id: `msg_${Date.now() + 1}`,
        role: 'assistant',
        content: `抱歉，处理您的请求时出现了错误：${error instanceof Error ? error.message : '未知错误'}`,
        timestamp: new Date()
      }
      setMessages(prev => [...prev, errorMessage])
    } finally {
      setIsLoading(false)
    }
  }

  const handleSuggestionClick = (suggestion: string) => {
    setInputValue(suggestion)
  }

  const handleClearHistory = () => {
    setMessages([])
    setSuggestions([])
  }

  const handleSyncStatus = () => {
    // 手动同步AI Agent上下文和全局状态
    const agentContext = aiAgentService.getContext()
    
    if (agentContext.currentProject && agentContext.currentProject !== currentProject) {
      setCurrentProject(agentContext.currentProject)
    }
    
    if (agentContext.currentChapter && agentContext.currentChapter !== currentChapter) {
      setCurrentChapter(agentContext.currentChapter)
    }
    
    // 更新AI Agent上下文以确保同步
    aiAgentService.updateContext({
      currentProject: currentProject || undefined,
      currentChapter: currentChapter || undefined,
      currentCharacters: characters
    })
    
    console.log('[AIAgentPanel] 状态已同步')
  }

  const handleFileUploadSuccess = (files: any) => {
    console.log('[AIAgentPanel] 文件上传成功', files)
    
    // 为每个上传的文件自动生成分析提示
    if (Array.isArray(files)) {
      files.forEach((file: any, index: number) => {
        const prompt = `请分析这个文件"${file.fileName}"的内容：

文件信息：
- 文件名：${file.fileName}
- 文件大小：${file.fileSize}字节
- 分析时间：${file.analyzedAt}
${file.chapterCount ? `- 章节数量：${file.chapterCount}章` : ''}
${file.wordCount ? `- 字数统计：${file.wordCount}字` : ''}

内容摘要：
${file.content || ''}

请帮我分析这个文件的内容结构、写作风格和潜在的改进建议。`

        // 自动发送分析请求
        setTimeout(() => {
          setInputValue(prompt)
          handleSendMessage(prompt)
        }, index * 1000) // 每个文件间隔1秒发送
      })
    } else {
      // 单文件处理
      const file = files as any
      const prompt = `请分析这个文件"${file.fileName}"的内容：

文件信息：
- 文件名：${file.fileName}
- 文件大小：${file.fileSize}字节
- 分析时间：${file.analyzedAt}
${file.chapterCount ? `- 章节数量：${file.chapterCount}章` : ''}
${file.wordCount ? `- 字数统计：${file.wordCount}字` : ''}

内容摘要：
${file.content || ''}

请帮我分析这个文件的内容结构、写作风格和潜在的改进建议。`

      setInputValue(prompt)
      handleSendMessage(prompt)
    }
    
    setFileUploadVisible(false)
  }

  const handleFileUploadError = (error: any) => {
    console.error('[AIAgentPanel] 文件上传失败', error)
    notification.error({
      message: '文件上传失败',
      description: error.message || '上传过程中发生错误，请重试',
      duration: 4.5
    })
  }

  const getStepIcon = (step: AIAgentStep) => {
    switch (step.status) {
      case 'pending':
        return <ClockCircleOutlined style={{ color: '#8c8c8c' }} />
      case 'running':
        return <LoadingOutlined style={{ color: '#1890ff' }} />
      case 'completed':
        return <CheckCircleOutlined style={{ color: '#52c41a' }} />
      case 'failed':
        return <ExclamationCircleOutlined style={{ color: '#ff4d4f' }} />
      default:
        return <ClockCircleOutlined style={{ color: '#8c8c8c' }} />
    }
  }

  const getStepStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return '#8c8c8c'
      case 'running': return '#1890ff'
      case 'completed': return '#52c41a'
      case 'failed': return '#ff4d4f'
      default: return '#8c8c8c'
    }
  }

  const renderProcessSteps = (process: AIAgentProcess) => {
    if (!showProcessDetails) return null

    return (
      <div className="process-steps">
        <Divider orientation="left" orientationMargin="0">
          <span style={{ fontSize: '12px', color: '#666' }}>AI执行过程</span>
        </Divider>
        
        <Timeline mode="left" className="ai-process-timeline">
          {process.steps.map((step) => (
            <Timeline.Item
              key={step.id}
              dot={getStepIcon(step)}
              color={getStepStatusColor(step.status)}
            >
              <div className="step-content">
                <div className="step-header">
                  <Typography.Text strong style={{ color: getStepStatusColor(step.status) }}>
                    {step.title}
                  </Typography.Text>
                  <Typography.Text type="secondary" style={{ fontSize: '12px', marginLeft: '8px' }}>
                    {step.timestamp.toLocaleTimeString()}
                    {step.duration && ` (${step.duration}ms)`}
                  </Typography.Text>
                </div>
                <Typography.Text style={{ fontSize: '12px', color: '#666' }}>
                  {step.description}
                </Typography.Text>
                
                {step.details && (
                  <Collapse size="small" ghost style={{ marginTop: '4px' }}>
                    <Collapse.Panel 
                      header="查看详情" 
                      key="details"
                      style={{ fontSize: '11px' }}
                    >
                      <pre style={{ 
                        fontSize: '11px', 
                        backgroundColor: '#f5f5f5', 
                        padding: '8px', 
                        borderRadius: '4px',
                        margin: 0,
                        whiteSpace: 'pre-wrap'
                      }}>
                        {typeof step.details === 'string' 
                          ? step.details 
                          : JSON.stringify(step.details, null, 2)
                        }
                      </pre>
                    </Collapse.Panel>
                  </Collapse>
                )}
                
                {step.error && (
                  <Alert 
                    message="执行错误" 
                    description={step.error}
                    type="error" 
                    style={{ marginTop: '4px', fontSize: '12px' }}
                  />
                )}
              </div>
            </Timeline.Item>
          ))}
        </Timeline>
      </div>
    )
  }

  const renderMessage = (message: ConversationMessage) => {
    const isUser = message.role === 'user'
    
    return (
      <div key={message.id} className={`message ${isUser ? 'user-message' : 'assistant-message'}`}>
        <div className="message-header">
          <Avatar 
            icon={isUser ? <UserOutlined /> : <RobotOutlined />} 
            className={isUser ? 'user-avatar' : 'assistant-avatar'}
          />
          <span className="message-time">
            {message.timestamp.toLocaleTimeString()}
          </span>
        </div>
        <div className="message-content">
          {message.loading ? (
            <Spin size="small" />
          ) : (
            <div className="message-text">{message.content}</div>
          )}
          
          {/* 显示AI执行过程 */}
          {!isUser && message.process && renderProcessSteps(message.process)}
          
          {message.actions && message.actions.length > 0 && (
            <div className="message-actions">
              <Divider orientation="left" orientationMargin="0">
                <span style={{ fontSize: '12px', color: '#666' }}>执行的动作</span>
              </Divider>
              {message.actions.map((action, index) => (
                <Tag 
                  key={index} 
                  color={action.success ? 'green' : 'red'}
                  icon={<ThunderboltOutlined />}
                  className="action-tag"
                >
                  {action.actionType}
                </Tag>
              ))}
            </div>
          )}
        </div>
      </div>
    )
  }

  // 渲染写作统计面板
  const renderWritingStats = () => (
    <div style={{ padding: '16px' }}>
      <Space direction="vertical" style={{ width: '100%' }} size="middle">
        {/* 今日统计 */}
        <Card size="small" title={<><FireOutlined /> 今日写作</>}>
          <Row gutter={16}>
            <Col span={12}>
              <Statistic 
                title="今日字数" 
                value={writingStats.todayWordCount} 
                suffix="字"
                valueStyle={{ color: '#1890ff' }}
              />
            </Col>
            <Col span={12}>
              <Statistic 
                title="写作时长" 
                value={writingStats.sessionTime} 
                suffix="分钟"
                valueStyle={{ color: '#52c41a' }}
              />
            </Col>
          </Row>
          <Progress 
            percent={Math.min((writingStats.todayWordCount / writingStats.dailyGoal) * 100, 100)}
            strokeColor="#1890ff"
            size="small"
            style={{ marginTop: '8px' }}
          />
        </Card>

        {/* 总体进度 */}
        <Card size="small" title={<><AimOutlined /> 写作进度</>}>
          <Row gutter={16}>
            <Col span={12}>
              <Statistic 
                title="总字数" 
                value={writingStats.totalWordCount} 
                suffix="字"
                valueStyle={{ color: '#722ed1' }}
              />
            </Col>
            <Col span={12}>
              <Statistic 
                title="目标字数" 
                value={writingStats.targetWordCount} 
                suffix="字"
                valueStyle={{ color: '#13c2c2' }}
              />
            </Col>
          </Row>
          <Progress 
            percent={Math.min((writingStats.totalWordCount / writingStats.targetWordCount) * 100, 100)}
            strokeColor="#722ed1"
            size="small"
            style={{ marginTop: '8px' }}
          />
        </Card>

        {/* 写作成就 */}
        <Card size="small" title={<><TrophyOutlined /> 写作成就</>}>
          <Row gutter={16}>
            <Col span={12}>
              <Statistic 
                title="连续天数" 
                value={writingStats.writingStreak} 
                suffix="天"
                valueStyle={{ color: '#fa8c16' }}
              />
            </Col>
            <Col span={12}>
              <Statistic 
                title="本周字数" 
                value={writingStats.weekWordCount} 
                suffix="字"
                valueStyle={{ color: '#52c41a' }}
              />
            </Col>
          </Row>
        </Card>
      </Space>
    </div>
  )

  // 渲染AI建议面板
  const renderAISuggestions = () => (
    <div style={{ padding: '16px' }}>
      <Space direction="vertical" style={{ width: '100%' }} size="middle">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography.Text strong>AI写作建议</Typography.Text>
          <Button 
            type="primary" 
            size="small" 
            icon={<RobotOutlined />}
            onClick={() => {
              // 模拟获取新的AI建议
              const newSuggestions: AISuggestion[] = [
                {
                  type: 'plot',
                  title: '情节转折点',
                  content: '考虑在此处加入一个意外事件来推动剧情发展',
                  priority: 'high'
                },
                {
                  type: 'character',
                  title: '角色动机',
                  content: '深入挖掘角色的内在动机，让读者更容易产生共鸣',
                  priority: 'medium'
                }
              ]
              setAiSuggestions(newSuggestions)
            }}
          >
            获取建议
          </Button>
        </div>
        
        <List
          size="small"
          dataSource={aiSuggestions}
          renderItem={item => (
            <List.Item style={{ 
              padding: '12px', 
              background: '#fafafa', 
              marginBottom: '8px', 
              borderRadius: '6px',
              border: '1px solid #f0f0f0'
            }}>
              <Space direction="vertical" style={{ width: '100%' }} size="small">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography.Text strong style={{ fontSize: '13px' }}>{item.title}</Typography.Text>
                  <Tag 
                    color={item.priority === 'high' ? 'red' : item.priority === 'medium' ? 'orange' : 'green'}
                    style={{ fontSize: '10px', margin: 0 }}
                  >
                    {item.priority === 'high' ? '重要' : item.priority === 'medium' ? '中等' : '建议'}
                  </Tag>
                </div>
                <Typography.Text style={{ fontSize: '12px', color: '#666' }}>{item.content}</Typography.Text>
                <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                  <Button type="link" size="small" style={{ padding: 0, fontSize: '11px', height: 'auto' }}>
                    应用建议
                  </Button>
                </div>
              </Space>
            </List.Item>
          )}
        />

        {/* 快速工具 */}
        <Card size="small" title="快速工具">
          <Space wrap>
            <Button size="small" icon={<UserOutlined />}>角色生成</Button>
            <Button size="small" icon={<BookOutlined />}>情节发展</Button>
            <Button size="small" icon={<EnvironmentOutlined />}>场景描述</Button>
            <Button size="small" icon={<EditOutlined />}>对话润色</Button>
          </Space>
        </Card>
      </Space>
    </div>
  )

  // 渲染聊天面板
  const renderChatPanel = () => (
    <div className="ai-agent-content">
      {/* 对话区域 */}
      <div className="conversation-area">
        {messages.length === 0 ? (
          <div className="welcome-message">
            <RobotOutlined style={{ fontSize: '48px', color: '#1890ff', marginBottom: '16px' }} />
            <h3>你好！我是AI写作助手</h3>
            <p>我可以帮助您：</p>
            <ul>
              <li>创建和管理角色</li>
              <li>编写和续写小说内容</li>
              <li>制定故事大纲</li>
              <li>分析和改进文本</li>
              <li>管理项目和章节</li>
            </ul>
            <p>请告诉我您想要做什么！</p>
          </div>
        ) : (
          <div className="messages-list">
            {messages.map((message) => renderMessage(message))}
            <div ref={messagesEndRef} />
          </div>
        )}
        
        {suggestions.length > 0 && (
          <div className="suggestions-area">
            <Divider orientation="left" orientationMargin="0">
              <span style={{ fontSize: '12px', color: '#666' }}>建议操作</span>
            </Divider>
            <div className="suggestions-list">
              {suggestions.map((suggestion, index) => (
                <Tag 
                  key={index}
                  className="suggestion-tag"
                  onClick={() => handleSuggestionClick(suggestion)}
                >
                  {suggestion}
                </Tag>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* 输入区域 */}
      <div className="input-area">
        <TextArea
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          placeholder="请描述您想要做的事情，例如：创建一个名叫张三的主角，或者继续写这一章..."
          autoSize={{ minRows: 2, maxRows: 4 }}
          disabled={isLoading}
          onPressEnter={(e) => {
            if (e.ctrlKey || e.metaKey) {
              handleSendMessage()
            }
          }}
          className="message-input"
        />
        <div className="input-controls">
          <div className="input-tip">
            按 Ctrl+Enter 发送
          </div>
          <Space>
            <Tooltip title="上传文件进行分析">
              <Button
                icon={<PaperClipOutlined />}
                onClick={() => setFileUploadVisible(true)}
                disabled={isLoading}
              />
            </Tooltip>
            <Button
              type="primary"
              icon={<SendOutlined />}
              onClick={() => handleSendMessage()}
              loading={isLoading}
              disabled={!inputValue.trim()}
            >
              发送
            </Button>
          </Space>
        </div>
      </div>
    </div>
  )

  return (
    <Card 
      title={
        <Space>
          <RobotOutlined />
          <span>AI 写作助手</span>
          {currentProject && (
            <Tag color="blue" style={{ marginLeft: 8 }}>
              {currentProject.title}
            </Tag>
          )}
        </Space>
      }
      className="ai-agent-panel"
      extra={
        <Space>
          <Tooltip title={showProcessDetails ? "隐藏执行过程" : "显示执行过程"}>
            <Button 
              icon={showProcessDetails ? <EyeInvisibleOutlined /> : <EyeOutlined />}
              size="small" 
              onClick={() => setShowProcessDetails(!showProcessDetails)}
            />
          </Tooltip>
          <Tooltip title="同步状态">
            <Button 
              icon={<SettingOutlined />} 
              size="small" 
              onClick={handleSyncStatus}
            />
          </Tooltip>
          <Tooltip title="查看使用历史">
            <Button icon={<HistoryOutlined />} size="small" />
          </Tooltip>
          <Tooltip title="清除对话历史">
            <Button 
              icon={<ClearOutlined />} 
              size="small" 
              onClick={handleClearHistory}
            />
          </Tooltip>
          <Tooltip title="设置">
            <Button icon={<SettingOutlined />} size="small" />
          </Tooltip>
        </Space>
      }
    >
      <Tabs 
        activeKey={activeTab} 
        onChange={setActiveTab}
        size="small"
        type="card"
        items={[
          {
            key: 'chat',
            label: (
              <span>
                <RobotOutlined />
                对话
              </span>
            ),
            children: renderChatPanel()
          },
          {
            key: 'stats',
            label: (
              <span>
                <BarChartOutlined />
                统计
              </span>
            ),
            children: renderWritingStats()
          },
          {
            key: 'suggestions',
            label: (
              <span>
                <BulbOutlined />
                建议
              </span>
            ),
            children: renderAISuggestions()
          }
        ]}
      />
      
      {/* 文件上传组件 */}
      <UnifiedFileUpload
        visible={fileUploadVisible}
        onCancel={() => setFileUploadVisible(false)}
        onSuccess={handleFileUploadSuccess}
        onError={handleFileUploadError}
        mode="multiple"
        title="上传文件进行分析"
      />
    </Card>
  )
}
