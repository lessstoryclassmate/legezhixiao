import React, { useState, useEffect } from 'react';
import {
  Card,
  Tabs,
  Alert,
  Button,
  Space,
  Typography,
  Badge,
  Tooltip,
  Modal,
  Spin,
  message,
  Row,
  Col,
  Statistic,
  Progress,
  Timeline
} from 'antd';
import {
  DatabaseOutlined,
  SettingOutlined,
  BranchesOutlined,
  InfoCircleOutlined,
  ExperimentOutlined,
  CheckCircleOutlined,
  ExclamationCircleOutlined,
  ReloadOutlined,
  CloudServerOutlined,
  BookOutlined,
  UserOutlined,
  ThunderboltOutlined
} from '@ant-design/icons';
import Neo4jKnowledgeGraph from './Neo4jKnowledgeGraph';
import Neo4jConfigPanel from './Neo4jConfigPanel';
import { getNeo4jService, GraphData, GraphNode, GraphRelationship } from '../services/neo4jService';

const { Title, Text, Paragraph } = Typography;
const { TabPane } = Tabs;

interface KnowledgeGraphManagerProps {
  projectId: string;
  visible?: boolean;
  onClose?: () => void;
}

interface SystemStatus {
  neo4jConnected: boolean;
  databaseInitialized: boolean;
  graphSize: {
    nodes: number;
    relationships: number;
  };
  lastUpdate?: Date;
  error?: string;
}

