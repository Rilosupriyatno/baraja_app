import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// GRO Socket Service - Handles real-time updates for GRO Dashboard
/// Listens to: order_status_updated, table_status_updated, reservation_cancelled, etc.
class GroSocketService extends ChangeNotifier {
  static final GroSocketService _instance = GroSocketService._internal();
  factory GroSocketService() => _instance;
  GroSocketService._internal();

  IO.Socket? _socket;
  final String? baseUrl = dotenv.env['BASE_URL'];
  bool _isConnected = false;
  
  // Callbacks for real-time updates
  Function(Map<String, dynamic>)? onOrderStatusUpdated;
  Function(Map<String, dynamic>)? onTableStatusUpdated;
  Function(Map<String, dynamic>)? onReservationCancelled;
  Function(Map<String, dynamic>)? onReservationConfirmed;
  Function(Map<String, dynamic>)? onReservationCheckedIn;
  Function(Map<String, dynamic>)? onReservationCheckedOut;
  Function()? onDataChanged; // Generic callback to trigger UI refresh

  bool get isConnected => _isConnected;

  /// Connect to socket server and join GRO room
  void connect() {
    if (_socket != null && _isConnected) {
      debugPrint('📡 GRO Socket: Already connected');
      return;
    }

    debugPrint('📡 GRO Socket: Connecting to $baseUrl');

    try {
      _socket = IO.io(baseUrl, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 10,
        'reconnectionDelay': 1000,
        'timeout': 30000,
        'forceNew': true, // ✅ Match SocketService configuration
      });

      _setupListeners();
      
    } catch (e) {
      debugPrint('❌ GRO Socket: Connection error: $e');
    }
  }

  void _setupListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      debugPrint('✅ GRO Socket: Connected with ID: ${_socket!.id}');
      _isConnected = true;
      
      // Join GRO room for receiving updates
      _socket!.emit('join_gro_room', {
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      debugPrint('🔌 GRO Socket: Disconnected');
      _isConnected = false;
      notifyListeners();
    });

    _socket!.onConnectError((error) {
      debugPrint('❌ GRO Socket: Connection error: $error');
      _isConnected = false;
    });

    // ✅ ORDER STATUS UPDATED - Real-time order status changes
    _socket!.on('order_status_updated', (data) {
      debugPrint('📦 GRO Socket: order_status_updated received');
      try {
        if (data != null && data is Map) {
          final orderData = Map<String, dynamic>.from(data);
          debugPrint('   Order: ${orderData['order_id']} -> ${orderData['status']}');
          
          onOrderStatusUpdated?.call(orderData);
          onDataChanged?.call();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('❌ GRO Socket: Error processing order_status_updated: $e');
      }
    });

    // ✅ TABLE STATUS UPDATED - Real-time table availability changes
    _socket!.on('table_status_updated', (data) {
      debugPrint('🪑 GRO Socket: table_status_updated received');
      try {
        if (data != null && data is Map) {
          final tableData = Map<String, dynamic>.from(data);
          debugPrint('   Tables: ${tableData['tables']} -> ${tableData['newStatus']}');
          
          onTableStatusUpdated?.call(tableData);
          onDataChanged?.call();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('❌ GRO Socket: Error processing table_status_updated: $e');
      }
    });

    // ✅ RESERVATION CANCELLED - Real-time cancellation
    _socket!.on('reservation_cancelled', (data) {
      debugPrint('❌ GRO Socket: reservation_cancelled received');
      try {
        if (data != null && data is Map) {
          final cancelData = Map<String, dynamic>.from(data);
          debugPrint('   Cancelled by: ${cancelData['cancelledBy']}');
          
          onReservationCancelled?.call(cancelData);
          onDataChanged?.call();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('❌ GRO Socket: Error processing reservation_cancelled: $e');
      }
    });

    // ✅ RESERVATION CONFIRMED
    _socket!.on('reservation_confirmed', (data) {
      debugPrint('✅ GRO Socket: reservation_confirmed received');
      try {
        if (data != null && data is Map) {
          final confirmData = Map<String, dynamic>.from(data);
          
          onReservationConfirmed?.call(confirmData);
          onDataChanged?.call();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('❌ GRO Socket: Error processing reservation_confirmed: $e');
      }
    });

    // ✅ RESERVATION CHECKED IN
    _socket!.on('reservation_checked_in', (data) {
      debugPrint('📍 GRO Socket: reservation_checked_in received');
      try {
        if (data != null && data is Map) {
          final checkInData = Map<String, dynamic>.from(data);
          
          onReservationCheckedIn?.call(checkInData);
          onDataChanged?.call();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('❌ GRO Socket: Error processing reservation_checked_in: $e');
      }
    });

    // ✅ RESERVATION CHECKED OUT
    _socket!.on('reservation_checked_out', (data) {
      debugPrint('🚪 GRO Socket: reservation_checked_out received');
      try {
        if (data != null && data is Map) {
          final checkOutData = Map<String, dynamic>.from(data);
          
          onReservationCheckedOut?.call(checkOutData);
          onDataChanged?.call();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('❌ GRO Socket: Error processing reservation_checked_out: $e');
      }
    });

    // Server ping handler
    _socket!.on('ping', (data) {
      _socket!.emit('pong', {
        'message': 'Pong from GRO client',
        'timestamp': DateTime.now().toIso8601String()
      });
    });
  }

  /// Disconnect from socket server
  void disconnect() {
    if (_socket != null) {
      debugPrint('📡 GRO Socket: Disconnecting...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Clear all callbacks
  void clearCallbacks() {
    onOrderStatusUpdated = null;
    onTableStatusUpdated = null;
    onReservationCancelled = null;
    onReservationConfirmed = null;
    onReservationCheckedIn = null;
    onReservationCheckedOut = null;
    onDataChanged = null;
  }

  @override
  void dispose() {
    clearCallbacks();
    disconnect();
    super.dispose();
  }
}
