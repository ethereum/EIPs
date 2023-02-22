<script setup>
import DefaultTheme from 'vitepress/theme'; // Gets rid of compiler error for $frontmatter
import { getCurrentInstance, ref, computed, watch } from 'vue';

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
        link: `/EIPS/eip-${eip.eip}`,
        status: eip.status,
        type: eip.type,
        category: eip.category,
    });
}

let search = ref("");
let results = computed(() => {
    let searchQuery = search.value.toLowerCase().match(/([^\s-_"]|((?<!\\)".*(?!\\)"))+/g);
    if (!searchQuery) return [];
    let searchModifiers = searchQuery.filter(q => q && q.includes(":")).map(q => q.replaceAll(`"`, ""));
    searchQuery = searchQuery.filter(q => q && !q.includes(":"));
    let results = transformedEips.filter(eip => {
        for (let query of searchQuery) {
            if (!eip?.title?.toLowerCase()?.includes(query) && !eip?.wrongTitle?.toLowerCase()?.includes(query) && !eip?.description?.toLowerCase()?.includes(query)) {
                return false;
            }
        }
        for (let modifier of searchModifiers) {
            let [key, value] = modifier.split(":");
            if (eip[key]?.toLowerCase() != value?.toLowerCase()) return false;
        }
        return true;
    }).sort((eip1, eip2) => {
        let statusOrder = ["living", "last call", "final", "review", "draft", "stagnant", "withdrawn"];
        let status1 = statusOrder.indexOf(eip1.status.toLowerCase());
        let status2 = statusOrder.indexOf(eip2.status.toLowerCase());
        if (status1 != status2) return status1 - status2;
        return eip1.eip - eip2.eip
    });
    return results;
});

// Set up query params
const urlParams = new URLSearchParams(window.location.search);
if (urlParams.has('search')) {
    search.value = urlParams.get('search');
}

// Update query params
watch(search, (newSearch) => {
    if (newSearch) {
        urlParams.set('search', newSearch);
    } else {
        urlParams.delete('search');
    }
    window.history.replaceState({}, '', `${window.location.pathname}?${urlParams}`);
});
</script>
<template>
    <div type="button" class="DocSearch DocSearch-Button" aria-label="Search">
        <span class="DocSearch-Button-Container">
            <svg width="20" height="20" class="DocSearch-Search-Icon" viewBox="0 0 20 20">
                <path d="M14.386 14.386l4.0877 4.0877-4.0877-4.0877c-2.9418 2.9419-7.7115 2.9419-10.6533 0-2.9419-2.9418-2.9419-7.7115 0-10.6533 2.9418-2.9419 7.7115-2.9419 10.6533 0 2.9419 2.9418 2.9419 7.7115 0 10.6533z" stroke="currentColor" fill="none" fill-rule="evenodd" stroke-linecap="round" stroke-linejoin="round" style="--darkreader-inline-stroke: currentColor;" data-darkreader-inline-stroke=""></path>
            </svg>
            <input type="text" v-model="search" placeholder="Search..." autofocus>
        </span>
    </div>
    <div>
        <p v-if="!results.length">Sorry, no results for <code>{{search}}</code></p>
        <div class="info custom-block search-result" v-for="(r, i) in results" :key="i">
            <p class="custom-block-title">
                <a :href="r.link">
                    {{ r.title }}
                    <Badge type="danger" text="🚧 Stagnant" v-if="r.status == 'Stagnant'"/>
                    <Badge type="danger" text="🛑 Withdrawn" v-if="r.status == 'Withdrawn'"/>
                    <Badge type="warning" text="⚠️ Draft" v-if="r.status == 'Draft'"/>
                    <Badge type="warning" text="⚠️ Review" v-if="r.status == 'Review'"/>
                    <Badge type="warning" text="📢 Last Call" v-if="r.status == 'Last Call'"/>
                    <Badge type="tip" text="Final" v-if="r.status == 'Final'"/>
                    <Badge type="tip" text="Living" v-if="r.status == 'Living'"/>
                    <Badge type="info" text="Core" v-if="r.category == 'Core'"/>
                    <Badge type="info" text="Networking" v-if="r.category == 'Networking'"/>
                    <Badge type="info" text="Interface" v-if="r.category == 'Interface'"/>
                    <Badge type="info" text="ERC" v-if="r.category == 'ERC'"/>
                    <Badge type="info" text="Meta" v-if="r.type == 'Meta'"/>
                    <Badge type="info" text="Informational" v-if="r.type == 'Informational'"/>
                </a>
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