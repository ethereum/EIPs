import DefaultTheme from 'vitepress/theme';
import Layout from './Layout.vue';
import Listing from './Listing.vue';

export default {
  ...DefaultTheme,
  Layout,
  enhanceApp({ app, router, siteData }) {
    DefaultTheme.enhanceApp({ app, router, siteData });

    app.component('Listing', Listing);
  }
};
