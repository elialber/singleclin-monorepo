class OnboardingStep {
  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.imageAsset,
    this.lottieAsset,
    this.customData,
  });

  factory OnboardingStep.fromJson(Map<String, dynamic> json) {
    return OnboardingStep(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageAsset: json['imageAsset'] ?? '',
      lottieAsset: json['lottieAsset'],
      customData: json['customData'],
    );
  }
  final int id;
  final String title;
  final String description;
  final String imageAsset;
  final String? lottieAsset;
  final Map<String, dynamic>? customData;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageAsset': imageAsset,
      'lottieAsset': lottieAsset,
      'customData': customData,
    };
  }

  OnboardingStep copyWith({
    int? id,
    String? title,
    String? description,
    String? imageAsset,
    String? lottieAsset,
    Map<String, dynamic>? customData,
  }) {
    return OnboardingStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageAsset: imageAsset ?? this.imageAsset,
      lottieAsset: lottieAsset ?? this.lottieAsset,
      customData: customData ?? this.customData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingStep &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.imageAsset == imageAsset &&
        other.lottieAsset == lottieAsset;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, description, imageAsset, lottieAsset);
  }

  @override
  String toString() {
    return 'OnboardingStep(id: $id, title: $title, description: $description)';
  }
}
