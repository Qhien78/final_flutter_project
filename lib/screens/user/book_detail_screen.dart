import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../data/db/database_helper.dart';
import '../../data/models/book_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/review_model.dart';
import 'read_book_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  final User currentUser;
  const BookDetailScreen({super.key, required this.book, required this.currentUser});
  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _commentController = TextEditingController();
  double _rating = 5.0;
  List<Map<String, dynamic>> _reviews = [];
  late Book _currentBook;
  bool _hasAccess = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _loadData();
    _checkFavorite();
  }

  void _loadData() async {
    _reviews = await DatabaseHelper.instance.getReviewsByBookId(widget.book.id!);
    bool owned = await DatabaseHelper.instance.hasUserBorrowedBook(widget.currentUser.id!, widget.book.id!);
    if (mounted) setState(() => _hasAccess = owned);
  }

  void _checkFavorite() async {
    bool fav = await DatabaseHelper.instance.isFavorite(widget.currentUser.id!, widget.book.id!);
    if (mounted) setState(() => _isFavorite = fav);
  }

  void _toggleFavorite() async {
    bool newState = await DatabaseHelper.instance.toggleFavorite(widget.currentUser.id!, widget.book.id!);
    if (!mounted) return;
    setState(() => _isFavorite = newState);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newState ? "Đã thêm yêu thích" : "Đã bỏ yêu thích")));
  }

  // HÀM XỬ LÝ ĐẶT HÀNG (KHI HẾT SÁCH)
  void _handleOrderQueue() async {
    final msg = await DatabaseHelper.instance.addToQueue(widget.currentUser.id!, _currentBook.id!);
    if(!mounted) return;
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Thông báo"),
          content: Text(msg),
          actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("Đóng"))],
        )
    );
  }

  void _showPaymentDialog(String type) {
    double price = type == 'rent' ? _currentBook.rentPrice : _currentBook.buyPrice;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userBalance = auth.currentUser!.balance;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(type == 'rent' ? "Thuê Sách" : "Mua Vĩnh Viễn"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Giá tiền: ${currencyFormat.format(price)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Số dư của bạn: "),
                Text(currencyFormat.format(userBalance), style: TextStyle(color: userBalance >= price ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            if (userBalance < price)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text("Thiếu ${currencyFormat.format(price - userBalance)} nữa. Hãy nạp thêm!", style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: userBalance >= price ? Colors.blue : Colors.grey, foregroundColor: Colors.white),
            onPressed: userBalance < price ? null : () async {
              Navigator.pop(dialogContext);
              String msg = await DatabaseHelper.instance.processTransaction(widget.currentUser.id!, _currentBook.id!, type);

              if (!mounted) return;
              if (msg == "OK") {
                await auth.reloadUser();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${type == 'rent' ? 'Thuê' : 'Mua'} thành công!"), backgroundColor: Colors.green));
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
              }
            },
            child: const Text("THANH TOÁN"),
          )
        ],
      ),
    );
  }

  void _submitReview() async {
    final review = Review(userId: widget.currentUser.id!, bookId: widget.book.id!, rating: _rating, comment: _commentController.text, date: DateTime.now().toIso8601String());
    await DatabaseHelper.instance.addReview(review);
    _commentController.clear(); _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    // Kiểm tra xem sách có hết hàng không (Sách giấy + Available = 0)
    bool isOutOfStock = !_currentBook.isEbook && _currentBook.available <= 0;

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết sách"), actions: [IconButton(icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red), onPressed: _toggleFavorite)]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 130, height: 190,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10)]),
              child: ClipRRect(borderRadius: BorderRadius.circular(10), child: _currentBook.imagePath != null ? Image.file(File(_currentBook.imagePath!), fit: BoxFit.cover) : const Icon(Icons.book)),
            ),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_currentBook.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(_currentBook.author, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 10),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(5)), child: Text(_currentBook.category, style: const TextStyle(color: Colors.blue))),
              const SizedBox(height: 10),

              // HIỂN THỊ TỒN KHO HOẶC HẾT HÀNG
              if (!_currentBook.isEbook)
                isOutOfStock
                    ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(5)), child: const Text("TẠM HẾT HÀNG", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
                    : Text("Kho: ${_currentBook.available} cuốn", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ]))
          ]),
          const SizedBox(height: 20),

          // KHU VỰC NÚT BẤM (Logic quan trọng)
          if (_hasAccess) ...[
            if (_currentBook.isEbook)
              ElevatedButton.icon(icon: const Icon(Icons.menu_book), label: const Text("ĐỌC SÁCH NGAY"), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ReadBookScreen(filePath: _currentBook.pdfPath!, title: _currentBook.title, bookId: _currentBook.id!, userId: widget.currentUser.id!)));
              })
            else
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)), child: const Center(child: Text("Bạn đang mượn sách giấy này. Hãy bảo quản tốt!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)))),
          ] else ...[
            // CHƯA MƯỢN
            if (isOutOfStock)
            // NẾU HẾT HÀNG -> HIỆN NÚT ĐẶT HÀNG
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.access_time_filled),
                  label: const Text("ĐẶT HÀNG KHI CÓ SÁCH"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                  onPressed: _handleOrderQueue,
                ),
              )
            else
            // CÒN HÀNG -> HIỆN NÚT MUA/THUÊ
              Row(children: [
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () => _showPaymentDialog('rent'),
                  child: Column(children: [const Text("THUÊ SÁCH"), Text(currencyFormat.format(_currentBook.rentPrice), style: const TextStyle(fontSize: 12))]),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () => _showPaymentDialog('buy'),
                  child: Column(children: [const Text("MUA VĨNH VIỄN"), Text(currencyFormat.format(_currentBook.buyPrice), style: const TextStyle(fontSize: 12))]),
                )),
              ]),
          ],

          const Divider(height: 30),
          const Text("Giới thiệu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(_currentBook.description, style: const TextStyle(color: Colors.grey)),

          const Divider(height: 30),
          const Text("Đánh giá", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if(_hasAccess) ...[
            RatingBar.builder(initialRating: 5, minRating: 1, direction: Axis.horizontal, itemCount: 5, itemSize: 20, itemBuilder: (c,_)=>const Icon(Icons.star, color: Colors.amber), onRatingUpdate: (r)=>_rating=r),
            TextField(controller: _commentController, decoration: const InputDecoration(hintText: "Viết cảm nhận...", suffixIcon: Icon(Icons.send)), onSubmitted: (_)=>_submitReview()),
          ],
          ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _reviews.length, itemBuilder: (context, index) {
            final r = _reviews[index];
            return ListTile(leading: CircleAvatar(child: Text(r['username'][0])), title: Text(r['username']), subtitle: Text(r['comment']), trailing: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star, size: 14, color: Colors.amber), Text(r['rating'].toString())]));
          })
        ],
      ),
    );
  }
}