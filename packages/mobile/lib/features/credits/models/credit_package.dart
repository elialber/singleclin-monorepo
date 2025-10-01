enum PackageType { starter, popular, value, premium }

class CreditPackage {
  CreditPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.credits,
    required this.price,
    required this.originalPrice,
    required this.discount,
    required this.isPopular,
    required this.isActive,
    this.isPromo = false,
    this.promoEndDate,
    this.promoDescription,
    required this.type,
    this.bonusFeatures,
    this.iconUrl,
  });

  factory CreditPackage.fromJson(Map<String, dynamic> json) {
    return CreditPackage(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      credits: json['credits'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      originalPrice: (json['originalPrice'] ?? 0.0).toDouble(),
      discount: (json['discount'] ?? 0.0).toDouble(),
      isPopular: json['isPopular'] ?? false,
      isActive: json['isActive'] ?? true,
      isPromo: json['isPromo'] ?? false,
      promoEndDate: json['promoEndDate'] != null
          ? DateTime.parse(json['promoEndDate'])
          : null,
      promoDescription: json['promoDescription'],
      type: PackageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => PackageType.starter,
      ),
      bonusFeatures: json['bonusFeatures'],
      iconUrl: json['iconUrl'],
    );
  }
  final String id;
  final String name;
  final String description;
  final int credits;
  final double price;
  final double originalPrice;
  final double discount;
  final bool isPopular;
  final bool isActive;
  final bool isPromo;
  final DateTime? promoEndDate;
  final String? promoDescription;
  final PackageType type;
  final Map<String, dynamic>? bonusFeatures;
  final String? iconUrl;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'credits': credits,
      'price': price,
      'originalPrice': originalPrice,
      'discount': discount,
      'isPopular': isPopular,
      'isActive': isActive,
      'isPromo': isPromo,
      'promoEndDate': promoEndDate?.toIso8601String(),
      'promoDescription': promoDescription,
      'type': type.toString().split('.').last,
      'bonusFeatures': bonusFeatures,
      'iconUrl': iconUrl,
    };
  }

  String get priceDisplay {
    return 'R\$ ${price.toStringAsFixed(2)}';
  }

  String get originalPriceDisplay {
    return 'R\$ ${originalPrice.toStringAsFixed(2)}';
  }

  String get discountDisplay {
    return '${discount.toInt()}% OFF';
  }

  double get creditValue {
    return price / credits;
  }

  String get creditValueDisplay {
    return 'R\$ ${creditValue.toStringAsFixed(2)}/crédito';
  }

  double get savings {
    return originalPrice - price;
  }

  String get savingsDisplay {
    return 'Economize R\$ ${savings.toStringAsFixed(2)}';
  }

  bool get hasDiscount => discount > 0;

  String get typeDisplayName {
    switch (type) {
      case PackageType.starter:
        return 'Iniciante';
      case PackageType.popular:
        return 'Popular';
      case PackageType.value:
        return 'Melhor Valor';
      case PackageType.premium:
        return 'Premium';
    }
  }

  bool get isPromoValid {
    if (!isPromo || promoEndDate == null) return false;
    return DateTime.now().isBefore(promoEndDate!);
  }

  int get promoTimeRemainingHours {
    if (!isPromoValid || promoEndDate == null) return 0;
    return promoEndDate!.difference(DateTime.now()).inHours;
  }

  String get promoTimeRemainingDisplay {
    if (!isPromoValid) return '';

    final remaining = promoEndDate!.difference(DateTime.now());
    if (remaining.inDays > 0) {
      return '${remaining.inDays} dias restantes';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h restantes';
    } else {
      return '${remaining.inMinutes}min restantes';
    }
  }
}

class PaymentMethod {
  PaymentMethod({
    required this.id,
    required this.type,
    required this.displayName,
    this.last4,
    this.brand,
    required this.isDefault,
    required this.isActive,
    this.expiryDate,
    required this.createdAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      displayName: json['displayName'] ?? '',
      last4: json['last4'],
      brand: json['brand'],
      isDefault: json['isDefault'] ?? false,
      isActive: json['isActive'] ?? true,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
  final String id;
  final String type; // 'credit_card', 'pix', 'apple_pay', 'google_pay'
  final String displayName;
  final String? last4; // for cards
  final String? brand; // visa, mastercard, etc
  final bool isDefault;
  final bool isActive;
  final DateTime? expiryDate;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'displayName': displayName,
      'last4': last4,
      'brand': brand,
      'isDefault': isDefault,
      'isActive': isActive,
      'expiryDate': expiryDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'credit_card':
        return 'Cartão de Crédito';
      case 'pix':
        return 'PIX';
      case 'apple_pay':
        return 'Apple Pay';
      case 'google_pay':
        return 'Google Pay';
      default:
        return type;
    }
  }

  bool get isCreditCard => type.toLowerCase() == 'credit_card';
  bool get isPix => type.toLowerCase() == 'pix';
  bool get isApplePay => type.toLowerCase() == 'apple_pay';
  bool get isGooglePay => type.toLowerCase() == 'google_pay';

  bool get isExpiring {
    if (expiryDate == null) return false;
    return expiryDate!.difference(DateTime.now()).inDays <= 30;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }
}
