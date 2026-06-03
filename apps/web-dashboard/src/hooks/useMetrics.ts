import { useState, useEffect, useCallback } from 'react';
import type { DashboardData, MetricHistory } from '../types/dashboard';

const MOCK_DATA: DashboardData = {
  tokens: { used: 15000, limit: 30000, cost: 0.45 },
  sessions: { total: 42, active: 3, today: 5 },
  git: { commits: 128, prsMerged: 15, contributors: 4 },
  health: { status: 'healthy', routing: 0.95 },
};

export function useMetrics(useWebSocketMode = false) {
  const [data, setData] = useState<DashboardData>(MOCK_DATA);
  const [history, setHistory] = useState<MetricHistory[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [wsConnected, setWsConnected] = useState(false);

  // WebSocket connection
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
          setData(message.data);
          setHistory((prev) => {
            const newEntry: MetricHistory = {
              timestamp: message.data.timestamp || new Date().toISOString(),
              tokens: message.data.tokens.used,
              sessions: message.data.sessions.active,
              cost: message.data.tokens.cost,
            };
            return [...prev, newEntry].slice(-20);
          });
        }
      } catch (err) {
        console.error('[WS] Parse error:', err);
      }
    };

    ws.onclose = () => {
      setWsConnected(false);
      // Auto-reconnect after 3 seconds
      setTimeout(connectWebSocket, 3000);
    };

    ws.onerror = () => {
      setError('WebSocket connection failed');
    };

    return () => ws.close();
  }, [useWebSocketMode]);

  // HTTP fallback
  const fetchMetrics = useCallback(async () => {
    if (useWebSocketMode && wsConnected) return;

    setLoading(true);
    try {
      await new Promise((resolve) => setTimeout(resolve, 500));

      const newData: DashboardData = {
        tokens: {
          used: MOCK_DATA.tokens.used + Math.floor(Math.random() * 100),
          limit: MOCK_DATA.tokens.limit,
          cost: MOCK_DATA.tokens.cost + Math.random() * 0.01,
        },
        sessions: {
          total: MOCK_DATA.sessions.total + Math.floor(Math.random() * 2),
          active: MOCK_DATA.sessions.active,
          today: MOCK_DATA.sessions.today,
        },
        git: MOCK_DATA.git,
        health: MOCK_DATA.health,
      };

      setData(newData);
      setHistory((prev) => {
        const newEntry: MetricHistory = {
          timestamp: new Date().toISOString(),
          tokens: newData.tokens.used,
          sessions: newData.sessions.active,
          cost: newData.tokens.cost,
        };
        return [...prev, newEntry].slice(-20);
      });

      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch metrics');
    } finally {
      setLoading(false);
    }
  }, [useWebSocketMode, wsConnected]);

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
