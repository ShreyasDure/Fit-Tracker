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

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/workouts', workoutRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/challenges', challengeRoutes);
app.use('/api/social', socialRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'FitTracker API is running' });
});

// Connect to MongoDB and start server
const PORT = process.env.PORT || 3000;

mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('✅ Connected to MongoDB Atlas');
    app.listen(PORT, () => {
      console.log(`🚀 FitTracker API running on http://localhost:${PORT}`);
      console.log(`📋 Health check: http://localhost:${PORT}/api/health`);
    });
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
