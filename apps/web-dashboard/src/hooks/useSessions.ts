import { useState, useEffect, useCallback } from 'react';
import type { Session } from '../types/dashboard';

export function useSessions() {
  const [sessions, setSessions] = useState<Session[]>([]);

  const fetchSessions = useCallback(async () => {
    try {
      const res = await fetch('/api/agent/sessions');
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
    } catch {
      /* best-effort */
    }
  }, []);

  useEffect(() => {
    void fetchSessions();
    const interval = setInterval(fetchSessions, 10000);
    return () => clearInterval(interval);
  }, [fetchSessions]);

  return sessions;
}
