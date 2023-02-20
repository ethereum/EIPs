import { defineConfig } from 'vite';
import { SimpleSearch } from 'vitepress-plugin-simple-search';

// Handled mostly by vitepress
export default defineConfig({
    plugins: [SimpleSearch({
        partialsToIgnore: [ 'assets', '.vitepress', 'node_modules', '404', 'index', 'readme', 'license' ] // Exclude these partials from search results
    })],
});
