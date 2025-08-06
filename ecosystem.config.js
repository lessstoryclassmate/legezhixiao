module.exports = {
  apps: [
    {
      name: 'backend',
      script: 'npm',
      args: 'run dev',
      cwd: '/workspaces/legezhixiao/backend',
      env: {
        NODE_ENV: 'development',
        PORT: '3000',
        HOST: '0.0.0.0'
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: '3000',
        HOST: '0.0.0.0'
      },
      autorestart: true,
      watch: ['src'],
      ignore_watch: ['node_modules', 'logs', 'uploads', 'dist'],
      max_memory_restart: '1G',
      error_file: './logs/backend-error.log',
      out_file: './logs/backend-out.log',
      log_file: './logs/backend-combined.log',
      time: true,
      instances: 1,
      exec_mode: 'fork',
      restart_delay: 2000,
      max_restarts: 10,
      min_uptime: '10s'
    },
    {
      name: 'frontend',
      script: 'npm',
      args: 'run dev',
      cwd: '/workspaces/legezhixiao/frontend',
      env: {
        NODE_ENV: 'development',
        VITE_PORT: '5173',
        VITE_HOST: '0.0.0.0'
      },
      env_production: {
        NODE_ENV: 'production',
        VITE_PORT: '5173',
        VITE_HOST: '0.0.0.0'
      },
      autorestart: true,
      watch: ['src'],
      ignore_watch: ['node_modules', 'dist', 'logs'],
      max_memory_restart: '1G',
      error_file: './logs/frontend-error.log',
      out_file: './logs/frontend-out.log',
      log_file: './logs/frontend-combined.log',
      time: true,
      instances: 1,
      exec_mode: 'fork',
      restart_delay: 2000,
      max_restarts: 10,
      min_uptime: '10s'
    }
  ],

  deploy: {
    production: {
      user: 'node',
      host: 'localhost',
      ref: 'origin/main',
      repo: 'git@github.com:lessstoryclassmate/legezhixiao.git',
      path: '/var/www/legezhixiao',
      'pre-deploy-local': '',
      'post-deploy': 'npm install && pm2 reload ecosystem.config.js --env production',
      'pre-setup': ''
    }
  }
};
