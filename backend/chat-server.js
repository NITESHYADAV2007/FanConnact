const { WebSocketServer } = require('ws');
const https = require('https');

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

// Resolve a real player photo from Wikipedia (cached). Falls back to initials avatar.
const WIKI_AVATAR_CACHE = {};
function wikiAvatar(name, fallbackBg) {
  const key = (name || '').toLowerCase();
  if (WIKI_AVATAR_CACHE[key]) return WIKI_AVATAR_CACHE[key];
  const fb = 'https://ui-avatars.com/api/?name=' + encodeURIComponent(name || 'Fan') + '&background=' + (fallbackBg || '2196f3') + '&color=fff&size=64';
  WIKI_AVATAR_CACHE[key] = fb;
  const searchUrl = 'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=' + encodeURIComponent(name + ' cricketer') + '&format=json&origin=*&srlimit=1';
  https.get(searchUrl, res => {
    let body = '';
    res.on('data', d => body += d);
    res.on('end', () => {
      try {
        const data = JSON.parse(body);
        const title = data.query && data.query.search && data.query.search[0] && data.query.search[0].title;
        if (!title) return;
        https.get('https://en.wikipedia.org/w/api.php?action=query&titles=' + encodeURIComponent(title) + '&prop=pageimages&format=json&origin=*&pithumbsize=200', r2 => {
          let b2 = '';
          r2.on('data', d => b2 += d);
          r2.on('end', () => {
            try {
              const d2 = JSON.parse(b2);
              const pages = d2.query && d2.query.pages ? d2.query.pages : {};
              for (const p in pages) {
                if (pages[p].thumbnail && pages[p].thumbnail.source) {
                  WIKI_AVATAR_CACHE[key] = pages[p].thumbnail.source;
                }
              }
            } catch (e) {}
          });
        }).on('error', () => {});
      } catch (e) {}
    });
  }).on('error', () => {});
  return fb;
}

function createSystemMessage(text) {
  return {
    type: 'system',
    text,
    time: Date.now(),
    id: 'sys_' + Date.now() + '_' + Math.random().toString(36).slice(2, 6)
  };
}

function createUserMessage(user, payload) {
  const msg = {
    type: 'message',
    user: {
      name: user.name,
      img: user.img,
      id: user.id
    },
    time: Date.now(),
    likes: 0,
    id: 'msg_' + Date.now() + '_' + Math.random().toString(36).slice(2, 6)
  };
  if (payload.kind === 'image' && payload.image) {
    msg.kind = 'image';
    msg.image = String(payload.image).slice(0, 1500000); // cap ~1.5MB data URL
    if (payload.text) msg.text = String(payload.text).slice(0, 200);
  } else if (payload.kind === 'sticker' && payload.sticker) {
    msg.kind = 'sticker';
    msg.sticker = String(payload.sticker).slice(0, 8);
  } else {
    msg.kind = 'text';
    msg.text = String(payload.text || '').slice(0, 500);
  }
  msg.seenBy = []; // ids of users who have seen this message
  return msg;
}

function getOnlineCount() {
  let count = 0;
  onlineUsers.forEach(u => { if (u.alive) count++; });
  return count || onlineUsers.size;
}

function createChatServer(httpServer) {
  const wss = new WebSocketServer({ noServer: true });

  wss.on('connection', (ws, req) => {
    const matchId = new URL(req.url, 'http://localhost').searchParams.get('match') || 'default';
    ws.matchId = matchId;
    const sport = getSportFromMatchId(matchId);
    userCounter++;
    const userId = 'user_' + userCounter;
    const userColors = ['#2196f3', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#06b6d4', '#f97316'];
    const userName = 'Fan_' + Math.random().toString(36).slice(2, 6).toUpperCase();
    const userAvatar = `https://ui-avatars.com/api/?name=${userName}&background=${userColors[userCounter % userColors.length].replace('#', '')}&color=fff&size=32`;
    const user = { name: userName, img: userAvatar, id: userId, color: userColors[userCounter % userColors.length] };

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

        if (msg.type === 'identify' && msg.user) {
          // Client sends its real profile (name + photo) from Firebase
          if (msg.user.name) user.name = String(msg.user.name).slice(0, 40);
          if (msg.user.img) user.img = String(msg.user.img).slice(0, 2000);
          onlineUsers.set(ws, { name: user.name, id: userId, alive: true, matchId });
          ws.send(JSON.stringify({ type: 'identified', user }));
          return;
        }

        if (msg.type === 'ping') {
          ws.send(JSON.stringify({ type: 'pong' }));
          return;
        }

        if (msg.type === 'message' && msg.payload) {
          const message = createUserMessage(user, msg.payload);
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

        if (msg.type === 'seen' && msg.messageId) {
          const target = messageHistory.find(m => m.id === msg.messageId);
          if (target && target.type === 'message' && !target.seenBy.includes(userId)) {
            target.seenBy.push(userId);
            broadcast(wss, {
              type: 'seen_update',
              messageId: msg.messageId,
              seenBy: target.seenBy
            }, matchId);
          }
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
    if (client.readyState === client.OPEN && (client.matchId || 'default') === matchId) {
      client.send(data);
    }
  });
}

module.exports = { createChatServer, broadcast };
