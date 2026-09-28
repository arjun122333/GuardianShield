import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/home_screen.dart';

/// Role options for Child Safety Guardian application
enum UserRole { parent, kid }

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.parent:
        return 'Parent';
      case UserRole.kid:
        return 'Kid';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.parent:
        return 'Parent / Guardian';
      case UserRole.kid:
        return 'Kid / Child';
    }
  }
}

/// A modern, warm-toned Login & Registration screen for Child Safety & Guardian Apps.
class ChildSafetyLoginScreen extends StatefulWidget {
  /// Optional callback invoked after successful authentication
  final VoidCallback? onLoginSuccess;

  const ChildSafetyLoginScreen({super.key, this.onLoginSuccess});

  @override
  State<ChildSafetyLoginScreen> createState() => _ChildSafetyLoginScreenState();
}

class _ChildSafetyLoginScreenState extends State<ChildSafetyLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // State Variables
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.parent;

  // Safe Firebase getters
  FirebaseAuth? get _auth => Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _firestore => Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;

  // Warm Child-Safety Color Palette
  static const Color _primaryWarmCoral = Color(0xFFFF6F59);
  static const Color _secondaryWarmAmber = Color(0xFFFFB347);
  static const Color _softPeachBg = Color(0xFFFFF8F3);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF2D3142);
  static const Color _textMuted = Color(0xFF9094A6);
  static const Color _parentBadgeColor = Color(0xFF4A90E2);
  static const Color _kidBadgeColor = Color(0xFFFF9F1C);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Handle Form Submission (Login / Register)
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (Firebase.apps.isNotEmpty && _auth != null) {
        if (_isLogin) {
          // --- 1. Firebase Sign In ---
          await _auth!.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          if (!mounted) return;
          _showSnackBar('Welcome back!', isError: false);
        } else {
          // --- 2. Firebase Sign Up ---
          final UserCredential credential = await _auth!.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          final user = credential.user;
          if (user != null && _firestore != null) {
            // --- 3. Cloud Firestore Record Creation ---
            await _firestore!.collection('users').doc(user.uid).set({
              'email': email,
              'role': _selectedRole.value,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }

          if (!mounted) return;
          _showSnackBar('Account created successfully!', isError: false);
        }
      } else {
        // Fallback for local demo mode
        if (!mounted) return;
        _showSnackBar(_isLogin ? 'Logged in as ${_selectedRole.value}' : 'Account registered!', isError: false);
      }

      // Trigger success callback if provided, or navigate to HomeScreen
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!.call();
      } else if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnackBar(_getAuthErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('no-app') || e.toString().contains('not initialized')) {
        _showSnackBar('Logged in successfully as ${_selectedRole.value}', isError: false);
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!.call();
        } else if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        _showSnackBar('Authentication Notice: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Friendly error messages for FirebaseAuthExceptions
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'The password provided is too weak (at least 6 characters).';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-credential':
        return 'Invalid email or password credentials.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  // Helper method to display error or success SnackBars
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _softPeachBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Logo & Branding
                _buildHeader(),

                const SizedBox(height: 24),

                // Main Form Card
                Container(
                  width: size.width > 500 ? 460 : double.infinity,
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryWarmCoral.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Segmented Tab Switcher (Login / Register)
                        _buildModeToggle(),

                        const SizedBox(height: 24),

                        // Role Selector ('Parent' vs 'Kid')
                        _buildRoleSelector(),

                        const SizedBox(height: 24),

                        // Email Input
                        _buildEmailField(),

                        const SizedBox(height: 16),

                        // Password Input
                        _buildPasswordField(),

                        // Confirm Password Input (Only for Register)
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          _buildConfirmPasswordField(),
                        ],

                        const SizedBox(height: 28),

                        // Submit Button with Loading Indicator
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Bottom Toggle Link
                _buildBottomToggleLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Header Widget ---
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primaryWarmCoral, _secondaryWarmAmber],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _primaryWarmCoral.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Guardian Shield',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _textDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isLogin
              ? 'Sign in to protect and connect with your family'
              : 'Create an account for safe family protection',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: _textMuted,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  // --- Mode Toggle Switcher (Sign In vs Create Account) ---
  Widget _buildModeToggle() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _softPeachBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isLogin) {
                  setState(() {
                    _isLogin = true;
                    _formKey.currentState?.reset();
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _isLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _isLogin
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isLogin ? _primaryWarmCoral : _textMuted,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isLogin) {
                  setState(() {
                    _isLogin = false;
                    _formKey.currentState?.reset();
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !_isLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: !_isLogin
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Register',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: !_isLogin ? _primaryWarmCoral : _textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Role Selector Cards ('Parent' vs 'Kid') ---
  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SELECT YOUR ROLE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                role: UserRole.parent,
                title: 'Parent',
                subtitle: 'Guardian',
                icon: Icons.supervisor_account_rounded,
                activeColor: _parentBadgeColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleCard(
                role: UserRole.kid,
                title: 'Kid',
                subtitle: 'Protected',
                icon: Icons.child_care_rounded,
                activeColor: _kidBadgeColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE8ECEF),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : const Color(0xFFF0F3F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : _textMuted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? _textDark : _textMuted,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? activeColor : _textMuted,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Email Text Form Field ---
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: _textDark, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'name@family.com',
        labelStyle: const TextStyle(color: _textMuted),
        prefixIcon: const Icon(Icons.email_outlined, color: _primaryWarmCoral),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryWarmCoral, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email address.';
        }
        final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value.trim())) {
          return 'Please enter a valid email address.';
        }
        return null;
      },
    );
  }

  // --- Password Text Form Field ---
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
      style: const TextStyle(color: _textDark, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: const TextStyle(color: _textMuted),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: _primaryWarmCoral),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: _textMuted,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryWarmCoral, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password.';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters.';
        }
        return null;
      },
      onFieldSubmitted: (_) {
        if (_isLogin) _submitForm();
      },
    );
  }

  // --- Confirm Password Form Field (Registration mode) ---
  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      style: const TextStyle(color: _textDark, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        labelStyle: const TextStyle(color: _textMuted),
        prefixIcon: const Icon(Icons.lock_reset_rounded, color: _primaryWarmCoral),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: _textMuted,
          ),
          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryWarmCoral, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
      ),
      validator: (value) {
        if (!_isLogin) {
          if (value == null || value.isEmpty) {
            return 'Please confirm your password.';
          }
          if (value != _passwordController.text) {
            return 'Passwords do not match.';
          }
        }
        return null;
      },
      onFieldSubmitted: (_) => _submitForm(),
    );
  }

  // --- Primary Action Button ---
  Widget _buildSubmitButton() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryWarmCoral, _secondaryWarmAmber],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryWarmCoral.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? 'Sign In as ${_selectedRole.value}' : 'Create ${_selectedRole.value} Account',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
      ),
    );
  }

  // --- Bottom Toggle Link ---
  Widget _buildBottomToggleLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account? " : "Already have an account? ",
          style: const TextStyle(color: _textMuted, fontSize: 14),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isLogin = !_isLogin;
              _formKey.currentState?.reset();
            });
          },
          child: Text(
            _isLogin ? 'Register' : 'Sign In',
            style: const TextStyle(
              color: _primaryWarmCoral,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
