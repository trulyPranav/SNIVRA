import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/core/network/api_client.dart';
import 'src/features/auth/data/auth_repository.dart';
import 'src/features/auth/presentation/bloc/auth_bloc.dart';
import 'src/features/saloon/data/saloon_repository.dart';
import 'src/features/seat/data/seat_repository.dart';
import 'src/features/splash/presentation/splash_page.dart';
import 'src/features/time_slot/data/time_slot_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient();
  final authRepository = AuthRepository(apiClient: apiClient);
  final saloonRepository = SaloonRepository(apiClient: apiClient);
  final seatRepository = SeatRepository(apiClient: apiClient);
  final timeSlotRepository = TimeSlotRepository(apiClient: apiClient);

  runApp(
    SNIVRAApp(
      authRepository: authRepository,
      saloonRepository: saloonRepository,
      seatRepository: seatRepository,
      timeSlotRepository: timeSlotRepository,
    ),
  );
}

class SNIVRAApp extends StatelessWidget {
  const SNIVRAApp({
    super.key,
    required this.authRepository,
    required this.saloonRepository,
    required this.seatRepository,
    required this.timeSlotRepository,
  });

  final AuthRepository authRepository;
  final SaloonRepository saloonRepository;
  final SeatRepository seatRepository;
  final TimeSlotRepository timeSlotRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: saloonRepository),
        RepositoryProvider.value(value: seatRepository),
        RepositoryProvider.value(value: timeSlotRepository),
      ],
      child: BlocProvider(
        create: (_) => AuthBloc(authRepository: authRepository),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SNIVRA',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFB07C4F),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF5EFE8),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.85),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFB07C4F), width: 1.4),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D1B19),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
              ),
            ),
          ),
          home: const SplashPage(),
        ),
      ),
    );
  }
}
