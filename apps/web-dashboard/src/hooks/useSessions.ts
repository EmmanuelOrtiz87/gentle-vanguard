import { useState, useEffect, useCallback, useRef } from 'react';
import type { Session } from '../types/dashboard';

export function useSessions() {
  const [sessions, setSessions] = useState<Session[]>([]);
  const requestRef = useRef<AbortController | null>(null);

  const fetchSessions = useCallback(async () => {
    requestRef.current?.abort();
    const controller = new AbortController();
    requestRef.current = controller;
    try {
      const res = await fetch('/api/agent/sessions', { signal: controller.signal });
      if (!res.ok) return;
      const data = await res.json();
      const list: Session[] = (data.sessions || []).map((s: any) => ({
        id: s.id || s.sessionId || 'unknown',
        agent: s.agent || 'DEV',
        status: s.status === 'active' || s.status === 'awaiting_input' ? 'active' : 'idle',
        startTime: s.startedAt || s.createdAt || s.startTime || new Date().toISOString(),
        tokensUsed: s.totalTokens || s.tokensUsed || 0,
        model: s.model || 'unknown',
        cost: s.totalCost || s.cost || 0,
      }));
      setSessions(list);
    } catch (error) {
      if (error instanceof DOMException && error.name === 'AbortError') return;
      /* best-effort */
    } finally {
      if (requestRef.current === controller) requestRef.current = null;
    }
  }, []);

  useEffect(() => {
    void fetchSessions();
    const interval = setInterval(fetchSessions, 10000);
    return () => {
      clearInterval(interval);
      requestRef.current?.abort();
    };
  }, [fetchSessions]);

  return sessions;
}
