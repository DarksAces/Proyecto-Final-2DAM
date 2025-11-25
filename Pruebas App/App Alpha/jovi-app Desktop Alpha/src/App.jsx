import React, { useState } from 'react';
import { 
  LayoutDashboard, 
  CheckCircle, 
  XCircle, 
  Map as MapIcon, 
  Users, 
  Settings, 
  LogOut, 
  Search, 
  Filter, 
  MoreVertical, 
  ChevronRight, 
  Eye, 
  Edit, 
  ArrowUpRight, 
  Box, 
  Bell,
  Menu
} from 'lucide-react';

// --- CONFIGURACIÓN DE DISEÑO (TEMA ESCRITORIO) ---
const THEME = {
  colors: {
    sidebar: '#223B80',     // Azul Jovi (Profundo)
    primary: '#F8C41E',     // Amarillo Jovi
    action: '#E34132',      // Rojo Acción
    success: '#2EAE56',     // Verde Aprobación
    bg: '#F4F4F6',          // Gris Claro Fondo
    white: '#FFFFFF',
    textMain: '#2B2B2E',    // Gris Oscuro
    textSec: '#CDCED3',     // Gris Medio
    border: '#E5E7EB'
  }
};

// --- DATOS SIMULADOS (MOCK DATA) ---
const MOCK_STATS = [
  { label: "Obras Pendientes", value: 24, icon: Box, color: "text-yellow-600", bg: "bg-yellow-100" },
  { label: "Aprobadas este mes", value: 156, icon: CheckCircle, color: "text-green-600", bg: "bg-green-100" },
  { label: "Usuarios Nuevos", value: 45, icon: Users, color: "text-blue-600", bg: "bg-blue-100" },
  { label: "Rechazadas", value: 8, icon: XCircle, color: "text-red-600", bg: "bg-red-100" },
];

const MOCK_ARTWORKS = [
  { id: 1, title: "Mural del Sol", author: "Ana García", date: "2023-10-24", status: "pending", location: "Parque Central", img: "https://via.placeholder.com/150/F8C41E/223B80?text=Mural" },
  { id: 2, title: "Escultura Plastilina", author: "Marc Rojo", date: "2023-10-23", status: "approved", location: "Plaza Mayor", img: "https://via.placeholder.com/150/223B80/FFFFFF?text=Escultura" },
  { id: 3, title: "Grafiti Abstracto", author: "Sonia López", date: "2023-10-22", status: "rejected", location: "Colegio San Juan", img: "https://via.placeholder.com/150/E34132/FFFFFF?text=Grafiti" },
  { id: 4, title: "Estatua de Cera", author: "Pedro M.", date: "2023-10-25", status: "pending", location: "Museo Abierto", img: "https://via.placeholder.com/150/2EAE56/FFFFFF?text=Cera" },
  { id: 5, title: "Castillo de Arena", author: "Lucía F.", date: "2023-10-26", status: "pending", location: "Playa", img: "https://via.placeholder.com/150/F8C41E/223B80?text=Arena" },
];

const MOCK_USERS = [
  { id: 1, name: "Ana García", email: "ana@example.com", registered: "2023-01-15", artworks: 12, status: "active" },
  { id: 2, name: "Marc Rojo", email: "marc@example.com", registered: "2023-02-20", artworks: 5, status: "active" },
  { id: 3, name: "Sonia López", email: "sonia@example.com", registered: "2023-03-10", artworks: 0, status: "inactive" },
];

// --- COMPONENTES UI ---

const Badge = ({ status }) => {
  const styles = {
    pending: "bg-yellow-100 text-yellow-800 border-yellow-200",
    approved: "bg-green-100 text-green-800 border-green-200",
    rejected: "bg-red-100 text-red-800 border-red-200",
    active: "bg-blue-100 text-blue-800 border-blue-200",
    inactive: "bg-gray-100 text-gray-600 border-gray-200",
  };
  
  const labels = {
    pending: "Pendiente",
    approved: "Aprobada",
    rejected: "Rechazada",
    active: "Activo",
    inactive: "Inactivo"
  };

  return (
    <span className={`px-3 py-1 rounded-full text-xs font-semibold border ${styles[status] || styles.pending}`}>
      {labels[status] || status}
    </span>
  );
};

