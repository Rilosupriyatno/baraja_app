import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

  @override
  QRScannerState createState() => QRScannerState(); // Ubah ke public
}

class QRScannerState extends State<QRScanner> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin { // Ubah nama class ke public
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool isFlashOn = false;
  bool isFrontCamera = false;
  bool isPaused = false;
  bool _isVisible = true;

  @override
  bool get wantKeepAlive => true; // Keep alive karena menggunakan persistent nav bar

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

  // Lifecycle methods untuk handle tab navigation dan app lifecycle
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

  // Method untuk handle visibility dari parent widget
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

  // Method untuk pause kamera saat tab berubah
  void pauseCamera() {
    controller?.pauseCamera();
    setState(() {
      isPaused = true;
    });
  }

  // Method untuk resume kamera saat kembali ke tab ini
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
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
        ],
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
              'Scan QR Code',
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
                        'Scanned Result:',
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
                              onPressed: () {
                                // Copy to clipboard or handle result
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Result copied!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Use Result'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
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
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ],
                  )
                      : const Text(
                    'Point your camera at a QR code',
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
            onPressed: onPressed,
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
      // Menaikkan posisi kotak scanner dengan mengatur top dan menggunakan Align
      top: MediaQuery.of(context).size.height * 0.2, // Kotak akan berada 20% dari atas layar
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
        borderColor: Colors.transparent, // Hide default border
        borderRadius: 12,
        borderLength: 0,
        borderWidth: 0,
        cutOutSize: scanArea,
        // Menaikkan posisi cutout area
        cutOutBottomOffset: MediaQuery.of(context).size.height * 0.1, // Menaikkan area scan
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      if (mounted) {
        setState(() {
          result = scanData;
        });
      }
    });

    // Get initial flash status
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
          content: const Text('Camera permission denied'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleFlash() async {
    await controller?.toggleFlash();
    final status = await controller?.getFlashStatus();
    if (mounted) {
      setState(() {
        isFlashOn = status ?? false;
      });
    }
  }

  void _flipCamera() async {
    await controller?.flipCamera();
    setState(() {
      isFrontCamera = !isFrontCamera;
    });
  }

  void _togglePause() async {
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