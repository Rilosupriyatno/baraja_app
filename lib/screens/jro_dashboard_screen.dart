// jro_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/utils/role_based_widget.dart';

class JroDashboardScreen extends StatefulWidget {
  const JroDashboardScreen({super.key});

  @override
  State<JroDashboardScreen> createState() => _JroDashboardScreenState();
}

class _JroDashboardScreenState extends State<JroDashboardScreen> with RoleCheckMixin {
  final Map<String, dynamic> _dashboardStats = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Consumer<AuthService>(
          builder: (context, authService, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard JRO',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Hai, ${authService.getUserDisplayName()}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: const Color(0xFF2E8B57), // Sea green for JRO
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Navigate to notifications
            },
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifikasi',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E8B57), Color(0xFF228B22)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.restaurant_menu,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sistem Manajemen Reservasi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Juru Rawat Operations',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Kelola reservasi, meja, dan operasional restoran dengan efisien',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Stats
              const Text(
                'Statistik Hari Ini',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Stats Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    title: 'Total Reservasi',
                    value: '${_dashboardStats['totalReservations'] ?? 0}',
                    icon: Icons.event_seat,
                    color: const Color(0xFF3B82F6),
                    onTap: () => _navigateToReservations(),
                  ),
                  _buildStatCard(
                    title: 'Menunggu',
                    value: '${_dashboardStats['pendingReservations'] ?? 0}',
                    icon: Icons.schedule,
                    color: const Color(0xFFF59E0B),
                    onTap: () => _navigateToReservations(status: 'pending'),
                  ),
                  _buildStatCard(
                    title: 'Sedang Berlangsung',
                    value: '${_dashboardStats['activeReservations'] ?? 0}',
                    icon: Icons.dining,
                    color: const Color(0xFF10B981),
                    onTap: () => _navigateToReservations(status: 'active'),
                  ),
                  _buildStatCard(
                    title: 'Meja Tersedia',
                    value: '${_dashboardStats['availableTables'] ?? 0}',
                    icon: Icons.table_restaurant,
                    color: const Color(0xFF8B5CF6),
                    onTap: () => _navigateToTableManagement(),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }






  void _navigateToReservations({String? status}) {
    Navigator.pushNamed(
      context,
      '/reservation-management',
      arguments: {'filter': status},
    );
  }

  void _navigateToTableManagement() {
    Navigator.pushNamed(context, '/table-management');
  }

}