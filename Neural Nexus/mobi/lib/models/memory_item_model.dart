class MemoryItemModel {
  final String id;
  final String patientId;
  final String category; // family, favorite, place, routine
  final String title;
  final String details;
  final String? relationship;
  final String? imageUrl;

  MemoryItemModel({
    required this.id,
    required this.patientId,
    required this.category,
    required this.title,
    required this.details,
    this.relationship,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'category': category,
      'title': title,
      'details': details,
      'relationship': relationship,
      'image_url': imageUrl,
    };
  }

  factory MemoryItemModel.fromMap(Map<String, dynamic> map) {
    return MemoryItemModel(
      id: map['id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      category: map['category']?.toString() ?? 'family',
      title: map['title']?.toString() ?? '',
      details: map['details']?.toString() ?? '',
      relationship: map['relationship']?.toString(),
      imageUrl: map['image_url']?.toString(),
    );
  }
}
