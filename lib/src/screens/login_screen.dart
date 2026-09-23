import "dart:ui";
import "package:flutter/material.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:google_fonts/google_fonts.dart";
import "package:flutter_animate/flutter_animate.dart";
import "signup_screen.dart";
import "forgot_password_screen.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          "user-not-found" => "No account found with that email.",
          "wrong-password" => "Incorrect password.",
          "invalid-email" => "That email address looks invalid.",
          "invalid-credential" => "Incorrect email or password.",
          _ => "Login failed: ${e.message}",
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
          // Base gradient background
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
          // Soft glow blob, top-right
          Positioned(
            top: -120,
            right: -80,
            child: _GlowBlob(
              color: Colors.deepPurpleAccent.withValues(alpha: 0.35),
              size: 320,
            ),
          ),
          // Soft glow blob, bottom-left
          Positioned(
            bottom: -140,
            left: -100,
            child: _GlowBlob(
              color: Colors.blueAccent.withValues(alpha: 0.25),
              size: 360,
            ),
          ),
          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(Icons.groups_rounded,
                                    size: 56,
                                    color: Colors.deepPurpleAccent.shade100)
                                .animate()
                                .fadeIn(duration: 600.ms)
                                .scale(begin: const Offset(0.8, 0.8)),
                            const SizedBox(height: 16),
                            Text(
                              "PreFlight Crew",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ).animate().fadeIn(duration: 600.ms).slideY(
                                begin: -0.2),
                            const SizedBox(height: 8),
                            Text(
                              "Sign in with your WeThinkCode account",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 32),
                            _GlassTextField(
                              controller: _emailController,
                              label: "Email",
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your email";
                                }
                                if (!value.contains("@")) {
                                  return "Please enter a valid email";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _GlassTextField(
                              controller: _passwordController,
                              label: "Password",
                              icon: Icons.lock_outline,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your password";
                                }
                                return null;
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _HoverText(
                                text: "Forgot password?",
                                onTap: _isLoading
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ForgotPasswordScreen(),
                                          ),
                                        );
                                      },
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                    color: Colors.redAccent),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 16),
                            _HoverButton(
                              onPressed: _isLoading ? null : _login,
                              isLoading: _isLoading,
                              label: "Sign In",
                            ),
                            const SizedBox(height: 20),
                            _HoverText(
                              text: "Don't have an account? Sign up",
                              onTap: _isLoading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SignupScreen(),
                                        ),
                                      );
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms).scale(
                  begin: const Offset(0.96, 0.96)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A soft, blurred circle of color used as a decorative background glow.
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

/// A frosted-glass styled text field matching the login card.
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

/// A button that scales and glows slightly when hovered (web/desktop),
/// giving genuine interactive feedback instead of a static click target.
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

/// A text link that brightens and underlines on hover.
class _HoverText extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;

  const _HoverText({required this.text, required this.onTap});

  @override
  State<_HoverText> createState() => _HoverTextState();
}

class _HoverTextState extends State<_HoverText> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            color: _isHovered
                ? Colors.deepPurpleAccent.shade100
                : Colors.deepPurpleAccent.shade200.withValues(alpha: 0.8),
            decoration:
                _isHovered ? TextDecoration.underline : TextDecoration.none,
            fontWeight: FontWeight.w500,
          ),
          child: Text(widget.text),
        ),
      ),
    );
  }
}
