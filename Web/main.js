import { initializeApp } from "firebase/app";
import { getFirestore, collection, getDocs } from "firebase/firestore";

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

let allModels = [];
let currentIndex = 0;

async function loadModels() {
    const container = document.getElementById('thumbnails-container');
    
    try {
        const querySnapshot = await getDocs(collection(db, "ar_objects"));
        if (querySnapshot.empty) {
            container.innerHTML = '<div class="loading-state">No hay modelos.</div>';
            return;
        }

        allModels = [];
        querySnapshot.forEach((doc) => {
            const data = doc.data();
            if (data.url && data.type === 'glb') {
                allModels.push({ id: doc.id, name: data.name || "Objeto 3D", url: data.url });
            }
        });

        container.innerHTML = ''; 
        allModels.forEach((model, index) => {
            const thumb = createThumbnail(model, index);
            container.appendChild(thumb);
        });

        if (allModels.length > 0) selectModel(0);

    } catch (error) {
        console.error(error);
    }
}

function createThumbnail(model, index) {
    const div = document.createElement('div');
    div.className = 'thumb-card';
    div.id = `thumb-${index}`;
    div.innerHTML = `<span>${index + 1}</span>`;
    div.onclick = () => selectModel(index);
    return div;
}

function selectModel(index) {
    if (index < 0) index = allModels.length - 1;
    if (index >= allModels.length) index = 0;
    
    currentIndex = index;
    const model = allModels[index];
    const viewer = document.getElementById('main-viewer');
    const nameOverlay = document.getElementById('model-name-overlay');

    viewer.src = model.url;
    nameOverlay.innerText = `${index + 1}. ${model.name.replace('.glb', '')}`;

    document.querySelectorAll('.thumb-card').forEach(card => card.classList.remove('active'));
    const activeThumb = document.getElementById(`thumb-${index}`);
    if (activeThumb) {
        activeThumb.classList.add('active');
        activeThumb.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
    }
}

// Navegación
document.getElementById('next-btn').onclick = () => selectModel(currentIndex + 1);
document.getElementById('prev-btn').onclick = () => selectModel(currentIndex - 1);

document.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowRight') selectModel(currentIndex + 1);
    if (e.key === 'ArrowLeft') selectModel(currentIndex - 1);
});

// Pantalla Completa
document.getElementById('fullscreen-btn').onclick = () => {
    const stage = document.querySelector('.immersive-layout');
    if (!document.fullscreenElement) {
        stage.requestFullscreen();
    } else {
        document.exitFullscreen();
    }
};

document.addEventListener('DOMContentLoaded', loadModels);
