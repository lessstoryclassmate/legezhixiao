import express from 'express';
import { ProjectController } from '../controllers/projectController';

const router = express.Router();
const projectController = new ProjectController();

// 获取用户的所有项目
router.get('/', projectController.getProjects);

// 创建新项目
router.post('/', projectController.createProject);

// 获取单个项目详情
router.get('/:projectId', projectController.getProjectById);

// 更新项目信息
router.put('/:projectId', projectController.updateProject);

// 删除项目
router.delete('/:projectId', projectController.deleteProject);

export default router;
