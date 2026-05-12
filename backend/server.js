const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const workoutRoutes = require('./routes/workouts');
const settingsRoutes = require('./routes/settings');
const challengeRoutes = require('./routes/challenges');
const socialRoutes = require('./routes/social');
const aiRoutes = require('./routes/ai');
const healthRoutes = require('./routes/health');
const adminRoutes = require('./routes/admin');
const achievementRoutes = require('./routes/achievements');
const { initCronJobs } = require('./cron');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Request Logger
app.use((req, res, next) => {
  console.log(`[${new Date().toLocaleTimeString()}] ${req.method} ${req.url}`);
  next();
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/workouts', workoutRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/challenges', challengeRoutes);
app.use('/api/social', socialRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/health', healthRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/broadcast', require('./routes/broadcast'));
app.use('/api/achievements', achievementRoutes);

// Welcome/Root route
app.get('/', (req, res) => {
  res.send(`
    <div style="font-family: sans-serif; padding: 2rem; text-align: center;">
      <h1 style="color: #39FF14;">🚀 FitTracker API</h1>
      <p>The backend is running successfully!</p>
      <p>Try the health check: <a href="/api/health">/api/health</a></p>
    </div>
  `);
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'FitTracker API is running' });
});

const BASE_PORT = Number.parseInt(process.env.PORT || '3000', 10);

function getLocalIp() {
  const { networkInterfaces } = require('os');
  const nets = networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        return net.address;
      }
    }
  }
  return 'localhost';
}

function startListening(portToTry) {
  const localIp = getLocalIp();
  const server = app.listen(portToTry, '0.0.0.0', () => {
    console.log(`🚀 FitTracker API running on http://localhost:${portToTry}`);
    console.log(`📡 Network access: http://${localIp}:${portToTry}`);
    console.log(`📋 Health check: http://${localIp}:${portToTry}/api/health`);
  });

  server.on('error', (err) => {
    if (err && err.code === 'EADDRINUSE') {
      const nextPort = portToTry + 1;
      console.log(`⚠️ Port ${portToTry} already in use. Trying ${nextPort}...`);
      startListening(nextPort);
      return;
    }

    console.error('❌ Server listen error:', err);
    process.exit(1);
  });
}

// Connect to MongoDB and start server
mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('✅ Connected to MongoDB Atlas');
    initCronJobs();
    startListening(BASE_PORT);
  })
  .catch((err) => {
    console.error('❌ MongoDB connection error:', err.message);
    console.log('\n📝 Setup Instructions:');
    console.log('1. Go to https://cloud.mongodb.com');
    console.log('2. Create a free M0 cluster');
    console.log('3. Create a database user');
    console.log('4. Add your IP to the access list (or allow 0.0.0.0/0)');
    console.log('5. Click "Connect" → "Drivers" → Copy the connection string');
    console.log('6. Paste it in backend/.env as MONGODB_URI');
  });
