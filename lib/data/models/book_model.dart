class Book {
  final int? id;
  final String title;
  final String author;
  final String description;
  final String? imagePath;
  final String? pdfPath;
  final int quantity;
  final int available;

  // CÁC TRƯỜNG MỚI
  final double rentPrice; // Giá thuê
  final double buyPrice;  // Giá mua đứt
  final String category;  // Thể loại

  Book({
    this.id,
    required this.title,
    required this.author,
    required this.description,
    this.imagePath,
    this.pdfPath,
    required this.quantity,
    required this.available,
    required this.rentPrice,
    required this.buyPrice,
    required this.category,
  });

  bool get isEbook => pdfPath != null && pdfPath!.isNotEmpty;
  String? get filePath => pdfPath;
  String? get coverImage => imagePath;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'image_path': imagePath,
      'pdf_path': pdfPath,
      'quantity': quantity,
      'available': available,
      'rent_price': rentPrice,
      'buy_price': buyPrice,
      'category': category,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      description: map['description'] ?? '',
      imagePath: map['image_path'],
      pdfPath: map['pdf_path'],
      quantity: map['quantity'],
      available: map['available'],
      // Nếu null thì mặc định là 0 hoặc "Khác"
      rentPrice: map['rent_price'] != null ? (map['rent_price'] as num).toDouble() : 0.0,
      buyPrice: map['buy_price'] != null ? (map['buy_price'] as num).toDouble() : 0.0,
      category: map['category'] ?? 'Khác',
    );
  }
}