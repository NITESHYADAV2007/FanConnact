/*=================================
FANCONNACT THEME ENGINE
=================================*/

const STORAGE_KEY = "fanconnact-settings";

/* Default */

const defaultSettings = {
  theme: "dark",

  compact: false,

  largeText: false,

  reduceAnimation: false,

  sports: [],

  notifications: {},

  language: "English",

  timezone: "Asia/Kolkata",

  region: "India",
};

/* Load */

let settings = JSON.parse(localStorage.getItem(STORAGE_KEY)) || defaultSettings;

/*=================================
SAVE
=================================*/

function saveSettings() {
  localStorage.setItem(
    STORAGE_KEY,

    JSON.stringify(settings),
  );
}

/*=================================
THEME
=================================*/

const themeCards = document.querySelectorAll(".theme-item");

function applyTheme(theme) {
  /* remove old */

  document.body.classList.remove(
    "theme-light",

    "theme-dark",

    "theme-stadium",

    "theme-esports",

    "theme-royal",
  );

  /* add new */

  document.body.classList.add(`theme-${theme}`);

  settings.theme = theme;

  saveSettings();

  /* active border */

  themeCards.forEach((card) => {
    card.classList.remove("active-theme");
  });

  document

    .querySelector(`[data-theme="${theme}"]`)

    .classList.add("active-theme");
}
themeCards.forEach((card) => {
  card.addEventListener(
    "click",

    () => {
      applyTheme(card.dataset.theme);
    },
  );
});

document.addEventListener("DOMContentLoaded", () => {
  applyTheme(settings.theme);

  compactToggle.checked = settings.compact;
  animationToggle.checked = settings.reduceAnimation;
  largeTextToggle.checked = settings.largeText;

  applyCompactMode();
  applyLargeText();
  applyAnimation();
});

/*=================================
APPEARANCE SETTINGS
=================================*/

const compactToggle = document.getElementById("compactMode");

const animationToggle = document.getElementById("reduceAnimation");

const largeTextToggle = document.getElementById("largeText");

/*=================================
LOAD TOGGLES
=================================*/

compactToggle.checked = settings.compact;

animationToggle.checked = settings.reduceAnimation;

largeTextToggle.checked = settings.largeText;

/*=================================
COMPACT MODE
=================================*/

function applyCompactMode() {
  if (settings.compact) {
    document.body.classList.add("compact-mode");
  } else {
    document.body.classList.remove("compact-mode");
  }
}

compactToggle.addEventListener(
  "change",

  function () {
    settings.compact = this.checked;

    saveSettings();

    applyCompactMode();
  },
);

/*=================================
LARGE TEXT
=================================*/

function applyLargeText() {
  if (settings.largeText) {
    document.body.classList.add("large-text");
  } else {
    document.body.classList.remove("large-text");
  }
}

largeTextToggle.addEventListener(
  "change",

  function () {
    settings.largeText = this.checked;

    saveSettings();

    applyLargeText();
  },
);

/*=================================
REDUCE ANIMATION
=================================*/

function applyAnimation() {
  if (settings.reduceAnimation) {
    document.body.classList.add("reduce-animation");
  } else {
    document.body.classList.remove("reduce-animation");
  }
}

animationToggle.addEventListener(
  "change",

  function () {
    settings.reduceAnimation = this.checked;

    saveSettings();

    applyAnimation();
  },
);
