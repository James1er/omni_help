import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Pour sélectionner le fichier PDF
import 'package:cloud_firestore/cloud_firestore.dart'; // Import UTILISÉ pour la sauvegarde
import 'package:firebase_auth/firebase_auth.dart'; // Import UTILISÉ pour l'ID utilisateur
import 'package:firebase_storage/firebase_storage.dart'; // Import pour Firebase Storage
import 'dart:io';

class JobFormScreen extends StatefulWidget {
  const JobFormScreen({super.key});

  @override
  State<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends State<JobFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();

  String? selectedJobType;
  File? _selectedFile; // Fichier sélectionné par l'utilisateur (CV/document)

  // Cette variable DOIT rester modifiable (non-final) car elle change d'état
  bool _isLoading = false;

  final List<String> jobTypes = const [
    'Temps plein',
    'Temps partiel',
    'Freelance/Contractuel',
    'Stage',
  ];

  // --- LOGIQUE DE SÉLECTION DE FICHIER (TODO: Implémentation) ---
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      // Nous prenons le premier fichier sélectionné
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier sélectionné : ${result.files.single.name}'),
          ),
        );
      }
    }
  }

  // --- LOGIQUE DE SOUMISSION DU FORMULAIRE (CORRECTION: Utilisation des imports) ---
  Future<void> _submitJobOffer() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez remplir tous les champs requis.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Utilisateur non connecté.");
      }

      String? uploadedFileUrl;
      if (_selectedFile != null) {
        // Crée une référence unique pour le fichier dans Firebase Storage
        final ref = FirebaseStorage.instance
            .ref()
            .child('job_documents')
            .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}');
        
        // Uploade le fichier
        await ref.putFile(_selectedFile!);
        
        // Récupère l'URL de téléchargement
        uploadedFileUrl = await ref.getDownloadURL();
      }

      // Création du JSON (Map Dart) pour Firestore
      Map<String, dynamic> jobData = {
        'title': _titleController.text.trim(),
        'company': _companyController.text.trim(),
        'description': _descriptionController.text.trim(),
        'contactEmail': _contactEmailController.text.trim(),
        'jobType': selectedJobType,
        'documentUrl': uploadedFileUrl, // URL du fichier uploadé
        'ownerId': user.uid,
        'ownerName': user.displayName ?? 'Anonyme',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Sauvegarde des données dans la collection 'job_offers' de Firestore
      await FirebaseFirestore.instance.collection('job_offers').add(jobData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offre d\'emploi soumise avec succès !'),
          ),
        );
        Navigator.pop(context); // Retour à l'écran précédent
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de soumission : $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Soumettre une Offre d\'Emploi')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            // --- Champ Titre ---
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titre du Poste'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Veuillez entrer le titre du poste.'
                  : null,
            ),
            const SizedBox(height: 15),

            // --- Champ Société ---
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: 'Nom de la Société'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Veuillez entrer le nom de la société.'
                  : null,
            ),
            const SizedBox(height: 15),

            // --- Champ Description ---
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description de l\'Offre',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) => value == null || value.isEmpty
                  ? 'Veuillez décrire l\'offre.'
                  : null,
            ),
            const SizedBox(height: 15),

            // --- Type d'Emploi (Correction: `value` -> `initialValue`) ---
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Type d\'Emploi',
                border: OutlineInputBorder(),
              ),
              // Utilisation de `initialValue` au lieu de `value`
              initialValue: selectedJobType,
              hint: const Text('Sélectionnez le type d\'emploi'),
              items: jobTypes.map((String type) {
                return DropdownMenuItem<String>(value: type, child: Text(type));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedJobType = newValue;
                });
              },
              validator: (value) =>
                  value == null ? 'Veuillez sélectionner un type.' : null,
            ),
            const SizedBox(height: 15),

            // --- E-mail de Contact ---
            TextFormField(
              controller: _contactEmailController,
              decoration: const InputDecoration(labelText: 'E-mail de Contact'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Veuillez entrer un e-mail valide.';
                }
                return null;
              },
            ),
            const SizedBox(height: 25),

            // --- Sélecteur de Fichier (Document/Cahier des charges) ---
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(
                _selectedFile == null
                    ? 'Ajouter un cahier des charges (PDF, DOC)'
                    : 'Fichier sélectionné: ${_selectedFile!.path.split('/').last}',
              ),
              trailing: const Icon(Icons.file_upload),
              onTap: _pickFile,
            ),
            const SizedBox(height: 30),

            // --- Bouton de Soumission ---
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitJobOffer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(15),
                    ),
                    child: const Text(
                      'Soumettre l\'Offre',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
