import { DataTypes, Model, Optional } from 'sequelize';
import { databaseConfig } from '../config/database';

// 写作目标属性接口
export interface WritingGoalAttributes {
  id: string;
  userId: string;          // 用户ID
  projectId?: string;      // 项目ID（可选，全局目标时为空）
  type: 'daily' | 'weekly' | 'monthly' | 'yearly' | 'custom'; // 目标类型
  targetWords: number;     // 目标字数
  currentWords: number;    // 当前字数
  startDate: Date;         // 开始日期
  endDate: Date;           // 结束日期
  status: 'active' | 'completed' | 'paused' | 'failed'; // 状态
  priority: 'high' | 'medium' | 'low'; // 优先级
  title: string;           // 目标标题
  description?: string;    // 目标描述
  rewards?: string[];      // 奖励机制
  milestones?: {           // 里程碑
    percentage: number;
    description: string;
    completed: boolean;
    completedAt?: Date;
  }[];
  streak?: {               // 连续记录
    current: number;
    longest: number;
    lastUpdate: Date;
  };
  reminders?: {            // 提醒设置
    enabled: boolean;
    times: string[];       // 提醒时间
    frequency: 'daily' | 'weekly';
  };
  tags?: string[];         // 标签
  notes?: string;          // 备注
  createdAt: Date;
  updatedAt: Date;
}

interface WritingGoalCreationAttributes extends Optional<WritingGoalAttributes, 
  'id' | 'createdAt' | 'updatedAt' | 'projectId' | 'description' | 'rewards' | 
  'milestones' | 'streak' | 'reminders' | 'tags' | 'notes'> {}

// 写作目标模型
export class WritingGoal extends Model<WritingGoalAttributes, WritingGoalCreationAttributes> 
  implements WritingGoalAttributes {
  public id!: string;
  public userId!: string;
  public projectId?: string;
  public type!: 'daily' | 'weekly' | 'monthly' | 'yearly' | 'custom';
  public targetWords!: number;
  public currentWords!: number;
  public startDate!: Date;
  public endDate!: Date;
  public status!: 'active' | 'completed' | 'paused' | 'failed';
  public priority!: 'high' | 'medium' | 'low';
  public title!: string;
  public description?: string;
  public rewards?: string[];
  public milestones?: {
    percentage: number;
    description: string;
    completed: boolean;
    completedAt?: Date;
  }[];
  public streak?: {
    current: number;
    longest: number;
    lastUpdate: Date;
  };
  public reminders?: {
    enabled: boolean;
    times: string[];
    frequency: 'daily' | 'weekly';
  };
  public tags?: string[];
  public notes?: string;
  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;

  // 实例方法
  public getProgress(): number {
    return this.targetWords > 0 ? (this.currentWords / this.targetWords) * 100 : 0;
  }

  public isCompleted(): boolean {
    return this.currentWords >= this.targetWords;
  }

  public getDaysRemaining(): number {
    const now = new Date();
    const diff = this.endDate.getTime() - now.getTime();
    return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)));
  }

  // 关联方法
  public static associate() {
    // 这里会在models/index.ts中设置关联
  }
}

// 初始化模型
export const initWritingGoalModel = () => {
  const sequelize = databaseConfig.getSequelize();
  if (!sequelize) {
    throw new Error('Database not initialized');
  }

  WritingGoal.init({
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
      allowNull: true,
      references: {
        model: 'Projects',
        key: 'id'
      }
    },
    type: {
      type: DataTypes.ENUM('daily', 'weekly', 'monthly', 'yearly', 'custom'),
      allowNull: false
    },
    targetWords: {
      type: DataTypes.INTEGER,
      allowNull: false,
      validate: {
        min: 1
      }
    },
    currentWords: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
      validate: {
        min: 0
      }
    },
    startDate: {
      type: DataTypes.DATE,
      allowNull: false
    },
    endDate: {
      type: DataTypes.DATE,
      allowNull: false
    },
    status: {
      type: DataTypes.ENUM('active', 'completed', 'paused', 'failed'),
      allowNull: false,
      defaultValue: 'active'
    },
    priority: {
      type: DataTypes.ENUM('high', 'medium', 'low'),
      allowNull: false,
      defaultValue: 'medium'
    },
    title: {
      type: DataTypes.STRING,
      allowNull: false
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    rewards: {
      type: DataTypes.JSON,
      allowNull: true
    },
    milestones: {
      type: DataTypes.JSON,
      allowNull: true
    },
    streak: {
      type: DataTypes.JSON,
      allowNull: true
    },
    reminders: {
      type: DataTypes.JSON,
      allowNull: true
    },
    tags: {
      type: DataTypes.JSON,
      allowNull: true
    },
    notes: {
      type: DataTypes.TEXT,
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
    modelName: 'WritingGoal',
    tableName: 'WritingGoals',
    timestamps: true,
    indexes: [
      {
        fields: ['userId']
      },
      {
        fields: ['projectId']
      },
      {
        fields: ['type']
      },
      {
        fields: ['status']
      },
      {
        fields: ['startDate', 'endDate']
      }
    ]
  });

  return WritingGoal;
};
