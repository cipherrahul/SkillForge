import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';
import 'auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'test@test.com');
  final _passwordController = TextEditingController(text: '123456');
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
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailController.text, _passwordController.text);
    if (!mounted) return;
    if (success) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F0FE), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo centered
                    Column(
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: const Icon(Icons.bolt_rounded,
                              color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: AppTheme.sp16),
                        Text('SkillForge',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w800)),
                      ],
                    ),

                    const SizedBox(height: AppTheme.sp48),
                    Text('Welcome back',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textHeading,
                        )),
                    const SizedBox(height: AppTheme.sp8),
                    Text('Sign in to continue your learning journey',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        )),
                    const SizedBox(height: AppTheme.sp32),

                    // Form inside a clean card
                    Container(
                      padding: const EdgeInsets.all(AppTheme.sp24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          )
                        ],
                        border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: Theme.of(context).textTheme.bodyLarge,
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: Icon(Icons.mail_outline_rounded,
                                    color: AppTheme.textSecondary, size: 22),
                              ),
                              validator: (v) =>
                                  v == null || !v.contains('@')
                                      ? 'Enter a valid email'
                                      : null,
                            ),
                            const SizedBox(height: AppTheme.sp24),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: Theme.of(context).textTheme.bodyLarge,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded,
                                    color: AppTheme.textSecondary, size: 22),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppTheme.textSecondary, size: 22,
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
                            
                            const SizedBox(height: AppTheme.sp12),
                            
                            // Error message
                            Consumer<AuthProvider>(builder: (_, auth, __) {
                              if (auth.errorMessage == null) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: AppTheme.sp4, bottom: AppTheme.sp8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        color: AppTheme.error, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(auth.errorMessage!,
                                        style: const TextStyle(
                                            color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w500))),
                                  ],
                                ),
                              );
                            }),

                            const SizedBox(height: AppTheme.sp24),

                            // Sign In button
                            Consumer<AuthProvider>(builder: (_, auth, __) {
                              return SizedBox(
                                width: double.infinity,
                                height: 52, // Slightly taller button
                                child: ElevatedButton(
                                  onPressed: auth.isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: auth.isLoading ? 0 : 4,
                                    shadowColor: AppTheme.primary.withOpacity(0.5),
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(width: 24, height: 24,
                                          child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2.5))
                                      : Text('Sign In', 
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          )),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.sp32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            )),
                        TextButton(
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: const Size(0, 0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: () => Navigator.pushReplacement(context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen())),
                          child: Text('Create account',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            )),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.sp32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
