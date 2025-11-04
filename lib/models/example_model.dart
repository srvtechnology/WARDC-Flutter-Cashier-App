// lib/models/example_model.dart

/// Example model class
/// Models represent data structures in your application
class ExampleModel {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;

  ExampleModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  // Convert from JSON
  factory ExampleModel.fromJson(Map<String, dynamic> json) {
    return ExampleModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with method
  ExampleModel copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return ExampleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ExampleModel(id: $id, name: $name, description: $description, createdAt: $createdAt)';
  }
}

