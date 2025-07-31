import React, { useState } from 'react'
import { Button, Card, Input, Space, Typography, message } from 'antd'
import AIServiceManager from '../services/aiService'

const { Title, Text } = Typography
const { TextArea } = Input

const AITestPanel: React.FC = () => {
    const [input, setInput] = useState('')
    const [response, setResponse] = useState('')
    const [loading, setLoading] = useState(false)

    const testAI = async () => {
        if (!input.trim()) {
            message.warning('请输入测试内容')
            return
        }

        setLoading(true)
        try {
            // 使用预设配置
            const config = {
                provider: 'siliconflow' as const,
                apiKey: 'sk-mjithqmjwccqgffouexthbavtnvftwkqjludpcxhrmeztcib',
                customApiUrl: 'https://api.siliconflow.cn/v1/chat/completions',
                model: 'deepseek-ai/DeepSeek-V3'
            }

            const aiService = AIServiceManager.getInstance(config)
            
            const result = await aiService.generateResponse({
                message: input,
                type: 'general'
            })

            setResponse(result.text)
            message.success('AI响应成功！')
        } catch (error) {
            console.error('AI测试失败:', error)
            message.error('AI测试失败，请检查网络连接')
        } finally {
            setLoading(false)
        }
    }

    return (
        <Card 
            title="AI服务测试面板" 
            style={{ margin: '20px', maxWidth: '800px' }}
            className="tech-card"
        >
            <Space direction="vertical" style={{ width: '100%' }} size="large">
                <div>
                    <Title level={5}>测试输入</Title>
                    <TextArea
                        value={input}
                        onChange={(e) => setInput(e.target.value)}
                        placeholder="输入您想测试的内容，例如：你好，请介绍一下自己"
                        rows={3}
                    />
                </div>

                <Button 
                    type="primary" 
                    onClick={testAI}
                    loading={loading}
                    size="large"
                    className="tech-button"
                >
                    测试AI响应
                </Button>

                {response && (
                    <div>
                        <Title level={5}>AI响应</Title>
                        <Card size="small" style={{ backgroundColor: '#f6f8fa' }}>
                            <Text>{response}</Text>
                        </Card>
                    </div>
                )}

                <div>
                    <Title level={5}>使用说明</Title>
                    <ul>
                        <li>这个面板使用您提供的SiliconFlow API密钥</li>
                        <li>模型：deepseek-ai/DeepSeek-V3</li>
                        <li>如果测试成功，说明AI服务配置正确</li>
                        <li>您可以在AI助手中正常使用所有功能</li>
                    </ul>
                </div>
            </Space>
        </Card>
    )
}

export default AITestPanel
