import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/authentication/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;

  @override
  void initState() {
    super.initState();

    // 🎞️ Gradient animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _colorAnimation1 = ColorTween(
      begin: Colors.blue.shade300,
      end: Colors.blue.shade600,
    ).animate(_controller);

    _colorAnimation2 = ColorTween(
      begin: Colors.purple.shade300,
      end: Colors.indigo.shade400,
    ).animate(_controller);

    // ⏳ Navigate after splash delay
    Future.delayed(const Duration(seconds: 2), _navigateBasedOnAuth);
  }

  void _navigateBasedOnAuth() {
    final authState = ref.read(authStateProvider);

    authState.when(
      data: (user) => context.go(user != null ? '/dashboard' : '/login'),
      loading: () => Future.delayed(
        const Duration(milliseconds: 500),
        _navigateBasedOnAuth,
      ),
      error: (_, __) => context.go('/login'),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.35;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _colorAnimation1.value ?? Colors.blue,
                  _colorAnimation2.value ?? Colors.purple,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          );
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🎨 Logo
              Image.asset(
                'assets/images/logo.png',
                height: logoSize,
                width: logoSize,
              ),
              const SizedBox(height: 20),

              // 🏷️ App Name
              const Text(
                "AlgoMentor",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 30),

              // ⏳ Loading indicator
              const CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
