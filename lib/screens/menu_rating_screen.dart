import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../services/rating_service.dart'; // Import RatingService

class MenuRatingPage extends StatefulWidget {
  final Map<String, dynamic>? orderData;
  final String? menuItemId;
  final String? orderId;
  // final String? outletId;

  const MenuRatingPage({
    super.key,
    required this.orderData,
    this.menuItemId,
    this.orderId,
    // this.outletId,
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

  // Cek apakah user sudah pernah rating untuk order ini
  // Future<void> _checkExistingRating() async {
  //   try {
  //     final menuItemId = widget.menuItemId ?? widget.orderData?['items']?[0]?['menuItemId'];
  //     final orderId = widget.orderId ?? widget.orderData?['orderId'];
  //
  //     if (menuItemId == null || orderId == null) {
  //       setState(() {
  //         isLoading = false;
  //       });
  //       return;
  //     }
  //
  //     final rating = await RatingService.getExistingRating(
  //       menuItemId: menuItemId,
  //       orderId: orderId,
  //     );
  //
  //     if (rating != null) {
  //       setState(() {
  //         existingRating = rating;
  //         selectedRating = existingRating?['rating'] ?? 0;
  //         _reviewController.text = existingRating?['review'] ?? '';
  //       });
  //     }
  //   } catch (e) {
  //     print('Error checking existing rating: $e');
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

// Ganti method _submitRating() dengan versi debug ini:
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

      // final outletId = widget.outletId ??
      //     widget.orderData?['outletId'] ??
      //     widget.orderData?['outlet_id'] ??
      //     widget.orderData?['storeId'];

      // DEBUG: Print extracted values
      print('🔍 Extracted values:');
      print('🔍 menuItemId: $menuItemId');
      print('🔍 orderId: $orderId');
      // print('🔍 outletId: $outletId');
      print('🔍 widget.menuItemId: ${widget.menuItemId}');
      print('🔍 widget.orderId: ${widget.orderId}');
      // print('🔍 widget.outletId: ${widget.outletId}');

      // Coba berbagai kemungkinan field name untuk menuItemId
      String? finalMenuItemId = menuItemId;
      if (finalMenuItemId == null && widget.orderData?['items'] != null && widget.orderData?['items'].isNotEmpty) {
        final firstItem = widget.orderData?['items'][0];
        // Coba berbagai kemungkinan nama field
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

      // Coba berbagai kemungkinan field name untuk outletId
      // String? finalOutletId = outletId;
      // if (finalOutletId == null) {
      //   finalOutletId = widget.orderData?['outletId'] ??
      //       widget.orderData?['outlet_id'] ??
      //       widget.orderData?['storeId'] ??
      //       widget.orderData?['store_id'];
      //   print('🔍 Trying alternative outletId: $finalOutletId');
      // }

      print('🔍 Final values:');
      print('🔍 finalMenuItemId: $finalMenuItemId');
      print('🔍 finalOrderId: $finalOrderId');
      // print('🔍 finalOutletId: $finalOutletId');

      if (finalMenuItemId == null || finalOrderId == null) {
        print('❌ Missing required data:');
        print('❌ finalMenuItemId is null: ${finalMenuItemId == null}');
        print('❌ finalOrderId is null: ${finalOrderId == null}');

        // Show more specific error message
        List<String> missingFields = [];
        if (finalMenuItemId == null) missingFields.add('Menu Item ID');
        if (finalOrderId == null) missingFields.add('Order ID');

        throw Exception('Data tidak lengkap: ${missingFields.join(', ')} tidak ditemukan');
      }

      final result = await RatingService.submitRating(
        menuItemId: finalMenuItemId,
        orderId: finalOrderId,
        // outletId: finalOutletId,
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
        Navigator.of(context).pop(true); // Return true to indicate success
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

// Juga update method _checkExistingRating() untuk debug:
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

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final isSelected = index < selectedRating;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedRating = index + 1;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 42,
              color: isSelected
                  ? Colors.amber
                  : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }

  String _getRatingText() {
    switch (selectedRating) {
      case 1:
        return 'Sangat Kurang';
      case 2:
        return 'Kurang';
      case 3:
        return 'Cukup';
      case 4:
        return 'Baik';
      case 5:
        return 'Sangat Baik';
      default:
        return 'Pilih Rating';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle null orderData
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
    final item = orderData['items']?[0] ?? {};

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
              // Existing Rating Info (if any)
              if (existingRating != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Anda sudah memberikan rating untuk pesanan ini. Anda dapat mengubahnya di bawah.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Order Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Order Number
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.barajaPrimary.primaryColor.withOpacity(0.1),
                            AppTheme.barajaPrimary.primaryColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: AppTheme.barajaPrimary.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_outlined,
                            size: 14,
                            color: AppTheme.barajaPrimary.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            orderData['orderNumber']?.toString() ?? 'N/A',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.barajaPrimary.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Product Info
                    Row(
                      children: [
                        // Product Image
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: (item['imageUrl'] != null &&
                                item['imageUrl'].toString().isNotEmpty &&
                                item['imageUrl'] != 'https://placehold.co/1920x1080/png')
                                ? Image.network(
                              item['imageUrl'].toString(),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/product_default_image.jpeg',
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                                : Image.asset(
                              'assets/images/product_default_image.jpeg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Product Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name']?.toString() ?? 'Produk',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      'x${item['quantity']?.toString() ?? '0'}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      formatCurrency((item['price'] as num?) ?? 0),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.barajaPrimary.primaryColor,
                                        letterSpacing: -0.3,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Rating Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Rating Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.withOpacity(0.15),
                                Colors.amber.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            existingRating != null
                                ? 'Perbarui rating Anda'
                                : 'Bagaimana pengalaman Anda?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: -0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Star Rating
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _buildStarRating(),
                    ),
                    const SizedBox(height: 16),

                    // Rating Text
                    Text(
                      _getRatingText(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: selectedRating > 0
                            ? AppTheme.barajaPrimary.primaryColor
                            : Colors.grey.shade500,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Review Text Field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _reviewController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: '✍️ Ceritakan pengalaman Anda... (opsional)',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(20),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
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