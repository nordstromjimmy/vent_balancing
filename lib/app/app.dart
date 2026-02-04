import 'package:flutter/material.dart';
import '../features/projects/presentation/projects_list_page.dart';

class VentBalancingApp extends StatelessWidget {
  const VentBalancingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vent Balancing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey),
      home: const ProjectsListPage(),
    );
  }
}
