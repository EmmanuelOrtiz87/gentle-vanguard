import { useState, useCallback } from 'react';
import { useSharedWs } from './useSharedWs';

export interface Alert {
  name: string;
  rule: string;
  actual: number;
  threshold: number;
  severity: string;
  triggered: boolean;
  unit: string;
  transition?: string;
}

export function useAlerts() {
  const [alerts, setAlerts] = useState<Alert[]>([]);

  const handleMessage = useCallback((msg: Record<string, unknown>) => {
    if (msg.type === 'alerts') {
      setAlerts((msg.data as Alert[]) || []);
    }
  }, []);

  useSharedWs(handleMessage, [handleMessage]);

  const triggeredAlerts = alerts.filter((a) => a.triggered);

  return { alerts, triggeredAlerts };
}
