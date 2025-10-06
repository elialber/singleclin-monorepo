/// Enum defining different box types for organized data storage
enum BoxType {
  /// User profiles and authentication data
  users,

  /// Clinic information and details
  clinics,

  /// Treatment plans and packages
  plans,

  /// User-plan relationships and remaining credits
  userPlans,

  /// Transaction history and credit usage
  transactions,

  /// QR codes for clinic visits (temporary cache)
  qrCodes,

  /// Appointment bookings and history
  appointments,

  /// Credit purchase and usage history
  creditHistory,

  /// User favorites (clinics, services, etc.)
  favorites,

  /// Search results and query cache
  searchCache,

  /// Cache metadata (timestamps, versions, etc.)
  metadata,

  /// Pending operations for offline sync
  operationQueue,

  /// User preferences and app settings
  preferences,
}

/// Base interface for cacheable entities
abstract class CacheableEntity {
  String get cacheKey;
  Map<String, dynamic> toJson();
  DateTime get lastModified;

  /// Priority for cache retention (higher = keep longer)
  int get cachePriority => 1;

  /// Whether this entity should be available offline
  bool get isOfflineCapable => true;

  /// Maximum age in hours before considered stale
  int get maxAgeHours => 24;
}

/// Metadata for cached items
class CacheMetadata {
  CacheMetadata({
    required this.key,
    required this.cachedAt,
    required this.lastAccessed,
    required this.accessCount, required this.entityType, required this.size, this.expiresAt,
    this.customData,
  });

  factory CacheMetadata.fromJson(Map<String, dynamic> json) {
    return CacheMetadata(
      key: json['key'] as String,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      lastAccessed: DateTime.parse(json['lastAccessed'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      accessCount: json['accessCount'] as int,
      entityType: json['entityType'] as String,
      size: json['size'] as int,
      customData: json['customData'] as Map<String, dynamic>?,
    );
  }
  final String key;
  final DateTime cachedAt;
  final DateTime lastAccessed;
  final DateTime? expiresAt;
  final int accessCount;
  final String entityType;
  final int size; // Approximate size in bytes
  final Map<String, dynamic>? customData;

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'cachedAt': cachedAt.toIso8601String(),
      'lastAccessed': lastAccessed.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'accessCount': accessCount,
      'entityType': entityType,
      'size': size,
      'customData': customData,
    };
  }

  /// Create updated metadata with new access
  CacheMetadata accessed() {
    return CacheMetadata(
      key: key,
      cachedAt: cachedAt,
      lastAccessed: DateTime.now(),
      expiresAt: expiresAt,
      accessCount: accessCount + 1,
      entityType: entityType,
      size: size,
      customData: customData,
    );
  }

  /// Check if cache entry is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if cache entry is stale (not accessed recently)
  bool get isStale {
    const stalePeriod = Duration(days: 7); // Consider stale after 7 days
    return DateTime.now().difference(lastAccessed) > stalePeriod;
  }

  /// Calculate cache score for eviction decisions (higher = keep)
  double get cacheScore {
    const ageWeight = 0.3;
    const accessWeight = 0.4;
    const sizeWeight = 0.3;

    // Normalize values (0-1)
    final ageDays = DateTime.now().difference(cachedAt).inDays;
    final ageScore = 1.0 - (ageDays / 30.0).clamp(0.0, 1.0); // Newer = better

    final accessScore = (accessCount / 100.0).clamp(
      0.0,
      1.0,
    ); // More access = better

    final sizeScore =
        1.0 - (size / 100000.0).clamp(0.0, 1.0); // Smaller = better

    return (ageScore * ageWeight) +
        (accessScore * accessWeight) +
        (sizeScore * sizeWeight);
  }
}

/// Cache operation types for queue
enum CacheOperation { create, update, delete, sync }

/// Pending operation for offline queue
class PendingOperation {
  PendingOperation({
    required this.id,
    required this.operation,
    required this.boxType,
    required this.entityKey,
    required this.createdAt, this.data,
    this.retryCount = 0,
    this.lastRetryAt,
    this.errorMessage,
    this.metadata,
  });

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'] as String,
      operation: CacheOperation.values.firstWhere(
        (op) => op.name == json['operation'],
      ),
      boxType: BoxType.values.firstWhere(
        (type) => type.name == json['boxType'],
      ),
      entityKey: json['entityKey'] as String,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      lastRetryAt: json['lastRetryAt'] != null
          ? DateTime.parse(json['lastRetryAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  final String id;
  final CacheOperation operation;
  final BoxType boxType;
  final String entityKey;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? lastRetryAt;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation': operation.name,
      'boxType': boxType.name,
      'entityKey': entityKey,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'lastRetryAt': lastRetryAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }

  /// Create a copy with retry information
  PendingOperation withRetry(String? error) {
    return PendingOperation(
      id: id,
      operation: operation,
      boxType: boxType,
      entityKey: entityKey,
      data: data,
      createdAt: createdAt,
      retryCount: retryCount + 1,
      lastRetryAt: DateTime.now(),
      errorMessage: error,
      metadata: metadata,
    );
  }

  /// Check if operation should be retried
  bool get shouldRetry {
    const maxRetries = 5;
    if (retryCount >= maxRetries) return false;

    // Exponential backoff: wait longer between retries
    if (lastRetryAt != null) {
      final backoffMinutes = [1, 5, 15, 60, 240][retryCount.clamp(0, 4)];
      final nextRetryTime = lastRetryAt!.add(Duration(minutes: backoffMinutes));
      return DateTime.now().isAfter(nextRetryTime);
    }

    return true;
  }

  /// Get next retry time
  DateTime? get nextRetryTime {
    if (!shouldRetry || lastRetryAt == null) return null;

    final backoffMinutes = [1, 5, 15, 60, 240][retryCount.clamp(0, 4)];
    return lastRetryAt!.add(Duration(minutes: backoffMinutes));
  }
}

/// Search cache entry
class SearchCacheEntry {
  SearchCacheEntry({
    required this.query,
    required this.filters,
    required this.results,
    required this.cachedAt,
    required this.totalResults,
    required this.queryDuration,
  });

  factory SearchCacheEntry.fromJson(Map<String, dynamic> json) {
    return SearchCacheEntry(
      query: json['query'] as String,
      filters: json['filters'] as Map<String, dynamic>,
      results: List<Map<String, dynamic>>.from(json['results']),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      totalResults: json['totalResults'] as int,
      queryDuration: Duration(milliseconds: json['queryDurationMs'] as int),
    );
  }
  final String query;
  final Map<String, dynamic> filters;
  final List<Map<String, dynamic>> results;
  final DateTime cachedAt;
  final int totalResults;
  final Duration queryDuration;

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'filters': filters,
      'results': results,
      'cachedAt': cachedAt.toIso8601String(),
      'totalResults': totalResults,
      'queryDurationMs': queryDuration.inMilliseconds,
    };
  }

  /// Generate cache key for this search
  String get cacheKey {
    final filtersString = filters.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');
    return 'search_${query}_$filtersString'.hashCode.toString();
  }

  /// Check if search cache is still valid
  bool get isValid {
    const maxAge = Duration(minutes: 30); // Search cache valid for 30 minutes
    return DateTime.now().difference(cachedAt) < maxAge;
  }
}
