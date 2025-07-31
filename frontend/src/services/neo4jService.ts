import neo4j, { Driver, Session, Result } from 'neo4j-driver';

// Neo4j连接配置
interface Neo4jConfig {
  uri: string;
  username: string;
  password: string;
}

// 知识图谱节点类型
export interface GraphNode {
  id: string;
  type: 'CHARACTER' | 'LOCATION' | 'EVENT' | 'CONCEPT' | 'THEME' | 'ORGANIZATION' | 'PLOT_POINT' | 'TIMELINE';
  name: string;
  description?: string;
  properties: Record<string, any>;
  importance: 'HIGH' | 'MEDIUM' | 'LOW';
  status: 'ACTIVE' | 'INACTIVE' | 'DRAFT';
  tags: string[];
  chapterIds?: string[];
  projectId: string;
  createdAt: string;
  updatedAt: string;
}

// 知识图谱关系类型
export interface GraphRelationship {
  id: string;
  type: 'KNOWS' | 'RELATED_TO' | 'PARTICIPATES_IN' | 'LOCATED_AT' | 'INFLUENCES' | 'CONFLICTS_WITH' | 
        'LOVES' | 'HATES' | 'MENTOR_OF' | 'FAMILY_OF' | 'ALLIANCE_WITH' | 'OWNS' | 'LEADS' | 
        'CAUSES' | 'PRECEDES' | 'FOLLOWS' | 'SIMILAR_TO' | 'OPPOSITE_OF';
  startNodeId: string;
  endNodeId: string;
  strength: number; // 0-100
  description?: string;
  properties: Record<string, any>;
  bidirectional: boolean;
  startChapter?: string;
  endChapter?: string;
  status: 'CURRENT' | 'PAST' | 'FUTURE' | 'PLANNED';
  createdAt: string;
  updatedAt: string;
}

// 查询结果类型
export interface GraphData {
  nodes: GraphNode[];
  relationships: GraphRelationship[];
  statistics: {
    nodeCount: number;
    relationshipCount: number;
    typeDistribution: Record<string, number>;
  };
}

export class Neo4jKnowledgeGraphService {
  private driver: Driver | null = null;
  private session: Session | null = null;
  private uri: string;
  private username: string;
  private password: string;
  private database: string;

  constructor(private config: Neo4jConfig) {
    this.uri = config.uri;
    this.username = config.username;
    this.password = config.password;
    this.database = 'neo4j';
  }

  /**
   * 初始化Neo4j连接
   */
  async initialize(): Promise<void> {
    try {
      this.driver = neo4j.driver(
        this.config.uri,
        neo4j.auth.basic(this.config.username, this.config.password),
        {
          disableLosslessIntegers: true,
          connectionTimeout: 30000,
          maxConnectionLifetime: 30 * 60 * 1000, // 30分钟
        }
      );

      // 验证连接
      await this.driver.verifyConnectivity();
      console.log('Neo4j连接成功');

      // 创建约束和索引
      await this.createConstraintsAndIndexes();
    } catch (error) {
      console.error('Neo4j初始化失败:', error);
      throw error;
    }
  }

  /**
   * 创建数据库约束和索引
   */
  private async createConstraintsAndIndexes(): Promise<void> {
    const session = this.getSession();
    
    try {
      // 创建节点唯一性约束
      await session.run(`
        CREATE CONSTRAINT node_id_unique IF NOT EXISTS
        FOR (n:KnowledgeNode) REQUIRE n.id IS UNIQUE
      `);

      // 创建关系唯一性约束
      await session.run(`
        CREATE CONSTRAINT relationship_id_unique IF NOT EXISTS
        FOR ()-[r:RELATIONSHIP]-() REQUIRE r.id IS UNIQUE
      `);

      // 创建项目索引
      await session.run(`
        CREATE INDEX project_index IF NOT EXISTS
        FOR (n:KnowledgeNode) ON (n.projectId)
      `);

      // 创建类型索引
      await session.run(`
        CREATE INDEX type_index IF NOT EXISTS
        FOR (n:KnowledgeNode) ON (n.type)
      `);

      console.log('Neo4j约束和索引创建完成');
    } catch (error) {
      console.error('创建约束和索引失败:', error);
    } finally {
      await session.close();
    }
  }

