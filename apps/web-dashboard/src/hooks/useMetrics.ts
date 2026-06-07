import { useState, useEffect, useCallback, useRef } from 'react';
import type { DashboardData, MetricHistory } from '../types/dashboard';
import { useSharedWs } from './useSharedWs';

export interface Notification {
  type: string;
  message: string;
  severity: string;
  timestamp: string;
}

const FALLBACK_DATA: DashboardData = {
  tokens: { used: 0, limit: 0, cost: 0 },
  sessions: { total: 0, active: 0, today: 0 },
  git: { commits: 0, prsMerged: 0, contributors: 0 },
  health: { status: 'unknown', routing: 0 },
};

export function useMetrics(useWebSocketMode = false) {
  const [data, setData] = useState<DashboardData>(FALLBACK_DATA);
  const [history, setHistory] = useState<MetricHistory[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notifications, setNotifications] = useState<Notification[]>([]);

  const updateFromPayload = useCallback(
    (payload: {
      tokens: any;
      sessions: any;
      git: any;
      health: any;
      globalHealth?: any;
      mcp?: any;
      timestamp?: string;
    }) => {
      setData({
        tokens: payload.tokens,
        sessions: payload.sessions,
        git: payload.git,
        health: payload.health,
        globalHealth: payload.globalHealth,
        mcp: payload.mcp,
      });
      setHistory((prev) => {
        const newEntry: MetricHistory = {
          timestamp: payload.timestamp || new Date().toISOString(),
          tokens: payload.tokens.used,
          sessions: payload.sessions.active,
          cost: payload.tokens.cost,
        };
        return [...prev, newEntry].slice(-20);
      });
    },
    [],
  );

  const { connected: wsConnected } = useSharedWs(
    useCallback(
      (msg: any) => {
        if (msg.type === 'metrics') {
          updateFromPayload(msg.data);
        } else if (msg.type === 'notification') {
          setNotifications((prev) => {
            const notes: Notification[] = msg.notifications || [];
            const updated = [...notes, ...prev];
            return updated.slice(0, 20);
          });
          setTimeout(() => {
            setNotifications((prev) => prev.slice(0, -1));
          }, 8000);
        }
      },
      [updateFromPayload],
    ),
  );

  const fetchMetrics = useCallback(async () => {
    if (wsConnected) return;
    setLoading(true);
    try {
      const res = await fetch('/api/metrics');
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const message = await res.json();
      if (message.type === 'metrics') {
        updateFromPayload(message.data);
      }
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch metrics');
    } finally {
      setLoading(false);
    }
  }, [wsConnected, updateFromPayload]);

  const modeRef = useRef(useWebSocketMode);
  useEffect(() => {
    modeRef.current = useWebSocketMode;
  }, [useWebSocketMode]);

  useEffect(() => {
    if (!useWebSocketMode) {
      fetchMetrics();
      const interval = setInterval(fetchMetrics, 5000);
      return () => clearInterval(interval);
    }
  }, [useWebSocketMode, fetchMetrics]);

  const dismissNotification = useCallback((index: number) => {
    setNotifications((prev) => prev.filter((_, i) => i !== index));
  }, []);

  return {
    data,
    history,
    loading,
    error,
    wsConnected,
    refetch: fetchMetrics,
    notifications,
    dismissNotification,
  };
}
