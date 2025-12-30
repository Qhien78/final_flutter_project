import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/book_model.dart';
import '../models/review_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('library_v9_wallet.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL UNIQUE, password TEXT NOT NULL, role TEXT NOT NULL, library_card_id TEXT UNIQUE, balance REAL DEFAULT 0)');
    await db.execute('CREATE TABLE books (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, author TEXT NOT NULL, description TEXT, image_path TEXT, pdf_path TEXT, quantity INTEGER NOT NULL, available INTEGER NOT NULL, rent_price REAL DEFAULT 0, buy_price REAL DEFAULT 0, category TEXT)');
    await db.execute('CREATE TABLE loans (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, book_id INTEGER NOT NULL, loan_date TEXT NOT NULL, due_date TEXT NOT NULL, return_date TEXT, status TEXT NOT NULL, fine_paid REAL DEFAULT 0, type TEXT DEFAULT "rent", FOREIGN KEY (user_id) REFERENCES users (id), FOREIGN KEY (book_id) REFERENCES books (id))');
    await db.execute('CREATE TABLE reviews (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, book_id INTEGER NOT NULL, rating REAL NOT NULL, comment TEXT, date TEXT, parent_id INTEGER, FOREIGN KEY (user_id) REFERENCES users (id), FOREIGN KEY (book_id) REFERENCES books (id))');
    await db.execute('CREATE TABLE favorites (user_id INTEGER, book_id INTEGER, PRIMARY KEY (user_id, book_id))');
    await db.execute('CREATE TABLE reservations (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, book_id INTEGER, created_at TEXT, status TEXT)');
    await db.execute('CREATE TABLE reading_progress (user_id INTEGER, book_id INTEGER, current_page INTEGER, total_pages INTEGER, last_read_time TEXT, PRIMARY KEY (user_id, book_id))');

    await db.insert('users', User(username: 'admin', password: '123', role: 'admin', libraryCardId: 'ADMIN-001', balance: 999999999).toMap());
  }