  /**
   * 获取会话
   */
  private getSession(): Session {
    if (!this.driver) {
      throw new Error('Neo4j驱动未初始化');
    }
    return this.driver.session();
  }

  /**
   * 创建节点
   */
  async createNode(node: Omit<GraphNode, 'id' | 'createdAt' | 'updatedAt'>): Promise<GraphNode> {
    const session = this.getSession();
    
    try {
      const nodeId = `node_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const now = new Date().toISOString();
      
      const result = await session.run(`
        CREATE (n:KnowledgeNode {
          id: $id,
          type: $type,
          name: $name,
          description: $description,
          properties: $properties,
          importance: $importance,
          status: $status,
          tags: $tags,
          chapterIds: $chapterIds,
          projectId: $projectId,
          createdAt: $createdAt,
          updatedAt: $updatedAt
        })
        RETURN n
      `, {
        id: nodeId,
        type: node.type,
        name: node.name,
        description: node.description || '',
        properties: JSON.stringify(node.properties),
        importance: node.importance,
        status: node.status,
        tags: node.tags,
        chapterIds: node.chapterIds || [],
        projectId: node.projectId,
        createdAt: now,
        updatedAt: now
      });

      const createdNode = result.records[0].get('n').properties;
      return {
        ...createdNode,
        properties: JSON.parse(createdNode.properties),
        id: nodeId,
        createdAt: now,
        updatedAt: now
      } as GraphNode;
    } catch (error) {
      console.error('创建节点失败:', error);
      throw error;
    } finally {
      await session.close();
    }
  }

  /**
   * 创建关系
   */
  async createRelationship(relationship: Omit<GraphRelationship, 'id' | 'createdAt' | 'updatedAt'>): Promise<GraphRelationship> {
    const session = this.getSession();
    
    try {
      const relationshipId = `rel_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const now = new Date().toISOString();
      
      const result = await session.run(`
        MATCH (start:KnowledgeNode {id: $startNodeId})
        MATCH (end:KnowledgeNode {id: $endNodeId})
        CREATE (start)-[r:RELATIONSHIP {
          id: $id,
          type: $type,
          strength: $strength,
          description: $description,
          properties: $properties,
          bidirectional: $bidirectional,
          startChapter: $startChapter,
          endChapter: $endChapter,
          status: $status,
          createdAt: $createdAt,
          updatedAt: $updatedAt
        }]->(end)
        RETURN r, start.id as startNodeId, end.id as endNodeId
      `, {
        id: relationshipId,
        startNodeId: relationship.startNodeId,
        endNodeId: relationship.endNodeId,
        type: relationship.type,
        strength: relationship.strength,
        description: relationship.description || '',
        properties: JSON.stringify(relationship.properties),
        bidirectional: relationship.bidirectional,
        startChapter: relationship.startChapter || '',
        endChapter: relationship.endChapter || '',
        status: relationship.status,
        createdAt: now,
        updatedAt: now
      });

      const createdRel = result.records[0].get('r').properties;
      return {
        ...createdRel,
        properties: JSON.parse(createdRel.properties),
        id: relationshipId,
        startNodeId: relationship.startNodeId,
        endNodeId: relationship.endNodeId,
        createdAt: now,
        updatedAt: now
      } as GraphRelationship;
    } catch (error) {
      console.error('创建关系失败:', error);
      throw error;
    } finally {
      await session.close();
    }
  }

