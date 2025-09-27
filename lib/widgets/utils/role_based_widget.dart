import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'navigation_bar.dart';

/// Widget yang menampilkan konten berdasarkan role pengguna
class RoleBasedWidget extends StatelessWidget {
  final Widget? customerChild;
  final Widget? marketingChild;
  final Widget? jroChild;        // Add JRO child
  final Widget? adminChild;
  final Widget? fallbackChild;
  final List<String>? allowedRoles;
  final List<String>? requiredPermissions;

  const RoleBasedWidget({
    super.key,
    this.customerChild,
    this.marketingChild,
    this.jroChild,                // Add JRO child parameter
    this.adminChild,
    this.fallbackChild,
    this.allowedRoles,
    this.requiredPermissions,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // Check by specific roles first
        if (allowedRoles != null) {
          final userRole = authService.getUserRole();
          if (userRole != null && allowedRoles!.contains(userRole)) {
            return _getWidgetForRole(authService) ?? _fallback();
          }
          return _fallback();
        }

        // Check by permissions
        if (requiredPermissions != null) {
          final hasAllPermissions = requiredPermissions!.every(
                (permission) => authService.hasPermission(permission),
          );
          if (hasAllPermissions) {
            return _getWidgetForRole(authService) ?? _fallback();
          }
          return _fallback();
        }

        // Default role-based rendering
        return _getWidgetForRole(authService) ?? _fallback();
      },
    );
  }

  Widget? _getWidgetForRole(AuthService authService) {
    if (authService.isCustomer() && customerChild != null) {
      return customerChild;
    } else if (authService.isMarketing() && marketingChild != null) {
      return marketingChild;
    } else if (authService.isJro() && jroChild != null) {      // Add JRO check
      return jroChild;
    } else if (authService.isAdmin() && adminChild != null) {
      return adminChild;
    }
    return null;
  }

  Widget _fallback() {
    return fallbackChild ?? const SizedBox.shrink();
  }
}

/// Widget yang hanya menampilkan konten jika user memiliki role tertentu
class ShowForRole extends StatelessWidget {
  final List<String> roles;
  final Widget child;
  final Widget? fallback;

