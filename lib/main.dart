import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import pour Firebase Core
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // NOUVEL IMPORT
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart'; // Import de l'écran d'accueil
import 'screens/conversation_screen.dart'; // NOUVEL IMPORT pour la navigation
// NOUVEL IMPORT

// --- NOUVEAU: Logique de notification ---

// Fonction pour demander la permission et sauvegarder le jeton FCM
Future<void> _setupFcm() async {
  final messaging = FirebaseMessaging.instance;

  // 1. Demander la permission à l'utilisateur
  await messaging.requestPermission();

  // 2. Obtenir le jeton de l'appareil
  final fcmToken = await messaging.getToken();
  debugPrint("FCM Token: $fcmToken");

  // 3. Sauvegarder le jeton dans le profil de l'utilisateur s'il est connecté
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null && fcmToken != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set(
          {'fcmToken': fcmToken},
          SetOptions(
            merge: true,
          ), // Utilise merge pour ne pas écraser les autres données
        );
  }
}

// NOUVEAU: GlobalKey pour la navigation sans BuildContext
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// NOUVEAU: Gère les messages FCM lorsque l'app est en arrière-plan ou terminée
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Si vous avez besoin d'initialiser des choses, faites-le ici.
  // Par exemple, si vous utilisez un autre plugin qui doit être initialisé.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Gestion d'un message en arrière-plan: ${message.messageId}");
}

// NOUVEAU: Logique complète de gestion des notifications
Future<void> _setupNotificationHandlers() async {
  // Gère les messages lorsque l'app est terminée et qu'on clique sur la notif
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      _navigateToChat(message.data);
    }
  });

  // Gère les messages lorsque l'app est en arrière-plan et qu'on clique sur la notif
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _navigateToChat(message.data);
  });

  // Gère les messages lorsque l'app est au premier plan (ne crée pas de notif système)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Message reçu au premier plan: ${message.notification?.title}');
    // Ici, vous pourriez afficher une SnackBar ou une alerte locale si vous le souhaitez.
  });
}

void _navigateToChat(Map<String, dynamic> data) {
  final chatId = data['chatId'];
  final chatPartnerName = data['chatPartnerName'];
  if (chatId != null && chatPartnerName != null) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ConversationScreen(
          chatId: chatId,
          chatPartnerName: chatPartnerName,
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // Utilise la configuration générée
  );

  // Configuration FCM complète
  await _setupFcm();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // Ne pas await ici, car il configure des listeners
  _setupNotificationHandlers();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projet Communautaire Global',
      navigatorKey: navigatorKey, // Attribuer le GlobalKey
      debugShowCheckedModeBanner: false, // Enlève la bannière "Debug"
      theme:
          ThemeData.from(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(
                0xFF26A69A,
              ), // Une couleur "vert d'eau" agréable
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ).copyWith(
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            appBarTheme: const AppBarTheme(centerTitle: true),
          ),
      // Démarrage dynamique en fonction de l'état de connexion de l'utilisateur
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance
            .authStateChanges(), // Utilise le stream natif de Firebase
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          // Pendant le chargement de la vérification
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Si l'utilisateur est connecté, on va à l'accueil
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }

          // Sinon, on affiche l'écran de bienvenue pour qu'il se connecte/s'inscrive
          return const OnboardingScreen();
        },
      ),
    );
  }
}
