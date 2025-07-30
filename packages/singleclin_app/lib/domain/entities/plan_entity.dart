/// Plan entity representing a healthcare plan
class PlanEntity {
  final int id;
  final String name;
  final String description;
  final int totalCredits;
  final double price;
  final int validityDays;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlanEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.totalCredits,
    required this.price,
    required this.validityDays,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  String toString() {
    return 'PlanEntity{id: $id, name: $name, totalCredits: $totalCredits, price: $price}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}