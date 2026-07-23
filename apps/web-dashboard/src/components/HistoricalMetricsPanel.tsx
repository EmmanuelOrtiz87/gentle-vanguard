import React, { useState, useEffect } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { useLocale } from '../hooks/useLocale';

// Tipos para métricas históricas
interface HistoricalMetric {
  timestamp: string;
  metricName: string;
  value: number;
  unit: string;
  trend: 'up' | 'down' | 'stable';
}

interface MetricFilter {
  metric: string;
  timeRange: '1h' | '6h' | '1d' | '1w' | '1m';
  component: string;
}

const HistoricalMetricsPanel: React.FC = () => {
  const { t } = useLocale();
  const [filters, setFilters] = useState<MetricFilter>({
    metric: 'all',
    timeRange: '1d',
    component: 'all'
  });
  
  const [metrics, setMetrics] = useState<HistoricalMetric[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Simular datos históricos para demostración
  useEffect(() => {
    setLoading(true);
    
    // Simular llamada a API
    setTimeout(() => {
      const sampleMetrics: HistoricalMetric[] = [
        { timestamp: '2026-07-21T10:00:00Z', metricName: 'tokens_used', value: 12500, unit: 'tokens', trend: 'up' },
        { timestamp: '2026-07-21T11:00:00Z', metricName: 'tokens_used', value: 15200, unit: 'tokens', trend: 'up' },
        { timestamp: '2026-07-21T12:00:00Z', metricName: 'tokens_used', value: 18700, unit: 'tokens', trend: 'up' },
        { timestamp: '2026-07-21T13:00:00Z', metricName: 'tokens_used', value: 16500, unit: 'tokens', trend: 'down' },
        { timestamp: '2026-07-21T14:00:00Z', metricName: 'tokens_used', value: 21300, unit: 'tokens', trend: 'up' },
        { timestamp: '2026-07-21T15:00:00Z', metricName: 'tokens_used', value: 24500, unit: 'tokens', trend: 'up' },
        { timestamp: '2026-07-21T16:00:00Z', metricName: 'tokens_used', value: 22800, unit: 'tokens', trend: 'down' },
        
        { timestamp: '2026-07-21T10:00:00Z', metricName: 'memory_usage', value: 75, unit: '%', trend: 'stable' },
        { timestamp: '2026-07-21T11:00:00Z', metricName: 'memory_usage', value: 78, unit: '%', trend: 'up' },
        { timestamp: '2026-07-21T12:00:00Z', metricName: 'memory_usage', value: 82, unit: '%', trend: 'up' },
        { timestamp: '2026-07-21T13:00:00Z', metricName: 'memory_usage', value: 79, unit: '%', trend: 'down' },
        { timestamp: '2026-07-21T14:00:00Z', metricName: 'memory_usage', value: 85, unit: '%', trend: 'up' },
        { timestamp: '2026-07-21T15:00:00Z', metricName: 'memory_usage', value: 88, unit: '%', trend: 'up' },
        { timestamp: '2026-07-21T16:00:00Z', metricName: 'memory_usage', value: 83, unit: '%', trend: 'down' },
        
        { timestamp: '2026-07-21T10:00:00Z', metricName: 'response_time', value: 1250, unit: 'ms', trend: 'stable' },
        { timestamp: '2026-07-21T11:00:00Z', metricName: 'response_time', value: 1320, unit: 'ms', trend: 'up' },
        { timestamp: '2026-07-21T12:00:00Z', metricName: 'response_time', value: 1450, unit: 'ms', trend: 'up' },
        { timestamp: '2026-07-21T13:00:00Z', metricName: 'response_time', value: 1380, unit: 'ms', trend: 'down' },
        { timestamp: '2026-07-21T14:00:00Z', metricName: 'response_time', value: 1520, unit: 'ms', trend: 'up' },
        { timestamp: '2026-07-21T15:00:00Z', metricName: 'response_time', value: 1680, unit: 'ms', trend: 'up' },
        { timestamp: '2026-07-21T16:00:00Z', metricName: 'response_time', value: 1590, unit: 'ms', trend: 'down' },
      ];
      
      setMetrics(sampleMetrics);
      setLoading(false);
    }, 500);
  }, []);

  // Filtrar métricas según los filtros
  const filteredMetrics = metrics.filter(metric => {
    if (filters.metric !== 'all' && metric.metricName !== filters.metric) return false;
    if (filters.component !== 'all' && metric.metricName.includes(filters.component)) return false;
    return true;
  });

  // Preparar datos para el gráfico
  const chartData = filteredMetrics.reduce((acc, metric) => {
    const existing = acc.find(item => item.timestamp === metric.timestamp);
    if (existing) {
      existing[metric.metricName] = metric.value;
    } else {
      acc.push({
        timestamp: metric.timestamp,
        [metric.metricName]: metric.value
      });
    }
    return acc;
  }, [] as any[]);

  // Renderizar tendencia
  const renderTrendIcon = (trend: string) => {
    switch (trend) {
      case 'up':
        return '📈';
      case 'down':
        return '📉';
      case 'stable':
        return '➡️';
      default:
        return '❓';
    }
  };

  // Formatear fecha
  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleTimeString();
  };

  return (
    <div className="bg-white shadow rounded-lg p-6">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-xl font-bold text-gray-900">Métricas Históricas</h2>
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
          <label className="block text-sm font-medium text-gray-700 mb-1">Métrica</label>
          <select 
            value={filters.metric}
            onChange={(e) => setFilters({...filters, metric: e.target.value})}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">Todas</option>
            <option value="tokens_used">Tokens Usados</option>
            <option value="memory_usage">Uso de Memoria</option>
            <option value="response_time">Tiempo de Respuesta</option>
          </select>
        </div>
        
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Rango de Tiempo</label>
          <select 
            value={filters.timeRange}
            onChange={(e) => setFilters({...filters, timeRange: e.target.value as any})}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="1h">Última Hora</option>
            <option value="6h">Últimas 6 Horas</option>
            <option value="1d">Último Día</option>
            <option value="1w">Última Semana</option>
            <option value="1m">Último Mes</option>
          </select>
        </div>
        
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Componente</label>
          <select 
            value={filters.component}
            onChange={(e) => setFilters({...filters, component: e.target.value})}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">Todos</option>
            <option value="dashboard">Dashboard</option>
            <option value="metrics">Métricas</option>
            <option value="logging">Logging</option>
          </select>
        </div>
      </div>
      
      {/* Gráfico */}
      <div className="h-80 mb-6">
        {loading ? (
          <div className="flex items-center justify-center h-full">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
          </div>
        ) : (
          <ResponsiveContainer width="100%" height="100%">
            <LineChart
              data={chartData}
              margin={{ top: 5, right: 30, left: 20, bottom: 5 }}
            >
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis 
                dataKey="timestamp" 
                tickFormatter={(value) => formatDate(value)}
                tick={{ fontSize: 12 }}
              />
              <YAxis />
              <Tooltip 
                formatter={(value) => [value, 'Valor']}
                labelFormatter={(value) => `Fecha: ${formatDate(value)}`}
              />
              <Legend />
              <Line 
                type="monotone" 
                dataKey="tokens_used" 
                stroke="#8884d8" 
                activeDot={{ r: 8 }} 
                name="Tokens Usados"
              />
              <Line 
                type="monotone" 
                dataKey="memory_usage" 
                stroke="#82ca9d" 
                name="Uso de Memoria (%)"
              />
              <Line 
                type="monotone" 
                dataKey="response_time" 
                stroke="#ffc658" 
                name="Tiempo de Respuesta (ms)"
              />
            </LineChart>
          </ResponsiveContainer>
        )}
      </div>
      
      {/* Tabla de métricas */}
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Fecha</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Métrica</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Valor</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tendencia</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {filteredMetrics.slice(0, 10).map((metric, index) => (
              <tr key={index} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {formatDate(metric.timestamp)}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {metric.metricName}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {metric.value} {metric.unit}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <span className="flex items-center">
                    {renderTrendIcon(metric.trend)}
                    <span className="ml-1 capitalize">{metric.trend}</span>
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      
      {/* Estadísticas */}
      <div className="mt-6 pt-4 border-t border-gray-200">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Estadísticas</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-blue-50 p-4 rounded-lg">
            <h4 className="font-medium text-blue-800">Promedio de Tokens</h4>
            <p className="text-2xl font-bold text-blue-600">18,400 tokens</p>
          </div>
          <div className="bg-green-50 p-4 rounded-lg">
            <h4 className="font-medium text-green-800">Uso Máximo de Memoria</h4>
            <p className="text-2xl font-bold text-green-600">88%</p>
          </div>
          <div className="bg-purple-50 p-4 rounded-lg">
            <h4 className="font-medium text-purple-800">Tiempo Promedio de Respuesta</h4>
            <p className="text-2xl font-bold text-purple-600">1,520 ms</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default HistoricalMetricsPanel;