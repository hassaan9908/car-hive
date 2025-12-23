import 'package:flutter/material.dart';
import 'package:carhive/auth/loginscreen.dart';
import 'package:carhive/auth/signupscreen.dart';
// import removed: app_colors not directly used, theme colors pulled from Theme.of(context)
import 'package:shared_preferences/shared_preferences.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _markStartupAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_startup', true);
    } catch (e) {
      print('Error saving startup status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Orange Car Image at the top
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Image.asset(
                          'assets/images/orange_car.png',
                          height: 350,
                          width: 350,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              width: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.car_rental,
                                size: 100,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // CarHive Title
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                        'Car',
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: const Color(0xFFf48c25),
                          fontWeight: FontWeight.bold,
                          fontSize: 42,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Hive',
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 42,
                          letterSpacing: -0.5,
                        ),
                      ),
                        ],
                      )
                    ),

                    const SizedBox(height: 16),

                    // Subtitle
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Your Ultimate Car Marketplace\nBuy, sell, and discover amazing cars',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? Colors.white.withOpacity(0.8)
                              : Colors.black87.withOpacity(0.7),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Action Buttons
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _slideController,
                        curve: const Interval(0.3, 1.0,
                            curve: Curves.easeOutCubic),
                      )),
                      child: FadeTransition(
                        opacity: Tween<double>(
                          begin: 0.0,
                          end: 1.0,
                        ).animate(CurvedAnimation(
                          parent: _fadeController,
                          curve: const Interval(0.5, 1.0),
                        )),
                        child: Column(
                          children: [
                            // Create Account Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: 
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),                      
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
                                ),
                                
                                child: ElevatedButton(
                                onPressed: () async {
                                  await _markStartupAsSeen();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const Signupscreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Create an Account',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            ),
                            const SizedBox(height: 16),

                            // Sign In Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: () async {
                                  await _markStartupAsSeen();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const Loginscreen(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? const Color(0xFF221910)
                                      : Colors.white,
                                  foregroundColor: Colors.black,
                                  side: BorderSide(
                                    color: isDark
                                      ? Colors.white
                                      : Colors.black,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Sign in',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: isDark
                                      ? Colors.white
                                      : Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Browse as Guest Button
                            TextButton(
                              onPressed: () async {
                                await _markStartupAsSeen();
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/home',
                                  (route) => false,
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: isDark
                                    ? Colors.white
                                    : Colors.black87,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                'Browse as guest',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }
}
