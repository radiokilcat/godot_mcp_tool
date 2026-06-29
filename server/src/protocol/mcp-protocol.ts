/**
 * MCP Protocol Handler
 * Handles serialization, deserialization, and protocol logic
 */

export interface MCPMessage {
  type:
    | "request"
    | "response"
    | "error"
    | "ping"
    | "pong"
    | "notification";
  data: Record<string, unknown>;
}

export interface MCPRequest {
  id: string;
  method: string;
  params?: Record<string, unknown>;
}

export interface MCPResponse {
  id: string;
  result: unknown;
}

export interface MCPError {
  id: string;
  code: number;
  message: string;
  data?: Record<string, unknown>;
}

/**
 * Serialize a message to JSON
 */
export function serializeMessage(message: MCPMessage): string {
  return JSON.stringify(message);
}

/**
 * Deserialize a message from JSON
 */
export function deserializeMessage(json: string): MCPMessage | null {
  try {
    const parsed = JSON.parse(json);
    if (!parsed.type || !parsed.data) {
      return null;
    }
    return parsed as MCPMessage;
  } catch {
    return null;
  }
}

/**
 * Create a request message
 */
export function createRequest(
  id: string,
  method: string,
  params: Record<string, unknown> = {}
): MCPMessage {
  return {
    type: "request",
    data: {
      id,
      method,
      params,
    },
  };
}

/**
 * Create a response message
 */
export function createResponse(id: string, result: unknown): MCPMessage {
  return {
    type: "response",
    data: {
      id,
      result,
    },
  };
}

/**
 * Create an error response message
 */
export function createError(
  id: string,
  code: number,
  message: string,
  data?: Record<string, unknown>
): MCPMessage {
  return {
    type: "error",
    data: {
      id,
      code,
      message,
      ...(data && { data }),
    },
  };
}

/**
 * Create a ping message
 */
export function createPing(id: string = ""): MCPMessage {
  return {
    type: "ping",
    data: {
      id: id || String(Math.random()),
    },
  };
}

/**
 * Create a pong message
 */
export function createPong(id: string): MCPMessage {
  return {
    type: "pong",
    data: { id },
  };
}

/**
 * Create a notification message
 */
export function createNotification(
  method: string,
  params: Record<string, unknown> = {}
): MCPMessage {
  return {
    type: "notification",
    data: {
      method,
      params,
    },
  };
}

/**
 * Extract request from message
 */
export function extractRequest(message: MCPMessage): MCPRequest | null {
  if (message.type !== "request") {
    return null;
  }
  const data = message.data as Record<string, unknown>;
  return {
    id: String(data.id),
    method: String(data.method),
    params: (data.params as Record<string, unknown>) || {},
  };
}

/**
 * Extract response from message
 */
export function extractResponse(message: MCPMessage): MCPResponse | null {
  if (message.type !== "response") {
    return null;
  }
  const data = message.data as Record<string, unknown>;
  return {
    id: String(data.id),
    result: data.result,
  };
}

/**
 * Extract error from message
 */
export function extractError(message: MCPMessage): MCPError | null {
  if (message.type !== "error") {
    return null;
  }
  const data = message.data as Record<string, unknown>;
  return {
    id: String(data.id),
    code: Number(data.code),
    message: String(data.message),
    data: (data.data as Record<string, unknown>) || undefined,
  };
}
