import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.adminLogin(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/admin/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A0F08), const Color(0xFF2C1A0E)]
                : [const Color(0xFFFFF3EB), const Color(0xFFFFE0C8)],
          ),
        ),
        child: isWide
            ? _buildWideLayout(isDark)
            : _buildNarrowLayout(isDark),
      ),
    );
  }

  Widget _buildWideLayout(bool isDark) {
    return Row(
      children: [
        Expanded(flex: 5, child: _buildBrandingPanel()),
        Expanded(
          flex: 4,
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: _buildFormCard(isDark),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildNarrowHeader(),
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildFormCard(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D0500), Color(0xFF1C0A02), Color(0xFF0D0500)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Hexagon honeycomb grid
          Positioned.fill(
            child: CustomPaint(painter: _HexGridPainter()),
          ),

          // Deep orange radial glow — center right
          Positioned(
            right: -80,
            top: 100,
            child: Container(
              width: 560,
              height: 560,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFFF6B35).withOpacity(0.22),
                  const Color(0xFFFF4500).withOpacity(0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // Softer bottom glow
          Positioned(
            bottom: -120,
            right: 80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFFF6B35).withOpacity(0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(64, 52, 48, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // CarHive logo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.45),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.directions_car_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'CarHive',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 56),

                // Big headline
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 96,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: -3,
                    ),
                    children: [
                      TextSpan(text: 'Admin\n',   style: TextStyle(color: Colors.white)),
                      TextSpan(text: 'Control\n', style: TextStyle(color: Color(0xFFFF6B35))),
                      TextSpan(text: 'Center',    style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Manage users, listings, and platform\nsettings from one powerful dashboard.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.48),
                    fontSize: 16,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 48),

                _featureBadge(Icons.verified_user_rounded, 'Role-based access control'),
                const SizedBox(height: 16),
                _featureBadge(Icons.bar_chart_rounded, 'Real-time analytics'),
                const SizedBox(height: 16),
                _featureBadge(Icons.manage_accounts_rounded, 'User & listing management'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 56, 32, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFE8521A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'CarHive Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Control Center',
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1410) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF3A2518) : const Color(0xFFEEEEEE);

    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : const Color(0xFFFF6B35).withOpacity(0.12),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFF6B35),
                        ),
                      ),
                      Text(
                        'Sign in to continue',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white54
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Admin notice
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF6B35).withOpacity(isDark ? 0.18 : 0.10),
                      const Color(0xFFFF8C42).withOpacity(isDark ? 0.10 : 0.05),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFF6B35).withOpacity(0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shield_rounded,
                          color: Color(0xFFFF6B35), size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restricted Access',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFFF8C42)
                                  : const Color(0xFFCC4A00),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Admin or super_admin role required.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFFFFAA70)
                                  : const Color(0xFFB85000),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Email field
              _buildLabel('Email Address', isDark),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hint: 'admin@carhive.com',
                icon: Icons.email_outlined,
                isDark: isDark,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
                    return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password field
              _buildLabel('Password', isDark),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                isDark: isDark,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'At least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Sign In button
              Consumer<AdminProvider>(
                builder: (context, adminProvider, _) {
                  return Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: adminProvider.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: adminProvider.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Sign In to Admin Panel',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),

              // Error message
              Consumer<AdminProvider>(
                builder: (context, adminProvider, _) {
                  if (adminProvider.errorMessage == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: Colors.red.shade600, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              adminProvider.errorMessage!,
                              style: TextStyle(
                                  color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white70 : Colors.grey.shade700,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final fillColor = isDark ? const Color(0xFF2A1A10) : const Color(0xFFFAFAFA);
    final borderColor = isDark ? const Color(0xFF3D2418) : const Color(0xFFE0E0E0);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white.withOpacity(0.87) : Colors.grey.shade900,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white24 : Colors.grey.shade400,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon,
            color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFFF6B35), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _featureBadge(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HexGridPainter extends CustomPainter {
  static const double _r = 38.0; // hex circumradius (flat-top)

  @override
  void paint(Canvas canvas, Size size) {
    // Flat-top hex: column step = 1.5r, row step = sqrt(3)*r
    final double colStep = _r * 1.5;
    final double rowStep = _r * math.sqrt(3);

    // Glow origin — center-right of the panel
    final Offset glowCenter = Offset(size.width * 0.78, size.height * 0.42);
    final double maxDist = size.width * 0.75;

    int col = 0;
    for (double x = -_r; x < size.width + _r * 2; x += colStep) {
      int row = 0;
      // Odd columns are offset downward by half a row
      final double yOffset = (col.isOdd) ? rowStep / 2 : 0.0;
      for (double y = -_r + yOffset; y < size.height + _r; y += rowStep) {
        final Offset center = Offset(x, y);
        final double dist = (center - glowCenter).distance;
        final double proximity =
            (1.0 - (dist / maxDist).clamp(0.0, 1.0));

        // Pseudo-random highlight a few hexagons
        final int seed = (col * 13 + row * 29) % 24;
        final bool highlight = seed < 4 && proximity > 0.35;

        final double strokeOpacity = proximity * 0.28 + 0.03;
        final double fillOpacity =
            highlight ? proximity * 0.40 : proximity * 0.07;

        _drawHex(canvas, center, strokeOpacity, fillOpacity);
        row++;
      }
      col++;
    }
  }

  void _drawHex(Canvas canvas, Offset c, double strokeOp, double fillOp) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final double angle = i * 60.0 * math.pi / 180.0; // flat-top: 0° = right
      final double px = c.dx + _r * math.cos(angle);
      final double py = c.dy + _r * math.sin(angle);
      i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
    }
    path.close();

    if (fillOp > 0.015) {
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFF6B35).withOpacity(fillOp)
          ..style = PaintingStyle.fill,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFF6B35).withOpacity(strokeOp)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
  }

  @override
  bool shouldRepaint(covariant _HexGridPainter old) => false;
}
