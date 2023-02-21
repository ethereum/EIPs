<script setup>
import DefaultTheme from 'vitepress/theme'; // Gets rid of compiler error for $frontmatter
import { getCurrentInstance, ref, watch } from 'vue';
import { useVueFuse } from 'vue-fuse';

// Get front matter from the current page (in app.config.globalProperties.$frontmatter)
let vm = getCurrentInstance();
let app = vm.appContext.app;
const frontmatter = app.config.globalProperties.$frontmatter;

let transformedEips = [];
for (let eip of frontmatter.allEips) {
    let eipPrefix = eip.category == 'ERC' ? 'ERC' : 'EIP'; // Since some people use the wrong prefix
    let wrongEipPrefix = eip.category == 'ERC' ? 'EIP' : 'ERC'; // Since some people use the wrong prefix
    transformedEips.push({
        title: `${eipPrefix}-${eip.eip}: ${eip.onlyTitle}`,
        wrongTitle: `${wrongEipPrefix}-${eip.eip}: ${eip.onlyTitle}`,
        description: eip.description,
        author: eip.author,
        link: `/EIPS/eip-${eip.eip}`
    });
}

let showSearchModal = ref(false);

const { search, results, noResults } = useVueFuse(transformedEips, {
    keys: ['title', 'wrongTitle'],
    threshold: 0.3,
});

// Manage classes according to search modal state
const appEl = document.querySelector('#app');
watch(showSearchModal, (val) => {
    if (val) {
        appEl.classList.add('search-blur');
    } else {
        appEl.classList.remove('search-blur');
    }
});
</script>
<template>
    <div id="docsearch">
        <button type="button" class="DocSearch DocSearch-Button" aria-label="Search" @click="showSearchModal = true">
            <span class="DocSearch-Button-Container">
                <svg width="20" height="20" class="DocSearch-Search-Icon" viewBox="0 0 20 20">
                    <path d="M14.386 14.386l4.0877 4.0877-4.0877-4.0877c-2.9418 2.9419-7.7115 2.9419-10.6533 0-2.9419-2.9418-2.9419-7.7115 0-10.6533 2.9418-2.9419 7.7115-2.9419 10.6533 0 2.9419 2.9418 2.9419 7.7115 0 10.6533z" stroke="currentColor" fill="none" fill-rule="evenodd" stroke-linecap="round" stroke-linejoin="round" style="--darkreader-inline-stroke: currentColor;" data-darkreader-inline-stroke=""></path>
                </svg>
                <span class="DocSearch-Button-Placeholder">Search</span>
            </span>
            <span class="DocSearch-Button-Keys">
                <kbd class="DocSearch-Button-Key"></kbd>
                <kbd class="DocSearch-Button-Key">Ctrl K</kbd>
            </span>
        </button>
    </div>
    <Teleport to="body">
        <div class="modal search-modal" v-if="showSearchModal" id="search">
            <button class="VPButton medium alt closeButton" @click="showSearchModal = false">Back</button>
            <div type="button" class="DocSearch DocSearch-Button" aria-label="Search">
                <span class="DocSearch-Button-Container">
                    <svg width="20" height="20" class="DocSearch-Search-Icon" viewBox="0 0 20 20">
                        <path d="M14.386 14.386l4.0877 4.0877-4.0877-4.0877c-2.9418 2.9419-7.7115 2.9419-10.6533 0-2.9419-2.9418-2.9419-7.7115 0-10.6533 2.9418-2.9419 7.7115-2.9419 10.6533 0 2.9419 2.9418 2.9419 7.7115 0 10.6533z" stroke="currentColor" fill="none" fill-rule="evenodd" stroke-linecap="round" stroke-linejoin="round" style="--darkreader-inline-stroke: currentColor;" data-darkreader-inline-stroke=""></path>
                    </svg>
                    <input type="text" v-model="search" placeholder="Search...">
                </span>
            </div>
            <div>
                <p v-if="noResults">Sorry, no results for {{search}}</p>
                <div class="info custom-block search-result" v-for="(r, i) in results" :key="i">
                    <p class="custom-block-title">
                        <a :href="r.link">{{ r.title }}</a>
                    </p>
                    <p>{{ r.description }}</p>
                </div>
            </div>
        </div>
    </Teleport>
</template>
<style v-if="showSearchModal">
.search-modal {
    filter: none !important;
    border: 2px solid rgb(20, 20, 30);
    border-radius: 5px;
    padding: 1em;
    background-color: inherit;
}
/* blur everything behind the modal, if it exists */
#app.search-blur {
    filter: blur(5px);
}
</style>
<style scoped>
.search-result {
    margin-bottom: 0.75em;
    margin-top: 0.25em;
}

.search-modal {
  position: fixed;
  z-index: 999;
  top: 20%;
  left: 50%;
  width: 300px;
  margin-left: -150px;
}
.closeButton {
	border-color: var(--vp-button-alt-border);
	color: var(--vp-button-alt-text);
	background-color: var(--vp-button-alt-bg);
	border-radius: 20px;
	padding: 0 20px;
	line-height: 38px;
	font-size: 14px;
	display: inline-block;
	border: 1px solid transparent;
	text-align: center;
	font-weight: 600;
	white-space: nowrap;
	transition: color 0.25s, border-color 0.25s, background-color 0.25s;
    margin-top: 1em;
    margin-bottom: 1em;
}
</style>