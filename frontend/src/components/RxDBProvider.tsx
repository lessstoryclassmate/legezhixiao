import React, { useEffect, useState } from 'react';
import { useRxDB } from '../hooks/useRxDB';

interface RxDBProviderProps {
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

const RxDBProvider: React.FC<RxDBProviderProps> = ({ 
  children, 
  fallback = <DatabaseInitializing /> 
}) => {
  const { isInitialized } = useRxDB();

  if (!isInitialized) {
    return <>{fallback}</>;
  }

  return <>{children}</>;
};

// 数据库初始化加载组件
const DatabaseInitializing: React.FC = () => {
  const [dots, setDots] = useState('');

  useEffect(() => {
    const interval = setInterval(() => {
      setDots(prev => prev.length >= 3 ? '' : prev + '.');
    }, 500);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-50 dark:bg-gray-900">
      <div className="text-center">
        <div className="w-16 h-16 mx-auto mb-4 border-4 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
        <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-200 mb-2">
          初始化本地数据库{dots}
        </h2>
        <p className="text-gray-600 dark:text-gray-400">
          正在设置离线优先的数据存储和同步
        </p>
      </div>
    </div>
  );
};

// 数据同步状态指示器
export const SyncStatusIndicator: React.FC = () => {
  const { syncState, forceSync } = useRxDB();
  const [lastSyncTime, setLastSyncTime] = useState<Date | null>(null);

  useEffect(() => {
    if (syncState === 'idle') {
      setLastSyncTime(new Date());
    }
  }, [syncState]);

  const getSyncStatusInfo = () => {
    switch (syncState) {
      case 'syncing':
        return {
          icon: '🔄',
          color: 'text-blue-500',
          bgColor: 'bg-blue-50 dark:bg-blue-900/20',
          borderColor: 'border-blue-200 dark:border-blue-700',
          text: '正在同步...',
          description: '数据正在与服务器同步'
        };
      case 'error':
        return {
          icon: '⚠️',
          color: 'text-red-500',
          bgColor: 'bg-red-50 dark:bg-red-900/20',
          borderColor: 'border-red-200 dark:border-red-700',
          text: '同步失败',
          description: '数据同步遇到问题，点击重试'
        };
      default:
        return {
          icon: '✅',
          color: 'text-green-500',
          bgColor: 'bg-green-50 dark:bg-green-900/20',
          borderColor: 'border-green-200 dark:border-green-700',
          text: '已同步',
          description: lastSyncTime ? `最后同步: ${lastSyncTime.toLocaleTimeString()}` : '数据已同步'
        };
    }
  };

  const statusInfo = getSyncStatusInfo();

  const handleSyncClick = () => {
    if (syncState === 'error' || syncState === 'idle') {
      forceSync();
    }
  };

  return (
    <div 
      className={`
        flex items-center gap-2 px-3 py-2 rounded-lg border transition-all duration-200 cursor-pointer
        ${statusInfo.bgColor} ${statusInfo.borderColor} hover:scale-105
      `}
      onClick={handleSyncClick}
      title={statusInfo.description}
    >
      <span className="text-sm">{statusInfo.icon}</span>
      <div className="flex flex-col">
        <span className={`text-xs font-medium ${statusInfo.color}`}>
          {statusInfo.text}
        </span>
        {syncState === 'idle' && lastSyncTime && (
          <span className="text-xs text-gray-500 dark:text-gray-400">
            {lastSyncTime.toLocaleTimeString()}
          </span>
        )}
      </div>
    </div>
  );
};

// 数据库操作面板
export const DatabaseControls: React.FC = () => {
  const { clearCache, exportData, importData } = useRxDB();
  const [isExporting, setIsExporting] = useState(false);
  const [isImporting, setIsImporting] = useState(false);
  const [exportSuccess, setExportSuccess] = useState(false);

  const handleExport = async () => {
    setIsExporting(true);
    try {
      const data = await exportData();
      
      // 创建下载链接
      const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `legezhixiao-backup-${new Date().toISOString().split('T')[0]}.json`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
      
      setExportSuccess(true);
      setTimeout(() => setExportSuccess(false), 3000);
    } catch (error) {
      console.error('导出数据失败:', error);
    } finally {
      setIsExporting(false);
    }
  };

  const handleImport = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setIsImporting(true);
    try {
      const text = await file.text();
      const data = JSON.parse(text);
      await importData(data);
      console.log('数据导入成功');
    } catch (error) {
      console.error('导入数据失败:', error);
    } finally {
      setIsImporting(false);
    }
  };

  const handleClearCache = async () => {
    if (confirm('确定要清理缓存吗？这将删除所有本地缓存数据。')) {
      try {
        await clearCache();
        console.log('缓存清理成功');
      } catch (error) {
        console.error('清理缓存失败:', error);
      }
    }
  };

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
      <h3 className="text-lg font-semibold text-gray-800 dark:text-gray-200 mb-4">
        数据库管理
      </h3>
      
      <div className="space-y-3">
        {/* 导出数据 */}
        <button
          onClick={handleExport}
          disabled={isExporting}
          className={`
            w-full flex items-center justify-center gap-2 px-4 py-2 rounded-md transition-colors
            ${isExporting 
              ? 'bg-gray-100 dark:bg-gray-700 text-gray-400 cursor-not-allowed' 
              : 'bg-blue-500 hover:bg-blue-600 text-white'
            }
          `}
        >
          {isExporting ? (
            <>
              <div className="w-4 h-4 border-2 border-gray-400 border-t-transparent rounded-full animate-spin"></div>
              导出中...
            </>
          ) : exportSuccess ? (
            <>
              <span>✅</span>
              导出成功！
            </>
          ) : (
            <>
              <span>📤</span>
              导出数据
            </>
          )}
        </button>

        {/* 导入数据 */}
        <div className="relative">
          <input
            type="file"
            accept=".json"
            onChange={handleImport}
            disabled={isImporting}
            className="absolute inset-0 w-full h-full opacity-0 cursor-pointer disabled:cursor-not-allowed"
          />
          <button
            disabled={isImporting}
            className={`
              w-full flex items-center justify-center gap-2 px-4 py-2 rounded-md transition-colors
              ${isImporting 
                ? 'bg-gray-100 dark:bg-gray-700 text-gray-400 cursor-not-allowed' 
                : 'bg-green-500 hover:bg-green-600 text-white'
              }
            `}
          >
            {isImporting ? (
              <>
                <div className="w-4 h-4 border-2 border-gray-400 border-t-transparent rounded-full animate-spin"></div>
                导入中...
              </>
            ) : (
              <>
                <span>📥</span>
                导入数据
              </>
            )}
          </button>
        </div>

        {/* 清理缓存 */}
        <button
          onClick={handleClearCache}
          className="w-full flex items-center justify-center gap-2 px-4 py-2 rounded-md bg-orange-500 hover:bg-orange-600 text-white transition-colors"
        >
          <span>🧹</span>
          清理缓存
        </button>
      </div>
      
      <div className="mt-4 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-md">
        <p className="text-sm text-gray-600 dark:text-gray-400">
          💡 <strong>提示:</strong> 定期导出数据可以作为备份。导入功能用于恢复数据或在设备间同步。
        </p>
      </div>
    </div>
  );
};