const KnowledgeGraphManager: React.FC<KnowledgeGraphManagerProps> = ({
  projectId,
  visible = true,
  onClose
}) => {
  // 状态管理
  const [activeTab, setActiveTab] = useState('graph');
  const [systemStatus, setSystemStatus] = useState<SystemStatus>({
    neo4jConnected: false,
    databaseInitialized: false,
    graphSize: { nodes: 0, relationships: 0 }
  });
  const [loading, setLoading] = useState(true);
  const [graphData, setGraphData] = useState<GraphData | null>(null);
  const [selectedNode, setSelectedNode] = useState<GraphNode | null>(null);
  const [selectedRelationship, setSelectedRelationship] = useState<GraphRelationship | null>(null);
  const [showWelcomeModal, setShowWelcomeModal] = useState(false);

  // Neo4j 服务实例
  const neo4jService = getNeo4jService();

  // 初始化
  useEffect(() => {
    initializeSystem();
  }, [projectId]);

  // 检查是否首次使用
  useEffect(() => {
    const hasSeenWelcome = localStorage.getItem('knowledge-graph-welcome');
    if (!hasSeenWelcome) {
      setShowWelcomeModal(true);
    }
  }, []);

  // 系统初始化
  const initializeSystem = async () => {
    try {
      setLoading(true);
      
      // 检查Neo4j连接
      const isConnected = await checkNeo4jConnection();
      
      if (isConnected) {
        // 检查数据库初始化状态
        const isInitialized = await checkDatabaseInitialization();
        
        if (isInitialized) {
          // 加载图谱数据
          await loadGraphData();
        }
        
        setSystemStatus(prev => ({
          ...prev,
          neo4jConnected: isConnected,
          databaseInitialized: isInitialized
        }));
      }
    } catch (error: any) {
      console.error('系统初始化失败:', error);
      setSystemStatus(prev => ({
        ...prev,
        error: error.message
      }));
    } finally {
      setLoading(false);
    }
  };

  // 检查Neo4j连接
  const checkNeo4jConnection = async (): Promise<boolean> => {
    try {
      return await neo4jService.isConnected();
    } catch (error) {
      console.error('检查Neo4j连接失败:', error);
      return false;
    }
  };

  // 检查数据库初始化状态
  const checkDatabaseInitialization = async (): Promise<boolean> => {
    try {
      // 尝试运行一个简单的查询来检查约束是否存在
      const result = await neo4jService.runQuery(
        'SHOW CONSTRAINTS YIELD name WHERE name CONTAINS "GraphNode"',
        {}
      );
      return result.records.length > 0;
    } catch (error) {
      console.error('检查数据库初始化状态失败:', error);
      return false;
    }
  };

  // 加载图谱数据
  const loadGraphData = async () => {
    try {
      const data = await neo4jService.getProjectKnowledgeGraph(projectId);
      setGraphData(data);
      
      setSystemStatus(prev => ({
        ...prev,
        graphSize: {
          nodes: data.statistics.nodeCount,
          relationships: data.statistics.relationshipCount
        },
        lastUpdate: new Date()
      }));
    } catch (error) {
      console.error('加载图谱数据失败:', error);
      message.error('加载图谱数据失败');
    }
  };

  // 初始化数据库
  const initializeDatabase = async () => {
    try {
      setLoading(true);
      await neo4jService.initializeConstraints();
      await initializeSystem();
      message.success('数据库初始化成功');
    } catch (error: any) {
      console.error('数据库初始化失败:', error);
      message.error(`数据库初始化失败: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  // 处理节点选择
  const handleNodeSelect = (node: GraphNode) => {
    setSelectedNode(node);
  };

  // 处理关系选择
  const handleRelationshipSelect = (relationship: GraphRelationship) => {
    setSelectedRelationship(relationship);
  };

  // 处理图谱更新
  const handleGraphUpdate = () => {
    loadGraphData();
  };

  // 关闭欢迎弹窗
  const handleCloseWelcome = () => {
    setShowWelcomeModal(false);
    localStorage.setItem('knowledge-graph-welcome', 'true');
  };

  // 获取系统状态显示
  const getSystemStatusComponent = () => {
    if (loading) {
      return (
        <Card>
          <div style={{ textAlign: 'center', padding: '40px' }}>
            <Spin size="large" />
            <div style={{ marginTop: '16px' }}>
              <Text>正在初始化知识图谱系统...</Text>
            </div>
          </div>
        </Card>
      );
    }

    if (!systemStatus.neo4jConnected) {
      return (
        <Card>
          <Alert
            message="Neo4j 未连接"
            description={
              <div>
                <Paragraph>
                  知识图谱功能需要连接到Neo4j数据库。请先配置数据库连接。
                </Paragraph>
                <Button 
                  type="primary" 
                  icon={<SettingOutlined />}
                  onClick={() => setActiveTab('config')}
                >
                  配置数据库连接
                </Button>
              </div>
            }
            type="warning"
            showIcon
          />
        </Card>
      );
    }

    if (!systemStatus.databaseInitialized) {
      return (
        <Card>
          <Alert
            message="数据库未初始化"
            description={
              <div>
                <Paragraph>
                  数据库连接正常，但需要初始化约束和索引。
                </Paragraph>
                <Button 
                  type="primary" 
                  icon={<DatabaseOutlined />}
                  onClick={initializeDatabase}
                  loading={loading}
                >
                  初始化数据库
                </Button>
              </div>
            }
            type="info"
            showIcon
          />
        </Card>
      );
    }

    return null;
  };

  // 渲染状态面板
  const renderStatusPanel = () => (
    <Card title="系统状态" size="small">
      <Row gutter={[16, 16]}>
        <Col span={6}>
          <Statistic
            title="Neo4j连接"
            value={systemStatus.neo4jConnected ? '已连接' : '未连接'}
            prefix={
              systemStatus.neo4jConnected ? 
                <CheckCircleOutlined style={{ color: '#52c41a' }} /> : 
                <ExclamationCircleOutlined style={{ color: '#ff4d4f' }} />
            }
            valueStyle={{ 
              color: systemStatus.neo4jConnected ? '#52c41a' : '#ff4d4f',
              fontSize: '14px'
            }}
          />
        </Col>
        <Col span={6}>
          <Statistic
            title="数据库状态"
            value={systemStatus.databaseInitialized ? '已初始化' : '未初始化'}
            prefix={
              systemStatus.databaseInitialized ? 
                <DatabaseOutlined style={{ color: '#52c41a' }} /> : 
                <ExclamationCircleOutlined style={{ color: '#faad14' }} />
            }
            valueStyle={{ 
              color: systemStatus.databaseInitialized ? '#52c41a' : '#faad14',
              fontSize: '14px'
            }}
          />
        </Col>
        <Col span={6}>
          <Statistic
            title="图谱节点"
            value={systemStatus.graphSize.nodes}
            prefix={<UserOutlined />}
            valueStyle={{ fontSize: '14px' }}
          />
        </Col>
        <Col span={6}>
          <Statistic
            title="图谱关系"
            value={systemStatus.graphSize.relationships}
            prefix={<BranchesOutlined />}
            valueStyle={{ fontSize: '14px' }}
          />
        </Col>
      </Row>
      
      {systemStatus.lastUpdate && (
        <div style={{ marginTop: '12px', textAlign: 'center' }}>
          <Text type="secondary" style={{ fontSize: '12px' }}>
            最后更新: {systemStatus.lastUpdate.toLocaleString()}
          </Text>
        </div>
      )}
    </Card>
  );

  // 渲染选中元素信息
  const renderSelectionInfo = () => {
    if (!selectedNode && !selectedRelationship) {
      return (
        <Card title="选中信息" size="small">
          <div style={{ textAlign: 'center', padding: '20px', color: '#999' }}>
            <InfoCircleOutlined style={{ fontSize: '24px', marginBottom: '8px' }} />
            <div>点击节点或关系查看详细信息</div>
          </div>
        </Card>
      );
    }

    if (selectedNode) {
      return (
        <Card title={`节点: ${selectedNode.name}`} size="small">
          <Space direction="vertical" style={{ width: '100%' }}>
            <div><Text strong>类型:</Text> {selectedNode.type}</div>
            <div><Text strong>重要程度:</Text> {selectedNode.importance}</div>
            <div><Text strong>状态:</Text> {selectedNode.status}</div>
            {selectedNode.description && (
              <div><Text strong>描述:</Text> {selectedNode.description}</div>
            )}
            {selectedNode.tags.length > 0 && (
              <div>
                <Text strong>标签:</Text>
                <div style={{ marginTop: '4px' }}>
                  {selectedNode.tags.map(tag => (
                    <Badge key={tag} count={tag} style={{ backgroundColor: '#108ee9' }} />
                  ))}
                </div>
              </div>
            )}
          </Space>
        </Card>
      );
    }

    if (selectedRelationship) {
      return (
        <Card title={`关系: ${selectedRelationship.type}`} size="small">
          <Space direction="vertical" style={{ width: '100%' }}>
            <div><Text strong>类型:</Text> {selectedRelationship.type}</div>
            <div><Text strong>强度:</Text> {selectedRelationship.strength}/100</div>
            <div><Text strong>状态:</Text> {selectedRelationship.status}</div>
            <div><Text strong>双向:</Text> {selectedRelationship.bidirectional ? '是' : '否'}</div>
            {selectedRelationship.description && (
              <div><Text strong>描述:</Text> {selectedRelationship.description}</div>
            )}
            <Progress percent={selectedRelationship.strength} size="small" />
          </Space>
        </Card>
      );
    }

    return null;
  };

  const systemStatusComponent = getSystemStatusComponent();

  return (
    <>
      <div style={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
        {/* 顶部状态栏 */}
        <div style={{ padding: '16px', borderBottom: '1px solid #f0f0f0' }}>
          {renderStatusPanel()}
        </div>

        {/* 主要内容 */}
        <div style={{ flex: 1, overflow: 'hidden' }}>
          {systemStatusComponent ? (
            <div style={{ padding: '24px' }}>
              {systemStatusComponent}
            </div>
          ) : (
            <Tabs 
              activeKey={activeTab} 
              onChange={setActiveTab}
              style={{ height: '100%' }}
              items={[
                {
                  key: 'graph',
                  label: (
                    <Space>
                      <BranchesOutlined />
                      <span>知识图谱</span>
                      <Badge count={systemStatus.graphSize.nodes} />
                    </Space>
                  ),
                  children: (
                    <div style={{ height: 'calc(100vh - 140px)', display: 'flex' }}>
                      <div style={{ flex: 1 }}>
                        <Neo4jKnowledgeGraph
                          projectId={projectId}
                          height={window.innerHeight - 140}
                          onNodeSelect={handleNodeSelect}
                          onRelationshipSelect={handleRelationshipSelect}
                          onGraphUpdate={handleGraphUpdate}
                        />
                      </div>
                      <div style={{ width: '300px', padding: '16px' }}>
                        {renderSelectionInfo()}
                      </div>
                    </div>
                  )
                },
                {
                  key: 'config',
                  label: (
                    <Space>
                      <SettingOutlined />
                      <span>数据库配置</span>
                      <Badge 
                        status={systemStatus.neo4jConnected ? 'success' : 'error'} 
                      />
                    </Space>
                  ),
                  children: (
                    <div style={{ padding: '16px', height: 'calc(100vh - 140px)', overflow: 'auto' }}>
                      <Neo4jConfigPanel />
                    </div>
                  )
                },
                {
                  key: 'analytics',
                  label: (
                    <Space>
                      <ExperimentOutlined />
                      <span>图谱分析</span>
                    </Space>
                  ),
                  children: (
                    <div style={{ padding: '24px' }}>
                      <Card title="图谱分析功能">
                        <Alert
                          message="功能开发中"
                          description="图谱分析功能正在开发中，将包括：节点重要性分析、社区发现、路径分析、相似性检测等。"
                          type="info"
                          showIcon
                        />
                      </Card>
                    </div>
                  )
                }
              ]}
            />
          )}
        </div>
      </div>

      {/* 欢迎弹窗 */}
      <Modal
        title={
          <Space>
            <ThunderboltOutlined style={{ color: '#1890ff' }} />
            <span>欢迎使用知识图谱</span>
          </Space>
        }
        open={showWelcomeModal}
        onOk={handleCloseWelcome}
        onCancel={handleCloseWelcome}
        width={700}
        okText="开始使用"
        cancelText="稍后再说"
      >
        <div style={{ padding: '16px' }}>
          <Paragraph>
            <Text strong>知识图谱</Text> 是一个强大的工具，可以帮助您：
          </Paragraph>
          
          <Timeline
            items={[
              {
                dot: <UserOutlined style={{ color: '#1890ff' }} />,
                children: <Text><Text strong>角色管理:</Text> 创建和管理小说中的角色，建立角色之间的关系</Text>
              },
              {
                dot: <BookOutlined style={{ color: '#52c41a' }} />,
                children: <Text><Text strong>情节分析:</Text> 可视化情节发展，追踪事件之间的因果关系</Text>
              },
              {
                dot: <BranchesOutlined style={{ color: '#722ed1' }} />,
                children: <Text><Text strong>关系网络:</Text> 构建复杂的人物关系网，发现潜在的故事线索</Text>
              },
              {
                dot: <ThunderboltOutlined style={{ color: '#fa541c' }} />,
                children: <Text><Text strong>智能推荐:</Text> 基于现有关系，智能推荐可能的新连接</Text>
              }
            ]}
          />
          
          <Alert
            message="开始前准备"
            description={
              <div>
                <Paragraph style={{ marginBottom: '8px' }}>
                  使用知识图谱功能需要：
                </Paragraph>
                <ul style={{ paddingLeft: '20px', margin: 0 }}>
                  <li>安装并运行 Neo4j 数据库</li>
                  <li>配置数据库连接参数</li>
                  <li>初始化数据库约束和索引</li>
                </ul>
              </div>
            }
            type="info"
            style={{ marginTop: '16px' }}
          />
        </div>
      </Modal>
    </>
  );
};

export default KnowledgeGraphManager;
