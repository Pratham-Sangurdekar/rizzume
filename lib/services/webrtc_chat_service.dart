import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';

class WebRTCChatService {
  // Update to match the backend port. Change host/IP as needed.
  static const String SIGNALING_SERVER = 'http://192.168.29.34:5051';
  
  // Google's free STUN server
  static const Map<String, dynamic> configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  IO.Socket? socket;
  RTCPeerConnection? peerConnection;
  RTCDataChannel? dataChannel;
  
  String? myUserId;
  String? remoteUserId;
  String? currentChatId;
  
  final StreamController<ChatMessage> _messageController = StreamController<ChatMessage>.broadcast();
  final StreamController<String> _connectionController = StreamController<String>.broadcast();
  
  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<String> get connectionStream => _connectionController.stream;
  
  Box<ChatMessage>? chatBox;
  bool isConnected = false;
  
  Future<void> initialize(String userId) async {
    myUserId = userId;
    
    // Initialize Hive for local message storage
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }
    chatBox = await Hive.openBox<ChatMessage>('chat_messages');
    
    // Connect to signaling server
    _connectToSignalingServer();
  }

  void _connectToSignalingServer() {
    print('🔌 Connecting to signaling server: $SIGNALING_SERVER');
    
    socket = IO.io(SIGNALING_SERVER, 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build()
    );

    socket!.connect();

    socket!.onConnect((_) {
      print('✅ Connected to signaling server');
      socket!.emit('register', {'userId': myUserId});
      _connectionController.add('connected');
    });

    socket!.on('user-registered', (data) {
      print('✅ User registered: $data');
    });

    socket!.on('offer', (data) async {
      print('📨 Received offer from ${data['from']}');
      remoteUserId = data['from'];
      await _handleOffer(data['offer']);
    });

    socket!.on('answer', (data) async {
      print('📨 Received answer from ${data['from']}');
      await _handleAnswer(data['answer']);
    });

    socket!.on('ice-candidate', (data) async {
      print('🧊 Received ICE candidate');
      await _handleIceCandidate(data['candidate']);
    });

    socket!.onDisconnect((_) {
      print('❌ Disconnected from signaling server');
      _connectionController.add('disconnected');
    });

    socket!.on('error', (data) {
      print('❌ Socket error: $data');
    });
  }

  Future<void> connectToPeer(String targetUserId) async {
    if (remoteUserId == targetUserId && isConnected) {
      print('⚠️ Already connected to this user');
      return;
    }

    remoteUserId = targetUserId;
    currentChatId = _getChatId(myUserId!, remoteUserId!);
    
    print('🔗 Initiating connection to: $targetUserId');
    
    // Create peer connection
    peerConnection = await createPeerConnection(configuration);
    
    // Create data channel
    RTCDataChannelInit dataChannelDict = RTCDataChannelInit();
    dataChannel = await peerConnection!.createDataChannel('chat', dataChannelDict);
    
    _setupDataChannel();

    // Handle ICE candidates
    peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      print('🧊 Sending ICE candidate');
      socket!.emit('ice-candidate', {
        'to': targetUserId,
        'from': myUserId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        }
      });
    };

    peerConnection!.onDataChannel = (RTCDataChannel channel) {
      print('📡 Data channel received');
      dataChannel = channel;
      _setupDataChannel();
    };

    // Create and send offer
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    
    print('📤 Sending offer to $targetUserId');
    socket!.emit('offer', {
      'to': targetUserId,
      'from': myUserId,
      'offer': {
        'type': offer.type,
        'sdp': offer.sdp,
      }
    });
  }

  Future<void> _handleOffer(Map<String, dynamic> offer) async {
    print('🔗 Handling offer...');
    currentChatId = _getChatId(myUserId!, remoteUserId!);
    
    peerConnection = await createPeerConnection(configuration);

    peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      print('🧊 Sending ICE candidate');
      socket!.emit('ice-candidate', {
        'to': remoteUserId,
        'from': myUserId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        }
      });
    };

    peerConnection!.onDataChannel = (RTCDataChannel channel) {
      print('📡 Data channel received');
      dataChannel = channel;
      _setupDataChannel();
    };

    await peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type'])
    );

    RTCSessionDescription answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    print('📤 Sending answer');
    socket!.emit('answer', {
      'to': remoteUserId,
      'from': myUserId,
      'answer': {
        'type': answer.type,
        'sdp': answer.sdp,
      }
    });
  }

  Future<void> _handleAnswer(Map<String, dynamic> answer) async {
    print('✅ Setting remote description with answer');
    await peerConnection?.setRemoteDescription(
      RTCSessionDescription(answer['sdp'], answer['type'])
    );
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> candidateData) async {
    print('🧊 Adding ICE candidate');
    RTCIceCandidate candidate = RTCIceCandidate(
      candidateData['candidate'],
      candidateData['sdpMid'],
      candidateData['sdpMLineIndex'],
    );
    await peerConnection?.addCandidate(candidate);
  }

  void _setupDataChannel() {
    dataChannel?.onMessage = (RTCDataChannelMessage message) {
      print('📨 Received message: ${message.text}');
      if (message.text.isNotEmpty) {
        _handleReceivedMessage(message.text);
      }
    };

    dataChannel?.onDataChannelState = (RTCDataChannelState state) {
      print('📡 Data channel state: $state');
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        isConnected = true;
        _connectionController.add('peer_connected');
      } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
        isConnected = false;
        _connectionController.add('peer_disconnected');
      }
    };
  }

  void _handleReceivedMessage(String messageText) {
    try {
      final data = jsonDecode(messageText);
      final message = ChatMessage(
        id: data['id'],
        senderId: data['senderId'],
        receiverId: myUserId!,
        message: data['message'],
        timestamp: DateTime.parse(data['timestamp']),
        isSentByMe: false,
      );

      // Save to local storage
      _saveMessageLocally(message);
      
      // Emit to stream
      _messageController.add(message);
    } catch (e) {
      print('❌ Error handling message: $e');
    }
  }

  Future<void> sendMessage(String messageText) async {
    if (!isConnected || dataChannel == null) {
      print('❌ Not connected to peer');
      throw Exception('Not connected to peer');
    }

    final message = ChatMessage(
      id: const Uuid().v4(),
      senderId: myUserId!,
      receiverId: remoteUserId!,
      message: messageText,
      timestamp: DateTime.now(),
      isSentByMe: true,
    );

    final messageData = jsonEncode({
      'id': message.id,
      'senderId': message.senderId,
      'receiverId': message.receiverId,
      'message': message.message,
      'timestamp': message.timestamp.toIso8601String(),
    });

    try {
      await dataChannel!.send(RTCDataChannelMessage(messageData));
      print('✅ Message sent');
      
      // Save to local storage
      _saveMessageLocally(message);
      
      // Emit to stream
      _messageController.add(message);
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  void _saveMessageLocally(ChatMessage message) {
    try {
      chatBox?.put(message.id, message);
    } catch (e) {
      print('❌ Error saving message locally: $e');
    }
  }

  List<ChatMessage> getLocalMessages(String chatId) {
    try {
      final allMessages = chatBox?.values.toList() ?? [];
      return allMessages.where((msg) {
        final msgChatId = _getChatId(msg.senderId, msg.receiverId);
        return msgChatId == chatId;
      }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      print('❌ Error getting local messages: $e');
      return [];
    }
  }

  String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> disconnect() async {
    isConnected = false;
    await dataChannel?.close();
    await peerConnection?.close();
    socket?.disconnect();
    dataChannel = null;
    peerConnection = null;
    remoteUserId = null;
    _connectionController.add('disconnected');
  }

  void dispose() {
    _messageController.close();
    _connectionController.close();
    chatBox?.close();
    disconnect();
  }
}
