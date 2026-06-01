// Firebase SDK — Marketing Site
// Firebase JS SDK v11 (modular API)
import { initializeApp } from 'https://www.gstatic.com/firebasejs/11.2.0/firebase-app.js';
import { getAnalytics, logEvent } from 'https://www.gstatic.com/firebasejs/11.2.0/firebase-analytics.js';

const firebaseConfig = {
  apiKey: 'AIzaSyB0Ly1MO8mB_c52Mzhis_vEQ8XY9xtw17g',
  authDomain: 'ilandlands.firebaseapp.com',
  projectId: 'ilandlands',
  storageBucket: 'ilandlands.firebasestorage.app',
  messagingSenderId: '685494651118',
  appId: '1:685494651118:web:4f7fe1d91ba34cfb344bff',
  measurementId: 'G-D2508P154N',
};

const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);

// Log initial page view
logEvent(analytics, 'page_view', {
  page_title: document.title,
  page_location: window.location.href,
  page_path: window.location.pathname,
});

export { analytics, logEvent };
