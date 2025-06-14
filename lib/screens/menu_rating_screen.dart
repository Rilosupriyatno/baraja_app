import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/rating_service.dart';
import '../widgets/rating/existing_rating_info.dart';
import '../widgets/rating/order_info_card.dart';
import '../widgets/rating/rating_section.dart';

class MenuRatingPage extends StatefulWidget {
  final Map<String, dynamic>? orderData;
  final String? menuItemId;
  final String? orderId;

  const MenuRatingPage({
    super.key,
    required this.orderData,
    this.menuItemId,
    this.orderId,
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

      final orderId = widget.orderId ??
          widget.orderData?['orderId'] ??
          widget.orderData?['id'] ??
          widget.orderData?['_id'];

      // DEBUG: Print extracted values
      print('🔍 Extracted values:');
      print('🔍 menuItemId: $menuItemId');
      print('🔍 orderId: $orderId');
      print('🔍 widget.menuItemId: ${widget.menuItemId}');
      print('🔍 widget.orderId: ${widget.orderId}');

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

      // Coba berbagai kemungkinan field name untuk orderId
      String? finalOrderId = orderId;
      if (finalOrderId == null) {
        finalOrderId = widget.orderData?['orderId'] ??
            widget.orderData?['order_id'] ??
            widget.orderData?['id'] ??
            widget.orderData?['orderNumber'];
        print('🔍 Trying alternative orderId: $finalOrderId');
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
        orderId: finalOrderId,
        rating: selectedRating,
        review: _reviewController.text.trim(),
        existingRating: existingRating,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingRating != null
                ? 'Rating berhasil diperbarui. Terima kasih!'
                : 'Rating berhasil dikirim. Terima kasih!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
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
      print('🔍 widget.orderId: ${widget.orderId}');
      print('🔍 orderData items: ${widget.orderData?['items']}');

      final menuItemId = widget.menuItemId ?? widget.orderData?['items']?[0]?['menuItemId'];
      final orderId = widget.orderId ?? widget.orderData?['orderId'];

      print('🔍 Extracted in _checkExistingRating:');
      print('🔍 menuItemId: $menuItemId');
      print('🔍 orderId: $orderId');

      if (menuItemId == null || orderId == null) {
        print('❌ Cannot check existing rating - missing data');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final rating = await RatingService.getExistingRating(
        menuItemId: menuItemId,
        orderId: orderId,
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