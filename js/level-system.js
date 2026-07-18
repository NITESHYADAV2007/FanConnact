// FanConnect leveling system for fans.
//
// XP required to advance FROM level L to level L+1 (the "step" cost):
//   L1  -> L2   = 50 XP
//   each level up to L10 adds +20 more than the previous step
//     (L2->L3 = 70, L3->L4 = 90, ... L9->L10 = 210)
//   after L10 the step grows by +25 per level
//     (L10->L11 = 235, L11->L12 = 260, ... L19->L20 = 460)
//   after L20 the step grows by +30 per level
//     (L20->L21 = 490, L21->L22 = 520, ...)
//
// Level 1 starts at 0 XP. A fan's level is always derived from total XP.
(function (global) {
  "use strict";

  // XP needed to go from level L to level L+1.
  function reqForStep(L) {
    if (L <= 9) return 50 + 20 * (L - 1); // L = 1..9
    if (L <= 19) return 235 + 25 * (L - 10); // L = 10..19
    return 490 + 30 * (L - 20); // L >= 20
  }

  // Cumulative XP required to BE at `level` (level 1 = 0 XP).
  var _cumCache = { 1: 0 };
  function cumForLevel(level) {
    level = Math.max(1, Math.floor(level) || 1);
    if (_cumCache[level] != null) return _cumCache[level];
    var total = cumForLevel(level - 1) + reqForStep(level - 1);
    _cumCache[level] = total;
    return total;
  }

  // Highest level a fan has reached given total XP.
  function levelFromXP(xp) {
    xp = Math.max(0, Math.floor(xp) || 0);
    var lvl = 1;
    while (cumForLevel(lvl + 1) <= xp) lvl++;
    return lvl;
  }

  // XP remaining until the next level.
  function xpToNextLevel(xp) {
    xp = Math.max(0, Math.floor(xp) || 0);
    var lvl = levelFromXP(xp);
    return cumForLevel(lvl + 1) - xp;
  }

  // Total XP needed to reach the next level (for progress denominators).
  function nextLevelXP(xp) {
    xp = Math.max(0, Math.floor(xp) || 0);
    var lvl = levelFromXP(xp);
    return cumForLevel(lvl + 1);
  }

  // Progress toward next level as a 0..1 fraction.
  function xpProgress(xp) {
    xp = Math.max(0, Math.floor(xp) || 0);
    var lvl = levelFromXP(xp);
    var base = cumForLevel(lvl);
    var next = cumForLevel(lvl + 1);
    if (next === base) return 0;
    return (xp - base) / (next - base);
  }

  global.LevelSystem = {
    reqForStep: reqForStep,
    cumForLevel: cumForLevel,
    levelFromXP: levelFromXP,
    xpToNextLevel: xpToNextLevel,
    nextLevelXP: nextLevelXP,
    xpProgress: xpProgress,
  };
})(window);
