import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ConfigProvider } from 'antd'
import zhCN from 'antd/locale/zh_CN'
import React from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import App from './App'
// import SimpleApp from './SimpleApp'
import ErrorBoundary from './components/ErrorBoundary'
import './index.css'
import './styles/tech-theme.css'
// 重新启用日志系统以便调试
import './utils/logger'

// 创建 React Query 客户端
const queryClient = new QueryClient({
    defaultOptions: {
        queries: {
            retry: 1,
            refetchOnWindowFocus: false,
        },
    },
})

// Ant Design 主题配置
const theme = {
    token: {
        colorPrimary: '#1890ff',
        borderRadius: 6,
    },
}

const container = document.getElementById('root')
if (!container) throw new Error('Failed to find the root element')

// 添加调试信息
console.log('🚀 前端应用开始初始化...')
console.log('📦 Root容器已找到:', container)

const root = createRoot(container)

console.log('🔧 React Root已创建')

root.render(
    <React.StrictMode>
        <ErrorBoundary>
            <QueryClientProvider client={queryClient}>
                <ConfigProvider locale={zhCN} theme={theme}>
                    <BrowserRouter>
                        <App />
                    </BrowserRouter>
                </ConfigProvider>
            </QueryClientProvider>
        </ErrorBoundary>
    </React.StrictMode>,
)

console.log('✅ React应用已渲染')
