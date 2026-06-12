class NewsItemModel {
  const NewsItemModel({
    required this.id,
    required this.headline,
    this.summary,
    this.source,
    this.url,
    this.imageUrl,
    this.publishedAt,
    this.relatedSymbols = const [],
  });

  final String id;
  final String headline;
  final String? summary;
  final String? source;
  final String? url;
  final String? imageUrl;
  final DateTime? publishedAt;
  final List<String> relatedSymbols;

  factory NewsItemModel.fromJson(Map<String, dynamic> json) {
    return NewsItemModel(
      id: _readString(json['id'], fallback: _readString(json['url'])),
      headline: _readString(json['headline'], fallback: 'Market update'),
      summary: _nullableString(json['summary']),
      source: _nullableString(json['source']),
      url: _nullableString(json['url']),
      imageUrl: _nullableString(json['imageUrl']),
      publishedAt: _readDateTime(json['publishedAt']),
      relatedSymbols: _readStringList(json['relatedSymbols'])
          .map((symbol) => symbol.toUpperCase())
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'headline': headline,
      if (summary != null) 'summary': summary,
      if (source != null) 'source': source,
      if (url != null) 'url': url,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
      'relatedSymbols': relatedSymbols,
    };
  }

  NewsItemModel copyWith({
    String? id,
    String? headline,
    String? summary,
    String? source,
    String? url,
    String? imageUrl,
    DateTime? publishedAt,
    List<String>? relatedSymbols,
    bool clearSummary = false,
    bool clearSource = false,
    bool clearUrl = false,
    bool clearImageUrl = false,
    bool clearPublishedAt = false,
  }) {
    return NewsItemModel(
      id: id ?? this.id,
      headline: headline ?? this.headline,
      summary: clearSummary ? null : summary ?? this.summary,
      source: clearSource ? null : source ?? this.source,
      url: clearUrl ? null : url ?? this.url,
      imageUrl: clearImageUrl ? null : imageUrl ?? this.imageUrl,
      publishedAt: clearPublishedAt ? null : publishedAt ?? this.publishedAt,
      relatedSymbols: relatedSymbols ?? this.relatedSymbols,
    );
  }
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

List<String> _readStringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }
  return const [];
}

DateTime? _readDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
  if (value is String) return DateTime.tryParse(value);
  return null;
}
