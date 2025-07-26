import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/authentication/domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../../../../shared/widgets/loading_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  File? _selectedFile; // ✅ to store profile pic temporarily
  String? _profilePicUrl; // ✅ Supabase uploaded URL
  bool _isUploading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  /// ✅ Pick Image using FilePicker
  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  /// ✅ Upload image to Supabase
  Future<String?> _uploadProfileImage(String userId) async {
    if (_selectedFile == null) return null;

    try {
      setState(() => _isUploading = true);

      final fileName = "${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg";

      await Supabase.instance.client.storage
          .from('chat-files')
          .upload(fileName, _selectedFile!,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: false));

      final publicUrl = Supabase.instance.client.storage.from('chat-files').getPublicUrl(fileName);

      setState(() {
        _profilePicUrl = publicUrl;
        _isUploading = false;
      });

      return publicUrl;
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Upload failed: $e")));
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<UserEntity?>>(authControllerProvider, (previous, next) async {
      next.when(
        data: (user) async {
          if (user != null) {
            /// ✅ Upload profile image to Supabase
            final imageUrl = await _uploadProfileImage(user.id);

            /// ✅ Save user details to Firestore
            await FirebaseFirestore.instance.collection('users').doc(user.id).set({
              'name': _displayNameController.text.trim(),
              'email': _emailController.text.trim(),
              'profilePic': imageUrl ?? '', // if user didn’t select pic, keep empty
              'createdAt': DateTime.now(),
            });

            if (mounted) context.go('/dashboard');
          }
        },
        loading: () {},
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign up failed: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                /// ✅ Profile Picture Picker
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _selectedFile != null
                            ? FileImage(_selectedFile!)
                            : null,
                        child: _selectedFile == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.teal,
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                CustomTextField(
                  controller: _displayNameController,
                  label: 'Display Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your display name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                authController.when(
                  data: (_) => CustomButton(
                    text: 'Sign Up',
                    onPressed: _handleSignUp,
                  ),
                  loading: () => const LoadingWidget(),
                  error: (_, __) => CustomButton(
                    text: 'Sign Up',
                    onPressed: _handleSignUp,
                  ),
                ),

                const SizedBox(height: 16),
                CustomButton(
                  text: 'Sign up with Google',
                  onPressed: _handleGoogleSignIn,
                  backgroundColor: Colors.red,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Login'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSignUp() {
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider.notifier).signUpWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            displayName: _displayNameController.text.trim(),
          );
    }
  }

  void _handleGoogleSignIn() {
    ref.read(authControllerProvider.notifier).signInWithGoogle();
  }
}
