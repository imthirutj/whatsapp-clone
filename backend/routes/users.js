const express = require('express');
const User = require('../models/User');
const { protect } = require('../middleware/auth');

const router = express.Router();

// All routes protected
router.use(protect);

// GET /api/users?q=searchterm — search by username, email, or _id
// Returns empty array if no query provided (don't expose full user list)
router.get('/', async (req, res) => {
  try {
    const { q } = req.query;

    if (!q || q.trim().length < 1) {
      return res.status(200).json([]);
    }

    const term = q.trim();
    const orConditions = [
      { username: term.toLowerCase() },       // exact username
      { email: term.toLowerCase() },          // exact email
    ];

    // also match by MongoDB _id if it looks like one
    const mongoose = require('mongoose');
    if (mongoose.Types.ObjectId.isValid(term)) {
      orConditions.push({ _id: term });
    }

    const query = {
      _id: { $ne: req.user.userId },
      $or: orConditions,
    };

    const users = await User.find(query).select('-password').limit(20);
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: 'Server error fetching users', error: error.message });
  }
});

// GET /api/users/:id - get single user
router.get('/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.status(200).json(user);
  } catch (error) {
    res.status(500).json({ message: 'Server error fetching user', error: error.message });
  }
});

// PUT /api/users/profile - update profile
router.put('/profile', async (req, res) => {
  try {
    const { name, phone, bio } = req.body;

    const updatedUser = await User.findByIdAndUpdate(
      req.user.userId,
      { name, phone, bio },
      { new: true, runValidators: true }
    ).select('-password');

    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json(updatedUser);
  } catch (error) {
    res.status(500).json({ message: 'Server error updating profile', error: error.message });
  }
});

// PATCH /api/users/online - update online status
router.patch('/online', async (req, res) => {
  try {
    const { online } = req.body;

    const updateData = { online };
    if (!online) {
      updateData.lastSeen = new Date();
    }

    const updatedUser = await User.findByIdAndUpdate(
      req.user.userId,
      updateData,
      { new: true }
    ).select('-password');

    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json(updatedUser);
  } catch (error) {
    res.status(500).json({ message: 'Server error updating online status', error: error.message });
  }
});

module.exports = router;
