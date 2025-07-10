// MongoDB初始化脚本
print('开始初始化AI小说数据库...');

// 切换到应用数据库
db = db.getSiblingDB('ai_novel_db');

// 创建用户集合
db.createCollection('users');

// 创建小说集合
db.createCollection('novels');

// 创建章节集合
db.createCollection('chapters');

// 创建人物集合
db.createCollection('characters');

// 创建世界观集合
db.createCollection('worldviews');

// 创建剧情集合
db.createCollection('plots');

// 创建伏笔集合
db.createCollection('foreshadows');

// 创建用户会话集合
db.createCollection('user_sessions');

// 创建AI对话历史集合
db.createCollection('ai_conversations');

// 创建索引
print('创建索引...');

// 用户索引
db.users.createIndex({ "email": 1 }, { unique: true });
db.users.createIndex({ "username": 1 }, { unique: true });
db.users.createIndex({ "created_at": 1 });

// 小说索引
db.novels.createIndex({ "user_id": 1 });
db.novels.createIndex({ "title": "text", "description": "text" });
db.novels.createIndex({ "created_at": 1 });
db.novels.createIndex({ "updated_at": 1 });
db.novels.createIndex({ "status": 1 });

// 章节索引
db.chapters.createIndex({ "novel_id": 1 });
db.chapters.createIndex({ "novel_id": 1, "order": 1 });
db.chapters.createIndex({ "title": "text", "content": "text" });

// 人物索引
db.characters.createIndex({ "novel_id": 1 });
db.characters.createIndex({ "name": 1 });

// 世界观索引
db.worldviews.createIndex({ "novel_id": 1 });
db.worldviews.createIndex({ "type": 1 });

// 剧情索引
db.plots.createIndex({ "novel_id": 1 });
db.plots.createIndex({ "type": 1 });

// 伏笔索引
db.foreshadows.createIndex({ "novel_id": 1 });
db.foreshadows.createIndex({ "chapter_id": 1 });
db.foreshadows.createIndex({ "status": 1 });

// 会话索引
db.user_sessions.createIndex({ "user_id": 1 });
db.user_sessions.createIndex({ "expires_at": 1 });

// AI对话历史索引
db.ai_conversations.createIndex({ "user_id": 1 });
db.ai_conversations.createIndex({ "novel_id": 1 });
db.ai_conversations.createIndex({ "created_at": 1 });

// 插入示例数据
print('插入示例数据...');

// 示例用户
db.users.insertOne({
    "_id": ObjectId(),
    "username": "demo_user",
    "email": "demo@example.com",
    "password_hash": "$2b$12$demo_hash_here",
    "is_active": true,
    "created_at": new Date(),
    "updated_at": new Date()
});

print('数据库初始化完成！');

// 显示集合信息
print('创建的集合：');
db.getCollectionNames().forEach(function(collection) {
    print('- ' + collection);
});
