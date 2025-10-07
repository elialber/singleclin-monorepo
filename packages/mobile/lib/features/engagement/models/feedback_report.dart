import 'package:equatable/equatable.dart';

/// Feedback report model for app improvements and bug reports
class FeedbackReport extends Equatable {
  const FeedbackReport({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.screenshots,
    required this.deviceInfo,
    required this.appVersion,
    required this.osVersion,
    required this.createdAt,
    required this.status,
    required this.votesCount,
    required this.hasVoted,
    required this.tags,
    required this.comments,
    this.updatedAt,
    this.developerResponse,
    this.resolvedAt,
  });

  factory FeedbackReport.fromJson(Map<String, dynamic> json) {
    return FeedbackReport(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: FeedbackType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => FeedbackType.suggestion,
      ),
      category: FeedbackCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => FeedbackCategory.general,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      priority: FeedbackPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => FeedbackPriority.medium,
      ),
      screenshots: List<String>.from(json['screenshots'] as List),
      deviceInfo: Map<String, dynamic>.from(json['deviceInfo'] as Map),
      appVersion: json['appVersion'] as String,
      osVersion: json['osVersion'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      status: FeedbackStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => FeedbackStatus.submitted,
      ),
      votesCount: json['votesCount'] as int,
      hasVoted: json['hasVoted'] as bool,
      tags: List<String>.from(json['tags'] as List),
      developerResponse: json['developerResponse'] as String?,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      comments:
          (json['comments'] as List<dynamic>?)
              ?.map((c) => FeedbackComment.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
  final String id;
  final String userId;
  final FeedbackType type;
  final FeedbackCategory category;
  final String title;
  final String description;
  final FeedbackPriority priority;
  final List<String> screenshots;
  final Map<String, dynamic> deviceInfo;
  final String appVersion;
  final String osVersion;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final FeedbackStatus status;
  final int votesCount;
  final bool hasVoted;
  final List<String> tags;
  final String? developerResponse;
  final DateTime? resolvedAt;
  final List<FeedbackComment> comments;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'category': category.name,
      'title': title,
      'description': description,
      'priority': priority.name,
      'screenshots': screenshots,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
      'osVersion': osVersion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status.name,
      'votesCount': votesCount,
      'hasVoted': hasVoted,
      'tags': tags,
      'developerResponse': developerResponse,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'comments': comments.map((c) => c.toJson()).toList(),
    };
  }

  FeedbackReport copyWith({
    String? id,
    String? userId,
    FeedbackType? type,
    FeedbackCategory? category,
    String? title,
    String? description,
    FeedbackPriority? priority,
    List<String>? screenshots,
    Map<String, dynamic>? deviceInfo,
    String? appVersion,
    String? osVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    FeedbackStatus? status,
    int? votesCount,
    bool? hasVoted,
    List<String>? tags,
    String? developerResponse,
    DateTime? resolvedAt,
    List<FeedbackComment>? comments,
  }) {
    return FeedbackReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      screenshots: screenshots ?? this.screenshots,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      appVersion: appVersion ?? this.appVersion,
      osVersion: osVersion ?? this.osVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      votesCount: votesCount ?? this.votesCount,
      hasVoted: hasVoted ?? this.hasVoted,
      tags: tags ?? this.tags,
      developerResponse: developerResponse ?? this.developerResponse,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      comments: comments ?? this.comments,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    category,
    title,
    description,
    priority,
    screenshots,
    deviceInfo,
    appVersion,
    osVersion,
    createdAt,
    updatedAt,
    status,
    votesCount,
    hasVoted,
    tags,
    developerResponse,
    resolvedAt,
    comments,
  ];
}

/// Feedback comment for discussions
class FeedbackComment extends Equatable {
  const FeedbackComment({
    required this.id,
    required this.feedbackId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.content,
    required this.createdAt,
    required this.isOfficial,
  });

  factory FeedbackComment.fromJson(Map<String, dynamic> json) {
    return FeedbackComment(
      id: json['id'] as String,
      feedbackId: json['feedbackId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userRole: json['userRole'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isOfficial: json['isOfficial'] as bool,
    );
  }
  final String id;
  final String feedbackId;
  final String userId;
  final String userName;
  final String userRole; // 'user', 'developer', 'moderator'
  final String content;
  final DateTime createdAt;
  final bool isOfficial;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'feedbackId': feedbackId,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isOfficial': isOfficial,
    };
  }

  @override
  List<Object> get props => [
    id,
    feedbackId,
    userId,
    userName,
    userRole,
    content,
    createdAt,
    isOfficial,
  ];
}

/// Feature request model for new features
class FeatureRequest extends Equatable {
  const FeatureRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.votesCount,
    required this.hasVoted,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.tags,
    required this.comments,
    this.plannedFor,
    this.estimatedEffort,
    this.roadmapUrl,
  });

  factory FeatureRequest.fromJson(Map<String, dynamic> json) {
    return FeatureRequest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      votesCount: json['votesCount'] as int,
      hasVoted: json['hasVoted'] as bool,
      status: RequestStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RequestStatus.submitted,
      ),
      priority: RequestPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => RequestPriority.medium,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      plannedFor: json['plannedFor'] != null
          ? DateTime.parse(json['plannedFor'] as String)
          : null,
      estimatedEffort: json['estimatedEffort'] as String?,
      tags: List<String>.from(json['tags'] as List),
      comments:
          (json['comments'] as List<dynamic>?)
              ?.map((c) => FeedbackComment.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      roadmapUrl: json['roadmapUrl'] as String?,
    );
  }
  final String id;
  final String title;
  final String description;
  final String category;
  final int votesCount;
  final bool hasVoted;
  final RequestStatus status;
  final RequestPriority priority;
  final DateTime createdAt;
  final DateTime? plannedFor;
  final String? estimatedEffort;
  final List<String> tags;
  final List<FeedbackComment> comments;
  final String? roadmapUrl;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'votesCount': votesCount,
      'hasVoted': hasVoted,
      'status': status.name,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'plannedFor': plannedFor?.toIso8601String(),
      'estimatedEffort': estimatedEffort,
      'tags': tags,
      'comments': comments.map((c) => c.toJson()).toList(),
      'roadmapUrl': roadmapUrl,
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    votesCount,
    hasVoted,
    status,
    priority,
    createdAt,
    plannedFor,
    estimatedEffort,
    tags,
    comments,
    roadmapUrl,
  ];
}

