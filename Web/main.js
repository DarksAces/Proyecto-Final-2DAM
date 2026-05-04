import { initializeApp } from "firebase/app";
import { getFirestore, collection, getDocs } from "firebase/firestore";

// CONFIGURACIÓN DE FIREBASE
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

async function loadModels() {
    const container = document.getElementById('thumbnails-container');
    
    try {
        const querySnapshot = await getDocs(collection(db, "ar_objects"));

        if (querySnapshot.empty) {
            container.innerHTML = '<div class="loading-state">No hay modelos disponibles.</div>';
            return;
        }

        container.innerHTML = ''; 
        allModels = [];

        querySnapshot.forEach((doc) => {
            const data = doc.data();
            if (data.url && data.type === 'glb') {
                allModels.push({
                    id: doc.id,
                    name: data.name || "Objeto 3D",
                    url: data.url
                });
            }
        });

        // Crear miniaturas
        allModels.forEach((model, index) => {
            const thumb = createThumbnail(model, index);
            container.appendChild(thumb);
        });

        // Cargar el primer modelo por defecto
        if (allModels.length > 0) {
            selectModel(0);
        }

    } catch (error) {
        console.error("Error:", error);
        container.innerHTML = '<div class="loading-state">Error al conectar con la colección.</div>';
    }
}

function createThumbnail(model, index) {
    const div = document.createElement('div');
    div.className = 'thumb-card';
    div.id = `thumb-${index}`;
    div.innerHTML = `
        <div class="thumb-icon">📦</div>
        <span>${model.name.replace('.glb', '')}</span>
    `;
    div.onclick = () => selectModel(index);
    return div;
}

function selectModel(index) {
    const model = allModels[index];
    const viewer = document.getElementById('main-viewer');
    const nameOverlay = document.getElementById('model-name-overlay');

    // Actualizar Visor
    viewer.src = model.url;
    nameOverlay.innerText = model.name.replace('.glb', '');

    // Actualizar clase activa en miniaturas
    document.querySelectorAll('.thumb-card').forEach(card => card.classList.remove('active'));
    document.getElementById(`thumb-${index}`).classList.add('active');

    // Efecto de entrada suave
    viewer.style.opacity = '0';
    setTimeout(() => {
        viewer.style.opacity = '1';
    }, 50);
}

document.addEventListener('DOMContentLoaded', loadModels);
