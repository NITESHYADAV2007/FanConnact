// Real-time Live Chat for Match Center
// Connects to backend WS (/ws/chat). Falls back to a local in-page mode if the
// server is unavailable so the UI still works for demos.
(function () {
  'use strict';

  const WS_URL = 'ws://localhost:3001/ws/chat';
  const messagesEl = document.getElementById('chat-messages');
  const inputEl = document.getElementById('chat-input');
  const sendBtn = document.getElementById('chat-send');
  const statusEl = document.getElementById('chat-status');
  const onlineEl = document.getElementById('chat-online-count');
  const typingEl = document.getElementById('chat-typing');
  const stickerBtn = document.getElementById('chat-sticker-btn');
  const stickerBox = document.getElementById('chat-stickers');
  const imgBtn = document.getElementById('chat-img-btn');
  const imgInput = document.getElementById('chat-img-input');

  if (!messagesEl) return; // panel not present

  // Map of message id -> DOM node, for live "seen" updates
  const renderedMessages = {};

  // ---- Identity (from Firebase profile if available, else generated) ----
  // Read live from the header elements so the real name/photo (set by script.js
  // after Firebase auth resolves) are used even if chat loads first.
  let me = { name: 'You', img: '', id: 'me_' + Math.random().toString(36).slice(2, 7) };
  function refreshIdentity() {
    try {
      // Prefer the real database profile exposed by script.js (full name, no @)
      if (window.currentUserProfile && window.currentUserProfile.name) {
        me.name = window.currentUserProfile.name;
        if (window.currentUserProfile.photoURL) me.img = window.currentUserProfile.photoURL;
        return;
      }
      const nameEl = document.getElementById('user-name-display');
      const imgEl = document.getElementById('user-profile-img');
      if (nameEl && nameEl.textContent && nameEl.textContent.trim()) {
        me.name = nameEl.textContent.trim().replace(/^@/, '');
      }
      if (imgEl && imgEl.src && !imgEl.src.includes('ui-avatars')) me.img = imgEl.src;
    } catch (e) {}
    if (!me.img) {
      me.img = 'https://ui-avatars.com/api/?name=' + encodeURIComponent(me.name) + '&background=2196f3&color=fff&size=64';
    }
  }
  refreshIdentity();
  // Re-check after Firebase auth populates the header (script.js runs async)
  setTimeout(refreshIdentity, 800);
  setTimeout(refreshIdentity, 2500);

  // ---- Stickers ----
  const STICKERS = ['🏏', '🔥', '💥', '👏', '💪', '⭐', '🎯', '🏆', '😂', '😮', '😍', '🥳', '👍', '🤯', '🙌', '❤️'];
  STICKERS.forEach(s => {
    const b = document.createElement('button');
    b.className = 'text-2xl hover:scale-110 transition';
    b.textContent = s;
    b.addEventListener('click', () => sendPayload({ kind: 'sticker', sticker: s }));
    stickerBox.appendChild(b);
  });
  stickerBtn.addEventListener('click', () => stickerBox.classList.toggle('hidden'));

  // ---- Helpers ----
  function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  }
  function timeStr(t) {
    const d = new Date(t || Date.now());
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  }
  function avatarFor(user) {
    return user && user.img ? user.img : 'https://ui-avatars.com/api/?name=' + encodeURIComponent((user && user.name) || 'Fan') + '&background=2196f3&color=fff&size=64';
  }

  function renderMessage(m) {
    const wrap = document.createElement('div');
    wrap.className = 'flex gap-3 items-start';
    const isMe = (m.user && m.user.id === me.id) || m.mine;
    if (m.id) renderedMessages[m.id] = wrap;
    const av = document.createElement('img');
    av.className = 'w-9 h-9 rounded-full border border-gray-200 dark:border-white/10 shrink-0';
    av.src = avatarFor(m.user);
    av.alt = (m.user && m.user.name) || 'Fan';
    av.onerror = function () { this.src = 'https://ui-avatars.com/api/?name=' + encodeURIComponent((m.user && m.user.name) || 'Fan') + '&background=2196f3&color=fff&size=64'; };

    const body = document.createElement('div');
    body.className = 'min-w-0 flex-1';

    const meta = document.createElement('div');
    meta.className = 'flex items-center gap-2 mb-0.5';
    meta.innerHTML = '<span class="text-xs font-semibold text-gray-800 dark:text-white">' + escapeHtml((m.user && m.user.name) || 'Fan') + '</span><span class="text-[10px] text-gray-400">' + timeStr(m.time) + '</span>';
    body.appendChild(meta);

    const content = document.createElement('div');
    if (m.kind === 'image') {
      const img = document.createElement('img');
      img.src = m.image;
      img.className = 'max-w-[220px] rounded-lg border border-gray-200 dark:border-white/10 cursor-pointer';
      img.addEventListener('click', () => window.open(m.image, '_blank'));
      content.appendChild(img);
      if (m.text) {
        const cap = document.createElement('p');
        cap.className = 'text-sm text-gray-700 dark:text-gray-200 mt-1';
        cap.textContent = m.text;
        content.appendChild(cap);
      }
    } else if (m.kind === 'sticker') {
      const st = document.createElement('div');
      st.className = 'text-5xl leading-none';
      st.textContent = m.sticker;
      content.appendChild(st);
    } else {
      const p = document.createElement('p');
      p.className = 'text-sm text-gray-700 dark:text-gray-200 break-words';
      p.textContent = m.text || '';
      content.appendChild(p);
    }
    body.appendChild(content);

    // Seen indicator (only meaningful for own messages)
    const seenEl = document.createElement('div');
    seenEl.className = 'text-[10px] text-gray-400 mt-0.5 seen-line';
    seenEl.dataset.msgId = m.id || '';
    if (isMe && m.seenBy && m.seenBy.length) {
      seenEl.textContent = '✓✓ Seen by ' + m.seenBy.length;
    } else if (isMe) {
      seenEl.textContent = '✓ Sent';
    }
    body.appendChild(seenEl);

    if (isMe) { wrap.classList.add('flex-row-reverse'); body.classList.add('text-right'); meta.classList.add('justify-end'); }
    wrap.appendChild(av);
    wrap.appendChild(body);
    messagesEl.appendChild(wrap);
    messagesEl.scrollTop = messagesEl.scrollHeight;
  }

  function renderSystem(text) {
    const d = document.createElement('div');
    d.className = 'text-center text-[11px] text-gray-400 my-1';
    d.textContent = text;
    messagesEl.appendChild(d);
    messagesEl.scrollTop = messagesEl.scrollHeight;
  }

  // ---- Sending ----
  function sendPayload(payload) {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({ type: 'message', payload }));
    } else if (fallback) {
      const m = Object.assign({ user: me, time: Date.now(), mine: true, likes: 0 }, payloadToMessage(payload));
      renderMessage(m);
    }
  }
  function payloadToMessage(p) {
    if (p.kind === 'image') return { kind: 'image', image: p.image, text: p.text };
    if (p.kind === 'sticker') return { kind: 'sticker', sticker: p.sticker };
    return { kind: 'text', text: p.text };
  }
  function sendText() {
    const v = inputEl.value.trim();
    if (!v) return;
    sendPayload({ kind: 'text', text: v });
    inputEl.value = '';
  }
  sendBtn.addEventListener('click', sendText);
  inputEl.addEventListener('keydown', e => { if (e.key === 'Enter') sendText(); });

  imgBtn.addEventListener('click', () => imgInput.click());
  imgInput.addEventListener('change', () => {
    const file = imgInput.files && imgInput.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => sendPayload({ kind: 'image', image: reader.result, text: '' });
    reader.readAsDataURL(file);
    imgInput.value = '';
  });

  // ---- WebSocket ----
  let ws = null;
  let fallback = false;
  let retry = 0;
  const MAX_RETRY = 4;

  function setStatus(text, cls) {
    if (!statusEl) return;
    statusEl.textContent = text;
    statusEl.className = 'text-[10px] px-2 py-0.5 rounded-full ' + (cls || 'bg-gray-200 dark:bg-white/10 text-gray-500 dark:text-gray-400');
  }

  function connect() {
    try {
      ws = new WebSocket(WS_URL + '?match=cricket-eng-ind-1st-odi-2026');
      ws.onopen = () => { retry = 0; fallback = false; setStatus('live', 'bg-emerald-500/20 text-emerald-400'); refreshIdentity(); ws.send(JSON.stringify({ type: 'identify', user: { name: me.name, img: me.img } })); };
      ws.onmessage = ev => {
        let m; try { m = JSON.parse(ev.data); } catch (e) { return; }
        if (m.type === 'connected') {
          (m.recentMessages || []).forEach(renderMessage);
          if (m.onlineCount != null && onlineEl) onlineEl.textContent = m.onlineCount;
        } else if (m.type === 'identified') {
          if (m.user && m.user.name) me.name = m.user.name;
          if (m.user && m.user.img) me.img = m.user.img;
        } else if (m.type === 'message') {
          renderMessage(m);
          // Mark others' messages as seen (until match is live)
          if (m.id && !(m.user && m.user.id === me.id) && ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({ type: 'seen', messageId: m.id }));
          }
        } else if (m.type === 'seen_update') {
          const node = renderedMessages[m.messageId];
          if (node) {
            const line = node.querySelector('.seen-line');
            if (line) line.textContent = '✓✓ Seen by ' + (m.seenBy ? m.seenBy.length : 1);
          }
        } else if (m.type === 'system') {
          renderSystem(m.text);
        } else if (m.type === 'online_count') {
          if (onlineEl) onlineEl.textContent = m.onlineCount;
        } else if (m.type === 'typing') {
          if (m.isTyping && m.userName) {
            typingEl.textContent = m.userName + ' is typing…';
            clearTimeout(typingEl._t);
            typingEl._t = setTimeout(() => typingEl.textContent = '', 2000);
          }
        }
      };
      ws.onclose = () => { if (retry < MAX_RETRY) { retry++; setTimeout(connect, 1500); } else enableFallback(); };
      ws.onerror = () => { try { ws.close(); } catch (e) {} };
    } catch (e) { enableFallback(); }
  }

  function enableFallback() {
    fallback = true;
    setStatus('offline (local)', 'bg-amber-500/20 text-amber-400');
    renderSystem('Chat server offline — showing local demo mode. Start the backend (cd backend && npm start) for real-time chat.');
  }

  connect();
})();