// --- LOGIC ADMIN: QUẢN LÝ ĐẶT HÀNG ---

  // 1. Lấy tất cả đơn đặt hàng đang chờ
  Future<List<Map<String, dynamic>>> getAllReservations() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT reservations.id, reservations.created_at, 
             users.username, users.library_card_id, 
             books.title, books.image_path, books.id as book_id
      FROM reservations
      JOIN users ON reservations.user_id = users.id
      JOIN books ON reservations.book_id = books.id
      WHERE reservations.status = 'waiting'
      ORDER BY reservations.created_at ASC
    ''');
  }

  // 2. Xử lý xong đơn hàng (Xóa khỏi danh sách chờ)

  // --- LOGIC ĐẶT HÀNG (QUEUE) ---
  Future<String> addToQueue(int userId, int bookId) async {
    final db = await instance.database;

    // Kiểm tra xem đã đặt trước đó chưa
    final ex = await db.query('reservations', where: 'user_id=? AND book_id=? AND status="waiting"', whereArgs: [userId, bookId]);
    if(ex.isNotEmpty) return "Bạn đã đăng ký chờ cuốn này rồi.";

    // Kiểm tra xem đang mượn cuốn này không (đang mượn thì ko cho đặt thêm)
    final borrowing = await db.rawQuery("SELECT * FROM loans WHERE user_id = ? AND book_id = ? AND status = 'borrowing'", [userId, bookId]);
    if(borrowing.isNotEmpty) return "Bạn đang giữ cuốn này rồi.";

    await db.insert('reservations', {
      'user_id': userId,
      'book_id': bookId,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'waiting'
    });

    return "Đã đăng ký! Khi có sách chúng tôi sẽ báo.";
  }

  // --- CÁC HÀM GIAO DỊCH KHÁC ---
  Future<String> processTransaction(int userId, int bookId, String type) async {
    final db = await instance.database;
    final bookRes = await db.query('books', where: 'id = ?', whereArgs: [bookId]);
    if (bookRes.isEmpty) return "Sách không tồn tại";
    final book = Book.fromMap(bookRes.first);
    double price = type == 'rent' ? book.rentPrice : book.buyPrice;

    final userRes = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    final user = User.fromMap(userRes.first);

    // Check kho sách giấy
    if (!book.isEbook && book.available <= 0) {
      return "Sách giấy đã hết hàng.";
    }

    if (user.balance < price) return "Số dư không đủ! Cần thêm ${price - user.balance}đ.";

    final active = await db.rawQuery("SELECT * FROM loans WHERE user_id = ? AND book_id = ? AND status = 'borrowing'", [userId, bookId]);
    if (active.isNotEmpty) return "Bạn đang sở hữu/thuê cuốn này rồi!";

    try {
      await db.transaction((txn) async {
        await txn.rawUpdate('UPDATE users SET balance = balance - ? WHERE id = ?', [price, userId]);
        if (!book.isEbook) {
          await txn.rawUpdate('UPDATE books SET available = available - 1 WHERE id = ?', [bookId]);
        }
        DateTime dueDate = type == 'buy' ? DateTime.now().add(const Duration(days: 36500)) : DateTime.now().add(const Duration(days: 30));
        await txn.insert('loans', {'user_id': userId, 'book_id': bookId, 'loan_date': DateTime.now().toIso8601String(), 'due_date': dueDate.toIso8601String(), 'status': 'borrowing', 'type': type, 'fine_paid': price});
      });
      return "OK";
    } catch (e) { return "Lỗi: $e"; }
  }
// --- LOGIC MỚI: QUY TRÌNH ĐẶT HÀNG - DUYỆT - THANH TOÁN ---

  // 1. Lấy danh sách đơn hàng CỦA USER (để hiện bên Tủ sách)
  Future<List<Map<String, dynamic>>> getUserReservations(int userId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT reservations.id, reservations.status, reservations.created_at,
             books.title, books.author, books.image_path, books.id as book_id,
             books.rent_price, books.buy_price
      FROM reservations
      JOIN books ON reservations.book_id = books.id
      WHERE reservations.user_id = ?
      ORDER BY reservations.created_at DESC
    ''', [userId]);
  }

  // 2. Admin DUYỆT đơn (Chuyển sang trạng thái chờ thanh toán)
  Future<void> approveReservation(int id) async {
    final db = await instance.database;
    await db.update('reservations', {'status': 'approved'}, where: 'id = ?', whereArgs: [id]);
  }

  // 3. Xóa đơn hàng (Dùng cho cả Admin từ chối hoặc User hủy, hoặc sau khi thanh toán xong)
  Future<void> deleteReservation(int id) async {
    final db = await instance.database;
    await db.delete('reservations', where: 'id = ?', whereArgs: [id]);
  }

  // --- CÁC HÀM CƠ BẢN GIỮ NGUYÊN ---
  Future<int> register(User user) async { final db = await instance.database; return await db.insert('users', user.toMap()); }
  Future<User?> login(String username, String password) async { final db = await instance.database; final res = await db.query('users', where: 'username = ? AND password = ?', whereArgs: [username, password]); return res.isNotEmpty ? User.fromMap(res.first) : null; }
  Future<User?> getUserById(int id) async { final db = await instance.database; final res = await db.query('users', where: 'id = ?', whereArgs: [id]); return res.isNotEmpty ? User.fromMap(res.first) : null; }
  Future<void> depositMoney(int userId, double amount) async { final db = await instance.database; await db.rawUpdate('UPDATE users SET balance = balance + ? WHERE id = ?', [amount, userId]); }
  Future<bool> resetPassword(String username, String cardId, String newPass) async { final db = await instance.database; final res = await db.query('users', where: 'username = ? AND library_card_id = ?', whereArgs: [username, cardId]); if (res.isNotEmpty) { await db.update('users', {'password': newPass}, where: 'username = ?', whereArgs: [username]); return true; } return false; }
  Future<void> returnBook(int loanId, int bookId) async { final db = await instance.database; final loanRes = await db.query('loans', where: 'id = ?', whereArgs: [loanId]); if(loanRes.isEmpty) return; String type = loanRes.first['type'] as String; await db.transaction((txn) async { await txn.update('loans', {'status': 'returned', 'return_date': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [loanId]); if (type == 'rent') { final bookRes = await txn.query('books', where: 'id=?', whereArgs: [bookId]); final book = Book.fromMap(bookRes.first); if (!book.isEbook) { await txn.rawUpdate('UPDATE books SET available = available + 1 WHERE id = ?', [bookId]); } } }); }
  Future<int> addBook(Book book) async { final db = await instance.database; return await db.insert('books', book.toMap()); }
  Future<int> updateBook(Book book) async { final db = await instance.database; return await db.update('books', book.toMap(), where: 'id = ?', whereArgs: [book.id]); }
  Future<int> deleteBook(int id) async { final db = await instance.database; return await db.delete('books', where: 'id=?', whereArgs: [id]); }
  Future<List<Book>> getAllBooks() async { final db = await instance.database; final res = await db.query('books'); return res.map((e)=>Book.fromMap(e)).toList(); }
  Future<String> addReview(Review review) async { final db = await instance.database; if(review.parentId == null) { final ex = await db.rawQuery('SELECT COUNT(*) FROM reviews WHERE user_id=? AND book_id=? AND parent_id IS NULL', [review.userId, review.bookId]); if(Sqflite.firstIntValue(ex)! > 0) return "Chỉ được đánh giá 1 lần."; } await db.insert('reviews', review.toMap()); return "OK"; }
  Future<List<Map<String, dynamic>>> getReviewsByBookId(int bookId) async { final db = await instance.database; return await db.rawQuery('SELECT reviews.*, users.username FROM reviews INNER JOIN users ON reviews.user_id = users.id WHERE book_id = ? ORDER BY date DESC', [bookId]); }
  Future<bool> hasUserBorrowedBook(int userId, int bookId) async { final db = await instance.database; final res = await db.rawQuery("SELECT COUNT(*) FROM loans WHERE user_id = ? AND book_id = ? AND status='borrowing'", [userId, bookId]); return Sqflite.firstIntValue(res)! > 0; }
  Future<bool> toggleFavorite(int userId, int bookId) async { final db = await instance.database; final ex = await db.query('favorites', where: 'user_id=? AND book_id=?', whereArgs: [userId, bookId]); if(ex.isNotEmpty) { await db.delete('favorites', where: 'user_id=? AND book_id=?', whereArgs: [userId, bookId]); return false; } else { await db.insert('favorites', {'user_id': userId, 'book_id': bookId}); return true; } }
  Future<bool> isFavorite(int userId, int bookId) async { final db = await instance.database; return (await db.query('favorites', where: 'user_id=? AND book_id=?', whereArgs: [userId, bookId])).isNotEmpty; }
  Future<void> saveReadingProgress(int userId, int bookId, int page, int total) async { final db = await instance.database; await db.insert('reading_progress', {'user_id': userId, 'book_id': bookId, 'current_page': page, 'total_pages': total, 'last_read_time': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace); }
  Future<int> getLastReadPage(int userId, int bookId) async { final db = await instance.database; final res = await db.query('reading_progress', columns: ['current_page'], where: 'user_id = ? AND book_id = ?', whereArgs: [userId, bookId]); if (res.isNotEmpty) return res.first['current_page'] as int; return 0; }
  Future<List<Map<String, dynamic>>> getUserLoans(int userId, String status) async { final db = await instance.database; return await db.rawQuery('SELECT books.*, loans.id as loan_id, loans.due_date, loans.loan_date, loans.return_date, loans.fine_paid, loans.type FROM loans JOIN books ON loans.book_id = books.id WHERE loans.user_id = ? AND loans.status = ? ORDER BY loans.loan_date DESC', [userId, status]); }
  Future<List<Book>> getUserFavorites(int userId) async { final db = await instance.database; final res = await db.rawQuery('SELECT books.* FROM favorites JOIN books ON favorites.book_id = books.id WHERE favorites.user_id = ?', [userId]); return res.map((e) => Book.fromMap(e)).toList(); }
  Future<double> getTotalIncome() async { final db = await instance.database; final res = await db.rawQuery('SELECT SUM(fine_paid) as total FROM loans'); return res.first['total'] != null ? (res.first['total'] as num).toDouble() : 0.0; }
  Future<List<Map<String, dynamic>>> getTopUsers() async { final db = await instance.database; return await db.rawQuery('SELECT users.username, users.library_card_id, COUNT(loans.id) as loan_count FROM loans JOIN users ON loans.user_id = users.id GROUP BY users.id ORDER BY loan_count DESC LIMIT 5'); }
  Future<int> getMonthlyBorrowersCount() async { final db = await instance.database; String currentMonth = DateTime.now().toIso8601String().substring(0, 7); final res = await db.rawQuery("SELECT COUNT(*) FROM loans WHERE loan_date LIKE '$currentMonth%'"); return Sqflite.firstIntValue(res) ?? 0; }
  Future<String> getMostPopularCategory() async { return "Sách Giáo Khoa"; }
  Future<String> getMostBorrowedBook() async { final list = await getTopBorrowedBooksWeek(); if (list.isNotEmpty) return list.first.title; return "Chưa có"; }
  Future<String> getMostReadBook() async { return await getMostBorrowedBook(); }
  Future<String> getTopUser() async { final list = await getTopUsers(); if (list.isNotEmpty) return list.first['username'] as String; return "Chưa có"; }
  Future<List<Book>> getTopBorrowedBooksWeek() async { final db = await instance.database; final res = await db.rawQuery('SELECT books.*, COUNT(loans.id) as count FROM loans JOIN books ON loans.book_id = books.id GROUP BY books.id ORDER BY count DESC LIMIT 5'); return res.map((e) => Book.fromMap(e)).toList(); }
}