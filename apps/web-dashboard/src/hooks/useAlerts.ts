import { useState, useEffect, useCallback } from 'react';

export interface Alert {
  name: string;
  rule: string;
  actual: number;
  threshold: number;
  severity: string;
  triggered: boolean;
  unit: string;
}

export function useAlerts() {
  const [alerts, setAlerts] = useState<Alert[]>([]);

  const fetchAlerts = useCallback(async () => {
    try {
      const res = await fetch('/api/alerts');
      const data = await res.json();
      setAlerts(data.alerts || []);
    } catch {
      /* best-effort */
    }
  }, []);

  useEffect(() => {
    void fetchAlerts();
    const interval = setInterval(fetchAlerts, 10000);
    return () => clearInterval(interval);
  }, [fetchAlerts]);

  const triggeredAlerts = alerts.filter((a) => a.triggered);

  return { alerts, triggeredAlerts };
}