  /**
   * 获取项目的完整知识图谱
   */
  async getProjectKnowledgeGraph(projectId: string): Promise<GraphData> {
    const session = this.getSession();
    
    try {
      // 获取节点
      const nodesResult = await session.run(`
        MATCH (n:KnowledgeNode {projectId: $projectId})
        RETURN n
        ORDER BY n.importance DESC, n.name ASC
      `, { projectId });

      const nodes: GraphNode[] = nodesResult.records.map(record => {
        const node = record.get('n').properties;
        return {
          ...node,
          properties: JSON.parse(node.properties || '{}')
        } as GraphNode;
      });

      // 获取关系
      const relationshipsResult = await session.run(`
        MATCH (start:KnowledgeNode {projectId: $projectId})-[r:RELATIONSHIP]->(end:KnowledgeNode {projectId: $projectId})
        RETURN r, start.id as startNodeId, end.id as endNodeId
      `, { projectId });

      const relationships: GraphRelationship[] = relationshipsResult.records.map(record => {
        const rel = record.get('r').properties;
        return {
          ...rel,
          properties: JSON.parse(rel.properties || '{}'),
          startNodeId: record.get('startNodeId'),
          endNodeId: record.get('endNodeId')
        } as GraphRelationship;
      });

      // 计算统计信息
      const typeDistribution: Record<string, number> = {};
      nodes.forEach(node => {
        typeDistribution[node.type] = (typeDistribution[node.type] || 0) + 1;
      });

      return {
        nodes,
        relationships,
        statistics: {
          nodeCount: nodes.length,
          relationshipCount: relationships.length,
          typeDistribution
        }
      };
    } catch (error) {
      console.error('获取知识图谱失败:', error);
      throw error;
    } finally {
      await session.close();
    }
  }

  /**
   * 更新节点
   */
  async updateNode(nodeId: string, updates: Partial<GraphNode>): Promise<GraphNode> {
    const session = this.getSession();
    
    try {
      const setClause = Object.entries(updates)
        .filter(([key]) => key !== 'id' && key !== 'createdAt')
        .map(([key, value]) => {
          if (key === 'properties') {
            return `n.${key} = "${JSON.stringify(value).replace(/"/g, '\\"')}"`;
          }
          if (Array.isArray(value)) {
            return `n.${key} = $${key}`;
          }
          return `n.${key} = $${key}`;
        })
        .join(', ');

      const parameters = {
        nodeId,
        updatedAt: new Date().toISOString(),
        ...Object.fromEntries(
          Object.entries(updates).filter(([key]) => key !== 'id' && key !== 'createdAt')
        )
      };

      const result = await session.run(`
        MATCH (n:KnowledgeNode {id: $nodeId})
        SET ${setClause}, n.updatedAt = $updatedAt
        RETURN n
      `, parameters);

      const updatedNode = result.records[0].get('n').properties;
      return {
        ...updatedNode,
        properties: JSON.parse(updatedNode.properties || '{}')
      } as GraphNode;
    } catch (error) {
      console.error('更新节点失败:', error);
      throw error;
    } finally {
      await session.close();
    }
  }

  /**
   * 删除节点及其所有关系
   */
  async deleteNode(nodeId: string): Promise<void> {
    const session = this.getSession();
    
    try {
      await session.run(`
        MATCH (n:KnowledgeNode {id: $nodeId})
        DETACH DELETE n
      `, { nodeId });
    } catch (error) {
      console.error('删除节点失败:', error);
      throw error;
    } finally {
      await session.close();
    }
  }

  /**
   * 删除关系
   */
  async deleteRelationship(relationshipId: string): Promise<void> {
    const session = this.getSession();
    
    try {
      await session.run(`
        MATCH ()-[r:RELATIONSHIP {id: $relationshipId}]-()
        DELETE r
      `, { relationshipId });
    } catch (error) {
      console.error('删除关系失败:', error);
      throw error;
    } finally {
      await session.close();
    }
  }

