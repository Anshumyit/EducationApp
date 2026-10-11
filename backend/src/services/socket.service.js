let ioInstance = null;

const initSocket = (io) => {
  ioInstance = io;

  io.on('connection', (socket) => {
    console.log(`[Socket.io] Client connected: ${socket.id}`);

    // Client joins their personal user channel
    socket.on('join:user', (userId) => {
      if (userId) {
        socket.join(`user_${userId}`);
        console.log(`[Socket.io] Socket ${socket.id} joined user_${userId}`);
      }
    });

    // Client joins their role channel (ADMIN, TEACHER, PARENT)
    socket.on('join:role', (role) => {
      if (role) {
        socket.join(`role_${role}`);
        console.log(`[Socket.io] Socket ${socket.id} joined role_${role}`);
      }
    });

    // Client joins class channel
    socket.on('join:class', (classId) => {
      if (classId) {
        socket.join(`class_${classId}`);
        console.log(`[Socket.io] Socket ${socket.id} joined class_${classId}`);
      }
    });

    socket.on('disconnect', () => {
      console.log(`[Socket.io] Client disconnected: ${socket.id}`);
    });
  });

  return io;
};

const getIO = () => {
  return ioInstance;
};

module.exports = {
  initSocket,
  getIO,
};
