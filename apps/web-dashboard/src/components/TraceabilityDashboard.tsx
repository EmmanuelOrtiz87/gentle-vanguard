import React, { useState, useEffect } from 'react';
import { useLocale } from '../hooks/useLocale';

// Tipos para eventos de trazabilidad
interface TraceEvent {
  id: string;
  timestamp: string;
  eventType: 'session.start' | 'tool.call' | 'metric.update' | 'error' | 'warning';
  component: string;
  description: string;
  details?: Record<string, any>;
  correlationId?: string;
  sessionId?: string;
}

const TraceabilityDashboard: React.FC = () => {
  const { t } = useLocale();
  const [events, setEvents] = useState<TraceEvent[]>([]);
  const [filteredEvents, setFilteredEvents] = useState<TraceEvent[]>([]);
  const [filters, setFilters] = useState({
    eventType: 'all',
    component: 'all',
    dateRange: { start: '', end: '' }
  });
  const [loading, setLoading] = useState(false);

  // Simular datos de eventos para demostración
  useEffect(() => {
    setLoading(true);
    
    // Simular llamada a API
    setTimeout(() => {
      const sampleEvents: TraceEvent[] = [
        {
          id: '1',
          timestamp: new Date().toISOString(),
          eventType: 'session.start',
          component: 'session',
          description: 'Nueva sesión iniciada',
          details: { sessionId: 'session-20260721T1600', userId: 'user-123' },
          correlationId: 'corr-12345'
        },
        {
          id: '2',
          timestamp: new Date(Date.now() - 300000).toISOString(),
          eventType: 'tool.call',
          component: 'metrics',
          description: 'Llamada a herramienta gpt-4',
          details: { tool: 'gpt-4', duration: 1200, tokens: 12500 },
          correlationId: 'corr-12345'
        },
        {
          id: '3',
          timestamp: new Date(Date.now() - 600000).toISOString(),
          eventType: 'metric.update',
          component: 'dashboard',
          description: 'Actualización de métricas',
          details: { metricsUpdated: ['tokens_used', 'memory_usage'] },
          correlationId: 'corr-12345'
        },
        {
          id: '4',
          timestamp: new Date(Date.now() - 1200000).toISOString(),
          eventType: 'error',
          component: 'api',
          description: 'Error en conexión a API externa',
          details: { error: 'Timeout', statusCode: 500 },
          correlationId: 'corr-12345'
        },
        {
          id: '5',
          timestamp: new Date(Date.now() - 1800000).toISOString(),
          eventType: 'warning',
          component: 'logging',
          description: 'Alto uso de memoria detectado',
          details: { memoryUsage: '85%', threshold: '80%' },
          correlationId: 'corr-12345'
        },
        {
          id: '6',
          timestamp: new Date(Date.now() - 2400000).toISOString(),
          eventType: 'session.start',
          component: 'session',
          description: 'Sesión reanudada',
          details: { sessionId: 'session-20260721T1400', userId: 'user-123' },
          correlationId: 'corr-12345'
        }
      ];
      
      setEvents(sampleEvents);
      setFilteredEvents(sampleEvents);
      setLoading(false);
    }, 500);
  }, []);

  // Filtrar eventos según los filtros
  useEffect(() => {
    let filtered = [...events];
    
    // Filtrar por tipo de evento
    if (filters.eventType !== 'all') {
      filtered = filtered.filter(event => event.eventType === filters.eventType);
    }
    
    // Filtrar por componente
    if (filters.component !== 'all') {
      filtered = filtered.filter(event => event.component === filters.component);
    }
    
    setFilteredEvents(filtered);
  }, [filters, events]);

  // Manejar cambios en los filtros
  const handleFilterChange = (key: string, value: string) => {
    setFilters(prev => ({ ...prev, [key]: value }));
  };

  // Formatear fecha
  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleString();
  };

  // Renderizar tipo de evento
  const renderEventTypeBadge = (eventType: string) => {
    const typeClasses: Record<string, string> = {
      'session.start': 'bg-green-100 text-green-800 border-green-200',
      'tool.call': 'bg-blue-100 text-blue-800 border-blue-200',
      'metric.update': 'bg-purple-100 text-purple-800 border-purple-200',
      'error': 'bg-red-100 text-red-800 border-red-200',
      'warning': 'bg-yellow-100 text-yellow-800 border-yellow-200'
    };
    
    return (
      <span className={`px-2 py-1 rounded-full text-xs font-medium border ${typeClasses[eventType] || 'bg-gray-100 text-gray-800'}`}>
        {eventType.replace('.', ' ')}
      </span>
    );
  };

  // Renderizar tabla de eventos
  const renderEventTable = () => {
    if (loading) {
      return <div className="text-center py-8">Cargando eventos...</div>;
    }
    
    if (filteredEvents.length === 0) {
      return <div className="text-center py-8 text-gray-500">No hay eventos registrados</div>;
    }
    
    return (
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Fecha</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tipo</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Componente</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Descripción</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Correlación</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {filteredEvents.map((event) => (
              <tr key={event.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{formatDate(event.timestamp)}</td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {renderEventTypeBadge(event.eventType)}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{event.component}</td>
                <td className="px-6 py-4 text-sm text-gray-900 max-w-md">{event.description}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {event.correlationId || '-'}
                </td>
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
        <h2 className="text-xl font-bold text-gray-900">Trazabilidad del Sistema</h2>
        <button 
          onClick={() => {
            // Simular refresco
            setLoading(true);
            setTimeout(() => setLoading(false), 500);
          }}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
        >
          Refrescar
        </button>
      </div>
      
      {/* Filtros */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Tipo de Evento</label>
          <select 
            value={filters.eventType}
            onChange={(e) => handleFilterChange('eventType', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">Todos</option>
            <option value="session.start">Inicio de Sesión</option>
            <option value="tool.call">Llamada a Herramienta</option>
            <option value="metric.update">Actualización de Métricas</option>
            <option value="error">Error</option>
            <option value="warning">Advertencia</option>
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
            <option value="session">Sesión</option>
            <option value="metrics">Métricas</option>
            <option value="api">API</option>
            <option value="logging">Logging</option>
            <option value="dashboard">Dashboard</option>
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
      </div>
      
      {/* Tabla de eventos */}
      {renderEventTable()}
      
      {/* Diagrama de flujo de trazabilidad */}
      <div className="mt-8">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Diagrama de Flujo de Trazabilidad</h3>
        <div className="border rounded-lg p-4 bg-gray-50">
          <div className="flex flex-col items-center">
            <div className="flex items-center mb-4">
              <div className="bg-blue-500 text-white px-4 py-2 rounded-lg mr-2">Sesión Iniciada</div>
              <div className="text-gray-500">→</div>
              <div className="bg-green-500 text-white px-4 py-2 rounded-lg mx-2">Herramienta Llamada</div>
              <div className="text-gray-500">→</div>
              <div className="bg-purple-500 text-white px-4 py-2 rounded-lg ml-2">Métricas Actualizadas</div>
            </div>
            <div className="text-sm text-gray-600">
              Correlación: corr-12345
            </div>
          </div>
        </div>
      </div>
      
      {/* Estadísticas de trazabilidad */}
      <div className="mt-6 pt-4 border-t border-gray-200">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Estadísticas de Trazabilidad</h3>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-blue-50 p-4 rounded-lg">
            <h4 className="font-medium text-blue-800">Eventos Totales</h4>
            <p className="text-2xl font-bold text-blue-600">{filteredEvents.length}</p>
          </div>
          <div className="bg-green-50 p-4 rounded-lg">
            <h4 className="font-medium text-green-800">Sesiones</h4>
            <p className="text-2xl font-bold text-green-600">
              {filteredEvents.filter(e => e.eventType === 'session.start').length}
            </p>
          </div>
          <div className="bg-red-50 p-4 rounded-lg">
            <h4 className="font-medium text-red-800">Errores</h4>
            <p className="text-2xl font-bold text-red-600">
              {filteredEvents.filter(e => e.eventType === 'error').length}
            </p>
          </div>
          <div className="bg-yellow-50 p-4 rounded-lg">
            <h4 className="font-medium text-yellow-800">Advertencias</h4>
            <p className="text-2xl font-bold text-yellow-600">
              {filteredEvents.filter(e => e.eventType === 'warning').length}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TraceabilityDashboard;