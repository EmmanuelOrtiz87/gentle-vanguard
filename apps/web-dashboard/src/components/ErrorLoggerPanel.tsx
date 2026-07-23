import React, { useState, useEffect } from 'react';
import { useLocale } from '../hooks/useLocale';

// Tipos para los errores
interface ErrorLog {
  id: string;
  timestamp: string;
  level: 'info' | 'debug' | 'warning' | 'error' | 'critical';
  component: string;
  message: string;
  stack?: string;
  context?: Record<string, any>;
  sessionId?: string;
  userId?: string;
}

// Tipos para los filtros
interface ErrorFilters {
  level: 'all' | 'info' | 'debug' | 'warning' | 'error' | 'critical';
  component: string;
  dateRange: { start: string; end: string };
  searchQuery: string;
}

const ErrorLoggerPanel: React.FC = () => {
  const { t } = useLocale();
  const [filters, setFilters] = useState<ErrorFilters>({
    level: 'all',
    component: 'all',
    dateRange: { start: '', end: '' },
    searchQuery: ''
  });
  
  const [logs, setLogs] = useState<ErrorLog[]>([]);
  const [filteredLogs, setFilteredLogs] = useState<ErrorLog[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isPaused, setIsPaused] = useState(false);

  // Simular datos de error para demostración
  useEffect(() => {
    const sampleErrors: ErrorLog[] = [
      {
        id: '1',
        timestamp: new Date().toISOString(),
        level: 'error',
        component: 'dashboard',
        message: 'Failed to load metrics data',
        stack: 'Error: Network timeout\n    at fetchMetrics (dashboard.ts:45)',
        context: { url: '/api/metrics', status: 500 }
      },
      {
        id: '2',
        timestamp: new Date(Date.now() - 300000).toISOString(),
        level: 'warning',
        component: 'metrics',
        message: 'High memory usage detected',
        context: { memory: '85%', threshold: '80%' }
      },
      {
        id: '3',
        timestamp: new Date(Date.now() - 600000).toISOString(),
        level: 'info',
        component: 'logging',
        message: 'New error logging system initialized',
        context: { version: '1.0.0' }
      },
      {
        id: '4',
        timestamp: new Date(Date.now() - 1200000).toISOString(),
        level: 'debug',
        component: 'api',
        message: 'API request processed successfully',
        context: { method: 'GET', endpoint: '/api/metrics' }
      }
    ];
    
    setLogs(sampleErrors);
    setFilteredLogs(sampleErrors);
  }, []);

  // Filtrar logs cuando cambian los filtros
  useEffect(() => {
    let filtered = [...logs];
    
    // Filtrar por nivel
    if (filters.level !== 'all') {
      filtered = filtered.filter(log => log.level === filters.level);
    }
    
    // Filtrar por componente
    if (filters.component !== 'all') {
      filtered = filtered.filter(log => log.component === filters.component);
    }
    
    // Filtrar por búsqueda
    if (filters.searchQuery) {
      const query = filters.searchQuery.toLowerCase();
      filtered = filtered.filter(log => 
        log.message.toLowerCase().includes(query) ||
        log.component.toLowerCase().includes(query)
      );
    }
    
    setFilteredLogs(filtered);
  }, [filters, logs]);

  // Manejar cambios en los filtros
  const handleFilterChange = (key: keyof ErrorFilters, value: any) => {
    setFilters(prev => ({ ...prev, [key]: value }));
  };

  // Limpiar todos los filtros
  const clearFilters = () => {
    setFilters({
      level: 'all',
      component: 'all',
      dateRange: { start: '', end: '' },
      searchQuery: ''
    });
  };

  // Renderizar nivel de severidad
  const renderSeverityBadge = (level: string) => {
    const severityClasses: Record<string, string> = {
      error: 'bg-red-100 text-red-800 border-red-200',
      warning: 'bg-yellow-100 text-yellow-800 border-yellow-200',
      info: 'bg-blue-100 text-blue-800 border-blue-200',
      debug: 'bg-gray-100 text-gray-800 border-gray-200',
      critical: 'bg-purple-100 text-purple-800 border-purple-200'
    };
    
    return (
      <span className={`px-2 py-1 rounded-full text-xs font-medium border ${severityClasses[level] || 'bg-gray-100 text-gray-800'}`}>
        {level.toUpperCase()}
      </span>
    );
  };

  // Formatear fecha
  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleString();
  };

  // Renderizar tabla de errores
  const renderErrorTable = () => {
    if (loading) {
      return <div className="text-center py-8">Cargando errores...</div>;
    }
    
    if (error) {
      return (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
          Error cargando logs: {error}
        </div>
      );
    }
    
    if (filteredLogs.length === 0) {
      return <div className="text-center py-8 text-gray-500">No hay errores registrados</div>;
    }
    
    return (
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Fecha</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Nivel</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Componente</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Mensaje</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {filteredLogs.map((log) => (
              <tr key={log.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{formatDate(log.timestamp)}</td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {renderSeverityBadge(log.level)}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{log.component}</td>
                <td className="px-6 py-4 text-sm text-gray-900 max-w-md truncate">{log.message}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  };

  return (
    <div className="bg-white shadow rounded-lg p-6">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-xl font-bold text-gray-900">Registro de Errores</h2>
        <div className="flex space-x-2">
          <button 
            onClick={() => setIsPaused(!isPaused)}
            className={`px-4 py-2 rounded-md transition-colors ${
              isPaused 
                ? 'bg-green-600 text-white hover:bg-green-700' 
                : 'bg-gray-600 text-white hover:bg-gray-700'
            }`}
          >
            {isPaused ? 'Reanudar' : 'Pausar'}
          </button>
          <button 
            onClick={() => {
              // Simular refresco
              const sampleErrors: ErrorLog[] = [
                {
                  id: Date.now().toString(),
                  timestamp: new Date().toISOString(),
                  level: 'error',
                  component: 'dashboard',
                  message: 'Nuevo error detectado',
                  context: { source: 'auto-refresh' }
                }
              ];
              setLogs(prev => [...sampleErrors, ...prev]);
            }}
            className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
          >
            Refrescar
          </button>
        </div>
      </div>
      
      {/* Filtros */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Nivel</label>
          <select 
            value={filters.level}
            onChange={(e) => handleFilterChange('level', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">Todos</option>
            <option value="error">Error</option>
            <option value="warning">Warning</option>
            <option value="info">Info</option>
            <option value="debug">Debug</option>
            <option value="critical">Critical</option>
          </select>
        </div>
        
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Componente</label>
          <select 
            value={filters.component}
            onChange={(e) => handleFilterChange('component', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">Todos</option>
            <option value="dashboard">Dashboard</option>
            <option value="metrics">Métricas</option>
            <option value="logging">Logging</option>
            <option value="api">API</option>
            <option value="session">Sesión</option>
          </select>
        </div>
        
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Desde</label>
          <input 
            type="datetime-local"
            value={filters.dateRange.start}
            onChange={(e) => handleFilterChange('dateRange', {...filters.dateRange, start: e.target.value})}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Hasta</label>
          <input 
            type="datetime-local"
            value={filters.dateRange.end}
            onChange={(e) => handleFilterChange('dateRange', {...filters.dateRange, end: e.target.value})}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
      </div>
      
      <div className="mb-4">
        <label className="block text-sm font-medium text-gray-700 mb-1">Buscar</label>
        <input 
          type="text"
          placeholder="Buscar mensajes o componentes..."
          value={filters.searchQuery}
          onChange={(e) => handleFilterChange('searchQuery', e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>
      
      <div className="flex justify-end mb-4">
        <button 
          onClick={clearFilters}
          className="px-4 py-2 text-sm text-gray-600 hover:text-gray-800"
        >
          Limpiar filtros
        </button>
      </div>
      
      {/* Tabla de errores */}
      {renderErrorTable()}
      
      {/* Información adicional */}
      <div className="mt-6 pt-4 border-t border-gray-200">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-blue-50 p-4 rounded-lg">
            <h3 className="font-medium text-blue-800">Total de Errores</h3>
            <p className="text-2xl font-bold text-blue-600">{filteredLogs.length}</p>
          </div>
          <div className="bg-red-50 p-4 rounded-lg">
            <h3 className="font-medium text-red-800">Errores Críticos</h3>
            <p className="text-2xl font-bold text-red-600">
              {filteredLogs.filter(l => l.level === 'critical').length}
            </p>
          </div>
          <div className="bg-yellow-50 p-4 rounded-lg">
            <h3 className="font-medium text-yellow-800">Advertencias</h3>
            <p className="text-2xl font-bold text-yellow-600">
              {filteredLogs.filter(l => l.level === 'warning').length}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ErrorLoggerPanel;