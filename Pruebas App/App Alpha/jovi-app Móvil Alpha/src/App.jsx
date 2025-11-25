import React, { useState, useEffect, useRef } from 'react';
import { 
  MapPin, 
  Camera, 
  User, 
  Settings, 
  LogOut, 
  Plus, 
  X, 
  Image as ImageIcon, 
  Navigation,
  Layers,
  Maximize2,
  Check
} from 'lucide-react';

// --- CONFIGURACIÓN DE DISEÑO (TEMA) ---
const THEME = {
  colors: {
    primary: '#F8C41E', // Amarillo creativo
    secondary: '#2A4D9B', // Azul confiado
    accent: '#E34132', // Rojo artístico
    white: '#FFFFFF',
    bg: '#F2F2F5', // Gris claro
    text: '#1A1A1A',
    textLight: '#A1A1A8',
    border: '#DADADA'
  },
  fonts: {
    main: 'font-sans', // Simulando Poppins/Baloo con sans redondeado
  },
  radius: 'rounded-2xl', // 16px
  btnRadius: 'rounded-xl', // 12px
};

// --- DATOS SIMULADOS (MOCK DATA) ---
const INITIAL_MARKERS = [
  { id: 1, lat: 40, lng: 40, title: "Mural del Sol", author: "Ana G.", type: "Mural", description: "Pintura hecha con ceras Jovi sobre pared rugosa.", color: "#E34132" },
  { id: 2, lat: 60, lng: 70, title: "Escultura de Plastilina", author: "Marc R.", type: "Escultura", description: "Modelado 3D escaneado en el parque.", color: "#2A4D9B" },
  { id: 3, lat: 20, lng: 80, title: "Grafiti Abstracto", author: "Sonia L.", type: "Urbano", description: "Colores vibrantes en la esquina del colegio.", color: "#F8C41E" },
];

// --- COMPONENTES UI REUTILIZABLES ---

const Button = ({ children, variant = 'primary', onClick, className = '', icon: Icon, fullWidth = false }) => {
  const baseStyle = `flex items-center justify-center gap-2 px-6 py-3 font-semibold transition-transform active:scale-95 shadow-sm ${THEME.btnRadius} ${fullWidth ? 'w-full' : ''}`;
  
  const variants = {
    primary: `bg-[${THEME.colors.primary}] text-[${THEME.colors.secondary}] hover:brightness-105`,
    secondary: `bg-[${THEME.colors.secondary}] text-white hover:bg-opacity-90`,
    danger: `bg-[${THEME.colors.accent}] text-white hover:bg-opacity-90`,
    outline: `bg-transparent border-2 border-[${THEME.colors.secondary}] text-[${THEME.colors.secondary}]`,
    ghost: `bg-transparent text-[${THEME.colors.textLight}] hover:text-[${THEME.colors.secondary}]`
  };

  return (
    <button 
      onClick={onClick} 
      className={`${baseStyle} ${variants[variant]} ${className}`}
      style={variant === 'primary' ? { backgroundColor: THEME.colors.primary, color: THEME.colors.secondary } : {}}
    >
      {Icon && <Icon size={20} />}
      {children}
    </button>
  );
};

const Input = ({ label, type = "text", placeholder, value, onChange }) => (
  <div className="flex flex-col gap-1 mb-4">
    <label className="text-sm font-medium ml-1 text-gray-600">{label}</label>
    <input
      type={type}
      value={value}
      onChange={onChange}
      placeholder={placeholder}
      className={`w-full p-4 bg-white border border-[${THEME.colors.border}] ${THEME.btnRadius} focus:outline-none focus:ring-2 focus:ring-[${THEME.colors.primary}] text-[${THEME.colors.text}]`}
    />
  </div>
);

const Card = ({ children, className = '' }) => (
  <div className={`bg-white p-5 shadow-lg shadow-gray-200/50 ${THEME.radius} ${className}`}>
    {children}
  </div>
);

// --- PANTALLAS PRINCIPALES ---

