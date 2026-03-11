class CaptureSession {
  final String id;
  final String name;
  final DateTime createdAt;
  final int imageCount;
  final String status;
  final String? modelUrl;

  CaptureSession({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.imageCount,
    required this.status,
    this.modelUrl,
  });

  factory CaptureSession.fromJson(Map<String, dynamic> json) {
    return CaptureSession(
      id: json['session_id'] ?? '',
      name: json['name'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now() 
          : DateTime.now(),
      imageCount: json['image_count'] ?? 0,
      status: json['status'] ?? 'unknown',
      modelUrl: json['model_url'],
    );
  }
}
