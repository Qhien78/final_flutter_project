import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/db/database_helper.dart';
import '../../data/models/book_model.dart';
import '../auth/login_screen.dart';
import 'add_edit_book_screen.dart';
import 'admin_stats_screen.dart';
import 'admin_reservations_screen.dart'; // NHỚ IMPORT FILE VỪA TẠO

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Future<void> _refresh() async { setState(() {}); }
  void _deleteBook(int id) async { await DatabaseHelper.instance.deleteBook(id); _refresh(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản Trị Thư Viện"),
        actions: [
          // --- NÚT XEM ĐƠN ĐẶT HÀNG (MỚI) ---
          IconButton(
            icon: const Icon(Icons.assignment_late, color: Colors.deepPurple), // Icon màu tím
            tooltip: 'Đơn đặt hàng',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReservationsScreen())),
          ),
          // ----------------------------------

          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Thống kê',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStatsScreen())),
          ),
          IconButton(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Kho Sách Hiện Có", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            FutureBuilder<List<Book>>(
              future: DatabaseHelper.instance.getAllBooks(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.isEmpty) return const Text("Kho sách trống.");

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final book = snapshot.data![index];
                    return Card(
                      child: ListTile(
                        leading: book.imagePath != null
                            ? Image.file(File(book.imagePath!), width: 40, height: 60, fit: BoxFit.cover)
                            : const Icon(Icons.book, size: 40),
                        title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Tác giả: ${book.author}"),
                            if(book.isEbook)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                                child: const Text("E-Book", style: TextStyle(color: Colors.white, fontSize: 10)),
                              )
                            else
                              Text("Kho: ${book.available} | Thuê: ${book.rentPrice.toInt()}đ"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBook(book.id!),
                        ),
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditBookScreen(book: book)));
                          _refresh();
                        },
                      ),
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditBookScreen()));
          _refresh();
        },
      ),
    );
  }
}