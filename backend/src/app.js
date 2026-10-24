const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const errorHandler = require('./middlewares/error.middleware');

const path = require('path');

// Route imports
const authRoutes = require('./routes/auth.routes');
const superAdminRoutes = require('./routes/superAdmin.routes');
const adminRoutes = require('./routes/admin.routes');
const teacherRoutes = require('./routes/teacher.routes');
const parentRoutes = require('./routes/parent.routes');
const attendanceRoutes = require('./routes/attendance.routes');
const examRoutes = require('./routes/exam.routes');
const homeworkRoutes = require('./routes/homework.routes');
const leaveRoutes = require('./routes/leave.routes');
const feeRoutes = require('./routes/fee.routes');
const notificationRoutes = require('./routes/notification.routes');
const communicationRoutes = require('./routes/communication.routes');

const app = express();

// Middlewares
app.use(cors({ origin: '*', credentials: true }));
app.use(express.json({ limit: '16mb' }));
app.use(express.urlencoded({ extended: true, limit: '16mb' }));
app.use(morgan('dev'));

// Static files for Web Portals (e.g., Super Admin Web Portal)
app.use(express.static(path.join(__dirname, '../public')));

// Root welcome & status endpoint
app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: '🚀 ScholarCloud Unified Multi-School Management Enterprise API is live and operational!',
    version: '2.0.0-SuperAdmin',
    apiBase: '/api/v1',
    superAdminPortal: '/super-admin',
    health: '/health',
    timestamp: new Date().toISOString(),
  });
});

// Super Admin Web route fallback
app.get('/super-admin', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/super-admin/index.html'));
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    service: 'ScholarCloud Multi-School Backend API',
  });
});

// API Routes
app.use('/api/v1/super-admin', superAdminRoutes);
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/teacher', teacherRoutes);
app.use('/api/v1/parent', parentRoutes);
app.use('/api/v1/attendance', attendanceRoutes);
app.use('/api/v1/exams', examRoutes);
app.use('/api/v1/homework', homeworkRoutes);
app.use('/api/v1/leave', leaveRoutes);
app.use('/api/v1/fees', feeRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/communication', communicationRoutes);


// Global Error Handler

app.use(errorHandler);

module.exports = app;
