import { Router } from 'express';
import { arangoDBService } from '../services/arangoDBService';
import { auth } from '../middleware/auth';

const router = Router();

// RxDB 同步端点的通用处理函数
const createSyncEndpoints = (collectionName: string) => {
  // 拉取同步 - 从 ArangoDB 获取更新的文档
  router.post(`/${collectionName}/pull`, auth, async (req, res) => {
    try {
      const { checkpoint, batchSize = 20 } = req.body;
      const userId = req.user?.id;

      if (!userId) {
        return res.status(401).json({ error: '用户未认证' });
      }

      let documents = [];
      let newCheckpoint = null;

      // 根据集合类型获取文档
      switch (collectionName) {
        case 'users':
          if (checkpoint) {
            // 获取自上次检查点后更新的用户文档
            const userDoc = await arangoDBService.getUserById(userId);
            if (userDoc && new Date(userDoc.updatedAt) > new Date(checkpoint)) {
              documents = [userDoc];
            }
          } else {
            // 初始同步，获取当前用户
            const userDoc = await arangoDBService.getUserById(userId);
            if (userDoc) {
              documents = [userDoc];
            }
          }
          break;

        case 'projects':
          if (checkpoint) {
            // 获取自检查点后更新的项目
            const allProjects = await arangoDBService.getProjectsByUserId(userId);
            documents = allProjects.filter(project => 
              new Date(project.updatedAt) > new Date(checkpoint)
            ).slice(0, batchSize);
          } else {
            // 初始同步
            const allProjects = await arangoDBService.getProjectsByUserId(userId);
            documents = allProjects.slice(0, batchSize);
          }
          break;

        case 'chapters':
          if (checkpoint) {
            // 获取用户所有项目的章节更新
            const userProjects = await arangoDBService.getProjectsByUserId(userId);
            const projectIds = userProjects.map(p => p.id);
            const allChapters = [];
            
            for (const projectId of projectIds) {
              const chapters = await arangoDBService.getChaptersByProjectId(projectId);
              allChapters.push(...chapters);
            }
            
            documents = allChapters.filter(chapter => 
              new Date(chapter.updatedAt) > new Date(checkpoint)
            ).slice(0, batchSize);
          } else {
            // 初始同步
            const userProjects = await arangoDBService.getProjectsByUserId(userId);
            const projectIds = userProjects.map(p => p.id);
            const allChapters = [];
            
            for (const projectId of projectIds) {
              const chapters = await arangoDBService.getChaptersByProjectId(projectId);
              allChapters.push(...chapters);
            }
            
            documents = allChapters.slice(0, batchSize);
          }
          break;

        case 'characters':
          if (checkpoint) {
            // 获取用户所有项目的角色更新
            const userProjects = await arangoDBService.getProjectsByUserId(userId);
            const projectIds = userProjects.map(p => p.id);
            const allCharacters = [];
            
            for (const projectId of projectIds) {
              const characters = await arangoDBService.getCharactersByProjectId(projectId);
              allCharacters.push(...characters);
            }
            
            documents = allCharacters.filter(character => 
              new Date(character.updatedAt) > new Date(checkpoint)
            ).slice(0, batchSize);
          } else {
            // 初始同步
            const userProjects = await arangoDBService.getProjectsByUserId(userId);
            const projectIds = userProjects.map(p => p.id);
            const allCharacters = [];
            
            for (const projectId of projectIds) {
              const characters = await arangoDBService.getCharactersByProjectId(projectId);
              allCharacters.push(...characters);
            }
            
            documents = allCharacters.slice(0, batchSize);
          }
          break;

        case 'worldbuilding':
          // 世界构建元素同步逻辑
          const userProjects = await arangoDBService.getProjectsByUserId(userId);
          const projectIds = userProjects.map(p => p.id);
          const allWorldBuilding = [];
          
          for (const projectId of projectIds) {
            const elements = await arangoDBService.getWorldBuildingByProjectId(projectId);
            allWorldBuilding.push(...elements);
          }
          
          if (checkpoint) {
            documents = allWorldBuilding.filter(element => 
              new Date(element.updatedAt) > new Date(checkpoint)
            ).slice(0, batchSize);
          } else {
            documents = allWorldBuilding.slice(0, batchSize);
          }
          break;

        case 'writing_sessions':
          // 写作会话同步逻辑
          const allSessions = await arangoDBService.getWritingSessionsByUserId(userId);
          
          if (checkpoint) {
            documents = allSessions.filter(session => 
              new Date(session.createdAt) > new Date(checkpoint)
            ).slice(0, batchSize);
          } else {
            documents = allSessions.slice(0, batchSize);
          }
          break;

        case 'writing_goals':
          // 写作目标同步逻辑
          const allGoals = await arangoDBService.getWritingGoalsByUserId(userId);
          
          if (checkpoint) {
            documents = allGoals.filter(goal => 
              new Date(goal.updatedAt) > new Date(checkpoint)
            ).slice(0, batchSize);
          } else {
            documents = allGoals.slice(0, batchSize);
          }
          break;

        default:
          return res.status(400).json({ error: '不支持的集合类型' });
      }

      // 设置新的检查点
      if (documents.length > 0) {
        const latestDoc = documents.reduce((latest, doc) => {
          const docTime = new Date(doc.updatedAt || doc.createdAt);
          const latestTime = new Date(latest.updatedAt || latest.createdAt);
          return docTime > latestTime ? doc : latest;
        });
        newCheckpoint = latestDoc.updatedAt || latestDoc.createdAt;
      }

      res.json({
        documents,
        checkpoint: newCheckpoint
      });
    } catch (error) {
      console.error(`拉取同步错误 (${collectionName}):`, error);
      res.status(500).json({ error: '同步失败' });
    }
  });

  // 推送同步 - 将 RxDB 的更改推送到 ArangoDB
  router.post(`/${collectionName}/push`, auth, async (req, res) => {
    try {
      const { changes } = req.body;
      const userId = req.user?.id;

      if (!userId) {
        return res.status(401).json({ error: '用户未认证' });
      }

      const conflicts = [];

      for (const change of changes) {
        try {
          const { newDocumentState, assumedMasterState } = change;
          
          // 验证文档所有权
          if (newDocumentState.userId && newDocumentState.userId !== userId) {
            conflicts.push({
              ...change,
              error: '无权限修改此文档'
            });
            continue;
          }

          // 根据操作类型处理文档
          switch (collectionName) {
            case 'users':
              if (newDocumentState.id === userId) {
                await arangoDBService.updateUser(userId, newDocumentState);
              }
              break;

            case 'projects':
              if (change.operation === 'INSERT') {
                await arangoDBService.createProject(newDocumentState);
              } else if (change.operation === 'UPDATE') {
                await arangoDBService.updateProject(newDocumentState.id, newDocumentState);
              } else if (change.operation === 'DELETE') {
                await arangoDBService.deleteProject(newDocumentState.id);
              }
              break;

            case 'chapters':
              if (change.operation === 'INSERT') {
                await arangoDBService.createChapter(newDocumentState);
              } else if (change.operation === 'UPDATE') {
                await arangoDBService.updateChapter(newDocumentState.id, newDocumentState);
              } else if (change.operation === 'DELETE') {
                await arangoDBService.deleteChapter(newDocumentState.id);
              }
              break;

            case 'characters':
              if (change.operation === 'INSERT') {
                await arangoDBService.createCharacter(newDocumentState);
              } else if (change.operation === 'UPDATE') {
                await arangoDBService.updateCharacter(newDocumentState.id, newDocumentState);
              } else if (change.operation === 'DELETE') {
                await arangoDBService.deleteCharacter(newDocumentState.id);
              }
              break;

            case 'worldbuilding':
              if (change.operation === 'INSERT') {
                await arangoDBService.createWorldBuilding(newDocumentState);
              } else if (change.operation === 'UPDATE') {
                await arangoDBService.updateWorldBuilding(newDocumentState.id, newDocumentState);
              } else if (change.operation === 'DELETE') {
                await arangoDBService.deleteWorldBuilding(newDocumentState.id);
              }
              break;

            case 'writing_sessions':
              if (change.operation === 'INSERT') {
                await arangoDBService.createWritingSession(newDocumentState);
              }
              break;

            case 'writing_goals':
              if (change.operation === 'INSERT') {
                await arangoDBService.createWritingGoal(newDocumentState);
              } else if (change.operation === 'UPDATE') {
                await arangoDBService.updateWritingGoal(newDocumentState.id, newDocumentState);
              } else if (change.operation === 'DELETE') {
                await arangoDBService.deleteWritingGoal(newDocumentState.id);
              }
              break;
          }
        } catch (error) {
          console.error(`处理变更失败:`, error);
          conflicts.push({
            ...change,
            error: error.message
          });
        }
      }

      res.json({ conflicts });
    } catch (error) {
      console.error(`推送同步错误 (${collectionName}):`, error);
      res.status(500).json({ error: '同步失败' });
    }
  });
};

