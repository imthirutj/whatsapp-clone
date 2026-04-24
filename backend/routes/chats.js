const express = require('express');
const Chat = require('../models/Chat');
const Message = require('../models/Message');
const { protect } = require('../middleware/auth');

const router = express.Router();

// All routes protected
router.use(protect);

// GET /api/chats - get all chats for current user
router.get('/', async (req, res) => {
  try {
    const chats = await Chat.find({ participants: req.user.userId })
      .populate('participants', 'name avatarColor online lastSeen')
      .populate({
        path: 'lastMessage',
        populate: {
          path: 'sender',
          select: 'name avatarColor'
        }
      })
      .sort({ updatedAt: -1 });

    res.status(200).json(chats);
  } catch (error) {
    res.status(500).json({ message: 'Server error fetching chats', error: error.message });
  }
});

// POST /api/chats - create or find existing direct chat
router.post('/', async (req, res) => {
  try {
    const { participantId } = req.body;

    if (!participantId) {
      return res.status(400).json({ message: 'participantId is required' });
    }

    // Check if direct chat already exists between both users
    const existingChat = await Chat.findOne({
      isGroup: false,
      participants: { $all: [req.user.userId, participantId], $size: 2 }
    })
      .populate('participants', 'name avatarColor online lastSeen')
      .populate({
        path: 'lastMessage',
        populate: {
          path: 'sender',
          select: 'name avatarColor'
        }
      });

    if (existingChat) {
      return res.status(200).json(existingChat);
    }

    const newChat = await Chat.create({
      participants: [req.user.userId, participantId],
      isGroup: false
    });

    const populatedChat = await Chat.findById(newChat._id)
      .populate('participants', 'name avatarColor online lastSeen')
      .populate({
        path: 'lastMessage',
        populate: {
          path: 'sender',
          select: 'name avatarColor'
        }
      });

    res.status(201).json(populatedChat);
  } catch (error) {
    res.status(500).json({ message: 'Server error creating chat', error: error.message });
  }
});

// GET /api/chats/:id/messages - get all messages for a chat
router.get('/:id/messages', async (req, res) => {
  try {
    const chat = await Chat.findOne({
      _id: req.params.id,
      participants: req.user.userId
    });

    if (!chat) {
      return res.status(404).json({ message: 'Chat not found or access denied' });
    }

    const messages = await Message.find({ chatId: req.params.id })
      .populate('sender', 'name avatarColor')
      .sort({ createdAt: 1 });

    res.status(200).json(messages);
  } catch (error) {
    res.status(500).json({ message: 'Server error fetching messages', error: error.message });
  }
});

// POST /api/chats/:id/messages - send a message
router.post('/:id/messages', async (req, res) => {
  try {
    const { text } = req.body;

    if (!text) {
      return res.status(400).json({ message: 'Message text is required' });
    }

    const chat = await Chat.findOne({
      _id: req.params.id,
      participants: req.user.userId
    });

    if (!chat) {
      return res.status(404).json({ message: 'Chat not found or access denied' });
    }

    const message = await Message.create({
      chatId: req.params.id,
      sender: req.user.userId,
      text
    });

    // Update chat's lastMessage and updatedAt
    await Chat.findByIdAndUpdate(req.params.id, {
      lastMessage: message._id,
      updatedAt: new Date()
    });

    const populatedMessage = await Message.findById(message._id)
      .populate('sender', 'name avatarColor');

    // Emit to the chat room (for users with chat open)
    // AND to each participant's personal room (for users on chats list or background)
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

module.exports = router;
