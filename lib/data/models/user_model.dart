class User {
  final int? id;
  final String username;
  final String password;
  final String role; // 'admin' hoặc 'customer'
  final String? libraryCardId;
  final double balance; // MỚI: Số dư ví

  User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    this.libraryCardId,
    this.balance = 0.0, // Mặc định là 0 đồng
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'library_card_id': libraryCardId,
      'balance': balance, // Lưu số dư
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      role: map['role'],
      libraryCardId: map['library_card_id'],
      balance: map['balance'] != null ? (map['balance'] as num).toDouble() : 0.0,
    );
  }
}