import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.directions_car,
                    color: Colors.white, size: 44),
              ),
              const SizedBox(height: 24),
              const Text('WEGO',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.secondary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ghép chuyến thông minh\nTiết kiệm chi phí di chuyển',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // Minh họa 3 lợi ích
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _BenefitItem(icon: Icons.savings, label: 'Tiết kiệm'),
                  _BenefitItem(icon: Icons.verified_user, label: 'An toàn'),
                  _BenefitItem(icon: Icons.access_time, label: 'Đúng giờ'),
                ],
              ),

              const Spacer(flex: 3),

              // Nút đăng nhập Google
              auth.isLoading
                  ? const CircularProgressIndicator()
                  : _GoogleSignInButton(
                onPressed: () async {
                  final result = await auth.signInWithGoogle();
                  if (!context.mounted) return;
                  if (result == 'new_user') {
                    context.go('/select-role');
                  } else if (result != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result)),
                    );
                  }
                },
              ),

              const SizedBox(height: 16),
              const Text(
                'Bằng cách đăng nhập, bạn đồng ý với\nĐiều khoản sử dụng của WEGO',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BenefitItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 28),
        ),
        const SizedBox(height: 6),
        Text(label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Image.network(
          'https://www.google.com/favicon.ico',
          width: 20, height: 20,
        ),
        label: const Text(
          'Tiếp tục với Google',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}