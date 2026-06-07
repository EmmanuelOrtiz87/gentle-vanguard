import { useState, useEffect, useRef } from 'react';

export interface LiveTrace {
  id: string;
  model: string;
  turnCount: number;
  sessionId: string;
  timestamp: string;
}

export function useLiveTraces() {
  const [traces, setTraces] = useState<LiveTrace[]>([]);
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const ws = new WebSocket(`${protocol}//${window.location.host}/ws`);
    wsRef.current = ws;

    ws.onmessage = (event) => {
      try {
        const msg = JSON.parse(event.data);
        if (msg.type === 'trace_update' && msg.session?.state) {
          const s = msg.session.state;
          setTraces((prev) => {
            const updated = [
              { id: msg.session.id, model: s.model || 'unknown', turnCount: s.turnCount || 0, sessionId: s.sessionId || msg.session.id, timestamp: new Date().toISOString() },
              ...prev.filter((t) => t.id !== msg.session.id),
            ].slice(0, 10);
            return updated;
          });
        }
      } catch { /* ignore */ }
    };

    return () => ws.close();
  }, []);

  return traces;
}
