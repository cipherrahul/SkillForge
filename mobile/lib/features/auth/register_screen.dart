import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';
import 'auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    if (success) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.sp48),
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bolt_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: AppTheme.sp8),
                    Text('SkillForge',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: AppTheme.sp48),
                Text('Create your account',
                    style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: AppTheme.sp8),
                Text(
                    'Join thousands of students advancing their careers.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppTheme.sp32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline_rounded,
                              color: AppTheme.textSecondary, size: 20),
                        ),
                        validator: (v) =>
                            v == null || v.trim().length < 2
                                ? 'Enter your full name'
                                : null,
                      ),
                      const SizedBox(height: AppTheme.sp16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.mail_outline_rounded,
                              color: AppTheme.textSecondary, size: 20),
                        ),
                        validator: (v) =>
                            v == null || !v.contains('@')
                                ? 'Enter a valid email'
                                : null,
                      ),
                      const SizedBox(height: AppTheme.sp16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              color: AppTheme.textSecondary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.textSecondary, size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.length < 6
                                ? 'Minimum 6 characters'
                                : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.sp8),
                Consumer<AuthProvider>(builder: (_, auth, __) {
                  if (auth.errorMessage == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppTheme.sp8),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppTheme.error, size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text(auth.errorMessage!,
                            style: const TextStyle(
                                color: AppTheme.error, fontSize: 13))),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppTheme.sp32),
                Consumer<AuthProvider>(builder: (_, auth, __) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Create Account'),
                    ),
                  );
                }),
                const SizedBox(height: AppTheme.sp24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium),
                    TextButton(
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0)),
                      onPressed: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen())),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
