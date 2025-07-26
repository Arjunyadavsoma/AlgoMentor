import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../models/user_model.dart';

/// 🔹 Abstract definition for authentication data source
abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  Future<UserModel> signInWithGoogle();

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> get authStateChanges;
}

/// 🔹 Implementation using FirebaseAuth + GoogleSignIn + Supabase
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final SupabaseClient _supabaseClient;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required SupabaseClient supabaseClient,
    required GoogleSignIn googleSignIn, // ✅ injected dependency
  })  : _firebaseAuth = firebaseAuth,
        _supabaseClient = supabaseClient,
        _googleSignIn = googleSignIn;

  // ---------------------------------------------------------------------------
  // 📌 EMAIL/PASSWORD SIGN-IN
  // ---------------------------------------------------------------------------
  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Sign in failed — no user returned.');
      }

      return _userToModel(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw Exception('Sign in failed: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 EMAIL/PASSWORD SIGN-UP
  // ---------------------------------------------------------------------------
  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Sign up failed — no user returned.');
      }

      // 🏷 Optionally set display name
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }

      // ✅ Store profile in Supabase
      await _createUserProfile(credential.user!);

      return _userToModel(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw Exception('Sign up failed: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 GOOGLE SIGN-IN (v7.1.1 flow)
  // ---------------------------------------------------------------------------

@override
Future<UserModel> signInWithGoogle() async {
  try {
    // ✅ Initialize GoogleSignIn
    await _googleSignIn.initialize();

    // ✅ Launch auth flow
    final googleUser = await _googleSignIn.authenticate();
    if (googleUser == null) {
      throw Exception('Google sign-in canceled by user.');
    }

    final auth = await googleUser.authentication;
    if (auth.idToken == null) {
      throw Exception('Missing Google ID token.');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: auth.idToken,
    );

    final userCred = await _firebaseAuth.signInWithCredential(credential);
    if (userCred.user == null) {
      throw Exception('Firebase user is null.');
    }

    await _createUserProfile(userCred.user!);
    return _userToModel(userCred.user!);
  } catch (e) {
    throw Exception('Google sign-in failed: $e');
  }
}




  // ---------------------------------------------------------------------------
  // 📌 SIGN OUT
  // ---------------------------------------------------------------------------
  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(), // ✅ signOut instead of disconnect for v7
      ]);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 GET CURRENT USER
  // ---------------------------------------------------------------------------
  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    return user != null ? _userToModel(user) : null;
  }

  // ---------------------------------------------------------------------------
  // 📌 AUTH STATE CHANGES (real-time stream)
  // ---------------------------------------------------------------------------
  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(
          (user) => user != null ? _userToModel(user) : null,
        );
  }

  // ---------------------------------------------------------------------------
  // 🔧 HELPER: Convert Firebase User → UserModel
  // ---------------------------------------------------------------------------
  UserModel _userToModel(User user) {
    if (user.email == null) {
      throw Exception('Firebase user email is null');
    }
    return UserModel(
      id: user.uid,
      email: user.email!,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  // ---------------------------------------------------------------------------
  // 🔧 HELPER: Create or update user profile in Supabase
  // ---------------------------------------------------------------------------
  Future<void> _createUserProfile(User user) async {
    try {
      final existingProfile = await _supabaseClient
          .from('profiles')
          .select('id')
          .eq('id', user.uid)
          .maybeSingle();

      if (existingProfile == null) {
        await _supabaseClient.from('profiles').insert({
          'id': user.uid,
          'email': user.email,
          'display_name': user.displayName,
          'photo_url': user.photoURL,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        await _supabaseClient.from('profiles').update({
          'email': user.email,
          'display_name': user.displayName,
          'photo_url': user.photoURL,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.uid);
      }
    } catch (e) {
      print('⚠️ Supabase user profile error: $e'); // Silent fail (non-blocking)
    }
  }
}
