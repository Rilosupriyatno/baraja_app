import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket _socket;
  final String? baseUrl = dotenv.env['BASE_URL'];
  bool _isConnected = false;

  void connectToSocket({
    required Function(Map<String, dynamic>) onPaymentUpdate,
    required String orderId
  }) {
    print('Attempting to connect to socket server at: $baseUrl');

    try {
      _socket = IO.io(baseUrl, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 10,
        'reconnectionDelay': 1000,
        'timeout': 30000, // 30 seconds timeout
        'forceNew': true, // Force a new connection
      });

      // Connection listeners
      _socket.onConnect((_) {
        print('Connected to socket server with ID: ${_socket.id}');
        _isConnected = true;

        // Join room with acknowledgement callback
        print('Attempting to join room for order: $orderId');
        _socket.emitWithAck('join_order_room', orderId, ack: (data) {
          print('Room join acknowledgement: $data');
        });
      });

      _socket.onConnectError((error) {
        print('Connection error: $error');
        _tryReconnect();
      });

      _socket.onError((error) {
        print('Socket error: $error');
        _tryReconnect();
      });

      _socket.onDisconnect((_) {
        print('Disconnected from socket server');
        _isConnected = false;
        _tryReconnect();
      });

      // Debug events
      _socket.onAny((event, data) {
        print('Event received: $event, data: $data');
      });

      // Room joined confirmation
      _socket.on('room_joined', (data) {
        print('Room joined confirmation: $data');
      });

      // Payment update handler
      _socket.on('payment_status_update', (data) {
        print('Received payment update: $data');
        try {
          if (data != null && data is Map) {
            final Map<String, dynamic> paymentData = Map<String, dynamic>.from(data);
            onPaymentUpdate(paymentData);
          } else {
            print('Invalid payment update format: $data');
          }
        } catch (e) {
          print('Error processing payment update: $e');
        }
      });

      // Server ping handler
      _socket.on('ping', (data) {
        print('Received ping from server: $data');
        _socket.emit('pong', {'message': 'Pong from client', 'timestamp': DateTime.now().toIso8601String()});
      });
    } catch (e) {
      print('Error setting up socket connection: $e');
    }
  }

  void _tryReconnect() {
    if (!_isConnected && _socket != null) {
      print('Attempting to reconnect...');
      Future.delayed(Duration(seconds: 2), () {
        _socket.connect();
      });
    }
  }

  // Method to manually emit join_order_room event
  void joinOrderRoom(String orderId) {
    if (_socket != null && _socket.connected) {
      print('Manually joining room for order: $orderId');
      _socket.emitWithAck('join_order_room', orderId, ack: (data) {
        print('Manual room join acknowledgement: $data');
      });
    } else {
      print('Cannot join room - socket not connected');
    }
  }

  void dispose() {
    print('Disposing socket connection');
    if (_socket != null) {
      _socket.disconnect();
      _socket.dispose();
    }
  }
}