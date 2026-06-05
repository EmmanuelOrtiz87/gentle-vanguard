import { useState, useEffect, useCallback, useRef } from 'react';
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

  const wsRef = useRef<WebSocket | null>(null);
  const reconnectRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const modeRef = useRef(useWebSocketMode);

  useEffect(() => {
    modeRef.current = useWebSocketMode;
  }, [useWebSocketMode]);

  const updateFromPayload = useCallback(
    (payload: { tokens: any; sessions: any; git: any; health: any; globalHealth?: any; mcp?: any; timestamp?: string }) => {
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

  const cleanupWebSocket = useCallback(() => {
    if (reconnectRef.current) {
      clearTimeout(reconnectRef.current);
      reconnectRef.current = null;
    }
    if (wsRef.current) {
      wsRef.current.onopen = null;
      wsRef.current.onclose = null;
      wsRef.current.onerror = null;
      wsRef.current.onmessage = null;
      if (wsRef.current.readyState === WebSocket.OPEN || wsRef.current.readyState === WebSocket.CONNECTING) {
        wsRef.current.close();
      }
      wsRef.current = null;
    }
  }, []);

  const connectWebSocket = useCallback(() => {
    if (!modeRef.current) return;

    cleanupWebSocket();

    const ws = new WebSocket('ws://localhost:8080');
    wsRef.current = ws;

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
      if (wsRef.current === ws && modeRef.current) {
        wsRef.current = null;
        reconnectRef.current = setTimeout(connectWebSocket, 3000);
      }
    };

    ws.onerror = () => {
      setError('WebSocket connection failed');
    };
  }, [updateFromPayload, cleanupWebSocket]);

  const fetchMetrics = useCallback(async () => {
    if (modeRef.current && wsConnected) return;

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

  useEffect(() => {
    if (useWebSocketMode) {
      cleanupWebSocket();
      connectWebSocket();
      return cleanupWebSocket;
    } else {
      cleanupWebSocket();
      fetchMetrics();
      const interval = setInterval(fetchMetrics, 5000);
      return () => {
        clearInterval(interval);
        cleanupWebSocket();
      };
    }
  }, [useWebSocketMode, connectWebSocket, fetchMetrics, cleanupWebSocket]);

  return { data, history, loading, error, wsConnected, refetch: fetchMetrics };
}
