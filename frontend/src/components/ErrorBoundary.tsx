import { Component, ErrorInfo, ReactNode } from 'react'
import { Button, Result } from 'antd'

interface Props {
  children: ReactNode
}

interface State {
  hasError: boolean
  error?: Error
  errorInfo?: ErrorInfo
}

class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false }
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('ErrorBoundary caught an error:', error, errorInfo)
    this.setState({ error, errorInfo })
  }

  render() {
    if (this.state.hasError) {
      return (
        <Result
          status="error"
          title="应用程序出现错误"
          subTitle={this.state.error?.message || '未知错误'}
          extra={[
            <Button type="primary" key="reload" onClick={() => window.location.reload()}>
              重新加载页面
            </Button>,
            <Button key="console" onClick={() => console.log('Error:', this.state.error, this.state.errorInfo)}>
              查看控制台
            </Button>
          ]}
        >
          <div style={{ marginTop: '20px', textAlign: 'left' }}>
            <h4>错误详情:</h4>
            <pre style={{ background: '#f5f5f5', padding: '10px', fontSize: '12px' }}>
              {this.state.error?.stack}
            </pre>
            {this.state.errorInfo && (
              <>
                <h4>组件堆栈:</h4>
                <pre style={{ background: '#f5f5f5', padding: '10px', fontSize: '12px' }}>
                  {this.state.errorInfo.componentStack}
                </pre>
              </>
            )}
          </div>
        </Result>
      )
    }

    return this.props.children
  }
}

export default ErrorBoundary
