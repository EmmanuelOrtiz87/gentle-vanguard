import { useState, useEffect, useCallback } from 'react';
import type { DashboardData, MetricHistory } from '../types/dashboard';

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
  const [wsConnected, setWsConnected] = useState(false);

  const updateFromPayload = useCallback(
    (payload: { tokens: any; sessions: any; git: any; health: any; timestamp?: string }) => {
      setData({
        tokens: payload.tokens,
        sessions: payload.sessions,
        git: payload.git,
        health: payload.health,
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

  const connectWebSocket = useCallback(() => {
    if (!useWebSocketMode) return;

    const ws = new WebSocket('ws://localhost:8080');

    ws.onopen = () => {
      setWsConnected(true);
      setError(null);
    };

    ws.onmessage = (event) => {
      try {
        const message = JSON.parse(event.data);
        if (message.type === 'metrics') {
          updateFromPayload(message.data);
        }
      } catch (err) {
        console.error('[WS] Parse error:', err);
      }
    };

    ws.onclose = () => {
      setWsConnected(false);
      setTimeout(connectWebSocket, 3000);
    };

    ws.onerror = () => {
      setError('WebSocket connection failed');
    };

    return () => ws.close();
  }, [useWebSocketMode, updateFromPayload]);

  const fetchMetrics = useCallback(async () => {
    if (useWebSocketMode && wsConnected) return;

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
  }, [useWebSocketMode, wsConnected, updateFromPayload]);

  useEffect(() => {
    if (useWebSocketMode) {
      const cleanup = connectWebSocket();
      return cleanup;
    } else {
      fetchMetrics();
      const interval = setInterval(fetchMetrics, 5000);
      return () => clearInterval(interval);
    }
  }, [useWebSocketMode, connectWebSocket, fetchMetrics]);

  return { data, history, loading, error, wsConnected, refetch: fetchMetrics };
}
