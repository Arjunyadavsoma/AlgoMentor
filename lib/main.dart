import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase for Web and Mobile separately
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAMUMosKnsl58zfgJJZH8_WOLH4QpRk_GU",
        authDomain: "flutter-project-52d1f.firebaseapp.com",
        projectId: "flutter-project-52d1f",
        storageBucket: "flutter-project-52d1f.firebasestorage.app",
        messagingSenderId: "569805638929",
        appId: "1:569805638929:web:3131787d42d8c50cf6d0b0",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  // ✅ Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
