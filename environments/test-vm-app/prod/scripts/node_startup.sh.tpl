export DEBIAN_FRONTEND=noninteractive

echo "=== [1] 開始安裝系統相依性 ==="
apt-get update
apt-get install -y curl gnupg git

echo "=== [2] 安裝 Node.js ==="
curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
apt-get install -y nodejs

echo "=== [3] 建立簡易 Node.js 伺服器 ==="
mkdir -p /opt/app
cd /opt/app

cat << 'EOF' > server.js
const http = require('http');

const server = http.createServer((req, res) => {
  if (req.url === '/healthz') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('OK');
    return;
  }

  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end('<h1>你好！這是一台由 Terraform 自動建立的 Node.js VM 🚀</h1>');
});

// 由外層變數動態決定要聽哪個 Port
const PORT = ${app_port}; 
server.listen(PORT, () => {
  console.log(`Server is running on port $${PORT}`);
});
EOF

echo "=== [4] 啟動伺服器 ==="
npm install -g pm2
pm2 start server.js --name "my-app"
pm2 save
env COMPOSER_ALLOW_SUPERUSER=1 pm2 startup systemd -u azureuser --hp /home/azureuser | bash

echo "=== 部署完成！ ==="