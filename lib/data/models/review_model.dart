class Review {
  final int? id;
  final int userId;
  final int bookId;
  final double rating;
  final String comment;
  final String date;
  final int? parentId; // MỚI: ID của comment cha (nếu là trả lời)

  Review({
    this.id, required this.userId, required this.bookId,
    required this.rating, required this.comment, required this.date,
    this.parentId, // MỚI
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'user_id': userId, 'book_id': bookId, 'rating': rating,
      'comment': comment, 'date': date, 'parent_id': parentId // MỚI
    };
  }

  // Factory giữ nguyên, thêm parentId vào
  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'], userId: map['user_id'], bookId: map['book_id'],
      rating: map['rating'], comment: map['comment'], date: map['date'],
      parentId: map['parent_id'],
    );
  }
}