// 为所有集合创建同步端点
const collections = [
  'users',
  'projects', 
  'chapters',
  'characters',
  'worldbuilding',
  'writing_sessions',
  'writing_goals'
];

collections.forEach(createSyncEndpoints);

// 全局同步状态端点
router.get('/status', auth, async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: '用户未认证' });
    }

    // 获取各集合的统计信息
    const userProjects = await arangoDBService.getProjectsByUserId(userId);
    const projectIds = userProjects.map(p => p.id);
    
    let totalChapters = 0;
    let totalCharacters = 0;
    let totalWorldBuilding = 0;
    
    for (const projectId of projectIds) {
      const chapters = await arangoDBService.getChaptersByProjectId(projectId);
      const characters = await arangoDBService.getCharactersByProjectId(projectId);
      const worldBuilding = await arangoDBService.getWorldBuildingByProjectId(projectId);
      
      totalChapters += chapters.length;
      totalCharacters += characters.length;
      totalWorldBuilding += worldBuilding.length;
    }

    const sessions = await arangoDBService.getWritingSessionsByUserId(userId);
    const goals = await arangoDBService.getWritingGoalsByUserId(userId);

    res.json({
      status: 'online',
      lastSync: new Date().toISOString(),
      collections: {
        projects: userProjects.length,
        chapters: totalChapters,
        characters: totalCharacters,
        worldbuilding: totalWorldBuilding,
        writing_sessions: sessions.length,
        writing_goals: goals.length
      }
    });
  } catch (error) {
    console.error('获取同步状态失败:', error);
    res.status(500).json({ error: '获取状态失败' });
  }
});

// 强制同步端点
router.post('/force', auth, async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: '用户未认证' });
    }

    // 触发强制同步逻辑
    // 这里可以添加清理缓存、重建索引等操作
    
    res.json({
      success: true,
      message: '强制同步完成',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('强制同步失败:', error);
    res.status(500).json({ error: '强制同步失败' });
  }
});

export default router;
