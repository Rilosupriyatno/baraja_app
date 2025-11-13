import 'package:baraja_app/providers/cart_provider.dart';
import 'package:baraja_app/providers/order_provider.dart';
import 'package:baraja_app/routes/app_router.dart';
import 'package:baraja_app/services/auth_service.dart';
import 'package:baraja_app/services/notification_count_service.dart';
import 'package:baraja_app/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'firebase_options.dart';
import 'theme/app_theme.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
  print('Message data: ${message.data}');
  print('Message notification: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Get FCM token
  final fcmToken = await notificationService.getToken();
  print('FCM Token: $fcmToken');

  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';

  final String? baseUrl = dotenv.env['BASE_URL'];
  // Socket IO setup
  IO.Socket socket = IO.io(baseUrl);
  socket.onConnect((_) {
    print('Socket connected');
    socket.emit('msg', 'test');
  });
  socket.on('event', (data) => print(data));
  socket.onDisconnect((_) => print('Socket disconnected'));
  socket.on('fromServer', (_) => print(_));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => OrderProvider()),
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (_) => NotificationCountService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // 🔒 CRITICAL: Setup callbacks setelah build pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupCartProviderCallbacks();
    });
  }

  void _setupCartProviderCallbacks() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // 🔒 Set callbacks di AuthService
    authService.setCartProviderCallbacks(
      onUserLoggedIn: (userId, role) {
        debugPrint('🔐 MyApp: Setting user in CartProvider: $userId as $role');
        cartProvider.setCurrentUser(userId, role);
      },
      onUserLoggedOut: () {
        debugPrint('🔓 MyApp: Clearing user from CartProvider');
        cartProvider.clearCurrentUser();
      },
    );

    debugPrint('✅ CartProvider callbacks setup complete');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      debugShowCheckedModeBanner: false,
      title: 'Coffee Shop App',
      theme: AppTheme.themeData,
      routerConfig: AppRouter.getRouter(),
    );
  }
}
