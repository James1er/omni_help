import 'package:flutter/material.dart';
import 'auth_screens.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // Icône représentative
              const Icon(Icons.public, size: 150, color: Colors.blue),

              Column(
                children: const [
                  Text(
                    'Bienvenue dans notre Communauté Globale !',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Collaborer sur idées révolutionnaires et trouvez des opportunités de carrière internationales.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 62, 58, 58),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              // Bouton CTA : "Démarrer"
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const AuthChoiceScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 15,
                  ),
                  shape: const StadiumBorder(), // Bouton moderne arrondi
                ),
                child: const Text('Démarrer', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
