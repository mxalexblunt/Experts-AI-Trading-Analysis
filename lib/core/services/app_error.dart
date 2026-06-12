enum AppErrorType {
  unavailable,
  network,
  unauthorized,
  rateLimited,
  invalidData,
  consentRequired,
  parsing,
  unknown,
}

class AppError implements Exception {
  const AppError({
    required this.message,
    this.type = AppErrorType.unknown,
    this.statusCode,
    this.cause,
  });

  final String message;
  final AppErrorType type;
  final int? statusCode;
  final Object? cause;

  factory AppError.unavailable(String message) {
    return AppError(message: message, type: AppErrorType.unavailable);
  }

  factory AppError.consentRequired() {
    return const AppError(
      message: 'AI data consent is required before generating analysis.',
      type: AppErrorType.consentRequired,
    );
  }

  factory AppError.fromJson(Map<String, dynamic> json) {
    return AppError(
      message: json['message'] as String? ?? 'Something went wrong.',
      type: _parseType(json['type'] as String?),
      statusCode: _readInt(json['statusCode']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'type': type.name,
      if (statusCode != null) 'statusCode': statusCode,
    };
  }

  AppError copyWith({
    String? message,
    AppErrorType? type,
    int? statusCode,
    Object? cause,
    bool clearStatusCode = false,
    bool clearCause = false,
  }) {
    return AppError(
      message: message ?? this.message,
      type: type ?? this.type,
      statusCode: clearStatusCode ? null : statusCode ?? this.statusCode,
      cause: clearCause ? null : cause ?? this.cause,
    );
  }

  static AppErrorType _parseType(String? value) {
    return AppErrorType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AppErrorType.unknown,
    );
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  String toString() {
    final code = statusCode == null ? '' : ' ($statusCode)';
    return 'AppError.${type.name}$code: $message';
  }
}
