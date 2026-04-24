const express = require('express');
const Chat = require('../models/Chat');
const Message = require('../models/Message');
const { protect } = require('../middleware/auth');

const router = express.Router();
router.use(protect);

const populateChat = (query) =>
  query
    .populate('participants', 'name username avatarColor online lastSeen')
    .populate({ path: 'lastMessage', populate: { path: 'sender', select: 'name avatarColor' } });

// GET /api/chats
router.get('/', async (req, res) => {
  try {
    const chats = await populateChat(
      Chat.find({ participants: req.user.userId })
    ).sort({ updatedAt: -1 });

    // Attach this user's unread count to each chat
    const result = chats.map(chat => {
      const obj = chat.toObject();
      obj.unreadCount = chat.unreadCounts?.get(req.user.userId.toString()) || 0;
      return obj;
    });

    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ message: 'Server error fetching chats', error: error.message });
  }
});

// POST /api/chats
router.post('/', async (req, res) => {
  try {
    const { participantId } = req.body;
    if (!participantId) return res.status(400).json({ message: 'participantId is required' });

    let chat = await populateChat(Chat.findOne({
      isGroup: false,
      participants: { $all: [req.user.userId, participantId], $size: 2 }
    }));

    if (!chat) {
      const newChat = await Chat.create({ participants: [req.user.userId, participantId], isGroup: false });
      chat = await populateChat(Chat.findById(newChat._id));
    }

    const obj = chat.toObject();
    obj.unreadCount = chat.unreadCounts?.get(req.user.userId.toString()) || 0;
    res.status(200).json(obj);
  } catch (error) {
    res.status(500).json({ message: 'Server error creating chat', error: error.message });
  }
});

// GET /api/chats/:id/messages?limit=50&before=<messageId>
router.get('/:id/messages', async (req, res) => {
  try {
    const chat = await Chat.findOne({ _id: req.params.id, participants: req.user.userId });
    if (!chat) return res.status(404).json({ message: 'Chat not found or access denied' });

    const limit = Math.min(parseInt(req.query.limit) || 50, 100);
    const before = req.query.before;

    const query = { chatId: req.params.id };
    if (before) {
      const anchor = await Message.findById(before).select('createdAt');
      if (anchor) query.createdAt = { $lt: anchor.createdAt };
    }

    const messages = await Message.find(query)
      .populate('sender', 'name avatarColor')
      .sort({ createdAt: -1 }) // newest first so limit cuts off oldest
      .limit(limit);

    messages.reverse(); // return in chronological order

    res.status(200).json({
      messages,
      hasMore: messages.length === limit,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error fetching messages', error: error.message });
  }
});

// POST /api/chats/:id/messages
router.post('/:id/messages', async (req, res) => {
  try {
    const { text, type = 'text' } = req.body;
    if (!text) return res.status(400).json({ message: 'Message text is required' });

    const chat = await Chat.findOne({ _id: req.params.id, participants: req.user.userId });
    if (!chat) return res.status(404).json({ message: 'Chat not found or access denied' });

    const message = await Message.create({ chatId: req.params.id, sender: req.user.userId, text, type });

    // Increment unread count for every participant except sender
    const unreadUpdate = {};
    chat.participants.forEach(p => {
      if (p.toString() !== req.user.userId.toString()) {
        unreadUpdate[`unreadCounts.${p}`] = 1;
      }
    });
    await Chat.findByIdAndUpdate(req.params.id, {
      $inc: unreadUpdate,
      lastMessage: message._id,
      updatedAt: new Date()
    });

    const populatedMessage = await Message.findById(message._id).populate('sender', 'name avatarColor');

    const io = req.app.get('io');
    if (io) {
      io.to(`chat_${req.params.id}`).emit('new_message', populatedMessage);
      chat.participants.forEach(participantId => {
        if (participantId.toString() !== req.user.userId.toString()) {
          io.to(`user_${participantId}`).emit('new_message', populatedMessage);
        }
      });
    }

    res.status(201).json(populatedMessage);
  } catch (error) {
    res.status(500).json({ message: 'Server error sending message', error: error.message });
  }
});

// PATCH /api/chats/:id/read — mark all messages as read, reset unread count
router.patch('/:id/read', async (req, res) => {
  try {
    const chat = await Chat.findOne({ _id: req.params.id, participants: req.user.userId });
    if (!chat) return res.status(404).json({ message: 'Chat not found' });

    // Mark all messages from others as read
    await Message.updateMany(
      { chatId: req.params.id, sender: { $ne: req.user.userId }, status: { $ne: 'read' } },
      { status: 'read' }
    );

    // Reset this user's unread count to 0
    await Chat.findByIdAndUpdate(req.params.id, {
      [`unreadCounts.${req.user.userId}`]: 0
    });

    // Notify everyone in chat that this user read the messages (for blue ticks)
    const io = req.app.get('io');
    if (io) {
      io.to(`chat_${req.params.id}`).emit('messages_read', {
        chatId: req.params.id,
        readBy: req.user.userId
      });
    }

    res.status(200).json({ message: 'Messages marked as read' });
  } catch (error) {
    res.status(500).json({ message: 'Server error marking as read', error: error.message });
  }
});

module.exports = router;
