import 'package:flutter/material.dart';

class JobDetailScreen extends StatelessWidget {
  final String jobTitle;
  const JobDetailScreen({super.key, required this.jobTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(jobTitle)),
      body: Center(
        child: Text(
          'Détails de l\'offre : $jobTitle\n(TODO: Affichage du contenu complet)',
        ),
      ),
    );
  }
}
