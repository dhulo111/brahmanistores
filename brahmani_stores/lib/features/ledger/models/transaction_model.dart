class TransactionModel {
  final String id;
  final double amount;
  final String description;
  final String type; // 'UDHAR' or 'JAMA'
  final String userId;
  final DateTime createdAt;
  final String? userName;
  final String? userAvatar;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.description,
    required this.type,
    required this.userId,
    required this.createdAt,
    this.userName,
    this.userAvatar,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    String? name;
    String? avatar;
    if (json['user'] != null) {
      name = '${json['user']['firstName'] ?? ''} ${json['user']['lastName'] ?? ''}'.trim();
      avatar = json['user']['avatarUrl'];
    }

    return TransactionModel(
      id: json['id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']).toLocal() 
          : DateTime.now(),
      userName: name,
      userAvatar: avatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'type': type,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      if (userName != null) 'userName': userName,
      if (userAvatar != null) 'userAvatar': userAvatar,
    };
  }
}
