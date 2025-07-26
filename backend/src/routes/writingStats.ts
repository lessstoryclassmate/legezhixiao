import { Router } from 'express';
import { WritingStatsController } from '../controllers/writingStatsController';

const router = Router();

// 实例化控制器
const writingStatsController = new WritingStatsController();

// 写作统计相关路由
router.get('/projects/:projectId/stats/overview', writingStatsController.getWritingOverview);
router.get('/projects/:projectId/stats', writingStatsController.getProjectStats);
router.get('/projects/:projectId/stats/sessions', writingStatsController.getWritingSessions);
router.post('/projects/:projectId/sessions/start', writingStatsController.startWritingSession);
router.post('/sessions/:sessionId/end', writingStatsController.endWritingSession);
router.get('/projects/:projectId/stats/heatmap', writingStatsController.getWritingHeatmap);
router.get('/projects/:projectId/stats/trends', writingStatsController.getWritingTrends);

export default router;
