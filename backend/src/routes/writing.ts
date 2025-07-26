import { Router } from 'express';
import { ChapterController } from '../controllers/chapterController';
import { CharacterController } from '../controllers/characterController';
import { ProjectController } from '../controllers/projectController';
import { WorldBuildingController } from '../controllers/worldBuildingController';

const router = Router();

// 实例化控制器
const chapterController = new ChapterController();
const characterController = new CharacterController();
const projectController = new ProjectController();
const worldBuildingController = new WorldBuildingController();

// 项目相关路由
router.get('/projects', projectController.getProjects);
router.get('/projects/:projectId', projectController.getProjectById);
router.post('/projects', projectController.createProject);
router.put('/projects/:projectId', projectController.updateProject);
router.delete('/projects/:projectId', projectController.deleteProject);
router.get('/projects/:projectId/stats', projectController.getProjectStats);
router.post('/projects/:projectId/backup', projectController.backupProject);
router.post('/projects/restore', projectController.restoreProject);
router.post('/projects/template', projectController.generateProjectTemplate);

// 章节相关路由
router.get('/projects/:projectId/chapters', chapterController.getChaptersByProject);
router.get('/chapters/:chapterId', chapterController.getChapterById);
router.post('/projects/:projectId/chapters', chapterController.createChapter);
router.put('/chapters/:chapterId', chapterController.updateChapterContent);
router.delete('/chapters/:chapterId', chapterController.deleteChapter);
router.post('/chapters/:chapterId/autosave', chapterController.autoSaveChapter);
router.put('/projects/:projectId/chapters/reorder', chapterController.reorderChapters);
router.get('/chapters/:chapterId/stats', chapterController.getChapterStatistics);

// 角色相关路由
router.get('/projects/:projectId/characters', characterController.getCharactersByProject);
router.get('/characters/:characterId', characterController.getCharacterById);
router.post('/projects/:projectId/characters', characterController.createCharacter);
router.put('/characters/:characterId', characterController.updateCharacter);
router.delete('/characters/:characterId', characterController.deleteCharacter);
router.get('/projects/:projectId/characters/relationships', characterController.getCharacterRelationships);
router.post('/projects/:projectId/characters/batch', characterController.batchImportCharacters);
router.get('/projects/:projectId/characters/appearance-stats', characterController.getCharacterAppearanceStats);

// 世界观设定相关路由
router.get('/projects/:projectId/worldbuilding', worldBuildingController.getWorldBuildingsByProject);
router.get('/projects/:projectId/worldbuilding/category/:category', worldBuildingController.getWorldBuildingsByCategory);
router.get('/projects/:projectId/worldbuilding/categories', worldBuildingController.getCategories);
router.get('/worldbuilding/:worldBuildingId', worldBuildingController.getWorldBuildingById);
router.post('/projects/:projectId/worldbuilding', worldBuildingController.createWorldBuilding);
router.put('/worldbuilding/:worldBuildingId', worldBuildingController.updateWorldBuilding);
router.delete('/worldbuilding/:worldBuildingId', worldBuildingController.deleteWorldBuilding);
router.post('/projects/:projectId/worldbuilding/batch', worldBuildingController.batchCreateWorldBuilding);
router.get('/projects/:projectId/worldbuilding/search', worldBuildingController.searchWorldBuilding);
router.get('/projects/:projectId/worldbuilding/export', worldBuildingController.exportWorldBuilding);

export default router;