  /**
   * 路径查询 - 查找两个节点之间的关系路径
   */
  async findShortestPath(startNodeId: string, endNodeId: string): Promise<{
    path: Array<{node: GraphNode, relationship?: GraphRelationship}>;
    length: number;
  } | null> {
    const session = this.getSession();
    
    try {
      const result = await session.run(`
        MATCH p = shortestPath((start:KnowledgeNode {id: $startNodeId})-[*..5]-(end:KnowledgeNode {id: $endNodeId}))
        WITH p, length(p) as pathLength
        UNWIND range(0, pathLength) as i
        WITH p, pathLength, nodes(p)[i] as node, 
             CASE WHEN i < pathLength THEN relationships(p)[i] ELSE null END as rel
        RETURN node, rel, pathLength
        ORDER BY i
      `, { startNodeId, endNodeId });

      if (result.records.length === 0) {
        return null;
      }

      const pathLength = result.records[0].get('pathLength');
      const path = result.records.map(record => {
        const node = record.get('node').properties;
        const rel = record.get('rel');
        
        return {
          node: {
            ...node,
            properties: JSON.parse(node.properties || '{}')
          } as GraphNode,
          relationship: rel ? {
            ...rel.properties,
            properties: JSON.parse(rel.properties || '{}')
          } as GraphRelationship : undefined
        };
      });

      return { path, length: pathLength };
    } catch (error) {
      console.error('查找路径失败:', error);
      return null;
    } finally {
      await session.close();
    }
  }

  /**
   * 获取节点的邻居节点
   */
  async getNodeNeighbors(nodeId: string, depth: number = 1): Promise<GraphData> {
    const session = this.getSession();
    
    try {
      const result = await session.run(`
        MATCH (center:KnowledgeNode {id: $nodeId})
        CALL apoc.path.subgraphNodes(center, {maxLevel: $depth}) YIELD node
        WITH collect(DISTINCT node) as nodes
        UNWIND nodes as n1
        UNWIND nodes as n2
        MATCH (n1)-[r:RELATIONSHIP]-(n2)
        RETURN collect(DISTINCT n1) as nodes, collect(DISTINCT r) as relationships
      `, { nodeId, depth });

      if (result.records.length === 0) {
        return { nodes: [], relationships: [], statistics: { nodeCount: 0, relationshipCount: 0, typeDistribution: {} } };
      }

      const nodes = result.records[0].get('nodes').map((node: any) => ({
        ...node.properties,
        properties: JSON.parse(node.properties.properties || '{}')
      }));

      const relationships = result.records[0].get('relationships').map((rel: any) => ({
        ...rel.properties,
        properties: JSON.parse(rel.properties.properties || '{}')
      }));

      const typeDistribution: Record<string, number> = {};
      nodes.forEach((node: GraphNode) => {
        typeDistribution[node.type] = (typeDistribution[node.type] || 0) + 1;
      });

      return {
        nodes,
        relationships,
        statistics: {
          nodeCount: nodes.length,
          relationshipCount: relationships.length,
          typeDistribution
        }
      };
    } catch (error) {
      console.error('获取邻居节点失败:', error);
      return { nodes: [], relationships: [], statistics: { nodeCount: 0, relationshipCount: 0, typeDistribution: {} } };
    } finally {
      await session.close();
    }
  }

  /**
   * 智能推荐连接
   */
  async getRecommendedConnections(nodeId: string, limit: number = 10): Promise<GraphNode[]> {
    const session = this.getSession();
    
    try {
      const result = await session.run(`
        MATCH (source:KnowledgeNode {id: $nodeId})-[:RELATIONSHIP*1..2]-(connected:KnowledgeNode)
        WHERE source <> connected
        AND NOT (source)-[:RELATIONSHIP]-(connected)
        WITH connected, COUNT(*) as commonConnections
        ORDER BY commonConnections DESC
        LIMIT $limit
        RETURN connected as node
      `, { nodeId, limit });

      return result.records.map(record => {
        const node = record.get('node').properties;
        return {
          ...node,
          properties: JSON.parse(node.properties || '{}')
        } as GraphNode;
      });
    } catch (error) {
      console.error('获取推荐连接失败:', error);
      return [];
    } finally {
      await session.close();
    }
  }

