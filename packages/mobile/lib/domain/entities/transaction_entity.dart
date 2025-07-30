/// Transaction entity representing a healthcare service transaction
class TransactionEntity {
  final int id;
  final int userId;
  final int clinicId;
  final String clinicName;
  final String serviceType;
  final int creditsUsed;
  final double value;
  final String status;
  final String? notes;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.clinicId,
    required this.clinicName,
    required this.serviceType,
    required this.creditsUsed,
    required this.value,
    required this.status,
    this.notes,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if transaction is completed
  bool get isCompleted => status.toLowerCase() == 'completed';

  /// Check if transaction is pending
  bool get isPending => status.toLowerCase() == 'pending';

  /// Check if transaction is cancelled
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  /// Get formatted transaction date
  String get formattedDate {
    final date = transactionDate;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Get status color
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'green';
      case 'pending':
        return 'yellow';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  @override
  String toString() {
    return 'TransactionEntity{id: $id, clinicName: $clinicName, serviceType: $serviceType, creditsUsed: $creditsUsed}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}