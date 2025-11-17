import 'package:flutter/material.dart';
import 'package:omni_help/screens/carrier_space_screen.dart';
import 'package:omni_help/widgets/state_indicators.dart';
import '../widgets/project_card.dart';
import 'project_form_screen.dart';
import 'job_portal_screen.dart';
// NOUVEAUX IMPORTS NÉCESSAIRES POUR LE DRAWER ET LA DÉCONNEXION
import 'package:cloud_firestore/cloud_firestore.dart'; // Import pour Firestore
import 'package:omni_help/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Pour récupérer l'utilisateur et se déconnecter
// NOUVEL IMPORT
import 'conversations_list_screen.dart';
import 'moderation_screen.dart'; // NOUVEL IMPORT
import 'favorites_screen.dart'; // NOUVEL IMPORT

class HomeScreen extends StatefulWidget {
  // NOUVEAU: Injection de dépendance pour la testabilité
  final FirebaseAuth? auth;

  const HomeScreen({super.key, this.auth});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Récupérer l'instance de l'utilisateur connecté
  late final User? _user;
  // NOUVEAU: État pour les claims de l'utilisateur (admin/modérateur)
  late final FirebaseAuth _auth;

  bool _isModerator = false;
  bool _isAdmin = false;

  // --- NOUVEAU: États pour la recherche et le filtrage ---
  String _searchQuery = '';
  String? _selectedDomain;
  // NOUVEAU: État pour les tags
  final List<String> _selectedTags = [];
  final TextEditingController _searchController = TextEditingController();

  // Liste des domaines pour le filtre (doit correspondre à celle de project_form_screen.dart)
  final List<String> _domains = const [
    'Informatique / IT',
    'Agriculture / Agroalimentaire',
    'Énergies Renouvelables',
    'Éducation & Formation',
    'Santé & Bien-être',
    'Art & Culture',
    'Transport & Logistique',
    'Autre',
  ];

  // Méthode pour gérer la déconnexion
  Future<void> _signOut() async {
    // La navigation est gérée par le StreamBuilder dans main.dart
    // Il suffit d'appeler la méthode de déconnexion de FirebaseAuth.
    // Le try-catch est une bonne pratique si la déconnexion peut échouer.
    try {
      // Utiliser le AuthService pour une déconnexion complète (Firebase + Google)
      await AuthService().signOut();
    } catch (e) {
      debugPrint("Erreur lors de la déconnexion: $e");
    }
  }

