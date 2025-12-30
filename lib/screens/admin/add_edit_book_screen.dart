// File: lib/screens/admin/add_edit_book_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:printing/printing.dart';
// ĐÃ XÓA IMPORT THỪA pdf/pdf.dart

import '../../data/db/database_helper.dart';
import '../../data/models/book_model.dart';

class AddEditBookScreen extends StatefulWidget {
  final Book? book;
  const AddEditBookScreen({super.key, this.book});
  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _descController;
  late TextEditingController _qtyController;
  late TextEditingController _rentPriceController;
  late TextEditingController _buyPriceController;

  String _selectedCategory = "Công nghệ";
  final List<String> _categories = ["Công nghệ", "Văn học", "Kinh tế", "Thiếu nhi", "Ngoại ngữ", "Khác"];

  File? _imageFile;
  String? _pdfPath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book?.title ?? '');
    _authorController = TextEditingController(text: widget.book?.author ?? '');
    _descController = TextEditingController(text: widget.book?.description ?? '');
    _qtyController = TextEditingController(text: widget.book?.quantity.toString() ?? '');

    _rentPriceController = TextEditingController(text: widget.book?.rentPrice.toInt().toString() ?? '5000');
    _buyPriceController = TextEditingController(text: widget.book?.buyPrice.toInt().toString() ?? '50000');
    if (widget.book?.category != null && _categories.contains(widget.book!.category)) {
      _selectedCategory = widget.book!.category;
    }

    if (widget.book?.imagePath != null) _imageFile = File(widget.book!.imagePath!);
    _pdfPath = widget.book?.pdfPath;
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(picked.path);
        final saved = await File(picked.path).copy('${appDir.path}/$fileName');
        setState(() => _imageFile = saved);
      }
    } catch (e) {
      if (!mounted) return; // FIX ASYNC GAP
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi chọn ảnh: $e")));
    }
  }

  Future<void> _generateCoverFromPDF(File pdfFile) async {
    try {
      await for (var page in Printing.raster(await pdfFile.readAsBytes(), pages: [0], dpi: 72)) {
        final imageBytes = await page.toPng();
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = "cover_${DateTime.now().millisecondsSinceEpoch}.png";
        final imageFile = File('${appDir.path}/$fileName');
        await imageFile.writeAsBytes(imageBytes);
        setState(() { _imageFile = imageFile; });
        break;
      }
    } catch (e) {
      // Đã xóa print trong production code nếu muốn, hoặc để debug
    }
  }

  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (result != null) {
        File file = File(result.files.single.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(file.path);
        final saved = await file.copy('${appDir.path}/$fileName');
        setState(() => _pdfPath = saved.path);

        if (_imageFile == null) await _generateCoverFromPDF(saved);
      }
    } catch (e) {
      if (!mounted) return; // FIX ASYNC GAP
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi PDF: $e")));
    }
  }

  void _saveBook() async {
    if (_formKey.currentState!.validate()) {
      int qty = int.tryParse(_qtyController.text) ?? 0;
      // FIX BRACES
      if (_pdfPath != null && qty == 0) {
        qty = 9999;
      }

      final newBook = Book(
          id: widget.book?.id,
          title: _titleController.text,
          author: _authorController.text,
          description: _descController.text,
          quantity: qty,
          available: qty,
          imagePath: _imageFile?.path,
          pdfPath: _pdfPath,
          rentPrice: double.tryParse(_rentPriceController.text) ?? 0,
          buyPrice: double.tryParse(_buyPriceController.text) ?? 0,
          category: _selectedCategory
      );

      if (widget.book == null) {
        await DatabaseHelper.instance.addBook(newBook);
      } else {
        await DatabaseHelper.instance.updateBook(newBook);
      }

      if (!mounted) return; // FIX ASYNC GAP
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book == null ? "Thêm Sách" : "Sửa Sách")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                  child: _imageFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_imageFile!, fit: BoxFit.contain))
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.add_a_photo, size: 50), Text("Ảnh bìa (Tự động nếu chọn PDF)")]),
                ),
              ),
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _pdfPath != null ? Colors.green[50] : Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                child: Column(children: [
                  TextButton.icon(icon: const Icon(Icons.picture_as_pdf), label: Text(_pdfPath == null ? "Tải lên PDF" : "Đổi file PDF"), onPressed: _pickPDF),
                  if(_pdfPath != null) Text("Đã chọn: ${path.basename(_pdfPath!)}", style: const TextStyle(fontSize: 10)),
                ]),
              ),
              const SizedBox(height: 15),

              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: "Tên sách", border: OutlineInputBorder()), validator: (v)=>v!.isEmpty?'Nhập tên':null),
              const SizedBox(height: 10),
              TextFormField(controller: _authorController, decoration: const InputDecoration(labelText: "Tác giả", border: OutlineInputBorder()), validator: (v)=>v!.isEmpty?'Nhập tác giả':null),
              const SizedBox(height: 10),

              Row(children: [
                Expanded(child: TextFormField(controller: _rentPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Giá thuê", border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: _buyPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Giá mua", border: OutlineInputBorder()))),
              ]),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
                decoration: const InputDecoration(labelText: "Thể loại", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),

              if (_pdfPath == null)
                TextFormField(controller: _qtyController, decoration: const InputDecoration(labelText: "Số lượng kho", border: OutlineInputBorder()), keyboardType: TextInputType.number),

              const SizedBox(height: 10),
              TextFormField(controller: _descController, decoration: const InputDecoration(labelText: "Mô tả", border: OutlineInputBorder()), maxLines: 3),

              const SizedBox(height: 20),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                  onPressed: _saveBook,
                  child: const Text("LƯU SÁCH", style: TextStyle(fontWeight: FontWeight.bold))
              ),
            ],
          ),
        ),
      ),
    );
  }
}