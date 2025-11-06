class JobOffer {
  final String id;
  final String title;
  final String company;
  final String description;
  final String imageUrl;
  final String location;
  final String salary;
  final String type; // Full-time, Part-time, Contract, etc.
  final List<String> requirements;
  final List<String> tags; // Skills/tags like "Flutter", "Remote", etc.
  final DateTime postedDate;

  JobOffer({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.salary,
    required this.type,
    required this.requirements,
    required this.tags,
    required this.postedDate,
  });

  factory JobOffer.fromFirestore(Map<String, dynamic> data, String id) {
    // Handle postedDate which might be missing or in different formats
    DateTime parsedDate = DateTime.now();
    try {
      final postedDateField = data['postedDate'];
      if (postedDateField != null) {
        if (postedDateField is DateTime) {
          parsedDate = postedDateField;
        } else if (postedDateField.runtimeType.toString().contains('Timestamp')) {
          // Firestore Timestamp
          parsedDate = postedDateField.toDate();
        } else if (postedDateField is String) {
          // Try to parse string date
          parsedDate = DateTime.tryParse(postedDateField) ?? DateTime.now();
        } else if (postedDateField is int) {
          // Unix timestamp
          parsedDate = DateTime.fromMillisecondsSinceEpoch(postedDateField);
        }
      }
    } catch (e) {
      print('⚠️ Error parsing postedDate for job $id: $e, using current date');
      parsedDate = DateTime.now();
    }

    return JobOffer(
      id: id,
      title: data['title'] ?? '',
      company: data['company'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      location: data['location'] ?? '',
      salary: data['salary'] ?? '',
      type: data['type'] ?? 'Full-time',
      requirements: List<String>.from(data['requirements'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      postedDate: parsedDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'company': company,
      'description': description,
      'imageUrl': imageUrl,
      'location': location,
      'salary': salary,
      'type': type,
      'requirements': requirements,
      'tags': tags,
      'postedDate': postedDate,
    };
  }
}
