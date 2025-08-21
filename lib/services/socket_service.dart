import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket _socket;
  final String? baseUrl = dotenv.env['BASE_URL'];
  bool _isConnected = false;

  void connectToSocket({
    required Function(Map<String, dynamic>) onPaymentUpdate,
    required Function(Map<String, dynamic>) onOrderUpdate, // ✅ tambahan callback
    required String id,
  }) {
    print('Attempting to connect to socket server at: $baseUrl');

    try {
      _socket = IO.io(baseUrl, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 10,
        'reconnectionDelay': 1000,
        'timeout': 30000,
        'forceNew': true,
      });

      _socket.onConnect((_) {
        print('Connected to socket server with ID: ${_socket.id}');
        _isConnected = true;

        // Join room dengan ack
        print('Attempting to join room for order: $id');
        _socket.emitWithAck('join_order_room', id, ack: (data) {
          print('Room join acknowledgement: $data');
        });
      });

      // 🔔 Payment update
      _socket.on('payment_status_update', (data) {
        print('Received payment update: $data');
        if (data is Map) {
          onPaymentUpdate(Map<String, dynamic>.from(data));
        }
      });

      // 🔔 Order status update
      _socket.on('order_status_update', (data) {
        print('Received order status update: $data');
        if (data is Map) {
          onOrderUpdate(Map<String, dynamic>.from(data));
        }
      });

      _socket.onDisconnect((_) {
        print('Disconnected from socket server');
        _isConnected = false;
        _tryReconnect();
      });

      _socket.onError((error) {
        print('Socket error: $error');
      });
    } catch (e) {
      print('Error setting up socket connection: $e');
    }
  }

  void _tryReconnect() {
    if (!_isConnected) {
      print('Attempting to reconnect...');
      Future.delayed(const Duration(seconds: 2), () {
        _socket.connect();
      });
    }
  }

  void joinOrderRoom(String id) {
    if (_socket.connected) {
      print('Manually joining room for order: $id');
      _socket.emitWithAck('join_order_room', id, ack: (data) {
        print('Manual room join acknowledgement: $data');
      });
    } else {
      print('Cannot join room - socket not connected');
    }
  }

  void dispose() {
    print('Disposing socket connection');
    _socket.disconnect();
    _socket.dispose();
  }
}
