import { createRxDatabase, addRxPlugin } from 'rxdb';
import { getRxStorageDexie } from 'rxdb/plugins/storage-dexie';

async function simpleRxDBTest() {
    console.log('🔄 开始简单 RxDB 测试...');
    
    try {
        console.log('🔄 创建简单数据库...');
        const db = await createRxDatabase({
            name: 'simple_test_db',
            storage: getRxStorageDexie(),
            ignoreDuplicate: true
        });
        console.log('✅ 简单数据库创建成功');
        
        // 添加一个简单的集合
        console.log('🔄 添加简单集合...');
        await db.addCollections({
            simple_collection: {
                schema: {
                    version: 0,
                    primaryKey: 'id',
                    type: 'object',
                    properties: {
                        id: { type: 'string', maxLength: 100 },
                        name: { type: 'string', maxLength: 100 }
                    },
                    required: ['id', 'name']
                }
            }
        });
        console.log('✅ 简单集合添加成功');
        
        // 清理
        await db.destroy();
        console.log('✅ 简单测试完成');
        
        return true;
    } catch (error) {
        console.error('❌ 简单 RxDB 测试失败:', error);
        return false;
    }
}

// 导出测试函数
window.simpleRxDBTest = simpleRxDBTest;

// 自动运行测试
simpleRxDBTest().then(success => {
    document.body.innerHTML = `
        <h1>简单 RxDB 测试</h1>
        <p style="color: ${success ? 'green' : 'red'};">
            ${success ? '✅ 测试通过' : '❌ 测试失败'}
        </p>
        <p>请查看控制台了解详细信息</p>
    `;
});
