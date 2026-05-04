class Artifact {
  final int? id;
  final String name;
  final String? description;
  final String category;
  final String? originCountry;
  final DateTime? dateAcquired;
  final double? estimatedValue;
  final bool isOnDisplay;
  final String? locationInMuseum;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  /// Local asset image path (not from API). Set only for locally-sourced artifacts.
  final String? localImagePath;

  Artifact({
    this.id,
    required this.name,
    this.description,
    required this.category,
    this.originCountry,
    this.dateAcquired,
    this.estimatedValue,
    required this.isOnDisplay,
    this.locationInMuseum,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.localImagePath,
  });

  factory Artifact.fromJson(Map<String, dynamic> json) {
    return Artifact(
      id: json['id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      originCountry: json['originCountry'] as String?,
      dateAcquired: json['dateAcquired'] != null
          ? DateTime.parse(json['dateAcquired'] as String)
          : null,
      estimatedValue: json['estimatedValue'] != null
          ? (json['estimatedValue'] as num).toDouble()
          : null,
      isOnDisplay: json['isOnDisplay'] as bool? ?? false,
      locationInMuseum: json['locationInMuseum'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'originCountry': originCountry,
      'dateAcquired': dateAcquired?.toIso8601String().split('T')[0],
      'estimatedValue': estimatedValue,
      'isOnDisplay': isOnDisplay,
      'locationInMuseum': locationInMuseum,
    };
  }

  Artifact copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    String? originCountry,
    DateTime? dateAcquired,
    double? estimatedValue,
    bool? isOnDisplay,
    String? locationInMuseum,
  }) {
    return Artifact(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      originCountry: originCountry ?? this.originCountry,
      dateAcquired: dateAcquired ?? this.dateAcquired,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      isOnDisplay: isOnDisplay ?? this.isOnDisplay,
      locationInMuseum: locationInMuseum ?? this.locationInMuseum,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
      updatedBy: updatedBy,
    );
  }
}

class ArtifactListResponse {
  final List<Artifact> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;

  ArtifactListResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
  });

  factory ArtifactListResponse.fromJson(Map<String, dynamic> json) {
    return ArtifactListResponse(
      content: (json['content'] as List)
          .map((item) => Artifact.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      number: json['number'] as int,
      size: json['size'] as int,
    );
  }
}
