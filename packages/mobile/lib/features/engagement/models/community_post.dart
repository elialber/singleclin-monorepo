import 'package:equatable/equatable.dart';

/// Community post model for user interactions
class CommunityPost extends Equatable {
  const CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.title,
    required this.content,
    required this.type,
    required this.group,
    required this.images,
    required this.tags,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.isLikedByMe,
    required this.isBookmarked,
    required this.createdAt,
    required this.status,
    required this.comments,
    required this.isAnonymous,
    required this.visibility,
    this.updatedAt,
    this.clinicId,
    this.clinicName,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: PostType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PostType.experience,
      ),
      group: CommunityGroup.values.firstWhere(
        (g) => g.name == json['group'],
        orElse: () => CommunityGroup.general,
      ),
      images: List<String>.from(json['images'] as List),
      tags: List<String>.from(json['tags'] as List),
      likesCount: json['likesCount'] as int,
      commentsCount: json['commentsCount'] as int,
      sharesCount: json['sharesCount'] as int,
      isLikedByMe: json['isLikedByMe'] as bool,
      isBookmarked: json['isBookmarked'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      status: PostStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PostStatus.published,
      ),
      comments:
          (json['comments'] as List<dynamic>?)
              ?.map((c) => PostComment.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      isAnonymous: json['isAnonymous'] as bool,
      visibility: PostVisibility.values.firstWhere(
        (v) => v.name == json['visibility'],
        orElse: () => PostVisibility.public,
      ),
      clinicId: json['clinicId'] as String?,
      clinicName: json['clinicName'] as String?,
    );
  }
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String title;
  final String content;
  final PostType type;
  final CommunityGroup group;
  final List<String> images;
  final List<String> tags;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLikedByMe;
  final bool isBookmarked;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final PostStatus status;
  final List<PostComment> comments;
  final bool isAnonymous;
  final PostVisibility visibility;
  final String? clinicId;
  final String? clinicName;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'title': title,
      'content': content,
      'type': type.name,
      'group': group.name,
      'images': images,
      'tags': tags,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'isLikedByMe': isLikedByMe,
      'isBookmarked': isBookmarked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status.name,
      'comments': comments.map((c) => c.toJson()).toList(),
      'isAnonymous': isAnonymous,
      'visibility': visibility.name,
      'clinicId': clinicId,
      'clinicName': clinicName,
    };
  }

  CommunityPost copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? title,
    String? content,
    PostType? type,
    CommunityGroup? group,
    List<String>? images,
    List<String>? tags,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLikedByMe,
    bool? isBookmarked,
    DateTime? createdAt,
    DateTime? updatedAt,
    PostStatus? status,
    List<PostComment>? comments,
    bool? isAnonymous,
    PostVisibility? visibility,
    String? clinicId,
    String? clinicName,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      group: group ?? this.group,
      images: images ?? this.images,
      tags: tags ?? this.tags,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      comments: comments ?? this.comments,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      visibility: visibility ?? this.visibility,
      clinicId: clinicId ?? this.clinicId,
      clinicName: clinicName ?? this.clinicName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    userAvatar,
    title,
    content,
    type,
    group,
    images,
    tags,
    likesCount,
    commentsCount,
    sharesCount,
    isLikedByMe,
    isBookmarked,
    createdAt,
    updatedAt,
    status,
    comments,
    isAnonymous,
    visibility,
    clinicId,
    clinicName,
  ];
}

