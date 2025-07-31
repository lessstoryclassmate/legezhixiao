import { NovelProject, Character, Chapter, ChapterStatus } from '../types'
import { projectService } from './projectService'
import { ProjectContentAnalyzer } from './projectAnalyzer'
import AIServiceManager from './aiService'
import { knowledgeGraphService, GraphNode, GraphRelationship } from './knowledgeGraphService'

const aiService = AIServiceManager.getInstance()

/**
 * AI Agent 功能模块接口
 */
export interface AIAgentAction {
  type: string
  description: string
  execute: (params: any, context: AIAgentContext) => Promise<any>
  validate?: (params: any) => boolean
}

/**
 * AI Agent 上下文
 */
export interface AIAgentContext {
  currentProject?: NovelProject
  currentChapter?: Chapter
  currentCharacters: Character[]
  userInput: string
  conversationHistory: Array<{
    role: 'user' | 'assistant' | 'system'
    content: string
    timestamp: Date
    actions?: AIAgentExecutedAction[]
  }>
}

/**
 * AI Agent 执行的动作记录
 */
export interface AIAgentExecutedAction {
  actionType: string
  params: any
  result: any
  timestamp: Date
  success: boolean
}

/**
 * AI Agent 执行步骤详情
 */
export interface AIAgentStep {
  id: string
  type: 'thinking' | 'action' | 'result'
  title: string
  description: string
  status: 'pending' | 'running' | 'completed' | 'failed'
  timestamp: Date
  duration?: number
  details?: any
  error?: string
}

/**
 * AI Agent 处理过程
 */
export interface AIAgentProcess {
  id: string
  userInput: string
  steps: AIAgentStep[]
  startTime: Date
  endTime?: Date
  status: 'running' | 'completed' | 'failed'
  finalResult?: string
}

/**
 * AI Agent 响应
 */
export interface AIAgentResponse {
  message: string
  actions: AIAgentExecutedAction[]
  process?: AIAgentProcess
  suggestions?: string[]
  needsUserInput?: boolean
  context: AIAgentContext
}

/**
 * AI Agent 核心服务类
 */
export class AIAgentService {
  private actions: Map<string, AIAgentAction> = new Map()
  private context: AIAgentContext = {
    currentCharacters: [],
    userInput: '',
    conversationHistory: []
  }
  private eventListeners: Map<string, Function[]> = new Map()

  constructor() {
    this.initializeActions()
  }

  /**
   * 初始化所有可用的AI Agent动作
   */
  private initializeActions() {
    // 项目管理动作
    this.registerAction({
      type: 'create_project',
      description: '创建新的小说项目',
      execute: this.createProject.bind(this),
      validate: (params) => params.title && params.genre
    })

    this.registerAction({
      type: 'switch_project',
      description: '切换到指定的项目',
      execute: this.switchProject.bind(this),
      validate: (params) => params.projectId
    })

    // 角色管理动作
    this.registerAction({
      type: 'create_character',
      description: '创建新角色',
      execute: this.createCharacter.bind(this),
      validate: (params) => params.name
    })

    this.registerAction({
      type: 'update_character',
      description: '更新角色信息',
      execute: this.updateCharacter.bind(this),
      validate: (params) => params.characterId
    })

    this.registerAction({
      type: 'list_characters',
      description: '列出当前项目的所有角色',
      execute: this.listCharacters.bind(this)
    })

    // 章节管理动作
    this.registerAction({
      type: 'create_chapter',
      description: '创建新章节',
      execute: this.createChapter.bind(this),
      validate: (params) => params.title
    })

    this.registerAction({
      type: 'write_content',
      description: '为当前章节写入内容',
      execute: this.writeContent.bind(this),
      validate: (params) => params.content
    })

    this.registerAction({
      type: 'continue_writing',
      description: '续写当前章节',
      execute: this.continueWriting.bind(this)
    })

    // 大纲管理动作
    this.registerAction({
      type: 'create_outline',
      description: '创建故事大纲',
      execute: this.createOutline.bind(this),
      validate: (params) => params.outline
    })

    this.registerAction({
      type: 'update_outline',
      description: '更新故事大纲',
      execute: this.updateOutline.bind(this),
      validate: (params) => params.chapterNumber && params.outline
    })

    // 世界观管理动作
    this.registerAction({
      type: 'create_world_element',
      description: '创建世界观元素',
      execute: this.createWorldElement.bind(this),
      validate: (params) => params.name && params.type
    })

    // 写作辅助动作
    this.registerAction({
      type: 'analyze_text',
      description: '分析文本内容',
      execute: this.analyzeText.bind(this),
      validate: (params) => params.text
    })

    this.registerAction({
      type: 'suggest_improvements',
      description: '提供写作改进建议',
      execute: this.suggestImprovements.bind(this),
      validate: (params) => params.text
    })

    // 高级创作工具
    this.registerAction({
      type: 'search_knowledge_graph',
      description: '在知识图谱中搜索相关信息',
      execute: this.searchKnowledgeGraph.bind(this),
      validate: (params) => params.query
    })

    this.registerAction({
      type: 'get_character_relationships',
      description: '获取角色关系网络',
      execute: this.getCharacterRelationships.bind(this),
      validate: (params) => params.characterName
    })

    this.registerAction({
      type: 'analyze_plot_connections',
      description: '分析情节连接',
      execute: this.analyzePlotConnections.bind(this)
    })

    this.registerAction({
      type: 'get_world_elements',
      description: '获取世界观元素',
      execute: this.getWorldElements.bind(this),
      validate: (params) => params.elementType
    })

    this.registerAction({
      type: 'create_knowledge_node',
      description: '在知识图谱中创建新节点',
      execute: this.createKnowledgeNode.bind(this),
      validate: (params) => params.name && params.type
    })

    this.registerAction({
      type: 'create_knowledge_relationship',
      description: '在知识图谱中创建关系',
      execute: this.createKnowledgeRelationship.bind(this),
      validate: (params) => params.startNode && params.endNode && params.relationshipType
    })

    // 原有的高级创作工具
    this.registerAction({
      type: 'generate_plot_twist',
      description: '生成剧情转折',
      execute: this.generatePlotTwist.bind(this)
    })

    this.registerAction({
      type: 'develop_character_arc',
      description: '制定角色发展弧线',
      execute: this.developCharacterArc.bind(this),
      validate: (params) => params.characterId
    })

    this.registerAction({
      type: 'create_scene',
      description: '创建场景描述',
      execute: this.createScene.bind(this),
      validate: (params) => params.sceneType
    })

    this.registerAction({
      type: 'generate_dialogue',
      description: '生成对话内容',
      execute: this.generateDialogue.bind(this),
      validate: (params) => params.characters && params.characters.length >= 2
    })

    this.registerAction({
      type: 'create_conflict',
      description: '创建冲突情节',
      execute: this.createConflict.bind(this),
      validate: (params) => params.conflictType
    })

    this.registerAction({
      type: 'develop_setting',
      description: '完善世界设定',
      execute: this.developSetting.bind(this),
      validate: (params) => params.settingType
    })

    this.registerAction({
      type: 'generate_backstory',
      description: '生成背景故事',
      execute: this.generateBackstory.bind(this),
      validate: (params) => params.target
    })

    this.registerAction({
      type: 'create_subplot',
      description: '创建副线剧情',
      execute: this.createSubplot.bind(this),
      validate: (params) => params.theme
    })

    this.registerAction({
      type: 'polish_prose',
      description: '润色文本',
      execute: this.polishProse.bind(this),
      validate: (params) => params.text
    })

    this.registerAction({
      type: 'check_consistency',
      description: '检查前后一致性',
      execute: this.checkConsistency.bind(this)
    })

    this.registerAction({
      type: 'suggest_pacing',
      description: '优化节奏建议',
      execute: this.suggestPacing.bind(this)
    })

    this.registerAction({
      type: 'create_mood_atmosphere',
      description: '营造氛围和情绪',
      execute: this.createMoodAtmosphere.bind(this),
      validate: (params) => params.mood
    })

    this.registerAction({
      type: 'generate_chapter_summary',
      description: '生成章节总结',
      execute: this.generateChapterSummary.bind(this),
      validate: (params) => params.chapterId
    })

    this.registerAction({
      type: 'create_foreshadowing',
      description: '添加伏笔暗示',
      execute: this.createForeshadowing.bind(this),
      validate: (params) => params.futureEvent
    })

    this.registerAction({
      type: 'develop_theme',
      description: '深化主题表达',
      execute: this.developTheme.bind(this),
      validate: (params) => params.theme
    })
  }

  /**
   * 注册新的AI Agent动作
   */
  registerAction(action: AIAgentAction) {
    this.actions.set(action.type, action)
  }

  /**
   * 更新AI Agent上下文
   */
  updateContext(updates: Partial<AIAgentContext>) {
    this.context = { ...this.context, ...updates }
  }

