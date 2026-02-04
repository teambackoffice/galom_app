import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:location_tracker_app/controller/login_controller.dart';
import 'package:location_tracker_app/view/mainscreen/homepage.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late AnimationController _loadingController;
  late AnimationController _successController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _obscurePassword = true;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _loadingController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    _loadingController.forward();

    final loginController = Provider.of<LoginController>(
      context,
      listen: false,
    );

    final success = await loginController.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    _loadingController.reverse();

    if (success && mounted) {
      _showSuccessAnimation();
    } else if (mounted) {
      _showErrorSnackBar(loginController.errorMessage);
    }
  }

  void _showSuccessAnimation() {
    setState(() {
      _showSuccess = true;
    });
    _successController.forward();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SpinKitPulse(color: Colors.white, size: 20.0),
            SizedBox(width: 12),
            Text(
              'Login successful! Redirecting...',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
        duration: Duration(milliseconds: 1000),
      ),
    );

    Future.delayed(Duration(milliseconds: 1000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                MainScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
            transitionDuration: Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  void _showErrorSnackBar(String? error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SpinKitRing(color: Colors.white, size: 20.0, lineWidth: 2.0),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                error ?? 'Login failed. Please try again.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F6FA),
      body: Consumer<LoginController>(
        builder: (context, loginController, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 60),
                  // Welcome Text
                  AnimatedDefaultTextStyle(
                    duration: Duration(milliseconds: 300),
                    style: TextStyle(
                      color: Color(0xFF764BA2),
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                    child: Text("Welcome"),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Login to continue your journey",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 150),

                  // Login Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          hint: "Email",
                          isPassword: false,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }

                            return null;
                          },
                        ),
                        SizedBox(height: 18),

                        // Password Field
                        _buildTextField(
                          controller: _passwordController,
                          icon: Icons.lock_outline,
                          hint: "Password",
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 12),

                        // Forgot Password
                        SizedBox(height: 25),

                        // Login Button with single indicator
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: loginController.isLoading
                                ? null
                                : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF764BA2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: loginController.isLoading ? 0 : 2,
                            ),
                            child: loginController.isLoading
                                ? SpinKitThreeBounce(
                                    color: Colors.white,
                                    size: 20.0,
                                  )
                                : Text(
                                    "Login",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required bool isPassword,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Color(0xFF764BA2)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Color(0xFF764BA2),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFF764BA2), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
      ),
    );
  }
}
