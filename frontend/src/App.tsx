import { Layout } from 'antd'
import { useState, useEffect, useContext } from 'react'
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
import AuthPage from './pages/AuthPage'
import AuthorizedRoutes from './pages/AuthorizedRoutes'
import { useAppStore } from './store/appStore'
import { apiLogger, log } from './utils/apiLogger'

console.log('📱 App组件开始加载...')

const { Content } = Layout

const AppContent: React.FC = () => {
  console.log('� AppContent: Component rendering started');
  
  try {
    console.log('� AppContent: Accessing store...');
    const store = useAppStore();
    console.log('✅ AppContent: Store accessed successfully:', !!store);
    
    console.log('� AppContent: Accessing editor context...');
    const editorContext = useContext(EditorContext);
    console.log('✅ AppContent: Editor context accessed:', !!editorContext);
    
    console.log('🔄 AppContent: Initializing local state...');
    const [mounted, setMounted] = useState(false);
    console.log('✅ AppContent: Local state initialized');

    useEffect(() => {
      console.log('🔄 AppContent: useEffect triggered');
      setMounted(true);
      console.log('✅ AppContent: Component mounted');
    }, []);

    console.log('🔄 AppContent: About to render main content');
    
    return (
      <div className="app">
        <Routes>
          <Route path="/login" element={<AuthPage />} />
          <Route path="/register" element={<AuthPage />} />
          <Route path="/*" element={<AuthorizedRoutes />} />
        </Routes>
      </div>
    );
  } catch (error) {
    console.error('❌ AppContent: Error in component:', error);
    return <div>AppContent Error: {error instanceof Error ? error.message : String(error)}</div>;
  }
};

// 增加RxDB状态监控组件
const RxDBDebugWrapper: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  console.log('🔄 RxDBDebugWrapper: Initializing...');
  
  useEffect(() => {
    console.log('🔄 RxDBDebugWrapper: Starting RxDB status monitoring...');
    
    // 检查RxDB服务实例
    try {
      console.log('🔄 RxDBDebugWrapper: Checking rxdbService import...');
      import('./services/rxdbService').then(module => {
        console.log('✅ RxDBDebugWrapper: rxdbService module loaded:', !!module.rxdbService);
        
        // 监听初始化状态
        const subscription = module.rxdbService.isInitialized().subscribe({
          next: (isInit) => {
            console.log(`📊 RxDBDebugWrapper: DB initialization status changed: ${isInit}`);
          },
          error: (error) => {
            console.error('❌ RxDBDebugWrapper: DB initialization error:', error);
          }
        });
        
        return () => subscription.unsubscribe();
      }).catch(error => {
        console.error('❌ RxDBDebugWrapper: Failed to import rxdbService:', error);
      });
    } catch (error) {
      console.error('❌ RxDBDebugWrapper: Error during RxDB monitoring setup:', error);
    }
  }, []);
  
  return <>{children}</>;
};

function App() {
    console.log('🚀 主App组件开始渲染...')
    
    useEffect(() => {
        console.log('📊 App根组件useEffect开始执行...')
        log.info('App', '应用根组件挂载')
        return () => {
            console.log('🗑️ App根组件卸载...')
            log.info('App', '应用根组件卸载')
        }
    }, [])

    console.log('🔗 开始渲染Provider链...')
    return (
        <ErrorBoundary>
            <RxDBDebugWrapper>
                <AuthProvider>
                    <RxDBProvider>
                        <EditorProvider>
                            <AIProvider>
                                <AppContent />
                            </AIProvider>
                        </EditorProvider>
                    </RxDBProvider>
                </AuthProvider>
            </RxDBDebugWrapper>
        </ErrorBoundary>
    )
}

export default App
