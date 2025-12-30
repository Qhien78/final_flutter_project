import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_home_screen.dart';
import '../user/customer_home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart'; // MỚI

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  void _handleLogin() async {
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin")));
      return;
    }
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(_userController.text, _passController.text);
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => auth.isAdmin ? const AdminHomeScreen() : const CustomerHomeScreen()));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tài khoản hoặc mật khẩu không đúng!"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.blue.shade900, Colors.blue.shade500]),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))]), child: const Icon(Icons.local_library_rounded, size: 80, color: Colors.blue)),
                const SizedBox(height: 30),
                const Text("THƯ VIỆN SAY-GEX", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                const SizedBox(height: 40),
                Card(
                  elevation: 10, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      children: [
                        TextField(controller: _userController, decoration: InputDecoration(labelText: "Tài khoản", prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                        const SizedBox(height: 20),
                        TextField(controller: _passController, obscureText: _obscureText, decoration: InputDecoration(labelText: "Mật khẩu", prefixIcon: const Icon(Icons.lock), suffixIcon: IconButton(icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureText = !_obscureText)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),

                        // NÚT QUÊN MẬT KHẨU
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                            child: const Text("Quên mật khẩu?"),
                          ),
                        ),

                        const SizedBox(height: 10),
                        _isLoading ? const CircularProgressIndicator() : SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _handleLogin, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("ĐĂNG NHẬP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                        const SizedBox(height: 20),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("Chưa có tài khoản?"), TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text("Đăng ký ngay", style: TextStyle(fontWeight: FontWeight.bold)))])
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}