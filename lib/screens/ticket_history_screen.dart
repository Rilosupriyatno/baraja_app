import 'package:baraja_app/screens/ticket_payment_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/ticket_service.dart';

class TicketHistoryScreen extends StatefulWidget {
  final String userId;

  const TicketHistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  State<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends State<TicketHistoryScreen> {
  final TicketService _ticketService = TicketService();
  late Future<List<Map<String, dynamic>>> _futureTickets;

  @override
  void initState() {
    super.initState();
    _futureTickets = _ticketService.getUserTickets(widget.userId);
  }

  Future<void> _refreshTickets() async {
    setState(() {
      _futureTickets = _ticketService.getUserTickets(widget.userId);
    });
  }

  Color _getStatusColorValue(String status) {
    switch (status.toLowerCase()) {
      case 'settlement':
      case 'capture':
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.amber;
      case 'pending':
        return Colors.orange;
      case 'expire':
      case 'unpaid':
        return Colors.red;
      case 'cancel':
      case 'deny':
      case 'failure':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    final lower = status.toLowerCase();
    String mapped;
    switch (lower) {
      case 'settlement':
      case 'capture':
      case 'paid':
        mapped = 'Lunas';
        break;
      case 'partial':
        mapped = 'Menunggu Pelunasan';
        break;
      case 'pending':
        mapped = 'Menunggu Pembayaran';
        break;
      case 'expire':
      case 'unpaid':
        mapped = 'Kadaluarsa';
        break;
      case 'cancel':
        mapped = 'Dibatalkan';
        break;
      case 'deny':
        mapped = 'Ditolak';
        break;
      case 'failure':
        mapped = 'Gagal';
        break;
      default:
        mapped = status;
    }

    debugPrint("Mapping status: raw='$status' -> mapped='$mapped'");
    return mapped;
  }

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // String _formatDate(String dateString) {
  //   try {
  //     final DateTime date = DateTime.parse(dateString);
  //     final months = [
  //       'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  //       'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
  //     ];
  //     return '${date.day} ${months[date.month - 1]} ${date.year}';
  //   } catch (e) {
  //     return dateString;
  //   }
  // }

  String _formatDateTime(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          "Riwayat Tiket",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
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
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureTickets,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshTickets,
                    child: const Text("Coba Lagi"),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada riwayat tiket",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tiket yang Anda beli akan muncul di sini",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          final tickets = snapshot.data!;
          return RefreshIndicator(
            color: const Color(0xFFD4AF37),
            onRefresh: _refreshTickets,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                final event = ticket['event'] as Map<String, dynamic>?;
                final payment = ticket['payment_id'] as Map<String, dynamic>?;

                if (event == null) {
                  return const SizedBox.shrink();
                }

                // Ambil status dari payment_id
                final rawStatus = payment?['status'] ?? 'unknown';
                final imageUrl = event['imageUrl'] ?? '';

                debugPrint("Ticket ${ticket['_id']} raw status: $rawStatus");

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // Navigate to payment detail if pending, otherwise show ticket detail
                      if (rawStatus.toLowerCase() == 'pending') {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => TicketPaymentDetailScreen(
                        //       ticket: ticket,
                        //     ),
                        //   ),
                        // ).then((_) => _refreshTickets());
                      } else {
                        _showTicketDetail(context, ticket);
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image section
                        if (imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 120,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 120,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),

                        // Content section
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status badge
                              Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColorValue(rawStatus),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusText(rawStatus),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Event title
                              Text(
                                event['name'] ?? 'Nama Event Tidak Tersedia',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),

                              // Event date and location
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _formatDateTime(event['date'] ?? ''),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      event['location'] ?? 'Lokasi Tidak Tersedia',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Price and quantity info
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Pembayaran',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        _formatCurrency(payment?['totalAmount'] ?? ticket['totalPrice'] ?? 0),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFD4AF37),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${ticket['quantity'] ?? 1} tiket',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              // Show payment action for pending status
                              if (rawStatus.toLowerCase() == 'pending') ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TicketPaymentDetailScreen(
                                            ticket: ticket,
                                          ),
                                        ),
                                      ).then((_) => _refreshTickets());
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD4AF37),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Bayar Sekarang',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showTicketDetail(BuildContext context, Map<String, dynamic> ticket) {
    final event = ticket['event'] as Map<String, dynamic>?;
    final payment = ticket['payment_id'] as Map<String, dynamic>?;

    if (event == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              minWidth: 280,
              maxWidth: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          event['name'] ?? 'Detail Tiket',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Event image
                        if (event['imageUrl'] != null && event['imageUrl'].toString().isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: event['imageUrl'],
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                height: 120,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        _buildDetailRow("Lokasi", event['location'] ?? '-'),
                        _buildDetailRow("Tanggal", _formatDateTime(event['date'] ?? '')),
                        _buildDetailRow("Harga per Tiket", _formatCurrency(event['price'] ?? 0)),
                        _buildDetailRow("Jumlah Tiket", "${ticket['quantity'] ?? 0}"),
                        _buildDetailRow("Total Harga", _formatCurrency(ticket['totalPrice'] ?? 0)),

                        const Divider(height: 24),

                        Text(
                          "Informasi Pembayaran",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),

                        _buildDetailRow("Metode Bayar", (payment?['method'] ?? '-').toString().toUpperCase()),
                        _buildDetailRow("Status", _getStatusText(payment?['status'] ?? 'Unknown')),
                        _buildDetailRow("Waktu Transaksi", payment?['transaction_time'] ?? '-'),

                        if (payment?['payment_code'] != null)
                          _buildDetailRow("Kode Pembayaran", payment?['payment_code'] ?? '-'),

                        if (payment?['expiry_time'] != null && payment?['status'] == 'pending')
                          _buildDetailRow("Berlaku Hingga", payment?['expiry_time'] ?? '-'),
                      ],
                    ),
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Tutup"),
                        ),
                      ),
                      if (payment?['status'] == 'pending') ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TicketPaymentDetailScreen(
                                    ticket: ticket,
                                  ),
                                ),
                              ).then((_) => _refreshTickets());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                            ),
                            child: const Text(
                              "Bayar",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(": "),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}