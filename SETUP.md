# WhatsApp Clone — Setup Guide

Full-stack messaging app: Flutter (Android) + Node.js backend + MongoDB + Socket.io

---

## Prerequisites

- Node.js 18+
- Flutter 3.10+
- An Android device or emulator
- Your MongoDB connection string (Atlas or self-hosted)

---

## 1. Backend Setup

### Step 1 — Add your MongoDB credentials

```bash
cd backend
cp .env.example .env
```

Open `backend/.env` and fill in:

```
PORT=3000
MONGODB_URI=mongodb+srv://YOUR_USERNAME:YOUR_PASSWORD@YOUR_CLUSTER.mongodb.net/whatsapp_clone?retryWrites=true&w=majority
JWT_SECRET=pick_any_long_random_string_here
```

### Step 2 — Install dependencies

```bash
cd backend
npm install
```

### Step 3 — Start the backend

```bash
npm run dev       # development (nodemon, auto-restarts on changes)
# or
npm start         # production
```

You should see:
```
MongoDB Connected: <your-host>
Server running on port 3000
```

### API is now live at: `http://localhost:3000`

---

## 2. Flutter App Setup

### Step 1 — Point the app at your backend

If running on a physical Android device (not emulator), update `flutter_app/lib/constants.dart`:

```dart
// For Android emulator (default):
const String kBaseUrl = 'http://10.0.2.2:3000/api';
const String kSocketUrl = 'http://10.0.2.2:3000';

// For physical device (replace with your machine's local IP):
const String kBaseUrl = 'http://192.168.1.X:3000/api';
const String kSocketUrl = 'http://192.168.1.X:3000';
```

> `10.0.2.2` is the Android emulator's alias for your host machine's `localhost`.

### Step 2 — Install Flutter dependencies

```bash
cd flutter_app
flutter pub get
```

### Step 3 — Run the app

```bash
flutter run
```

---

## App Features

### Authentication
- Register with name, email, optional phone, password
- Login with email + password
- JWT stored securely via flutter_secure_storage
- Auto-login on app restart

### Chats
- Real-time messaging via Socket.io
- Typing indicators (animated dots)
- Message delivery status (sent → delivered → read)
- Emoji picker (50 emojis)
- Attach / camera buttons (UI ready, file upload coming)
- Chat wallpaper (#ECE5DD green-grey)

### Updates (Status)
- View statuses from contacts
- Animated ring: green = unseen, grey = viewed
- Add your own status

### Calls
- Call history with incoming / outgoing / missed indicators
- Audio and video call log entries

### Communities
- Placeholder screen for community creation

---

## Project Structure

```
backend/
  server.js              # Express + Socket.io entry point
  config/db.js           # MongoDB connection
  middleware/auth.js     # JWT protect middleware
  models/                # Mongoose schemas (User, Chat, Message, Call, Status)
  routes/                # REST API routes (auth, chats, users, calls, status)
  socket/socketHandler.js # Real-time Socket.io events

flutter_app/
  lib/
    constants.dart        # API URLs, theme colors
    main.dart             # App entry + routing
    theme/app_theme.dart  # Material Design 3 theme
    models/               # Dart models (User, Chat, Message, Call, Status)
    services/             # API, Socket, Storage services
    providers/            # AuthProvider, ChatProvider (state management)
    screens/              # All app screens
    widgets/              # Reusable widgets (Avatar, MessageBubble, ChatListItem)
    utils/time_utils.dart # Timestamp formatting
```

---

## Socket.io Events Reference

| Direction | Event | Payload |
|-----------|-------|---------|
| Client → Server | `authenticate` | `{ token }` |
| Client → Server | `join_chat` | `{ chatId }` |
| Client → Server | `send_message` | `{ chatId, text }` |
| Client → Server | `typing` | `{ chatId, isTyping }` |
| Client → Server | `message_read` | `{ chatId, messageId }` |
| Server → Client | `new_message` | Message object |
| Server → Client | `message_status` | `{ messageId, status }` |
| Server → Client | `typing` | `{ userId, isTyping }` |
| Server → Client | `user_status` | `{ userId, online, lastSeen? }` |
