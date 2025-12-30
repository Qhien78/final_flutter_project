import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart'; // Để format tiền
import '../../providers/auth_provider.dart';
import '../../data/db/database_helper.dart';
import '../../data/models/book_model.dart';
import '../auth/login_screen.dart';
import 'book_detail_screen.dart';
import 'my_library_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});
  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String _searchQuery = "";
  String _selectedCategory = "Tất cả";
  final List<String> _categories = ["Tất cả", "Công nghệ", "Văn học", "Kinh tế", "Thiếu nhi", "Ngoại ngữ", "Khác"];

  // HÀM NẠP TIỀN
  // HÀM NẠP TIỀN ĐÃ SỬA LỖI ASYNC GAP
  // HÀM NẠP TIỀN ĐÃ SỬA LỖI ASYNC GAP
  void _showDepositDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog( // Đổi tên biến context thành dialogContext để tránh nhầm
        title: const Text("Nạp Ngân Lượng"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Nhập số tiền (VNĐ)", border: OutlineInputBorder(), suffixText: "đ"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              double? amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                // Lưu AuthProvider ra biến cục bộ trước khi await
                final auth = Provider.of<AuthProvider>(context, listen: false);

                // Xử lý Database
                await DatabaseHelper.instance.depositMoney(auth.currentUser!.id!, amount);
                await auth.reloadUser();

                // Kiểm tra mounted chuẩn xác trước khi dùng context
                if (!context.mounted) return;

                Navigator.pop(dialogContext); // Đóng dialog
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã nạp thành công ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount)}")));
              }
            },
            child: const Text("NẠP NGAY"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // HEADER CẢI TIẾN
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]
              ),
              child: Column(
                children: [
                  Row(children: [
                    CircleAvatar(backgroundColor: Colors.blue, child: Text(user?.username[0].toUpperCase() ?? "U", style: const TextStyle(color: Colors.white))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("Xin chào, ${user?.username}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Mã thẻ: ${user?.libraryCardId}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ]),
                    ),
                    // NÚT DARK MODE
                    IconButton(
                      icon: Icon(auth.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                      onPressed: () => auth.toggleTheme(),
                    ),
                    IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () {
                      auth.logout();
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    }),
                  ]),
                  const SizedBox(height: 15),

                  // CARD VÍ TIỀN
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade400]),
                        borderRadius: BorderRadius.circular(15)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text("Số dư khả dụng", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(currencyFormat.format(user?.balance ?? 0), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ]),
                        ElevatedButton.icon(
                          onPressed: () => _showDepositDialog(context),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text("NẠP TIỀN"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                        hintText: "Tìm sách, tác giả...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true, fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 0)
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Sách Hot 🔥", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), TextButton(onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>MyLibraryScreen(userId: user!.id!))), child: const Text("Tủ sách của tôi >"))])),

                    FutureBuilder<List<Book>>(
                      future: DatabaseHelper.instance.getTopBorrowedBooksWeek(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox(height: 50, child: Center(child: Text("Chưa có dữ liệu nổi bật")));
                        return CarouselSlider(
                          options: CarouselOptions(height: 180.0, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.8),
                          items: snapshot.data!.map((book) {
                            return GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(book: book, currentUser: user!))),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  image: DecorationImage(image: book.imagePath != null ? FileImage(File(book.imagePath!)) : const AssetImage('assets/placeholder.png') as ImageProvider, fit: BoxFit.cover),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent])),
                                  padding: const EdgeInsets.all(10),
                                  alignment: Alignment.bottomLeft,
                                  child: Text(book.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = cat == _selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (v) => setState(() => _selectedCategory = cat),
                              backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                              selectedColor: Colors.blue,
                              labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!)),
                            ),
                          );
                        },
                      ),
                    ),

                    FutureBuilder<List<Book>>(
                      future: DatabaseHelper.instance.getAllBooks(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        var books = snapshot.data!;
                        books = books.where((b) {
                          final matchQuery = b.title.toLowerCase().contains(_searchQuery) || b.author.toLowerCase().contains(_searchQuery);
                          final matchCat = _selectedCategory == "Tất cả" || b.category == _selectedCategory;
                          return matchQuery && matchCat;
                        }).toList();

                        if (books.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Không tìm thấy sách nào.")));

                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 15, mainAxisSpacing: 15),
                          itemCount: books.length,
                          itemBuilder: (context, index) {
                            final book = books[index];
                            return GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(book: book, currentUser: user!))),
                              child: Container(
                                decoration: BoxDecoration(color: isDark ? Colors.grey[800] : Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      child: book.imagePath != null ? Image.file(File(book.imagePath!), width: double.infinity, fit: BoxFit.cover) : const Icon(Icons.book, size: 50),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text("${currencyFormat.format(book.rentPrice)} /thuê", style: const TextStyle(color: Colors.orange, fontSize: 11)),
                                    ]),
                                  )
                                ]),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}