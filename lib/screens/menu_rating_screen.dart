import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/rating_service.dart';
import '../widgets/rating/existing_rating_info.dart';
import '../widgets/rating/order_info_card.dart';
import '../widgets/rating/rating_section.dart';

class MenuRatingPage extends StatefulWidget {
  final Map<String, dynamic>? orderData;
  final String? menuItemId;
  final String? id;

  const MenuRatingPage({
    super.key,
    required this.orderData,
    this.menuItemId,
    this.id,
  });

  @override
  State<MenuRatingPage> createState() => _MenuRatingPageState();
}

class _MenuRatingPageState extends State<MenuRatingPage> {
  int selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool isSubmitting = false;
  bool isLoading = true;
  Map<String, dynamic>? existingRating;

  // Google Place ID
  static const String googlePlaceId = 'ChIJ7Sa1NADjbi4R3L5OBuXuuJ4';
  // URL Google Maps untuk tempat Anda
  static const String googleMapsUrl = 'https://www.google.com/maps/place/Baraja+Coffee+Amphitheater/@-6.7104235,108.5357765,17z/data=!3m1!4b1!4m6!3m5!1s0x2e6ee30034b526ed:0x9eb8eee5064ebedc!8m2!3d-6.7104288!4d108.5383514!16s%2Fg%2F11y2hk0g0l?entry=ttu&g_ep=EgoyMDI1MTAwMS4wIKXMDSoASAFQAw%3D%3D';

  @override
  void initState() {
    super.initState();
    _checkExistingRating();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _showGoogleReviewDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppTheme.barajaPrimary.primaryColor.withOpacity(0.02),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.barajaPrimary.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    size: 48,
                    color: AppTheme.barajaPrimary.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Terima Kasih! 🎉',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'Rating Anda sangat berarti bagi kami. Mau bantu kami lebih lagi dengan memberi rating di Google?',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Buttons
                Column(
                  children: [
                    // Yes Button
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.barajaPrimary.primaryColor,
                            AppTheme.barajaPrimary.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.barajaPrimary.primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openGoogleReview();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/google.png', // Anda perlu menambahkan icon Google
                              width: 20,
                              height: 20,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.open_in_new,
                                  color: Colors.white,
                                  size: 20,
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Beri Rating di Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // No Button
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(true);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Lain kali saja',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openGoogleReview() async {
    // List of URL alternatives to try - URUTAN PENTING!
    final urls = [
      // URL 1: Direct link ke halaman Google Maps (akan buka di section reviews)
      googleMapsUrl,

      // URL 2: Google Maps dengan Place ID - Buka halaman place
      'https://www.google.com/maps/search/?api=1&query=Baraja%20Coffee%20Amphitheater&query_place_id=$googlePlaceId',

      // URL 3: Simple Google Maps link
      'https://maps.google.com/?q=Baraja+Coffee+Amphitheater',

      // URL 4: Geo URI untuk fallback
      'geo:-6.7104288,108.5383514?q=Baraja+Coffee+Amphitheater',
    ];

    bool success = false;
    String? errorMessage;

    for (String url in urls) {
      try {
        print('🔗 Trying URL: $url');
        final uri = Uri.parse(url);

        // Coba launch dengan mode yang berbeda
        try {
          // Try 1: platformDefault - biarkan sistem yang tentukan
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );

          if (launched) {
            print('✅ Successfully launched with platformDefault: $url');
            success = true;

            if (mounted) {
              await Future.delayed(const Duration(milliseconds: 500));
              Navigator.of(context).pop(true);
            }
            break;
          }
        } catch (e1) {
          print('⚠️ platformDefault failed, trying externalApplication: $e1');

          // Try 2: externalApplication
          try {
            final launched = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );

            if (launched) {
              print('✅ Successfully launched with externalApplication: $url');
              success = true;

              if (mounted) {
                await Future.delayed(const Duration(milliseconds: 500));
                Navigator.of(context).pop(true);
              }
              break;
            }
          } catch (e2) {
            print('⚠️ externalApplication failed, trying inAppWebView: $e2');

            // Try 3: inAppWebView sebagai fallback terakhir
            try {
              final launched = await launchUrl(
                uri,
                mode: LaunchMode.inAppWebView,
              );

              if (launched) {
                print('✅ Successfully launched with inAppWebView: $url');
                success = true;

                if (mounted) {
                  await Future.delayed(const Duration(milliseconds: 500));
                  Navigator.of(context).pop(true);
                }
                break;
              }
            } catch (e3) {
              errorMessage = 'All launch modes failed: $e3';
              print('❌ All launch modes failed for $url: $e3');
            }
          }
        }
      } catch (e) {
        errorMessage = e.toString();
        print('❌ Failed to launch $url: $e');
        continue;
      }
    }

    if (!success && mounted) {
      print('❌ All URLs failed. Last error: $errorMessage');

      // Show error message in SnackBar untuk debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat membuka Google Maps\nError: $errorMessage'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );

      // Jika semua URL gagal, tampilkan dialog alternatif
      await Future.delayed(const Duration(milliseconds: 500));
      _showManualGoogleReviewDialog();
    }
  }