  /**
   * 检查连接状态
   */
  async isConnected(): Promise<boolean> {
    try {
      if (!this.driver) return false;
      const session = this.driver.session();
      await session.run('RETURN 1');
      session.close();
      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * 获取数据库信息
   */
  async getDatabaseInfo(): Promise<{
    database: string;
    version: string;
    mode: string;
    role: string;
    address: string;
  }> {
    const session = this.getSession();
    
    try {
      const result = await session.run('CALL dbms.components() YIELD name, versions, edition');
      const versionRecord = result.records[0];
      
      return {
        database: this.database || 'neo4j',
        version: versionRecord ? versionRecord.get('versions')[0] : 'Unknown',
        mode: versionRecord ? versionRecord.get('edition') : 'Community',
        role: 'primary',
        address: this.uri
      };
    } catch (error) {
      // 如果无法获取版本信息，返回默认值
      return {
        database: this.database || 'neo4j',
        version: 'Unknown',
        mode: 'Community',
        role: 'primary',
        address: this.uri
      };
    } finally {
      await session.close();
    }
  }

  /**
   * 配置服务
   */
  async configure(config: {
    uri: string;
    username: string;
    password: string;
    database?: string;
    encrypted?: boolean;
    maxConnectionPoolSize?: number;
    connectionTimeout?: number;
    maxTransactionRetryTime?: number;
  }): Promise<void> {
    this.uri = config.uri;
    this.username = config.username;
    this.password = config.password;
    this.database = config.database || 'neo4j';
    
    // 关闭现有连接
    if (this.driver) {
      await this.driver.close();
    }
    
    // 创建新驱动
    this.driver = neo4j.driver(
      this.uri,
      neo4j.auth.basic(this.username, this.password),
      {
        encrypted: config.encrypted ? 'ENCRYPTION_ON' : 'ENCRYPTION_OFF',
        maxConnectionPoolSize: config.maxConnectionPoolSize || 50,
        connectionTimeout: config.connectionTimeout || 30000,
        maxTransactionRetryTime: config.maxTransactionRetryTime || 30000
      }
    );
  }

  /**
   * 运行自定义查询
   */
  async runQuery(query: string, parameters: Record<string, any>): Promise<any> {
    const session = this.getSession();
    
    try {
      const result = await session.run(query, parameters);
      return result;
    } catch (error) {
      console.error('查询执行失败:', error);
      throw error;
    } finally {
      await session.close();
    }
  }

  /**
   * 关闭连接
   */
  async close(): Promise<void> {
    if (this.session) {
      await this.session.close();
    }
    if (this.driver) {
      await this.driver.close();
    }
  }
}

// 单例实例
let neo4jService: Neo4jKnowledgeGraphService | null = null;

export const createNeo4jService = (config: Neo4jConfig): Neo4jKnowledgeGraphService => {
  if (!neo4jService) {
    neo4jService = new Neo4jKnowledgeGraphService(config);
  }
  return neo4jService;
};

export const getNeo4jService = (): Neo4jKnowledgeGraphService => {
  if (!neo4jService) {
    // 使用默认配置 - 在生产环境中应该从环境变量读取
    const config: Neo4jConfig = {
      uri: process.env.REACT_APP_NEO4J_URI || 'bolt://localhost:7687',
      username: process.env.REACT_APP_NEO4J_USERNAME || 'neo4j',
      password: process.env.REACT_APP_NEO4J_PASSWORD || 'password'
    };
    neo4jService = new Neo4jKnowledgeGraphService(config);
  }
  return neo4jService;
};

export default Neo4jKnowledgeGraphService;
