// @ts-nocheck — React hooks used from apps/web-dashboard context
// React types not available in root src/ tsconfig scope
/* eslint-disable @typescript-eslint/no-explicit-any */

// Hook para optimización de refresco
export const useDashboardOptimization = (refreshInterval = 5000) => {
  const [isPaused, setIsPaused] = useState(false);
  const [lastUpdate, setLastUpdate] = useState(Date.now());
  const debounceTimer = useRef<any>(null);
  const throttleTimer = useRef<any>(null);
  
  // Debounce para refresco
  const debounceRefresh = (callback: () => void, delay: number) => {
    clearTimeout(debounceTimer.current);
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
export const OptimizedDataLoader = ({ 
  fetchData, 
  onDataLoaded, 
  refreshInterval = 5000,
  cacheEnabled = true 
}: {
  fetchData: () => Promise<any>;
  onDataLoaded: (data: any) => void;
  refreshInterval?: number;
  cacheEnabled?: boolean;
}) => {
  const [cachedData, setCachedData] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<any>(null);
  const cacheRef = useRef<{ data?: any; timestamp?: number }>({});
  
  // Cargar datos con cache
  const loadData = async () => {
    if (loading) return;
    
    setLoading(true);
    setError(null);
    
    try {
      // Verificar cache
      if (cacheEnabled && cacheRef.current.data) {
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
    } catch (err: any) {
      setError(err?.message || String(err));
      console.error('Error loading data:', err);
    } finally {
      setLoading(false);
    }
  };
  
  useEffect(() => {
    const interval = setInterval(loadData, refreshInterval);
    loadData(); // Cargar datos iniciales
    
    return () => clearInterval(interval);
  }, [refreshInterval]);
  
  return { data: cachedData, loading, error, reload: loadData };
};

// Componente de logs optimizados
export const OptimizedErrorLogger = () => {
  const [logs, setLogs] = useState<any[]>([]);
  const [filteredLogs, setFilteredLogs] = useState<any[]>([]);
  const [filters, setFilters] = useState({
    level: 'all',
    component: 'all',
    dateRange: { start: '', end: '' }
  });
  
  // Filtrar logs
  const filterLogs = (newFilters: { level: string; component: string; dateRange: { start: string; end: string } }) => {
    setFilters(newFilters);
    const filtered = logs.filter(log => {
      if (newFilters.level !== 'all' && (log as any).level !== newFilters.level) return false;
      if (newFilters.component !== 'all' && (log as any).component !== newFilters.component) return false;
      return true;
    });
    setFilteredLogs(filtered);
  };
  
  return {
    logs,
    filteredLogs,
    filters,
    filterLogs,
    addLog: (log: any) => {
      setLogs((prev: any[]) => [log, ...prev.slice(0, 999)]);
    }
  };
};