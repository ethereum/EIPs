import DefaultTheme from 'vitepress/theme';
import Layout from './Layout.vue';

export default {
  ...DefaultTheme,
  Layout,
  enhanceApp({ app, router, siteData }) {
    DefaultTheme.enhanceApp({ app, router, siteData });
  }
};
