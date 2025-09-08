class Event {
  final String id;
  final String name;
  final String description;
  final String location;
  final DateTime date;
  final int price;
  final String organizer;
  final String contactEmail;
  final String imageUrl;
  final String category;
  final List<String> tags;
  final String status;
  final int capacity;
  final List<String> attendees;
  final String privacy;
  final String terms;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.date,
    required this.price,
    required this.organizer,
    required this.contactEmail,
    required this.imageUrl,
    required this.category,
    required this.tags,
    required this.status,
    required this.capacity,
    required this.attendees,
    required this.privacy,
    required this.terms,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      date: DateTime.parse(json['date']),
      price: (json['price'] ?? 0).toInt(),
      organizer: json['organizer'] ?? '',
      contactEmail: json['contactEmail'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      status: json['status'] ?? '',
      capacity: json['capacity'] ?? 0,
      attendees: List<String>.from(json['attendees'] ?? []),
      privacy: json['privacy'] ?? '',
      terms: json['terms'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
