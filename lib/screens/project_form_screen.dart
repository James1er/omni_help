import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Pour sélectionner l'image/vidéo
import 'package:cloud_firestore/cloud_firestore.dart'; // Pour la base de données (JSON)
import 'package:firebase_auth/firebase_auth.dart'; // Pour obtenir l'ID de l'utilisateur
import 'dart:io'; // Pour utiliser le type File
import 'package:firebase_storage/firebase_storage.dart'; // Import pour Firebase Storage (nécessaire pour l'upload réel)

class ProjectFormScreen extends StatefulWidget {
  // Paramètre optionnel pour l'édition
  final QueryDocumentSnapshot<Map<String, dynamic>>? projectToEdit;

  const ProjectFormScreen({super.key, this.projectToEdit});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  // Clé pour la validation du formulaire
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs de texte
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  // État des sélections
  String? selectedDomain;
  File? _selectedFile; // Fichier sélectionné par l'utilisateur (image/vidéo)
  String? _existingMediaUrl; // URL du média existant si en mode édition
  bool _isLoading = false;

  final List<String> domains = const [
    'Technologie et IT',
    'Environnement et Climat',
    'Éducation et Formation',
    'Santé et Bien-être',
    'Art et Culture',
    'Agriculture et Alimentation',
  ];

  @override
  void initState() {
    super.initState();

    // Si nous sommes en mode édition, pré-remplir les champs
    if (widget.projectToEdit != null) {
      final data = widget.projectToEdit!.data();
      _titleController.text = data['title'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _budgetController.text = (data['budget'] as num?)?.toString() ?? '';
      selectedDomain = data['domain'];
      _existingMediaUrl = data['mediaUrl'];
    }
  }

  // --- LOGIQUE DE SÉLECTION DE FICHIER ---
  Future<void> _pickMedia() async {
    // NOTE: On utilise pickImage pour simplifier, mais on pourrait utiliser pickMedia pour tous les types.
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
        // Effacer l'URL existante car un nouveau fichier a été sélectionné
        _existingMediaUrl = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nouveau fichier sélectionné : ${pickedFile.name}'),
          ),
        );
      }
    }
  }

  // --- LOGIQUE D'UPLOAD VERS STORAGE (Simulation) ---
  Future<String> _uploadMedia(File file, String ownerId) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref = FirebaseStorage.instance
        .ref()
        .child('project_media')
        .child(ownerId)
        .child(fileName);

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // --- LOGIQUE DE SOUMISSION DU FORMULAIRE (Sauvegarde ou Mise à Jour) ---
  Future<void> _submitProject() async {
    // La validation échoue si : le formulaire est invalide OU nous sommes en mode création
    // et aucun fichier n'a été sélectionné (car en édition, _existingMediaUrl peut exister)
    if (!_formKey.currentState!.validate() ||
        (widget.projectToEdit == null &&
            _selectedFile == null &&
            (_existingMediaUrl == null || _existingMediaUrl!.isEmpty))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez remplir tous les champs et sélectionner un média.',
            ),
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

      String mediaUrl = _existingMediaUrl ?? '';

      // 1. Upload du nouveau fichier si sélectionné
      if (_selectedFile != null) {
        mediaUrl = await _uploadMedia(_selectedFile!, user.uid);
      }

      // 2. Création du JSON (Map Dart) pour Firestore
      final title = _titleController.text.trim();
      Map<String, dynamic> projectData = {
        'title': title,
        'description': _descriptionController.text.trim(),
        'budget': double.tryParse(_budgetController.text) ?? 0.0,
        'domain': selectedDomain,
        'mediaUrl': mediaUrl, // URL gérée par l'édition/création
        'searchableTitle': title
            .toLowerCase(), // Add lowercase field for searching
        'ownerId': user.uid,
        'ownerName': user.displayName ?? 'Anonyme',
      };

      if (widget.projectToEdit == null) {
        // Mode Création
        projectData['status'] = 'En attente';
        projectData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('projects')
            .add(projectData);
      } else {
        // Mode Édition
        // Note: Conserver le statut et la date de création existants sauf modification explicite
        projectData['updatedAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectToEdit!.id)
            .update(projectData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Projet ${widget.projectToEdit == null ? 'soumis' : 'mis à jour'} avec succès !',
            ),
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
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  // Détermine le texte du bouton de soumission
  String get _submitButtonText => widget.projectToEdit == null
      ? 'Soumettre le Projet'
      : 'Mettre à Jour le Projet';
  // Détermine le texte de l'AppBar
  String get _appBarTitle => widget.projectToEdit == null
      ? 'Soumettre un Nouveau Projet'
      : 'Modifier le Projet';

  @override
  Widget build(BuildContext context) {
    // Détermine le texte affiché pour le média sélectionné ou existant
    String mediaText;
    if (_selectedFile != null) {
      mediaText =
          'Nouveau fichier sélectionné: ${_selectedFile!.path.split('/').last}';
    } else if (_existingMediaUrl != null && _existingMediaUrl!.isNotEmpty) {
      mediaText = 'Fichier existant (cliquer pour changer)';
    } else {
      mediaText = 'Ajouter une image, vidéo ou un PDF';
    }

    return Scaffold(
      appBar: AppBar(title: Text(_appBarTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            // --- Champ Titre ---
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titre du Projet'),
              enableInteractiveSelection:
                  true, // Assurer que le copier-coller est activé
              validator: (value) => value == null || value.isEmpty
                  ? 'Veuillez entrer un titre.'
                  : null,
            ),
            const SizedBox(height: 15),

            // --- Champ Description ---
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description détaillée',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              enableInteractiveSelection:
                  true, // Assurer que le copier-coller est activé
              validator: (value) => value == null || value.isEmpty
                  ? 'Veuillez décrire votre projet.'
                  : null,
            ),
            const SizedBox(height: 15),

            // --- Domaine du Projet ---
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Domaine du Projet',
                border: OutlineInputBorder(),
              ),
              initialValue:
                  selectedDomain, // Utilisation de `value` car il est mis à jour dans `initState`
              hint: const Text('Sélectionnez le domaine principal'),
              items: domains.map((String domain) {
                return DropdownMenuItem<String>(
                  value: domain,
                  child: Text(domain),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedDomain = newValue;
                });
              },
              validator: (value) =>
                  value == null ? 'Veuillez sélectionner un domaine.' : null,
            ),
            const SizedBox(height: 15),

            // --- Champ Budget Estimé ---
            TextFormField(
              controller: _budgetController,
              decoration: const InputDecoration(labelText: 'Budget Estimé (€)'),
              keyboardType: TextInputType.number,
              enableInteractiveSelection:
                  true, // Assurer que le copier-coller est activé
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return 'Veuillez entrer un montant valide.';
                }
                return null;
              },
            ),

            const SizedBox(height: 25),

            // --- Sélecteur de Média ---
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(mediaText),
              trailing: const Icon(Icons.upload_file),
              onTap: _pickMedia,
            ),

            // --- Aperçu du Média ---

            // 1. Afficher l'aperçu du nouveau fichier sélectionné
            if (_selectedFile != null &&
                (_selectedFile!.path.endsWith('.jpg') ||
                    _selectedFile!.path.endsWith('.png')))
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Image.file(
                  _selectedFile!,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              )
            // 2. Sinon, afficher l'aperçu du fichier existant (en mode édition)
            else if (_existingMediaUrl != null && _existingMediaUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Image.network(
                  _existingMediaUrl!,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text('Image existante non affichable'),
                    ),
                  ),
                ),
              ),

            // Espace avant le bouton de soumission
            const SizedBox(height: 30),

            // --- Bouton de Soumission ---
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitProject,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(15),
                    ),
                    child: Text(
                      _submitButtonText,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