  // --- NOUVEAU: Méthode pour afficher le filtre des domaines ---
  void _showDomainFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount:
              _domains.length + 1, // +1 pour l'option "Tous les domaines"
          itemBuilder: (context, index) {
            if (index == 0) {
              // Option pour réinitialiser le filtre
              return ListTile(
                title: const Text(
                  'Tous les domaines',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  setState(() {
                    _selectedDomain = null;
                  });
                  Navigator.pop(context);
                },
              );
            }
            final domain = _domains[index - 1];
            return ListTile(
              title: Text(domain),
              onTap: () {
                setState(() {
                  _selectedDomain = domain;
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  // --- NOUVEAU: Méthode pour afficher le filtre des tags ---
  void _showTagFilter() async {
    // 1. OPTIMISATION: Récupérer les tags depuis la collection dédiée 'tags'
    final tagsSnapshot = await FirebaseFirestore.instance
        .collection('tags')
        .get();
    // On récupère l'ID (le nom du tag) et le compteur
    final allTags = tagsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.id, 'count': data['projectCount'] ?? 0};
    }).toList();
    allTags.sort(
      (a, b) => (a['id'] as String).compareTo(b['id'] as String),
    ); // Pour un affichage alphabétique

    if (!mounted) return;

    // 2. Afficher la modale avec les tags
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: allTags.map((tagData) {
            final tag = tagData['id'] as String;
            final count = tagData['count'] as int;
            return CheckboxListTile(
              title: Text('$tag ($count)'), // Affiche le tag avec son compteur
              value: _selectedTags.contains(tag),
              onChanged: (bool? isSelected) {
                setState(() {
                  if (isSelected == true) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
                Navigator.pop(
                  context,
                ); // Ferme et ré-ouvre pour voir le changement
                _showTagFilter(); // Permet de sélectionner plusieurs tags sans fermer
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _auth = widget.auth ?? FirebaseAuth.instance;
    _user = _auth.currentUser;
    _checkUserRole(); // Vérifier le rôle de l'utilisateur au démarrage
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  // NOUVEAU: Méthode pour vérifier les claims de l'utilisateur
  Future<void> _checkUserRole() async {
    if (_user == null) return;
    try {
      final idTokenResult = await _user.getIdTokenResult(
        true,
      ); // Forcer le rafraîchissement
      final claims = idTokenResult.claims ?? {};
      setState(() {
        _isModerator = claims['moderator'] == true;
        _isAdmin = claims['admin'] == true;
      });
    } catch (e) {
      debugPrint("Erreur lors de la vérification du rôle de l'utilisateur: $e");
      // Gérer l'erreur si nécessaire
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- NOUVEAU: Méthode pour confirmer la déconnexion ---
  Future<void> _confirmSignOut() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _signOut();
    }
  }

  // --- Le Drawer (Tiroir de Navigation) ---
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            // NOUVEAU: Affichage du nom avec un badge de rôle conditionnel
            accountName: Row(
              children: [
                Flexible(
                  child: Text(
                    _user?.displayName ?? 'Nom non défini',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (_isAdmin)
                  const Chip(
                    label: Text('Admin', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.zero,
                  )
                else if (_isModerator)
                  const Chip(
                    label: Text('Modo', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            accountEmail: Text(
              _user?.email ?? 'Email non défini',
            ), // Affiche l'email
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.blue),
            ),
            decoration: const BoxDecoration(color: Colors.blue),
          ),
          ListTile(
            leading: const Icon(Icons.feed),
            title: const Text('Fil des Projets'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.business_center),
            title: const Text('Mon Espace Porteur'),
            onTap: () {
              // ✅ CORRECTION: Naviguer vers l'espace porteur
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CarrierSpaceScreen(),
                ),
              );
            },
          ),
          // NOUVEAU: Lien vers les favoris
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.redAccent),
            title: const Text('Mes Favoris'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('Trouver un emploi / un stage'),
            onTap: () {
              // Naviguer vers le portail emploi
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const JobPortalScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messagerie Interne'),
            onTap: () {
              // ✅ CORRECTION: Naviguer vers l'écran de Chat
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ConversationsListScreen(),
                ),
              );
            },
          ),
          // NOUVEAU: Lien vers l'écran de modération (conditionnel)
          if (_isModerator || _isAdmin)
            ListTile(
              leading: const Icon(Icons.gavel, color: Colors.orange),
              title: const Text('Modération'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ModerationScreen(),
                  ),
                );
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion'),
            // ✅ CORRECTION: Appeler la méthode de déconnexion
            onTap: _confirmSignOut,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projets'),
        actions: [
          // --- NOUVEAU: Icône de filtre ---
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _selectedDomain != null ? Colors.blue : null,
            ),
            onPressed: _showDomainFilter,
            tooltip: 'Filtrer par domaine',
          ),
          // --- NOUVEAU: Icône de filtre pour les tags ---
          IconButton(
            icon: Icon(
              Icons.label,
              color: _selectedTags.isNotEmpty ? Colors.blue : null,
            ),
            onPressed: _showTagFilter,
            tooltip: 'Filtrer par tags',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              /* La recherche est maintenant gérée par le champ de texte ci-dessous */
            },
          ),
        ],
      ),

      // Ajout du Drawer
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          // --- NOUVEAU: Barre de recherche ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher par titre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          // --- NOUVEAU: Affichage du filtre actif ---
          if (_selectedDomain != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Chip(
                label: Text('Filtre: $_selectedDomain'),
                onDeleted: () {
                  setState(() {
                    _selectedDomain = null;
                  });
                },
              ),
            ),
          // --- NOUVEAU: Affichage des filtres de tags actifs ---
          if (_selectedTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Wrap(
                spacing: 8.0,
                children: _selectedTags
                    .map(
                      (tag) => Chip(
                        label: Text('Tag: $tag'),
                        onDeleted: () {
                          setState(() {
                            _selectedTags.remove(tag);
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          // --- StreamBuilder mis à jour pour la recherche/filtre ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildProjectStream(),
              builder: (context, snapshot) {
                // 1. Utiliser un widget de chargement dédié
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }
                // 2. Utiliser un widget d'erreur dédié avec une action
                if (snapshot.hasError) {
                  return ErrorView(
                    message: 'Impossible de charger les projets.',
                    onRetry: () => setState(() {
                      // Forcer la reconstruction du widget pour relancer le stream
                    }),
                  );
                }
                // 3. Gérer le cas où il n'y a aucun résultat
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun projet ne correspond à votre recherche.',
                    ),
                  );
                }

                // 4. Si tout va bien, on construit la liste
                final projects = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    return ProjectCard(project: projects[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Le Floating Action Button pour ajouter un projet
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Naviguer vers le formulaire d'ajout de projet
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ProjectFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- NOUVEAU: Méthode pour construire la requête Firestore dynamiquement ---
  Stream<QuerySnapshot> _buildProjectStream() {
    Query query = FirebaseFirestore.instance.collection('projects');

    // Appliquer le filtre de domaine s'il est sélectionné
    if (_selectedDomain != null) {
      query = query.where('domain', isEqualTo: _selectedDomain);
    }

    // Appliquer le filtre de recherche par titre (recherche de préfixe)
    // This is now case-insensitive
    if (_searchQuery.isNotEmpty) {
      query = query
          .where(
            'searchableTitle',
            isGreaterThanOrEqualTo: _searchQuery.toLowerCase(),
          )
          .where(
            'searchableTitle',
            isLessThanOrEqualTo: '${_searchQuery.toLowerCase()}\uf8ff',
          );
    }

    // --- NOUVEAU: Appliquer le filtre de tags ---
    if (_selectedTags.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: _selectedTags);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }
}
