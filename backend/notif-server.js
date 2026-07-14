const { WebSocketServer } = require('ws');

let notifications = [];
const NOTIF_HISTORY_LIMIT = 50;
let notifClients = new Set();

function createNotificationServer(httpServer) {
  const wss = new WebSocketServer({ server: httpServer, path: '/ws/notifications' });

  wss.on('connection', (ws) => {
    notifClients.add(ws);

    ws.send(JSON.stringify({
      type: 'notif_history',
      notifications: notifications.slice(-20)
    }));

    ws.on('close', () => {
      notifClients.delete(ws);
    });

    ws.on('error', () => {
      notifClients.delete(ws);
    });
  });

  return wss;
}

function pushNotification(notif) {
  const entry = {
    id: 'notif_' + Date.now() + '_' + Math.random().toString(36).slice(2, 6),
    type: notif.type || 'match',
    sport: notif.sport || 'general',
    title: notif.title || '',
    message: notif.message || '',
    time: Date.now(),
    icon: notif.icon || '🔔',
    read: false
  };
  notifications.push(entry);
  if (notifications.length > NOTIF_HISTORY_LIMIT) {
    notifications = notifications.slice(-NOTIF_HISTORY_LIMIT);
  }
  const data = JSON.stringify({ type: 'new_notification', notification: entry });
  notifClients.forEach(client => {
    if (client.readyState === client.OPEN) {
      client.send(data);
    }
  });
}

function markAsRead(notifId) {
  const n = notifications.find(n => n.id === notifId);
  if (n) n.read = true;
}

function getUnreadCount() {
  return notifications.filter(n => !n.read).length;
}

const SAMPLE_NOTIFS = [
  { type: 'match', sport: 'cricket', title: 'Match Starting Soon', message: 'MI vs CSK starts in 15 mins', icon: '🏏' },
  { type: 'match', sport: 'football', title: 'Goal!', message: 'Messi scores in the 72nd minute!', icon: '⚽' },
  { type: 'match', sport: 'basketball', title: 'Score Update', message: 'LAL 98 - BOS 94 (Q4 2:00)', icon: '🏀' },
  { type: 'system', sport: 'general', title: 'Welcome', message: 'Notifications are now live!', icon: '🎉' },
];

// Push sample notifications periodically
if (typeof setInterval !== 'undefined') {
  let idx = 0;
  setInterval(() => {
    if (notifClients.size > 0) {
      pushNotification(SAMPLE_NOTIFS[idx % SAMPLE_NOTIFS.length]);
      idx++;
    }
  }, 60000);
}

module.exports = { createNotificationServer, pushNotification, markAsRead, getUnreadCount };
