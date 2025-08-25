import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket _socket;
  final String? baseUrl = dotenv.env['BASE_URL'];
  bool _isConnected = false;

  void connectToSocket({
    required Function(Map<String, dynamic>) onPaymentUpdate,
    required Function(Map<String, dynamic>) onOrderUpdate,
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

        // Join room with acknowledgment
        print('Attempting to join room for order: $id');
        _socket.emitWithAck('join_order_room', id, ack: (data) {
          print('Room join acknowledgement: $data');
        });
      });

      // Payment status updates
      _socket.on('payment_status_update', (data) {
        print('Received payment update: $data');
        if (data is Map) {
          onPaymentUpdate(Map<String, dynamic>.from(data));
        }
      });

      // Order status updates (including cashier confirmations)
      _socket.on('order_status_update', (data) {
        print('Received order status update: $data');
        if (data is Map) {
          final orderData = Map<String, dynamic>.from(data);

          // Handle different status updates
          if (orderData['status'] == 'Waiting') {
            print('Order is now being processed by cashier: ${orderData['cashier']}');
          } else if (orderData['status'] == 'OnProcess'){
            print('Order is now being processed by cashier: ${orderData['cashier']}');
          }
          else if (orderData['status'] == 'Ready') {
            print('Order is ready for pickup/serving');
          } else if (orderData['status'] == 'Completed') {
            print('Order has been completed');
          }

          onOrderUpdate(orderData);
        }
      });

      // Handle specific events for better UX
      _socket.on('order_confirmed', (data) {
        print('Order confirmed by cashier: $data');
        if (data is Map) {
          final confirmData = Map<String, dynamic>.from(data);

          // 🔥 PERBAIKAN: Sertakan paymentStatus dalam mapping data
          final mappedData = {
            'order_id': confirmData['orderId'],
            'orderStatus': confirmData['orderStatus'] ?? 'Waiting', // Gunakan status dari server
            'paymentStatus': confirmData['paymentStatus'] ?? 'settlement', // ✅ TAMBAHKAN ini
            'cashier': confirmData['cashier'],
            'message': confirmData['message'] ?? 'Your order is now being prepared',
            'timestamp': confirmData['timestamp'],
          };

          print('🔧 Mapped order_confirmed data: $mappedData');
          onOrderUpdate(mappedData);
        }
      });

      // Kitchen updates (if you want to show cooking progress)
      _socket.on('kitchen_update', (data) {
        print('Kitchen update received: $data');
        if (data is Map) {
          final kitchenData = Map<String, dynamic>.from(data);

          // 🔥 PERBAIKAN: Pastikan struktur data konsisten
          final mappedKitchenData = {
            'order_id': kitchenData['orderId'],
            'orderStatus': kitchenData['orderStatus'],
            'paymentStatus': kitchenData['paymentStatus'], // ✅ Sertakan jika ada
            'message': kitchenData['message'] ?? 'Your food is ready!',
            'completedItems': kitchenData['completedItems'],
            'timestamp': kitchenData['timestamp'],
          };

          print('🔧 Mapped kitchen_update data: $mappedKitchenData');
          onOrderUpdate(mappedKitchenData);
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

      // Handle reconnect event
      _socket.onReconnect((_) {
        print('Reconnected to socket server');
        _isConnected = true;
        // Rejoin the room after reconnection
        _socket.emitWithAck('join_order_room', id, ack: (data) {
          print('Rejoined room after reconnection: $data');
        });
      });

    } catch (e) {
      print('Error setting up socket connection: $e');
    }
  }

  void _tryReconnect() {
    if (!_isConnected) {
      print('Attempting to reconnect...');
      Future.delayed(const Duration(seconds: 2), () {
        if (!_isConnected) {
          _socket.connect();
        }
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

  // Method to send order status update (if customer can trigger any actions)
  void updateOrderStatus(String orderId, String orderStatus) {
    if (_socket.connected) {
      _socket.emit('update_order_status', {
        'orderId': orderId,
        'orderStatus': orderStatus,
        'source': 'customer',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  bool get isConnected => _isConnected;

  void dispose() {
    print('Disposing socket connection');
    if (_socket.connected) {
      _socket.disconnect();
    }
    _socket.dispose();
  }
}