import 'package:firebase_core/firebase_core.dart';

/// Web SDK options for the share player. Add a **Web app** in Firebase Console
/// (Project settings → Your apps) and replace [appId] if Firestore init fails.
FirebaseOptions shareWebFirebaseOptions() {
  return const FirebaseOptions(
    apiKey: 'AIzaSyDFs4KrEfmvHWlBWoJLVKbt6PGAof7RKpM',
    appId: '1:468016404938:web:sharePlayerReplaceInFirebaseConsole',
    messagingSenderId: '468016404938',
    projectId: 'questionmaker-a821f',
    authDomain: 'questionmaker-a821f.firebaseapp.com',
    storageBucket: 'questionmaker-a821f.appspot.com',
  );
}
