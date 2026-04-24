require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const connectDB = require('./config/db');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const chatRoutes = require('./routes/chats');
const callRoutes = require('./routes/calls');
const statusRoutes = require('./routes/status');
const mediaRoutes = require('./routes/media');
const path = require('path');
const setupSocket = require('./socket/socketHandler');

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']
  }
});

// Make io accessible to routes via req.app.get('io')
app.set('io', io);

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/chats', chatRoutes);
app.use('/api/calls', callRoutes);
app.use('/api/status', statusRoutes);
app.use('/api/media', mediaRoutes);

// Health check
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Health check endpoint moved to /api/health
app.get('/api/health', (req, res) => {
  res.json({ message: 'WhatsApp Clone API is running' });
});

// Version endpoint
app.get('/api/version', (req, res) => {
  res.sendFile(path.join(__dirname, 'version.json'));
});

// Socket setup
setupSocket(io);

// Connect to MongoDB and start server
const PORT = process.env.PORT || 3000;

connectDB().then(() => {
  server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
});
