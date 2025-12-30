import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart'; // Import AuthProvider
import '../../data/db/database_helper.dart';
import '../../data/models/book_model.dart';
import 'read_book_screen.dart';

class MyLibraryScreen extends StatefulWidget {
  final int userId;
  const MyLibraryScreen({super.key, required this.userId});
  @override
  State<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // NÂNG CẤP: Tăng lên 5 Tab (Thêm tab Đang Đặt)
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tủ Sách Của Tôi"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "Đang Đặt"),  // TAB MỚI: QUẢN LÝ ĐƠN HÀNG
            Tab(text: "Đang Thuê"),
            Tab(text: "Đã Mua"),
            Tab(text: "Lịch Sử"),
            Tab(text: "Yêu Thích"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReservationList(), // Hàm mới xử lý đơn hàng
          _buildLoanList('borrowing', filterType: 'rent'),
          _buildLoanList('borrowing', filterType: 'buy'),
          _buildLoanList('returned', filterType: null),
          _buildFavoriteList(),
        ],
      ),
    );
  }

  // --- TAB 1: QUẢN LÝ ĐƠN ĐẶT HÀNG ---
  Widget _buildReservationList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getUserReservations(widget.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Bạn không có đơn đặt hàng nào.", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            bool isApproved = item['status'] == 'approved';

            return Card(
              child: ListTile(
                leading: item['image_path'] != null
                    ? Image.file(File(item['image_path']), width: 40, fit: BoxFit.cover)
                    : const Icon(Icons.book),
                title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Ngày đặt: ${item['created_at'].substring(0,10)}"),
                    // TRẠNG THÁI ĐƠN HÀNG
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: isApproved ? Colors.green[100] : Colors.orange[100],
                          borderRadius: BorderRadius.circular(5)
                      ),
                      child: Text(
                        isApproved ? "Đã duyệt - Chờ thanh toán" : "Đang chờ Admin duyệt",
                        style: TextStyle(color: isApproved ? Colors.green[800] : Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    )
                  ],
                ),
                trailing: isApproved
                    ? ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: const Text("Thanh toán"),
                  onPressed: () => _showPaymentForReservation(item),
                )
                    : IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  tooltip: "Hủy đơn",
                  onPressed: () async {
                    await DatabaseHelper.instance.deleteReservation(item['id']);
                    setState(() {});
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // POPUP THANH TOÁN CHO ĐƠN ĐẶT HÀNG
  void _showPaymentForReservation(Map<String, dynamic> item) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    double userBalance = auth.currentUser!.balance;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Thanh toán đơn hàng"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sách: ${item['title']}"),
            const SizedBox(height: 10),
            const Text("Chọn hình thức:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Nút chọn Thuê hoặc Mua
            Row(
              children: [
                Expanded(child: _payButton(dialogContext, "Thuê", item['rent_price'], item, auth, "rent")),
                const SizedBox(width: 10),
                Expanded(child: _payButton(dialogContext, "Mua", item['buy_price'], item, auth, "buy")),
              ],
            ),
            const SizedBox(height: 15),
            Text("Số dư ví: ${currencyFormat.format(userBalance)}", style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _payButton(BuildContext dialogCtx, String label, double price, Map<String, dynamic> item, AuthProvider auth, String type) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    bool enoughMoney = auth.currentUser!.balance >= price;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: enoughMoney ? (type == 'rent' ? Colors.orange : Colors.blue) : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10)
      ),
      onPressed: enoughMoney ? () async {
        Navigator.pop(dialogCtx); // Đóng popup chọn

        // 1. Thực hiện giao dịch (Trừ tiền, trừ kho, thêm vào loans)
        String msg = await DatabaseHelper.instance.processTransaction(widget.userId, item['book_id'], type);

        if (msg == "OK") {
          // 2. Nếu thành công -> XÓA ĐƠN ĐẶT HÀNG
          await DatabaseHelper.instance.deleteReservation(item['id']);
          await auth.reloadUser(); // Cập nhật tiền

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thanh toán thành công! Sách đã vào tủ."), backgroundColor: Colors.green));
          setState(() {}); // Refresh lại giao diện
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
        }
      } : null, // Không đủ tiền thì disable
      child: Column(children: [
        Text(label),
        Text(currencyFormat.format(price), style: const TextStyle(fontSize: 10))
      ]),
    );
  }

  // --- CÁC TAB CŨ (GIỮ NGUYÊN) ---
  Widget _buildLoanList(String status, {String? filterType}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getUserLoans(widget.userId, status),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var list = snapshot.data!;
        if (filterType != null) list = list.where((item) => item['type'] == filterType).toList();
        if (list.isEmpty) return const Center(child: Text("Trống", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            final book = Book.fromMap(item);
            final type = item['type'];
            bool isOverdue = false;
            if (type == 'rent' && item['due_date'] != null) {
              try { isOverdue = DateTime.now().isAfter(DateTime.parse(item['due_date'])); } catch (_) {}
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: book.imagePath != null ? Image.file(File(book.imagePath!), width: 40, fit: BoxFit.cover) : const Icon(Icons.book),
                title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (status == 'returned') Text("Đã trả: ${item['return_date']?.substring(0, 10)}")
                  else if (type == 'buy') const Text("Sở hữu vĩnh viễn", style: TextStyle(color: Colors.blue))
                  else Text(isOverdue ? "QUÁ HẠN" : "Hạn: ${item['due_date']?.substring(0, 10)}", style: TextStyle(color: isOverdue ? Colors.red : Colors.orange))
                ]),
                trailing: (status == 'borrowing' && book.isEbook)
                    ? IconButton(icon: const Icon(Icons.menu_book, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReadBookScreen(filePath: book.pdfPath!, title: book.title, bookId: book.id!, userId: widget.userId))))
                    : (status == 'borrowing' && type == 'rent')
                    ? IconButton(icon: const Icon(Icons.assignment_return, color: Colors.red), onPressed: () async {
                  await DatabaseHelper.instance.returnBook(item['loan_id'], book.id!);
                  setState(() {});
                  if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã trả sách!")));
                })
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoriteList() {
    return FutureBuilder<List<Book>>(
      future: DatabaseHelper.instance.getUserFavorites(widget.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Chưa có"));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final book = snapshot.data![index];
            return Card(child: ListTile(leading: book.imagePath != null ? Image.file(File(book.imagePath!), width: 40) : const Icon(Icons.favorite), title: Text(book.title), subtitle: Text(book.author), trailing: const Icon(Icons.favorite, color: Colors.red)));
          },
        );
      },
    );
  }
}