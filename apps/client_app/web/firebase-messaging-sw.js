importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDZPvmE19PIxRzOc69lDdRZzCnBkY2ucWY",
  authDomain: "gannaty-f16cc.firebaseapp.com",
  projectId: "gannaty-f16cc",
  storageBucket: "gannaty-f16cc.firebasestorage.app",
  messagingSenderId: "766707217406",
  appId: "1:766707217406:web:d6eaad14fb1b16e8be06af",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? "Gannaty";
  const body = payload.notification?.body ?? "";
  return self.registration.showNotification(title, {
    body,
    icon: "/icons/Icon-192.png",
  });
});