// 连接状态指示器
export const ConnectionStatus: React.FC = () => {
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  const { syncState } = useRxDB();

  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  const getStatusInfo = () => {
    if (!isOnline) {
      return {
        icon: '📴',
        text: '离线模式',
        color: 'text-orange-500',
        bgColor: 'bg-orange-50 dark:bg-orange-900/20',
        description: '当前处于离线状态，数据将在连接恢复后同步'
      };
    }

    if (syncState === 'syncing') {
      return {
        icon: '🔄',
        text: '同步中',
        color: 'text-blue-500',
        bgColor: 'bg-blue-50 dark:bg-blue-900/20',
        description: '正在与服务器同步数据'
      };
    }

    return {
      icon: '🌐',
      text: '在线',
      color: 'text-green-500',
      bgColor: 'bg-green-50 dark:bg-green-900/20',
      description: '已连接到服务器'
    };
  };

  const status = getStatusInfo();

  return (
    <div 
      className={`
        flex items-center gap-2 px-2 py-1 rounded-md transition-all duration-200
        ${status.bgColor}
      `}
      title={status.description}
    >
      <span className="text-xs">{status.icon}</span>
      <span className={`text-xs font-medium ${status.color}`}>
        {status.text}
      </span>
    </div>
  );
};

// 数据库状态面板（开发调试用）
export const DatabaseDebugPanel: React.FC = () => {
  const { isInitialized, syncState } = useRxDB();
  const [dbInfo, setDbInfo] = useState<any>(null);

  useEffect(() => {
    const checkDbInfo = async () => {
      const db = (await import('../services/rxdbService')).rxdbService.getDatabase();
      if (db) {
        const collections = Object.keys(db.collections);
        const info = {
          name: db.name,
          collections,
          storage: db.storage.name
        };
        setDbInfo(info);
      }
    };

    if (isInitialized) {
      checkDbInfo();
    }
  }, [isInitialized]);

  if (!import.meta.env.DEV) {
    return null; // 仅在开发环境显示
  }

  return (
    <div className="fixed bottom-4 right-4 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 p-3 max-w-xs z-50">
      <div className="text-xs space-y-1">
        <div className="font-semibold text-gray-800 dark:text-gray-200">
          RxDB 状态 🔧
        </div>
        <div className={`${isInitialized ? 'text-green-600' : 'text-red-600'}`}>
          初始化: {isInitialized ? '✅' : '❌'}
        </div>
        <div className={`
          ${syncState === 'idle' ? 'text-green-600' : 
            syncState === 'syncing' ? 'text-blue-600' : 'text-red-600'}
        `}>
          同步: {syncState === 'idle' ? '✅' : syncState === 'syncing' ? '🔄' : '❌'}
        </div>
        {dbInfo && (
          <>
            <div className="text-gray-600 dark:text-gray-400">
              数据库: {dbInfo.name}
            </div>
            <div className="text-gray-600 dark:text-gray-400">
              集合: {dbInfo.collections.length}
            </div>
            <div className="text-gray-600 dark:text-gray-400">
              存储: {dbInfo.storage}
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default RxDBProvider;
