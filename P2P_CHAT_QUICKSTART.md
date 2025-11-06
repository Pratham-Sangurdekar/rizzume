# 🚀 P2P Chat - Quick Start (5 Minutes)

## ✅ Step 1: Run Signaling Server

```bash
cd rizzume_backend
pip install -r signaling_requirements.txt
python signaling_server.py
```

**Server will start at:** `http://0.0.0.0:5000`

---

## ✅ Step 2: Update Server URL

Open: `lib/services/webrtc_chat_service.dart`

**Find line 12:**
```dart
static const String SIGNALING_SERVER = 'http://YOUR_SERVER_IP:5000';
```

**Replace with your IP:**
- **Local testing:** `'http://192.168.1.100:5000'` (use your Mac's IP)
- **Cloud:** `'https://your-app.onrender.com'`

**Get your local IP:**
```bash
# macOS
ifconfig | grep "inet " | grep -v 127.0.0.1
```

---

## ✅ Step 3: Run the App

```bash
flutter pub get
flutter run
```

---

## 📱 How to Test

### Same Network Test:
1. Run app on 2 devices (same Wi-Fi)
2. Open any user's profile
3. Tap **Message** button
4. Start chatting!

### Different Network Test:
1. One device on Wi-Fi, one on 4G/5G
2. Follow same steps above
3. Connection should work (may take 2-5 seconds)

---

## 🔧 Troubleshooting

### "Cannot connect to server"
```bash
# Check server is running:
curl http://YOUR_IP:5000/health

# Should return:
{"status": "healthy", "users": 0}
```

### "Peer not found"
- Make sure target user has app open
- Both users must be connected to server

### Connection stuck
- Check both devices have internet
- Verify server URL is correct in code
- Check server logs for errors

---

## 🎯 What Was Built

### Client (Flutter):
- ✅ `lib/models/chat_message.dart` - Message data model
- ✅ `lib/services/webrtc_chat_service.dart` - P2P communication service
- ✅ `lib/screens/chat/p2p_chat_screen.dart` - Chat UI
- ✅ Message button wired in user profiles

### Server (Python):
- ✅ `rizzume_backend/signaling_server.py` - WebRTC signaling
- ✅ `rizzume_backend/signaling_requirements.txt` - Dependencies

### Infrastructure:
- ✅ WebRTC DataChannels for P2P messaging
- ✅ Google STUN servers for NAT traversal
- ✅ Socket.io for signaling
- ✅ Hive for local message storage

---

## 🌐 Network Architecture

```
Device A                    Signaling Server                    Device B
   |                               |                               |
   |--- Connect to server -------->|<------ Connect to server -----|
   |<-- Registered (ID: user123) --|-- Registered (ID: user456) ->|
   |                               |                               |
   |--- Offer (via server) ------->|------- Forward offer -------->|
   |<------ Answer (via server) ---|<------ Send answer -----------|
   |                               |                               |
   |<============= P2P DataChannel Established ==================>|
   |                               |                               |
   |<============== Direct Messages (No Server) =================>|
```

**Key Points:**
- Server only needed for initial handshake
- After connection, messages go directly P2P
- No messages stored on server
- Works under restricted Wi-Fi

---

## 💡 Production Deployment

### Free Server Hosting:
- **Render.com** (Recommended) - https://render.com
- **Railway.app** - https://railway.app  
- **Fly.io** - https://fly.io

See full guide: `P2P_CHAT_SETUP.md`

---

## 📊 Feature Status

| Feature | Status |
|---------|--------|
| P2P Messaging | ✅ Working |
| Local Storage | ✅ Working |
| Connection Status | ✅ Working |
| Message History | ✅ Working |
| Message Button | ✅ Integrated |
| Read Receipts | ❌ Not implemented |
| Typing Indicator | ❌ Not implemented |
| File Sharing | ❌ Not implemented |
| Group Chat | ❌ Not implemented |

---

## 🔒 Privacy & Security

✅ **End-to-end encrypted** (WebRTC DTLS-SRTP)
✅ **No database** (messages only on device)
✅ **No message logging** (server doesn't see content)
✅ **Free to run** (no paid services)

---

## 📚 Need More Help?

- **Full Setup Guide:** `P2P_CHAT_SETUP.md`
- **WebRTC Docs:** https://webrtc.org/
- **Flutter WebRTC:** https://pub.dev/packages/flutter_webrtc

---

**That's it! You now have a working P2P chat system.** 🎉
