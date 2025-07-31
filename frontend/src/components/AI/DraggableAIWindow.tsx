import React, { useState, useEffect, useCallback } from 'react'
import { Button, Tooltip } from 'antd'
import { CloseOutlined, ExpandOutlined, MinusOutlined } from '@ant-design/icons'
import { AIAgentPanel } from './AIAgentPanel'
import WindowPositionManager, { WindowPosition, WindowSize } from '../../utils/WindowPositionManager'
import './DraggableAIWindow.css'

interface DraggableAIWindowProps {
  visible: boolean
  onClose: () => void
  currentWordCount?: number
  totalWordCount?: number
  targetWordCount?: number
  sessionTime?: number
}

export const DraggableAIWindow: React.FC<DraggableAIWindowProps> = ({
  visible,
  onClose,
  currentWordCount = 0,
  totalWordCount = 12500,
  targetWordCount = 50000,
  sessionTime = 45
}) => {
  // 位置和大小状态
  const [position, setPosition] = useState<WindowPosition>(() => 
    WindowPositionManager.getDefaultPosition({ width: 420, height: 650 })
  )
  const [size, setSize] = useState<WindowSize>({ width: 420, height: 650 })
  const [isDragging, setIsDragging] = useState(false)
  const [isResizing, setIsResizing] = useState(false)
  const [resizeDirection, setResizeDirection] = useState<string>('')
  const [isMinimized, setIsMinimized] = useState(false)
  const [isMaximized, setIsMaximized] = useState(false)
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 })
  const [resizeStartPos, setResizeStartPos] = useState({ x: 0, y: 0 })
  const [resizeStartSize, setResizeStartSize] = useState({ width: 0, height: 0 })

  // 检查是否需要内容可见性调整
  const needsVisibilityAdjustment = useCallback(() => {
    return WindowPositionManager.needsContentVisibilityAdjustment({ position, size })
  }, [position, size])

  // 鼠标移动处理
  const handleMouseMove = useCallback((e: MouseEvent) => {
    if (isDragging) {
      const newX = e.clientX - dragOffset.x
      const newY = e.clientY - dragOffset.y
      
      // 应用新的位置约束逻辑（仅限制顶部）
      const constrainedPosition = WindowPositionManager.constrainPosition(
        { x: newX, y: newY },
        size
      )
      
      setPosition(constrainedPosition)
    } else if (isResizing) {
      const deltaX = e.clientX - resizeStartPos.x
      const deltaY = e.clientY - resizeStartPos.y
      
      let newWidth = resizeStartSize.width
      let newHeight = resizeStartSize.height
      let newX = position.x
      let newY = position.y
      
      // 根据调整方向计算新的大小和位置
      if (resizeDirection.includes('right')) {
        newWidth = Math.max(300, resizeStartSize.width + deltaX)
      }
      if (resizeDirection.includes('bottom')) {
        newHeight = Math.max(200, resizeStartSize.height + deltaY)
      }
      if (resizeDirection.includes('left')) {
        const maxDelta = resizeStartSize.width - 300
        const constrainedDelta = Math.max(-maxDelta, deltaX)
        newWidth = resizeStartSize.width - constrainedDelta
        newX = position.x + constrainedDelta
      }
      if (resizeDirection.includes('top')) {
        const maxDelta = resizeStartSize.height - 200
        const constrainedDelta = Math.max(-maxDelta, deltaY)
        newHeight = resizeStartSize.height - constrainedDelta
        newY = position.y + constrainedDelta
      }
      
      // 应用大小约束
      const constrainedSize = WindowPositionManager.constrainSize(
        { width: newWidth, height: newHeight }
      )
      
      // 应用位置约束
      const constrainedPosition = WindowPositionManager.constrainPosition(
        { x: newX, y: newY },
        constrainedSize
      )
      
      setSize(constrainedSize)
      setPosition(constrainedPosition)
    }
  }, [isDragging, isResizing, dragOffset, size, resizeDirection, resizeStartPos, resizeStartSize, position])

  // 鼠标释放处理
  const handleMouseUp = useCallback(() => {
    setIsDragging(false)
    setIsResizing(false)
    setResizeDirection('')
  }, [])

  // 添加全局事件监听
  useEffect(() => {
    if (isDragging || isResizing) {
      document.addEventListener('mousemove', handleMouseMove)
      document.addEventListener('mouseup', handleMouseUp)
      document.body.style.userSelect = 'none'
      if (isDragging) {
        document.body.style.cursor = 'move'
      } else if (isResizing) {
        const cursorMap: { [key: string]: string } = {
          'top': 'n-resize',
          'bottom': 's-resize',
          'left': 'w-resize',
          'right': 'e-resize',
          'top-left': 'nw-resize',
          'top-right': 'ne-resize',
          'bottom-left': 'sw-resize',
          'bottom-right': 'se-resize'
        }
        document.body.style.cursor = cursorMap[resizeDirection] || 'default'
      }
    }

    return () => {
      document.removeEventListener('mousemove', handleMouseMove)
      document.removeEventListener('mouseup', handleMouseUp)
      document.body.style.userSelect = ''
      document.body.style.cursor = ''
    }
  }, [isDragging, isResizing, resizeDirection, handleMouseMove, handleMouseUp])

  // 开始拖拽
  const handleMouseDown = (e: React.MouseEvent) => {
    if (isMaximized) return
    setIsDragging(true)
    setDragOffset({
      x: e.clientX - position.x,
      y: e.clientY - position.y
    })
  }

  // 开始调整大小
  const handleResizeStart = (e: React.MouseEvent, direction: string) => {
    if (isMaximized) return
    e.stopPropagation()
    setIsResizing(true)
    setResizeDirection(direction)
    setResizeStartPos({ x: e.clientX, y: e.clientY })
    setResizeStartSize({ width: size.width, height: size.height })
  }

  // 窗口控制函数
  const handleMinimize = () => {
    setIsMinimized(!isMinimized)
  }

  const handleMaximize = () => {
    if (isMaximized) {
      // 恢复原始大小和位置
      const defaultPosition = WindowPositionManager.getDefaultPosition({ width: 420, height: 650 })
      setPosition(defaultPosition)
      setSize({ width: 420, height: 650 })
      setIsMaximized(false)
    } else {
      // 最大化
      setPosition({ x: 20, y: 20 })
      setSize({ 
        width: window.innerWidth - 40, 
        height: window.innerHeight - 40 
      })
      setIsMaximized(true)
    }
  }

  // 处理窗口大小变化
  useEffect(() => {
    const handleResize = () => {
      if (!isMaximized) {
        // 确保窗口内容仍然可见
        const bounds = WindowPositionManager.handleViewportResize({ position, size })
        
        if (bounds.position.x !== position.x || bounds.position.y !== position.y) {
          setPosition(bounds.position)
        }
        if (bounds.size.width !== size.width || bounds.size.height !== size.height) {
          setSize(bounds.size)
        }
      }
    }

    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [position, size, isMaximized])

  // 自动调整窗口位置以确保内容可见
  useEffect(() => {
    if (!isMaximized && needsVisibilityAdjustment()) {
      const adjustedBounds = WindowPositionManager.adjustForContentVisibility({ position, size })
      
      if (adjustedBounds.position.x !== position.x || adjustedBounds.position.y !== position.y) {
        setPosition(adjustedBounds.position)
      }
      if (adjustedBounds.size.width !== size.width || adjustedBounds.size.height !== size.height) {
        setSize(adjustedBounds.size)
      }
    }
  }, [position, size, isMaximized, needsVisibilityAdjustment])

  if (!visible) return null

  return (
    <div
      className={`draggable-ai-window ${isDragging ? 'dragging' : ''} ${isResizing ? 'resizing' : ''} ${needsVisibilityAdjustment() ? 'needs-adjustment' : ''}`}
      style={{
        position: 'fixed',
        left: position.x,
        top: position.y,
        width: size.width,
        height: isMinimized ? 40 : size.height,
        zIndex: 1000,
        background: '#fff',
        borderRadius: isMaximized ? '0' : '12px',
        boxShadow: isDragging || isResizing 
          ? '0 20px 60px rgba(0, 0, 0, 0.3)' 
          : '0 8px 40px rgba(0, 0, 0, 0.12)',
        border: `1px solid ${isDragging || isResizing ? '#1890ff' : 'rgba(0, 0, 0, 0.06)'}`,
        overflow: 'hidden',
        transform: isDragging ? 'scale(1.02)' : isResizing ? 'scale(1.01)' : 'scale(1)',
        transition: isDragging || isResizing ? 'none' : 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
      }}
    >
      {/* 窗口标题栏 */}
      <div
        className="window-header"
        style={{
          height: '40px',
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          color: 'white',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '0 12px',
          cursor: isDragging ? 'move' : 'pointer',
          userSelect: 'none'
        }}
        onMouseDown={handleMouseDown}
      >
        <div style={{ 
          fontSize: '14px', 
          fontWeight: 'bold',
          display: 'flex',
          alignItems: 'center',
          gap: '8px'
        }}>
          🤖 AI 写作助手
        </div>
        
        <div style={{ display: 'flex', gap: '4px' }}>
          <Tooltip title={isMinimized ? "展开" : "最小化"}>
            <Button
              type="text"
              size="small"
              icon={<MinusOutlined />}
              onClick={handleMinimize}
              style={{ 
                color: 'white', 
                border: 'none',
                width: '24px',
                height: '24px'
              }}
            />
          </Tooltip>
          
          <Tooltip title={isMaximized ? "恢复" : "最大化"}>
            <Button
              type="text"
              size="small"
              icon={<ExpandOutlined />}
              onClick={handleMaximize}
              style={{ 
                color: 'white', 
                border: 'none',
                width: '24px',
                height: '24px'
              }}
            />
          </Tooltip>
          
          <Tooltip title="关闭">
            <Button
              type="text"
              size="small"
              icon={<CloseOutlined />}
              onClick={onClose}
              style={{ 
                color: 'white', 
                border: 'none',
                width: '24px',
                height: '24px'
              }}
            />
          </Tooltip>
        </div>
      </div>

      {/* 窗口内容 */}
      {!isMinimized && (
        <div style={{ 
          height: 'calc(100% - 40px)', 
          background: '#fff',
          display: 'flex',
          flexDirection: 'column'
        }}>
          <AIAgentPanel
            currentWordCount={currentWordCount}
            totalWordCount={totalWordCount}
            targetWordCount={targetWordCount}
            sessionTime={sessionTime}
          />
        </div>
      )}

      {/* 调整大小的边缘和角落 */}
      {!isMaximized && !isMinimized && (
        <>
          {/* 四条边 */}
          <div
            className="resize-edge resize-top"
            onMouseDown={(e) => handleResizeStart(e, 'top')}
            style={{
              position: 'absolute',
              top: 0,
              left: 8,
              right: 8,
              height: '4px',
              cursor: 'n-resize',
              zIndex: 10
            }}
          />
          <div
            className="resize-edge resize-bottom"
            onMouseDown={(e) => handleResizeStart(e, 'bottom')}
            style={{
              position: 'absolute',
              bottom: 0,
              left: 8,
              right: 8,
              height: '4px',
              cursor: 's-resize',
              zIndex: 10
            }}
          />
          <div
            className="resize-edge resize-left"
            onMouseDown={(e) => handleResizeStart(e, 'left')}
            style={{
              position: 'absolute',
              top: 8,
              bottom: 8,
              left: 0,
              width: '4px',
              cursor: 'w-resize',
              zIndex: 10
            }}
          />
          <div
            className="resize-edge resize-right"
            onMouseDown={(e) => handleResizeStart(e, 'right')}
            style={{
              position: 'absolute',
              top: 8,
              bottom: 8,
              right: 0,
              width: '4px',
              cursor: 'e-resize',
              zIndex: 10
            }}
          />

          {/* 四个角 */}
          <div
            className="resize-corner resize-top-left"
            onMouseDown={(e) => handleResizeStart(e, 'top-left')}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '8px',
              height: '8px',
              cursor: 'nw-resize',
              zIndex: 11
            }}
          />
          <div
            className="resize-corner resize-top-right"
            onMouseDown={(e) => handleResizeStart(e, 'top-right')}
            style={{
              position: 'absolute',
              top: 0,
              right: 0,
              width: '8px',
              height: '8px',
              cursor: 'ne-resize',
              zIndex: 11
            }}
          />
          <div
            className="resize-corner resize-bottom-left"
            onMouseDown={(e) => handleResizeStart(e, 'bottom-left')}
            style={{
              position: 'absolute',
              bottom: 0,
              left: 0,
              width: '8px',
              height: '8px',
              cursor: 'sw-resize',
              zIndex: 11
            }}
          />
          <div
            className="resize-corner resize-bottom-right"
            onMouseDown={(e) => handleResizeStart(e, 'bottom-right')}
            style={{
              position: 'absolute',
              bottom: 0,
              right: 0,
              width: '8px',
              height: '8px',
              cursor: 'se-resize',
              zIndex: 11
            }}
          />
        </>
      )}
    </div>
  )
}

export default DraggableAIWindow