  Future<void> _showManualGoogleReviewDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Buka Google Maps',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Untuk memberi rating di Google, silakan:',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              const Text(
                '1. Buka aplikasi Google Maps\n2. Cari "Baraja Coffee"\n3. Scroll ke bawah\n4. Tap "Write a review"',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Atau cari tempat kami di Google Maps',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitRating() async {
    if (selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih rating terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // DEBUG: Print semua data yang ada
      print('🔍 DEBUG orderData structure:');
      print('🔍 orderData keys: ${widget.orderData?.keys}');
      print('🔍 orderData: ${widget.orderData}');

      // Debug items array
      print('🔍 items array: ${widget.orderData?['items']}');
      if (widget.orderData?['items'] != null) {
        print('🔍 items length: ${widget.orderData?['items'].length}');
        if (widget.orderData?['items'].isNotEmpty) {
          print('🔍 first item: ${widget.orderData?['items'][0]}');
          print('🔍 first item keys: ${widget.orderData?['items'][0]?.keys}');
        }
      }

      // Coba berbagai kemungkinan field name berdasarkan tracking screen
      final menuItemId = widget.menuItemId ??
          widget.orderData?['items']?[0]?['menuItemId'] ??
          widget.orderData?['items']?[0]?['id'] ??
          widget.orderData?['items']?[0]?['itemId'];

      final id = widget.id ??
          widget.orderData?['id'] ??
          widget.orderData?['id'] ??
          widget.orderData?['_id'];

      // DEBUG: Print extracted values
      print('🔍 Extracted values:');
      print('🔍 menuItemId: $menuItemId');
      print('🔍 id: $id');
      print('🔍 widget.menuItemId: ${widget.menuItemId}');
      print('🔍 widget.id: ${widget.id}');

      // Coba berbagai kemungkinan field name untuk menuItemId
      String? finalMenuItemId = menuItemId;
      if (finalMenuItemId == null && widget.orderData?['items'] != null && widget.orderData?['items'].isNotEmpty) {
        final firstItem = widget.orderData?['items'][0];
        finalMenuItemId = firstItem?['menuItemId'] ??
            firstItem?['menu_item_id'] ??
            firstItem?['itemId'] ??
            firstItem?['item_id'] ??
            firstItem?['id'];
        print('🔍 Trying alternative menuItemId: $finalMenuItemId');
      }

      // Coba berbagai kemungkinan field name untuk id
      String? finalOrderId = id;
      if (finalOrderId == null) {
        finalOrderId = widget.orderData?['id'] ??
            widget.orderData?['order_id'] ??
            widget.orderData?['id'] ??
            widget.orderData?['orderNumber'];
        print('🔍 Trying alternative id: $finalOrderId');
      }

      print('🔍 Final values:');
      print('🔍 finalMenuItemId: $finalMenuItemId');
      print('🔍 finalOrderId: $finalOrderId');

      if (finalMenuItemId == null || finalOrderId == null) {
        print('❌ Missing required data:');
        print('❌ finalMenuItemId is null: ${finalMenuItemId == null}');
        print('❌ finalOrderId is null: ${finalOrderId == null}');

        List<String> missingFields = [];
        if (finalMenuItemId == null) missingFields.add('Menu Item ID');
        if (finalOrderId == null) missingFields.add('Order ID');

        throw Exception('Data tidak lengkap: ${missingFields.join(', ')} tidak ditemukan');
      }

      final result = await RatingService.submitRating(
        menuItemId: finalMenuItemId,
        id: finalOrderId,
        rating: selectedRating,
        review: _reviewController.text.trim(),
        existingRating: existingRating,
      );

      if (result['success']) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingRating != null
                ? 'Rating berhasil diperbarui. Terima kasih!'
                : 'Rating berhasil dikirim. Terima kasih!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Wait for snackbar to show, then show Google Review dialog
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          await _showGoogleReviewDialog();
        }
      } else {
        throw Exception(result['message'] ?? 'Gagal mengirim rating');
      }
    } catch (e) {
      print('❌ Error in _submitRating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  Future<void> _checkExistingRating() async {
    try {
      print('🔍 DEBUG _checkExistingRating:');
      print('🔍 widget.menuItemId: ${widget.menuItemId}');
      print('🔍 widget.id: ${widget.id}');
      print('🔍 orderData items: ${widget.orderData?['items']}');

      final menuItemId = widget.menuItemId ?? widget.orderData?['items']?[0]?['menuItemId'];
      final id = widget.id ?? widget.orderData?['id'];

      print('🔍 Extracted in _checkExistingRating:');
      print('🔍 menuItemId: $menuItemId');
      print('🔍 id: $id');

      if (menuItemId == null || id == null) {
        print('❌ Cannot check existing rating - missing data');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final rating = await RatingService.getExistingRating(
        menuItemId: menuItemId,
        id: id,
      );

      if (rating != null) {
        setState(() {
          existingRating = rating;
          selectedRating = existingRating?['rating'] ?? 0;
          _reviewController.text = existingRating?['review'] ?? '';
        });
      }
    } catch (e) {
      print('Error checking existing rating: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onRatingChanged(int rating) {
    setState(() {
      selectedRating = rating;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orderData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Beri Rating'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Data order tidak tersedia',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Beri Rating'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final orderData = widget.orderData!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: AppTheme.barajaPrimary.primaryColor,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          existingRating != null ? 'Edit Rating' : 'Beri Rating',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Existing Rating Info
              if (existingRating != null)
                const ExistingRatingInfo(),

              // Order Info Card
              OrderInfoCard(orderData: orderData),

              const SizedBox(height: 32),

              // Rating Section
              RatingSection(
                selectedRating: selectedRating,
                reviewController: _reviewController,
                existingRating: existingRating,
                onRatingChanged: _onRatingChanged,
              ),

              const SizedBox(height: 32),

              // Submit Button
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.barajaPrimary.primaryColor,
                      AppTheme.barajaPrimary.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.barajaPrimary.primaryColor.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.5,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        existingRating != null ? 'Perbarui Rating' : 'Kirim Rating',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Skip Button
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: Text(
                  'Lewati untuk sekarang',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}