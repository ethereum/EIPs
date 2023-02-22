<script setup>
import DefaultTheme from 'vitepress/theme';

import ReloadPrompt from './ReloadPrompt.vue';

import EipCitation from './EipCitation.vue';
import EipPreamble from './EipPreamble.vue';

const { Layout } = DefaultTheme;
</script>

<template>
    <svg xmlns="http://www.w3.org/2000/svg" style="display: none;">
        <symbol id="bi-megaphone-fill" fill="currentColor" viewBox="0 0 16 16">
            <title>Alert</title>
            <path d="M13 2.5a1.5 1.5 0 0 1 3 0v11a1.5 1.5 0 0 1-3 0v-11zm-1 .724c-2.067.95-4.539 1.481-7 1.656v6.237a25.222 25.222 0 0 1 1.088.085c2.053.204 4.038.668 5.912 1.56V3.224zm-8 7.841V4.934c-.68.027-1.399.043-2.008.053A2.02 2.02 0 0 0 0 7v2c0 1.106.896 1.996 1.994 2.009a68.14 68.14 0 0 1 .496.008 64 64 0 0 1 1.51.048zm1.39 1.081c.285.021.569.047.85.078l.253 1.69a1 1 0 0 1-.983 1.187h-.548a1 1 0 0 1-.916-.599l-1.314-2.48a65.81 65.81 0 0 1 1.692.064c.327.017.65.037.966.06z"/>
        </symbol>
        <symbol id="bi-code" fill="currentColor" viewBox="0 0 16 16">
            <title>Source</title>
            <path d="M5.854 4.854a.5.5 0 1 0-.708-.708l-3.5 3.5a.5.5 0 0 0 0 .708l3.5 3.5a.5.5 0 0 0 .708-.708L2.707 8l3.147-3.146zm4.292 0a.5.5 0 0 1 .708-.708l3.5 3.5a.5.5 0 0 1 0 .708l-3.5 3.5a.5.5 0 0 1-.708-.708L13.293 8l-3.147-3.146z"/>
        </symbol>
        <svg id="bi-chat" fill="currentColor" viewBox="0 0 16 16">
            <title>Discuss</title>
            <path d="M2.678 11.894a1 1 0 0 1 .287.801 10.97 10.97 0 0 1-.398 2c1.395-.323 2.247-.697 2.634-.893a1 1 0 0 1 .71-.074A8.06 8.06 0 0 0 8 14c3.996 0 7-2.807 7-6 0-3.192-3.004-6-7-6S1 4.808 1 8c0 1.468.617 2.83 1.678 3.894zm-.493 3.905a21.682 21.682 0 0 1-.713.129c-.2.032-.352-.176-.273-.362a9.68 9.68 0 0 0 .244-.637l.003-.01c.248-.72.45-1.548.524-2.319C.743 11.37 0 9.76 0 8c0-3.866 3.582-7 8-7s8 3.134 8 7-3.582 7-8 7a9.06 9.06 0 0 1-2.347-.306c-.52.263-1.639.742-3.468 1.105z"/>
        </svg>
    </svg>
    <Layout>
        <template #doc-before v-if="$frontmatter.eip">
            <EipPreamble/>
        </template>
        <template #doc-after v-if="$frontmatter.eip">
            <EipCitation/>
        </template>
        <template #layout-bottom>
            <ReloadPrompt/>
        </template>
        <template #nav-bar-content-before>
            <div id="docsearch">
                <a class="DocSearch DocSearch-Button" aria-label="Search" href="/search">
                    <span class="DocSearch-Button-Container">
                        <svg width="20" height="20" class="DocSearch-Search-Icon" viewBox="0 0 20 20">
                            <path d="M14.386 14.386l4.0877 4.0877-4.0877-4.0877c-2.9418 2.9419-7.7115 2.9419-10.6533 0-2.9419-2.9418-2.9419-7.7115 0-10.6533 2.9418-2.9419 7.7115-2.9419 10.6533 0 2.9419 2.9418 2.9419 7.7115 0 10.6533z" stroke="currentColor" fill="none" fill-rule="evenodd" stroke-linecap="round" stroke-linejoin="round" style="--darkreader-inline-stroke: currentColor;" data-darkreader-inline-stroke=""></path>
                        </svg>
                        <span class="DocSearch-Button-Placeholder">Search</span>
                    </span>
                    <span class="DocSearch-Button-Keys">
                        <kbd class="DocSearch-Button-Key"></kbd>
                        <kbd class="DocSearch-Button-Key">K</kbd>
                    </span>
                </a>
            </div>
        </template>
    </Layout>
    <!-- Hacky way to add a script to the page -->
    <!-- Doesn't support JS comments! -->
    <component :is="'script'">
        document.addEventListener('keydown', (e) => {
            if (e.key === 'k' && document?.activeElement?.tagName?.toLowerCase() !== 'input' && window?.location?.pathname !== '/search') {
                window.location.href = '/search';
            }
        });
    </component>
</template>

<style>
.inline-svg {
  display: inline-block;
  fill: currentColor;
  width: 1.5ex;
  height: 1.5ex;
  margin: 0 0.25em;
  object-fit: cover;
}
a img {
    display:inline-block;
}
.preamble-table, .preamble-table * {
    border: none !important;
    background-color: inherit !important;
}

/* Centering is added randomly by the parent element of these. This is to override it. */
.aside, .content {
    text-align: left;
    justify-content: left;
    align-items: left;
}
</style>