  /**
   * 处理用户输入并执行相应动作
   */
  async processUserInput(input: string): Promise<AIAgentResponse> {
    this.context.userInput = input
    
    // 创建处理过程记录
    const process: AIAgentProcess = {
      id: `process_${Date.now()}`,
      userInput: input,
      steps: [],
      startTime: new Date(),
      status: 'running'
    }
    
    // 执行相应动作
    const executedActions: AIAgentExecutedAction[] = []
    let responseMessage = ''
    let intent: any = null
    
    try {
      // 步骤1: 分析用户意图
      const thinkingStep: AIAgentStep = {
        id: `step_${Date.now()}_1`,
        type: 'thinking',
        title: '分析用户意图',
        description: '正在理解您的需求并制定执行计划...',
        status: 'running',
        timestamp: new Date()
      }
      process.steps.push(thinkingStep)
      
      const intentStartTime = Date.now()
      intent = await this.analyzeUserIntent(input)
      const intentDuration = Date.now() - intentStartTime
      
      thinkingStep.status = 'completed'
      thinkingStep.duration = intentDuration
      thinkingStep.description = `已识别用户意图，计划执行 ${intent.actions.length} 个动作`
      thinkingStep.details = {
        intentions: intent.actions.map((a: any) => a.type),
        response: intent.response
      }

      // 根据意图执行动作
      for (let i = 0; i < intent.actions.length; i++) {
        const actionPlan = intent.actions[i]
        const action = this.actions.get(actionPlan.type)
        
        // 创建动作步骤
        const actionStep: AIAgentStep = {
          id: `step_${Date.now()}_${i + 2}`,
          type: 'action',
          title: `执行动作: ${actionPlan.type}`,
          description: `正在执行 ${actionPlan.type} 动作...`,
          status: 'running',
          timestamp: new Date(),
          details: actionPlan.params
        }
        process.steps.push(actionStep)
        
        try {
          if (action) {
            if (!action.validate || action.validate(actionPlan.params)) {
              const actionStartTime = Date.now()
              const result = await action.execute(actionPlan.params, this.context)
              const actionDuration = Date.now() - actionStartTime
              
              actionStep.status = 'completed'
              actionStep.duration = actionDuration
              actionStep.description = `成功执行 ${actionPlan.type} 动作`
              
              // 创建结果步骤
              const resultStep: AIAgentStep = {
                id: `step_${Date.now()}_result_${i}`,
                type: 'result',
                title: '执行结果',
                description: `${actionPlan.type} 执行完成`,
                status: 'completed',
                timestamp: new Date(),
                details: result
              }
              process.steps.push(resultStep)
              
              executedActions.push({
                actionType: actionPlan.type,
                params: actionPlan.params,
                result,
                timestamp: new Date(),
                success: true
              })

              // 触发状态变化事件
              this.emit('actionExecuted', {
                actionType: actionPlan.type,
                params: actionPlan.params,
                result,
                context: this.context
              })
            } else {
              actionStep.status = 'failed'
              actionStep.error = '参数验证失败'
              actionStep.description = `${actionPlan.type} 动作参数验证失败`
            }
          } else {
            actionStep.status = 'failed'
            actionStep.error = `未找到动作: ${actionPlan.type}`
            actionStep.description = `未知的动作类型: ${actionPlan.type}`
          }
        } catch (error) {
          actionStep.status = 'failed'
          actionStep.error = error instanceof Error ? error.message : '未知错误'
          actionStep.description = `执行 ${actionPlan.type} 时出错`
        }
      }

      responseMessage = intent.response || '已完成您的请求。'
      process.status = 'completed'
      process.endTime = new Date()
      process.finalResult = responseMessage
      
    } catch (error) {
      responseMessage = `执行过程中出现错误: ${error instanceof Error ? error.message : '未知错误'}`
      process.status = 'failed'
      process.endTime = new Date()
      
      // 添加错误步骤
      const errorStep: AIAgentStep = {
        id: `step_${Date.now()}_error`,
        type: 'result',
        title: '执行错误',
        description: '处理过程中发生错误',
        status: 'failed',
        timestamp: new Date(),
        error: error instanceof Error ? error.message : '未知错误'
      }
      process.steps.push(errorStep)
    }

    // 更新对话历史
    this.context.conversationHistory.push({
      role: 'user',
      content: input,
      timestamp: new Date()
    }, {
      role: 'assistant',
      content: responseMessage,
      timestamp: new Date(),
      actions: executedActions
    })

    return {
      message: responseMessage,
      actions: executedActions,
      process,
      suggestions: intent?.suggestions,
      needsUserInput: intent?.needsUserInput,
      context: this.context
    }
  }

