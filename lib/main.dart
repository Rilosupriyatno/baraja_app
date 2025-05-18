
import 'package:baraja_app/providers/cart_provider.dart';
import 'package:baraja_app/providers/order_provider.dart';
import 'package:baraja_app/routes/app_router.dart';
import 'package:baraja_app/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'firebase_options.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final String? baseUrl = dotenv.env['BASE_URL'];
  // Dart client
  IO.Socket socket = IO.io(baseUrl);
  socket.onConnect((_) {
    print('connect');
    socket.emit('msg', 'test');
  });
  socket.on('event', (data) => print(data));
  socket.onDisconnect((_) => print('disconnect'));
  socket.on('fromServer', (_) => print(_));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => OrderProvider()),
        ChangeNotifierProvider(create: (context) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override

  // Widget build(BuildContext context) {
  //   return AdaptiveTheme(
  //     light: ThemeData.light(useMaterial3: true),
  //     dark: ThemeData.dark(useMaterial3: true),
  //     initial: AdaptiveThemeMode.dark,
  //     builder: (light, dark) => MaterialApp.router(
  //       debugShowCheckedModeBanner: false,
  //       title: 'Baraja App',
  //       theme: light,
  //       darkTheme: dark,
  //       routerConfig: AppRouter.getRouter(),
  //     ),
  //   );
  // }
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Coffee Shop App',
      theme: AppTheme.themeData,
      routerConfig: AppRouter.getRouter(),
    );
  }
}
