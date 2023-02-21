import DefaultTheme from 'vitepress/theme';

import { VPTeamMembers } from 'vitepress/theme'

import Layout from './components/Layout.vue';
import EipsListing from './components/EipsListing.vue';
import SearchWidget from './components/SearchWidget.vue';

export default {
  ...DefaultTheme,
  Layout,
  enhanceApp({ app, router, siteData }) {
    DefaultTheme.enhanceApp({ app, router, siteData });

    app.component('EipsListing', EipsListing);
    app.component('VPTeamMembers', VPTeamMembers);
    app.component('SearchWidget', SearchWidget);
  }
};
