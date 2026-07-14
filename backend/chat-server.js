const { WebSocketServer } = require('ws');

const CHAT_HISTORY_LIMIT = 100;
let messageHistory = [];
let onlineUsers = new Map();
let userCounter = 0;

const SPORT_EMOJIS = {
  cricket: ['🏏', '🏆', '🔥', '💥', '🎯', '👏', '💪', '⭐'],
  football: ['⚽', '🥅', '🔥', '💪', '👏', '🎯', '⭐', '🏆'],
  basketball: ['🏀', '🔥', '💪', '👏', '🎯', '⭐', '🏆', '💥'],
  tennis: ['🎾', '🔥', '💪', '👏', '🎯', '⭐', '🏆', '💥'],
};

function getRandomEmojis(sport) {
  const emojis = SPORT_EMOJIS[sport] || SPORT_EMOJIS.cricket;
  return emojis[Math.floor(Math.random() * emojis.length)];
}

function getSportFromMatchId(matchId) {
  if (!matchId) return 'cricket';
  const sportPrefixes = ['cricket', 'football', 'basketball', 'tennis', 'baseball', 'hockey', 'vollyeball', 'kabbaddi', 'e-sports', 'tabletennis'];
  for (const prefix of sportPrefixes) {
    if (matchId.startsWith(prefix)) return prefix;
  }
  return 'cricket';
}

function createSystemMessage(text) {
  return {
    type: 'system',
    text,
    time: Date.now(),
    id: 'sys_' + Date.now() + '_' + Math.random().toString(36).slice(2, 6)
  };
}

function createUserMessage(user, text) {
  return {
    type: 'message',
    user: {
      name: user.name,
      img: user.img,
      id: user.id
    },
    text,
    time: Date.now(),
    likes: 0,
    id: 'msg_' + Date.now() + '_' + Math.random().toString(36).slice(2, 6)
  };
}

function getOnlineCount() {
  let count = 0;
  onlineUsers.forEach(u => { if (u.alive) count++; });
  return count || onlineUsers.size;
}

function createChatServer(httpServer) {
  const wss = new WebSocketServer({ server: httpServer, path: '/ws/chat' });

  wss.on('connection', (ws, req) => {
    const matchId = new URL(req.url, 'http://localhost').searchParams.get('match') || 'default';
    const sport = getSportFromMatchId(matchId);
    userCounter++;
    const userId = 'user_' + userCounter;
    const userColors = ['#2196f3', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#06b6d4', '#f97316'];
    const userName = 'Fan_' + Math.random().toString(36).slice(2, 6).toUpperCase();
    const userAvatar = `https://ui-avatars.com/api/?name=${userName}&background=${userColors[userCounter % userColors.length].replace('#', '')}&color=fff&size=32`;
    const user = { name: userName, img: userAvatar, id: userId };

    onlineUsers.set(ws, { name: userName, id: userId, alive: true, matchId });

    ws.send(JSON.stringify({
      type: 'connected',
      user,
      onlineCount: getOnlineCount(),
      recentMessages: messageHistory.slice(-30)
    }));

    const welcomeMsg = createSystemMessage(`👋 ${userName} joined the chat!`);
    broadcast(wss, welcomeMsg, matchId);

    broadcast(wss, {
      type: 'online_count',
      onlineCount: getOnlineCount()
    }, matchId);

    ws.on('message', (data) => {
      try {
        const msg = JSON.parse(data.toString());

        if (msg.type === 'ping') {
          ws.send(JSON.stringify({ type: 'pong' }));
          return;
        }

        if (msg.type === 'message' && msg.text && msg.text.trim()) {
          const text = msg.text.trim().slice(0, 500);
          const message = createUserMessage(user, text);
          messageHistory.push(message);
          if (messageHistory.length > CHAT_HISTORY_LIMIT) {
            messageHistory = messageHistory.slice(-CHAT_HISTORY_LIMIT);
          }
          broadcast(wss, message, matchId);
        }

        if (msg.type === 'like' && msg.messageId) {
          const target = messageHistory.find(m => m.id === msg.messageId);
          if (target && target.type === 'message') {
            target.likes = (target.likes || 0) + 1;
            broadcast(wss, {
              type: 'like_update',
              messageId: msg.messageId,
              likes: target.likes
            }, matchId);
          }
        }

        if (msg.type === 'typing') {
          broadcast(wss, {
            type: 'typing',
            userId: userId,
            userName: userName,
            isTyping: msg.isTyping
          }, matchId);
        }
      } catch (e) {
        // ignore invalid messages
      }
    });

    ws.on('close', () => {
      onlineUsers.delete(ws);
      const leaveMsg = createSystemMessage(`🚶 ${userName} left the chat`);
      broadcast(wss, leaveMsg, matchId);
      broadcast(wss, {
        type: 'online_count',
        onlineCount: getOnlineCount()
      }, matchId);
    });

    ws.on('error', () => {
      onlineUsers.delete(ws);
    });
  });

  // Heartbeat every 30s to detect stale connections
  const heartbeat = setInterval(() => {
    wss.clients.forEach(ws => {
      if (ws.readyState === ws.OPEN) {
        ws.send(JSON.stringify({ type: 'ping' }));
      }
    });
  }, 30000);

  wss.on('close', () => clearInterval(heartbeat));

  return wss;
}

function broadcast(wss, message, matchId) {
  const data = JSON.stringify(message);
  wss.clients.forEach(client => {
    if (client.readyState === client.OPEN) {
      const clientMatchId = new URL(client.url || '', 'http://localhost').searchParams.get('match') || 'default';
      if (clientMatchId === matchId) {
        client.send(data);
      }
    }
  });
}

module.exports = { createChatServer, broadcast };
