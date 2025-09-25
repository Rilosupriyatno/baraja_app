import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/event_model.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  // Gold & Silver colors
  Color get _goldColor => const Color(0xFFD4AF37);
  Color get _goldBackgroundColor => const Color(0xFFFFF8E1);
  Color get _silverColor => const Color(0xFF8E8E93);
  Color get _silverBackgroundColor => const Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    final isFree = widget.event.price == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade300, Colors.grey.shade200],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: widget.event.imageUrl.isNotEmpty
                      ? Image.network(
                    widget.event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                      : _placeholder(),
                ),
                // Gradient overlay
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
            // Content Card
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 28, 24, isFree ? 100 : 180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.event.name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isFree ? _silverBackgroundColor : _goldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isFree ? _silverColor.withOpacity(0.3) : _goldColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              isFree ? 'GRATIS' : 'Rp ${NumberFormat('#,###', 'id_ID').format(widget.event.price)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isFree ? _silverColor : _goldColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Quick Info Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickInfoCard(
                              FontAwesomeIcons.calendar,
                              'Tanggal',
                              DateFormat('d MMM yyyy', 'id_ID').format(widget.event.date),
                              const Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickInfoCard(
                              FontAwesomeIcons.clock,
                              'Waktu',
                              DateFormat('HH:mm', 'id_ID').format(widget.event.date),
                              const Color(0xFF2196F3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Details Section
                      _buildSectionTitle('Detail Event'),
                      const SizedBox(height: 16),
                      _buildDetailRow(FontAwesomeIcons.locationDot, 'Lokasi', widget.event.location),
                      _buildDetailRow(FontAwesomeIcons.user, 'Penyelenggara', widget.event.organizer),
                      _buildDetailRow(FontAwesomeIcons.envelope, 'Kontak', widget.event.contactEmail),
                      _buildDetailRow(FontAwesomeIcons.users, 'Kapasitas', '${widget.event.capacity} orang'),
                      _buildDetailRow(FontAwesomeIcons.tag, 'Kategori', widget.event.category),

                      const SizedBox(height: 28),
                      _buildSectionTitle('Deskripsi'),
                      const SizedBox(height: 12),
                      _buildDescription(widget.event.description),

                      // Conditionally show Terms & Conditions only for paid events
                      if (!isFree) ...[
                        const SizedBox(height: 28),
                        _buildSectionTitle('Syarat & Ketentuan'),
                        const SizedBox(height: 12),
                        _buildDescription(widget.event.terms),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Floating Action Button (Buy Ticket) - Updated to navigate to payment method selection
      floatingActionButton: !isFree
          ? Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: ElevatedButton(
          onPressed: _handleBuyTicket,
          style: ElevatedButton.styleFrom(
            backgroundColor: _goldColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: _goldColor.withOpacity(0.3),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart, size: 20),
              SizedBox(width: 8),
              Text(
                'Beli Tiket',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

// Update the _handleBuyTicket method in your EventDetailScreen

  void _handleBuyTicket() {
    // Navigate to payment method screen with event context
    context.push('/paymentMethod', extra: {
      'source': 'event', // This tells the payment method screen where it came from
      'eventData': {
        'id': widget.event.id,
        'name': widget.event.name,
        'price': widget.event.price,
        'date': widget.event.date.toIso8601String(),
        'location': widget.event.location,
        'organizer': widget.event.organizer,
        'category': widget.event.category,
      }
    });
  }

  // Helper widgets (unchanged from original)
  Widget _placeholder() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.grey.shade300, Colors.grey.shade200],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: const Center(
      child: Icon(Icons.image_outlined, size: 60, color: Colors.grey),
    ),
  );

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    ),
  );

  Widget _buildQuickInfoCard(IconData icon, String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Colors.black87,
        ),
      ),
    );
  }
}