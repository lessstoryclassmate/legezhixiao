import React from 'react'

// 最简单的App组件
const SimpleApp: React.FC = () => {
    console.log('✅ SimpleApp组件渲染成功')
    
    return (
        <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
            <h1 style={{ color: '#1890ff' }}>🎉 乐格至效前端应用</h1>
            <p>前端应用已成功启动！</p>
            <div style={{ marginTop: '20px', padding: '10px', backgroundColor: '#f0f0f0', borderRadius: '4px' }}>
                <h3>系统状态</h3>
                <ul>
                    <li>✅ React 渲染正常</li>
                    <li>✅ 前端服务运行在 http://localhost:5173</li>
                    <li>✅ 后端API: http://localhost:3000</li>
                </ul>
            </div>
        </div>
    )
}

export default SimpleApp
