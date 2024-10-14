# 使用 Node.js 的官方映像作為基礎映像
FROM node:14

# 設定工作目錄
WORKDIR /usr/src/app

# 複製 package.json 和 package-lock.json
COPY package*.json ./

# 安裝應用程式的依賴
RUN npm install

# 複製應用程式的檔案
COPY . .

# 暴露應用程式的端口
EXPOSE 3000

# 啟動應用程式
CMD ["node", "index.js"]
