# Rizzume P2P Chat - Setup & Deployment Guide

## 🎯 Overview
This is a **free, peer-to-peer WebRTC chat system** that works even under restricted college Wi-Fi (where WhatsApp/Instagram are blocked). Messages are exchanged directly between devices with **no database required**.

## ✨ Features
- ✅ Direct peer-to-peer messaging via WebRTC DataChannels
- ✅ Works under restrictive networks (NAT traversal via STUN)
- ✅ No database needed (messages stored locally on device)
- ✅ Auto-encrypted messages (WebRTC default encryption)
- ✅ Free public STUN servers (Google's stun.l.google.com)
- ✅ Lightweight Python signaling server
- ✅ Modern Gen-Z UI with gradient bubbles

---

## 🚀 Quick Start

### Step 1: Set Up Python Signaling Server

#### Option A: Deploy on Your Local Network (Testing)

1. **Install Python 3.8+** (if not already installed)

2. **Navigate to backend folder:**
   ```bash
   cd rizzume_backend
   ```

3. **Install dependencies:**
   ```bash
   pip install -r signaling_requirements.txt
   ```

4. **Run the server:**
   ```bash
   python signaling_server.py
   ```

5. **Server will start on:** `http://0.0.0.0:5000`
   - Access from same machine: `http://localhost:5000`
   - Access from other devices: `http://YOUR_LOCAL_IP:5000`
   - Find your local IP:
     - **macOS/Linux:** `ifconfig` or `ip addr`
     - **Windows:** `ipconfig`

#### Option B: Deploy on Free Cloud (Production)

**Recommended: Render.com (Free Tier)**

1. **Create account** at [render.com](https://render.com)

2. **Create new Web Service:**
   - Connect your GitHub repo
   - Or upload `signaling_server.py` + `signaling_requirements.txt`

3. **Configure service:**
   - **Build Command:** `pip install -r signaling_requirements.txt`
   - **Start Command:** `python signaling_server.py`
   - **Environment:** Python 3
   - **Port:** 5000

4. **Deploy** - You'll get a URL like `https://your-app.onrender.com`

**Alternative Free Options:**
- **Railway.app** - 500 hours/month free
- **Fly.io** - Free tier with 3 VMs
- **PythonAnywhere** - Free with some limitations
- **Heroku** - Eco dynos ($5/month, no free tier)

---

### Step 2: Update Flutter App Configuration

1. **Open:** `lib/services/webrtc_chat_service.dart`

2. **Find line 12:**
   ```dart
   static const String SIGNALING_SERVER = 'http://YOUR_SERVER_IP:5000';
   ```

3. **Update with your server URL:**
   - **Local testing:** `'http://192.168.1.100:5000'` (your local IP)
   - **Cloud deployment:** `'https://your-app.onrender.com'`

4. **Save the file**

---

### Step 3: Generate Hive Adapters

The app uses Hive for local message storage. Generate the adapter code:

1. **Add build dependencies to `pubspec.yaml`:**
   ```yaml
   dev_dependencies:
     build_runner: ^2.4.8
     hive_generator: ^2.0.1
   ```

2. **Run code generation:**
   ```bash
   flutter pub get
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

This will generate `lib/models/chat_message.g.dart`

---

### Step 4: Run the Flutter App

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run on your device:**
   ```bash
   flutter run
   ```

3. **Or build APK for Android:**
   ```bash
   flutter build apk --release
   ```

---

## 💬 How to Use the Chat

### Starting a Chat:

1. **Both users must have the app installed**

2. **From user profile screen:**
   - Tap the **Message** button on any user's profile
   - This opens the P2P chat screen

3. **Connection process:**
   - App connects to signaling server
   - WebRTC handshake happens automatically
   - Direct P2P connection established
   - Start chatting!

### Integration with Existing Code:

The Message button already exists in `user_profile_view_screen.dart`. Update it:

```dart
OutlinedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => P2PChatScreen(
          targetUserId: widget.userId,
          targetUserName: userName,
        ),
      ),
    );
  },
  // ... rest of button styling
)
```

---

## 🔧 Troubleshooting

### "Connection failed" error:
- ✅ Check signaling server is running: Visit `http://YOUR_SERVER:5000` in browser
- ✅ Verify `SIGNALING_SERVER` URL is correct in `webrtc_chat_service.dart`
- ✅ Ensure both devices can reach the server

### Messages not sending:
- ✅ Check connection status shows "Connected ✓"
- ✅ Verify both users are online
- ✅ Check device internet connection

### "Peer not found" error:
- ✅ Ensure target user has app open and connected
- ✅ Both users must be registered with server

### Connection works on Wi-Fi but not mobile data:
- ✅ This is normal - some mobile carriers use symmetric NAT
- ✅ Solution: Use TURN server (see Advanced Setup below)

---

## 🌐 Network Requirements