  /**
   * 分析用户意图
   */
  private async analyzeUserIntent(input: string): Promise<{
    actions: Array<{ type: string; params: any }>
    response: string
    suggestions?: string[]
    needsUserInput?: boolean
  }> {
    const prompt = `
作为小说创作AI助手，请分析用户的输入并确定需要执行的动作。

当前上下文:
- 当前项目: ${this.context.currentProject?.title || '无'}
- 当前章节: ${this.context.currentChapter?.title || '无'}
- 已有角色: ${this.context.currentCharacters.map(c => c.name).join(', ') || '无'}

用户输入: "${input}"

可用动作类型:
- create_project: 创建新项目 (参数: title, genre, description)
- create_character: 创建角色 (参数: name, role, personality, background)
- create_chapter: 创建章节 (参数: title, outline)
- write_content: 写入内容 (参数: content)
- continue_writing: 续写内容
- create_outline: 创建大纲 (参数: outline)

高级创作工具:
- generate_plot_twist: 生成剧情转折
- develop_character_arc: 制定角色发展弧线 (参数: characterId)
- create_scene: 创建场景描述 (参数: sceneType, mood, timeOfDay)
- generate_dialogue: 生成对话内容 (参数: characters, situation, tone)
- create_conflict: 创建冲突情节 (参数: conflictType, intensity)
- develop_setting: 完善世界设定 (参数: settingType, scope)
- generate_backstory: 生成背景故事 (参数: target, targetName, timeframe)
- create_subplot: 创建副线剧情 (参数: theme, characters, complexity)
- polish_prose: 润色文本 (参数: text, style, focus)
- check_consistency: 检查前后一致性
- suggest_pacing: 优化节奏建议
- create_mood_atmosphere: 营造氛围和情绪 (参数: mood, setting, intensity)
- generate_chapter_summary: 生成章节总结 (参数: chapterId)
- create_foreshadowing: 添加伏笔暗示 (参数: futureEvent, subtlety, method)
- develop_theme: 深化主题表达 (参数: theme, approach)

请以JSON格式返回:
{
  "actions": [{"type": "action_type", "params": {...}}],
  "response": "回复用户的消息",
  "suggestions": ["建议1", "建议2"],
  "needsUserInput": false
}
`

    try {
      const aiResponse = await aiService.generateResponse({
        message: input,
        context: prompt,
        type: 'general'
      })

      // 尝试解析AI响应为JSON
      const jsonMatch = aiResponse.text.match(/\{[\s\S]*\}/)
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0])
      }
    } catch (error) {
      console.error('分析用户意图失败:', error)
    }

    // 降级处理：简单的关键词匹配
    return this.fallbackIntentAnalysis(input)
  }

  /**
   * 降级意图分析（关键词匹配）
   */
  private fallbackIntentAnalysis(input: string): {
    actions: Array<{ type: string; params: any }>
    response: string
    suggestions?: string[]
  } {
    const lowerInput = input.toLowerCase()
    
    // 项目创建处理
    if ((lowerInput.includes('创建') && (lowerInput.includes('项目') || lowerInput.includes('小说'))) ||
        lowerInput.includes('新建项目') || lowerInput.includes('新建小说')) {
      
      // 尝试从输入中提取标题和类型
      const titleMatch = input.match(/["'《](.*?)["'》]/) || input.match(/标题[：:]\s*([^\s,，]+)/) || input.match(/名字[：:]\s*([^\s,，]+)/)
      const genreMatch = input.match(/类型[：:]\s*([^\s,，]+)/) || input.match(/题材[：:]\s*([^\s,，]+)/)
      
      // 常见类型关键词匹配
      let genre = ''
      if (lowerInput.includes('玄幻')) genre = '玄幻'
      else if (lowerInput.includes('都市')) genre = '都市'
      else if (lowerInput.includes('历史')) genre = '历史'
      else if (lowerInput.includes('科幻')) genre = '科幻'
      else if (lowerInput.includes('武侠')) genre = '武侠'
      else if (lowerInput.includes('悬疑')) genre = '悬疑'
      else if (lowerInput.includes('言情')) genre = '言情'
      else if (lowerInput.includes('青春')) genre = '青春'
      else if (genreMatch) genre = genreMatch[1]
      
      const title = titleMatch ? titleMatch[1] : ''
      
      if (title && genre) {
        return {
          actions: [{ 
            type: 'create_project', 
            params: { 
              title: title,
              genre: genre,
              description: `一部${genre}类型的小说项目`,
              targetWords: 100000,
              author: '作者'
            } 
          }],
          response: `正在创建《${title}》项目（${genre}类型）...`
        }
      } else {
        return {
          actions: [],
          response: '我可以帮您创建新的小说项目。请提供项目标题和类型，例如："创建玄幻小说《仙侠传说》"',
          suggestions: ['创建玄幻小说《修仙之路》', '创建都市小说《都市传奇》', '创建科幻小说《星际争霸》']
        }
      }
    }
    
    if (lowerInput.includes('创建') && lowerInput.includes('角色')) {
      return {
        actions: [],
        response: '我可以帮您创建角色。请提供角色的姓名、性格特点和背景故事。',
        suggestions: ['创建主角', '创建反派', '创建配角']
      }
    }
    
    if (lowerInput.includes('写') || lowerInput.includes('续写')) {
      return {
        actions: [{ type: 'continue_writing', params: {} }],
        response: '正在为您续写内容...'
      }
    }

    // 创作工具关键词匹配
    if (lowerInput.includes('剧情转折') || lowerInput.includes('转折') || lowerInput.includes('反转')) {
      return {
        actions: [{ type: 'generate_plot_twist', params: {} }],
        response: '正在为您生成剧情转折...',
        suggestions: ['生成不同类型的转折', '分析当前剧情', '设计意外情节']
      }
    }

    if (lowerInput.includes('场景') || lowerInput.includes('环境描写')) {
      const sceneType = lowerInput.includes('战斗') ? '战斗场景' : 
                      lowerInput.includes('对话') ? '对话场景' : 
                      lowerInput.includes('风景') ? '风景描写' : '日常场景'
      return {
        actions: [{ type: 'create_scene', params: { sceneType } }],
        response: `正在为您创建${sceneType}...`,
        suggestions: ['调整场景氛围', '添加细节描写', '营造特定情绪']
      }
    }

    if (lowerInput.includes('对话') || lowerInput.includes('台词')) {
      return {
        actions: [],
        response: '我可以帮您生成角色对话。请告诉我哪些角色参与对话，以及对话的情境。',
        suggestions: ['生成冲突对话', '创建情感对话', '设计揭示性对话']
      }
    }

    if (lowerInput.includes('冲突') || lowerInput.includes('矛盾')) {
      const conflictType = lowerInput.includes('内心') ? 'internal' : 
                          lowerInput.includes('人际') ? 'interpersonal' : 'external'
      return {
        actions: [{ type: 'create_conflict', params: { conflictType } }],
        response: '正在为您创建冲突情节...',
        suggestions: ['调整冲突强度', '设计解决方案', '深化角色动机']
      }
    }

    if (lowerInput.includes('世界观') || lowerInput.includes('设定') || lowerInput.includes('背景')) {
      const settingType = lowerInput.includes('地理') ? 'geography' :
                         lowerInput.includes('文化') ? 'culture' :
                         lowerInput.includes('政治') ? 'politics' :
                         lowerInput.includes('魔法') ? 'magic_system' : 'culture'
      return {
        actions: [{ type: 'develop_setting', params: { settingType } }],
        response: '正在完善世界设定...',
        suggestions: ['扩展设定细节', '建立规则体系', '设计历史背景']
      }
    }

    if (lowerInput.includes('润色') || lowerInput.includes('修改') || lowerInput.includes('改进')) {
      return {
        actions: [],
        response: '我可以帮您润色文本。请提供需要润色的内容。',
        suggestions: ['提升文学性', '改善可读性', '调整语言风格']
      }
    }

    if (lowerInput.includes('检查') || lowerInput.includes('一致性') || lowerInput.includes('逻辑')) {
      return {
        actions: [{ type: 'check_consistency', params: {} }],
        response: '正在检查故事的前后一致性...',
        suggestions: ['修复逻辑问题', '完善角色设定', '统一世界观']
      }
    }

    if (lowerInput.includes('节奏') || lowerInput.includes('pacing')) {
      return {
        actions: [{ type: 'suggest_pacing', params: {} }],
        response: '正在分析故事节奏并提供优化建议...',
        suggestions: ['调整情节速度', '重新安排章节', '优化高潮分布']
      }
    }

    if (lowerInput.includes('氛围') || lowerInput.includes('情绪') || lowerInput.includes('mood')) {
      const mood = lowerInput.includes('紧张') ? '紧张' :
                  lowerInput.includes('悲伤') ? '悲伤' :
                  lowerInput.includes('神秘') ? '神秘' :
                  lowerInput.includes('浪漫') ? '浪漫' : '平静'
      return {
        actions: [{ type: 'create_mood_atmosphere', params: { mood } }],
        response: `正在营造${mood}氛围...`,
        suggestions: ['调整氛围强度', '添加感官描写', '运用象征手法']
      }
    }

    if (lowerInput.includes('伏笔') || lowerInput.includes('暗示') || lowerInput.includes('铺垫')) {
      return {
        actions: [],
        response: '我可以帮您设计伏笔。请告诉我要为哪个未来事件做铺垫。',
        suggestions: ['设计巧妙伏笔', '调整隐蔽程度', '增加故事深度']
      }
    }

    if (lowerInput.includes('主题') || lowerInput.includes('寓意') || lowerInput.includes('思想')) {
      return {
        actions: [],
        response: '我可以帮您深化主题表达。请告诉我想要探讨的主题。',
        suggestions: ['强化主题表达', '添加象征元素', '增强思想深度']
      }
    }

    // 知识图谱相关关键词识别
    if (lowerInput.includes('知识图谱') || lowerInput.includes('关系网络') || lowerInput.includes('图谱')) {
      if (lowerInput.includes('搜索') || lowerInput.includes('查找') || lowerInput.includes('检索')) {
        const query = input.replace(/.*?(搜索|查找|检索)\s*/, '').replace(/在?知识图谱中?/, '').trim()
        if (query) {
          return {
            actions: [{ type: 'search_knowledge_graph', params: { query, searchType: 'general' } }],
            response: `正在知识图谱中搜索"${query}"...`,
            suggestions: ['查看搜索结果', '分析相关关系', '应用到当前创作']
          }
        }
      }
      return {
        actions: [],
        response: '我可以帮您操作知识图谱。请告诉我具体需要做什么，比如搜索信息、查看关系、创建节点等。',
        suggestions: ['搜索角色信息', '查看角色关系', '分析情节连接', '获取世界观元素']
      }
    }

    if (lowerInput.includes('角色关系') || lowerInput.includes('人物关系') || lowerInput.includes('关系分析')) {
      const characterMatch = input.match(/["'《](.*?)["'》]/) || input.match(/角色[：:]\s*([^\s,，]+)/) || input.match(/人物[：:]\s*([^\s,，]+)/)
      const characterName = characterMatch ? characterMatch[1] : ''
      
      if (characterName) {
        return {
          actions: [{ type: 'get_character_relationships', params: { characterName } }],
          response: `正在分析"${characterName}"的角色关系网络...`,
          suggestions: ['探索关系动态', '创造冲突情节', '深化关系层次']
        }
      } else {
        return {
          actions: [],
          response: '请告诉我要分析哪个角色的关系，例如："分析李明的角色关系"',
          suggestions: ['指定角色名称', '查看所有角色', '分析主要角色关系']
        }
      }
    }

    if (lowerInput.includes('情节连接') || lowerInput.includes('剧情分析') || lowerInput.includes('情节分析')) {
      return {
        actions: [{ type: 'analyze_plot_connections', params: {} }],
        response: '正在分析情节连接结构...',
        suggestions: ['填补情节空隙', '优化情节节奏', '加强伏笔设置']
      }
    }

    if (lowerInput.includes('世界观') || lowerInput.includes('设定') && (lowerInput.includes('获取') || lowerInput.includes('查看'))) {
      let elementType = 'LOCATION'
      if (lowerInput.includes('地点') || lowerInput.includes('地理') || lowerInput.includes('位置')) {
        elementType = 'LOCATION'
      } else if (lowerInput.includes('组织') || lowerInput.includes('团体') || lowerInput.includes('势力')) {
        elementType = 'ORGANIZATION'
      } else if (lowerInput.includes('概念') || lowerInput.includes('设定')) {
        elementType = 'CONCEPT'
      } else if (lowerInput.includes('主题')) {
        elementType = 'THEME'
      }

      return {
        actions: [{ type: 'get_world_elements', params: { elementType } }],
        response: `正在获取${elementType}相关的世界观元素...`,
        suggestions: ['完善世界观设定', '加强元素关联', '深化独特性']
      }
    }

    if (lowerInput.includes('创建节点') || lowerInput.includes('添加节点') || (lowerInput.includes('创建') && lowerInput.includes('知识'))) {
      return {
        actions: [],
        response: '我可以帮您在知识图谱中创建新节点。请告诉我节点的名称、类型（角色/地点/事件/概念等）和描述。',
        suggestions: ['创建角色节点', '创建地点节点', '创建事件节点', '创建概念节点']
      }
    }

    if (lowerInput.includes('创建关系') || lowerInput.includes('建立关系') || lowerInput.includes('连接')) {
      return {
        actions: [],
        response: '我可以帮您在知识图谱中创建关系。请告诉我要连接的两个节点和关系类型。',
        suggestions: ['建立角色关系', '创建地点关联', '设置事件连接']
      }
    }
    
    return {
      actions: [],
      response: '我理解您的需求，但需要更多具体信息才能执行相应动作。',
      suggestions: [
        '创建新项目', '创建新角色', '继续写作', 
        '生成剧情转折', '创建场景描写', '设计角色对话',
        '营造故事氛围', '检查故事一致性', '润色文本内容',
        '完善世界设定', '添加伏笔暗示', '深化主题表达'
      ]
    }
  }

  // ===== 动作执行方法 =====

  private async createProject(params: any): Promise<any> {
    const projectData = {
      title: params.title,
      description: params.description || '',
      genre: Array.isArray(params.genre) ? params.genre : [params.genre],
      targetWords: params.targetWords || 100000,
      author: params.author || '匿名作者',
      type: 'novel'
    }

    const response = await projectService.createProject(projectData)
    if (response.success) {
      this.context.currentProject = response.data
      return { success: true, project: response.data }
    }
    throw new Error('项目创建失败')
  }

  private async switchProject(params: any): Promise<any> {
    const response = await projectService.getProject(params.projectId)
    if (response.success) {
      this.context.currentProject = response.data
      return { success: true, project: response.data }
    }
    throw new Error('项目切换失败')
  }

  private async createCharacter(params: any): Promise<any> {
    if (!this.context.currentProject) {
      throw new Error('请先选择或创建一个项目')
    }

    // 确定角色类型
    let characterType: any = 'supporting'
    if (params.role === 'main' || params.role === 'protagonist') {
      characterType = 'protagonist'
    } else if (params.role === 'antagonist' || params.role === 'villain') {
      characterType = 'antagonist'
    } else if (params.role === 'supporting') {
      characterType = 'supporting'
    } else if (params.role === 'minor') {
      characterType = 'minor'
    }

    const character: Character = {
      id: `char_${Date.now()}`,
      projectId: this.context.currentProject.id,
      name: params.name,
      type: characterType,
      importance: params.role === 'main' ? 5 : (params.role === 'supporting' ? 3 : 2),
      age: params.age,
      gender: params.gender,
      occupation: params.occupation,
      appearance: params.appearance,
      personality: params.personality || '',
      background: params.background || '',
      relationships: params.relationships || '',
      alias: params.alias,
      avatar: params.avatar,
      createdAt: new Date(),
      updatedAt: new Date()
    }

    try {
      // 调用后端API创建角色
      const response = await fetch(`/api/projects/${character.projectId}/characters`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name: character.name,
          type: character.type,
          importance: character.importance,
          age: character.age,
          gender: character.gender,
          occupation: character.occupation,
          appearance: character.appearance,
          personality: character.personality,
          background: character.background,
          relationships: character.relationships,
          alias: character.alias
        })
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const result = await response.json()
      
      if (result.success) {
        // 更新本地上下文
        this.context.currentCharacters.push(result.data)
        return { success: true, character: result.data }
      } else {
        throw new Error(result.message || '角色创建失败')
      }
    } catch (error) {
      // 如果API调用失败，暂时保存到本地上下文
      console.warn('后端API调用失败，暂时保存到本地:', error)
      this.context.currentCharacters.push(character)
      return { 
        success: true, 
        character,
        warning: '角色已创建，但未能保存到服务器。请检查网络连接。'
      }
    }
  }

  private async updateCharacter(params: any): Promise<any> {
    const characterIndex = this.context.currentCharacters.findIndex(
      c => c.id === params.characterId
    )
    
    if (characterIndex === -1) {
      throw new Error('角色不存在')
    }

    const character = this.context.currentCharacters[characterIndex]
    Object.assign(character, params.updates)
    
    return { success: true, character }
  }

  private async listCharacters(): Promise<any> {
    return {
      success: true,
      characters: this.context.currentCharacters
    }
  }

  private async createChapter(params: any): Promise<any> {
    if (!this.context.currentProject) {
      throw new Error('请先选择或创建一个项目')
    }

    const chapter: Chapter = {
      id: `chapter_${Date.now()}`,
      projectId: this.context.currentProject.id,
      number: (this.context.currentProject.chapters?.length || 0) + 1,
      title: params.title,
      content: params.content || '',
      wordCount: 0,
      status: 'draft' as ChapterStatus,
      aiSuggestions: [],
      createdAt: new Date(),
      updatedAt: new Date()
    }

    // 这里应该调用后端API保存章节
    if (!this.context.currentProject.chapters) {
      this.context.currentProject.chapters = []
    }
    this.context.currentProject.chapters.push(chapter)
    this.context.currentChapter = chapter
    
    return { success: true, chapter }
  }

  private async writeContent(params: any): Promise<any> {
    if (!this.context.currentChapter) {
      throw new Error('请先创建或选择一个章节')
    }

    this.context.currentChapter.content += params.content
    this.context.currentChapter.wordCount = this.context.currentChapter.content.length
    
    return { 
      success: true, 
      content: params.content,
      totalWords: this.context.currentChapter.wordCount
    }
  }

  private async continueWriting(): Promise<any> {
    if (!this.context.currentChapter) {
      throw new Error('请先创建或选择一个章节')
    }

    const prompt = `
请基于以下信息续写小说内容：

项目信息：${this.context.currentProject?.title}
当前章节：${this.context.currentChapter.title}
已有内容：${this.context.currentChapter.content.slice(-500)}

角色信息：
${this.context.currentCharacters.map(c => `${c.name}: ${c.background}`).join('\n')}

请续写200-300字的内容，保持风格一致。
`

    try {
      const aiResponse = await aiService.generateResponse({
        message: prompt,
        type: 'continuation'
      })

      const newContent = aiResponse.text.trim()
      this.context.currentChapter.content += '\n\n' + newContent
      this.context.currentChapter.wordCount = this.context.currentChapter.content.length

      return {
        success: true,
        newContent,
        totalWords: this.context.currentChapter.wordCount
      }
    } catch (error) {
      throw new Error(`续写失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  private async createOutline(params: any): Promise<any> {
    // 实现大纲创建逻辑
    return { success: true, outline: params.outline }
  }

  private async updateOutline(params: any): Promise<any> {
    // 实现大纲更新逻辑
    return { success: true, outline: params.outline }
  }

  private async createWorldElement(params: any): Promise<any> {
    // 实现世界观元素创建逻辑
    return { success: true, element: params }
  }

  private async analyzeText(params: any): Promise<any> {
    try {
      // 使用项目分析器进行基础分析
      const basicAnalysis = await ProjectContentAnalyzer.analyzeProject({
        id: params.projectId || 'temp',
        title: 'Text Analysis',
        author: 'System',
        genre: [],
        description: params.text,
        status: 'draft' as any,
        targetWords: 1000,
        currentWords: params.text?.length || 0,
        characters: [],
        chapters: [],
        worldBuilding: undefined,
        constraints: [],
        createdAt: new Date(),
        updatedAt: new Date()
      })

      // 结合AI分析
      const prompt = `请分析以下文本的写作质量：\n${params.text}`
      const response = await aiService.generateResponse({
        message: prompt,
        type: 'general'
      })

      return { 
        success: true, 
        analysis: response.text,
        projectAnalysis: basicAnalysis 
      }
    } catch (error) {
      // 降级到简单AI分析
      const prompt = `请分析以下文本的写作质量：\n${params.text}`
      const response = await aiService.generateResponse({
        message: prompt,
        type: 'general'
      })
      return { success: true, analysis: response.text }
    }
  }

  private async suggestImprovements(params: any): Promise<any> {
    const prompt = `请为以下文本提供改进建议：\n${params.text}`
    const response = await aiService.generateResponse({
      message: prompt,
      type: 'improvement'
    })
    return { success: true, suggestions: response.text }
  }

  // ===== 高级创作工具方法 =====

  /**
   * 生成剧情转折
   */
  private async generatePlotTwist(): Promise<any> {
    if (!this.context.currentProject) {
      throw new Error('请先选择一个项目')
    }

    // 分析当前项目内容
    const projectAnalysis = ProjectContentAnalyzer.analyzeProject(this.context.currentProject)
    const recentContent = ProjectContentAnalyzer.getRelevantChapterContent(this.context.currentProject.chapters, 3)
    const characterDetails = ProjectContentAnalyzer.getCharacterDetails(this.context.currentProject.characters)
    const worldSummary = ProjectContentAnalyzer.getWorldBuildingSummary(this.context.currentProject.worldBuilding)
    
    const prompt = `
基于当前小说《${this.context.currentProject.title}》的具体内容，生成一个意想不到的剧情转折。

## 项目基本信息
- 小说类型：${this.context.currentProject.genre.join(', ')}
- 简介：${this.context.currentProject.description}
- 当前字数：${projectAnalysis.projectInfo.totalWords}
- 章节数：${projectAnalysis.projectInfo.chaptersCount}

## 最近章节内容
${recentContent}

## 主要角色信息
${characterDetails}

## 世界观设定
${worldSummary}

## 当前情节分析
- 情节进展：${projectAnalysis.chapterAnalysis.plotProgression}
- 写作节奏：${projectAnalysis.chapterAnalysis.pacing}
- 主要主题：${projectAnalysis.chapterAnalysis.themes.join(', ')}
- 主要冲突：${projectAnalysis.plotAnalysis.conflicts.join(', ')}

要求：
1. 转折要基于已有的角色、设定和情节发展
2. 必须符合已建立的世界观和角色性格
3. 要能推动故事向前发展
4. 增加戏剧张力和读者兴趣
5. 考虑当前的情节进展阶段

请生成3个不同的剧情转折选项，每个300-400字，包含：
- 转折的具体内容
- 如何与现有情节衔接
- 对角色发展的影响
- 对后续情节的推动作用
`

    try {
      const response = await aiService.generateResponse({
        message: prompt,
        type: 'general'
      })
      
      return {
        success: true,
        plotTwists: response.text,
        projectContext: {
          recentChapters: projectAnalysis.chapterAnalysis.recentChapters.length,
          mainCharacters: projectAnalysis.characterAnalysis.mainCharacters.length,
          plotStage: projectAnalysis.chapterAnalysis.plotProgression
        },
        suggestions: ['选择转折方案1', '选择转折方案2', '选择转折方案3', '结合多个方案', '重新生成转折']
      }
    } catch (error) {
      throw new Error(`生成剧情转折失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 制定角色发展弧线
   */
  private async developCharacterArc(params: any): Promise<any> {
    if (!this.context.currentProject) {
      throw new Error('请先选择一个项目')
    }

    const character = this.context.currentCharacters.find(c => c.id === params.characterId)
    if (!character) {
      throw new Error('未找到指定角色')
    }

    // 分析项目内容
    const projectAnalysis = ProjectContentAnalyzer.analyzeProject(this.context.currentProject)
    const recentContent = ProjectContentAnalyzer.getRelevantChapterContent(this.context.currentProject.chapters, 3)
    const allCharacters = ProjectContentAnalyzer.getCharacterDetails(this.context.currentProject.characters)
    
    // 获取角色在最近章节中的表现
    const characterMentions = this.context.currentProject.chapters
      .slice(-3)
      .map(ch => ({
        chapter: ch.number,
        mentions: ch.content.includes(character.name) ? '有出场' : '未出场'
      }))

    const prompt = `
为小说《${this.context.currentProject.title}》中的角色"${character.name}"制定详细的角色发展弧线。

## 项目背景
- 小说类型：${this.context.currentProject.genre.join(', ')}
- 当前进度：${projectAnalysis.chapterAnalysis.plotProgression}
- 主要主题：${projectAnalysis.chapterAnalysis.themes.join(', ')}

## 目标角色信息
- 姓名：${character.name}
- 角色类型：${character.type}
- 重要程度：${character.importance}/5
- 性格特点：${character.personality || '待发展'}
- 背景故事：${character.background || '待完善'}
- 人物关系：${character.relationships || '待建立'}

## 其他重要角色
${allCharacters}

## 最近章节中的角色表现
${characterMentions.map(m => `第${m.chapter}章：${m.mentions}`).join('\n')}

## 最近情节发展
${recentContent.substring(0, 800)}

## 当前情节状态
- 主要冲突：${projectAnalysis.plotAnalysis.conflicts.join(', ')}
- 副线情节：${projectAnalysis.plotAnalysis.subplots.join(', ')}
- 待解决问题：${projectAnalysis.plotAnalysis.resolutions.join(', ')}

请制定包含以下阶段的完整角色发展弧线：

1. **当前状态分析**（200字）
   - 角色在故事中的当前位置
   - 现有的性格特点和动机
   - 与其他角色的关系现状

2. **发展目标设定**（200字）
   - 角色需要经历的成长
   - 要克服的内在缺陷或外在障碍
   - 最终要达到的状态

3. **发展路径规划**（300字）
   - 关键转折点和成长节点
   - 重要的经历和挑战
   - 与主线剧情的结合点

4. **角色关系演变**（200字）
   - 与其他角色关系的变化
   - 新关系的建立
   - 冲突的产生和解决

5. **成长收获总结**（200字）
   - 角色获得的能力或品质
   - 对整体故事的贡献
   - 读者可以获得的启发

要求角色弧线要符合：
- 当前的故事进展和世界观设定
- 角色的基本性格和背景
- 整体的故事主题和风格
- 与其他角色的协调发展
`

    try {
      const response = await aiService.generateResponse({
        message: prompt,
        type: 'general'
      })
      
      return {
        success: true,
        characterArc: response.text,
        character: character,
        projectContext: {
          plotStage: projectAnalysis.chapterAnalysis.plotProgression,
          characterRole: character.type,
          relationshipCount: character.relationships ? 1 : 0,
          recentActivity: characterMentions.filter(m => m.mentions === '有出场').length
        },
        suggestions: [
          '完善角色弧线细节', 
          '添加关键转折点', 
          '调整发展节奏',
          '强化角色动机',
          '优化角色关系'
        ]
      }
    } catch (error) {
      throw new Error(`制定角色弧线失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 创建场景描述
   */
  private async createScene(params: any): Promise<any> {
    if (!this.context.currentProject) {
      throw new Error('请先选择一个项目')
    }

    const sceneType = params.sceneType
    const mood = params.mood || '平静'
    const timeOfDay = params.timeOfDay || '白天'
    
    // 分析项目内容
    const projectAnalysis = ProjectContentAnalyzer.analyzeProject(this.context.currentProject)
    const recentContent = ProjectContentAnalyzer.getRelevantChapterContent(this.context.currentProject.chapters, 2)
    const worldSummary = ProjectContentAnalyzer.getWorldBuildingSummary(this.context.currentProject.worldBuilding)
    const characterDetails = ProjectContentAnalyzer.getCharacterDetails(this.context.currentProject.characters.slice(0, 5))

    const prompt = `
为小说《${this.context.currentProject.title}》创建一个${sceneType}场景描述。

## 项目背景信息
- 小说类型：${this.context.currentProject.genre.join(', ')}
- 故事进展：${projectAnalysis.chapterAnalysis.plotProgression}
- 写作风格：${projectAnalysis.styleAnalysis.narrativeStyle}

## 世界观设定
${worldSummary}

## 主要角色
${characterDetails}

## 最近情节发展
${recentContent}

## 场景要求
- 场景类型：${sceneType}
- 氛围要求：${mood}
- 时间设定：${timeOfDay}

## 当前故事状态
- 主要冲突：${projectAnalysis.plotAnalysis.conflicts.join(', ')}
- 情节主题：${projectAnalysis.chapterAnalysis.themes.join(', ')}
- 伏笔线索：${projectAnalysis.plotAnalysis.foreshadowing.join(', ')}

请创建一个生动的场景描述（400-600字），包括：

1. **环境描写**（150-200字）
   - 基于已有世界观的地点设定
   - 符合故事氛围的环境细节
   - 体现${timeOfDay}时间特点的光线和氛围

2. **感官体验**（100-150字）
   - 视觉：色彩、光影、动态变化
   - 听觉：环境音、对话声、特殊音效
   - 嗅觉、触觉：增强现场感的细节

3. **角色互动**（100-150字）
   - 结合在场角色的行为和反应
   - 体现角色性格的动作描写
   - 推进当前情节的对话或行动

4. **情节铺垫**（50-100字）
   - 为后续发展做的暗示
   - 与主线或副线的呼应
   - 氛围营造对读者情绪的引导

要求：
- 严格遵循已建立的世界观设定
- 场景要能自然衔接前后情节
- 体现${mood}的氛围要求
- 为角色发展和情节推进服务
- 保持与整体写作风格的一致性
`

    try {
      const response = await aiService.generateResponse({
        message: prompt,
        type: 'general'
      })
      
      return {
        success: true,
        scene: response.text,
        sceneType: sceneType,
        projectContext: {
          worldElements: worldSummary ? '已设定' : '需完善',
          characterCount: this.context.currentProject.characters.length,
          plotStage: projectAnalysis.chapterAnalysis.plotProgression,
          themeAlignment: projectAnalysis.chapterAnalysis.themes.join(', ')
        },
        suggestions: [
          '调整场景氛围', 
          '增加环境细节', 
          '强化角色互动',
          '添加情节铺垫',
          '完善感官描写'
        ]
      }
    } catch (error) {
      throw new Error(`创建场景失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 生成对话内容
   */
  private async generateDialogue(params: any): Promise<any> {
    // 获取当前项目
    const currentProject = this.context.currentProject;
    if (!currentProject) {
      throw new Error('未找到当前项目');
    }
    
    // 获取项目内容分析
    const projectAnalysis = ProjectContentAnalyzer.analyzeProject(currentProject);
    
    const characters = params.characters
    const situation = params.situation || '日常交流'
    const tone = params.tone || '自然'
    
    // 获取角色详细信息
    const characterDetails = characters.map((charName: string) => {
      const projectChar = currentProject.characters.find(c => c.name === charName);
      const contextChar = this.context.currentCharacters.find(c => c.name === charName);
      const charAnalysis = projectAnalysis.characterAnalysis.characterArcs.find(arc => arc.characterName === charName);
      
      return {
        name: charName,
        personality: projectChar?.personality || contextChar?.personality,
        background: projectChar?.background,
        relationships: projectAnalysis.characterAnalysis.characterRelationships
          .filter(rel => rel.character1 === charName || rel.character2 === charName),
        currentStage: charAnalysis?.currentStage,
        development: charAnalysis?.development
      };
    });
    
    // 获取最近几章的内容
    const recentChapters = projectAnalysis.chapterAnalysis.recentChapters
      .slice(-3)
      .map(chapter => `【${chapter.title}】${chapter.content.slice(-300)}`)
      .join('\n');

    const prompt = `
【项目深度分析对话生成】

项目信息：
- 作品：《${projectAnalysis.projectInfo.title}》
- 类型：${projectAnalysis.projectInfo.genre.join(', ')}
- 当前进度：${projectAnalysis.projectInfo.totalWords}字，${projectAnalysis.projectInfo.chaptersCount}章
- 情节进展：${projectAnalysis.chapterAnalysis.plotProgression}

对话参与者详细分析：
${characterDetails.map((char: any) => `
【${char.name}】
- 性格特征：${char.personality || '待分析'}
- 背景设定：${char.background || '待完善'}
- 角色关系：${char.relationships?.map((r: any) => `${r.character1 === char.name ? r.character2 : r.character1}(${r.relationship})`).join(', ') || '待建立'}
- 发展阶段：${char.currentStage || '发展中'}
- 发展轨迹：${char.development || '待观察'}
`).join('\n')}

对话情境：${situation}
期望语调：${tone}

世界观设定：
- 地理环境：${projectAnalysis.worldAnalysis.geography.join(', ')}
- 文化背景：${projectAnalysis.worldAnalysis.culture.join(', ')}
- 世界规则：${projectAnalysis.worldAnalysis.rules.join(', ')}

最近章节情节：
${recentChapters}

写作风格参考：
- 叙述风格：${projectAnalysis.styleAnalysis.narrativeStyle}
- 句式结构：${projectAnalysis.styleAnalysis.sentenceStructure}
- 词汇复杂度：${projectAnalysis.styleAnalysis.vocabularyComplexity}

主题元素：
${projectAnalysis.chapterAnalysis.themes.join(', ')}

主要情节线：
- 主线：${projectAnalysis.plotAnalysis.mainPlot}
- 支线：${projectAnalysis.plotAnalysis.subplots.join(', ')}
- 当前冲突：${projectAnalysis.plotAnalysis.conflicts.join(', ')}

对话生成要求：
1. 严格符合每个角色的性格特点和说话习惯
2. 体现角色间的具体关系动态
3. 推动当前情节阶段的发展
4. 保持与整体写作风格的一致性
5. 融入世界观设定的细节
6. 体现主题深度
7. 基于角色发展阶段展现内心状态

请生成12-18轮深度对话，包含：
- 符合角色特色的对话内容
- 细腻的动作和神态描写
- 角色内心活动
- 环境氛围渲染
- 情节推进元素
`

    try {
      const response = await aiService.generateResponse({
        message: prompt,
        type: 'general'
      })
      
      return {
        success: true,
        dialogue: response.text,
        characters: characters,
        suggestions: ['调整对话风格', '增加情感冲突', '添加潜台词']
      }
    } catch (error) {
      throw new Error(`生成对话失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 创建冲突情节
   */
  private async createConflict(params: any): Promise<any> {
    // 获取当前项目
    const currentProject = this.context.currentProject;
    if (!currentProject) {
      throw new Error('未找到当前项目');
    }
    
    // 获取项目内容分析
    const projectAnalysis = ProjectContentAnalyzer.analyzeProject(currentProject);
    
    const conflictType = params.conflictType // 'internal', 'interpersonal', 'external', 'societal'
    const intensity = params.intensity || 'medium'
    
    const conflictTypeMap: { [key: string]: string } = {
      'internal': '内心冲突',
      'interpersonal': '人际冲突', 
      'external': '外部冲突',
      'societal': '社会冲突'
    }

    // 分析现有冲突
    const existingConflicts = projectAnalysis.plotAnalysis.conflicts;
    const mainCharacters = projectAnalysis.characterAnalysis.mainCharacters;
    const characterRelationships = projectAnalysis.characterAnalysis.characterRelationships;
    
    // 获取最近章节内容
    const recentContext = projectAnalysis.chapterAnalysis.recentChapters
      .slice(-2)
      .map(chapter => `【${chapter.title}】${chapter.content.slice(-400)}`)
      .join('\n');

    const prompt = `
【项目深度分析冲突创建】

项目信息：
- 作品：《${projectAnalysis.projectInfo.title}》
- 类型：${projectAnalysis.projectInfo.genre.join(', ')}
- 当前进度：${projectAnalysis.plotAnalysis.mainPlot}

冲突设计目标：
- 冲突类型：${conflictTypeMap[conflictType] || conflictType}
- 冲突强度：${intensity}

主要角色分析：
${mainCharacters.map(char => `
【${char.name}】
- 性格特征：${char.personality}
- 角色背景：${char.background}
- 发展阶段：${projectAnalysis.characterAnalysis.characterArcs.find(arc => arc.characterName === char.name)?.currentStage}
- 角色类型：${char.type}(重要性:${char.importance})
`).join('\n')}

角色关系网络：
${characterRelationships.map(rel => `${rel.character1} ↔ ${rel.character2}: ${rel.relationship}`).join('\n')}

已有冲突分析：
${existingConflicts.map((conflict, index) => `${index + 1}. ${conflict}`).join('\n')}

世界观背景：
- 设定环境：${projectAnalysis.worldAnalysis.geography.join(', ')}
- 文化背景：${projectAnalysis.worldAnalysis.culture.join(', ')}
- 世界规则：${projectAnalysis.worldAnalysis.rules.join(', ')}

最近情节发展：
${recentContext}

当前主题：
${projectAnalysis.chapterAnalysis.themes.join(', ')}

冲突创建要求：
1. 基于现有角色关系和性格设计合理冲突
2. 避免与已有冲突重复
3. 符合世界观设定和文化背景
4. 推动主要角色的成长发展
5. 体现作品主题深度
6. 与当前情节进展自然衔接
7. 为后续发展留下合理空间

请设计一个${conflictTypeMap[conflictType] || conflictType}情节（600-800字），包括：

【冲突核心设计】
- 冲突起因和深层原因
- 涉及的主要角色及其立场
- 冲突的独特性和创新点

【冲突发展脉络】
- 冲突爆发的具体场景
- 冲突升级的阶段性发展
- 各方的策略和反应

【角色动机分析】
- 每个参与角色的内在动机
- 角色价值观的碰撞点
- 角色成长的催化作用

【世界观融合】
- 与世界设定的有机结合
- 文化背景的体现
- 环境因素的影响

【解决路径设计】
- 多种可能的解决方向
- 不同选择的后果预测
- 对整体情节的推动作用

确保冲突设计有深度、有张力，能够充分挖掘角色潜力并推动故事向前发展。
`

    try {
      const response = await aiService.generateResponse({
        message: prompt,
        type: 'general'
      })
      
      return {
        success: true,
        conflict: response.text,
        conflictType: conflictType,
        suggestions: ['加强冲突张力', '完善解决方案', '深化角色动机']
      }
    } catch (error) {
      throw new Error(`创建冲突失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 完善世界设定
   */
  private async developSetting(params: any): Promise<any> {
    // 获取当前项目
    const currentProject = this.context.currentProject;
    if (!currentProject) {
      throw new Error('未找到当前项目');
    }
    
    // 获取项目内容分析
    const projectAnalysis = ProjectContentAnalyzer.analyzeProject(currentProject);
    
    const settingType = params.settingType // 'geography', 'culture', 'politics', 'magic_system', 'technology'
    const scope = params.scope || 'detailed'
    
    const settingTypeMap: { [key: string]: string } = {
      'geography': '地理环境',
      'culture': '文化体系',
      'politics': '政治制度', 
      'magic_system': '魔法体系',
      'technology': '科技水平',
      'economy': '经济制度',
      'religion': '宗教信仰'
    }

    // 分析现有世界设定
    const existingSettings = projectAnalysis.worldAnalysis;
    const characterLocations = projectAnalysis.characterAnalysis.mainCharacters
      .map(char => char.background)
      .filter(bg => bg);

    const prompt = `
【项目深度分析世界设定完善】

项目信息：
- 作品：《${projectAnalysis.projectInfo.title}》
- 类型：${projectAnalysis.projectInfo.genre.join(', ')}
- 世界观需求：${settingTypeMap[settingType] || settingType}
- 设定详细程度：${scope}

现有世界设定分析：
【地理环境】${existingSettings.geography.join(', ') || '待完善'}
【文化背景】${existingSettings.culture.join(', ') || '待建立'}
【世界规则】${existingSettings.rules.join(', ') || '待制定'}

角色背景关联：
${characterLocations.join('\n') || '暂无明确地域关联'}

项目基础设定：
${currentProject.description}

主题元素：
${projectAnalysis.chapterAnalysis.themes.join(', ')}

设定完善要求：
1. 基于现有信息进行逻辑扩展
2. 与角色背景和情节发展相协调  
3. 符合作品类型和主题要求
4. 保持内部逻辑一致性
5. 为后续情节发展提供支撑

请详细设计【${settingTypeMap[settingType]}】，包括：
- 核心架构和运作机制
- 形成历史和发展脉络
- 对角色和情节的具体影响
- 独特的细节和规则
- 与其他设定要素的关联

要求输出详细完整的设定文档（800-1000字）。
`

    try {
      const response = await aiService.generateResponse({
        message: prompt,
        type: 'general'
      })
      
      return {
        success: true,
        setting: response.text,
        settingType: settingType,
        suggestions: ['扩展设定细节', '添加相关规则', '完善历史背景']
      }
    } catch (error) {
      throw new Error(`完善世界设定失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 生成背景故事
   */
  private async generateBackstory(params: any): Promise<any> {
    const target = params.target // 'character', 'location', 'organization', 'event'
    const targetName = params.targetName
    const timeframe = params.timeframe || '过去'
    
    const prompt = `
为小说《${this.context.currentProject?.title}》中的${targetName}创建详细的背景故事。

目标类型：${target}
时间框架：${timeframe}

当前相关信息：
${target === 'character' ? 
  this.context.currentCharacters.find(c => c.name === targetName)?.background || '' : 
  ''}

请创建一个引人入胜的背景故事（500-800字），包括：
1. 起源和早期发展
2. 关键事件和转折点
3. 重要人物和关系
4. 对现在故事的影响
5. 隐藏的秘密或未解之谜

确保背景故事与主线情节呼应，为未来发展留下伏笔。
`

    try {
      const response = await aiService.generateResponse({
        message: prompt,
        type: 'general'
      })
      
      return {
        success: true,
        backstory: response.text,
        target: target,
        targetName: targetName,
        suggestions: ['添加更多细节', '关联主线剧情', '设置悬念伏笔']
      }
    } catch (error) {
      throw new Error(`生成背景故事失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 创建副线剧情
   */
  private async createSubplot(params: any): Promise<any> {
    const theme = params.theme
    const characters = params.characters || []
    const complexity = params.complexity || 'medium'
    
    const prompt = `
为小说《${this.context.currentProject?.title}》创建副线剧情。

副线主题：${theme}
涉及角色：${characters.length > 0 ? characters.join(', ') : '次要角色'}
复杂程度：${complexity}

主线情节概要：
${this.context.currentProject?.description || ''}

当前故事进展：
${this.context.currentChapter?.content.slice(-400) || ''}

请设计一个副线剧情（600-800字），包括：
1. 副线的起始契机
2. 发展脉络和关键节点
3. 与主线的交汇点
4. 角色成长和情感发展
5. 副线的解决和收尾

确保副线能丰富故事层次，不与主线冲突。
`

    try {
      const response = await aiService.generateResponse({
        message: prompt,
        type: 'general'
      })
      
      return {
        success: true,
        subplot: response.text,
        theme: theme,
        suggestions: ['完善角色关系', '加强与主线联系', '调整节奏安排']
      }
    } catch (error) {
      throw new Error(`创建副线剧情失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 润色文本
   */
  private async polishProse(params: any): Promise<any> {
    if (!this.context.currentProject) {
      throw new Error('请先选择一个项目')
    }

    const text = params.text
    const style = params.style || 'elegant'
    const focus = params.focus || 'overall'
    
    // 分析项目内容获取写作风格参考
    const projectAnalysis = ProjectContentAnalyzer.analyzeProject(this.context.currentProject)
    const recentContent = ProjectContentAnalyzer.getRelevantChapterContent(this.context.currentProject.chapters, 2)
    
    const prompt = `
请润色以下文本，使其符合小说《${this.context.currentProject.title}》的整体风格。

## 项目背景
- 小说类型：${this.context.currentProject.genre.join(', ')}
- 故事风格：${projectAnalysis.styleAnalysis.narrativeStyle}
- 词汇复杂度：${projectAnalysis.styleAnalysis.vocabularyComplexity}
- 句式特点：${projectAnalysis.styleAnalysis.sentenceStructure}

## 参考文本风格（最近章节）
${recentContent.substring(0, 800)}

## 当前故事氛围
- 故事阶段：${projectAnalysis.chapterAnalysis.plotProgression}
- 主要主题：${projectAnalysis.chapterAnalysis.themes.join(', ')}
- 当前节奏：${projectAnalysis.chapterAnalysis.pacing}

## 待润色文本
${text}

## 润色要求
- 目标文风：${style}
- 重点方向：${focus}
- 字数要求：保持原文长度的80%-120%
- 风格统一：与已有章节保持一致

## 具体润色方向

### 1. 语言美感提升
- 优化词汇选择，使用更加精准和有表现力的词语
- 调整句式结构，增强语言的音韵美和节奏感
- 消除语言表达中的重复和冗余

### 2. 表达准确性
- 确保描述更加生动具体
- 增强情感表达的层次和深度
- 优化人物对话的真实感和个性化

### 3. 叙述节奏
- 调整信息披露的节奏
- 平衡描写与叙述的比例
- 增强文本的可读性和吸引力

### 4. 风格一致性
- 保持与项目整体风格的协调
- 符合当前故事阶段的氛围要求
- 体现角色和情节的特点

请提供：
1. **润色后的文本**（完整版本）
2. **主要改进点说明**（列举3-5个重要修改）
3. **风格特色分析**（说明润色后文本的特点）
4. **进一步优化建议**（如果需要再次润色的方向）

注意：
- 保持原文的核心内容和情节发展
- 不要改变人物对话的基本意思
- 润色要符合${this.context.currentProject.genre.join(', ')}类型小说的特点
`

    try {
      const response = await aiService.generateResponse({
        message: prompt,
        type: 'general'
      })
      
      return {
        success: true,
        polishedText: response.text,
        originalText: text,
        projectContext: {
          genreStyle: this.context.currentProject.genre.join(', '),
          narrativeStyle: projectAnalysis.styleAnalysis.narrativeStyle,
          plotStage: projectAnalysis.chapterAnalysis.plotProgression,
          referenceChapters: this.context.currentProject.chapters.length
        },
        suggestions: [
          '进一步精细润色', 
          '调整文风倾向', 
          '强化情感表达',
          '优化节奏感',
          '检查语法用词',
          '对比原文效果'
        ]
      }
    } catch (error) {
      throw new Error(`润色文本失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 检查前后一致性
   */
  private async checkConsistency(): Promise<any> {
    if (!this.context.currentProject) {
      throw new Error('请先选择一个项目')
    }

    // 分析项目内容
    const projectAnalysis = ProjectContentAnalyzer.analyzeProject(this.context.currentProject)
    const allChaptersContent = this.context.currentProject.chapters
      .map(ch => `第${ch.number}章《${ch.title}》: ${ch.content.substring(0, 500)}...`)
      .join('\n\n')
    const characterDetails = ProjectContentAnalyzer.getCharacterDetails(this.context.currentProject.characters)
    const worldSummary = ProjectContentAnalyzer.getWorldBuildingSummary(this.context.currentProject.worldBuilding)

    const prompt = `
请全面检查小说《${this.context.currentProject.title}》的前后一致性问题。

## 项目基本信息
- 小说类型：${this.context.currentProject.genre.join(', ')}
- 总字数：${projectAnalysis.projectInfo.totalWords}
- 章节数：${projectAnalysis.projectInfo.chaptersCount}
- 角色数：${projectAnalysis.projectInfo.charactersCount}

## 角色设定信息
${characterDetails}

## 世界观设定
${worldSummary}

## 所有章节内容概要
${allChaptersContent.substring(0, 3000)}...

## 需要检查的一致性方面

### 1. 角色设定一致性
请检查以下问题：
- 角色性格在不同章节中是否保持一致
- 角色能力和技能的描述是否前后矛盾
- 角色关系的发展是否合理连贯
- 角色的年龄、外貌描述是否一致

### 2. 世界观规则一致性
请检查以下问题：
- 魔法/科技体系的规则是否统一
- 地理环境和位置关系是否合理
- 社会制度和文化背景是否一致
- 时间线和历史背景是否有矛盾

### 3. 情节逻辑一致性
请检查以下问题：
- 因果关系是否合理
- 角色行为动机是否前后一致
- 重要事件的时间顺序是否正确
- 伏笔和结果是否相互呼应

### 4. 细节描述一致性
请检查以下问题：
- 重要物品的描述是否一致
- 地点的细节描述是否前后统一
- 专有名词的使用是否规范
- 数字信息（时间、距离等）是否准确

## 分析要求
请按以下格式提供详细的一致性检查报告：

**发现的问题**：
1. [具体问题描述]
   - 问题类型：[角色/世界观/情节/细节]
   - 出现章节：第X章
   - 具体表现：[详细说明]
   - 影响程度：[轻微/中等/严重]

**建议修改方案**：
1. [针对问题1的具体修改建议]
2. [针对问题2的具体修改建议]

**优点总结**：
- [项目中做得好的一致性方面]

**整体评价**：
- 一致性等级：[优秀/良好/一般/需改进]
- 主要优势：[简要说明]
- 需要重点关注的方面：[具体建议]
`

    try {
      const response = await aiService.generateResponse({
        message: prompt,
        type: 'general'
      })
      
      return {
        success: true,
        consistencyCheck: response.text,
        projectAnalysis: {
          chaptersAnalyzed: this.context.currentProject.chapters.length,
          charactersAnalyzed: this.context.currentProject.characters.length,
          worldElementsAnalyzed: this.context.currentProject.worldBuilding ? '已分析' : '无世界观数据',
          analysisScope: '全项目深度分析'
        },
        suggestions: [
          '修复一致性问题', 
          '完善角色档案', 
          '建立世界观文档',
          '制作角色关系图',
          '创建时间线图表',
          '定期一致性检查'
        ]
      }
    } catch (error) {
      throw new Error(`检查一致性失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 优化节奏建议
   */
  private async suggestPacing(): Promise<any> {
    const currentChapter = this.context.currentChapter
    const projectChapters = this.context.currentProject?.chapters || []
    
    const prompt = `
分析小说《${this.context.currentProject?.title}》的节奏安排。

当前章节：${currentChapter?.title}
总章节数：${projectChapters.length}
当前字数：${currentChapter?.wordCount || 0}

当前章节内容概要：
${currentChapter?.content.slice(-500) || ''}

请分析节奏问题并提供优化建议：
1. 情节推进速度
2. 张弛有度的安排
3. 高潮低谷的分布
4. 信息披露的时机
5. 角色发展的节奏

提供具体的改进建议和调整方案。
`

    try {
      const response = await aiService.generateResponse({
        message: prompt,
        type: 'general'
      })
      
      return {
        success: true,
        pacingAnalysis: response.text,
        suggestions: ['调整情节节奏', '重新安排章节结构', '优化信息披露']
      }
    } catch (error) {
      throw new Error(`节奏分析失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 营造氛围和情绪
   */
  private async createMoodAtmosphere(params: any): Promise<any> {
    const mood = params.mood
    const setting = params.setting || '当前场景'
    const intensity = params.intensity || 'medium'
    
    const prompt = `
为小说《${this.context.currentProject?.title}》营造${mood}氛围。

目标情绪：${mood}
场景设定：${setting}
强度等级：${intensity}

当前情节背景：
${this.context.currentChapter?.content.slice(-400) || ''}

请创建氛围描写（300-500字），运用：
1. 感官细节描述
2. 环境氛围渲染
3. 情绪传递技巧
4. 象征性元素
5. 节奏和语调控制

确保氛围与情节发展相配合。
`

    try {
      const response = await aiService.generateResponse({
        message: prompt,
        type: 'general'
      })
      
      return {
        success: true,
        atmosphere: response.text,
        mood: mood,
        suggestions: ['增强感官描写', '调整情绪强度', '添加象征元素']
      }
    } catch (error) {
      throw new Error(`营造氛围失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 生成章节总结
   */
  private async generateChapterSummary(params: any): Promise<any> {
    const chapterId = params.chapterId
    const chapter = this.context.currentProject?.chapters?.find(ch => ch.id === chapterId)
    
    if (!chapter) {
      throw new Error('未找到指定章节')
    }
    
    const prompt = `
为小说《${this.context.currentProject?.title}》第${chapter.number}章《${chapter.title}》生成详细总结。

章节内容：
${chapter.content}

请生成包含以下内容的章节总结：
1. 主要情节概述
2. 角色发展和变化
3. 重要对话和场景
4. 伏笔和暗示
5. 与整体故事的关联
6. 本章的主题和意义

总结应该简洁明了，便于后续参考。
`

    try {
      const response = await aiService.generateResponse({
        message: prompt,
        type: 'general'
      })
      
      return {
        success: true,
        summary: response.text,
        chapter: chapter,
        suggestions: ['完善章节大纲', '添加关键词标签', '建立章节索引']
      }
    } catch (error) {
      throw new Error(`生成章节总结失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 添加伏笔暗示
   */
  private async createForeshadowing(params: any): Promise<any> {
    const futureEvent = params.futureEvent
    const subtlety = params.subtlety || 'medium'
    const method = params.method || 'dialogue'
    
    const prompt = `
为小说《${this.context.currentProject?.title}》添加关于"${futureEvent}"的伏笔。

伏笔手法：${method}
隐蔽程度：${subtlety}

当前情节：
${this.context.currentChapter?.content.slice(-400) || ''}

主要角色：${this.context.currentCharacters.map(c => c.name).join(', ')}

请设计巧妙的伏笔（200-400字），要求：
1. 自然融入当前情节
2. 不显突兀或刻意
3. 为未来揭示做铺垫
4. 增加故事深度
5. 可用于后续呼应

提供3种不同的伏笔方案。
`

    try {
      const response = await aiService.generateResponse({
        message: prompt,
        type: 'general'
      })
      
      return {
        success: true,
        foreshadowing: response.text,
        futureEvent: futureEvent,
        suggestions: ['选择伏笔方案', '调整隐蔽程度', '添加更多层次']
      }
    } catch (error) {
      throw new Error(`创建伏笔失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 深化主题表达
   */
  private async developTheme(params: any): Promise<any> {
    const theme = params.theme
    const approach = params.approach || 'symbolic'
    
    const prompt = `
为小说《${this.context.currentProject?.title}》深化"${theme}"主题的表达。

表达方式：${approach}
故事类型：${this.context.currentProject?.genre?.join(', ')}

当前故事发展：
${this.context.currentChapter?.content.slice(-500) || ''}

主要角色：
${this.context.currentCharacters.map(c => `${c.name}: ${c.personality}`).join('\n')}

请提供主题深化方案（400-600字），包括：
1. 主题的具体表现方式
2. 通过角色行为体现主题
3. 情节设计强化主题
4. 象征和隐喻的运用
5. 与读者的情感共鸣

确保主题表达自然而深刻。
`

    try {
      const response = await aiService.generateResponse({
        message: prompt,
        type: 'general'
      })

      return {
        success: true,
        themeExpression: response.text,
        approach: approach,
        suggestions: ['优化表达方式', '增加层次感', '加强情感连接']
      }
    } catch (error) {
      throw new Error(`主题深化失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  // ======================
  // 知识图谱相关方法
  // ======================

  /**
   * 在知识图谱中搜索相关信息
   */
  private async searchKnowledgeGraph(params: any): Promise<any> {
    const isAvailable = await knowledgeGraphService.isAvailable()
    if (!isAvailable) {
      return {
        success: false,
        error: '知识图谱服务未连接',
        suggestion: '知识图谱服务暂时不可用，请检查后端连接'
      }
    }

    try {
      const query = params.query
      const searchType = params.searchType || 'general' // 'character', 'location', 'event', 'general'
      const projectId = this.context.currentProject?.id

      if (!projectId) {
        throw new Error('未选择项目')
      }

      // 根据搜索类型构建不同的查询
      let searchResults: GraphNode[]
      
      if (searchType === 'character') {
        searchResults = await knowledgeGraphService.searchNodes(projectId, 'CHARACTER', query)
      } else if (searchType === 'location') {
        searchResults = await knowledgeGraphService.searchNodes(projectId, 'LOCATION', query)
      } else if (searchType === 'event') {
        searchResults = await knowledgeGraphService.searchNodes(projectId, 'EVENT', query)
      } else {
        // 全文搜索
        searchResults = await knowledgeGraphService.searchNodes(projectId, undefined, query)
      }

      // 分析搜索结果并生成AI建议
      const analysisPrompt = `
基于知识图谱搜索结果，为小说《${this.context.currentProject?.title}》提供创作建议。

搜索查询：${query}
找到的节点：${searchResults.nodes.length}个
找到的关系：${searchResults.relationships.length}个

节点详情：
${searchResults.nodes.map(node => `- ${node.name} (${node.type}): ${node.description}`).join('\n')}

关系详情：
${searchResults.relationships.map(rel => `- ${rel.type}: ${rel.description}`).join('\n')}

请分析这些信息如何在当前创作中使用，并提供具体建议。
`

      const aiResponse = await aiService.generateResponse({
        message: analysisPrompt,
        type: 'general'
      })

      return {
        success: true,
        searchResults: searchResults,
        analysis: aiResponse.text,
        suggestions: [
          '将相关元素融入当前章节',
          '建立新的关系连接',
          '深入探索未开发的角色关系'
        ]
      }
    } catch (error) {
      throw new Error(`知识图谱搜索失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 获取角色关系网络
   */
  private async getCharacterRelationships(params: any): Promise<any> {
    const isAvailable = await knowledgeGraphService.isAvailable()
    if (!isAvailable) {
      return {
        success: false,
        error: '知识图谱服务未连接'
      }
    }

    try {
      const characterName = params.characterName
      const projectId = this.context.currentProject?.id

      if (!projectId) {
        throw new Error('未选择项目')
      }

      // 查找角色节点
      const characterNodes = await knowledgeGraphService.searchNodes(projectId, 'CHARACTER', characterName)
      
      if (characterNodes.length === 0) {
        return {
          success: false,
          error: `未找到角色：${characterName}`,
          suggestion: '请检查角色名称或先在知识图谱中创建该角色'
        }
      }

      const characterNode = characterNodes[0]

      // 获取该角色的所有关系
      const relationships = await knowledgeGraphService.getNodeRelationships(characterNode.id)

      // 分析关系网络
      const analysisPrompt = `
分析角色"${characterName}"的关系网络，为《${this.context.currentProject?.title}》的创作提供建议。

角色信息：
- 名称：${characterNode.name}
- 属性：${JSON.stringify(characterNode.properties, null, 2)}

关系网络：
${relationships.map(rel => 
  `- ${rel.type}：关系属性（${JSON.stringify(rel.properties, null, 2)}）`
).join('\n')}

请分析：
1. 关系网络的复杂度和合理性
2. 可能存在的情节发展机会
3. 关系冲突和张力点
4. 角色发展的可能方向
`

      const aiResponse = await aiService.generateResponse({
        message: analysisPrompt,
        type: 'general'
      })

      return {
        success: true,
        character: characterNode,
        relationships: relationships,
        analysis: aiResponse.text,
        suggestions: [
          '探索未开发的关系动态',
          '创造关系冲突情节',
          '深化现有关系的情感层次'
        ]
      }
    } catch (error) {
      throw new Error(`获取角色关系失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 分析情节连接
   */
  private async analyzePlotConnections(): Promise<any> {
    const isAvailable = await knowledgeGraphService.isAvailable()
    if (!isAvailable) {
      return {
        success: false,
        error: '知识图谱服务未连接'
      }
    }

    try {
      const projectId = this.context.currentProject?.id

      if (!projectId) {
        throw new Error('未选择项目')
      }

      // 获取所有事件节点
      const events = await knowledgeGraphService.searchNodes(projectId, 'EVENT')
      const plotPoints = await knowledgeGraphService.searchNodes(projectId, 'PLOT_POINT')
      
      // 合并事件和情节点
      const allPlotElements = [...events.nodes, ...plotPoints.nodes]
      const allRelationships = [...events.relationships, ...plotPoints.relationships]

      // 分析情节连接
      const analysisPrompt = `
分析小说《${this.context.currentProject?.title}》的情节连接结构。

情节元素（${allPlotElements.length}个）：
${allPlotElements.map(element => `- ${element.name} (${element.type}): ${element.description}`).join('\n')}

情节关系（${allRelationships.length}个）：
${allRelationships.map(rel => `- ${rel.type}: ${rel.description}`).join('\n')}

当前章节：${this.context.currentChapter?.title}

请分析：
1. 情节连接的完整性和逻辑性
2. 可能存在的情节漏洞
3. 伏笔和呼应的设置
4. 情节发展的节奏和张力
5. 建议的情节优化方案
`

      const aiResponse = await aiService.generateResponse({
        message: analysisPrompt,
        type: 'general'
      })

      return {
        success: true,
        plotElements: allPlotElements,
        plotRelationships: allRelationships,
        analysis: aiResponse.text,
        suggestions: [
          '填补情节连接空隙',
          '加强伏笔设置',
          '优化情节节奏',
          '增强情节冲突'
        ]
      }
    } catch (error) {
      throw new Error(`情节连接分析失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 获取世界观元素
   */
  private async getWorldElements(params: any): Promise<any> {
    const isAvailable = await knowledgeGraphService.isAvailable()
    if (!isAvailable) {
      return {
        success: false,
        error: '知识图谱服务未连接'
      }
    }

    try {
      const elementType = params.elementType // 'LOCATION', 'ORGANIZATION', 'CONCEPT', 'THEME'
      const projectId = this.context.currentProject?.id

      if (!projectId) {
        throw new Error('未选择项目')
      }

      // 获取指定类型的世界观元素
      const elements = await knowledgeGraphService.searchNodes(projectId, elementType as any)

      // 生成世界观分析
      const analysisPrompt = `
分析小说《${this.context.currentProject?.title}》的${elementType}元素。

${elementType}元素（${elements.nodes.length}个）：
${elements.nodes.map(element => `- ${element.name}: ${element.description}`).join('\n')}

相关关系：
${elements.relationships.map(rel => `- ${rel.type}: ${rel.description}`).join('\n')}

请分析：
1. 世界观的完整性和一致性
2. 各元素之间的关联性
3. 可能的世界观扩展方向
4. 在当前创作中的应用建议
`

      const aiResponse = await aiService.generateResponse({
        message: analysisPrompt,
        type: 'general'
      })

      return {
        success: true,
        elementType: elementType,
        elements: elements.nodes,
        relationships: elements.relationships,
        analysis: aiResponse.text,
        suggestions: [
          '完善世界观设定',
          '加强元素间的关联',
          '深化世界观的独特性'
        ]
      }
    } catch (error) {
      throw new Error(`获取世界观元素失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 在知识图谱中创建新节点
   */
  private async createKnowledgeNode(params: any): Promise<any> {
    const isAvailable = await knowledgeGraphService.isAvailable()
    if (!isAvailable) {
      return {
        success: false,
        error: '知识图谱服务未连接'
      }
    }

    try {
      const projectId = this.context.currentProject?.id

      if (!projectId) {
        throw new Error('未选择项目')
      }

      const nodeData = {
        type: params.type as GraphNode['type'],
        name: params.name,
        description: params.description || '',
        properties: params.properties || {},
        importance: params.importance || 'MEDIUM' as GraphNode['importance'],
        status: 'ACTIVE' as GraphNode['status'],
        tags: params.tags || [],
        chapterIds: params.chapterIds || [],
        projectId: projectId
      }

      const newNode = await knowledgeGraphService.createNode(nodeData)

      // 如果当前有章节，关联到当前章节
      if (this.context.currentChapter) {
        await knowledgeGraphService.updateNode(newNode.id, {
          ...newNode,
          properties: {
            ...newNode.properties,
            chapterIds: [...(newNode.properties.chapterIds || []), this.context.currentChapter.id]
          }
        })
      }

      return {
        success: true,
        node: newNode,
        message: `成功创建${params.type}节点：${params.name}`,
        suggestions: [
          '为该节点添加关系连接',
          '完善节点描述信息',
          '设置节点重要程度'
        ]
      }
    } catch (error) {
      throw new Error(`创建知识节点失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 在知识图谱中创建关系
   */
  private async createKnowledgeRelationship(params: any): Promise<any> {
    const isAvailable = await knowledgeGraphService.isAvailable()
    if (!isAvailable) {
      return {
        success: false,
        error: '知识图谱服务未连接'
      }
    }

    try {
      const projectId = this.context.currentProject?.id

      if (!projectId) {
        throw new Error('未选择项目')
      }

      // 查找起始和结束节点
      const startNodes = await knowledgeGraphService.searchNodes(projectId, undefined, params.startNode)
      const endNodes = await knowledgeGraphService.searchNodes(projectId, undefined, params.endNode)

      if (startNodes.nodes.length === 0) {
        throw new Error(`未找到起始节点：${params.startNode}`)
      }

      if (endNodes.nodes.length === 0) {
        throw new Error(`未找到结束节点：${params.endNode}`)
      }

      const relationshipData = {
        type: params.relationshipType as GraphRelationship['type'],
        startNodeId: startNodes.nodes[0].id,
        endNodeId: endNodes.nodes[0].id,
        strength: params.strength || 50,
        description: params.description || '',
        properties: params.properties || {},
        bidirectional: params.bidirectional || false,
        startChapter: this.context.currentChapter?.id || '',
        endChapter: '',
        status: 'CURRENT' as GraphRelationship['status']
      }

      const newRelationship = await knowledgeGraphService.createRelationship(relationshipData)

      return {
        success: true,
        relationship: newRelationship,
        message: `成功创建关系：${params.startNode} ${params.relationshipType} ${params.endNode}`,
        suggestions: [
          '调整关系强度',
          '添加关系描述',
          '设置关系的时间范围'
        ]
      }
    } catch (error) {
      throw new Error(`创建关系失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 重新连接知识图谱服务
   */
  async reconnectKnowledgeGraph(): Promise<boolean> {
    try {
      return await knowledgeGraphService.isAvailable()
    } catch (error) {
      console.error('重新连接知识图谱失败:', error)
      return false
    }
  }

  /**
   * 检查知识图谱连接状态
   */
  async isKnowledgeGraphConnected(): Promise<boolean> {
    return await knowledgeGraphService.isAvailable()
  }
      })
      
      return {
        success: true,
        themeExploration: response.text,
        theme: theme,
        suggestions: ['完善主题表达', '添加象征元素', '强化情感共鸣']
      }
    } catch (error) {
      throw new Error(`深化主题失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 获取当前上下文
   */
  getContext(): AIAgentContext {
    return this.context
  }

  /**
   * 获取可用动作列表
   */
  getAvailableActions(): string[] {
    return Array.from(this.actions.keys())
  }

  /**
   * 添加事件监听器
   */
  addEventListener(event: string, listener: Function) {
    if (!this.eventListeners.has(event)) {
      this.eventListeners.set(event, [])
    }
    this.eventListeners.get(event)!.push(listener)
  }

  /**
   * 移除事件监听器
   */
  removeEventListener(event: string, listener: Function) {
    const listeners = this.eventListeners.get(event)
    if (listeners) {
      const index = listeners.indexOf(listener)
      if (index > -1) {
        listeners.splice(index, 1)
      }
    }
  }

  /**
   * 触发事件
   */
  private emit(event: string, data?: any) {
    const listeners = this.eventListeners.get(event)
    if (listeners) {
      listeners.forEach(listener => listener(data))
    }
  }
}

// 创建单例实例
export const aiAgentService = new AIAgentService()
