import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/db/database_helper.dart';

class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({super.key});

  @override
  State<AdminReservationsScreen> createState() => _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {

  // Admin DUYỆT đơn -> Chuyển trạng thái sang 'approved' để user thanh toán
  void _approveOrder(int id) async {
    await DatabaseHelper.instance.approveReservation(id);
    _refresh();
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã duyệt! Đợi khách thanh toán."), backgroundColor: Colors.green));
  }

  // Admin TỪ CHỐI/XÓA đơn
  void _rejectOrder(int id) async {
    await DatabaseHelper.instance.deleteReservation(id);
    _refresh();
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa đơn hàng."), backgroundColor: Colors.red));
  }

  void _refresh() { setState(() {}); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản Lý Đơn Đặt Hàng")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getAllReservations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final list = snapshot.data!;
          if (list.isEmpty) return const Center(child: Text("Không có đơn chờ duyệt.", style: TextStyle(color: Colors.grey)));

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Card(
                elevation: 3, margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: item['image_path'] != null
                      ? Image.file(File(item['image_path']), width: 40, height: 60, fit: BoxFit.cover)
                      : const Icon(Icons.book, size: 40),
                  title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${item['username']} - ${item['created_at'].substring(0,10)}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nút Xóa
                      IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _rejectOrder(item['id'])),
                      // Nút Duyệt
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () => _approveOrder(item['id']),
                        child: const Text("DUYỆT"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}