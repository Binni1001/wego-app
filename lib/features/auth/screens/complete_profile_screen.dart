import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = GoRouterState.of(context).extra as String? ?? 'passenger';
    final auth = context.watch<AuthProvider>();
    final isDriver = role == 'driver';

    return Scaffold(
      appBar: AppBar(title: const Text('Hoàn thiện hồ sơ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDriver ? '🚗 Thông tin tài xế' : '👤 Thông tin hành khách',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Điền thông tin để hoàn tất đăng ký',
                  style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 32),

              // Họ tên
              const Text('Họ và tên',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  )),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Nhập họ và tên của bạn',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                v == null || v.isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 20),

              // Số điện thoại
              const Text('Số điện thoại',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  )),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '0xxxxxxxxx',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập SĐT';
                  if (v.length < 10) return 'Số điện thoại không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Nút hoàn tất
              auth.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  await auth.saveNewUser(
                    _nameController.text.trim(),
                    _phoneController.text.trim(),
                    role,
                  );
                  if (!context.mounted) return;
                  context.go(isDriver ? '/driver' : '/passenger');
                },
                child: const Text('Bắt đầu sử dụng WEGO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}