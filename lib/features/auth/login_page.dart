import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
 
  // State untuk visibilitas password
  bool _obsecurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void handleLogin() async {
    if (isLoading) return;

    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;

    if (_usernameController.text == "admin" &&
        _passwordController.text == "admin") {
      setState(() => isLoading = false);
        showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.transparent,
            builder: (ctx) => Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Login Berhasil',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14
                            )
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username / Password salah"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF134684)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 64,
                    offset: const Offset(0, 32),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      if (isDesktop)
                        Expanded(
                          child: Container(
                            color: const Color(0xFFEFF4FF),
                            padding: const EdgeInsets.fromLTRB(48, 32, 48, 48),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset(
                                  'assets/images/logo_pelindo.png',
                                  height: 100,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Vendor Contract &\nPayment Monitoring",
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF002753),
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    image: const DecorationImage(
                                      image: NetworkImage(
                                          'https://2.bp.blogspot.com/-x_4WoVCXjBQ/VnjGaWlW2eI/AAAAAAAAACs/mbgi0MF1QLs/s1600/Pelabuhan-Indonesia-1050x525.jpg'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Expanded(
                        child: Container(
                          color: Colors.white,
                          padding: EdgeInsets.all(isDesktop ? 64 : 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Welcome Back",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF002753),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Please sign in to access the dashboard.",
                                style: TextStyle(color: Colors.black45),
                              ),
                              const SizedBox(height: 48),
                              // Kolom Username[cite: 5]
                              TextFormField(
                                controller: _usernameController,
                                textInputAction: TextInputAction.next, // Pindah fokus ke password saat enter[cite: 5]
                                decoration: const InputDecoration(
                                  labelText: "Username",
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Kolom Password dengan fitur Mata & Enter[cite: 5]
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obsecurePassword,
                                textInputAction: TextInputAction.done, // Ikon keyboard selesai[cite: 5]
                                onFieldSubmitted: (value) => handleLogin(), // FITUR: Tekan Enter untuk Login[cite: 5]
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  // FITUR: Toggle Lihat Password[cite: 5]
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obsecurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obsecurePassword = !_obsecurePassword;
                                      });
                                    },
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text(
                                          "MASUK",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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