/// Post comment model
class PostComment extends Equatable {
  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.images,
    required this.likesCount,
    required this.isLikedByMe,
    required this.createdAt,
    required this.isAnonymous,
    required this.replies,
    this.updatedAt,
    this.parentCommentId,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] as String,
      postId: json['postId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String,
      content: json['content'] as String,
      images: List<String>.from(json['images'] as List),
      likesCount: json['likesCount'] as int,
      isLikedByMe: json['isLikedByMe'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isAnonymous: json['isAnonymous'] as bool,
      parentCommentId: json['parentCommentId'] as String?,
      replies:
          (json['replies'] as List<dynamic>?)
              ?.map((r) => PostComment.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final List<String> images;
  final int likesCount;
  final bool isLikedByMe;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isAnonymous;
  final String? parentCommentId;
  final List<PostComment> replies;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'images': images,
      'likesCount': likesCount,
      'isLikedByMe': isLikedByMe,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isAnonymous': isAnonymous,
      'parentCommentId': parentCommentId,
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    postId,
    userId,
    userName,
    userAvatar,
    content,
    images,
    likesCount,
    isLikedByMe,
    createdAt,
    updatedAt,
    isAnonymous,
    parentCommentId,
    replies,
  ];
}

/// Community event model
class CommunityEvent extends Equatable {
  const CommunityEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.speakers,
    required this.tags,
    required this.attendeesCount,
    required this.maxAttendees,
    required this.isAttending,
    required this.isReminder,
    required this.status,
    required this.materials,
    this.location,
    this.meetingLink,
    this.recordingUrl,
  });

  factory CommunityEvent.fromJson(Map<String, dynamic> json) {
    return CommunityEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: EventType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => EventType.webinar,
      ),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      location: json['location'] as String?,
      meetingLink: json['meetingLink'] as String?,
      speakers: List<String>.from(json['speakers'] as List),
      tags: List<String>.from(json['tags'] as List),
      attendeesCount: json['attendeesCount'] as int,
      maxAttendees: json['maxAttendees'] as int,
      isAttending: json['isAttending'] as bool,
      isReminder: json['isReminder'] as bool,
      status: EventStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => EventStatus.upcoming,
      ),
      recordingUrl: json['recordingUrl'] as String?,
      materials: List<String>.from(json['materials'] as List),
    );
  }
  final String id;
  final String title;
  final String description;
  final EventType type;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? meetingLink;
  final List<String> speakers;
  final List<String> tags;
  final int attendeesCount;
  final int maxAttendees;
  final bool isAttending;
  final bool isReminder;
  final EventStatus status;
  final String? recordingUrl;
  final List<String> materials;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'meetingLink': meetingLink,
      'speakers': speakers,
      'tags': tags,
      'attendeesCount': attendeesCount,
      'maxAttendees': maxAttendees,
      'isAttending': isAttending,
      'isReminder': isReminder,
      'status': status.name,
      'recordingUrl': recordingUrl,
      'materials': materials,
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    type,
    startTime,
    endTime,
    location,
    meetingLink,
    speakers,
    tags,
    attendeesCount,
    maxAttendees,
    isAttending,
    isReminder,
    status,
    recordingUrl,
    materials,
  ];
}

extension CommunityEventCopyWith on CommunityEvent {
  CommunityEvent copyWith({
    String? id,
    String? title,
    String? description,
    EventType? type,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? meetingLink,
    List<String>? speakers,
    List<String>? tags,
    int? attendeesCount,
    int? maxAttendees,
    bool? isAttending,
    bool? isReminder,
    EventStatus? status,
    String? recordingUrl,
    List<String>? materials,
  }) {
    return CommunityEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      meetingLink: meetingLink ?? this.meetingLink,
      speakers: speakers ?? this.speakers,
      tags: tags ?? this.tags,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      isAttending: isAttending ?? this.isAttending,
      isReminder: isReminder ?? this.isReminder,
      status: status ?? this.status,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      materials: materials ?? this.materials,
    );
  }
}

/// Enums for community functionality
enum PostType {
  experience,
  question,
  tip,
  beforeAfter,
  recommendation,
  story,
  review,
}

enum CommunityGroup {
  general,
  aestheticFacial,
  injectableTherapies,
  diagnostics,
  performanceHealth,
  weightLoss,
  skincare,
  antiAging,
  wellness,
}

enum PostStatus { draft, published, archived, flagged, removed }

enum PostVisibility { public, groupOnly, followers, private }

enum EventType { webinar, live, workshop, meetup, consultation, qa }

enum EventStatus { upcoming, live, ended, cancelled }

/// Community statistics
class CommunityStats extends Equatable {
  const CommunityStats({
    required this.totalMembers,
    required this.postsThisWeek,
    required this.myPostsCount,
    required this.myCommentsCount,
    required this.myLikesReceived,
    required this.groupActivity,
    required this.topContributors,
    required this.engagementScore,
  });

  factory CommunityStats.fromJson(Map<String, dynamic> json) {
    return CommunityStats(
      totalMembers: json['totalMembers'] as int,
      postsThisWeek: json['postsThisWeek'] as int,
      myPostsCount: json['myPostsCount'] as int,
      myCommentsCount: json['myCommentsCount'] as int,
      myLikesReceived: json['myLikesReceived'] as int,
      groupActivity: Map<CommunityGroup, int>.fromEntries(
        (json['groupActivity'] as Map<String, dynamic>).entries.map(
          (entry) => MapEntry(
            CommunityGroup.values.firstWhere((g) => g.name == entry.key),
            entry.value as int,
          ),
        ),
      ),
      topContributors: List<String>.from(json['topContributors'] as List),
      engagementScore: json['engagementScore'] as int,
    );
  }
  final int totalMembers;
  final int postsThisWeek;
  final int myPostsCount;
  final int myCommentsCount;
  final int myLikesReceived;
  final Map<CommunityGroup, int> groupActivity;
  final List<String> topContributors;
  final int engagementScore;

  @override
  List<Object> get props => [
    totalMembers,
    postsThisWeek,
    myPostsCount,
    myCommentsCount,
    myLikesReceived,
    groupActivity,
    topContributors,
    engagementScore,
  ];
}
