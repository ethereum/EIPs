import { defineConfig } from 'vite';
import { SearchPlugin } from 'vitepress-plugin-search';

// Handled mostly by vitepress
export default defineConfig({
    plugins: [SearchPlugin({
        previewLength: 62,
        buttonLabel: 'Search',
        placeholder: 'Search EIPs'
    })],
});
