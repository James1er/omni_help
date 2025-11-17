import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// Importez les nouveaux écrans de destination
import 'job_form_screen.dart'; // Pour le formulaire de publication d'offre
import 'job_detail_screen.dart'; // Pour le détail de l'offre

class JobPortalScreen extends StatelessWidget {
  const JobPortalScreen({super.key});

  final List<String> dummyJobs = const [
    'Stage Flutter (Paris)',
    'Développeur IA (Remote)',
    'Chef de Projet Agricole (Dakar)',
  ];

  Future<void> _applyForJob(BuildContext context, String jobTitle) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'recruteur@example.com', // Placeholder email
      queryParameters: {
        'subject': 'Candidature pour le poste: $jobTitle',
      },
    );

    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application de messagerie.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portail Emploi / Stage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.business),
            onPressed: () {
              // ✅ CORRECTION: Naviguer vers le formulaire de soumission d'offre pour les entreprises
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const JobFormScreen()),
              );
            },
            tooltip: 'Publier une offre',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: dummyJobs.length,
        itemBuilder: (context, index) {
          final jobTitle = dummyJobs[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.work_outline),
              title: Text(
                jobTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Entreprise X | Domaine Informatique'),
              trailing: ElevatedButton(
                onPressed: () => _applyForJob(context, jobTitle),
                child: const Text('Postuler'),
              ),
              onTap: () {
                // ✅ CORRECTION: Naviguer vers le détail de l'offre
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => JobDetailScreen(jobTitle: jobTitle),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}