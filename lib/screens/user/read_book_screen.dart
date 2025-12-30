import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../../data/db/database_helper.dart';

class ReadBookScreen extends StatefulWidget {
  final String filePath;
  final String title;
  final int bookId;
  final int userId;

  const ReadBookScreen({super.key, required this.filePath, required this.title, required this.bookId, required this.userId});

  @override
  State<ReadBookScreen> createState() => _ReadBookScreenState();
}

class _ReadBookScreenState extends State<ReadBookScreen> {
  final Completer<PDFViewController> _controller = Completer<PDFViewController>();
  int _initialPage = 0;
  bool _isReady = false; // Biến kiểm tra đã lấy được trang cũ chưa
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadLastPage();
  }

  // Bước 1: Lấy trang cũ từ Database trước
  Future<void> _loadLastPage() async {
    int savedPage = await DatabaseHelper.instance.getLastReadPage(widget.userId, widget.bookId);
    if (mounted) {
      setState(() {
        _initialPage = savedPage;
        _currentPage = savedPage;
        _isReady = true; // Đã sẵn sàng hiển thị PDF
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nếu chưa lấy được trang cũ thì hiện vòng xoay, ĐỪNG hiện PDF vội (tránh hiện trang 0)
    if (!_isReady) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Center(child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text("Trang ${_currentPage + 1}/$_totalPages", style: const TextStyle(fontWeight: FontWeight.bold)),
          ))
        ],
      ),
      body: PDFView(
        filePath: widget.filePath,
        defaultPage: _initialPage, // Mở đúng trang đã lưu
        enableSwipe: true,
        swipeHorizontal: true, // Vuốt ngang cho giống sách thật
        autoSpacing: false,
        pageFling: true,
        onRender: (pages) {
          setState(() => _totalPages = pages!);
        },
        onViewCreated: (PDFViewController pdfViewController) {
          _controller.complete(pdfViewController);
        },
        onPageChanged: (int? page, int? total) {
          if (page != null) {
            setState(() => _currentPage = page);
            // Lưu trang hiện tại vào DB
            DatabaseHelper.instance.saveReadingProgress(widget.userId, widget.bookId, page, total ?? 0);
          }
        },
        onError: (error) => Center(child: Text(error.toString())),
      ),
    );
  }
}