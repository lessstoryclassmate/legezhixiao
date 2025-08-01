import { Layout } from 'antd'
import { useState, useEffect } from 'react'
import { Route, Routes } from 'react-router-dom'
import FloatingAIButton from './components/AI/FloatingAIButton'
import { DraggableAIWindow } from './components/AI/DraggableAIWindow'
import AppHeader from './components/Layout/AppHeader'
import Sidebar from './components/Layout/Sidebar'
import RxDBProvider, { SyncStatusIndicator, ConnectionStatus, DatabaseDebugPanel } from './components/RxDBProvider'
import ErrorBoundary from './components/ErrorBoundary'
import LogMonitor from './components/LogMonitor'
import { AuthProvider } from './contexts/AuthContext'
import { EditorProvider, useEditor } from './contexts/EditorContext'
import { AIProvider } from './contexts/AIContext'
import ProjectDashboard from './pages/ProjectDashboard'
import ProjectSettings from './pages/ProjectSettings'
import NovelWorkspace from './pages/NovelWorkspace'
import WritingInterfaceOptimized from './pages/WritingInterfaceOptimized'
import CreativeToolsPage from './pages/CreativeToolsPage'
import CharacterManagementPage from './pages/CharacterManagementPage'
import WorldBuildingPage from './pages/WorldBuildingPage'
import RxDBTestPage from './pages/RxDBTestPage'
import { useAppStore } from './store/appStore'
import { apiLogger, log } from './utils/apiLogger'

const { Content } = Layout

const AppContent: React.FC = () => {
    const { sidebarCollapsed } = useAppStore()
    const { content } = useEditor()
    const [floatingAIVisible, setFloatingAIVisible] = useState(false)
    const [showLogMonitor, setShowLogMonitor] = useState(false)

    useEffect(() => {
        // 记录应用启动
        log.info('App', '应用程序启动', {
            timestamp: new Date().toISOString(),
            url: window.location.href,
            userAgent: navigator.userAgent,
            viewport: {
                width: window.innerWidth,
                height: window.innerHeight
            }
        })

        // 监听路由变化
        const handleLocationChange = () => {
            log.info('App', '路由变化', {
                url: window.location.href,
                pathname: window.location.pathname,
                search: window.location.search
            })
        }

        // 监听窗口大小变化
        const handleResize = () => {
            log.debug('App', '窗口大小变化', {
                width: window.innerWidth,
                height: window.innerHeight
            })
        }

        // 监听页面可见性变化
        const handleVisibilityChange = () => {
            log.info('App', `页面${document.hidden ? '隐藏' : '显示'}`)
        }

        window.addEventListener('popstate', handleLocationChange)
        window.addEventListener('resize', handleResize)
        document.addEventListener('visibilitychange', handleVisibilityChange)

        // 开发环境下默认显示日志监控
        if (import.meta.env.DEV) {
            setShowLogMonitor(true)
            log.info('App', '开发环境，启用日志监控')
        }

        return () => {
            window.removeEventListener('popstate', handleLocationChange)
            window.removeEventListener('resize', handleResize)
            document.removeEventListener('visibilitychange', handleVisibilityChange)
            log.info('App', '应用程序卸载')
        }
    }, [])

    const toggleLogMonitor = () => {
        setShowLogMonitor(!showLogMonitor)
        log.info('App', `日志监控${!showLogMonitor ? '打开' : '关闭'}`)
    }

    return (
        <ErrorBoundary>
            <Layout style={{ height: '100vh' }}>
                <AppHeader />
                <Layout>
                    <Sidebar collapsed={sidebarCollapsed} />
                    <Layout>
                        <Content style={{
                            padding: '0',
                            overflow: 'hidden',
                            background: '#fff'
                        }}>
                            <ErrorBoundary>
                                <Routes>
                                    <Route path="/" element={<ProjectDashboard />} />
                                    <Route path="/projects" element={<ProjectDashboard />} />
                                    <Route path="/project/:id/write" element={<WritingInterfaceOptimized />} />
                                    <Route path="/project/:id/write-legacy" element={<NovelWorkspace />} />
                                    <Route path="/project/:id/creative-tools" element={<CreativeToolsPage />} />
                                    <Route path="/project/:id/characters" element={<CharacterManagementPage />} />
                                    <Route path="/project/:id/world" element={<WorldBuildingPage />} />
                                    <Route path="/project/:id/settings" element={<ProjectSettings />} />
                                    <Route path="/rxdb-test" element={<RxDBTestPage />} />
                                </Routes>
                            </ErrorBoundary>
                        </Content>
                    </Layout>
                </Layout>

                {/* 数据同步状态指示器 */}
                <div className="fixed top-4 right-4 z-50 flex items-center gap-2">
                    <ConnectionStatus />
                    <SyncStatusIndicator />
                </div>

                {/* 全局浮动AI助手按钮 */}
                <FloatingAIButton
                    onToggleAI={() => setFloatingAIVisible(!floatingAIVisible)}
                    isAIVisible={floatingAIVisible}
                />

                {/* 全局可拖拽AI助手窗口 */}
                <DraggableAIWindow
                    visible={floatingAIVisible}
                    onClose={() => setFloatingAIVisible(false)}
                    currentWordCount={content?.length || 0}
                    totalWordCount={12500}
                    targetWordCount={50000}
                    sessionTime={45}
                />

                {/* 开发调试面板 */}
                <DatabaseDebugPanel />

                {/* 日志监控面板 */}
                <LogMonitor
                    visible={showLogMonitor}
                    onToggle={toggleLogMonitor}
                />

                {/* 日志监控快捷键 */}
                {import.meta.env.DEV && (
                    <div
                        style={{
                            position: 'fixed',
                            bottom: '80px',
                            right: '20px',
                            zIndex: 9999,
                        }}
                    >
                        <button
                            onClick={toggleLogMonitor}
                            style={{
                                backgroundColor: '#10b981',
                                color: 'white',
                                border: 'none',
                                borderRadius: '4px',
                                padding: '8px 12px',
                                cursor: 'pointer',
                                fontSize: '12px',
                                boxShadow: '0 2px 8px rgba(0,0,0,0.15)',
                            }}
                            title="切换日志监控 (开发模式)"
                        >
                            📊 日志
                        </button>
                    </div>
                )}
            </Layout>
        </ErrorBoundary>
    )
}

function App() {
    useEffect(() => {
        log.info('App', '应用根组件挂载')
        return () => {
            log.info('App', '应用根组件卸载')
        }
    }, [])
    useEffect(() => {
        log.info('App', '应用根组件挂载')
        return () => {
            log.info('App', '应用根组件卸载')
        }
    }, [])

    return (
        <ErrorBoundary>
            <AuthProvider>
                <RxDBProvider>
                    <EditorProvider>
                        <AIProvider>
                            <AppContent />
                        </AIProvider>
                    </EditorProvider>
                </RxDBProvider>
            </AuthProvider>
        </ErrorBoundary>
    )
}

export default App