  const ShowForRole({
    super.key,
    required this.roles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final userRole = authService.getUserRole();
        if (userRole != null && roles.contains(userRole)) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Widget yang hanya menampilkan konten jika user memiliki permission tertentu
class ShowForPermission extends StatelessWidget {
  final List<String> permissions;
  final Widget child;
  final Widget? fallback;
  final bool requireAll; // true = butuh semua permission, false = butuh salah satu

  const ShowForPermission({
    super.key,
    required this.permissions,
    required this.child,
    this.fallback,
    this.requireAll = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final userPermissions = authService.getUserPermissions();

        bool hasAccess;
        if (requireAll) {
          hasAccess = permissions.every(
                (permission) => userPermissions.contains(permission),
          );
        } else {
          hasAccess = permissions.any(
                (permission) => userPermissions.contains(permission),
          );
        }

        if (hasAccess) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Widget yang menyembunyikan konten dari role tertentu
class HideFromRole extends StatelessWidget {
  final List<String> roles;
  final Widget child;

  const HideFromRole({
    super.key,
    required this.roles,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final userRole = authService.getUserRole();
        if (userRole != null && roles.contains(userRole)) {
          return const SizedBox.shrink();
        }
        return child;
      },
    );
  }
}

/// Widget untuk menampilkan informasi user
class UserInfoWidget extends StatelessWidget {
  final bool showRole;
  final bool showPermissions;
  final bool showOutlets;

  const UserInfoWidget({
    super.key,
    this.showRole = true,
    this.showPermissions = false,
    this.showOutlets = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final user = authService.user;
        if (user == null) {
          return const Text('User not logged in');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // User Name
            Text(
              authService.getUserDisplayName(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Role
            if (showRole) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleColor(authService.getUserRole()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getRoleDisplayName(authService.getUserRole()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            // Permissions
            if (showPermissions) ...[
              const SizedBox(height: 8),
              const Text(
                'Permissions:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: authService.getUserPermissions().map((permission) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      permission,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Outlets
            if (showOutlets) ...[
              const SizedBox(height: 8),
              const Text(
                'Outlets:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              ...authService.getUserOutlets().map((outlet) {
                return Text(
                  'Outlet ID: ${outlet['outletId']}',
                  style: const TextStyle(fontSize: 12),
                );
              }),
            ],
          ],
        );
      },
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'customer':
        return Colors.blue;
      case 'marketing':
        return Colors.purple;
      case 'admin':
      case 'superadmin':
        return Colors.red;
      case 'staff':
        return Colors.green;
      case 'cashier junior':
      case 'cashier senior':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'customer':
        return 'Customer';
      case 'marketing':
        return 'Marketing';
      case 'admin':
        return 'Admin';
      case 'superadmin':
        return 'Super Admin';
      case 'staff':
        return 'Staff';
      case 'cashier junior':
        return 'Cashier Junior';
      case 'cashier senior':
        return 'Cashier Senior';
      default:
        return role ?? 'Unknown';
    }
  }
}

// Mixin untuk memudahkan akses role checking di StatefulWidget
mixin RoleCheckMixin<T extends StatefulWidget> on State<T> {
  AuthService get authService => Provider.of<AuthService>(context, listen: false);

  bool get isCustomer => authService.isCustomer();
  bool get isMarketing => authService.isMarketing();
  bool get isJro => authService.isJro();           // Add JRO mixin
  bool get isAdmin => authService.isAdmin();

  String? get userRole => authService.getUserRole();
  List<String> get userPermissions => authService.getUserPermissions();

  bool hasRole(String role) => authService.getUserRole() == role;
  bool hasAnyRole(List<String> roles) => roles.contains(authService.getUserRole());
  bool hasPermission(String permission) => authService.hasPermission(permission);
  bool hasAnyPermission(List<String> permissions) =>
      permissions.any((permission) => authService.hasPermission(permission));
  bool hasAllPermissions(List<String> permissions) =>
      permissions.every((permission) => authService.hasPermission(permission));

  // Add management capabilities
  bool get canManageReservations => authService.canManageReservations();
  bool get canManageTables => authService.canManageTables();
  bool get canViewReports => authService.canViewReports();
}

// Extension untuk memudahkan role checking di BuildContext
extension RoleCheckExtension on BuildContext {
  AuthService get authService => Provider.of<AuthService>(this, listen: false);

  bool get isCustomer => authService.isCustomer();
  bool get isMarketing => authService.isMarketing();
  bool get isJro => authService.isJro();           // Add JRO extension
  bool get isAdmin => authService.isAdmin();

  String? get userRole => authService.getUserRole();
  List<String> get userPermissions => authService.getUserPermissions();

  bool hasRole(String role) => authService.getUserRole() == role;
  bool hasAnyRole(List<String> roles) => roles.contains(authService.getUserRole());
  bool hasPermission(String permission) => authService.hasPermission(permission);
  bool hasAnyPermission(List<String> permissions) =>
      permissions.any((permission) => authService.hasPermission(permission));
  bool hasAllPermissions(List<String> permissions) =>
      permissions.every((permission) => authService.hasPermission(permission));

  // Add reservation and table management permissions
  bool get canManageReservations => authService.canManageReservations();
  bool get canManageTables => authService.canManageTables();
  bool get canViewReports => authService.canViewReports();
}


/// Custom AppBar yang berubah berdasarkan role
class RoleBasedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const RoleBasedAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        Color backgroundColor;
        Color foregroundColor;

        // Set colors based on role
        if (authService.isMarketing()) {
          backgroundColor = const Color(0xFF6366F1);
          foregroundColor = Colors.white;
        } else if (authService.isAdmin()) {
          backgroundColor = const Color(0xFFDC2626);
          foregroundColor = Colors.white;
        } else {
          backgroundColor = Colors.white;
          foregroundColor = Colors.black87;
        }

        return AppBar(
          title: Text(
            title ?? _getDefaultTitle(authService),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: foregroundColor,
            ),
          ),
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: automaticallyImplyLeading,
          leading: leading,
          actions: [
            // Role-based actions
            if (authService.isMarketing()) ...[
              IconButton(
                onPressed: () {
                  // Marketing specific action
                },
                icon: const Icon(Icons.campaign),
                tooltip: 'Marketing Tools',
              ),
            ],
            if (authService.isAdmin()) ...[
              IconButton(
                onPressed: () {
                  // Admin specific action
                },
                icon: const Icon(Icons.admin_panel_settings),
                tooltip: 'Admin Panel',
              ),
            ],
            ...?actions,
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.shade200,
                    Colors.grey.shade100,
                    Colors.grey.shade200,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getDefaultTitle(AuthService authService) {
    if (authService.isMarketing()) {
      return 'Marketing Dashboard';
    } else if (authService.isAdmin()) {
      return 'Admin Panel';
    } else {
      return 'Baraja App';
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}

/// Widget untuk menampilkan pesan jika user tidak memiliki akses
class NoAccessWidget extends StatelessWidget {
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;

  const NoAccessWidget({
    super.key,
    this.message,
    this.icon,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.lock,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              message ?? 'Anda tidak memiliki akses ke halaman ini',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Silahkan hubungi administrator jika Anda merasa ini adalah kesalahan',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Helper function untuk navigasi berdasarkan role
class RoleBasedNavigation {
  static void navigateBasedOnRole(BuildContext context, AuthService authService) {
    if (authService.isMarketing()) {
      // Navigate to marketing specific screen
      Navigator.pushReplacementNamed(context, '/marketing-dashboard');
    } else if (authService.isAdmin()) {
      // Navigate to admin specific screen
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else {
      // Navigate to customer screen
      Navigator.pushReplacementNamed(context, '/customer-home');
    }
  }

  static Widget getInitialRoute(AuthService authService) {
    if (authService.isMarketing()) {
      return const MarketingNavigationBar();
    } else {
      return const CustomerNavigationBar();
    }
  }
}