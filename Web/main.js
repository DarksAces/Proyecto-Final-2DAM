import { initializeApp } from "firebase/app";
import { getStorage, ref, listAll, getDownloadURL } from "firebase/storage";

// CONFIGURACIÓN DE FIREBASE (Vía Variables de Entorno)
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID
};

// Inicializar Firebase
const app = initializeApp(firebaseConfig);
const storage = getStorage(app);

async function loadModels() {
    const container = document.getElementById('models-container');
    
    try {
        // Carpeta donde están los .glb en Firebase Storage
        const listRef = ref(storage, 'models/');
        const res = await listAll(listRef);

        if (res.items.length === 0) {
            container.innerHTML = '<div class="loading-state">No hay modelos en la carpeta "models/" de Firebase.</div>';
            return;
        }

        container.innerHTML = ''; // Limpiar cargando

        for (const itemRef of res.items) {
            const url = await getDownloadURL(itemRef);
            createModelCard(itemRef.name, url);
        }
    } catch (error) {
        console.error("Error cargando modelos de Firebase:", error);
        // MODO DEMO si falla Firebase (para que veas cómo queda)
        showDemoModels();
    }
}

function createModelCard(name, url) {
    const container = document.getElementById('models-container');
    const card = document.createElement('div');
    card.className = 'model-card';
    
    card.innerHTML = `
        <model-viewer 
            src="${url}" 
            ar 
            ar-modes="webxr scene-viewer quick-look" 
            camera-controls 
            touch-action="pan-y" 
            shadow-intensity="1" 
            auto-rotate>
        </model-viewer>
        <div class="model-info">
            <h3>${name.replace('.glb', '')}</h3>
            <p>Formato: GLB | Listo para AR</p>
        </div>
    `;
    container.appendChild(card);
}

function showDemoModels() {
    const container = document.getElementById('models-container');
    container.innerHTML = `
        <div class="loading-state" style="animation: none; margin-bottom: 2rem; grid-column: 1/-1;">
            Mostrando ejemplos (Configura Firebase en main.js para ver tus propios archivos)
        </div>
    `;
    
    // Modelos de ejemplo de Google para probar el visor
    const demos = [
        { name: "Astronauta", url: "https://modelviewer.dev/shared-assets/models/Astronaut.glb" },
        { name: "Caja de Prueba", url: "https://modelviewer.dev/shared-assets/models/NeilArmstrong.glb" }
    ];

    demos.forEach(d => createModelCard(d.name, d.url));
}

document.addEventListener('DOMContentLoaded', loadModels);
