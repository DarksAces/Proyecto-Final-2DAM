// =============================
//  CONFIG
// =============================
mapboxgl.accessToken = "pk.eyJ1IjoiZGFuaWVsZ2FyYnJ1IiwiYSI6ImNtaWRmNHAwdTA0anYyanNjbHZibnBkcmUifQ.GWjrEAwP4-v8St3jYbSkzQ";

const AVATAR_URL = "https://models.readyplayer.me/6924944848062250a4f9c961.glb";

// =============================
//  MAPA
// =============================
const map = new mapboxgl.Map({
    container: "map",
    style: "mapbox://styles/mapbox/streets-v12",
    zoom: 18,
    pitch: 60,
    bearing: 0
});

// =============================
//  SEGUIMIENTO GPS
// =============================
navigator.geolocation.watchPosition(
    (pos) => {
        const lat = pos.coords.latitude;
        const lng = pos.coords.longitude;

        // Centrar mapa en usuario
        map.setCenter([lng, lat]);

        // Si ya está cargado el avatar -> actualizar posición
        if (window.person) {
            const merc = mapboxgl.MercatorCoordinate.fromLngLat({ lng, lat }, 0);
            person.position.set(merc.x, merc.y, merc.z + 1.7); // +1.7 para altura humana
        }
    },
    (err) => {
        console.error("Error GPS:", err);
        alert("Activa la ubicación del dispositivo.");
    },
    { enableHighAccuracy: true }
);

// =============================
//  CAPA 3D
// =============================
map.on("style.load", () => {
    const THREE = window.THREE;

    const customLayer = {
        id: "avatar-layer",
        type: "custom",
        renderingMode: "3d",

        onAdd: function (map, gl) {
            this.scene = new THREE.Scene();
            this.camera = new THREE.Camera();

            // ILUMINACIÓN
            const light = new THREE.DirectionalLight(0xffffff, 1);
            light.position.set(0, 10, 10);
            this.scene.add(light);

            const loader = new THREE.GLTFLoader();

            loader.load(
                AVATAR_URL,
                (gltf) => {
                    window.person = gltf.scene;

                    // Escala ajustada para humanos ReadyPlayerMe
                    person.scale.set(1.2, 1.2, 1.2);

                    this.scene.add(person);
                },
                undefined,
                (error) => console.error("Error al cargar el avatar:", error)
            );

            this.renderer = new THREE.WebGLRenderer({
                canvas: map.getCanvas(),
                context: gl,
                antialias: true
            });
            this.renderer.autoClear = false;
        },

        render: function (gl, matrix) {
            const m = new THREE.Matrix4().fromArray(matrix);
            this.camera.projectionMatrix = m;

            this.renderer.state.reset();
            this.renderer.render(this.scene, this.camera);

            map.triggerRepaint();
        }
    };

    map.addLayer(customLayer);
});
