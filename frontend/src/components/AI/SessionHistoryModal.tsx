import React, { useState, useEffect } from 'react'
import { Modal, List, Button, Input, Badge, Space, Typography, Tooltip, Popconfirm, Divider } from 'antd'
import { ProjectOutlined, MessageOutlined, ClockCircleOutlined, SearchOutlined, DeleteOutlined, HistoryOutlined } from '@ant-design/icons'
import type { SessionSummary } from '../../services/sessionManager'
import { useEditor } from '../../contexts/EditorContext'
import './SessionHistoryModal.css'

const { Text, Title } = Typography
const { Search } = Input

interface SessionHistoryModalProps {
    visible: boolean
    onClose: () => void
    onSelectProject?: (projectId: string, projectTitle: string) => void
}

export const SessionHistoryModal: React.FC<SessionHistoryModalProps> = ({
    visible,
    onClose,
    onSelectProject
}) => {
    const { sessionManager, currentProjectId } = useEditor()
    const [sessions, setSessions] = useState<SessionSummary[]>([])
    const [searchResults, setSearchResults] = useState<any[]>([])
    const [activeTab, setActiveTab] = useState<'sessions' | 'search'>('sessions')

    useEffect(() => {
        if (visible) {
            refreshSessions()
        }
    }, [visible])

    const refreshSessions = () => {
        const allSessions = sessionManager.getAllSessionSummaries()
        setSessions(allSessions)
    }

    const handleSearch = (query: string) => {
        if (query.trim()) {
            const results = sessionManager.searchMessages(query.trim())
            setSearchResults(results)
            setActiveTab('search')
        } else {
            setSearchResults([])
            setActiveTab('sessions')
        }
    }

    const handleDeleteSession = (projectId: string) => {
        sessionManager.deleteProjectSession(projectId)
        refreshSessions()
    }

    const handleSelectProject = (projectId: string, projectTitle: string) => {
        onSelectProject?.(projectId, projectTitle)
        onClose()
    }

    const formatDate = (date: Date) => {
        const now = new Date()
        const diff = now.getTime() - date.getTime()
        const minutes = Math.floor(diff / 60000)
        const hours = Math.floor(diff / 3600000)
        const days = Math.floor(diff / 86400000)

        if (minutes < 1) return '刚刚'
        if (minutes < 60) return `${minutes}分钟前`
        if (hours < 24) return `${hours}小时前`
        if (days < 7) return `${days}天前`
        return date.toLocaleDateString()
    }

    const renderSessionItem = (session: SessionSummary) => {
        const isCurrentProject = session.projectId === currentProjectId
        const stats = sessionManager.getProjectStats(session.projectId)

        return (
            <List.Item
                key={session.projectId}
                className={`session-item ${isCurrentProject ? 'current-project' : ''}`}
                actions={[
                    <Tooltip title="查看统计">
                        <Button
                            type="text"
                            icon={<HistoryOutlined />}
                            size="small"
                            onClick={() => {
                                // 可以扩展显示详细统计信息
                                console.log('Stats:', stats)
                            }}
                        />
                    </Tooltip>,
                    <Popconfirm
                        title="确定要删除这个小说的所有会话记录吗？"
                        onConfirm={() => handleDeleteSession(session.projectId)}
                        okText="删除"
                        cancelText="取消"
                        okType="danger"
                    >
                        <Button
                            type="text"
                            icon={<DeleteOutlined />}
                            size="small"
                            danger
                        />
                    </Popconfirm>
                ]}
                onClick={() => handleSelectProject(session.projectId, session.projectTitle)}
            >
                <List.Item.Meta
                    avatar={
                        <div className="project-avatar">
                            <ProjectOutlined />
                            {isCurrentProject && <div className="current-indicator" />}
                        </div>
                    }
                    title={
                        <Space>
                            <Text strong className={isCurrentProject ? 'current-project-title' : ''}>
                                {session.projectTitle}
                            </Text>
                            {isCurrentProject && <Badge status="processing" text="当前小说" />}
                        </Space>
                    }
                    description={
                        <div className="session-meta">
                            <div className="last-message">
                                <Text type="secondary">{session.lastMessage}</Text>
                            </div>
                            <div className="session-info">
                                <Space size="large">
                                    <span>
                                        <MessageOutlined style={{ marginRight: 4 }} />
                                        {session.messageCount} 条消息
                                    </span>
                                    <span>
                                        <ClockCircleOutlined style={{ marginRight: 4 }} />
                                        {formatDate(session.lastUpdated)}
                                    </span>
                                </Space>
                            </div>
                        </div>
                    }
                />
            </List.Item>
        )
    }

    const renderSearchResult = (result: any, index: number) => {
        return (
            <List.Item
                key={`${result.projectId}-${result.message.id}-${index}`}
                className="search-result-item"
                onClick={() => handleSelectProject(result.projectId, result.projectTitle)}
            >
                <List.Item.Meta
                    title={
                        <Space>
                            <ProjectOutlined />
                            <Text strong>{result.projectTitle}</Text>
                            <Badge 
                                color={result.message.type === 'user' ? 'blue' : 'green'} 
                                text={result.message.type === 'user' ? '用户' : 'AI'}
                            />
                        </Space>
                    }
                    description={
                        <div className="search-result-content">
                            <Text>{result.message.content}</Text>
                            <div className="search-result-time">
                                <ClockCircleOutlined style={{ marginRight: 4 }} />
                                <Text type="secondary">{formatDate(result.message.timestamp)}</Text>
                            </div>
                        </div>
                    }
                />
            </List.Item>
        )
    }

    return (
        <Modal
            title={
                <Space>
                    <HistoryOutlined />
                    小说会话历史
                </Space>
            }
            open={visible}
            onCancel={onClose}
            footer={null}
            width={800}
            className="session-history-modal"
        >
            <div className="session-history-content">
                <div className="search-section">
                    <Search
                        placeholder="搜索会话内容..."
                        allowClear
                        size="large"
                        prefix={<SearchOutlined />}
                        onSearch={handleSearch}
                        onChange={(e) => {
                            if (!e.target.value) {
                                setSearchResults([])
                                setActiveTab('sessions')
                            }
                        }}
                        style={{ marginBottom: 16 }}
                    />
                </div>

                <Divider orientation="left">
                    {activeTab === 'sessions' ? '所有小说会话' : `搜索结果 (${searchResults.length})`}
                </Divider>

                {activeTab === 'sessions' ? (
                    <List
                        dataSource={sessions}
                        renderItem={renderSessionItem}
                        locale={{ emptyText: '暂无会话记录' }}
                        className="sessions-list"
                    />
                ) : (
                    <List
                        dataSource={searchResults}
                        renderItem={renderSearchResult}
                        locale={{ emptyText: '没有找到相关内容' }}
                        className="search-results-list"
                    />
                )}

                {sessions.length === 0 && activeTab === 'sessions' && (
                    <div className="empty-state">
                        <div className="empty-icon">
                            <MessageOutlined style={{ fontSize: 48, color: '#d9d9d9' }} />
                        </div>
                        <Title level={4} type="secondary">还没有会话记录</Title>
                        <Text type="secondary">开始与AI助手对话，会话记录将自动保存到对应小说中</Text>
                    </div>
                )}
            </div>
        </Modal>
    )
}
