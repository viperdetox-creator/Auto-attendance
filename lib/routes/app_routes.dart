import '../features/auth/login_screen.dart';

class AppRoutes {
  static const login = '/login';

  static final routes = {
    login: (context) => const LoginScreen(),
  };
}

