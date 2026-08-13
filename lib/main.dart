import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/chess_game_state.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChessEngineApp());
}

class ChessEngineApp extends StatelessWidget {
  const ChessEngineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChessGameState()),
      ],
      child: MaterialApp(
        title: 'Chess Engine & Overlay Assistant',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
