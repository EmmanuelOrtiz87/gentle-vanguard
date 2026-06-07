import { useState, useEffect, useRef } from 'react';

export interface Validation {
  name: string;
  status: 'ok' | 'warn' | 'error';
  message: string;
  value?: string | number;
}

export function useValidations() {
  const [validations, setValidations] = useState<Validation[]>([]);
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const ws = new WebSocket(`${protocol}//${window.location.host}/ws`);
    wsRef.current = ws;

    ws.onmessage = (event) => {
      try {
        const msg = JSON.parse(event.data);
        if (msg.type === 'validations') {
          setValidations(msg.data || []);
        }
      } catch { /* ignore */ }
    };

    ws.onclose = () => {
      setTimeout(() => {
        if (wsRef.current === ws) wsRef.current = null;
      }, 3000);
    };

    return () => ws.close();
  }, []);

  return validations;
}
