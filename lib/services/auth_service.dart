import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A service class to handle all authentication-related logic.
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream for authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get the current authenticated user.
  User? get currentUser => _auth.currentUser;

  /// Sign in with Google and create a user document in Firestore if it's a new user.
  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
    if (googleUser == null) {
      // User canceled the sign-in.
      return null;
    }

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      // Create user document if it doesn't exist.
      final userDoc = _firestore.collection('users').doc(user.uid);
      final snapshot = await userDoc.get();
      if (!snapshot.exists) {
        await userDoc.set({
          'displayName': user.displayName,
          'email': user.email,
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'user',
        });
      }
    }
    return user;
  }

  /// Sign in a user with their email and password.
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  /// Register a new user with email, password, and username.
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      // Update display name
      await user.updateDisplayName(username);

      // Create user document in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': username,
        'email': email,
        'uid': user.uid,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return user;
  }

  /// Send a password reset email to the given email address.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Sign out the current user from both Firebase and Google.
  Future<void> signOut() async {
    // Check if the user signed in with Google to avoid unnecessary sign-out calls.
    final isGoogleUser =
        _auth.currentUser?.providerData.any(
          (info) => info.providerId == 'google.com',
        ) ??
        false;

    if (isGoogleUser) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }
}
