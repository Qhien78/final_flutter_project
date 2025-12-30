import 'package:flutter/material.dart';
import '../data/db/database_helper.dart';
import '../data/models/book_model.dart';

class LibraryProvider extends ChangeNotifier {
  List<Book> _books = [];

  List<Book> get books => _books;

  Future<void> loadBooks() async {
    _books = await DatabaseHelper.instance.getAllBooks();
    notifyListeners();
  }

  // Sửa lỗi: Nhận vào Book object và gọi hàm addBook của DB
  Future<void> addBook(Book book) async {
    await DatabaseHelper.instance.addBook(book);
    await loadBooks();
  }

  Future<void> updateBook(Book book) async {
    await DatabaseHelper.instance.updateBook(book);
    await loadBooks();
  }

  Future<void> deleteBook(int id) async {
    await DatabaseHelper.instance.deleteBook(id);
    await loadBooks();
  }
}