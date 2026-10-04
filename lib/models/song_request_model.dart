class SongRequestModel {
  final String id;
  final String songTitle;
  final String deity;
  final String language;
  final String singerOrComposer;
  final String referenceUrl;
  final String notes;
  final DateTime requestedAt;
  final String requestedByUserId;
  final String status; // 'pending', 'in_review', 'approved', 'fulfilled'
  final int votesCount;

  const SongRequestModel({
    required this.id,
    required this.songTitle,
    required this.deity,
    required this.language,
    this.singerOrComposer = '',
    this.referenceUrl = '',
    this.notes = '',
    required this.requestedAt,
    this.requestedByUserId = 'devotee',
    this.status = 'pending',
    this.votesCount = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'songTitle': songTitle,
    'deity': deity,
    'language': language,
    'singerOrComposer': singerOrComposer,
    'referenceUrl': referenceUrl,
    'notes': notes,
    'requestedAt': requestedAt.toIso8601String(),
    'requestedByUserId': requestedByUserId,
    'status': status,
    'votesCount': votesCount,
  };

  factory SongRequestModel.fromJson(Map<String, dynamic> json) => SongRequestModel(
    id: json['id'] as String? ?? '',
    songTitle: json['songTitle'] as String? ?? '',
    deity: json['deity'] as String? ?? '',
    language: json['language'] as String? ?? 'kn',
    singerOrComposer: json['singerOrComposer'] as String? ?? '',
    referenceUrl: json['referenceUrl'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    requestedAt: json['requestedAt'] != null
        ? DateTime.tryParse(json['requestedAt'] as String) ?? DateTime.now()
        : DateTime.now(),
    requestedByUserId: json['requestedByUserId'] as String? ?? 'devotee',
    status: json['status'] as String? ?? 'pending',
    votesCount: (json['votesCount'] as num?)?.toInt() ?? 1,
  );

  SongRequestModel copyWith({
    String? id,
    String? songTitle,
    String? deity,
    String? language,
    String? singerOrComposer,
    String? referenceUrl,
    String? notes,
    DateTime? requestedAt,
    String? requestedByUserId,
    String? status,
    int? votesCount,
  }) {
    return SongRequestModel(
      id: id ?? this.id,
      songTitle: songTitle ?? this.songTitle,
      deity: deity ?? this.deity,
      language: language ?? this.language,
      singerOrComposer: singerOrComposer ?? this.singerOrComposer,
      referenceUrl: referenceUrl ?? this.referenceUrl,
      notes: notes ?? this.notes,
      requestedAt: requestedAt ?? this.requestedAt,
      requestedByUserId: requestedByUserId ?? this.requestedByUserId,
      status: status ?? this.status,
      votesCount: votesCount ?? this.votesCount,
    );
  }
}
