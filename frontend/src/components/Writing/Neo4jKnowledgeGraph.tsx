import React, { useState, useCallback, useEffect, useMemo } from 'react';
import ReactFlow, {
  Node,
  Edge,
  addEdge,
  Connection,
  useNodesState,
  useEdgesState,
  Controls,
  Background,
  MiniMap,
  Position,
  NodeTypes,
  Handle,
  MarkerType,
  ReactFlowProvider,
} from 'reactflow';
import 'reactflow/dist/style.css';
import {
  Card,
  Button,
  Modal,
  Form,
  Input,
  Select,
  Space,
  Tooltip,
  Badge,
  Typography,
  Divider,
  Collapse,
  Tag,
  Slider,
  Switch,
  message,
  Spin,
  Alert,
  Progress,
  Popover,
  List,
  Avatar,
  Statistic,
  Row,
  Col
} from 'antd';
import {
  UserOutlined,
  HomeOutlined,
  BookOutlined,
  HeartOutlined,
  TeamOutlined,
  BranchesOutlined,
  PlusOutlined,
  EditOutlined,
  DeleteOutlined,
  EyeOutlined,
  ShareAltOutlined,
  ReloadOutlined,
  SearchOutlined,
  FilterOutlined,
  SettingOutlined,
  InfoCircleOutlined,
  LinkOutlined,
  BulbOutlined,
  ThunderboltOutlined,
  ClockCircleOutlined,
  ExperimentOutlined,
  DatabaseOutlined
} from '@ant-design/icons';
import * as d3 from 'd3';
import { getNeo4jService, GraphNode, GraphRelationship, GraphData } from '../services/neo4jService';

const { Text, Title } = Typography;
const { Panel } = Collapse;
const { Option } = Select;

// 自定义节点组件
const KnowledgeGraphNode: React.FC<{ data: GraphNode }> = ({ data }) => {
  const getNodeStyle = () => {
    const baseStyle = {
      padding: '12px',
      borderRadius: '12px',
      border: '3px solid',
      background: 'white',
      minWidth: '140px',
      textAlign: 'center' as const,
      boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
      transition: 'all 0.3s ease'
    };

    const typeStyles = {
      CHARACTER: { borderColor: '#1890ff', background: 'linear-gradient(135deg, #e6f7ff 0%, #bae7ff 100%)' },
      LOCATION: { borderColor: '#52c41a', background: 'linear-gradient(135deg, #f6ffed 0%, #d9f7be 100%)' },
      EVENT: { borderColor: '#faad14', background: 'linear-gradient(135deg, #fffbe6 0%, #fff1b8 100%)' },
      CONCEPT: { borderColor: '#722ed1', background: 'linear-gradient(135deg, #f9f0ff 0%, #efdbff 100%)' },
      THEME: { borderColor: '#eb2f96', background: 'linear-gradient(135deg, #fff0f6 0%, #ffd6e7 100%)' },
      ORGANIZATION: { borderColor: '#fa541c', background: 'linear-gradient(135deg, #fff2e8 0%, #ffd8bf 100%)' },
      PLOT_POINT: { borderColor: '#13c2c2', background: 'linear-gradient(135deg, #e6fffb 0%, #b5f5ec 100%)' },
      TIMELINE: { borderColor: '#a0d911', background: 'linear-gradient(135deg, #fcffe6 0%, #eaff8f 100%)' }
    };

    return { ...baseStyle, ...typeStyles[data.type] };
  };

  const getIcon = () => {
    const icons = {
      CHARACTER: <UserOutlined style={{ fontSize: '16px' }} />,
      LOCATION: <HomeOutlined style={{ fontSize: '16px' }} />,
      EVENT: <ThunderboltOutlined style={{ fontSize: '16px' }} />,
      CONCEPT: <BranchesOutlined style={{ fontSize: '16px' }} />,
      THEME: <HeartOutlined style={{ fontSize: '16px' }} />,
      ORGANIZATION: <TeamOutlined style={{ fontSize: '16px' }} />,
      PLOT_POINT: <BookOutlined style={{ fontSize: '16px' }} />,
      TIMELINE: <ClockCircleOutlined style={{ fontSize: '16px' }} />
    };
    return icons[data.type];
  };

  const getImportanceColor = () => {
    const colors = {
      HIGH: '#ff4d4f',
      MEDIUM: '#faad14',
      LOW: '#d9d9d9'
    };
    return colors[data.importance];
  };

  return (
    <div style={getNodeStyle()}>
      <Handle type="target" position={Position.Top} style={{ background: '#555' }} />
      
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '6px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
          <Badge 
            dot 
            color={getImportanceColor()}
            offset={[-2, 2]}
          >
            {getIcon()}
          </Badge>
          <Text strong style={{ fontSize: '13px', maxWidth: '100px' }} ellipsis>
            {data.name}
          </Text>
        </div>
        
        <Text type="secondary" style={{ fontSize: '10px' }}>
          {data.type.toLowerCase().replace('_', ' ')}
        </Text>
        
        {data.tags && data.tags.length > 0 && (
          <div style={{ display: 'flex', gap: '2px', flexWrap: 'wrap', justifyContent: 'center' }}>
            {data.tags.slice(0, 2).map(tag => (
              <Tag key={tag} size="small" color="blue" style={{ fontSize: '9px', margin: 0, padding: '0 4px' }}>
                {tag}
              </Tag>
            ))}
            {data.tags.length > 2 && (
              <Tag size="small" color="default" style={{ fontSize: '9px', margin: 0, padding: '0 4px' }}>
                +{data.tags.length - 2}
              </Tag>
            )}
          </div>
        )}

        {data.status !== 'ACTIVE' && (
          <Tag color="orange" size="small" style={{ fontSize: '9px' }}>
            {data.status}
          </Tag>
        )}
      </div>
      
      <Handle type="source" position={Position.Bottom} style={{ background: '#555' }} />
    </div>
  );
};

