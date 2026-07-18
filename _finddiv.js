const fs = require('fs');
const lines = fs.readFileSync('leaderboard.html', 'utf8').split('\n');
const findLine = (s) => lines.findIndex(l => l.includes(s));
const start = findLine('<section class="space-y-6 min-w-0">');
const end = findLine('three.min.js"></script>');
let balance = 0;
for (let i = start; i <= end; i++) {
  const o = (lines[i].match(/<div\b/g) || []).length;
  const c = (lines[i].match(/<\/div>/g) || []).length;
  balance += (o - c);
  if (balance < 0) {
    console.log('FIRST NEGATIVE at line', i + 1, 'balance', balance);
    console.log('LINE:', JSON.stringify(lines[i]));
    break;
  }
}
// Also print balance at a few key lines
console.log('--- balance trace (every line where balance changes) ---');
balance = 0;
for (let i = start; i <= end; i++) {
  const o = (lines[i].match(/<div\b/g) || []).length;
  const c = (lines[i].match(/<\/div>/g) || []).length;
  balance += (o - c);
  if (o !== 0 || c !== 0) {
    console.log((i+1).toString().padStart(4), 'o:'+o, 'c:'+c, 'bal:'+balance, '|', lines[i].trim().slice(0,70));
  }
}
