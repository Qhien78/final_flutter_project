import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/db/database_helper.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(title: const Text("Thống Kê Chi Tiết")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. DOANH THU
            Card(
              color: Colors.green[50],
              child: ListTile(
                leading: const Icon(Icons.monetization_on, color: Colors.green, size: 40),
                title: const Text("Tổng Doanh Thu Phạt"),
                subtitle: FutureBuilder<double>(
                  future: DatabaseHelper.instance.getTotalIncome(),
                  builder: (context, snapshot) => Text(
                    currencyFormat.format(snapshot.data ?? 0),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 2. NGƯỜI DÙNG TÍCH CỰC
            Card(
              color: Colors.blue[50],
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.blue, size: 40),
                title: const Text("Độc giả tích cực nhất"),
                subtitle: FutureBuilder<String>(
                  future: DatabaseHelper.instance.getTopUser(),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? "Đang tải...",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 3. SÁCH HOT
            Card(
              color: Colors.orange[50],
              child: ListTile(
                leading: const Icon(Icons.local_fire_department, color: Colors.orange, size: 40),
                title: const Text("Sách mượn nhiều nhất"),
                subtitle: FutureBuilder<String>(
                  future: DatabaseHelper.instance.getMostBorrowedBook(),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? "Đang tải...",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 4. LƯỢT MƯỢN THÁNG
            Card(
              color: Colors.purple[50],
              child: ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.purple, size: 40),
                title: const Text("Lượt mượn tháng này"),
                subtitle: FutureBuilder<int>(
                  future: DatabaseHelper.instance.getMonthlyBorrowersCount(),
                  builder: (context, snapshot) => Text(
                    "${snapshot.data ?? 0} lượt",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}