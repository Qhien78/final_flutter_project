import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final auth = Provider.of<AuthProvider>(context, listen: false);

      // --- SỬA LỖI TẠI ĐÂY: CHỈ TRUYỀN 2 THAM SỐ ---
      // (Bỏ tham số thứ 3 nếu có)
      final success = await auth.register(_userController.text, _passController.text);
      // ---------------------------------------------

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đăng ký thành công! Hãy đăng nhập."),
              backgroundColor: Colors.green,
            )
        );
        Navigator.pop(context); // Quay về màn hình đăng nhập
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Tên tài khoản đã tồn tại!"),
              backgroundColor: Colors.red,
            )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Nền gradient
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade800, Colors.blue.shade200],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "ĐĂNG KÝ",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 10),
                      Text("Tạo tài khoản thư viện", style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 30),

                      // User Input
                      TextFormField(
                        controller: _userController,
                        decoration: InputDecoration(
                          labelText: "Tên đăng nhập",
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (v) => v!.isEmpty ? "Không được để trống" : null,
                      ),
                      const SizedBox(height: 20),

                      // Password Input
                      TextFormField(
                        controller: _passController,
                        obscureText: _obscurePass,
                        decoration: InputDecoration(
                          labelText: "Mật khẩu",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (v) => v!.length < 3 ? "Mật khẩu quá ngắn" : null,
                      ),
                      const SizedBox(height: 20),

                      // Confirm Password Input
                      TextFormField(
                        controller: _confirmPassController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: "Xác nhận mật khẩu",
                          prefixIcon: const Icon(Icons.verified_user), // Đã sửa icon hợp lệ
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (v) {
                          if (v != _passController.text) return "Mật khẩu không khớp";
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),

                      // Button
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 5,
                          ),
                          child: const Text("TẠO TÀI KHOẢN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Đã có tài khoản? Đăng nhập ngay"),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}