import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _nameError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    final nameError = name.isEmpty ? 'Full name is required' : null;
    final phoneError = phone.isEmpty ? 'Enter your phone number' : null;
    final passwordError = password.isEmpty || password.length < 6
        ? 'Password must be at least 6 characters'
        : null;
    final confirmPasswordError =
        confirm != password ? 'Passwords do not match' : null;

    setState(() {
      _nameError = nameError;
      _phoneError = phoneError;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
    });

    return nameError == null &&
        phoneError == null &&
        passwordError == null &&
        confirmPasswordError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    await ref.read(authNotifierProvider.notifier).register(
          _nameController.text.trim(),
          _phoneController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authNotifierProvider);
    final isLoading = authAsync.isLoading;

    final authError = authAsync.valueOrNull is AuthUnauthenticated
        ? (authAsync.valueOrNull as AuthUnauthenticated).error
        : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : context.textSecondary;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (context.canPop())
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
              SizedBox(height: 32),
              Text(
                'Create account',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              SizedBox(height: 8),
              Text(
                'Start tracking your expenses',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textSecondary,
                    ),
              ),
              SizedBox(height: 32),
              AppInput(
                label: 'Full name',
                controller: _nameController,
                errorText: _nameError,
                keyboardType: TextInputType.name,
              ),
              SizedBox(height: 16),
              AppInput(
                label: 'Phone number',
                controller: _phoneController,
                errorText: _phoneError,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              AppInput(
                label: 'Password',
                controller: _passwordController,
                errorText: _passwordError,
                obscureText: true,
                showToggle: true,
              ),
              SizedBox(height: 16),
              AppInput(
                label: 'Confirm password',
                controller: _confirmPasswordController,
                errorText: _confirmPasswordError,
                obscureText: true,
                showToggle: true,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: 24),
              AppButton(
                label: 'Create account',
                onPressed: isLoading ? null : _submit,
                isLoading: isLoading,
              ),
              if (authError != null) ...[
                SizedBox(height: 8),
                Text(
                  authError,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text('Sign in'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
