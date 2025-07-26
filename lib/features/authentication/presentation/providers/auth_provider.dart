import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';

/// ✅ FirebaseAuth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// ✅ GoogleSignIn instance (new v7.x API uses `instance`)
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn.instance; // ✅ fixed for v7.x
});

/// ✅ Supabase client instance
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// ✅ AuthRemoteDataSource provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    supabaseClient: ref.watch(supabaseClientProvider),
    googleSignIn: ref.watch(googleSignInProvider), // ✅ properly injected
  );
});

/// ✅ AuthRepository provider
final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

/// ✅ Use Cases
final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.watch(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

/// ✅ Auth State Stream (for real-time auth changes)
final authStateProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// ✅ StateNotifier for managing auth actions (Sign In / Out / etc.)
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserEntity?>>((ref) {
  return AuthController(
    signInUseCase: ref.watch(signInUseCaseProvider),
    signUpUseCase: ref.watch(signUpUseCaseProvider),
    repository: ref.watch(authRepositoryProvider),
  );
});

/// ✅ StateNotifier class for Authentication Actions
class AuthController extends StateNotifier<AsyncValue<UserEntity?>> {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final AuthRepositoryImpl _repository;

  AuthController({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required AuthRepositoryImpl repository,
  })  : _signInUseCase = signInUseCase,
        _signUpUseCase = signUpUseCase,
        _repository = repository,
        super(const AsyncValue.data(null));

  /// 🔑 Email/Password Sign In
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await _signInUseCase(email: email, password: password);
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (user) => state = AsyncValue.data(user),
    );
  }

  /// 🔑 Email/Password Sign Up
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    final result = await _signUpUseCase(
      email: email,
      password: password,
      displayName: displayName,
    );
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (user) => state = AsyncValue.data(user),
    );
  }

  /// 🔑 Google Sign-In (v7.x flow)
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await _repository.signInWithGoogle();
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (user) => state = AsyncValue.data(user),
    );
  }

  /// 🚪 Sign Out
  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }
}
