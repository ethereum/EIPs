<script setup>
import { ref } from "vue";
let searchitem = ref("");
</script>
<template>
    <!-- Vue doesn't like the built in script thing. Use the component thing to get around it. -->
    <component :is="'script'" async src="https://cse.google.com/cse.js?cx=d55df9aacc78f45ed"></component>
    <div>
        <div class="gcse-search"></div>
    </div>
    <div id="docsearch" style="margin-right: 1em;">
        <button type="button" class="DocSearch DocSearch-Button" aria-label="Search">
            <span class="DocSearch-Button-Container">
                <svg class="DocSearch-Search-Icon" width="20" height="20" viewBox="0 0 20 20">
                    <path d="M14.386 14.386l4.0877 4.0877-4.0877-4.0877c-2.9418 2.9419-7.7115 2.9419-10.6533 0-2.9419-2.9418-2.9419-7.7115 0-10.6533 2.9418-2.9419 7.7115-2.9419 10.6533 0 2.9419 2.9418 2.9419 7.7115 0 10.6533z" stroke="currentColor" fill="none" fill-rule="evenodd" stroke-linecap="round" stroke-linejoin="round" style="--darkreader-inline-stroke: currentColor;" data-darkreader-inline-stroke=""></path>
                </svg>
                <input class="DocSearch-Button-Placeholder" id="searchitem" v-model="searchitem"/>
                <a class="DocSearch-Button-Keys" :href="`#gsc.tab=0&gsc.sort=&gsc.q=${searchitem}`" id="clicksearch">
                    <kbd class="DocSearch-Button-Key"></kbd>
                    <kbd class="DocSearch-Button-Key">Search</kbd>
                </a>
            </span>
        </button>
    </div>
    <component :is="'script'">
        document.getElementById("searchitem").addEventListener("keyup", function(event) {
            if (event.keyCode === 13) {
                event.preventDefault();
                document.getElementById("clicksearch").click();
            }
        });
    </component>
</template>
<style>
/* Overrides the default Google search box styles */
.gsc-control-cse {
    background-color: inherit !important;
    border: none !important;
    color: #000000 !important;
}
.gsc-search-box-tools { /* Make this disappear; We're using our own */
    display: none !important;
}
.gsc-completion-container {
    background-color: #ffffff !important;
    border: 1px solid #000000 !important;
    color: #000000 !important;
}
</style>