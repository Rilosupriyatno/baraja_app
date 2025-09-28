import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/auth_service.dart';
import '../widgets/event/event_card.dart';
import '../widgets/utils/role_based_widget.dart';
import 'event_detail_screen.dart';
import 'ticket_history_screen.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> with RoleCheckMixin {
  final eventService = EventService();
  late Future<List<Event>> _futureEvents;

  @override
  void initState() {
    super.initState();
    _futureEvents = eventService.fetchEvents();
  }

  Future<void> _refreshEvents() async {
    setState(() {
      _futureEvents = eventService.fetchEvents();
    });
  }

  Future<void> _navigateToHistory() async {
    // TODO: Replace with actual user ID from your authentication system
    final prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? ''; // This should come from your user session/auth


    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        TicketHistoryScreen(userId: userId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Consumer<AuthService>(
          builder: (context, authService, _) {
            if (authService.isMarketing()) {
              return const Text("Management Event", style: TextStyle(fontWeight: FontWeight.w600),);
            } else if (authService.isAdmin()) {
              return const Text("Admin Event", style: TextStyle(fontWeight: FontWeight.w600),);
            } else {
              return const Text("Event", style: TextStyle(fontWeight: FontWeight.w600),);
            }
          },
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Show different actions based on role
          RoleBasedWidget(
            customerChild: IconButton(
              onPressed: _navigateToHistory,
              icon: const Icon(Icons.history),
              tooltip: 'Riwayat Tiket',
              splashRadius: 24,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Show different header based on role
          RoleBasedWidget(
            marketingChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF6366F1),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.campaign,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Marketing Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kelola event dan promosi untuk meningkatkan engagement',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            adminChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFDC2626),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kontrol penuh terhadap sistem event dan pengguna',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick stats for Marketing and Admin
          ShowForRole(
            roles: const ['marketing', 'admin', 'superadmin'],
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Event',
                      value: '7',
                      icon: Icons.event,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ShowForPermission(
                    permissions: const ['manage_promo'],
                    child: Expanded(
                      child: _buildStatCard(
                        title: 'Event Aktif',
                        value: '7',
                        icon: Icons.play_circle,
                        color: Colors.green,
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),

          // Events List
          Expanded(
            child: FutureBuilder<List<Event>>(
              future: _futureEvents,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text("Error: ${snapshot.error}"),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshEvents,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Belum ada event",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  );
                }

                final events = snapshot.data!;
                return RefreshIndicator(
                  color: const Color(0xFFD4AF37),
                  onRefresh: _refreshEvents,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Stack(
                          children: [
                            EventCard(
                              event: event,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                        EventDetailScreen(event: event),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      const begin = Offset(1.0, 0.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeInOut;

                                      var tween = Tween(begin: begin, end: end).chain(
                                        CurveTween(curve: curve),
                                      );

                                      return SlideTransition(
                                        position: animation.drive(tween),
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),

                            // Admin/Marketing overlay with quick actions
                            // ShowForRole(
                            //   roles: const ['marketing', 'admin', 'superadmin'],
                            //   child: Positioned(
                            //     top: 8,
                            //     right: 8,
                            //     child: Container(
                            //       decoration: BoxDecoration(
                            //         color: Colors.black.withOpacity(0.7),
                            //         borderRadius: BorderRadius.circular(20),
                            //       ),
                            //       child: PopupMenuButton<String>(
                            //         icon: const Icon(
                            //           Icons.more_horiz,
                            //           color: Colors.white,
                            //           size: 20,
                            //         ),
                            //         color: Colors.white,
                            //         onSelected: (value) {
                            //           switch (value) {
                            //             case 'edit':
                            //               Navigator.pushNamed(
                            //                 context,
                            //                 '/edit-event',
                            //                 arguments: event,
                            //               );
                            //               break;
                            //             case 'duplicate':
                            //             // Duplicate event logic
                            //               break;
                            //             case 'analytics':
                            //               Navigator.pushNamed(
                            //                 context,
                            //                 '/event-analytics',
                            //                 arguments: event,
                            //               );
                            //               break;
                            //             case 'delete':
                            //               _showDeleteDialog(event);
                            //               break;
                            //           }
                            //         },
                            //         itemBuilder: (context) => [
                            //           const PopupMenuItem(
                            //             value: 'edit',
                            //             child: Row(
                            //               children: [
                            //                 Icon(Icons.edit, size: 16),
                            //                 SizedBox(width: 8),
                            //                 Text('Edit'),
                            //               ],
                            //             ),
                            //           ),
                            //           const PopupMenuItem(
                            //             value: 'duplicate',
                            //             child: Row(
                            //               children: [
                            //                 Icon(Icons.copy, size: 16),
                            //                 SizedBox(width: 8),
                            //                 Text('Duplikat'),
                            //               ],
                            //             ),
                            //           ),
                            //           const PopupMenuItem(
                            //             value: 'analytics',
                            //             child: Row(
                            //               children: [
                            //                 Icon(Icons.analytics, size: 16),
                            //                 SizedBox(width: 8),
                            //                 Text('Analitik'),
                            //               ],
                            //             ),
                            //           ),
                            //           const PopupMenuItem(
                            //             value: 'delete',
                            //             child: Row(
                            //               children: [
                            //                 Icon(Icons.delete, size: 16, color: Colors.red),
                            //                 SizedBox(width: 8),
                            //                 Text('Hapus', style: TextStyle(color: Colors.red)),
                            //               ],
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}