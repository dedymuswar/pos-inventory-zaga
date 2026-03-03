import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pos_inventory/features/auth/pages/login_page.dart';
import 'package:provider/provider.dart';
import 'package:pos_inventory/features/user/auth_controller.dart';

final colorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xff1D61E7),
);

final theme = ThemeData(
  colorScheme: colorScheme,
  useMaterial3: true,
  textTheme: GoogleFonts.robotoTextTheme(),
  elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xff1D61E7),
    foregroundColor: Colors.white,
    elevation: 0,
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ))
);
// .copyWith(
//   textTheme: GoogleFonts.ubuntuCondensedTextTheme().copyWith(
//     titleSmall: GoogleFonts.ubuntuCondensed(
//       fontWeight: FontWeight.bold,
//     ),
//     titleMedium:GoogleFonts.ubuntuCondensed(
//       fontWeight: FontWeight.bold,
//     ),
//     titleLarge: GoogleFonts.ubuntuCondensed(
//       fontWeight: FontWeight.bold,
//     ),
//   ),

// );

void main(List<String> args) {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: const MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {
  
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // return MaterialApp(title: 'POS MASTER BARANG', home: ProductPage());
    return MaterialApp(title: 'POS MASTER BARANG', theme: theme, home: LoginPage());
  }
}
