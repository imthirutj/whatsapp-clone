const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Message = require('../models/Message');
const Chat = require('../models/Chat');

const setupSocket = (io) => {
  io.on('connection', (socket) => {
    console.log(`Socket connected: ${socket.id}`);

    // Authenticate socket connection
    socket.on('authenticate', async ({ token }) => {
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        socket.userId = decoded.userId;

        // Join personal room for direct messages/notifications
        socket.join(`user_${socket.userId}`);

        // Mark user as online in DB
        await User.findByIdAndUpdate(socket.userId, { online: true });

        // Deliver all messages that arrived while user was offline
        const chats = await Chat.find({ participants: socket.userId }).select('_id');
        const chatIds = chats.map(c => c._id);
        const pendingMessages = await Message.find({
          chatId: { $in: chatIds },
          sender: { $ne: socket.userId },
          status: 'sent'
        }).select('_id chatId');

        if (pendingMessages.length > 0) {
          await Message.updateMany(
            { _id: { $in: pendingMessages.map(m => m._id) } },
            { status: 'delivered' }
          );
          for (const msg of pendingMessages) {
            io.to(`chat_${msg.chatId}`).emit('message_status', {
              chatId: msg.chatId.toString(),
              messageId: msg._id.toString(),
              status: 'delivered'
            });
          }
        }

        // Broadcast online status to all other connected clients
        socket.broadcast.emit('user_status', {
          userId: socket.userId,
          online: true
        });

        console.log(`User ${socket.userId} authenticated and online`);
      } catch (error) {
        console.error('Socket authentication error:', error.message);
        socket.emit('auth_error', { message: 'Authentication failed' });
      }
    });

    // Join a chat room
    socket.on('join_chat', ({ chatId }) => {
      socket.join(`chat_${chatId}`);
      console.log(`Socket ${socket.id} joined chat_${chatId}`);
    });

    // Send a message via socket
    socket.on('send_message', async ({ chatId, text }) => {
      try {
        if (!socket.userId) {
          socket.emit('error', { message: 'Not authenticated' });
          return;
        }

        const message = await Message.create({
          chatId,
          sender: socket.userId,
          text
        });

        // Update chat's lastMessage and updatedAt
        await Chat.findByIdAndUpdate(chatId, {
          lastMessage: message._id,
          updatedAt: new Date()
        });

        const populatedMessage = await Message.findById(message._id)
          .populate('sender', 'name avatarColor');

        const chat = await Chat.findById(chatId).select('participants');

        if (chat) {
          // Increment unread for all other participants
          const unreadUpdate = {};
          chat.participants.forEach(p => {
            if (p.toString() !== socket.userId.toString()) {
              unreadUpdate[`unreadCounts.${p}`] = 1;
            }
          });
          await Chat.findByIdAndUpdate(chatId, { $inc: unreadUpdate });

          // Emit to chat room + each participant's personal room
          io.to(`chat_${chatId}`).emit('new_message', populatedMessage);
          chat.participants.forEach(participantId => {
            if (participantId.toString() !== socket.userId.toString()) {
              io.to(`user_${participantId}`).emit('new_message', populatedMessage);
            }
          });
        }
      } catch (error) {
        console.error('Socket send_message error:', error.message);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // Typing indicator
    socket.on('typing', ({ chatId, isTyping }) => {
      if (!socket.userId) return;

      socket.to(`chat_${chatId}`).emit('typing', {
        chatId,
        userId: socket.userId,
        isTyping
      });
    });

    // Live typing — broadcast actual text as user types
    socket.on('live_typing', ({ chatId, text }) => {
      if (!socket.userId) return;

      socket.to(`chat_${chatId}`).emit('live_typing', {
        chatId,
        userId: socket.userId,
        text: text ?? ''
      });
    });

    // Delivery confirmation — emitted by recipient when they receive a new_message
    socket.on('message_delivered', async ({ messageId, chatId }) => {
      if (!socket.userId) return;
      try {
        // Only upgrade from 'sent'; never downgrade from 'read'
        await Message.findOneAndUpdate(
          { _id: messageId, status: 'sent' },
          { status: 'delivered' }
        );

        io.to(`chat_${chatId}`).emit('message_status', {
          chatId,
          messageId,
          status: 'delivered'
        });
      } catch (error) {
        console.error('Socket message_delivered error:', error.message);
      }
    });

    // Mark message as read
    socket.on('message_read', async ({ chatId, messageId }) => {
      try {
        if (!socket.userId) {
          socket.emit('error', { message: 'Not authenticated' });
          return;
        }

        await Message.findByIdAndUpdate(messageId, { status: 'read' });

        io.to(`chat_${chatId}`).emit('message_status', {
          chatId,
          messageId,
          status: 'read'
        });
      } catch (error) {
        console.error('Socket message_read error:', error.message);
        socket.emit('error', { message: 'Failed to update message status' });
      }
    });

    // Handle disconnect
    socket.on('disconnect', async () => {
      console.log(`Socket disconnected: ${socket.id}`);

      if (socket.userId) {
        try {
          const lastSeen = new Date();

          // Mark user offline and update lastSeen
          await User.findByIdAndUpdate(socket.userId, {
            online: false,
            lastSeen
          });

          // Broadcast offline status to all other connected clients
          socket.broadcast.emit('user_status', {
            userId: socket.userId,
            online: false,
            lastSeen
          });

          console.log(`User ${socket.userId} is now offline`);
        } catch (error) {
          console.error('Socket disconnect error:', error.message);
        }
      }
    });
  });
};

module.exports = setupSocket;