### What You Need:
- ✅ Internet connection (any type)
- ✅ Access to signaling server (HTTP/WebSocket)
- ✅ Access to STUN server (UDP port 19302)

### Will It Work On:
- ✅ College/School Wi-Fi (even with WhatsApp blocked)
- ✅ Mobile data (4G/5G)
- ✅ Home broadband
- ✅ Public Wi-Fi
- ⚠️ Corporate networks (might block WebRTC)

### Ports Used:
- **Signaling:** TCP 5000 (HTTP/WebSocket)
- **STUN:** UDP 19302 (Google's public server)
- **P2P Data:** Random high UDP ports (handled automatically)

---

## 🔒 Security & Privacy

### What's Encrypted:
- ✅ All P2P messages (DTLS encryption by WebRTC)
- ✅ Signaling messages (use HTTPS for server in production)

### What's Stored:
- ✅ Messages stored locally on device only (Hive database)
- ✅ No messages stored on server
- ✅ Signaling server only stores active user IDs (in memory)

### Privacy Notes:
- Signaling server sees: User IDs, connection metadata
- Signaling server does NOT see: Message content
- Messages are peer-to-peer after connection

---

## 📊 Testing the System

### Test 1: Same Network
1. Run app on 2 devices connected to same Wi-Fi
2. Open chat between users
3. Should connect in 1-3 seconds

### Test 2: Different Networks
1. One device on Wi-Fi, one on mobile data
2. Open chat between users
3. Should connect in 2-5 seconds

### Test 3: Server Health
Visit: `http://YOUR_SERVER:5000/health`

Response should show:
```json
{
  "status": "healthy",
  "users": 2
}
```

---

## 🚀 Advanced Setup

### Adding TURN Server (for difficult NAT situations):

If connections fail on certain networks, add a TURN server:

1. **Free TURN Server:** Use Metered TURN
   - Sign up at: https://www.metered.ca/tools/openrelay/
   - Get free credentials

2. **Update configuration in `webrtc_chat_service.dart`:**
   ```dart
   static const Map<String, dynamic> configuration = {
     'iceServers': [
       {'urls': 'stun:stun.l.google.com:19302'},
       {
         'urls': 'turn:a.relay.metered.ca:80',
         'username': 'YOUR_USERNAME',
         'credential': 'YOUR_CREDENTIAL'
       }
     ]
   };
   ```

### Monitoring Server Logs:

The Python server logs all events:
```bash
# View real-time logs
python signaling_server.py

# Output includes:
# - User connections/disconnections
# - Offer/Answer exchanges
# - ICE candidate exchanges
# - Errors
```

---

## 💾 Local Message Storage

Messages are stored using Hive (NoSQL database on device):

### Location:
- **Android:** `/data/data/com.example.rizzume/app_flutter/`
- **iOS:** App's documents directory

### Data Structure:
```dart
ChatMessage {
  String id;           // Unique message ID
  String senderId;     // Sender user ID
  String receiverId;   // Receiver user ID
  String message;      // Message text
  DateTime timestamp;  // When sent
  bool isSentByMe;     // Direction indicator
}
```

### Clearing Messages:
```dart
// In app, add a "Clear Chat" button:
await _chatService.chatBox?.clear();
```

---

## 📱 Production Deployment Checklist

### Before Release:

- [ ] Deploy signaling server to production (Render/Railway/etc.)
- [ ] Update `SIGNALING_SERVER` URL in code
- [ ] Enable HTTPS for signaling server (automatic on Render/Railway)
- [ ] Test on multiple networks (Wi-Fi, 4G, 5G)
- [ ] Add error handling for offline scenarios
- [ ] Implement connection retry logic
- [ ] Add "Clear Chat History" feature
- [ ] Build release APK/IPA

### Performance Tips:

1. **Connection Timeouts:**
   - Current: Unlimited wait
   - Recommended: Add 30-second timeout

2. **Message Limits:**
   - WebRTC DataChannel max: 256KB per message
   - For large files: Implement chunking

3. **Reconnection:**
   - Add automatic reconnect on disconnect
   - Store unsent messages in queue

---

## 🆘 Support & Resources

### Documentation:
- **WebRTC:** https://webrtc.org/
- **Flutter WebRTC:** https://pub.dev/packages/flutter_webrtc
- **Hive:** https://docs.hivedb.dev/

### Common Issues:
- **"Peer not connected"** → User is offline
- **"ICE negotiation failed"** → Network blocking WebRTC
- **"Signaling server unreachable"** → Check server URL

---

## 🎉 You're All Set!

Your P2P chat system is now ready. Users can chat directly without any database, and it works even under restricted networks!

**Key Points to Remember:**
- ✅ Signaling server must be running and accessible
- ✅ Both users need internet (any type)
- ✅ Messages are encrypted and peer-to-peer
- ✅ No chat history on server (privacy-first)
- ✅ Free to run (no paid services required)

Happy chatting! 🚀💬
