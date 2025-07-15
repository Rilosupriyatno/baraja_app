import 'dart:developer';
import 'dart:io';
import 'package:baraja_app/utils/base_screen_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
// Import Menu Screen
import 'menu_screen.dart'; // Sesuaikan dengan path yang benar

class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

  @override
  QRScannerState createState() => QRScannerState();
}

class QRScannerState extends State<QRScanner> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool isFlashOn = false;
  bool isFrontCamera = false;
  bool isPaused = false;
  bool _isVisible = true;
  bool _isProcessingResult = false; // Flag untuk mencegah multiple navigation

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      controller!.pauseCamera();
      setState(() {
        isPaused = true;
      });
    } else if (state == AppLifecycleState.resumed && _isVisible) {
      controller!.resumeCamera();
      setState(() {
        isPaused = false;
      });
    }
  }

  void setVisibility(bool visible) {
    if (!mounted) return;

    _isVisible = visible;
    if (controller != null) {
      if (visible) {
        controller!.resumeCamera();
        setState(() {
          isPaused = false;
        });
      } else {
        controller!.pauseCamera();
        setState(() {
          isPaused = true;
        });
      }
    }
  }

  void pauseCamera() {
    controller?.pauseCamera();
    setState(() {
      isPaused = true;
    });
  }

  void resumeCamera() {
    controller?.resumeCamera();
    setState(() {
      isPaused = false;
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  // Fungsi untuk memproses hasil QR dan navigasi ke Menu
  void _processQRResult(String qrData) {
    if (_isProcessingResult) return; // Mencegah multiple processing

    setState(() {
      _isProcessingResult = true;
    });

    // Parse QR data - asumsi format QR adalah table number (contoh: "A01", "B02", dll)
    String tableNumber = qrData.toUpperCase().trim();

    // Validasi format table number (opsional)
    if (_isValidTableNumber(tableNumber)) {
      // Pause camera sebelum navigasi
      controller?.pauseCamera();

      // Navigasi ke Menu Screen dengan parameter
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MenuScreen(
            isReservation: false, // Tidak dari reservasi
            isDineIn: true,       // Dine in karena scan QR di meja
            tableNumber: tableNumber,
          ),
        ),
      );
    } else {
      // Reset processing flag jika QR tidak valid
      setState(() {
        _isProcessingResult = false;
      });

      // Tampilkan error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR Code tidak valid: $qrData'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      // Clear result untuk scan ulang
      setState(() {
        result = null;
      });
    }
  }

  bool _isValidTableNumber(String tableNumber) {
    String cleanTableNumber = tableNumber.trim().toUpperCase();

    // Berbagai pattern yang umum digunakan:
    List<RegExp> validPatterns = [
      RegExp(r'^[A-Z]\d{1,3}$'),        // A1, A01, A123
      RegExp(r'^[A-Z]{1,2}\d{1,3}$'),   // A1, AB1, AB123
      RegExp(r'^\d{1,4}$'),             // 1, 01, 123, 1234
      RegExp(r'^TABLE\d{1,3}$'),        // TABLE1, TABLE01
      RegExp(r'^T\d{1,3}$'),            // T1, T01, T123
      RegExp(r'^MEJA\d{1,3}$'),         // MEJA1, MEJA01
    ];

    return validPatterns.any((pattern) => pattern.hasMatch(cleanTableNumber));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BaseScreenWrapper(
      customBackRoute: '/main',
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // QR Scanner View
            _buildQrView(context),

            // Top overlay with title and close button
            _buildTopOverlay(),

            // Bottom overlay with controls and result
            _buildBottomOverlay(),

            // Scan line animation (optional)
            if (!isPaused) _buildScanLine(),

            // Processing overlay
            if (_isProcessingResult)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Memproses QR Code...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Scan QR Meja',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Result display
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: result != null
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QR Code Terdeteksi:',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result!.code ?? 'No data',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isProcessingResult ? null : () {
                                _processQRResult(result!.code ?? '');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Buka Menu'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isProcessingResult ? null : () {
                              setState(() {
                                result = null;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Scan Ulang'),
                          ),
                        ],
                      ),
                    ],
                  )
                      : const Text(
                    'Arahkan kamera ke QR Code meja Anda',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
                      label: 'Flash',
                      onPressed: _toggleFlash,
                    ),
                    _buildControlButton(
                      icon: Icons.flip_camera_ios,
                      label: 'Flip',
                      onPressed: _flipCamera,
                    ),
                    _buildControlButton(
                      icon: isPaused ? Icons.play_arrow : Icons.pause,
                      label: isPaused ? 'Resume' : 'Pause',
                      onPressed: _togglePause,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: _isProcessingResult ? null : onPressed,
            icon: Icon(icon, color: Colors.white, size: 24),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildScanLine() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.2,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Corner decorations
              Positioned(
                top: -2,
                left: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                left: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = MediaQuery.of(context).size.width * 0.8;

    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.transparent,
        borderRadius: 12,
        borderLength: 0,
        borderWidth: 0,
        cutOutSize: scanArea,
        cutOutBottomOffset: MediaQuery.of(context).size.height * 0.1,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      if (mounted && !_isProcessingResult) {
        setState(() {
          result = scanData;
        });

        // Auto-process QR result setelah 1 detik
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && result != null && !_isProcessingResult) {
            _processQRResult(result!.code ?? '');
          }
        });
      }
    });

    controller.getFlashStatus().then((status) {
      if (mounted) {
        setState(() {
          isFlashOn = status!;
        });
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Izin kamera ditolak'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleFlash() async {
    if (_isProcessingResult) return;
    await controller?.toggleFlash();
    final status = await controller?.getFlashStatus();
    if (mounted) {
      setState(() {
        isFlashOn = status ?? false;
      });
    }
  }

  void _flipCamera() async {
    if (_isProcessingResult) return;
    await controller?.flipCamera();
    setState(() {
      isFrontCamera = !isFrontCamera;
    });
  }

  void _togglePause() async {
    if (_isProcessingResult) return;
    if (isPaused) {
      await controller?.resumeCamera();
    } else {
      await controller?.pauseCamera();
    }
    setState(() {
      isPaused = !isPaused;
    });
  }
}