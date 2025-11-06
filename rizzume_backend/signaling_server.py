"""
WebRTC Signaling Server for Rizzume P2P Chat
Free, lightweight Python server for WebRTC peer connection setup
Uses Flask + SocketIO for real-time signaling
"""

from flask import Flask, request
from flask_socketio import SocketIO, emit, join_room, leave_room
from flask_cors import CORS
import logging

app = Flask(__name__)
app.config['SECRET_KEY'] = 'rizzume-p2p-chat-secret-2024'
CORS(app)

socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')

# Store connected users
connected_users = {}

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@app.route('/')
def index():
    return {
        'status': 'online',
        'service': 'Rizzume WebRTC Signaling Server',
        'connected_users': len(connected_users),
        'version': '1.0.0'
    }


@app.route('/health')
def health():
    return {'status': 'healthy', 'users': len(connected_users)}


@socketio.on('connect')
def handle_connect():
    logger.info(f'Client connected: {request.sid}')
    emit('connected', {'sid': request.sid})


@socketio.on('disconnect')
def handle_disconnect():
    # Remove user from connected users
    disconnected_user = None
    for user_id, sid in list(connected_users.items()):
        if sid == request.sid:
            disconnected_user = user_id
            del connected_users[user_id]
            break
    
    if disconnected_user:
        logger.info(f'User disconnected: {disconnected_user}')
        # Notify other users
        emit('user-disconnected', {'userId': disconnected_user}, broadcast=True)
    else:
        logger.info(f'Client disconnected: {request.sid}')


@socketio.on('register')
def handle_register(data):
    user_id = data.get('userId')
    if not user_id:
        emit('error', {'message': 'userId is required'})
        return
    
    # Store user mapping
    connected_users[user_id] = request.sid
    join_room(user_id)
    
    logger.info(f'User registered: {user_id} (SID: {request.sid})')
    emit('user-registered', {
        'userId': user_id,
        'message': 'Successfully registered'
    })
    
    # Notify others about new user
    emit('user-online', {'userId': user_id}, broadcast=True, include_self=False)


@socketio.on('offer')
def handle_offer(data):
    to_user = data.get('to')
    from_user = data.get('from')
    offer = data.get('offer')
    
    if not all([to_user, from_user, offer]):
        emit('error', {'message': 'Invalid offer data'})
        return
    
    # Check if target user is connected
    if to_user not in connected_users:
        emit('error', {'message': f'User {to_user} is not online'})
        logger.warning(f'Offer failed: User {to_user} not found')
        return
    
    # Forward offer to target user
    target_sid = connected_users[to_user]
    logger.info(f'Forwarding offer from {from_user} to {to_user}')
    
    emit('offer', {
        'from': from_user,
        'offer': offer
    }, room=target_sid)


@socketio.on('answer')
def handle_answer(data):
    to_user = data.get('to')
    from_user = data.get('from')
    answer = data.get('answer')
    
    if not all([to_user, from_user, answer]):
        emit('error', {'message': 'Invalid answer data'})
        return
    
    # Check if target user is connected
    if to_user not in connected_users:
        emit('error', {'message': f'User {to_user} is not online'})
        logger.warning(f'Answer failed: User {to_user} not found')
        return
    
    # Forward answer to target user
    target_sid = connected_users[to_user]
    logger.info(f'Forwarding answer from {from_user} to {to_user}')
    
    emit('answer', {
        'from': from_user,
        'answer': answer
    }, room=target_sid)


@socketio.on('ice-candidate')
def handle_ice_candidate(data):
    to_user = data.get('to')
    from_user = data.get('from')
    candidate = data.get('candidate')
    
    if not all([to_user, from_user, candidate]):
        emit('error', {'message': 'Invalid ICE candidate data'})
        return
    
    # Check if target user is connected
    if to_user not in connected_users:
        logger.warning(f'ICE candidate failed: User {to_user} not found')
        return
    
    # Forward ICE candidate to target user
    target_sid = connected_users[to_user]
    logger.info(f'Forwarding ICE candidate from {from_user} to {to_user}')
    
    emit('ice-candidate', {
        'from': from_user,
        'candidate': candidate
    }, room=target_sid)


@socketio.on('ping')
def handle_ping():
    emit('pong', {'timestamp': request.sid})


if __name__ == '__main__':
    import os
    port = int(os.getenv('PORT', '5050'))  # default to 5050 to avoid macOS AirPlay conflict on 5000
    logger.info('🚀 Starting Rizzume WebRTC Signaling Server...')
    logger.info(f'📡 Server will be accessible on port {port}')
    logger.info('🔒 Using WebSocket transport for real-time communication')
    logger.info('🌐 CORS enabled for all origins')

    # Run server on all interfaces (0.0.0.0) to allow external connections
    socketio.run(
        app,
        host='0.0.0.0',
        port=port,
        debug=True,
        allow_unsafe_werkzeug=True
    )
