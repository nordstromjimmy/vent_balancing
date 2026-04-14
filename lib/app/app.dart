import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../features/projects/presentation/projects_list_page.dart';

class VentBalancingApp extends StatelessWidget {
  const VentBalancingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vent Balancing',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(), // ← was: ThemeData(useMaterial3: true, ...)
      home: const ProjectsListPage(),
    );
  }
}
