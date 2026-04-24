const express = require('express');
const Status = require('../models/Status');
const { protect } = require('../middleware/auth');

const router = express.Router();

// All routes protected
router.use(protect);

// GET /api/status - get all active statuses
router.get('/', async (req, res) => {
  try {
    const now = new Date();

    // Get other users' statuses
    const othersStatuses = await Status.find({
      user: { $ne: req.user.userId },
      expiresAt: { $gt: now }
    }).populate('user', 'name avatarColor');

    // Get current user's own statuses
    const myStatuses = await Status.find({
      user: req.user.userId,
      expiresAt: { $gt: now }
    }).populate('user', 'name avatarColor');

    // Return own statuses first, then others
    res.status(200).json([...myStatuses, ...othersStatuses]);
  } catch (error) {
    res.status(500).json({ message: 'Server error fetching statuses', error: error.message });
  }
});

// POST /api/status - create new status
router.post('/', async (req, res) => {
  try {
    const { text, backgroundColor } = req.body;

    const status = await Status.create({
      user: req.user.userId,
      text,
      backgroundColor: backgroundColor || '#006A4E',
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000)
    });

    const populatedStatus = await Status.findById(status._id)
      .populate('user', 'name avatarColor');

    res.status(201).json(populatedStatus);
  } catch (error) {
    res.status(500).json({ message: 'Server error creating status', error: error.message });
  }
});

// PATCH /api/status/:id/view - mark status as viewed
router.patch('/:id/view', async (req, res) => {
  try {
    const status = await Status.findById(req.params.id);

    if (!status) {
      return res.status(404).json({ message: 'Status not found' });
    }

    const alreadyViewed = status.viewers.some(
      (viewerId) => viewerId.toString() === req.user.userId.toString()
    );

    if (!alreadyViewed) {
      status.viewers.push(req.user.userId);
      await status.save();
    }

    const populatedStatus = await Status.findById(status._id)
      .populate('user', 'name avatarColor');

    res.status(200).json(populatedStatus);
  } catch (error) {
    res.status(500).json({ message: 'Server error updating status view', error: error.message });
  }
});

module.exports = router;