const Card = ({ children, className = "" }) => (
  <div className={`bg-white rounded-xl shadow-sm border border-gray-200 p-6 ${className}`}>
    {children}
  </div>
);

const Button = ({ children, variant = "primary", onClick, className = "", size = "md" }) => {
  const variants = {
    primary: `bg-[#223B80] text-white hover:bg-[#1A2E66] shadow-sm`,
    success: `bg-[#2EAE56] text-white hover:bg-[#258E46] shadow-sm`,
    danger: `bg-[#E34132] text-white hover:bg-[#C6392B] shadow-sm`,
    outline: `border border-gray-300 text-gray-600 hover:bg-gray-50 bg-white`,
    ghost: `bg-transparent text-gray-500 hover:bg-gray-100`
  };

  const sizes = {
    sm: "px-3 py-1.5 text-xs",
    md: "px-4 py-2 text-sm",
    lg: "px-6 py-3 text-base"
  };

  return (
    <button 
      onClick={onClick}
      className={`rounded-lg font-semibold transition-all flex items-center justify-center gap-2 ${variants[variant]} ${sizes[size]} ${className}`}
    >
      {children}
    </button>
  );
};

// --- MODAL DE DETALLE ---
const DetailModal = ({ artwork, isOpen, onClose }) => {
  if (!isOpen || !artwork) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-5xl max-h-[90vh] overflow-hidden flex flex-col md:flex-row animate-in zoom-in-95 duration-200">
        
        {/* Imagen / 3D */}
        <div className="w-full md:w-1/2 bg-gray-100 relative flex items-center justify-center p-12 border-r border-gray-200">
          <img src={artwork.img} alt={artwork.title} className="max-w-full max-h-full rounded-lg shadow-xl object-contain" />
          <div className="absolute top-4 left-4 bg-white/90 backdrop-blur px-3 py-1 rounded-full text-xs font-bold text-gray-500 shadow-sm border border-gray-200">
            VISOR 3D NO DISPONIBLE
          </div>
        </div>

        {/* Información y Acciones */}
        <div className="w-full md:w-1/2 p-8 flex flex-col bg-white">
          <div className="flex justify-between items-start mb-6">
            <div>
              <Badge status={artwork.status} />
              <h2 className="text-3xl font-bold text-[#2B2B2E] mt-3">{artwork.title}</h2>
              <p className="text-gray-500 font-medium text-lg">por {artwork.author}</p>
            </div>
            <button onClick={onClose} className="p-2 hover:bg-gray-100 rounded-full text-gray-400 hover:text-gray-600 transition-colors">
              <XCircle size={32} />
            </button>
          </div>

          <div className="space-y-6 flex-1 overflow-y-auto pr-2">
            <div className="bg-gray-50 p-4 rounded-xl border border-gray-200">
              <h4 className="text-xs font-bold uppercase text-gray-400 tracking-wider mb-2">Descripción</h4>
              <p className="text-gray-700 text-sm leading-relaxed">
                Esta obra representa la creatividad urbana utilizando texturas que imitan la plastilina Jovi. 
                Escaneada el {artwork.date} en {artwork.location}.
              </p>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="border border-gray-200 p-4 rounded-xl">
                <span className="text-xs text-gray-400 block mb-1">Ubicación GPS</span>
                <span className="font-semibold text-gray-700 flex items-center gap-2">
                  <MapIcon size={16} className="text-blue-500"/> {artwork.location}
                </span>
              </div>
              <div className="border border-gray-200 p-4 rounded-xl">
                <span className="text-xs text-gray-400 block mb-1">ID Sistema</span>
                <span className="font-mono text-gray-700">#{artwork.id.toString().padStart(6, '0')}</span>
              </div>
            </div>

            {/* Área de rechazo (solo visual) */}
            <div className="pt-4">
              <label className="text-xs font-bold text-gray-500 mb-2 block uppercase">Notas Administrativas</label>
              <textarea 
                className="w-full border border-gray-300 rounded-lg p-3 text-sm focus:ring-2 focus:ring-[#223B80] focus:outline-none resize-none bg-white"
                placeholder="Añade notas internas o motivo de rechazo..."
                rows={3}
              ></textarea>
            </div>
          </div>

          <div className="mt-8 pt-6 border-t border-gray-100 grid grid-cols-2 gap-4">
            <Button variant="danger" className="w-full py-3" onClick={onClose}>Rechazar Obra</Button>
            <Button variant="success" className="w-full py-3" onClick={onClose}>Aprobar y Publicar</Button>
          </div>
        </div>
      </div>
    </div>
  );
};

