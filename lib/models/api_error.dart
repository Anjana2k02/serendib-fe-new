class ApiError implements Exception {
  final int status;
  final String message;
  final String? path;
  final List<String>? errors;

  ApiError({
    required this.status,
    required this.message,
    this.path,
    this.errors,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      status: json['status'] as int,
      message: json['message'] as String,
      path: json['path'] as String?,
      errors: json['errors'] != null
          ? List<String>.from(json['errors'] as List)
          : null,
    );
  }

  String get displayMessage {
    if (errors != null && errors!.isNotEmpty) {
      return errors!.join('\n');
    }
    return message;
  }

  @override
  String toString() {
    return 'ApiError(status: $status, message: $message, path: $path, errors: $errors)';
  }
}
