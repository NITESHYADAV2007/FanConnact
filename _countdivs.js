const fs = require('fs');
const path = 'leaderboard.html';
const lines = fs.readFileSync(path, 'utf8').split('\n');
const findLine = (s) => lines.findIndex(l => l.includes(s));
const secOpen = findLine('<section class="space-y-6 min-w-0">');
const threeScript = findLine('three.min.js"></script>');
let opens = 0, closes = 0;
for (let i = secOpen; i <= threeScript; i++) {
  opens += (lines[i].match(/<div\b/g) || []).length;
  closes += (lines[i].match(/<\/div>/g) || []).length;
}
console.log('secOpen(line):', secOpen + 1, 'threeScript(line):', threeScript + 1, 'opens:', opens, 'closes:', closes, 'diff:', opens - closes);
