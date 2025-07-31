import { Layout } from 'antd'
import { useState } from 'react'
import { Route, Routes } from 'react-router-dom'
import FloatingAIButton from './components/AI/FloatingAIButton'
import { DraggableAIWindow } from './components/AI/DraggableAIWindow'
import AppHeader from './components/Layout/AppHeader'
import Sidebar from './components/Layout/Sidebar'
import RxDBProvider, { SyncStatusIndicator, ConnectionStatus, DatabaseDebugPanel } from './components/RxDBProvider'
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

const { Content } = Layout

const AppContent: React.FC = () => {
    const { sidebarCollapsed } = useAppStore()
    const { content } = useEditor()
    const [floatingAIVisible, setFloatingAIVisible] = useState(false)

    return (
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
        </Layout>
    )
}

function App() {
    return (
        <AuthProvider>
            <RxDBProvider>
                <EditorProvider>
                    <AIProvider>
                        <AppContent />
                    </AIProvider>
                </EditorProvider>
            </RxDBProvider>
        </AuthProvider>
    )
}

export default App
