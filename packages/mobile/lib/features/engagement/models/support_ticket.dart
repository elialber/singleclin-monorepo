import 'package:equatable/equatable.dart';

/// Support ticket model for customer support system
class SupportTicket extends Equatable {
  const SupportTicket({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.messages,
    required this.attachments,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.assignedAgentId,
    this.assignedAgentName,
    this.satisfactionRating,
    this.satisfactionComment,
    required this.tags,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: TicketCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => TicketCategory.general,
      ),
      priority: TicketPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TicketPriority.medium,
      ),
      status: TicketStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TicketStatus.open,
      ),
      messages: (json['messages'] as List<dynamic>)
          .map((m) => TicketMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      attachments: List<String>.from(json['attachments'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      assignedAgentId: json['assignedAgentId'] as String?,
      assignedAgentName: json['assignedAgentName'] as String?,
      satisfactionRating: json['satisfactionRating'] != null
          ? (json['satisfactionRating'] as num).toDouble()
          : null,
      satisfactionComment: json['satisfactionComment'] as String?,
      tags: List<String>.from(json['tags'] as List),
    );
  }
  final String id;
  final String userId;
  final String title;
  final String description;
  final TicketCategory category;
  final TicketPriority priority;
  final TicketStatus status;
  final List<TicketMessage> messages;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? assignedAgentId;
  final String? assignedAgentName;
  final double? satisfactionRating;
  final String? satisfactionComment;
  final List<String> tags;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category.name,
      'priority': priority.name,
      'status': status.name,
      'messages': messages.map((m) => m.toJson()).toList(),
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'assignedAgentId': assignedAgentId,
      'assignedAgentName': assignedAgentName,
      'satisfactionRating': satisfactionRating,
      'satisfactionComment': satisfactionComment,
      'tags': tags,
    };
  }

  SupportTicket copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TicketCategory? category,
    TicketPriority? priority,
    TicketStatus? status,
    List<TicketMessage>? messages,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? assignedAgentId,
    String? assignedAgentName,
    double? satisfactionRating,
    String? satisfactionComment,
    List<String>? tags,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      assignedAgentId: assignedAgentId ?? this.assignedAgentId,
      assignedAgentName: assignedAgentName ?? this.assignedAgentName,
      satisfactionRating: satisfactionRating ?? this.satisfactionRating,
      satisfactionComment: satisfactionComment ?? this.satisfactionComment,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    description,
    category,
    priority,
    status,
    messages,
    attachments,
    createdAt,
    updatedAt,
    resolvedAt,
    assignedAgentId,
    assignedAgentName,
    satisfactionRating,
    satisfactionComment,
    tags,
  ];
}

/// Ticket message for chat conversations
class TicketMessage extends Equatable {
  const TicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.attachments,
    required this.createdAt,
    required this.type,
    required this.isRead,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as String,
      ticketId: json['ticketId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderRole: json['senderRole'] as String,
      message: json['message'] as String,
      attachments: List<String>.from(json['attachments'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      type: MessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MessageType.text,
      ),
      isRead: json['isRead'] as bool,
    );
  }
  final String id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'user' or 'agent'
  final String message;
  final List<String> attachments;
  final DateTime createdAt;
  final MessageType type;
  final bool isRead;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'type': type.name,
      'isRead': isRead,
    };
  }

  TicketMessage copyWith({
    String? id,
    String? ticketId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? message,
    List<String>? attachments,
    DateTime? createdAt,
    MessageType? type,
    bool? isRead,
  }) {
    return TicketMessage(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      message: message ?? this.message,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object> get props => [
    id,
    ticketId,
    senderId,
    senderName,
    senderRole,
    message,
    attachments,
    createdAt,
    type,
    isRead,
  ];
}

/// Ticket categories
enum TicketCategory {
  general,
  technical,
  billing,
  appointment,
  credits,
  account,
  clinic,
  emergency,
}

/// Ticket priorities
enum TicketPriority { low, medium, high, urgent }

/// Ticket status
enum TicketStatus {
  open,
  inProgress,
  waitingForCustomer,
  resolved,
  closed,
  escalated,
}

/// Message types
enum MessageType { text, image, file, system, autoReply }

/// Chat session for live support
class ChatSession extends Equatable {
  const ChatSession({
    required this.id,
    required this.userId,
    this.agentId,
    this.agentName,
    required this.status,
    required this.messages,
    required this.createdAt,
    this.endedAt,
    required this.queuePosition,
    required this.topic,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      agentId: json['agentId'] as String?,
      agentName: json['agentName'] as String?,
      status: ChatStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ChatStatus.waiting,
      ),
      messages: (json['messages'] as List<dynamic>)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      queuePosition: json['queuePosition'] as int,
      topic: json['topic'] as String,
    );
  }
  final String id;
  final String userId;
  final String? agentId;
  final String? agentName;
  final ChatStatus status;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime? endedAt;
  final int queuePosition;
  final String topic;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'agentId': agentId,
      'agentName': agentName,
      'status': status.name,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'queuePosition': queuePosition,
      'topic': topic,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    agentId,
    agentName,
    status,
    messages,
    createdAt,
    endedAt,
    queuePosition,
    topic,
  ];
}

/// Chat message
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.senderType,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      senderId: json['senderId'] as String,
      senderType: json['senderType'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool,
    );
  }
  final String id;
  final String sessionId;
  final String senderId;
  final String senderType; // 'user', 'agent', 'system'
  final String message;
  final DateTime timestamp;
  final bool isRead;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'senderId': senderId,
      'senderType': senderType,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  @override
  List<Object> get props => [
    id,
    sessionId,
    senderId,
    senderType,
    message,
    timestamp,
    isRead,
  ];
}

/// Chat status
enum ChatStatus { waiting, active, ended, abandoned }
