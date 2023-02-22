<script setup>
import DefaultTheme from 'vitepress/theme'; // Gets rid of compiler error for $frontmatter
import { getCurrentInstance, ref, computed } from 'vue';

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

let search = ref("");
let results = computed(() => {
    let searchQuery = search.value.toLowerCase().split(/[\s-_]+/);
    let results = transformedEips.filter(eip => {
        for (let query of searchQuery) {
            if (!eip?.title?.toLowerCase()?.includes(query) && !eip?.wrongTitle?.toLowerCase()?.includes(query) && !eip?.description?.toLowerCase()?.includes(query)) {
                return false;
            }
        }
        return true;
    }).sort((eip1, eip2) => eip1.eip - eip2.eip);
    console.log(results);
    return results;
})
</script>
<template>
    <div type="button" class="DocSearch DocSearch-Button" aria-label="Search">
        <span class="DocSearch-Button-Container">
            <svg width="20" height="20" class="DocSearch-Search-Icon" viewBox="0 0 20 20">
                <path d="M14.386 14.386l4.0877 4.0877-4.0877-4.0877c-2.9418 2.9419-7.7115 2.9419-10.6533 0-2.9419-2.9418-2.9419-7.7115 0-10.6533 2.9418-2.9419 7.7115-2.9419 10.6533 0 2.9419 2.9418 2.9419 7.7115 0 10.6533z" stroke="currentColor" fill="none" fill-rule="evenodd" stroke-linecap="round" stroke-linejoin="round" style="--darkreader-inline-stroke: currentColor;" data-darkreader-inline-stroke=""></path>
            </svg>
            <input type="text" v-model="search" placeholder="Search...">
        </span>
    </div>
    <div>
        <p v-if="!results.length">Sorry, no results for <code>{{search}}</code></p>
        <div class="info custom-block search-result" v-for="(r, i) in results" :key="i">
            <p class="custom-block-title">
                <a :href="r.link">{{ r.title }}</a>
            </p>
            <p>{{ r.description }}</p>
        </div>
    </div>
</template>
<style scoped>
.search-result {
    margin-bottom: 0.75em;
    margin-top: 0.25em;
}
</style>