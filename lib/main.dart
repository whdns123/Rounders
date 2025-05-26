import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'models/meeting.dart';
import 'screens/meeting_result_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/create_meeting_screen.dart';
import 'screens/host_application_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 한국어 로케일 초기화
  await initializeDateFormatting('ko_KR', null);

  // Firebase 초기화
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          return MaterialApp(
            title: 'Rounders',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              useMaterial3: true,
            ),
            locale: const Locale('ko', 'KR'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ko', 'KR'),
              Locale('en', 'US'),
            ],
            home: StreamBuilder<User?>(
              stream: authService.authStateChanges,
              builder: (context, snapshot) {
                // 로딩 중이면 로딩 화면 표시
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // 로그인 상태이면 홈 화면으로, 아니면 로그인 화면으로
                final user = snapshot.data;
                if (user != null) {
                  // 로그인된 사용자가 있으면 사용자 정보 초기화 확인
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Provider.of<FirestoreService>(context, listen: false)
                        .initializeUserProfile(user);
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
              '/create-meeting': (context) => const CreateMeetingScreen(),
              '/host-application': (context) => const HostApplicationScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/meeting-result') {
                final Meeting meeting = settings.arguments as Meeting;
                return MaterialPageRoute(
                  builder: (context) => MeetingResultScreen(meeting: meeting),
                );
              }
              return null;
            },
          );
        },
      ),
    );
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
