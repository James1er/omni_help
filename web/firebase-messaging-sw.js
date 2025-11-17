/* eslint-disable no-undef */

// C'est un Service Worker par défaut requis par Firebase Messaging
// pour gérer les notifications PUSH sur le Web, même si l'application
// n'est pas ouverte.

// Importe les scripts et fonctions nécessaires pour Firebase Messaging.
importScripts('https://www.gstatic.com/firebasejs/9.1.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.1.0/firebase-messaging-compat.js');

// TODO: REMPLACER PAR VOTRE VRAIE CONFIGURATION FIREBASE
// En production, cette configuration est généralement injectée ou chargée dynamiquement.
// Pour l'instant, on utilise des valeurs de démo pour permettre l'enregistrement du Service Worker.
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT_ID.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID",
};

// Initialisation de Firebase
firebase.initializeApp(firebaseConfig);

// Initialisation de Firebase Messaging
const messaging = firebase.messaging();

// Gérer les messages en arrière-plan (facultatif, mais essentiel pour les notifications PUSH)
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  // Personnalisation de la notification affichée
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/favicon.png', // Assurez-vous d'avoir une icône dans le dossier web
    data: payload.data, // Données personnalisées
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Écoute des événements de clic de notification (facultatif)
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  // Logique pour ouvrir l'application ou une URL spécifique
  clients.openWindow('/'); 
});