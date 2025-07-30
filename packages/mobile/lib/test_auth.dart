import 'package:flutter/material.dart';
import 'data/services/auth_service.dart';
import 'domain/entities/user_entity.dart';
import 'core/errors/auth_exceptions.dart';

/// Simple test widget to verify authentication functionality
class AuthTestWidget extends StatefulWidget {
  const AuthTestWidget({super.key});

  @override
  State<AuthTestWidget> createState() => _AuthTestWidgetState();
}

class _AuthTestWidgetState extends State<AuthTestWidget> {
  final AuthService _authService = AuthService();
  UserEntity? _currentUser;
  String _status = 'Not authenticated';

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _listenToAuthChanges();
  }

  void _checkAuthState() async {
    try {
      final user = await _authService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _status = user != null ? 'Authenticated: ${user.email}' : 'Not authenticated';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((user) {
      setState(() {
        _currentUser = user;
        _status = user != null ? 'Authenticated: ${user.email}' : 'Not authenticated';
      });
    });
  }

  Future<void> _testSignUp() async {
    try {
      final user = await _authService.signUp(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
      );
      setState(() {
        _status = 'Sign up successful: ${user.email}';
      });
    } on AuthException catch (e) {
      setState(() {
        _status = 'Sign up failed: ${e.message}';
      });
    }
  }

  Future<void> _testSignIn() async {
    try {
      final user = await _authService.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );
      setState(() {
        _status = 'Sign in successful: ${user.email}';
      });
    } on AuthException catch (e) {
      setState(() {
        _status = 'Sign in failed: ${e.message}';
      });
    }
  }

  Future<void> _testGoogleSignIn() async {
    try {
      final user = await _authService.signInWithGoogle();
      setState(() {
        _status = 'Google sign in successful: ${user.email}';
      });
    } on AuthException catch (e) {
      setState(() {
        _status = 'Google sign in failed: ${e.message}';
      });
    }
  }

  Future<void> _testSignOut() async {
    try {
      await _authService.signOut();
      setState(() {
        _status = 'Sign out successful';
      });
    } on AuthException catch (e) {
      setState(() {
        _status = 'Sign out failed: ${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Status: $_status',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            if (_currentUser != null) ...[
              Text('User ID: ${_currentUser!.id}'),
              Text('Email: ${_currentUser!.email}'),
              Text('Display Name: ${_currentUser!.displayName ?? 'Not set'}'),
              Text('Email Verified: ${_currentUser!.isEmailVerified}'),
              const SizedBox(height: 20),
            ],
            ElevatedButton(
              onPressed: _testSignUp,
              child: const Text('Test Sign Up'),
            ),
            ElevatedButton(
              onPressed: _testSignIn,
              child: const Text('Test Sign In'),
            ),
            ElevatedButton(
              onPressed: _testGoogleSignIn,
              child: const Text('Test Google Sign In'),
            ),
            ElevatedButton(
              onPressed: _testSignOut,
              child: const Text('Test Sign Out'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}