const WelcomeScreen = ({ onNavigate }) => (
  <div className="flex flex-col items-center justify-center h-full p-8 text-center bg-white">
    <div className={`w-24 h-24 rounded-full bg-[${THEME.colors.primary}] mb-8 flex items-center justify-center shadow-lg animate-bounce`}>
      <Layers size={48} color={THEME.colors.secondary} />
    </div>
    <h1 className="text-3xl font-bold mb-2 text-[#2A4D9B]">Jovi Art World</h1>
    <p className="text-gray-500 mb-10 text-lg">Descubre, crea y escanea arte en tu ciudad.</p>
    
    <div className="w-full space-y-4">
      <Button fullWidth onClick={() => onNavigate('login')}>Iniciar Sesión</Button>
      <Button fullWidth variant="outline" onClick={() => onNavigate('register')}>Crear Cuenta</Button>
    </div>
  </div>
);

const AuthScreen = ({ type, onLogin, onNavigate }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = (e) => {
    e.preventDefault();
    setIsLoading(true);
    // Simulación de red
    setTimeout(() => {
      setIsLoading(false);
      onLogin({ name: "Artista Curioso", email });
    }, 1000);
  };

  return (
    <div className={`flex flex-col h-full p-6 bg-[${THEME.colors.bg}]`}>
      <div className="flex-1 flex flex-col justify-center">
        <button onClick={() => onNavigate('welcome')} className="mb-6 text-gray-400 hover:text-gray-600 w-fit">
          ← Volver
        </button>
        <h2 className="text-3xl font-bold mb-6 text-[#2A4D9B]">
          {type === 'login' ? '¡Hola de nuevo!' : 'Únete al club'}
        </h2>
        
        <form onSubmit={handleSubmit}>
          <Input 
            label="Email" 
            placeholder="artista@jovi.com" 
            value={email} 
            onChange={(e) => setEmail(e.target.value)} 
          />
          <Input 
            label="Contraseña" 
            type="password" 
            placeholder="••••••••" 
            value={password} 
            onChange={(e) => setPassword(e.target.value)} 
          />
          
          <Button fullWidth className="mt-4" icon={isLoading ? null : Check}>
            {isLoading ? 'Procesando...' : (type === 'login' ? 'Entrar' : 'Registrarse')}
          </Button>
        </form>
      </div>
    </div>
  );
};

// --- SISTEMA DE MAPA (SIMULADO) ---
const MapSystem = ({ markers, onMarkerClick }) => {
  return (
    <div className="relative w-full h-full bg-[#e5e7eb] overflow-hidden group">
      {/* Simulación visual del mapa */}
      <div className="absolute inset-0 opacity-30" style={{
        backgroundImage: 'radial-gradient(#A1A1A8 1px, transparent 1px)',
        backgroundSize: '20px 20px'
      }}></div>
      
      {/* Calles simuladas */}
      <div className="absolute top-1/2 left-0 w-full h-8 bg-white transform -rotate-6 shadow-sm"></div>
      <div className="absolute top-0 left-1/3 w-12 h-full bg-white transform rotate-12 shadow-sm"></div>
      
      {/* Marcadores */}
      {markers.map((m) => (
        <button
          key={m.id}
          onClick={() => onMarkerClick(m)}
          className="absolute transform -translate-x-1/2 -translate-y-1/2 transition-all hover:scale-125 active:scale-95 animate-in fade-in zoom-in duration-300"
          style={{ 
            left: `${m.lng}%`, 
            top: `${m.lat}%` 
          }}
        >
          <div className="relative">
            <MapPin 
              size={48} 
              fill={m.color} 
              color="white" 
              strokeWidth={1.5}
              className="drop-shadow-lg"
            />
            <div className="absolute top-3 left-1/2 transform -translate-x-1/2 bg-white rounded-full p-1">
               {/* Icono pequeño dentro del pin */}
               <div className="w-2 h-2 rounded-full bg-current opacity-50"></div>
            </div>
          </div>
        </button>
      ))}

      {/* Botón flotante de ubicación actual */}
      <button className="absolute bottom-24 right-4 bg-white p-3 rounded-full shadow-lg text-blue-600">
        <Navigation size={24} className="transform rotate-45" />
      </button>
    </div>
  );
};