// --- COMPONENTE PRINCIPAL ---

export default function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [selectedArtwork, setSelectedArtwork] = useState(null);

  // Vistas
  const DashboardContent = () => (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
      {/* KPIs */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {MOCK_STATS.map((stat, idx) => (
          <Card key={idx} className="flex items-center gap-4 transition-transform hover:-translate-y-1 duration-200">
            <div className={`p-4 rounded-xl ${stat.bg}`}>
              <stat.icon className={stat.color} size={28} />
            </div>
            <div>
              <p className="text-sm text-gray-500 font-medium mb-1">{stat.label}</p>
              <h3 className="text-3xl font-bold text-[#2B2B2E]">{stat.value}</h3>
            </div>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Gráfica Simulada */}
        <Card className="lg:col-span-2 flex flex-col h-[400px]">
          <div className="flex justify-between items-center mb-8">
            <div>
              <h3 className="text-lg font-bold text-[#2B2B2E]">Actividad de Envíos</h3>
              <p className="text-sm text-gray-400">Obras recibidas en los últimos 30 días</p>
            </div>
            <select className="bg-gray-50 border-none text-sm font-medium text-gray-600 rounded-lg px-4 py-2 cursor-pointer hover:bg-gray-100">
              <option>Últimos 30 días</option>
              <option>Este Año</option>
            </select>
          </div>
          
          <div className="flex-1 flex items-end justify-between gap-2 px-4 pb-2">
            {[35, 55, 40, 80, 60, 90, 75, 50, 65, 85, 45, 95, 70, 60, 100].map((h, i) => (
              <div key={i} className="w-full bg-gray-100 rounded-t-md relative group h-full flex items-end">
                <div 
                  className="w-full bg-[#223B80] rounded-t-md transition-all duration-500 group-hover:bg-[#F8C41E]"
                  style={{ height: `${h}%` }}
                ></div>
                {/* Tooltip */}
                <div className="absolute -top-10 left-1/2 -translate-x-1/2 bg-black text-white text-xs py-1 px-2 rounded opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-10">
                  {h}
                </div>
              </div>
            ))}
          </div>
          <div className="flex justify-between mt-4 pt-4 border-t border-gray-100 text-xs text-gray-400 font-medium uppercase tracking-wider">
            <span>Día 1</span>
            <span>Día 15</span>
            <span>Día 30</span>
          </div>
        </Card>

        {/* Lista Reciente */}
        <Card className="flex flex-col h-[400px]">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-lg font-bold text-[#2B2B2E]">Últimos Envíos</h3>
            <button className="text-[#223B80] hover:text-[#F8C41E] transition-colors"><ArrowUpRight size={20} /></button>
          </div>
          <div className="flex-1 overflow-y-auto space-y-4 pr-2">
            {MOCK_ARTWORKS.map((art) => (
              <div key={art.id} className="flex items-center gap-4 p-3 rounded-xl hover:bg-gray-50 transition-colors cursor-pointer group border border-transparent hover:border-gray-100" onClick={() => setSelectedArtwork(art)}>
                <img src={art.img} alt="" className="w-12 h-12 rounded-lg object-cover shadow-sm" />
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-bold text-gray-900 truncate group-hover:text-[#223B80]">{art.title}</p>
                  <p className="text-xs text-gray-500">{art.author}</p>
                </div>
                <Badge status={art.status} />
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );

  const TableContent = ({ data }) => (
    <Card className="p-0 overflow-hidden animate-in fade-in slide-in-from-bottom-4 duration-500">
      <table className="w-full text-left border-collapse">
        <thead className="bg-gray-50 border-b border-gray-200">
          <tr>
            <th className="p-5 text-xs font-bold text-gray-500 uppercase tracking-wider">Obra / Usuario</th>
            <th className="p-5 text-xs font-bold text-gray-500 uppercase tracking-wider">Detalles</th>
            <th className="p-5 text-xs font-bold text-gray-500 uppercase tracking-wider">Fecha</th>
            <th className="p-5 text-xs font-bold text-gray-500 uppercase tracking-wider">Estado</th>
            <th className="p-5 text-xs font-bold text-gray-500 uppercase tracking-wider text-right">Acciones</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100">
          {data.map((row) => (
            <tr key={row.id} className="hover:bg-blue-50/50 transition-colors group">
              <td className="p-5">
                <div className="flex items-center gap-4">
                  {row.img ? (
                    <img src={row.img} className="w-12 h-12 rounded-lg object-cover shadow-sm border border-gray-100" alt=""/>
                  ) : (
                    <div className="w-12 h-12 rounded-lg bg-blue-100 text-blue-600 flex items-center justify-center font-bold text-xl">
                      {row.name[0]}
                    </div>
                  )}
                  <div>
                    <p className="font-bold text-[#2B2B2E]">{row.title || row.name}</p>
                    <p className="text-xs text-gray-500">{row.email || "ID: #8293"}</p>
                  </div>
                </div>
              </td>
              <td className="p-5 text-sm text-gray-600">{row.author || `${row.artworks} obras enviadas`}</td>
              <td className="p-5 text-sm text-gray-600">{row.date || row.registered}</td>
              <td className="p-5"><Badge status={row.status} /></td>
              <td className="p-5 text-right">
                <div className="flex justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                  {row.title && (
                    <Button variant="outline" size="sm" onClick={() => setSelectedArtwork(row)}>
                      <Eye size={16} className="text-gray-600"/>
                    </Button>
                  )}
                  <Button variant="outline" size="sm"><Edit size={16} /></Button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </Card>
  );

  return (
    <div className="flex h-screen bg-[#F4F4F6] font-sans text-[#2B2B2E] overflow-hidden">
      
      {/* --- SIDEBAR --- */}
      <aside className="w-72 bg-[#223B80] text-white flex flex-col shadow-2xl z-20 flex-shrink-0">
        {/* Logo */}
        <div className="h-20 flex items-center px-8 border-b border-white/10">
          <div className="w-10 h-10 bg-[#F8C41E] rounded-xl flex items-center justify-center mr-3 shadow-lg transform rotate-3">
            <span className="font-black text-[#223B80] text-xl">J</span>
          </div>
          <div>
            <h1 className="font-bold text-xl tracking-tight">JOVI ADMIN</h1>
            <p className="text-xs text-blue-300 font-medium tracking-widest uppercase">Panel Control</p>
          </div>
        </div>

        {/* Menú */}
        <nav className="flex-1 p-6 space-y-2 overflow-y-auto">
          {[
            { id: 'dashboard', icon: LayoutDashboard, label: 'Dashboard' },
            { id: 'reviews', icon: Eye, label: 'En Revisión', badge: 4 },
            { id: 'approved', icon: CheckCircle, label: 'Aprobadas' },
            { id: 'map', icon: MapIcon, label: 'Mapa Global' },
            { id: 'users', icon: Users, label: 'Usuarios' },
            { id: 'settings', icon: Settings, label: 'Ajustes' },
          ].map((item) => (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`w-full flex items-center justify-between px-4 py-3.5 rounded-xl transition-all duration-200 group ${
                activeTab === item.id 
                  ? 'bg-[#F8C41E] text-[#223B80] font-bold shadow-md translate-x-1' 
                  : 'text-blue-100 hover:bg-white/10 hover:text-white'
              }`}
            >
              <div className="flex items-center gap-3">
                <item.icon size={20} className={activeTab === item.id ? 'text-[#223B80]' : 'text-blue-300 group-hover:text-white'} />
                <span>{item.label}</span>
              </div>
              {item.badge && (
                <span className={`text-xs font-bold px-2 py-0.5 rounded-md ${
                  activeTab === item.id ? 'bg-[#223B80]/20 text-[#223B80]' : 'bg-[#E34132] text-white'
                }`}>
                  {item.badge}
                </span>
              )}
            </button>
          ))}
        </nav>

        {/* Footer Sidebar */}
        <div className="p-6 border-t border-white/10">
          <button className="flex items-center gap-3 text-blue-200 hover:text-white w-full px-4 py-3 rounded-xl hover:bg-red-500/20 hover:text-red-200 transition-all">
            <LogOut size={20} />
            <span className="font-medium">Cerrar Sesión</span>
          </button>
        </div>
      </aside>

      {/* --- MAIN CONTENT --- */}
      <main className="flex-1 flex flex-col min-w-0">
        
        {/* Topbar */}
        <header className="h-20 bg-white border-b border-gray-200 flex items-center justify-between px-10 shadow-sm z-10 flex-shrink-0">
          <div className="flex items-center gap-3 text-sm text-gray-500">
            <span>Admin</span>
            <ChevronRight size={14} />
            <span className="font-bold text-[#223B80] capitalize">{activeTab}</span>
          </div>

          <div className="flex items-center gap-6">
            <div className="relative hidden md:block w-80">
              <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
              <input 
                type="text" 
                placeholder="Buscar obras, usuarios, IDs..." 
                className="w-full bg-gray-50 border border-gray-200 rounded-full pl-11 pr-4 py-2.5 text-sm focus:ring-2 focus:ring-[#223B80] focus:outline-none transition-all"
              />
            </div>
            <button className="relative p-2 text-gray-400 hover:bg-gray-100 rounded-full transition-colors">
              <Bell size={20} />
              <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full border-2 border-white"></span>
            </button>
            <div className="h-8 w-px bg-gray-200"></div>
            <div className="flex items-center gap-3">
              <div className="text-right hidden md:block leading-tight">
                <p className="text-sm font-bold text-[#2B2B2E]">Admin General</p>
                <p className="text-xs text-gray-500">admin@jovi.com</p>
              </div>
              <div className="w-10 h-10 bg-[#223B80] text-white rounded-full flex items-center justify-center font-bold shadow-md ring-4 ring-gray-50 border-2 border-white">
                A
              </div>
            </div>
          </div>
        </header>

        {/* Content Scroll */}
        <div className="flex-1 overflow-y-auto p-10 bg-[#F4F4F6]">
          <div className="max-w-7xl mx-auto pb-10">
            <div className="flex justify-between items-end mb-8">
              <div>
                <h1 className="text-3xl font-black text-[#2B2B2E] tracking-tight capitalize">{activeTab}</h1>
                <p className="text-gray-500 mt-1">Gestión y revisión del sistema</p>
              </div>
              {activeTab !== 'dashboard' && (
                <div className="flex gap-3">
                  <Button variant="outline"><Filter size={18} /> Filtros</Button>
                  <Button variant="primary">Generar Reporte</Button>
                </div>
              )}
            </div>

            {/* Renderizado Condicional */}
            {activeTab === 'dashboard' && <DashboardContent />}
            {activeTab === 'reviews' && <TableContent data={MOCK_ARTWORKS} />}
            {activeTab === 'approved' && <TableContent data={MOCK_ARTWORKS.filter(a => a.status === 'approved')} />}
            {activeTab === 'users' && <TableContent data={MOCK_USERS} />}
            {activeTab === 'map' && (
               <Card className="h-[600px] flex items-center justify-center border-2 border-dashed border-gray-300 bg-gray-50">
                  <div className="text-center text-gray-400">
                    <MapIcon size={64} className="mx-auto mb-4 opacity-50"/>
                    <h3 className="text-lg font-bold">Mapa Global Interactivo</h3>
                    <p>Aquí se cargaría la integración de mapa completo para escritorio.</p>
                  </div>
               </Card>
            )}
             {activeTab === 'settings' && (
               <Card className="h-[400px] flex items-center justify-center">
                  <div className="text-center text-gray-400">
                    <Settings size={48} className="mx-auto mb-4 opacity-50"/>
                    <p>Configuración del Sistema</p>
                  </div>
               </Card>
            )}
          </div>
        </div>
      </main>

      <DetailModal 
        artwork={selectedArtwork} 
        isOpen={!!selectedArtwork} 
        onClose={() => setSelectedArtwork(null)} 
      />
    </div>
  );
}