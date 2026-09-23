import "dart:ui";
import "package:flutter/material.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:google_fonts/google_fonts.dart";
import "package:flutter_animate/flutter_animate.dart";

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  static const _allowedDomain = "@student.wethinkcode.co.za";

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await credential.user?.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Account created! Check your inbox to verify your email."),
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          "email-already-in-use" =>
            "An account already exists for that email.",
          "weak-password" => "Password should be at least 6 characters.",
          "invalid-email" => "That email address looks invalid.",
          _ => "Sign up failed: ${e.message}",
        };
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F0C29),
                    Color(0xFF221F3F),
                    Color(0xFF302B63),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -80,
            child: _GlowBlob(
              color: Colors.blueAccent.withValues(alpha: 0.3),
              size: 300,
            ),
          ),
          Positioned(
            bottom: -140,
            right: -100,
            child: _GlowBlob(
              color: Colors.deepPurpleAccent.withValues(alpha: 0.35),
              size: 360,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.all(32.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      "Join PreFlight Crew",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    )
                                        .animate()
                                        .fadeIn(duration: 600.ms)
                                        .slideY(begin: -0.2),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Signup is restricted to $_allowedDomain emails",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    _GlassTextField(
                                      controller: _emailController,
                                      label: "WeThinkCode Student Email",
                                      icon: Icons.school_outlined,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Please enter your email";
                                        }
                                        if (!value
                                            .toLowerCase()
                                            .endsWith(_allowedDomain)) {
                                          return "Only $_allowedDomain emails are allowed";
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _GlassTextField(
                                      controller: _passwordController,
                                      label: "Password (min 6 characters)",
                                      icon: Icons.lock_outline,
                                      obscureText: true,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Please enter a password";
                                        }
                                        if (value.length < 6) {
                                          return "Password must be at least 6 characters";
                                        }
                                        return null;
                                      },
                                    ),
                                    if (_errorMessage != null) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                            color: Colors.redAccent),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    _HoverButton(
                                      onPressed:
                                          _isLoading ? null : _signup,
                                      isLoading: _isLoading,
                                      label: "Sign Up",
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .scale(begin: const Offset(0.96, 0.96)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurpleAccent.shade100),
        ),
      ),
    );
  }
}

class _HoverButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _HoverButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.deepPurpleAccent.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: widget.onPressed,
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(widget.label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
