import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../core/localization/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedCampus = 'MAIN CAMPUS';
  String? _selectedDepartment = 'SWE';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // List of campuses and departments
  final List<String> _campuses = [
    'MAIN CAMPUS',
    'HIT CAMPUS',
    'STATIONERY CAMPUS'
  ];

  final List<String> _departments = [
    'SWE',
    'CS',
    'IS',
    'SPORT',
    'ELECTRICAL',
    'CIVIL',
    'LAW'
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        _selectedCampus,
        _selectedDepartment,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Registration successful! Your account is pending admin approval.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fieldTextColor = theme.colorScheme.onSurface;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 80,
                        color: Color(0xFF8c6d46),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        localizations.welcomeBack,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          color: const Color(0xFF8c6d46),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeInDown(
                      duration: const Duration(milliseconds: 400),
                      child: TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: fieldTextColor),
                        decoration: _inputDecoration(
                            localizations.fullName, Icons.person),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations.pleaseEnterName;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInDown(
                      duration: const Duration(milliseconds: 400),
                      child: TextFormField(
                        controller: _emailController,
                        style: TextStyle(color: fieldTextColor),
                        decoration:
                            _inputDecoration(localizations.email, Icons.email),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations.pleaseEnterEmail;
                          }
                          if (!value.contains('@')) {
                            return localizations.pleaseEnterValidEmail;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: TextFormField(
                        controller: _phoneController,
                        style: TextStyle(color: fieldTextColor),
                        decoration: _inputDecoration(
                            '${localizations.phoneNumber} (${localizations.optional})',
                            Icons.phone),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: theme.scaffoldBackgroundColor,
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCampus,
                          style: TextStyle(color: fieldTextColor),
                          decoration: _inputDecoration(
                              localizations.campus, Icons.school),
                          dropdownColor: theme.scaffoldBackgroundColor,
                          items: _campuses.map((String campus) {
                            return DropdownMenuItem<String>(
                              value: campus,
                              child: Text(
                                campus,
                                style: TextStyle(color: fieldTextColor),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCampus = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInDown(
                      duration: const Duration(milliseconds: 1000),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: theme.scaffoldBackgroundColor,
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedDepartment,
                          style: TextStyle(color: fieldTextColor),
                          decoration: _inputDecoration(
                              localizations.department, Icons.business),
                          dropdownColor: theme.scaffoldBackgroundColor,
                          items: _departments.map((String department) {
                            return DropdownMenuItem<String>(
                              value: department,
                              child: Text(
                                department,
                                style: TextStyle(color: fieldTextColor),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedDepartment = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInDown(
                      duration: const Duration(milliseconds: 200),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: fieldTextColor),
                        decoration: InputDecoration(
                          labelText: localizations.password,
                          prefixIcon: Icon(Icons.lock,
                              color: theme.colorScheme.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations.pleaseEnterPassword;
                          }
                          if (value.length < 6) {
                            return localizations.passwordLengthError;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInDown(
                      duration: const Duration(milliseconds: 200),
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: TextStyle(color: fieldTextColor),
                        decoration: InputDecoration(
                          labelText: localizations.confirmPassword,
                          prefixIcon: Icon(Icons.lock,
                              color: theme.colorScheme.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations.pleaseConfirmPassword;
                          }
                          if (value != _passwordController.text) {
                            return localizations.passwordsDoNotMatch;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  localizations.register,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text(
                          '${localizations.registrationAlreadyHaveAccount} ${localizations.login}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: theme.colorScheme.primary,
        size: 24,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white24 : Colors.black12,
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white24 : Colors.black12,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 2,
        ),
      ),
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : Colors.black54,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: theme.colorScheme.primary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
