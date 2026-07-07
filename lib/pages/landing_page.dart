import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/resident_model.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/form_widgets.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String _loadingText = 'Accessing Dashboard...';

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _username.text.trim();
    final password = _password.text;

    if (username == 'admin' && password == 'admin123') {
      StorageService.clearCurrentResident();
      await _showSuccess(
        'Accessing Admin Dashboard...',
        AppRoutes.adminDashboard,
      );
      return;
    }

    setState(() {
      _loading = true;
      _loadingText = 'Checking resident account...';
    });
    await StorageService.ensureReady().timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
    if (!mounted) return;

    ResidentModel? resident;
    for (final item in StorageService.residents()) {
      if (item.username == username && item.password == password) {
        resident = item;
        break;
      }
    }

    if (resident != null) {
      StorageService.setCurrentResident(resident);
      await _showSuccess(
        'Accessing Resident Portal...',
        AppRoutes.residentDashboard,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _loading = false);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.red100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.close, color: AppColors.red600),
              ),
              const SizedBox(height: 16),
              const Text(
                'Login Failed',
                style: TextStyle(
                  color: AppColors.slate900,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Invalid username or password. Please check your credentials and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.slate500, fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'Try Again',
                  danger: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSuccess(String message, String route) async {
    setState(() {
      _loading = true;
      _loadingText = message;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 448,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate100),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1a0f172a),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.blue100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Icons.apartment,
                        color: AppColors.blue600,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Barangay IMS',
                      style: TextStyle(
                        color: AppColors.slate800,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to manage your community',
                      style: TextStyle(color: AppColors.slate500, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    LabeledTextField(
                      label: 'Username',
                      controller: _username,
                      requiredField: true,
                      hint: 'Enter your username',
                    ),
                    const SizedBox(height: 24),
                    LabeledTextField(
                      label: 'Password',
                      controller: _password,
                      requiredField: true,
                      hint: '••••••••',
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(label: 'Sign In', onPressed: _login),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 48,
                      width: 48,
                      child: CircularProgressIndicator(
                        color: AppColors.blue600,
                        strokeWidth: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _loadingText,
                      style: const TextStyle(
                        color: AppColors.slate600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
