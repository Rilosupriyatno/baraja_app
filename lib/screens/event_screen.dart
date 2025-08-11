import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class Event {
  final String id;
  final String name;
  final String imageUrl;
  final DateTime dateTime;
  final String location;
  final bool isFree;
  final double? price;
  final String description;

  Event({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.dateTime,
    required this.location,
    required this.isFree,
    this.price,
    required this.description,
  });
}

class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  List<Event> _getDummyEvents() {
    final now = DateTime.now();
    return [
      Event(
        id: '1',
        name: 'Konser Musik Akustik',
        imageUrl: 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=400',
        dateTime: now.add(const Duration(days: 1)),
        location: 'Baraja Amphitheater',
        isFree: true,
        description: 'Nikmati malam yang penuh dengan musik akustik dari artis lokal terbaik.',
      ),
      Event(
        id: '2',
        name: 'Workshop Digital Marketing',
        imageUrl: 'https://images.unsplash.com/photo-1556761175-b413da4baf72?w=400',
        dateTime: now.add(const Duration(days: 2)),
        location: 'Baraja Amphitheater',
        isFree: true,
        description: 'Pelajari strategi digital marketing terkini untuk mengembangkan bisnis Anda.',
      ),
      Event(
        id: '3',
        name: 'Pameran Seni Kontemporer',
        imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        dateTime: now.add(const Duration(days: 3)),
        location: 'Baraja Amphitheater',
        isFree: true,
        description: 'Eksplor karya seni kontemporer dari seniman Indonesia dan internasional.',
      ),
      Event(
        id: '4',
        name: 'Seminar Teknologi AI',
        imageUrl: 'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=400',
        dateTime: now.add(const Duration(days: 4)),
        location: 'Baraja Amphitheater',
        isFree: true,
        description: 'Diskusi mendalam tentang perkembangan teknologi AI dan dampaknya.',
      ),
      Event(
        id: '5',
        name: 'Festival Kuliner Nusantara',
        imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400',
        dateTime: now.add(const Duration(days: 5)),
        location: 'Baraja Amphitheater',
        isFree: false,
        price: 50000,
        description: 'Cicipi berbagai kuliner khas Nusantara dari Sabang hingga Merauke.',
      ),
      Event(
        id: '6',
        name: 'Konser Jazz Under The Stars',
        imageUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400',
        dateTime: now.add(const Duration(days: 6)),
        location: 'Baraja Amphitheater',
        isFree: true,
        description: 'Malam romantis dengan musik jazz di bawah bintang-bintang.',
      ),
      Event(
        id: '7',
        name: 'Bazaar Produk Lokal',
        imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
        dateTime: now.add(const Duration(days: 7)),
        location: 'Baraja Amphitheater',
        isFree: true,
        description: 'Dukung produk lokal dengan berbelanja di bazaar terbesar tahun ini.',
      ),
    ];
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;

    if (difference == 0) {
      return 'Hari ini, ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference == 1) {
      return 'Besok, ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('EEEE, d MMM yyyy • HH:mm', 'id_ID').format(dateTime);
    }
  }

  void _navigateToEventDetail(BuildContext context, Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = _getDummyEvents();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Event',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: EventCard(
              event: event,
              onTap: () => _navigateToEventDetail(context, event),
              formatDateTime: _formatDateTime,
            ),
          );
        },
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final String Function(DateTime) formatDateTime;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.formatDateTime,
  });

  // Warna Gold untuk event berbayar
  Color get _goldColor => const Color(0xFFD4AF37);
  Color get _goldBackgroundColor => const Color(0xFFFFF8E1);

  // Warna Silver untuk event gratis
  Color get _silverColor => const Color(0xFF8E8E93);
  Color get _silverBackgroundColor => const Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: event.isFree
            ? null
            : const LinearGradient(
          colors: [
            Color(0xFFB8860B), // Gold tua
            Color(0xFFFFD700), // Gold terang
            Color(0xFFB8860B), // Gold tua
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Material(
        color: event.isFree ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              // Content (pakai background putih transparan biar teks tetap jelas)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: event.isFree
                      ? Colors.white
                      : Colors.white.withOpacity(0.9), // transparan di atas gold
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(FontAwesomeIcons.calendar, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            formatDateTime(event.dateTime),
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(FontAwesomeIcons.locationDot, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.location,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: event.isFree
                                ? _silverBackgroundColor
                                : _goldBackgroundColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: event.isFree
                                  ? _silverColor.withOpacity(0.3)
                                  : _goldColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            event.isFree
                                ? 'GRATIS'
                                : 'Rp ${NumberFormat('#,###', 'id_ID').format(event.price)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: event.isFree ? _silverColor : _goldColor,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID').format(dateTime);
  }

  // Warna Gold untuk event berbayar
  Color get _goldColor => const Color(0xFFD4AF37);
  Color get _goldBackgroundColor => const Color(0xFFFFF8E1);

  // Warna Silver untuk event gratis
  Color get _silverColor => const Color(0xFF8E8E93);
  Color get _silverBackgroundColor => const Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Detail Event',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[300],
              child: Image.network(
                event.imageUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Date & Time
                  _buildInfoRow(
                    FontAwesomeIcons.calendar,
                    'Tanggal & Waktu',
                    _formatDateTime(event.dateTime),
                  ),
                  const SizedBox(height: 16),
                  // Location
                  _buildInfoRow(
                    FontAwesomeIcons.locationDot,
                    'Lokasi',
                    event.location,
                  ),
                  const SizedBox(height: 16),
                  // Price dengan styling khusus
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        FontAwesomeIcons.tag,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Harga',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: event.isFree ? _silverBackgroundColor : _goldBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: event.isFree ? _silverColor.withOpacity(0.3) : _goldColor.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                event.isFree
                                    ? 'GRATIS'
                                    : 'Rp ${NumberFormat('#,###', 'id_ID').format(event.price)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: event.isFree ? _silverColor : _goldColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              event.isFree
                                  ? 'Berhasil mendaftar ke event!'
                                  : 'Fitur pembelian tiket akan segera hadir!',
                            ),
                            backgroundColor: event.isFree ? _silverColor : _goldColor,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: event.isFree ? _silverColor : _goldColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        event.isFree ? 'Daftar Sekarang' : 'Beli Tiket',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}