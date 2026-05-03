import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    if (context.mounted) {
      if (success) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryBrown,
              AppColors.primaryBrown.withOpacity(0.8),
              AppColors.darkBrown,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingXl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),

                // App Icon/Logo
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingXl),
                  decoration: BoxDecoration(
                    color: AppColors.offWhite.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.explore,
                    size: 120,
                    color: AppColors.offWhite,
                  ),
                ),

                const SizedBox(height: AppConstants.spacingXl),

                // App Name
                Text(
                  'Serendib',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.offWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 48,
                        letterSpacing: 2,
                      ),
                ),

                const SizedBox(height: AppConstants.spacingMd),

                // Tagline
                Text(
                  'Discover the Beauty of Sri Lanka',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.offWhite.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppConstants.spacingSm),

                Text(
                  'Your personal museum guide',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.offWhite.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/register');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.offWhite,
                      foregroundColor: AppColors.primaryBrown,
                      elevation: 8,
                      shadowColor: Colors.black45,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_add, size: 24),
                        const SizedBox(width: AppConstants.spacingSm),
                        Text(
                          'Sign Up',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.primaryBrown,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.spacingMd),

                // Google Sign-In Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () => _handleGoogleSignIn(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 4,
                          shadowColor: Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                          ),
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CustomPaint(painter: _GoogleLogoPainter()),
                                  ),
                                  const SizedBox(width: AppConstants.spacingSm),
                                  Text(
                                    'Continue with Google',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppConstants.spacingLg),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.offWhite,
                      side: const BorderSide(
                        color: AppColors.offWhite,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login, size: 24),
                        const SizedBox(width: AppConstants.spacingSm),
                        Text(
                          'Sign In',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.offWhite,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.spacingXl),

                // Footer text
                Text(
                  'Experience interactive museum tours\nwith AR/VR and real-time navigation',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.offWhite.withOpacity(0.6),
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppConstants.spacingLg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    const List<_Arc> arcs = [
      _Arc(color: Color(0xFF4285F4), startAngle: -0.52, sweepAngle: 1.57),
      _Arc(color: Color(0xFF34A853), startAngle: 1.05, sweepAngle: 1.57),
      _Arc(color: Color(0xFFFBBC05), startAngle: 2.62, sweepAngle: 1.05),
      _Arc(color: Color(0xFFEA4335), startAngle: 3.67, sweepAngle: 1.05),
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;

    for (final arc in arcs) {
      paint.color = arc.color;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
        arc.startAngle,
        arc.sweepAngle,
        false,
        paint,
      );
    }

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;

    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.72, cy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Arc {
  final Color color;
  final double startAngle;
  final double sweepAngle;
  const _Arc({required this.color, required this.startAngle, required this.sweepAngle});
}
