import React, { useState, useEffect } from 'react'
import { Card, Row, Col, Button, Space, Tag, Divider, Typography, Modal, Input, message } from 'antd'
import { 
  ThunderboltOutlined, 
  TeamOutlined, 
  PictureOutlined, 
  MessageOutlined,
  GlobalOutlined,
  EditOutlined,
  SearchOutlined,
  BulbOutlined
} from '@ant-design/icons'
import { aiAgentService } from '../../services/aiAgentService'
import { ProjectContentAnalyzer } from '../../services/projectAnalyzer'

const { Title, Paragraph, Text } = Typography
const { TextArea } = Input

interface CreativeToolsManagerProps {
  currentProject?: any
}

interface ToolCategory {
  id: string
  title: string
  icon: React.ReactNode
  color: string
  tools: CreativeTool[]
}

interface CreativeTool {
  id: string
  name: string
  description: string
  examples: string[]
  actionType: string
  requiresParams: boolean
  paramDescription?: string
}

const CreativeToolsManager: React.FC<CreativeToolsManagerProps> = ({ currentProject }) => {
  const [selectedTool, setSelectedTool] = useState<CreativeTool | null>(null)
  const [modalVisible, setModalVisible] = useState(false)
  const [inputValue, setInputValue] = useState('')
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<string>('')
  const [projectAnalysis, setProjectAnalysis] = useState<any>(null)

  // 获取项目分析数据
  useEffect(() => {
    if (currentProject) {
      try {
        const analysis = ProjectContentAnalyzer.analyzeProject(currentProject)
        setProjectAnalysis(analysis)
      } catch (error) {
        console.warn('项目分析失败:', error)
      }
    }
  }, [currentProject])

  const toolCategories: ToolCategory[] = [
    {
      id: 'plot',
      title: '剧情创作工具',
      icon: <ThunderboltOutlined />,
      color: '#722ed1',
      tools: [
        {
          id: 'plot_twist',
          name: '生成剧情转折',
          description: '为当前故事生成意想不到的剧情转折，增加戏剧张力',
          examples: ['生成剧情转折', '来个大反转', '需要意外情节'],
          actionType: 'generate_plot_twist',
          requiresParams: false
        },
        {
          id: 'conflict',
          name: '创建冲突情节',
          description: '设计各种类型的冲突情节（内心/人际/外部/社会）',
          examples: ['创建人际冲突', '设计内心冲突', '需要外部冲突'],
          actionType: 'create_conflict',
          requiresParams: true,
          paramDescription: '请指定冲突类型：内心冲突、人际冲突、外部冲突、社会冲突'
        },
        {
          id: 'subplot',
          name: '创建副线剧情',
          description: '为主线故事添加丰富的副线情节，增加故事层次',
          examples: ['设计爱情副线', '创建复仇支线', '添加友情副线'],
          actionType: 'create_subplot',
          requiresParams: true,
          paramDescription: '请描述副线剧情的主题和涉及角色'
        }
      ]
    },
    {
      id: 'character',
      title: '角色发展工具',
      icon: <TeamOutlined />,
      color: '#eb2f96',
      tools: [
        {
          id: 'character_arc',
          name: '制定角色发展弧线',
          description: '为指定角色设计完整的成长轨迹和发展过程',
          examples: ['为李明制定角色弧线', '设计主角成长轨迹', '完善反派角色发展'],
          actionType: 'develop_character_arc',
          requiresParams: true,
          paramDescription: '请指定要发展的角色名称'
        },
        {
          id: 'backstory',
          name: '生成背景故事',
          description: '为角色、地点、组织等创建详细的背景故事',
          examples: ['为李明生成背景故事', '创建青云派的历史', '设计古战场的来源'],
          actionType: 'generate_backstory',
          requiresParams: true,
          paramDescription: '请指定要创建背景故事的对象（角色/地点/组织）'
        }
      ]
    },
    {
      id: 'scene',
      title: '场景构建工具',
      icon: <PictureOutlined />,
      color: '#13c2c2',
      tools: [
        {
          id: 'scene_description',
          name: '创建场景描述',
          description: '生成生动的场景描写，包括环境、氛围、细节',
          examples: ['创建战斗场景', '描写夜晚森林', '营造宫廷场景'],
          actionType: 'create_scene',
          requiresParams: true,
          paramDescription: '请描述场景类型、氛围和时间'
        },
        {
          id: 'mood_atmosphere',
          name: '营造氛围和情绪',
          description: '通过环境描写营造特定的情绪和氛围',
          examples: ['营造紧张氛围', '创造浪漫情调', '渲染悲伤情绪'],
          actionType: 'create_mood_atmosphere',
          requiresParams: true,
          paramDescription: '请指定要营造的氛围或情绪'
        }
      ]
    },
    {
      id: 'dialogue',
      title: '对话生成工具',
      icon: <MessageOutlined />,
      color: '#52c41a',
      tools: [
        {
          id: 'dialogue_generation',
          name: '生成对话内容',
          description: '为指定角色生成符合性格的对话内容',
          examples: ['生成李明和师父的对话', '创建冲突对话', '设计幽默对话'],
          actionType: 'generate_dialogue',
          requiresParams: true,
          paramDescription: '请指定参与对话的角色和对话情境'
        }
      ]
    },
    {
      id: 'worldbuilding',
      title: '世界设定工具',
      icon: <GlobalOutlined />,
      color: '#1890ff',
      tools: [
        {
          id: 'world_setting',
          name: '完善世界设定',
          description: '详细构建小说的世界观体系',
          examples: ['完善魔法体系设定', '构建宗门文化', '设计政治制度'],
          actionType: 'develop_setting',
          requiresParams: true,
          paramDescription: '请指定要完善的设定类型（地理/文化/政治/魔法体系等）'
        }
      ]
    },
    {
      id: 'writing_skills',
      title: '写作技巧工具',
      icon: <EditOutlined />,
      color: '#fa8c16',
      tools: [
        {
          id: 'polish_prose',
          name: '润色文本',
          description: '提升文本的文学性和可读性',
          examples: ['润色这段文字', '提升文学性', '改善可读性'],
          actionType: 'polish_prose',
          requiresParams: true,
          paramDescription: '请提供需要润色的文本内容'
        },
        {
          id: 'foreshadowing',
          name: '添加伏笔暗示',
          description: '为未来情节设置巧妙的伏笔和暗示',
          examples: ['为大boss出现设置伏笔', '添加身世之谜的暗示', '为重要事件做铺垫'],
          actionType: 'create_foreshadowing',
          requiresParams: true,
          paramDescription: '请描述要为哪个未来事件设置伏笔'
        },
        {
          id: 'theme_development',
          name: '深化主题表达',
          description: '强化小说的主题思想和内涵',
          examples: ['深化成长主题', '强化正义与邪恶的对比', '突出友情主题'],
          actionType: 'develop_theme',
          requiresParams: true,
          paramDescription: '请指定要深化的主题内容'
        }
      ]
    },
    {
      id: 'analysis',
      title: '分析改进工具',
      icon: <SearchOutlined />,
      color: '#f5222d',
      tools: [
        {
          id: 'consistency_check',
          name: '检查前后一致性',
          description: '检查故事的逻辑一致性和设定连贯性',
          examples: ['检查故事一致性', '分析逻辑问题', '验证角色设定'],
          actionType: 'check_consistency',
          requiresParams: false
        },
        {
          id: 'pacing_optimization',
          name: '优化节奏建议',
          description: '分析并优化故事的节奏和结构',
          examples: ['分析故事节奏', '优化情节安排', '调整章节结构'],
          actionType: 'suggest_pacing',
          requiresParams: false
        },
        {
          id: 'chapter_summary',
          name: '生成章节总结',
          description: '为指定章节生成详细的内容总结',
          examples: ['总结第一章内容', '生成章节大纲', '梳理章节要点'],
          actionType: 'generate_chapter_summary',
          requiresParams: true,
          paramDescription: '请指定要总结的章节'
        }
      ]
    }
  ]

  const handleToolClick = (tool: CreativeTool) => {
    setSelectedTool(tool)
    setModalVisible(true)
    setInputValue('')
    setResult('')
  }

  const handleExecuteTool = async () => {
    if (!selectedTool) return

    setLoading(true)
    try {
      let userInput = ''
      
      if (selectedTool.requiresParams && !inputValue.trim()) {
        message.warning('请输入必要的参数信息')
        setLoading(false)
        return
      }

      if (selectedTool.requiresParams) {
        userInput = inputValue.trim()
      } else {
        userInput = selectedTool.name
      }

      const response = await aiAgentService.processUserInput(userInput)
      
      if (response.message) {
        setResult(response.message)
        
        // 显示执行结果中的项目上下文信息
        if (response.actions && response.actions.length > 0) {
          const action = response.actions[0]
          if (action.result && action.result.projectContext) {
            message.success(`工具执行成功！基于${action.result.projectContext.plotStage || '当前进度'}分析生成`)
          } else {
            message.success('工具执行成功！')
          }
        } else {
          message.success('工具执行成功！')
        }
      } else {
        message.error('工具执行失败')
      }
    } catch (error) {
      console.error('执行工具失败:', error)
      message.error('工具执行出错，请稍后重试')
    } finally {
      setLoading(false)
    }
  }

  const renderToolCard = (tool: CreativeTool, categoryColor: string) => (
    <Card
      key={tool.id}
      hoverable
      style={{ 
        marginBottom: 16,
        borderLeft: `4px solid ${categoryColor}`,
        transition: 'all 0.3s ease'
      }}
      bodyStyle={{ padding: '16px 20px' }}
      onClick={() => handleToolClick(tool)}
    >
      <div style={{ marginBottom: 8 }}>
        <Text strong style={{ fontSize: '16px', color: categoryColor }}>
          {tool.name}
        </Text>
        {tool.requiresParams && (
          <Tag color="orange" style={{ marginLeft: 8, fontSize: '12px' }}>
            需要参数
          </Tag>
        )}
      </div>
      <Paragraph style={{ margin: '8px 0', color: '#666', fontSize: '14px' }}>
        {tool.description}
      </Paragraph>
      <div>
        <Text type="secondary" style={{ fontSize: '12px' }}>示例：</Text>
        <div style={{ marginTop: 4 }}>
          {tool.examples.map((example, index) => (
            <Tag key={index} style={{ margin: '2px 4px 2px 0', fontSize: '12px' }}>
              {example}
            </Tag>
          ))}
        </div>
      </div>
    </Card>
  )

  return (
    <div style={{ padding: '24px', background: '#fafafa', minHeight: '100vh' }}>
      <div style={{ marginBottom: 24 }}>
        <Title level={2} style={{ margin: 0, color: '#1890ff' }}>
          <BulbOutlined style={{ marginRight: 8 }} />
          AI创作工具箱
        </Title>
        <Paragraph style={{ margin: '8px 0 0 0', color: '#666' }}>
          15种专业创作工具，助力您的小说创作之路
          {currentProject && (
            <Text type="secondary">
              {' '}• 当前项目：{currentProject.title}
            </Text>
          )}
        </Paragraph>
        
        {/* 项目状态概览 */}
        {currentProject && projectAnalysis && (
          <Card 
            size="small" 
            style={{ 
              marginTop: 16, 
              background: '#f6ffed', 
              border: '1px solid #b7eb8f' 
            }}
          >
            <Row gutter={16}>
              <Col span={6}>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: '18px', fontWeight: 'bold', color: '#52c41a' }}>
                    {projectAnalysis.projectInfo.totalWords}
                  </div>
                  <div style={{ fontSize: '12px', color: '#666' }}>总字数</div>
                </div>
              </Col>
              <Col span={6}>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: '18px', fontWeight: 'bold', color: '#1890ff' }}>
                    {projectAnalysis.projectInfo.chaptersCount}
                  </div>
                  <div style={{ fontSize: '12px', color: '#666' }}>章节数</div>
                </div>
              </Col>
              <Col span={6}>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: '18px', fontWeight: 'bold', color: '#722ed1' }}>
                    {projectAnalysis.projectInfo.charactersCount}
                  </div>
                  <div style={{ fontSize: '12px', color: '#666' }}>角色数</div>
                </div>
              </Col>
              <Col span={6}>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: '12px', fontWeight: 'bold', color: '#fa8c16' }}>
                    {projectAnalysis.chapterAnalysis.plotProgression}
                  </div>
                  <div style={{ fontSize: '12px', color: '#666' }}>进度</div>
                </div>
              </Col>
            </Row>
          </Card>
        )}
      </div>

      <Row gutter={[24, 24]}>
        {toolCategories.map(category => (
          <Col xs={24} lg={12} xl={8} key={category.id}>
            <Card
              title={
                <Space>
                  <span style={{ color: category.color, fontSize: '18px' }}>
                    {category.icon}
                  </span>
                  <span style={{ color: category.color, fontWeight: 600 }}>
                    {category.title}
                  </span>
                  <Tag color={category.color} style={{ fontSize: '12px' }}>
                    {category.tools.length}个工具
                  </Tag>
                </Space>
              }
              style={{ 
                height: '100%',
                border: `1px solid ${category.color}20`,
                borderRadius: '8px'
              }}
              headStyle={{ 
                background: `${category.color}10`,
                borderBottom: `1px solid ${category.color}20`
              }}
              bodyStyle={{ padding: '16px' }}
            >
              {category.tools.map(tool => renderToolCard(tool, category.color))}
            </Card>
          </Col>
        ))}
      </Row>

      <Modal
        title={
          <Space>
            <BulbOutlined style={{ color: '#1890ff' }} />
            <span>{selectedTool?.name}</span>
          </Space>
        }
        open={modalVisible}
        onCancel={() => setModalVisible(false)}
        width={800}
        footer={[
          <Button key="cancel" onClick={() => setModalVisible(false)}>
            取消
          </Button>,
          <Button 
            key="execute" 
            type="primary" 
            loading={loading}
            onClick={handleExecuteTool}
            icon={<ThunderboltOutlined />}
          >
            执行工具
          </Button>
        ]}
      >
        {selectedTool && (
          <div>
            <Paragraph style={{ fontSize: '16px', marginBottom: 16 }}>
              {selectedTool.description}
            </Paragraph>

            <Divider orientation="left">使用示例</Divider>
            <div style={{ marginBottom: 16 }}>
              {selectedTool.examples.map((example, index) => (
                <Tag 
                  key={index} 
                  style={{ 
                    margin: '4px 8px 4px 0', 
                    padding: '4px 8px',
                    cursor: 'pointer'
                  }}
                  onClick={() => setInputValue(example)}
                >
                  {example}
                </Tag>
              ))}
            </div>

            {selectedTool.requiresParams && (
              <>
                <Divider orientation="left">输入参数</Divider>
                <div style={{ marginBottom: 16 }}>
                  <Text type="secondary" style={{ fontSize: '14px', display: 'block', marginBottom: 8 }}>
                    {selectedTool.paramDescription}
                  </Text>
                  <TextArea
                    value={inputValue}
                    onChange={(e) => setInputValue(e.target.value)}
                    placeholder="请输入具体要求..."
                    rows={3}
                    style={{ fontSize: '14px' }}
                  />
                </div>
              </>
            )}

            {result && (
              <>
                <Divider orientation="left">执行结果</Divider>
                <div 
                  style={{ 
                    background: '#f6ffed', 
                    border: '1px solid #b7eb8f',
                    borderRadius: '6px',
                    padding: '16px',
                    whiteSpace: 'pre-wrap',
                    fontSize: '14px',
                    lineHeight: '1.6'
                  }}
                >
                  {result}
                </div>
              </>
            )}
          </div>
        )}
      </Modal>
    </div>
  )
}

export default CreativeToolsManager
