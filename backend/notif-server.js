const { WebSocketServer } = require('ws');

let notifications = [];
const NOTIF_HISTORY_LIMIT = 50;
let notifClients = new Set();

function createNotificationServer(httpServer) {
  const wss = new WebSocketServer({ noServer: true });

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

// No demo/fake notifications are pushed automatically — only real match events
// (triggered via pushNotification from the backend) are sent to clients.

module.exports = { createNotificationServer, pushNotification, markAsRead, getUnreadCount };
