import { Sequelize } from 'sequelize';
import User from './User';
import Project from './Project';
import Chapter from './Chapter';
import Character from './Character';
import { initWorldBuildingModel, WorldBuilding } from './WorldBuilding';
import { initTimelineEventModel, TimelineEvent } from './TimelineEvent';
import { initWritingSessionModel, WritingSession } from './WritingSession';
import { initWritingGoalModel, WritingGoal } from './WritingGoal';
import { initWritingTemplateModel, WritingTemplate } from './WritingTemplate';

export interface Models {
  User: typeof User;
  Project: typeof Project;
  Chapter: typeof Chapter;
  Character: typeof Character;
  WorldBuilding: typeof WorldBuilding;
  TimelineEvent: typeof TimelineEvent;
  WritingSession: typeof WritingSession;
  WritingGoal: typeof WritingGoal;
  WritingTemplate: typeof WritingTemplate;
}

export function initializeModels(sequelize: Sequelize): Models {
  // 初始化所有模型 - 暂时跳过关联关系定义
  const UserModel = User;
  const ProjectModel = Project;
  const ChapterModel = Chapter;
  const CharacterModel = Character;
  const WorldBuildingModel = initWorldBuildingModel();
  const TimelineEventModel = initTimelineEventModel();
  const WritingSessionModel = initWritingSessionModel();
  const WritingGoalModel = initWritingGoalModel();
  const WritingTemplateModel = initWritingTemplateModel();

  // 暂时注释掉关联关系定义，先让服务器启动
  // TODO: 修复关联关系定义

  return {
    User: UserModel,
    Project: ProjectModel,
    Chapter: ChapterModel,
    Character: CharacterModel,
    WorldBuilding: WorldBuildingModel,
    TimelineEvent: TimelineEventModel,
    WritingSession: WritingSessionModel,
    WritingGoal: WritingGoalModel,
    WritingTemplate: WritingTemplateModel,
  };
}
