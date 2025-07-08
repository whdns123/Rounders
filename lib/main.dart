import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/favorites_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/host_application_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 한국어 로케일 초기화
  await initializeDateFormatting('ko_KR', null);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      print('✅ Firebase 초기화 성공');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Firebase 초기화 오류: $e');
    }
    // Firebase 오류가 있어도 앱은 계속 실행
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    _initializeApp(); // 앱 초기화

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProxyProvider<FirestoreService, FavoritesProvider>(
          create: (context) => FavoritesProvider(
            Provider.of<FirestoreService>(context, listen: false),
          ),
          update: (context, firestoreService, previous) =>
              previous ?? FavoritesProvider(firestoreService),
        ),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          return MaterialApp(
            title: 'Roundus',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              useMaterial3: true,
              // 전역 비활성화 버튼 색상 설정
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: const Color(0xFFC2C2C2), // 비활성화 배경색
                  disabledForegroundColor: const Color(
                    0xFF111111,
                  ), // 비활성화 텍스트색 (어두운 배경에 맞게)
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  disabledForegroundColor: const Color(0xFFC2C2C2), // 비활성화 텍스트색
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  disabledForegroundColor: const Color(0xFFC2C2C2), // 비활성화 텍스트색
                ),
              ),
            ),
            locale: const Locale('ko', 'KR'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
            home: StreamBuilder<User?>(
              stream: authService.authStateChanges,
              builder: (context, snapshot) {
                // 로딩 중이면 로딩 화면 표시
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // 로그인 상태이면 홈 화면으로, 아니면 로그인 화면으로
                final user = snapshot.data;
                if (user != null) {
                  // 로그인된 사용자가 있으면 사용자 정보 초기화 확인
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Provider.of<FirestoreService>(
                      context,
                      listen: false,
                    ).initializeUserProfile(user);
                  });
                  return const HomeScreen();
                } else {
                  // 로그인 화면으로 이동
                  return const LoginScreen();
                }
              },
            ),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/home': (context) => const HomeScreen(),
              '/host-application': (context) => const HostApplicationScreen(),
            },
          );
        },
      ),
    );
  }

  void _initializeApp() async {
    try {
      if (kDebugMode) {
        print('✅ Firebase 초기화 성공');
      }

      // 샘플 게임 데이터 추가 (한 번만 실행)
      final firestoreService = FirestoreService();
      // await firestoreService.addSampleGames(); // 자동 생성 비활성화
      if (kDebugMode) {
        print('✅ 샘플 게임 데이터 추가 완료');
      }

      // 앱 시작 시 만료된 모임들의 상태를 자동으로 업데이트
      firestoreService.updateExpiredMeetingsStatus().catchError((e) {
        if (kDebugMode) {
          print('⚠️ 앱 시작 시 모임 상태 자동 업데이트 중 오류: $e');
        }
      });
      if (kDebugMode) {
        print('🔄 앱 시작 시 모임 상태 자동 업데이트 시작');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 앱 초기화 실패: $e');
      }
    }
  }
}

// 주석 처리 또는 삭제
// Map<String, WidgetBuilder> routes = {
//   '/': (context) => const SplashScreen(),
//   '/login': (context) => const LoginScreen(),
//   '/signup': (context) => const SignupScreen(),
//   '/home': (context) => const HomeScreen(),
//   '/create-meeting': (context) => const CreateMeetingScreen(),
//   '/meeting-result': (context) => MeetingResultScreen(
//         meeting: ModalRoute.of(context)!.settings.arguments as Meeting,
//       ),
// };
