class SubscriptionStatus {
  bool subIsActive;
  String status;
  String activePriceId;

  SubscriptionStatus({
    required this.subIsActive,
    required this.status,
    required this.activePriceId,
  });

  /// 🔥 Convertir depuis Firestore
  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      subIsActive: json['subIsActive'] ?? false,
      status: json['status'] ?? '',
      activePriceId: json['activePriceId'] ?? '',
    );
  }

  /// 🔥 Convertir en JSON pour Firestore
  Map<String, dynamic> toJson() {
    return {
      'subIsActive': subIsActive,
      'status': status,
      'activePriceId': activePriceId,
    };
  }
}
