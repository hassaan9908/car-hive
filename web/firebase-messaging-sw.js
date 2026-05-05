importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCd1oSSITOW_0epwLHfNYJ1F2zFmfUHQgU",
  authDomain: "carhive-bf048.firebaseapp.com",
  projectId: "carhive-bf048",
  storageBucket: "carhive-bf048.firebasestorage.app",
  messagingSenderId: "1043251250775",
  appId: "1:1043251250775:web:4806edf021e7190f890512",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification;
  self.registration.showNotification(title, { body });
});
