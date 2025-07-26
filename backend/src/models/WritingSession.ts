import { DataTypes, Model, Optional } from 'sequelize';
import { databaseConfig } from '../config/database';

// 写作会话属性接口
export interface WritingSessionAttributes {
  id: string;
  userId: string;          // 用户ID
  projectId: string;       // 项目ID
  chapterId?: string;      // 章节ID（可选）
  startTime: Date;         // 开始时间
  endTime?: Date;          // 结束时间
  duration?: number;       // 持续时间（分钟）
  wordsWritten: number;    // 写作字数
  wordsBefore: number;     // 会话前字数
  wordsAfter: number;      // 会话后字数
  goal?: number;           // 目标字数
  mood?: 'excellent' | 'good' | 'neutral' | 'poor' | 'terrible'; // 写作状态
  productivity?: number;   // 生产力评分 (0-10)
  distractions?: string[]; // 干扰因素
  achievements?: string[]; // 成就
  notes?: string;          // 会话笔记
  tags?: string[];         // 标签
  aiInteractions?: {       // AI交互记录
    requests: number;
    suggestions: number;
    acceptedSuggestions: number;
    topics: string[];
  };
  writingStats?: {         // 写作统计
    avgWordsPerMinute: number;
    peakWordsPerMinute: number;
    pauseCount: number;
    longestPause: number;
    deletedWords: number;
    editCount: number;
  };
  createdAt: Date;
  updatedAt: Date;
}

interface WritingSessionCreationAttributes extends Optional<WritingSessionAttributes, 
  'id' | 'createdAt' | 'updatedAt' | 'chapterId' | 'endTime' | 'duration' | 'goal' | 
  'mood' | 'productivity' | 'distractions' | 'achievements' | 'notes' | 'tags' | 
  'aiInteractions' | 'writingStats'> {}

// 写作会话模型
export class WritingSession extends Model<WritingSessionAttributes, WritingSessionCreationAttributes> 
  implements WritingSessionAttributes {
  public id!: string;
  public userId!: string;
  public projectId!: string;
  public chapterId?: string;
  public startTime!: Date;
  public endTime?: Date;
  public duration?: number;
  public wordsWritten!: number;
  public wordsBefore!: number;
  public wordsAfter!: number;
  public goal?: number;
  public mood?: 'excellent' | 'good' | 'neutral' | 'poor' | 'terrible';
  public productivity?: number;
  public distractions?: string[];
  public achievements?: string[];
  public notes?: string;
  public tags?: string[];
  public aiInteractions?: {
    requests: number;
    suggestions: number;
    acceptedSuggestions: number;
    topics: string[];
  };
  public writingStats?: {
    avgWordsPerMinute: number;
    peakWordsPerMinute: number;
    pauseCount: number;
    longestPause: number;
    deletedWords: number;
    editCount: number;
  };
  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;

  // 关联方法
  public static associate() {
    // 这里会在models/index.ts中设置关联
  }
}

// 初始化模型
export const initWritingSessionModel = () => {
  const sequelize = databaseConfig.getSequelize();
  if (!sequelize) {
    throw new Error('Database not initialized');
  }

  WritingSession.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    userId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'Users',
        key: 'id'
      }
    },
    projectId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'Projects',
        key: 'id'
      }
    },
    chapterId: {
      type: DataTypes.UUID,
      allowNull: true,
      references: {
        model: 'Chapters',
        key: 'id'
      }
    },
    startTime: {
      type: DataTypes.DATE,
      allowNull: false
    },
    endTime: {
      type: DataTypes.DATE,
      allowNull: true
    },
    duration: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    wordsWritten: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0
    },
    wordsBefore: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0
    },
    wordsAfter: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0
    },
    goal: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    mood: {
      type: DataTypes.ENUM('excellent', 'good', 'neutral', 'poor', 'terrible'),
      allowNull: true
    },
    productivity: {
      type: DataTypes.INTEGER,
      allowNull: true,
      validate: {
        min: 0,
        max: 10
      }
    },
    distractions: {
      type: DataTypes.JSON,
      allowNull: true
    },
    achievements: {
      type: DataTypes.JSON,
      allowNull: true
    },
    notes: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    tags: {
      type: DataTypes.JSON,
      allowNull: true
    },
    aiInteractions: {
      type: DataTypes.JSON,
      allowNull: true
    },
    writingStats: {
      type: DataTypes.JSON,
      allowNull: true
    },
    createdAt: {
      type: DataTypes.DATE,
      allowNull: false
    },
    updatedAt: {
      type: DataTypes.DATE,
      allowNull: false
    }
  }, {
    sequelize,
    modelName: 'WritingSession',
    tableName: 'WritingSessions',
    timestamps: true,
    indexes: [
      {
        fields: ['userId']
      },
      {
        fields: ['projectId']
      },
      {
        fields: ['startTime']
      },
      {
        fields: ['mood']
      }
    ]
  });

  return WritingSession;
};
