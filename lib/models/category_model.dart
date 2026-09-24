import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final Map<String, String> name;
  final String icon;
  final int order;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.order = 0,
  });

  String getLocalizedName(String langCode) {
    return name[langCode] ?? name['en'] ?? id;
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] != null
          ? Map<String, String>.from(json['name'] as Map)
          : {'en': json['id'] as String? ?? ''},
      icon: json['icon'] as String? ?? 'temple',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CategoryModel.fromJson({
      ...data,
      'id': doc.id,
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'order': order,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'order': order,
    };
  }
}
