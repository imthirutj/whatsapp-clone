const express = require('express');
const Call = require('../models/Call');
const { protect } = require('../middleware/auth');

const router = express.Router();

// All routes protected
router.use(protect);

// GET /api/calls - get call history for current user
router.get('/', async (req, res) => {
  try {
    const calls = await Call.find({
      $or: [
        { caller: req.user.userId },
        { receiver: req.user.userId }
      ]
    })
      .populate('caller', 'name avatarColor')
      .populate('receiver', 'name avatarColor')
      .sort({ createdAt: -1 })
      .limit(50);

    res.status(200).json(calls);
  } catch (error) {
    res.status(500).json({ message: 'Server error fetching calls', error: error.message });
  }
});

// POST /api/calls - create call log
router.post('/', async (req, res) => {
  try {
    const { receiverId, type, status, duration } = req.body;

    if (!receiverId) {
      return res.status(400).json({ message: 'receiverId is required' });
    }

    const call = await Call.create({
      caller: req.user.userId,
      receiver: receiverId,
      type: type || 'audio',
      status: status || 'answered',
      duration: duration || 0
    });

    const populatedCall = await Call.findById(call._id)
      .populate('caller', 'name avatarColor')
      .populate('receiver', 'name avatarColor');

    res.status(201).json(populatedCall);
  } catch (error) {
    res.status(500).json({ message: 'Server error creating call log', error: error.message });
  }
});

module.exports = router;
