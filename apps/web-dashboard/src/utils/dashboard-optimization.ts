import React, { useEffect, useRef, useState } from 'react';

// Tipos para las funciones de optimización
interface DashboardOptimizationProps {
  refreshInterval?: number;
  children: React.ReactNode;
}

// Hook para optimización de refresco
export const useDashboardOptimization = (refreshInterval: number = 5000) => {
  const [isPaused, setIsPaused] = useState(false);
  const [lastUpdate, setLastUpdate] = useState(Date.now());
  const debounceTimer = useRef<NodeJS.Timeout | null>(null);
  const throttleTimer = useRef<NodeJS.Timeout | null>(null);
  
  // Debounce para refresco
  const debounceRefresh = (callback: () => void, delay: number) => {
    if (debounceTimer.current) {
      clearTimeout(debounceTimer.current);
    }
    debounceTimer.current = setTimeout(callback, delay);
  };
  
  // Throttle para solicitudes
  const throttleRequest = (callback: () => void, limit: number) => {
    const now = Date.now();
    if (!throttleTimer.current || now - throttleTimer.current > limit) {
      callback();
      throttleTimer.current = now;
    }
  };
  
  // Pausar refresco
  const pauseRefresh = () => {
    setIsPaused(true);
  };
  
  // Reanudar refresco
  const resumeRefresh = () => {
    setIsPaused(false);
    setLastUpdate(Date.now());
  };
  
  // Verificar si se debe actualizar
  const shouldUpdate = () => {
    return !isPaused && (Date.now() - lastUpdate) > refreshInterval;
  };
  
  // Limpiar timers al desmontar
  useEffect(() => {
    return () => {
      if (debounceTimer.current) {
        clearTimeout(debounceTimer.current);
      }
      if (throttleTimer.current) {
        clearTimeout(throttleTimer.current);
      }
    };
  }, []);
  
  return {
    isPaused,
    pauseRefresh,
    resumeRefresh,
    shouldUpdate,
    debounceRefresh,
    throttleRequest
  };
};

// Componente de optimización de datos
export const OptimizedDataLoader: React.FC<{
  fetchData: () => Promise<any>;
  onDataLoaded: (data: any) => void;
  refreshInterval?: number;
  cacheEnabled?: boolean;
}> = ({ fetchData, onDataLoaded, refreshInterval = 5000, cacheEnabled = true }) => {
  const [cachedData, setCachedData] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const cacheRef = useRef<{ data: any; timestamp: number } | null>(null);
  
  // Cargar datos con cache
  const loadData = async () => {
    if (loading) return;
    
    setLoading(true);
    setError(null);
    
    try {
      // Verificar cache
      if (cacheEnabled && cacheRef.current) {
        const cacheAge = Date.now() - cacheRef.current.timestamp;
        if (cacheAge < 300000) { // 5 minutos
          onDataLoaded(cacheRef.current.data);
          setLoading(false);
          return;
        }
      }
      
      const data = await fetchData();
      setCachedData(data);
      cacheRef.current = {
        data,
        timestamp: Date.now()
      };
      onDataLoaded(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error desconocido');
      console.error('Error loading data:', err);
    } finally {
      setLoading(false);
    }
  };
  
  // Configurar intervalo de refresco
  useEffect(() => {
    const interval = setInterval(loadData, refreshInterval);
    loadData(); // Cargar datos iniciales
    
    return () => clearInterval(interval);
  }, [refreshInterval]);
  
  return { data: cachedData, loading, error, reload: loadData };
};

// Componente principal de optimización del dashboard
export const DashboardOptimizer: React.FC<DashboardOptimizationProps> = ({ 
  refreshInterval = 5000, 
  children 
}) => {
  const [isPaused, setIsPaused] = useState(false);
  const [lastUpdate, setLastUpdate] = useState(Date.now());
  const [isLoading, setIsLoading] = useState(false);
  const debounceTimer = useRef<NodeJS.Timeout | null>(null);
  
  // Debounce para refresco
  const debounceRefresh = (callback: () => void, delay: number) => {
    if (debounceTimer.current) {
      clearTimeout(debounceTimer.current);
    }
    debounceTimer.current = setTimeout(callback, delay);
  };
  
  // Pausar refresco
  const pauseRefresh = () => {
    setIsPaused(true);
  };
  
  // Reanudar refresco
  const resumeRefresh = () => {
    setIsPaused(false);
    setLastUpdate(Date.now());
  };
  
  // Verificar si se debe actualizar
  const shouldUpdate = () => {
    return !isPaused && (Date.now() - lastUpdate) > refreshInterval;
  };
  
  // Limpiar timers al desmontar
  useEffect(() => {
    return () => {
      if (debounceTimer.current) {
        clearTimeout(debounceTimer.current);
      }
    };
  }, []);
  
  return (
    <div className={`dashboard-optimizer ${isPaused ? 'paused' : ''}`}>
      <div className="dashboard-controls">
        <button 
          onClick={pauseRefresh}
          className={`control-btn ${isPaused ? 'paused' : 'running'}`}
        >
          {isPaused ? '▶️ Reanudar' : '⏸️ Pausar'}
        </button>
        <span className="status-text">
          {isPaused ? 'Pausado' : 'Activo'}
        </span>
      </div>
      <div className="dashboard-content">
        {children}
      </div>
    </div>
  );
};