module.exports = {
  apps: [{
    name: 'video-alert-worker',
    script: './dist/index.js',
    cwd: '/opt/video-alerts',
    instances: 1,
    exec_mode: 'fork',
    max_memory_restart: '900M',
    node_args: '--max-old-space-size=1024',
    env: {
      NODE_ENV: 'production',
      UV_THREADPOOL_SIZE: 2
    }
  }]
};
