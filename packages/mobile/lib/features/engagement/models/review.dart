import 'package:equatable/equatable.dart';

/// Review model for user reviews system
class Review extends Equatable {
  final String id;
  final String userId;
  final String clinicId;
  final String serviceId;
  final String appointmentId;
  final double overallRating;
  final double serviceRating;
  final double cleanlinessRating;
  final double staffRating;
  final double valueRating;
  final String title;
  final String comment;
  final List<String> tags;
  final List<String> beforePhotos;
  final List<String> afterPhotos;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final ReviewStatus status;
  final bool isRecommended;
  final bool wouldReturn;
  final int helpfulCount;
  final int notHelpfulCount;
  final List<ReviewResponse> responses;

  const Review({
    required this.id,
    required this.userId,
    required this.clinicId,
    required this.serviceId,
    required this.appointmentId,
    required this.overallRating,
    required this.serviceRating,
    required this.cleanlinessRating,
    required this.staffRating,
    required this.valueRating,
    required this.title,
    required this.comment,
    required this.tags,
    required this.beforePhotos,
    required this.afterPhotos,
    required this.createdAt,
    this.updatedAt,
    required this.status,
    required this.isRecommended,
    required this.wouldReturn,
    required this.helpfulCount,
    required this.notHelpfulCount,
    required this.responses,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      userId: json['userId'] as String,
      clinicId: json['clinicId'] as String,
      serviceId: json['serviceId'] as String,
      appointmentId: json['appointmentId'] as String,
      overallRating: (json['overallRating'] as num).toDouble(),
      serviceRating: (json['serviceRating'] as num).toDouble(),
      cleanlinessRating: (json['cleanlinessRating'] as num).toDouble(),
      staffRating: (json['staffRating'] as num).toDouble(),
      valueRating: (json['valueRating'] as num).toDouble(),
      title: json['title'] as String,
      comment: json['comment'] as String,
      tags: List<String>.from(json['tags'] as List),
      beforePhotos: List<String>.from(json['beforePhotos'] as List),
      afterPhotos: List<String>.from(json['afterPhotos'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      status: ReviewStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ReviewStatus.pending,
      ),
      isRecommended: json['isRecommended'] as bool,
      wouldReturn: json['wouldReturn'] as bool,
      helpfulCount: json['helpfulCount'] as int,
      notHelpfulCount: json['notHelpfulCount'] as int,
      responses: (json['responses'] as List<dynamic>?)
          ?.map((r) => ReviewResponse.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'clinicId': clinicId,
      'serviceId': serviceId,
      'appointmentId': appointmentId,
      'overallRating': overallRating,
      'serviceRating': serviceRating,
      'cleanlinessRating': cleanlinessRating,
      'staffRating': staffRating,
      'valueRating': valueRating,
      'title': title,
      'comment': comment,
      'tags': tags,
      'beforePhotos': beforePhotos,
      'afterPhotos': afterPhotos,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status.name,
      'isRecommended': isRecommended,
      'wouldReturn': wouldReturn,
      'helpfulCount': helpfulCount,
      'notHelpfulCount': notHelpfulCount,
      'responses': responses.map((r) => r.toJson()).toList(),
    };
  }

  Review copyWith({
    String? id,
    String? userId,
    String? clinicId,
    String? serviceId,
    String? appointmentId,
    double? overallRating,
    double? serviceRating,
    double? cleanlinessRating,
    double? staffRating,
    double? valueRating,
    String? title,
    String? comment,
    List<String>? tags,
    List<String>? beforePhotos,
    List<String>? afterPhotos,
    DateTime? createdAt,
    DateTime? updatedAt,
    ReviewStatus? status,
    bool? isRecommended,
    bool? wouldReturn,
    int? helpfulCount,
    int? notHelpfulCount,
    List<ReviewResponse>? responses,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clinicId: clinicId ?? this.clinicId,
      serviceId: serviceId ?? this.serviceId,
      appointmentId: appointmentId ?? this.appointmentId,
      overallRating: overallRating ?? this.overallRating,
      serviceRating: serviceRating ?? this.serviceRating,
      cleanlinessRating: cleanlinessRating ?? this.cleanlinessRating,
      staffRating: staffRating ?? this.staffRating,
      valueRating: valueRating ?? this.valueRating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      tags: tags ?? this.tags,
      beforePhotos: beforePhotos ?? this.beforePhotos,
      afterPhotos: afterPhotos ?? this.afterPhotos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      isRecommended: isRecommended ?? this.isRecommended,
      wouldReturn: wouldReturn ?? this.wouldReturn,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      notHelpfulCount: notHelpfulCount ?? this.notHelpfulCount,
      responses: responses ?? this.responses,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        clinicId,
        serviceId,
        appointmentId,
        overallRating,
        serviceRating,
        cleanlinessRating,
        staffRating,
        valueRating,
        title,
        comment,
        tags,
        beforePhotos,
        afterPhotos,
        createdAt,
        updatedAt,
        status,
        isRecommended,
        wouldReturn,
        helpfulCount,
        notHelpfulCount,
        responses,
      ];
}

/// Review status enum
enum ReviewStatus {
  pending,
  approved,
  rejected,
  flagged,
  archived
}

/// Review response from clinic
class ReviewResponse extends Equatable {
  final String id;
  final String reviewId;
  final String clinicId;
  final String responseText;
  final DateTime createdAt;
  final String respondentName;
  final String respondentRole;

  const ReviewResponse({
    required this.id,
    required this.reviewId,
    required this.clinicId,
    required this.responseText,
    required this.createdAt,
    required this.respondentName,
    required this.respondentRole,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      id: json['id'] as String,
      reviewId: json['reviewId'] as String,
      clinicId: json['clinicId'] as String,
      responseText: json['responseText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondentName: json['respondentName'] as String,
      respondentRole: json['respondentRole'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewId': reviewId,
      'clinicId': clinicId,
      'responseText': responseText,
      'createdAt': createdAt.toIso8601String(),
      'respondentName': respondentName,
      'respondentRole': respondentRole,
    };
  }

  @override
  List<Object> get props => [
        id,
        reviewId,
        clinicId,
        responseText,
        createdAt,
        respondentName,
        respondentRole,
      ];
}

/// Review statistics for user
class ReviewStats extends Equatable {
  final int totalReviews;
  final double averageRating;
  final int helpfulVotes;
  final int reviewsThisMonth;
  final String topCategory;
  final List<ReviewBadge> badges;

  const ReviewStats({
    required this.totalReviews,
    required this.averageRating,
    required this.helpfulVotes,
    required this.reviewsThisMonth,
    required this.topCategory,
    required this.badges,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    return ReviewStats(
      totalReviews: json['totalReviews'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      helpfulVotes: json['helpfulVotes'] as int,
      reviewsThisMonth: json['reviewsThisMonth'] as int,
      topCategory: json['topCategory'] as String,
      badges: (json['badges'] as List<dynamic>)
          .map((b) => ReviewBadge.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object> get props => [
        totalReviews,
        averageRating,
        helpfulVotes,
        reviewsThisMonth,
        topCategory,
        badges,
      ];
}

/// Review badge for gamification
class ReviewBadge extends Equatable {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final DateTime earnedAt;
  final BadgeLevel level;

  const ReviewBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.earnedAt,
    required this.level,
  });

  factory ReviewBadge.fromJson(Map<String, dynamic> json) {
    return ReviewBadge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconPath: json['iconPath'] as String,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
      level: BadgeLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => BadgeLevel.bronze,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'earnedAt': earnedAt.toIso8601String(),
      'level': level.name,
    };
  }

  @override
  List<Object> get props => [id, name, description, iconPath, earnedAt, level];
}

/// Badge levels
enum BadgeLevel { bronze, silver, gold, platinum }