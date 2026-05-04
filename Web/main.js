import { initializeApp } from "firebase/app";
import { getFirestore, collection, getDocs } from "firebase/firestore";

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
const db = getFirestore(app);

async function loadModels() {
    const container = document.getElementById('models-container');
    
    try {
        // Obtenemos los documentos de la colección "ar_objects"
        const querySnapshot = await getDocs(collection(db, "ar_objects"));

        if (querySnapshot.empty) {
            container.innerHTML = '<div class="loading-state">No se encontraron objetos en la colección "ar_objects".</div>';
            return;
        }

        container.innerHTML = ''; // Limpiar cargando

        querySnapshot.forEach((doc) => {
            const data = doc.data();
            // Usamos el campo 'url' y 'name' que vemos en tu captura de Firebase
            if (data.url && data.type === 'glb') {
                createModelCard(data.name || "Objeto sin nombre", data.url);
            }
        });
    } catch (error) {
        console.error("Error cargando modelos de Firestore:", error);
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