extension FeatureRequestCopyWith on FeatureRequest {
  FeatureRequest copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? votesCount,
    bool? hasVoted,
    RequestStatus? status,
    RequestPriority? priority,
    DateTime? createdAt,
    DateTime? plannedFor,
    String? estimatedEffort,
    List<String>? tags,
    List<FeedbackComment>? comments,
    String? roadmapUrl,
  }) {
    return FeatureRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      votesCount: votesCount ?? this.votesCount,
      hasVoted: hasVoted ?? this.hasVoted,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      plannedFor: plannedFor ?? this.plannedFor,
      estimatedEffort: estimatedEffort ?? this.estimatedEffort,
      tags: tags ?? this.tags,
      comments: comments ?? this.comments,
      roadmapUrl: roadmapUrl ?? this.roadmapUrl,
    );
  }
}

/// Product roadmap item
class RoadmapItem extends Equatable {
  const RoadmapItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.category,
    required this.tags,
    required this.userVotes,
    required this.hasVoted,
    required this.features,
    this.plannedRelease,
    this.progress,
  });

  factory RoadmapItem.fromJson(Map<String, dynamic> json) {
    return RoadmapItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: RoadmapStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RoadmapStatus.planned,
      ),
      plannedRelease: json['plannedRelease'] != null
          ? DateTime.parse(json['plannedRelease'] as String)
          : null,
      category: json['category'] as String,
      tags: List<String>.from(json['tags'] as List),
      userVotes: json['userVotes'] as int,
      hasVoted: json['hasVoted'] as bool,
      progress: json['progress'] as String?,
      features: List<String>.from(json['features'] as List),
    );
  }
  final String id;
  final String title;
  final String description;
  final RoadmapStatus status;
  final DateTime? plannedRelease;
  final String category;
  final List<String> tags;
  final int userVotes;
  final bool hasVoted;
  final String? progress;
  final List<String> features;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'plannedRelease': plannedRelease?.toIso8601String(),
      'category': category,
      'tags': tags,
      'userVotes': userVotes,
      'hasVoted': hasVoted,
      'progress': progress,
      'features': features,
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    status,
    plannedRelease,
    category,
    tags,
    userVotes,
    hasVoted,
    progress,
    features,
  ];
}

extension RoadmapItemCopyWith on RoadmapItem {
  RoadmapItem copyWith({
    String? id,
    String? title,
    String? description,
    RoadmapStatus? status,
    DateTime? plannedRelease,
    String? category,
    List<String>? tags,
    int? userVotes,
    bool? hasVoted,
    String? progress,
    List<String>? features,
  }) {
    return RoadmapItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      plannedRelease: plannedRelease ?? this.plannedRelease,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      userVotes: userVotes ?? this.userVotes,
      hasVoted: hasVoted ?? this.hasVoted,
      progress: progress ?? this.progress,
      features: features ?? this.features,
    );
  }
}

/// Beta program enrollment
class BetaProgram extends Equatable {
  const BetaProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.isEnrolled,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.requirements,
    required this.benefits,
    required this.status,
    this.endDate,
  });

  factory BetaProgram.fromJson(Map<String, dynamic> json) {
    return BetaProgram(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isEnrolled: json['isEnrolled'] as bool,
      maxParticipants: json['maxParticipants'] as int,
      currentParticipants: json['currentParticipants'] as int,
      requirements: List<String>.from(json['requirements'] as List),
      benefits: List<String>.from(json['benefits'] as List),
      status: BetaStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => BetaStatus.planned,
      ),
    );
  }
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isEnrolled;
  final int maxParticipants;
  final int currentParticipants;
  final List<String> requirements;
  final List<String> benefits;
  final BetaStatus status;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isEnrolled': isEnrolled,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'requirements': requirements,
      'benefits': benefits,
      'status': status.name,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    startDate,
    endDate,
    isEnrolled,
    maxParticipants,
    currentParticipants,
    requirements,
    benefits,
    status,
  ];
}

extension BetaProgramCopyWith on BetaProgram {
  BetaProgram copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isEnrolled,
    int? maxParticipants,
    int? currentParticipants,
    List<String>? requirements,
    List<String>? benefits,
    BetaStatus? status,
  }) {
    return BetaProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      status: status ?? this.status,
    );
  }
}

/// Enums for feedback system
enum FeedbackType {
  bugReport,
  featureRequest,
  improvement,
  suggestion,
  compliment,
  complaint,
}

enum FeedbackCategory {
  general,
  ui,
  performance,
  functionality,
  accessibility,
  security,
  content,
  integration,
}

enum FeedbackPriority { low, medium, high, critical }

enum FeedbackStatus {
  submitted,
  underReview,
  inProgress,
  testing,
  resolved,
  rejected,
  archived,
}

enum RequestStatus {
  submitted,
  underReview,
  approved,
  inDevelopment,
  testing,
  released,
  rejected,
}

enum RequestPriority { low, medium, high, critical }

enum RoadmapStatus { planned, inProgress, testing, released, cancelled }

enum BetaStatus { planned, recruiting, active, ended }
