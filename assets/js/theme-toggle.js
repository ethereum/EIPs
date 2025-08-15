(function () {
  "use strict";

  const THEME_KEY = "eips-theme-preference";
  const THEME_AUTO = "auto";
  const THEME_LIGHT = "light";
  const THEME_DARK = "dark";

  class ThemeManager {
    constructor() {
      this.toggleBtn = null;
      this.lightIcon = null;
      this.darkIcon = null;
      this.currentTheme = this.getStoredTheme();
      this.systemPrefersDark = window.matchMedia(
        "(prefers-color-scheme: dark)"
      );

      this.init();
    }

    init() {
      this.bindElements();
      this.bindEvents();
      this.syncWithCurrentTheme();
      this.updateUI();
      this.enableTransitions();
    }

    enableTransitions() {
      document.body.classList.add("loaded");
    }

    syncWithCurrentTheme() {
      const currentDataTheme =
        document.documentElement.getAttribute("data-theme");
      if (currentDataTheme && currentDataTheme !== this.getEffectiveTheme()) {
        if (
          currentDataTheme === "dark" &&
          this.currentTheme === THEME_AUTO &&
          !this.systemPrefersDark.matches
        ) {
          this.currentTheme = THEME_DARK;
        } else if (
          currentDataTheme === "light" &&
          this.currentTheme === THEME_AUTO &&
          this.systemPrefersDark.matches
        ) {
          this.currentTheme = THEME_LIGHT;
        }
      }
    }

    bindElements() {
      this.toggleBtn = document.getElementById("theme-toggle");
      this.lightIcon = document.getElementById("theme-icon-light");
      this.darkIcon = document.getElementById("theme-icon-dark");

      this.toggleBtnMobile = document.getElementById("theme-toggle-mobile");
      this.lightIconMobile = document.getElementById("theme-icon-light-mobile");
      this.darkIconMobile = document.getElementById("theme-icon-dark-mobile");

      if (!this.toggleBtn && !this.toggleBtnMobile) {
        console.warn("Theme toggle buttons not found");
        return;
      }
    }

    bindEvents() {
      if (this.toggleBtn) {
        this.toggleBtn.addEventListener("click", () => this.toggleTheme());

        this.toggleBtn.addEventListener("keydown", (e) => {
          if (e.key === "Enter" || e.key === " ") {
            e.preventDefault();
            this.toggleTheme();
          }
        });
      }

      if (this.toggleBtnMobile) {
        this.toggleBtnMobile.addEventListener("click", () =>
          this.toggleTheme()
        );

        this.toggleBtnMobile.addEventListener("keydown", (e) => {
          if (e.key === "Enter" || e.key === " ") {
            e.preventDefault();
            this.toggleTheme();
          }
        });
      }

      this.systemPrefersDark.addEventListener("change", () => {
        if (this.currentTheme === THEME_AUTO) {
          this.updateUI();
          this.applySystemTheme();
        }
      });
    }

    getStoredTheme() {
      const stored = localStorage.getItem(THEME_KEY);
      if (stored && [THEME_AUTO, THEME_LIGHT, THEME_DARK].includes(stored)) {
        return stored;
      }
      return THEME_AUTO;
    }

    setStoredTheme(theme) {
      localStorage.setItem(THEME_KEY, theme);
      this.currentTheme = theme;
    }

    getEffectiveTheme() {
      if (this.currentTheme === THEME_AUTO) {
        return this.systemPrefersDark.matches ? THEME_DARK : THEME_LIGHT;
      }
      return this.currentTheme;
    }

    applyTheme(theme) {
      const effectiveTheme =
        theme === THEME_AUTO
          ? this.systemPrefersDark.matches
            ? THEME_DARK
            : THEME_LIGHT
          : theme;

      document.documentElement.setAttribute("data-theme", effectiveTheme);

      this.updateThemeColor(effectiveTheme);
    }

    applySystemTheme() {
      if (this.currentTheme === THEME_AUTO) {
        const effectiveTheme = this.systemPrefersDark.matches
          ? THEME_DARK
          : THEME_LIGHT;
        document.documentElement.setAttribute("data-theme", effectiveTheme);
        this.updateThemeColor(effectiveTheme);
      }
    }

    updateThemeColor(theme) {
      let metaThemeColor = document.querySelector('meta[name="theme-color"]');
      if (!metaThemeColor) {
        metaThemeColor = document.createElement("meta");
        metaThemeColor.name = "theme-color";
        document.getElementsByTagName("head")[0].appendChild(metaThemeColor);
      }

      metaThemeColor.content = theme === THEME_DARK ? "#212529" : "#ffffff";
    }

    updateUI() {
      const effectiveTheme = this.getEffectiveTheme();
      const isDark = effectiveTheme === THEME_DARK;
      const label = isDark ? "Switch to light mode" : "Switch to dark mode";

      if (this.toggleBtn && this.lightIcon && this.darkIcon) {
        this.lightIcon.style.display = isDark ? "none" : "block";
        this.darkIcon.style.display = isDark ? "block" : "none";
        this.toggleBtn.setAttribute("aria-label", label);
        this.toggleBtn.setAttribute("title", label);
        this.toggleBtn.classList.toggle("theme-dark", isDark);
      }

      if (this.toggleBtnMobile && this.lightIconMobile && this.darkIconMobile) {
        this.lightIconMobile.style.display = isDark ? "none" : "block";
        this.darkIconMobile.style.display = isDark ? "block" : "none";
        this.toggleBtnMobile.setAttribute("aria-label", label);
        this.toggleBtnMobile.setAttribute("title", label);
        this.toggleBtnMobile.classList.toggle("theme-dark", isDark);
      }
    }

    toggleTheme() {
      let nextTheme;

      switch (this.currentTheme) {
        case THEME_AUTO:
          nextTheme = this.systemPrefersDark.matches ? THEME_LIGHT : THEME_DARK;
          break;
        case THEME_LIGHT:
          nextTheme = THEME_DARK;
          break;
        case THEME_DARK:
          nextTheme = THEME_LIGHT;
          break;
        default:
          nextTheme = THEME_AUTO;
      }

      this.setStoredTheme(nextTheme);
      this.applyTheme(nextTheme);
      this.updateUI();

      this.announceThemeChange(nextTheme);
    }

    announceThemeChange(theme) {
      const effectiveTheme =
        theme === THEME_AUTO
          ? this.systemPrefersDark.matches
            ? "dark (auto)"
            : "light (auto)"
          : theme;

      const announcement = `Theme switched to ${effectiveTheme} mode`;

      const announcer = document.createElement("div");
      announcer.setAttribute("aria-live", "polite");
      announcer.setAttribute("aria-atomic", "true");
      announcer.style.position = "absolute";
      announcer.style.left = "-10000px";
      announcer.style.width = "1px";
      announcer.style.height = "1px";
      announcer.style.overflow = "hidden";

      document.body.appendChild(announcer);
      announcer.textContent = announcement;

      setTimeout(() => {
        document.body.removeChild(announcer);
      }, 1000);
    }

    getThemeInfo() {
      return {
        stored: this.currentTheme,
        effective: this.getEffectiveTheme(),
        systemPreference: this.systemPrefersDark.matches
          ? THEME_DARK
          : THEME_LIGHT,
      };
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => {
      window.eipsThemeManager = new ThemeManager();
    });
  } else {
    window.eipsThemeManager = new ThemeManager();
  }
})();
