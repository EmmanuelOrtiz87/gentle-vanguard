import { useEffect, useRef, useState, useCallback } from 'react';

type Listener = (msg: any) => void;

let sharedWs: WebSocket | null = null;
const listeners = new Set<Listener>();
let refCount = 0;
let reconnectTimer: ReturnType<typeof setTimeout> | null = null;

function connect() {
  if (
    sharedWs &&
    (sharedWs.readyState === WebSocket.OPEN || sharedWs.readyState === WebSocket.CONNECTING)
  )
    return;
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  sharedWs = new WebSocket(`${protocol}//${window.location.host}/ws`);
  sharedWs.onmessage = (event) => {
    try {
      const msg = JSON.parse(event.data);
      listeners.forEach((fn) => fn(msg));
    } catch {
      /* ignore */
    }
  };
  sharedWs.onclose = () => {
    if (refCount > 0) {
      reconnectTimer = setTimeout(connect, 3000);
    }
  };
}

function disconnect() {
  if (reconnectTimer) {
    clearTimeout(reconnectTimer);
    reconnectTimer = null;
  }
  if (sharedWs) {
    sharedWs.onopen = null;
    sharedWs.onclose = null;
    sharedWs.onerror = null;
    sharedWs.onmessage = null;
    if (sharedWs.readyState === WebSocket.OPEN) {
      sharedWs.close();
    }
    sharedWs = null;
  }
}

export function useSharedWs(
  listener: (msg: Record<string, unknown>) => void,
  deps: unknown[] = [],
) {
  const [connected, setConnected] = useState(false);
  const listenerRef = useRef(listener);
  listenerRef.current = listener;

  useEffect(() => {
    const wrapper = (msg: Record<string, unknown>) => listenerRef.current(msg);
    listeners.add(wrapper);
    refCount++;
    if (!sharedWs || sharedWs.readyState === WebSocket.CLOSED) {
      connect();
    }
    if (sharedWs?.readyState === WebSocket.OPEN) setConnected(true);
    return () => {
      listeners.delete(wrapper);
      refCount--;
      if (refCount <= 0) disconnect();
    };
  }, deps);

  const send = useCallback((data: Record<string, unknown>) => {
    if (sharedWs?.readyState === WebSocket.OPEN) {
      sharedWs.send(JSON.stringify(data));
    }
  }, []);

  return { connected, send };
}
