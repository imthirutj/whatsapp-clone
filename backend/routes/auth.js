const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { protect } = require('../middleware/auth');

const router = express.Router();

const signToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '7d' });
};

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, phone } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email, and password are required' });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'User with this email already exists' });
    }

    const user = await User.create({ name, email, password, phone });

    const token = signToken(user._id);

    const userObj = {
      _id: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      avatarColor: user.avatarColor,
      bio: user.bio,
      online: user.online,
      lastSeen: user.lastSeen,
      createdAt: user.createdAt
    };

    res.status(201).json({ token, user: userObj });
  } catch (error) {
    res.status(500).json({ message: 'Server error during registration', error: error.message });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const token = signToken(user._id);

    const userObj = {
      _id: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      avatarColor: user.avatarColor,
      bio: user.bio,
      online: user.online,
      lastSeen: user.lastSeen,
      createdAt: user.createdAt
    };

    res.status(200).json({ token, user: userObj });
  } catch (error) {
    res.status(500).json({ message: 'Server error during login', error: error.message });
  }
});

// GET /api/auth/me — returns current user from JWT (used by Flutter on app start)
router.get('/me', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.status(200).json({
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        avatarColor: user.avatarColor,
        bio: user.bio,
        online: user.online,
        lastSeen: user.lastSeen,
        createdAt: user.createdAt,
      }
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// POST /api/auth/logout — marks user offline (token invalidation is client-side)
router.post('/logout', protect, async (req, res) => {
  try {
    await User.findByIdAndUpdate(req.user.userId, { online: false, lastSeen: new Date() });
    res.status(200).json({ message: 'Logged out' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;
