import { useState, useEffect, useRef, useCallback } from 'react';
import type { AgentSession } from '../types/agent';

interface HitlRequestState {
  id: string;
  type: 'confirmation' | 'selection' | 'form' | 'review';
  title: string;
  description?: string;
  agent: string;
  options?: string[];
  oldValue?: string;
  newValue?: string;
  context?: Record<string, unknown>;
}

interface UseAgentStreamOptions {
  url?: string;
  agent?: string;
}

export function useAgentStream(opts: UseAgentStreamOptions = {}) {
  const defaultUrl =
    typeof window !== 'undefined'
      ? `${window.location.protocol === 'https:' ? 'wss:' : 'ws:'}//${window.location.host}/ws`
      : 'ws://localhost:8080';
  const { url = defaultUrl, agent: defaultAgent = 'DEV' } = opts;

  const [session, setSession] = useState<AgentSession | null>(null);
  const [connected, setConnected] = useState(false);
  const [bridgeConnected, setBridgeConnected] = useState(false);
  const [agentSessions, setAgentSessions] = useState<
    Array<{ id: string; agent: string; status: string; messageCount: number; updatedAt: string }>
  >([]);
  const [tools, setTools] = useState<Array<{ name: string; description: string }>>([]);
  const [hitlRequest, setHitlRequest] = useState<HitlRequestState | null>(null);
  const [historySessions, setHistorySessions] = useState<AgentSession[]>([]);
  const wsRef = useRef<WebSocket | null>(null);
  const reconnectRef = useRef<NodeJS.Timeout | null>(null);

  const send = useCallback((msg: Record<string, unknown>) => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify(msg));
    }
  }, []);

  const connect = useCallback(() => {
    try {
      const ws = new WebSocket(url);
      wsRef.current = ws;

      ws.onopen = () => {
        setConnected(true);
      };

      ws.onmessage = (event) => {
        try {
          const msg = JSON.parse(event.data);

          switch (msg.type) {
            case 'bridge_status':
              setBridgeConnected(msg.connected);
              break;

            case 'agent_session_created':
              setSession(msg.session);
              break;

            case 'agent_session':
              setSession(msg.session);
              break;

            case 'agent_sessions':
              setAgentSessions(msg.sessions);
              break;

            case 'agent_message':
              setSession((prev) => {
                if (!prev) return prev;
                const exists = prev.messages.some((m) => m.id === msg.message.id);
                if (exists) {
                  return {
                    ...prev,
                    messages: prev.messages.map((m) => (m.id === msg.message.id ? msg.message : m)),
                  };
                }
                return { ...prev, messages: [...prev.messages, msg.message] };
              });
              break;

            case 'agent_stream_done':
              setSession((prev) => {
                if (!prev) return prev;
                return {
                  ...prev,
                  messages: prev.messages.map((m) =>
                    m.id === msg.messageId ? { ...m, streaming: false } : m,
                  ),
                };
              });
              break;

            case 'agent_tools':
              setTools(msg.tools || []);
              setBridgeConnected(msg.connected);
              break;

            case 'hitl_request':
              setHitlRequest(msg.hitlRequest);
              setSession((prev) => (prev ? { ...prev, status: 'awaiting_input' } : prev));
              break;

            case 'hitl_resolved':
              setHitlRequest((prev) => (prev?.id === msg.requestId ? null : prev));
              setSession((prev) => (prev ? { ...prev, status: 'active' } : prev));
              break;

            case 'subscribed':
              break;

            case 'agent_history':
              setHistorySessions(msg.sessions || []);
              break;
          }
        } catch {
          // Ignore parse errors
        }
      };

      ws.onclose = () => {
        setConnected(false);
        reconnectRef.current = setTimeout(connect, 3000);
      };

      ws.onerror = () => {
        setConnected(false);
      };
    } catch {
      setConnected(false);
    }
  }, [url]);

  const disconnect = useCallback(() => {
    if (reconnectRef.current) clearTimeout(reconnectRef.current);
    wsRef.current?.close();
  }, []);

  const createSession = useCallback(
    (agent?: string) => {
      send({ type: 'agent', action: 'create_session', agent: agent || defaultAgent });
    },
    [send, defaultAgent],
  );

  const sendMessage = useCallback(
    (sessionId: string, message: string) => {
      send({ type: 'agent', action: 'send_message', sessionId, message });
    },
    [send],
  );

  const executeSkill = useCallback(
    (sessionId: string, skill: string, params?: Record<string, unknown>) => {
      send({ type: 'agent', action: 'execute_skill', sessionId, skill, params });
    },
    [send],
  );

  const listSessions = useCallback(() => {
    send({ type: 'agent', action: 'list_sessions' });
  }, [send]);

  const getSession = useCallback(
    (sessionId: string) => {
      send({ type: 'agent', action: 'get_session', sessionId });
    },
    [send],
  );

  const listTools = useCallback(() => {
    send({ type: 'agent', action: 'list_tools' });
  }, [send]);

  const subscribe = useCallback(
    (sessionId: string) => {
      send({ type: 'agent', action: 'subscribe', sessionId });
    },
    [send],
  );

  const listHistory = useCallback(() => {
    send({ type: 'agent', action: 'list_history' });
  }, [send]);

  const resolveHitl = useCallback(
    (
      requestId: string,
      response: { approved?: boolean; value?: string; values?: Record<string, unknown> },
    ) => {
      send({ type: 'agent', action: 'hitl_response', requestId, response });
      setHitlRequest(null);
    },
    [send],
  );

  useEffect(() => {
    connect();
    return disconnect;
  }, [connect, disconnect]);

  return {
    session,
    connected,
    bridgeConnected,
    agentSessions,
    tools,
    hitlRequest,
    historySessions,
    createSession,
    sendMessage,
    executeSkill,
    listSessions,
    getSession,
    listTools,
    subscribe,
    resolveHitl,
    listHistory,
  };
}
