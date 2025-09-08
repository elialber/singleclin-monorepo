import 'package:equatable/equatable.dart';

/// FAQ Item model for frequently asked questions
class FaqItem extends Equatable {
  final String id;
  final String question;
  final String answer;
  final FaqCategory category;
  final List<String> tags;
  final int viewCount;
  final int helpfulCount;
  final int notHelpfulCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int sortOrder;
  final bool isPublished;
  final List<String> relatedQuestions;
  final String? videoUrl;
  final List<String> attachments;

  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.tags,
    required this.viewCount,
    required this.helpfulCount,
    required this.notHelpfulCount,
    required this.createdAt,
    this.updatedAt,
    required this.sortOrder,
    required this.isPublished,
    required this.relatedQuestions,
    this.videoUrl,
    required this.attachments,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      category: FaqCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => FaqCategory.general,
      ),
      tags: List<String>.from(json['tags'] as List),
      viewCount: json['viewCount'] as int,
      helpfulCount: json['helpfulCount'] as int,
      notHelpfulCount: json['notHelpfulCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      sortOrder: json['sortOrder'] as int,
      isPublished: json['isPublished'] as bool,
      relatedQuestions: List<String>.from(json['relatedQuestions'] as List),
      videoUrl: json['videoUrl'] as String?,
      attachments: List<String>.from(json['attachments'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category.name,
      'tags': tags,
      'viewCount': viewCount,
      'helpfulCount': helpfulCount,
      'notHelpfulCount': notHelpfulCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'sortOrder': sortOrder,
      'isPublished': isPublished,
      'relatedQuestions': relatedQuestions,
      'videoUrl': videoUrl,
      'attachments': attachments,
    };
  }

  FaqItem copyWith({
    String? id,
    String? question,
    String? answer,
    FaqCategory? category,
    List<String>? tags,
    int? viewCount,
    int? helpfulCount,
    int? notHelpfulCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sortOrder,
    bool? isPublished,
    List<String>? relatedQuestions,
    String? videoUrl,
    List<String>? attachments,
  }) {
    return FaqItem(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      viewCount: viewCount ?? this.viewCount,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      notHelpfulCount: notHelpfulCount ?? this.notHelpfulCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      isPublished: isPublished ?? this.isPublished,
      relatedQuestions: relatedQuestions ?? this.relatedQuestions,
      videoUrl: videoUrl ?? this.videoUrl,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  List<Object?> get props => [
        id,
        question,
        answer,
        category,
        tags,
        viewCount,
        helpfulCount,
        notHelpfulCount,
        createdAt,
        updatedAt,
        sortOrder,
        isPublished,
        relatedQuestions,
        videoUrl,
        attachments,
      ];
}

/// FAQ Categories
enum FaqCategory {
  general,
  sgCredits,
  appointments,
  payments,
  account,
  clinics,
  services,
  technical,
  privacy,
  policies
}

/// FAQ Search Result
class FaqSearchResult extends Equatable {
  final List<FaqItem> items;
  final String searchTerm;
  final int totalCount;
  final Map<FaqCategory, int> categoryCount;
  final List<String> suggestions;

  const FaqSearchResult({
    required this.items,
    required this.searchTerm,
    required this.totalCount,
    required this.categoryCount,
    required this.suggestions,
  });

  factory FaqSearchResult.fromJson(Map<String, dynamic> json) {
    return FaqSearchResult(
      items: (json['items'] as List<dynamic>)
          .map((item) => FaqItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      searchTerm: json['searchTerm'] as String,
      totalCount: json['totalCount'] as int,
      categoryCount: Map<FaqCategory, int>.fromEntries(
        (json['categoryCount'] as Map<String, dynamic>).entries.map(
          (entry) => MapEntry(
            FaqCategory.values.firstWhere((c) => c.name == entry.key),
            entry.value as int,
          ),
        ),
      ),
      suggestions: List<String>.from(json['suggestions'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'searchTerm': searchTerm,
      'totalCount': totalCount,
      'categoryCount': Map<String, int>.fromEntries(
        categoryCount.entries.map(
          (entry) => MapEntry(entry.key.name, entry.value),
        ),
      ),
      'suggestions': suggestions,
    };
  }

  @override
  List<Object> get props => [
        items,
        searchTerm,
        totalCount,
        categoryCount,
        suggestions,
      ];
}

/// Chatbot Response
class ChatbotResponse extends Equatable {
  final String id;
  final String message;
  final List<String> suggestions;
  final List<FaqItem> relatedFaqs;
  final bool needsHumanSupport;
  final double confidence;
  final String intent;

  const ChatbotResponse({
    required this.id,
    required this.message,
    required this.suggestions,
    required this.relatedFaqs,
    required this.needsHumanSupport,
    required this.confidence,
    required this.intent,
  });

  factory ChatbotResponse.fromJson(Map<String, dynamic> json) {
    return ChatbotResponse(
      id: json['id'] as String,
      message: json['message'] as String,
      suggestions: List<String>.from(json['suggestions'] as List),
      relatedFaqs: (json['relatedFaqs'] as List<dynamic>)
          .map((faq) => FaqItem.fromJson(faq as Map<String, dynamic>))
          .toList(),
      needsHumanSupport: json['needsHumanSupport'] as bool,
      confidence: (json['confidence'] as num).toDouble(),
      intent: json['intent'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'suggestions': suggestions,
      'relatedFaqs': relatedFaqs.map((faq) => faq.toJson()).toList(),
      'needsHumanSupport': needsHumanSupport,
      'confidence': confidence,
      'intent': intent,
    };
  }

  @override
  List<Object> get props => [
        id,
        message,
        suggestions,
        relatedFaqs,
        needsHumanSupport,
        confidence,
        intent,
      ];
}

/// FAQ Statistics
class FaqStats extends Equatable {
  final int totalItems;
  final int totalViews;
  final int helpfulVotes;
  final int notHelpfulVotes;
  final Map<FaqCategory, int> categoryViews;
  final List<FaqItem> topViewed;
  final List<FaqItem> mostHelpful;
  final double avgHelpfulRating;

  const FaqStats({
    required this.totalItems,
    required this.totalViews,
    required this.helpfulVotes,
    required this.notHelpfulVotes,
    required this.categoryViews,
    required this.topViewed,
    required this.mostHelpful,
    required this.avgHelpfulRating,
  });

  factory FaqStats.fromJson(Map<String, dynamic> json) {
    return FaqStats(
      totalItems: json['totalItems'] as int,
      totalViews: json['totalViews'] as int,
      helpfulVotes: json['helpfulVotes'] as int,
      notHelpfulVotes: json['notHelpfulVotes'] as int,
      categoryViews: Map<FaqCategory, int>.fromEntries(
        (json['categoryViews'] as Map<String, dynamic>).entries.map(
          (entry) => MapEntry(
            FaqCategory.values.firstWhere((c) => c.name == entry.key),
            entry.value as int,
          ),
        ),
      ),
      topViewed: (json['topViewed'] as List<dynamic>)
          .map((item) => FaqItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      mostHelpful: (json['mostHelpful'] as List<dynamic>)
          .map((item) => FaqItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      avgHelpfulRating: (json['avgHelpfulRating'] as num).toDouble(),
    );
  }

  @override
  List<Object> get props => [
        totalItems,
        totalViews,
        helpfulVotes,
        notHelpfulVotes,
        categoryViews,
        topViewed,
        mostHelpful,
        avgHelpfulRating,
      ];
}