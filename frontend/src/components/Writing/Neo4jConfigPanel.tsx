import React, { useState, useEffect } from 'react';
import {
  Card,
  Form,
  Input,
  Button,
  Alert,
  Space,
  Typography,
  Divider,
  Switch,
  Spin,
  message,
  Tooltip,
  Steps,
  Row,
  Col,
  Statistic,
  Badge,
  Collapse,
  Tag
} from 'antd';
import {
  DatabaseOutlined,
  CheckCircleOutlined,
  ExclamationCircleOutlined,
  InfoCircleOutlined,
  SettingOutlined,
  ThunderboltOutlined,
  LinkOutlined,
  SecurityScanOutlined,
  CloudServerOutlined,
  UserOutlined
} from '@ant-design/icons';
import { getNeo4jService } from '../services/neo4jService';

const { Title, Text, Paragraph } = Typography;
const { Panel } = Collapse;
const { Step } = Steps;

interface Neo4jConfig {
  uri: string;
  username: string;
  password: string;
  database?: string;
  encrypted?: boolean;
  maxConnectionPoolSize?: number;
  connectionTimeout?: number;
  maxTransactionRetryTime?: number;
}

interface ConnectionStatus {
  connected: boolean;
  database?: string;
  version?: string;
  mode?: string;
  role?: string;
  address?: string;
  lastChecked?: Date;
  error?: string;
}

