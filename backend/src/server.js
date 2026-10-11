require('dotenv').config();
const http = require('http');
const { Server } = require('socket.io');
const app = require('./app');
const connectDB = require('./config/db');
const { initSocket } = require('./services/socket.service');

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    // 1. Connect MongoDB
    await connectDB();

    // 2. Create HTTP & Socket.io server
    const server = http.createServer(app);
    const io = new Server(server, {
      cors: {
        origin: '*',
        methods: ['GET', 'POST', 'PATCH', 'DELETE'],
      },
    });

    // 3. Initialize real-time socket events
    initSocket(io);

    // 4. Start listening
    server.listen(PORT, () => {
      console.log(`====================================================`);
      console.log(`🚀 School Management Server running on port ${PORT}`);
      console.log(`📡 WebSocket / Socket.io server ready for push alerts`);
      console.log(`🌐 Base URL: http://localhost:${PORT}/api/v1`);
      console.log(`====================================================`);
    });
  } catch (error) {
    console.error('Fatal Server Initialization Error:', error);
    process.exit(1);
  }
};

startServer();
