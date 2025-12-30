import 'package:flutter/material.dart';
import '../../data/db/database_helper.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameController = TextEditingController();
  final _cardIdController = TextEditingController();
  final _newPassController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _handleReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      bool success = await DatabaseHelper.instance.resetPassword(
          _usernameController.text,
          _cardIdController.text,
          _newPassController.text
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đổi mật khẩu thành công! Hãy đăng nhập lại."), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thông tin sai! Vui lòng kiểm tra Tên & Mã thẻ."), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Khôi Phục Mật Khẩu")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Nhập thông tin xác minh", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "Tên đăng nhập", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? "Nhập tên đăng nhập" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _cardIdController,
                decoration: const InputDecoration(labelText: "Mã thẻ thư viện (VD: LIB-123...)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
                validator: (v) => v!.isEmpty ? "Nhập mã thẻ" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _newPassController,
                decoration: const InputDecoration(labelText: "Mật khẩu mới", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                obscureText: true,
                validator: (v) => v!.length < 3 ? "Mật khẩu quá ngắn" : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleReset,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: _isLoading ? const CircularProgressIndicator() : const Text("ĐẶT LẠI MẬT KHẨU"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}