const Neo4jConfigPanel: React.FC = () => {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [testLoading, setTestLoading] = useState(false);
  const [connectionStatus, setConnectionStatus] = useState<ConnectionStatus>({ connected: false });
  const [currentConfig, setCurrentConfig] = useState<Neo4jConfig>({
    uri: 'bolt://localhost:7687',
    username: 'neo4j',
    password: '',
    database: 'neo4j',
    encrypted: false,
    maxConnectionPoolSize: 50,
    connectionTimeout: 30000,
    maxTransactionRetryTime: 30000
  });
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [currentStep, setCurrentStep] = useState(0);

  // Neo4j 服务实例
  const neo4jService = getNeo4jService();

  // 初始化
  useEffect(() => {
    loadConfig();
    checkConnection();
  }, []);

  // 加载配置
  const loadConfig = () => {
    const savedConfig = localStorage.getItem('neo4j-config');
    if (savedConfig) {
      try {
        const config = JSON.parse(savedConfig);
        setCurrentConfig(config);
        form.setFieldsValue(config);
      } catch (error) {
        console.error('加载配置失败:', error);
      }
    }
  };

  // 保存配置
  const saveConfig = (config: Neo4jConfig) => {
    localStorage.setItem('neo4j-config', JSON.stringify(config));
    setCurrentConfig(config);
  };

  // 测试连接
  const testConnection = async (config?: Neo4jConfig) => {
    const testConfig = config || currentConfig;
    
    try {
      setTestLoading(true);
      
      // 临时配置服务
      await neo4jService.configure(testConfig);
      await neo4jService.initialize();
      
      // 获取数据库信息
      const info = await neo4jService.getDatabaseInfo();
      
      setConnectionStatus({
        connected: true,
        database: info.database,
        version: info.version,
        mode: info.mode,
        role: info.role,
        address: info.address,
        lastChecked: new Date()
      });

      message.success('连接成功！');
      setCurrentStep(2);
      
      return true;
    } catch (error: any) {
      console.error('连接测试失败:', error);
      setConnectionStatus({
        connected: false,
        error: error.message || '连接失败',
        lastChecked: new Date()
      });
      message.error(`连接失败: ${error.message}`);
      return false;
    } finally {
      setTestLoading(false);
    }
  };

  // 检查当前连接状态
  const checkConnection = async () => {
    try {
      const isConnected = await neo4jService.isConnected();
      if (isConnected) {
        await testConnection();
      }
    } catch (error) {
      console.error('检查连接状态失败:', error);
    }
  };

  // 保存并应用配置
  const handleSaveConfig = async (values: any) => {
    try {
      setLoading(true);
      
      const config: Neo4jConfig = {
        uri: values.uri,
        username: values.username,
        password: values.password,
        database: values.database || 'neo4j',
        encrypted: values.encrypted || false,
        maxConnectionPoolSize: values.maxConnectionPoolSize || 50,
        connectionTimeout: values.connectionTimeout || 30000,
        maxTransactionRetryTime: values.maxTransactionRetryTime || 30000
      };

      // 测试连接
      const isValid = await testConnection(config);
      
      if (isValid) {
        saveConfig(config);
        message.success('配置已保存并应用');
        setCurrentStep(3);
      }
    } catch (error: any) {
      console.error('保存配置失败:', error);
      message.error(`保存失败: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  // 初始化数据库约束
  const initializeDatabase = async () => {
    try {
      setLoading(true);
      await neo4jService.initializeConstraints();
      message.success('数据库约束初始化完成');
      setCurrentStep(4);
    } catch (error: any) {
      console.error('初始化失败:', error);
      message.error(`初始化失败: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  // 获取连接状态显示
  const getConnectionStatusDisplay = () => {
    if (connectionStatus.connected) {
      return (
        <Alert
          message="连接正常"
          description={
            <Space direction="vertical" size="small">
              <Text>数据库: {connectionStatus.database}</Text>
              <Text>版本: {connectionStatus.version}</Text>
              <Text>地址: {connectionStatus.address}</Text>
              <Text>检查时间: {connectionStatus.lastChecked?.toLocaleString()}</Text>
            </Space>
          }
          type="success"
          icon={<CheckCircleOutlined />}
          showIcon
        />
      );
    } else {
      return (
        <Alert
          message="连接失败"
          description={connectionStatus.error || '未连接到Neo4j数据库'}
          type="error"
          icon={<ExclamationCircleOutlined />}
          showIcon
        />
      );
    }
  };

  return (
    <div style={{ maxWidth: '800px', margin: '0 auto', padding: '24px' }}>
      <Card
        title={
          <Space>
            <DatabaseOutlined />
            <span>Neo4j 数据库配置</span>
            <Badge 
              status={connectionStatus.connected ? 'success' : 'error'} 
              text={connectionStatus.connected ? '已连接' : '未连接'}
            />
          </Space>
        }
        extra={
          <Button 
            icon={<ThunderboltOutlined />} 
            onClick={() => testConnection()}
            loading={testLoading}
          >
            测试连接
          </Button>
        }
      >
        {/* 配置步骤 */}
        <Steps current={currentStep} style={{ marginBottom: '24px' }}>
          <Step title="基础配置" icon={<SettingOutlined />} />
          <Step title="高级设置" icon={<DatabaseOutlined />} />
          <Step title="连接测试" icon={<LinkOutlined />} />
          <Step title="数据库初始化" icon={<CheckCircleOutlined />} />
        </Steps>

        {/* 连接状态 */}
        <div style={{ marginBottom: '24px' }}>
          {getConnectionStatusDisplay()}
        </div>

        <Form
          form={form}
          layout="vertical"
          onFinish={handleSaveConfig}
          initialValues={currentConfig}
        >
          {/* 基础配置 */}
          <Card size="small" title="基础配置" style={{ marginBottom: '16px' }}>
            <Row gutter={16}>
              <Col span={24}>
                <Form.Item
                  name="uri"
                  label={
                    <Space>
                      连接地址
                      <Tooltip title="Neo4j数据库的连接地址，如 bolt://localhost:7687">
                        <InfoCircleOutlined />
                      </Tooltip>
                    </Space>
                  }
                  rules={[{ required: true, message: '请输入连接地址' }]}
                >
                  <Input 
                    placeholder="bolt://localhost:7687" 
                    prefix={<CloudServerOutlined />}
                    onChange={() => setCurrentStep(0)}
                  />
                </Form.Item>
              </Col>
            </Row>

            <Row gutter={16}>
              <Col span={12}>
                <Form.Item
                  name="username"
                  label="用户名"
                  rules={[{ required: true, message: '请输入用户名' }]}
                >
                  <Input 
                    placeholder="neo4j" 
                    prefix={<UserOutlined />}
                    onChange={() => setCurrentStep(0)}
                  />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item
                  name="password"
                  label="密码"
                  rules={[{ required: true, message: '请输入密码' }]}
                >
                  <Input.Password 
                    placeholder="输入密码"
                    onChange={() => setCurrentStep(0)}
                  />
                </Form.Item>
              </Col>
            </Row>

            <Row gutter={16}>
              <Col span={12}>
                <Form.Item
                  name="database"
                  label="数据库名称"
                >
                  <Input 
                    placeholder="neo4j" 
                    onChange={() => setCurrentStep(0)}
                  />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item
                  name="encrypted"
                  label="启用加密"
                  valuePropName="checked"
                >
                  <Switch 
                    checkedChildren="是" 
                    unCheckedChildren="否"
                    onChange={() => setCurrentStep(0)}
                  />
                </Form.Item>
              </Col>
            </Row>
          </Card>

          {/* 高级配置 */}
          <Collapse 
            onChange={(keys) => {
              setShowAdvanced(keys.length > 0);
              if (keys.length > 0) setCurrentStep(Math.max(currentStep, 1));
            }}
          >
            <Panel header="高级配置" key="advanced">
              <Row gutter={16}>
                <Col span={8}>
                  <Form.Item
                    name="maxConnectionPoolSize"
                    label={
                      <Space>
                        连接池大小
                        <Tooltip title="最大连接池大小，默认50">
                          <InfoCircleOutlined />
                        </Tooltip>
                      </Space>
                    }
                  >
                    <Input type="number" placeholder="50" />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    name="connectionTimeout"
                    label={
                      <Space>
                        连接超时(ms)
                        <Tooltip title="连接超时时间，默认30秒">
                          <InfoCircleOutlined />
                        </Tooltip>
                      </Space>
                    }
                  >
                    <Input type="number" placeholder="30000" />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    name="maxTransactionRetryTime"
                    label={
                      <Space>
                        重试时间(ms)
                        <Tooltip title="事务重试最大时间，默认30秒">
                          <InfoCircleOutlined />
                        </Tooltip>
                      </Space>
                    }
                  >
                    <Input type="number" placeholder="30000" />
                  </Form.Item>
                </Col>
              </Row>
            </Panel>
          </Collapse>

          {/* 操作按钮 */}
          <div style={{ marginTop: '24px', textAlign: 'center' }}>
            <Space size="large">
              <Button 
                type="primary" 
                htmlType="submit" 
                loading={loading}
                icon={<SettingOutlined />}
                size="large"
              >
                保存配置
              </Button>
              
              <Button 
                icon={<LinkOutlined />}
                onClick={() => testConnection()}
                loading={testLoading}
                size="large"
              >
                测试连接
              </Button>
              
              <Button 
                icon={<DatabaseOutlined />}
                onClick={initializeDatabase}
                loading={loading}
                disabled={!connectionStatus.connected}
                size="large"
              >
                初始化数据库
              </Button>
            </Space>
          </div>
        </Form>

        {/* 配置说明 */}
        <Divider />
        <Card size="small" title="配置说明">
          <Collapse ghost>
            <Panel header="本地开发环境" key="local">
              <Paragraph>
                <Text strong>Docker 快速启动:</Text>
                <pre style={{ background: '#f5f5f5', padding: '8px', borderRadius: '4px', marginTop: '8px' }}>
                  {`docker run \\
    --name neo4j \\
    -p7474:7474 -p7687:7687 \\
    -d \\
    -v $HOME/neo4j/data:/data \\
    -v $HOME/neo4j/logs:/logs \\
    -v $HOME/neo4j/import:/var/lib/neo4j/import \\
    -v $HOME/neo4j/plugins:/plugins \\
    --env NEO4J_AUTH=neo4j/password \\
    neo4j:latest`}
                </pre>
              </Paragraph>
              
              <Paragraph>
                <Text strong>默认配置:</Text>
                <ul>
                  <li>连接地址: bolt://localhost:7687</li>
                  <li>用户名: neo4j</li>
                  <li>密码: password</li>
                  <li>Web界面: http://localhost:7474</li>
                </ul>
              </Paragraph>
            </Panel>

            <Panel header="云服务配置" key="cloud">
              <Paragraph>
                <Text strong>Neo4j AuraDB:</Text>
                <ul>
                  <li>连接地址: neo4j+s://xxxxx.databases.neo4j.io</li>
                  <li>启用加密: 是</li>
                  <li>获取连接信息从AuraDB控制台</li>
                </ul>
              </Paragraph>
              
              <Paragraph>
                <Text strong>自建服务器:</Text>
                <ul>
                  <li>确保7687端口开放</li>
                  <li>配置防火墙规则</li>
                  <li>根据网络环境选择加密设置</li>
                </ul>
              </Paragraph>
            </Panel>

            <Panel header="性能优化" key="performance">
              <Paragraph>
                <Text strong>连接池设置:</Text>
                <ul>
                  <li>小型应用: 10-20 连接</li>
                  <li>中型应用: 50-100 连接</li>
                  <li>大型应用: 100+ 连接</li>
                </ul>
              </Paragraph>
              
              <Paragraph>
                <Text strong>超时设置:</Text>
                <ul>
                  <li>快速网络: 10-15秒</li>
                  <li>普通网络: 30秒</li>
                  <li>慢速网络: 60秒+</li>
                </ul>
              </Paragraph>
            </Panel>
          </Collapse>
        </Card>

        {/* 连接统计 */}
        {connectionStatus.connected && (
          <Card size="small" title="连接统计" style={{ marginTop: '16px' }}>
            <Row gutter={16}>
              <Col span={6}>
                <Statistic 
                  title="数据库版本" 
                  value={connectionStatus.version} 
                  prefix={<DatabaseOutlined />}
                />
              </Col>
              <Col span={6}>
                <Statistic 
                  title="运行模式" 
                  value={connectionStatus.mode} 
                  prefix={<CloudServerOutlined />}
                />
              </Col>
              <Col span={6}>
                <Statistic 
                  title="用户角色" 
                  value={connectionStatus.role} 
                  prefix={<UserOutlined />}
                />
              </Col>
              <Col span={6}>
                <Statistic 
                  title="连接状态" 
                  value="正常" 
                  prefix={<CheckCircleOutlined />}
                  valueStyle={{ color: '#3f8600' }}
                />
              </Col>
            </Row>
          </Card>
        )}
      </Card>
    </div>
  );
};

export default Neo4jConfigPanel;