// --- ESCANER AR (SIMULADO) ---
const ARScanner = ({ onCapture, onCancel }) => {
  const [step, setStep] = useState('scanning'); // scanning, captured, details
  const [capturedImage, setCapturedImage] = useState(null);
  const [title, setTitle] = useState('');
  const [desc, setDesc] = useState('');

  const handleCapture = () => {
    setStep('captured');
    setCapturedImage('https://via.placeholder.com/400x400/F8C41E/2A4D9B?text=Arte+Capturado'); // Mock image
  };

  const handleSave = () => {
    onCapture({ title, desc, image: capturedImage });
  };

  if (step === 'scanning') {
    return (
      <div className="absolute inset-0 bg-black z-50 flex flex-col items-center justify-between p-6">
        {/* Simulación de cámara */}
        <div className="absolute inset-0 bg-gray-800">
          <div className="w-full h-full opacity-30 bg-[url('https://images.unsplash.com/photo-1513364776144-60967b0f800f?q=80&w=1000&auto=format&fit=crop')] bg-cover bg-center" />
        </div>

        {/* UI Superpuesta */}
        <div className="relative w-full flex justify-between text-white pt-4">
          <button onClick={onCancel}><X size={32} /></button>
          <span className="bg-black/50 px-3 py-1 rounded-full text-sm backdrop-blur-sm">Modo AR</span>
          <button><Settings size={24} /></button>
        </div>

        {/* Marco de enfoque */}
        <div className="relative w-64 h-64 border-4 border-white/30 rounded-3xl flex items-center justify-center">
          <div className="w-60 h-60 border-2 border-dashed border-yellow-400 rounded-2xl animate-pulse"></div>
          <p className="absolute -bottom-10 text-white font-medium shadow-black drop-shadow-md">Apunta a la obra</p>
        </div>

        {/* Controles */}
        <div className="relative mb-8">
          <button 
            onClick={handleCapture}
            className="w-20 h-20 bg-[#E34132] rounded-full border-4 border-white shadow-xl flex items-center justify-center hover:scale-105 transition-transform"
          >
            <Camera size={32} color="white" />
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="absolute inset-0 bg-[#F2F2F5] z-50 p-6 flex flex-col h-full overflow-y-auto">
      <div className="flex items-center mb-4">
         <button onClick={() => setStep('scanning')} className="p-2 -ml-2"><X size={24} /></button>
         <h2 className="text-xl font-bold text-[#2A4D9B] ml-2">Nueva Pokeparada</h2>
      </div>
      
      <div className="w-full h-64 bg-gray-300 rounded-2xl mb-6 overflow-hidden relative shadow-inner">
        <img src={capturedImage} alt="Captura" className="w-full h-full object-cover" />
        <div className="absolute bottom-4 right-4 bg-white p-2 rounded-full shadow-md">
           <Maximize2 size={20} className="text-gray-600"/>
        </div>
      </div>

      <div className="flex-1">
        <Input label="Nombre de la obra" placeholder="Ej: Mural del Patio" value={title} onChange={e => setTitle(e.target.value)} />
        <Input label="Descripción" placeholder="¿Qué la hace especial?" value={desc} onChange={e => setDesc(e.target.value)} />
      </div>

      <div className="mt-4 space-y-3">
        <Button fullWidth onClick={handleSave} icon={MapPin}>Colocar en Mapa</Button>
        <Button fullWidth variant="ghost" onClick={() => setStep('scanning')}>Reintentar foto</Button>
      </div>
    </div>
  );
};

// --- VISTA DE DETALLE (MODAL) ---
const ArtDetail = ({ marker, onClose, onOpenAR }) => {
  if (!marker) return null;
  return (
    <div className="fixed inset-0 z-40 flex items-end justify-center sm:items-center bg-black/40 backdrop-blur-sm p-4 animate-in fade-in duration-200">
      <div className="bg-white w-full max-w-md rounded-3xl p-6 shadow-2xl relative animate-in slide-in-from-bottom-10 duration-300">
        <button onClick={onClose} className="absolute top-4 right-4 p-2 bg-gray-100 rounded-full hover:bg-gray-200">
          <X size={20} className="text-gray-600" />
        </button>

        <div className="flex flex-col items-center text-center -mt-12 mb-4">
          <div className="w-24 h-24 rounded-2xl bg-yellow-100 border-4 border-white shadow-md flex items-center justify-center mb-3 overflow-hidden">
             <ImageIcon size={40} className="text-yellow-500 opacity-50" />
             {/* En producción aquí iría la foto real */}
          </div>
          <span className="text-xs font-bold tracking-wider text-[#E34132] uppercase mb-1">{marker.type}</span>
          <h2 className="text-2xl font-bold text-[#2A4D9B]">{marker.title}</h2>
          <p className="text-sm text-gray-500">por {marker.author}</p>
        </div>

        <p className="text-gray-600 text-center mb-6 bg-gray-50 p-3 rounded-xl text-sm">
          "{marker.description}"
        </p>

        <div className="grid grid-cols-2 gap-3">
           <Button variant="outline" className="text-sm" icon={Navigation}>Ir</Button>
           <Button variant="primary" className="text-sm" icon={Maximize2} onClick={onOpenAR}>Ver en AR</Button>
        </div>
      </div>
    </div>
  );
};

// --- COMPONENTE PRINCIPAL ---

export default function App() {
  const [view, setView] = useState('welcome'); // welcome, login, register, map, profile, camera
  const [user, setUser] = useState(null);
  const [markers, setMarkers] = useState(INITIAL_MARKERS);
  const [selectedMarker, setSelectedMarker] = useState(null);
  const [arMode, setArMode] = useState(false); // 'view' or 'scan'

  // Handlers
  const handleLogin = (userData) => {
    setUser(userData);
    setView('map');
  };

  const handleScanComplete = (newArt) => {
    const newMarker = {
      id: Date.now(),
      lat: 50 + (Math.random() * 20 - 10), // Random pos center
      lng: 50 + (Math.random() * 20 - 10),
      title: newArt.title || "Obra Sin Título",
      author: user.name,
      type: "Nuevo Arte",
      description: newArt.desc || "Sin descripción",
      color: THEME.colors.primary
    };
    setMarkers([...markers, newMarker]);
    setView('map');
  };

  // Render Navigation Bar
  const NavBar = () => {
    const navItems = [
      { id: 'map', icon: MapPin, label: 'Mapa' },
      { id: 'camera', icon: Camera, label: 'Escanear', main: true },
      { id: 'profile', icon: User, label: 'Perfil' },
    ];

    return (
      <div className="fixed bottom-6 left-4 right-4 h-20 bg-white rounded-2xl shadow-xl flex items-center justify-between px-6 z-30 max-w-md mx-auto">
        {navItems.map((item) => {
           const isActive = view === item.id;
           if (item.main) {
             return (
               <div key={item.id} className="relative -top-8">
                 <button 
                    onClick={() => setView('camera')}
                    className={`w-16 h-16 rounded-full flex items-center justify-center shadow-lg transition-transform active:scale-90 ${isActive ? 'bg-[#E34132]' : 'bg-[#F8C41E]'}`}
                 >
                   <Camera size={28} className="text-white" />
                 </button>
               </div>
             );
           }
           return (
             <button 
                key={item.id}
                onClick={() => setView(item.id)}
                className={`flex flex-col items-center gap-1 transition-colors ${isActive ? 'text-[#2A4D9B]' : 'text-gray-400'}`}
             >
               <item.icon size={24} strokeWidth={isActive ? 2.5 : 2} />
               <span className="text-xs font-medium">{item.label}</span>
             </button>
           );
        })}
      </div>
    );
  };

  // Main Render Logic
  if (view === 'welcome') return <WelcomeScreen onNavigate={setView} />;
  if (view === 'login' || view === 'register') return <AuthScreen type={view} onLogin={handleLogin} onNavigate={setView} />;

  return (
    <div className="w-full h-screen bg-[#F2F2F5] overflow-hidden flex flex-col relative font-sans text-[#1A1A1A]">
      
      {/* HEADER (Solo visible en mapa/perfil) */}
      {view !== 'camera' && (
        <div className="absolute top-0 left-0 right-0 z-20 pt-12 px-6 pb-4 bg-gradient-to-b from-white/90 to-transparent pointer-events-none">
          <div className="flex justify-between items-center pointer-events-auto">
            <div className="flex items-center gap-2 bg-white/80 backdrop-blur-md p-2 pr-4 rounded-full shadow-sm">
              <div className="w-8 h-8 bg-[#2A4D9B] rounded-full flex items-center justify-center text-white font-bold text-xs">
                {user?.name[0]}
              </div>
              <span className="text-sm font-bold text-[#2A4D9B]">Nivel 3</span>
            </div>
            <button className="bg-white/80 p-2 rounded-full shadow-sm text-gray-600">
              <Settings size={20} />
            </button>
          </div>
        </div>
      )}

      {/* CONTENIDO PRINCIPAL */}
      <div className="flex-1 relative">
        
        {/* VISTA DE MAPA */}
        <div className={`absolute inset-0 transition-opacity duration-300 ${view === 'map' ? 'opacity-100 z-10' : 'opacity-0 z-0'}`}>
          <MapSystem markers={markers} onMarkerClick={setSelectedMarker} />
        </div>

        {/* VISTA DE PERFIL */}
        {view === 'profile' && (
          <div className="absolute inset-0 z-10 pt-24 px-6 overflow-y-auto pb-32 animate-in slide-in-from-right duration-300 bg-[#F2F2F5]">
             <h1 className="text-3xl font-bold text-[#2A4D9B] mb-6">Mi Perfil</h1>
             <Card className="mb-6 flex items-center gap-4">
                <div className="w-16 h-16 rounded-full bg-[#F8C41E] flex items-center justify-center text-2xl font-bold text-white">
                  {user?.name[0]}
                </div>
                <div>
                  <h3 className="font-bold text-lg">{user?.name}</h3>
                  <p className="text-gray-500 text-sm">Explorador Creativo</p>
                </div>
             </Card>
             
             <h3 className="font-bold text-gray-700 mb-3">Mis Estadísticas</h3>
             <div className="grid grid-cols-2 gap-4 mb-6">
                <Card className="text-center py-6">
                   <div className="text-3xl font-bold text-[#2A4D9B]">{markers.filter(m => m.author === user?.name).length}</div>
                   <div className="text-xs text-gray-500 uppercase font-bold mt-1">Obras Creadas</div>
                </Card>
                <Card className="text-center py-6">
                   <div className="text-3xl font-bold text-[#E34132]">12</div>
                   <div className="text-xs text-gray-500 uppercase font-bold mt-1">Escaneos</div>
                </Card>
             </div>

             <Button variant="outline" fullWidth icon={LogOut} onClick={() => setView('welcome')}>Cerrar Sesión</Button>
          </div>
        )}

        {/* VISTA DE CÁMARA (SCANNER) */}
        {view === 'camera' && (
          <ARScanner 
            onCapture={handleScanComplete} 
            onCancel={() => setView('map')} 
          />
        )}
      </div>

      {/* MODALES Y UI FLOTANTE */}
      {selectedMarker && (
        <ArtDetail 
          marker={selectedMarker} 
          onClose={() => setSelectedMarker(null)} 
          onOpenAR={() => {
            setSelectedMarker(null);
            alert("Abriendo visualizador AR para: " + selectedMarker.title);
          }}
        />
      )}

      {/* BARRA DE NAVEGACIÓN INFERIOR */}
      {user && view !== 'camera' && <NavBar />}

    </div>
  );
}