// 知识图谱主组件
interface Neo4jKnowledgeGraphProps {
  projectId: string;
  height?: number;
  onNodeSelect?: (node: GraphNode) => void;
  onRelationshipSelect?: (relationship: GraphRelationship) => void;
  onGraphUpdate?: () => void;
}

const Neo4jKnowledgeGraph: React.FC<Neo4jKnowledgeGraphProps> = ({
  projectId,
  height = 600,
  onNodeSelect,
  onRelationshipSelect,
  onGraphUpdate
}) => {
  // 状态管理
  const [nodes, setNodes, onNodesChange] = useNodesState([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState([]);
  const [graphData, setGraphData] = useState<GraphData>({ nodes: [], relationships: [], statistics: { nodeCount: 0, relationshipCount: 0, typeDistribution: {} } });
  const [selectedNode, setSelectedNode] = useState<GraphNode | null>(null);
  const [selectedRelationship, setSelectedRelationship] = useState<GraphRelationship | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  // 模态框状态
  const [showAddNodeModal, setShowAddNodeModal] = useState(false);
  const [showAddRelationshipModal, setShowAddRelationshipModal] = useState(false);
  const [showNodeDetailsModal, setShowNodeDetailsModal] = useState(false);
  const [showRecommendationsModal, setShowRecommendationsModal] = useState(false);
  const [showPathFinderModal, setShowPathFinderModal] = useState(false);
  
  // 其他状态
  const [recommendations, setRecommendations] = useState<GraphNode[]>([]);
  const [pathFindingResult, setPathFindingResult] = useState<any>(null);
  const [filterType, setFilterType] = useState<string>('ALL');
  const [filterImportance, setFilterImportance] = useState<string>('ALL');
  const [connectionParams, setConnectionParams] = useState({ source: '', target: '' });
  
  const [form] = Form.useForm();
  const [pathForm] = Form.useForm();

  // Neo4j服务实例
  const neo4jService = useMemo(() => getNeo4jService(), []);

  // 自定义节点类型
  const nodeTypes: NodeTypes = {
    knowledgeNode: KnowledgeGraphNode,
  };

  // 初始化Neo4j连接
  useEffect(() => {
    const initializeService = async () => {
      try {
        setLoading(true);
        await neo4jService.initialize();
        await loadGraphData();
      } catch (error) {
        console.error('Neo4j初始化失败:', error);
        setError('Neo4j连接失败，请检查配置');
      } finally {
        setLoading(false);
      }
    };

    initializeService();

    // 清理函数
    return () => {
      neo4jService.close();
    };
  }, [projectId]);

  // 加载图谱数据
  const loadGraphData = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await neo4jService.getProjectKnowledgeGraph(projectId);
      setGraphData(data);
      convertToReactFlowData(data);
    } catch (error) {
      console.error('加载图谱数据失败:', error);
      setError('加载数据失败');
    } finally {
      setLoading(false);
    }
  };

  // 转换数据格式
  const convertToReactFlowData = (data: GraphData) => {
    // 使用D3力导向布局计算位置
    const simulation = d3.forceSimulation(data.nodes as any)
      .force('link', d3.forceLink(data.relationships).id((d: any) => d.id).distance(150))
      .force('charge', d3.forceManyBody().strength(-300))
      .force('center', d3.forceCenter(400, 300))
      .force('collision', d3.forceCollide().radius(80));

    // 运行模拟
    for (let i = 0; i < 100; ++i) simulation.tick();

    // 转换节点
    const reactFlowNodes = data.nodes.map(node => ({
      id: node.id,
      type: 'knowledgeNode',
      position: { x: (node as any).x || Math.random() * 800, y: (node as any).y || Math.random() * 600 },
      data: node,
    }));

    // 转换边
    const reactFlowEdges = data.relationships.map(relationship => ({
      id: relationship.id,
      source: relationship.startNodeId,
      target: relationship.endNodeId,
      type: 'default',
      animated: relationship.status === 'CURRENT',
      style: {
        stroke: getRelationshipColor(relationship.type),
        strokeWidth: Math.max(2, relationship.strength / 25),
      },
      label: relationship.type.replace(/_/g, ' ').toLowerCase(),
      labelStyle: { fontSize: '10px', fontWeight: 'bold' },
      markerEnd: {
        type: MarkerType.ArrowClosed,
        color: getRelationshipColor(relationship.type),
      },
      data: relationship,
    }));

    setNodes(reactFlowNodes);
    setEdges(reactFlowEdges);
  };

  // 获取关系类型颜色
  const getRelationshipColor = (type: GraphRelationship['type']) => {
    const colors = {
      KNOWS: '#52c41a',
      RELATED_TO: '#1890ff',
      PARTICIPATES_IN: '#722ed1',
      LOCATED_AT: '#13c2c2',
      INFLUENCES: '#fa541c',
      CONFLICTS_WITH: '#ff4d4f',
      LOVES: '#eb2f96',
      HATES: '#f5222d',
      MENTOR_OF: '#faad14',
      FAMILY_OF: '#52c41a',
      ALLIANCE_WITH: '#1890ff',
      OWNS: '#fa8c16',
      LEADS: '#722ed1',
      CAUSES: '#ff7a45',
      PRECEDES: '#13c2c2',
      FOLLOWS: '#36cfc9',
      SIMILAR_TO: '#95de64',
      OPPOSITE_OF: '#ff85c0'
    };
    return colors[type] || '#666';
  };

  // 过滤图谱数据
  const filteredData = useMemo(() => {
    let filteredNodes = graphData.nodes;
    let filteredRelationships = graphData.relationships;

    if (filterType !== 'ALL') {
      filteredNodes = filteredNodes.filter(node => node.type === filterType);
      const nodeIds = new Set(filteredNodes.map(n => n.id));
      filteredRelationships = filteredRelationships.filter(rel => 
        nodeIds.has(rel.startNodeId) && nodeIds.has(rel.endNodeId)
      );
    }

    if (filterImportance !== 'ALL') {
      filteredNodes = filteredNodes.filter(node => node.importance === filterImportance);
      const nodeIds = new Set(filteredNodes.map(n => n.id));
      filteredRelationships = filteredRelationships.filter(rel => 
        nodeIds.has(rel.startNodeId) && nodeIds.has(rel.endNodeId)
      );
    }

    return { nodes: filteredNodes, relationships: filteredRelationships };
  }, [graphData, filterType, filterImportance]);

  // 应用过滤器
  useEffect(() => {
    convertToReactFlowData({
      ...graphData,
      nodes: filteredData.nodes,
      relationships: filteredData.relationships
    });
  }, [filteredData]);

  // 处理连接
  const onConnect = useCallback((params: Connection) => {
    if (!params.source || !params.target) return;
    
    setConnectionParams({ source: params.source, target: params.target });
    setShowAddRelationshipModal(true);
    form.setFieldsValue({
      startNodeId: params.source,
      endNodeId: params.target,
    });
  }, [form]);

  // 处理节点点击
  const onNodeClick = useCallback((event: React.MouseEvent, node: Node) => {
    const graphNode = graphData.nodes.find(n => n.id === node.id);
    if (graphNode) {
      setSelectedNode(graphNode);
      onNodeSelect?.(graphNode);
    }
  }, [graphData.nodes, onNodeSelect]);

  // 处理边点击
  const onEdgeClick = useCallback((event: React.MouseEvent, edge: Edge) => {
    const relationship = graphData.relationships.find(r => r.id === edge.id);
    if (relationship) {
      setSelectedRelationship(relationship);
      onRelationshipSelect?.(relationship);
    }
  }, [graphData.relationships, onRelationshipSelect]);

  // 添加新节点
  const handleAddNode = async (values: any) => {
    try {
      setLoading(true);
      const newNode = await neo4jService.createNode({
        type: values.type,
        name: values.name,
        description: values.description,
        properties: {},
        importance: values.importance || 'MEDIUM',
        status: 'ACTIVE',
        tags: values.tags ? values.tags.split(',').map((t: string) => t.trim()) : [],
        projectId
      });

      await loadGraphData();
      setShowAddNodeModal(false);
      form.resetFields();
      onGraphUpdate?.();
      message.success('节点创建成功');
    } catch (error) {
      console.error('创建节点失败:', error);
      message.error('创建节点失败');
    } finally {
      setLoading(false);
    }
  };

  // 添加新关系
  const handleAddRelationship = async (values: any) => {
    try {
      setLoading(true);
      await neo4jService.createRelationship({
        type: values.type,
        startNodeId: values.startNodeId,
        endNodeId: values.endNodeId,
        strength: values.strength || 50,
        description: values.description,
        properties: {},
        bidirectional: values.bidirectional || false,
        status: 'CURRENT'
      });

      await loadGraphData();
      setShowAddRelationshipModal(false);
      form.resetFields();
      onGraphUpdate?.();
      message.success('关系创建成功');
    } catch (error) {
      console.error('创建关系失败:', error);
      message.error('创建关系失败');
    } finally {
      setLoading(false);
    }
  };

  // 获取推荐连接
  const handleGetRecommendations = async () => {
    if (!selectedNode) return;
    
    try {
      setLoading(true);
      const recs = await neo4jService.getRecommendedConnections(selectedNode.id);
      setRecommendations(recs);
      setShowRecommendationsModal(true);
    } catch (error) {
      console.error('获取推荐失败:', error);
      message.error('获取推荐失败');
    } finally {
      setLoading(false);
    }
  };

  // 查找路径
  const handleFindPath = async (values: any) => {
    try {
      setLoading(true);
      const result = await neo4jService.findShortestPath(values.startNode, values.endNode);
      setPathFindingResult(result);
      pathForm.resetFields();
    } catch (error) {
      console.error('路径查找失败:', error);
      message.error('路径查找失败');
    } finally {
      setLoading(false);
    }
  };

  // 删除节点
  const handleDeleteNode = async (nodeId: string) => {
    try {
      setLoading(true);
      await neo4jService.deleteNode(nodeId);
      await loadGraphData();
      setSelectedNode(null);
      setShowNodeDetailsModal(false);
      onGraphUpdate?.();
      message.success('节点删除成功');
    } catch (error) {
      console.error('删除节点失败:', error);
      message.error('删除节点失败');
    } finally {
      setLoading(false);
    }
  };

  if (error) {
    return (
      <Alert
        message="连接错误"
        description={error}
        type="error"
        showIcon
        action={
          <Button size="small" danger onClick={loadGraphData}>
            重试
          </Button>
        }
      />
    );
  }

  return (
    <div style={{ height: '100vh', display: 'flex' }}>
      {/* 主要图形区域 */}
      <div style={{ flex: 1, position: 'relative' }}>
        <Spin spinning={loading} tip="正在处理...">
          <ReactFlowProvider>
            <ReactFlow
              nodes={nodes}
              edges={edges}
              onNodesChange={onNodesChange}
              onEdgesChange={onEdgesChange}
              onConnect={onConnect}
              onNodeClick={onNodeClick}
              onEdgeClick={onEdgeClick}
              nodeTypes={nodeTypes}
              fitView
              attributionPosition="bottom-left"
              style={{ height }}
            >
              <Background />
              <Controls />
              <MiniMap 
                nodeStrokeColor={(n) => '#333'}
                nodeColor={(n) => {
                  const data = n.data as GraphNode;
                  return data?.type === 'CHARACTER' ? '#1890ff' : '#52c41a';
                }}
                nodeBorderRadius={2}
              />
            </ReactFlow>
          </ReactFlowProvider>
        </Spin>

        {/* 浮动操作按钮 */}
        <div style={{ 
          position: 'absolute', 
          top: '10px', 
          right: '10px', 
          display: 'flex', 
          flexDirection: 'column',
          gap: '8px'
        }}>
          <Button 
            type="primary" 
            icon={<PlusOutlined />} 
            onClick={() => setShowAddNodeModal(true)}
          >
            添加节点
          </Button>
          <Button 
            icon={<ReloadOutlined />} 
            onClick={loadGraphData}
          >
            刷新
          </Button>
          <Button 
            icon={<BulbOutlined />} 
            onClick={handleGetRecommendations}
            disabled={!selectedNode}
          >
            智能推荐
          </Button>
          <Button 
            icon={<LinkOutlined />} 
            onClick={() => setShowPathFinderModal(true)}
          >
            路径查找
          </Button>
        </div>
      </div>

      {/* 侧边栏 */}
      <Card 
        title={
          <Space>
            <DatabaseOutlined />
            <span>知识图谱</span>
            <Badge count={graphData.statistics.nodeCount} />
          </Space>
        } 
        style={{ width: '350px', height: '100vh', overflow: 'auto' }}
        size="small"
      >
        <Collapse size="small" defaultActiveKey={['stats', 'filters', 'nodes']}>
          {/* 统计信息 */}
          <Panel header="统计信息" key="stats">
            <Row gutter={[8, 8]}>
              <Col span={12}>
                <Statistic title="节点" value={graphData.statistics.nodeCount} prefix={<UserOutlined />} />
              </Col>
              <Col span={12}>
                <Statistic title="关系" value={graphData.statistics.relationshipCount} prefix={<LinkOutlined />} />
              </Col>
            </Row>
            <Divider style={{ margin: '12px 0' }} />
            <div>
              <Text strong style={{ fontSize: '12px' }}>类型分布:</Text>
              {Object.entries(graphData.statistics.typeDistribution).map(([type, count]) => (
                <div key={type} style={{ display: 'flex', justifyContent: 'space-between', marginTop: '4px' }}>
                  <Text style={{ fontSize: '11px' }}>{type}:</Text>
                  <Badge count={count} style={{ backgroundColor: '#52c41a' }} />
                </div>
              ))}
            </div>
          </Panel>

          {/* 过滤器 */}
          <Panel header="过滤器" key="filters">
            <Space direction="vertical" style={{ width: '100%' }}>
              <div>
                <Text strong style={{ fontSize: '12px' }}>类型:</Text>
                <Select 
                  size="small" 
                  value={filterType} 
                  onChange={setFilterType}
                  style={{ width: '100%', marginTop: '4px' }}
                >
                  <Option value="ALL">全部</Option>
                  <Option value="CHARACTER">角色</Option>
                  <Option value="LOCATION">地点</Option>
                  <Option value="EVENT">事件</Option>
                  <Option value="CONCEPT">概念</Option>
                  <Option value="THEME">主题</Option>
                  <Option value="ORGANIZATION">组织</Option>
                  <Option value="PLOT_POINT">情节点</Option>
                  <Option value="TIMELINE">时间线</Option>
                </Select>
              </div>
              
              <div>
                <Text strong style={{ fontSize: '12px' }}>重要性:</Text>
                <Select 
                  size="small" 
                  value={filterImportance} 
                  onChange={setFilterImportance}
                  style={{ width: '100%', marginTop: '4px' }}
                >
                  <Option value="ALL">全部</Option>
                  <Option value="HIGH">高</Option>
                  <Option value="MEDIUM">中</Option>
                  <Option value="LOW">低</Option>
                </Select>
              </div>
            </Space>
          </Panel>

          {/* 节点列表 */}
          <Panel header="节点列表" key="nodes">
            <List
              size="small"
              dataSource={filteredData.nodes}
              renderItem={(node) => (
                <List.Item
                  style={{ cursor: 'pointer', padding: '8px' }}
                  onClick={() => {
                    setSelectedNode(node);
                    setShowNodeDetailsModal(true);
                  }}
                >
                  <List.Item.Meta
                    avatar={
                      <Avatar 
                        size="small" 
                        style={{ 
                          backgroundColor: node.type === 'CHARACTER' ? '#1890ff' : '#52c41a' 
                        }}
                      >
                        {node.type === 'CHARACTER' ? <UserOutlined /> : <HomeOutlined />}
                      </Avatar>
                    }
                    title={<Text style={{ fontSize: '12px' }}>{node.name}</Text>}
                    description={
                      <Space>
                        <Tag size="small" color="blue">{node.type}</Tag>
                        <Tag size="small" color={
                          node.importance === 'HIGH' ? 'red' :
                          node.importance === 'MEDIUM' ? 'orange' : 'green'
                        }>
                          {node.importance}
                        </Tag>
                      </Space>
                    }
                  />
                </List.Item>
              )}
            />
          </Panel>
        </Collapse>
      </Card>

      {/* 模态框组件 */}
      {/* 添加节点模态框 */}
      <Modal
        title="添加新节点"
        open={showAddNodeModal}
        onCancel={() => {
          setShowAddNodeModal(false);
          form.resetFields();
        }}
        onOk={() => form.submit()}
        okText="创建"
        cancelText="取消"
        confirmLoading={loading}
      >
        <Form form={form} onFinish={handleAddNode} layout="vertical">
          <Form.Item name="type" label="类型" rules={[{ required: true }]}>
            <Select placeholder="选择节点类型">
              <Option value="CHARACTER">角色</Option>
              <Option value="LOCATION">地点</Option>
              <Option value="EVENT">事件</Option>
              <Option value="CONCEPT">概念</Option>
              <Option value="THEME">主题</Option>
              <Option value="ORGANIZATION">组织</Option>
              <Option value="PLOT_POINT">情节点</Option>
              <Option value="TIMELINE">时间线</Option>
            </Select>
          </Form.Item>
          
          <Form.Item name="name" label="名称" rules={[{ required: true }]}>
            <Input placeholder="节点名称" />
          </Form.Item>
          
          <Form.Item name="description" label="描述">
            <Input.TextArea placeholder="节点描述" rows={3} />
          </Form.Item>
          
          <Form.Item name="importance" label="重要程度" initialValue="MEDIUM">
            <Select>
              <Option value="HIGH">高</Option>
              <Option value="MEDIUM">中</Option>
              <Option value="LOW">低</Option>
            </Select>
          </Form.Item>
          
          <Form.Item name="tags" label="标签">
            <Input placeholder="标签，用逗号分隔" />
          </Form.Item>
        </Form>
      </Modal>

      {/* 添加关系模态框 */}
      <Modal
        title="添加关系"
        open={showAddRelationshipModal}
        onCancel={() => {
          setShowAddRelationshipModal(false);
          form.resetFields();
        }}
        onOk={() => form.submit()}
        okText="创建"
        cancelText="取消"
        confirmLoading={loading}
      >
        <Form form={form} onFinish={handleAddRelationship} layout="vertical">
          <Form.Item name="startNodeId" label="起始节点">
            <Select placeholder="选择起始节点" disabled>
              {graphData.nodes.map(node => (
                <Option key={node.id} value={node.id}>
                  {node.name}
                </Option>
              ))}
            </Select>
          </Form.Item>
          
          <Form.Item name="endNodeId" label="目标节点">
            <Select placeholder="选择目标节点" disabled>
              {graphData.nodes.map(node => (
                <Option key={node.id} value={node.id}>
                  {node.name}
                </Option>
              ))}
            </Select>
          </Form.Item>
          
          <Form.Item name="type" label="关系类型" rules={[{ required: true }]}>
            <Select placeholder="选择关系类型">
              <Option value="KNOWS">认识</Option>
              <Option value="RELATED_TO">相关</Option>
              <Option value="LOVES">喜欢</Option>
              <Option value="HATES">讨厌</Option>
              <Option value="FAMILY_OF">家人</Option>
              <Option value="MENTOR_OF">导师</Option>
              <Option value="CONFLICTS_WITH">冲突</Option>
              <Option value="ALLIANCE_WITH">联盟</Option>
              <Option value="INFLUENCES">影响</Option>
              <Option value="OWNS">拥有</Option>
              <Option value="LEADS">领导</Option>
              <Option value="PARTICIPATES_IN">参与</Option>
              <Option value="LOCATED_AT">位于</Option>
            </Select>
          </Form.Item>
          
          <Form.Item name="strength" label="关系强度" initialValue={50}>
            <Slider min={0} max={100} />
          </Form.Item>
          
          <Form.Item name="description" label="关系描述">
            <Input.TextArea placeholder="描述这个关系" rows={2} />
          </Form.Item>
          
          <Form.Item name="bidirectional" label="双向关系" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>
      </Modal>

      {/* 节点详情模态框 */}
      <Modal
        title={selectedNode?.name}
        open={showNodeDetailsModal}
        onCancel={() => setShowNodeDetailsModal(false)}
        footer={[
          <Button 
            key="delete" 
            icon={<DeleteOutlined />} 
            danger 
            onClick={() => selectedNode && handleDeleteNode(selectedNode.id)}
          >
            删除
          </Button>,
          <Button key="close" onClick={() => setShowNodeDetailsModal(false)}>
            关闭
          </Button>
        ]}
        width={700}
      >
        {selectedNode && (
          <Space direction="vertical" style={{ width: '100%' }}>
            <Row gutter={16}>
              <Col span={12}>
                <Text strong>类型: </Text>
                <Tag color="blue">{selectedNode.type}</Tag>
              </Col>
              <Col span={12}>
                <Text strong>重要程度: </Text>
                <Tag color={
                  selectedNode.importance === 'HIGH' ? 'red' :
                  selectedNode.importance === 'MEDIUM' ? 'orange' : 'green'
                }>
                  {selectedNode.importance}
                </Tag>
              </Col>
            </Row>
            
            <div>
              <Text strong>描述: </Text>
              <Text>{selectedNode.description || '暂无描述'}</Text>
            </div>
            
            <div>
              <Text strong>标签: </Text>
              <Space wrap>
                {selectedNode.tags.map(tag => (
                  <Tag key={tag}>{tag}</Tag>
                ))}
              </Space>
            </div>
            
            <div>
              <Text strong>状态: </Text>
              <Tag color={selectedNode.status === 'ACTIVE' ? 'green' : 'orange'}>
                {selectedNode.status}
              </Tag>
            </div>
            
            <div>
              <Text strong>创建时间: </Text>
              <Text>{new Date(selectedNode.createdAt).toLocaleString()}</Text>
            </div>
            
            <div>
              <Text strong>更新时间: </Text>
              <Text>{new Date(selectedNode.updatedAt).toLocaleString()}</Text>
            </div>
          </Space>
        )}
      </Modal>

      {/* 智能推荐模态框 */}
      <Modal
        title="智能推荐连接"
        open={showRecommendationsModal}
        onCancel={() => setShowRecommendationsModal(false)}
        footer={[
          <Button key="close" onClick={() => setShowRecommendationsModal(false)}>
            关闭
          </Button>
        ]}
        width={600}
      >
        <List
          dataSource={recommendations}
          renderItem={(node) => (
            <List.Item>
              <List.Item.Meta
                avatar={
                  <Avatar style={{ backgroundColor: '#1890ff' }}>
                    <UserOutlined />
                  </Avatar>
                }
                title={node.name}
                description={
                  <Space>
                    <Tag color="blue">{node.type}</Tag>
                    <Tag color="green">推荐连接</Tag>
                  </Space>
                }
              />
              <Button 
                type="primary" 
                size="small"
                onClick={() => {
                  setConnectionParams({ source: selectedNode!.id, target: node.id });
                  setShowAddRelationshipModal(true);
                  setShowRecommendationsModal(false);
                  form.setFieldsValue({
                    startNodeId: selectedNode!.id,
                    endNodeId: node.id,
                  });
                }}
              >
                创建连接
              </Button>
            </List.Item>
          )}
        />
      </Modal>

      {/* 路径查找模态框 */}
      <Modal
        title="路径查找"
        open={showPathFinderModal}
        onCancel={() => setShowPathFinderModal(false)}
        onOk={() => pathForm.submit()}
        okText="查找"
        cancelText="取消"
        confirmLoading={loading}
        width={700}
      >
        <Form form={pathForm} onFinish={handleFindPath} layout="vertical">
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="startNode" label="起始节点" rules={[{ required: true }]}>
                <Select placeholder="选择起始节点" showSearch optionFilterProp="children">
                  {graphData.nodes.map(node => (
                    <Option key={node.id} value={node.id}>
                      {node.name} ({node.type})
                    </Option>
                  ))}
                </Select>
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="endNode" label="目标节点" rules={[{ required: true }]}>
                <Select placeholder="选择目标节点" showSearch optionFilterProp="children">
                  {graphData.nodes.map(node => (
                    <Option key={node.id} value={node.id}>
                      {node.name} ({node.type})
                    </Option>
                  ))}
                </Select>
              </Form.Item>
            </Col>
          </Row>
        </Form>
        
        {pathFindingResult && (
          <div style={{ marginTop: '16px' }}>
            <Divider />
            <Title level={5}>查找结果:</Title>
            {pathFindingResult ? (
              <div>
                <Text>路径长度: {pathFindingResult.length}</Text>
                <div style={{ marginTop: '8px' }}>
                  {pathFindingResult.path.map((item: any, index: number) => (
                    <span key={index}>
                      <Tag color="blue">{item.node.name}</Tag>
                      {index < pathFindingResult.path.length - 1 && (
                        <span style={{ margin: '0 8px' }}>→</span>
                      )}
                    </span>
                  ))}
                </div>
              </div>
            ) : (
              <Text type="secondary">未找到连接路径</Text>
            )}
          </div>
        )}
      </Modal>
    </div>
  );
};

export default Neo4jKnowledgeGraph;
