import 'package:cloud_firestore/cloud_firestore.dart';

/// Devotional Song Model
class SongModel {
  final String id;
  final String title;
  final Map<String, String>? titleLocalized;
  final String language;
  final String categoryId;
  final String? categoryName;
  final String deity;
  final Map<String, String>? deityLocalized;
  final String description;
  final String? artist;
  final String? album;
  final String imageUrl;
  final String audioUrl;
  final int duration; // in seconds
  final String? lyrics;
  final Map<String, String>? lyricsLocalized;
  final Map<String, String>? meaningLocalized;
  final String? licenseInfo;
  final bool isPublicDomain;
  final bool published;
  final DateTime createdAt;
  final DateTime updatedAt;

  SongModel({
    required this.id,
    required this.title,
    this.titleLocalized,
    required this.language,
    required this.categoryId,
    this.categoryName,
    required this.deity,
    this.deityLocalized,
    required this.description,
    this.artist,
    this.album,
    required this.imageUrl,
    required this.audioUrl,
    required this.duration,
    this.lyrics,
    this.lyricsLocalized,
    this.meaningLocalized,
    this.licenseInfo,
    this.isPublicDomain = true,
    this.published = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Resolves the title dynamically based on active locale code (kn, en, hi, ta, ml)
  String getLocalizedTitle(String langCode) {
    if (titleLocalized != null && titleLocalized!.containsKey(langCode)) {
      return titleLocalized![langCode]!;
    }
    return title;
  }

  /// Resolves deity name dynamically based on active locale code
  String getLocalizedDeity(String langCode) {
    if (deityLocalized != null && deityLocalized!.containsKey(langCode)) {
      return deityLocalized![langCode]!;
    }
    return deity;
  }

  /// Resolves lyrics dynamically in requested language (kn, en, hi, ta, ml)
  String? getLocalizedLyrics(String langCode) {
    if (lyricsLocalized != null && lyricsLocalized!.containsKey(langCode)) {
      return lyricsLocalized![langCode];
    }
    return lyrics;
  }

  /// Resolves spiritual meaning/commentary in requested language
  String? getLocalizedMeaning(String langCode) {
    if (meaningLocalized != null && meaningLocalized!.containsKey(langCode)) {
      return meaningLocalized![langCode];
    }
    return null;
  }

  /// Formatted duration string mm:ss or hh:mm:ss
  String get formattedDuration {
    final minutes = (duration / 60).floor();
    final seconds = duration % 60;
    if (minutes >= 60) {
      final hours = (minutes / 60).floor();
      final remMinutes = minutes % 60;
      return '${hours.toString().padLeft(2, '0')}:${remMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      titleLocalized: json['titleLocalized'] != null
          ? Map<String, String>.from(json['titleLocalized'] as Map)
          : null,
      language: json['language'] as String? ?? 'en',
      categoryId: json['categoryId'] as String? ?? 'stotras',
      categoryName: json['categoryName'] as String?,
      deity: json['deity'] as String? ?? '',
      deityLocalized: json['deityLocalized'] != null
          ? Map<String, String>.from(json['deityLocalized'] as Map)
          : null,
      description: json['description'] as String? ?? '',
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      imageUrl: json['imageUrl'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      lyrics: json['lyrics'] as String?,
      lyricsLocalized: json['lyricsLocalized'] != null
          ? Map<String, String>.from(json['lyricsLocalized'] as Map)
          : null,
      meaningLocalized: json['meaningLocalized'] != null
          ? Map<String, String>.from(json['meaningLocalized'] as Map)
          : null,
      licenseInfo: json['licenseInfo'] as String?,
      isPublicDomain: json['isPublicDomain'] as bool? ?? true,
      published: json['published'] as bool? ?? true,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  factory SongModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SongModel.fromJson({
      ...data,
      'id': doc.id,
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (titleLocalized != null) 'titleLocalized': titleLocalized,
      'language': language,
      'categoryId': categoryId,
      if (categoryName != null) 'categoryName': categoryName,
      'deity': deity,
      if (deityLocalized != null) 'deityLocalized': deityLocalized,
      'description': description,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'duration': duration,
      if (lyrics != null) 'lyrics': lyrics,
      if (lyricsLocalized != null) 'lyricsLocalized': lyricsLocalized,
      if (meaningLocalized != null) 'meaningLocalized': meaningLocalized,
      if (licenseInfo != null) 'licenseInfo': licenseInfo,
      'isPublicDomain': isPublicDomain,
      'published': published,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      if (titleLocalized != null) 'titleLocalized': titleLocalized,
      'language': language,
      'categoryId': categoryId,
      if (categoryName != null) 'categoryName': categoryName,
      'deity': deity,
      if (deityLocalized != null) 'deityLocalized': deityLocalized,
      'description': description,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'duration': duration,
      if (lyrics != null) 'lyrics': lyrics,
      if (lyricsLocalized != null) 'lyricsLocalized': lyricsLocalized,
      if (meaningLocalized != null) 'meaningLocalized': meaningLocalized,
      if (licenseInfo != null) 'licenseInfo': licenseInfo,
      'isPublicDomain': isPublicDomain,
      'published': published,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SongModel copyWith({
    String? id,
    String? title,
    Map<String, String>? titleLocalized,
    String? language,
    String? categoryId,
    String? categoryName,
    String? deity,
    Map<String, String>? deityLocalized,
    String? description,
    String? artist,
    String? album,
    String? imageUrl,
    String? audioUrl,
    int? duration,
    String? lyrics,
    Map<String, String>? lyricsLocalized,
    Map<String, String>? meaningLocalized,
    String? licenseInfo,
    bool? isPublicDomain,
    bool? published,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      titleLocalized: titleLocalized ?? this.titleLocalized,
      language: language ?? this.language,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      deity: deity ?? this.deity,
      deityLocalized: deityLocalized ?? this.deityLocalized,
      description: description ?? this.description,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      lyrics: lyrics ?? this.lyrics,
      lyricsLocalized: lyricsLocalized ?? this.lyricsLocalized,
      meaningLocalized: meaningLocalized ?? this.meaningLocalized,
      licenseInfo: licenseInfo ?? this.licenseInfo,
      isPublicDomain: isPublicDomain ?? this.isPublicDomain,
      published: published ?? this.published,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }


  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
