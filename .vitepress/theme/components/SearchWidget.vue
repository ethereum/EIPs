<script setup>
import DefaultTheme from 'vitepress/theme'; // Gets rid of compiler error for $frontmatter
import { getCurrentInstance, computed, watch, reactive, ref } from 'vue';

let searchModifiers = reactive({
    status: {
        draft: false,
        stagnant: false,
        living: true,
        review: true,
        final: true,
        withdrawn: false,
        "last call": false,
    },
    type: {
        "standards track": true,
        meta: true,
        informational: true,
    },
    category: {
        erc: true,
        core: true,
        networking: true,
        interface: true,
    },
});

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
    let _ = searchModifiers; // Re-render when this changes
    let searchQuery = search.value.toLowerCase().split(" ");
    if (!searchQuery) {
        searchQuery = [];
    };
    searchQuery = searchQuery.filter(q => q && !q.includes(":"));
    let results = transformedEips.filter(eip => {
        for (let query of searchQuery) {
            if (!eip?.title?.toLowerCase()?.includes(query) && !eip?.wrongTitle?.toLowerCase()?.includes(query) && !eip?.description?.toLowerCase()?.includes(query)) {
                return false;
            }
        }
        for (let modifier in searchModifiers) {
            let matchesAny = false;
            for (let value in searchModifiers[modifier]) {
                if (searchModifiers[modifier][value] && eip[modifier]?.toLowerCase() == value) {
                    matchesAny = true;
                }
            }
            if (!matchesAny) {
                return false;
            }
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
if (urlParams.has('status')) {
    let status = urlParams.get('status').split(',');
    for (let s of status) {
        searchModifiers.status[s] = true;
    }
}
if (urlParams.has('type')) {
    let type = urlParams.get('type').split(',');
    for (let t of type) {
        searchModifiers.type[t] = true;
    }
}
if (urlParams.has('category')) {
    let category = urlParams.get('category').split(',');
    for (let c of category) {
        searchModifiers.category[c] = true;
    }
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
watch(searchModifiers, (newSearchModifiers) => {
    let status = [];
    let type = [];
    let category = [];
    for (let s in newSearchModifiers.status) {
        if (newSearchModifiers.status[s]) {
            status.push(s);
        }
    }
    for (let t in newSearchModifiers.type) {
        if (newSearchModifiers.type[t]) {
            type.push(t);
        }
    }
    for (let c in newSearchModifiers.category) {
        if (newSearchModifiers.category[c]) {
            category.push(c);
        }
    }
    if (status.length) {
        urlParams.set('status', status.join(','));
    } else {
        urlParams.delete('status');
    }
    if (type.length) {
        urlParams.set('type', type.join(','));
    } else {
        urlParams.delete('type');
    }
    if (category.length) {
        urlParams.set('category', category.join(','));
    } else {
        urlParams.delete('category');
    }
    window.history.replaceState({}, '', `${window.location.pathname}?${urlParams}`);
}, { deep: true });
</script>
<template>
    <!-- Search Bar -->
    <div role="button" aria-expanded="true" aria-haspopup="listbox" aria-labelledby="docsearch-label" class="DocSearch" tabindex="0" style="margin-bottom: 1em;">
        <header class="DocSearch-SearchBar">
            <form class="DocSearch-Form">
                <label class="DocSearch-MagnifierLabel" for="docsearch-input" id="docsearch-label"><svg width="20" height="20" class="DocSearch-Search-Icon" viewBox="0 0 20 20"><path d="M14.386 14.386l4.0877 4.0877-4.0877-4.0877c-2.9418 2.9419-7.7115 2.9419-10.6533 0-2.9419-2.9418-2.9419-7.7115 0-10.6533 2.9418-2.9419 7.7115-2.9419 10.6533 0 2.9419 2.9418 2.9419 7.7115 0 10.6533z" stroke="currentColor" fill="none" fill-rule="evenodd" stroke-linecap="round" stroke-linejoin="round" style="--darkreader-inline-stroke: currentColor;" data-darkreader-inline-stroke=""></path></svg></label>
                <input v-model="search" class="DocSearch-Input" aria-autocomplete="both" aria-labelledby="docsearch-label" id="docsearch-input" autocomplete="off" autocorrect="off" autocapitalize="none" enterkeyhint="search" spellcheck="false" autofocus="true" placeholder="Search EIPs" maxlength="64" type="search">
            </form>
        </header>
    </div>
    <!-- Filters -->
    <table>
        <thead>
            <tr>
                <th>Status</th>
                <th>Type</th>
                <th>Category</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>
                    <label>
                        <input type="checkbox" v-model="searchModifiers.status.draft" />
                        Draft ({{ results.length ? results.filter(r => r.status == 'Draft').length : 0 }})
                    </label>
                </td>
                <td>
                    <label>
                        <input type="checkbox" v-model="searchModifiers.type['standards track']" />
                        Standards Track ({{ results.length ? results.filter(r => r.type == 'Standards Track').length : 0 }})
                    </label>
                </td>
                <td>
                    <label>
                        <input type="checkbox" v-model="searchModifiers.category.erc" />
                        ERC ({{ results.length ? results.filter(r => r.category == 'ERC').length : 0 }})
                    </label>
                </td>
            </tr>
            <tr>
                <td>
                    <label>
                        <input type="checkbox" v-model="searchModifiers.status.review" />
                        Review ({{ results.length ? results.filter(r => r.status == 'Review').length : 0 }})
                    </label>
                </td>
                <td>
                    <label>
                        <input type="checkbox" v-model="searchModifiers.type.informational" />
                        Informational ({{ results.length ? results.filter(r => r.type == 'Informational').length : 0 }})
                    </label>
                </td>
                <td>
                    <label>
                        <input type="checkbox" v-model="searchModifiers.category.core" />
                        Core ({{ results.length ? results.filter(r => r.category == 'Core').length : 0 }})
                    </label>
                </td>
            </tr>
            <tr>
                <td>
                    <label>
                        <input type="checkbox" v-model="searchModifiers.status.last_call" />
                        Last Call ({{ results.length ? results.filter(r => r.status == 'Last Call').length : 0 }})
                    </label>
                </td>
                <td>
                    <label>
                        <input type="checkbox" v-model="searchModifiers.type.meta" />
                        Meta ({{ results.length ? results.filter(r => r.type == 'Meta').length : 0 }})
                    </label>
                </td>
                <td>
                    <label>
                        <input type="checkbox" v-model="searchModifiers.category.interface" />
                        Interface ({{ results.length ? results.filter(r => r.category == 'Interface').length : 0 }})
                    </label>
                </td>
            </tr>
            <tr>
                <td>
                    <label>
                        <input type="checkbox" v-model="searchModifiers.status.final" />
                        Final ({{ results.length ? results.filter(r => r.status == 'Final').length : 0 }})
                    </label>
                </td>
                <td>
                </td>
                <td>
                    <label>
                        <input type="checkbox" v-model="searchModifiers.category.networking" />
                        Networking ({{ results.length ? results.filter(r => r.category == 'Networking').length : 0 }})
                    </label>
                </td>
            </tr>
            <tr>
                <td>
                    <label>
                        <input type="checkbox" v-model="searchModifiers.status.living" />
                        Living ({{ results.length ? results.filter(r => r.status == 'Living').length : 0 }})
                    </label>
                </td>
                <td colspan="2"></td>
            </tr>
            <tr>
                <td>
                    <label>
                        <input type="checkbox" v-model="searchModifiers.status.stagnant" />
                        Stagnant ({{ results.length ? results.filter(r => r.status == 'Stagnant').length : 0 }})
                    </label>
                </td>
                <td colspan="2"></td>
            </tr>
            <tr>
                <td>
                    <label>
                        <input type="checkbox" v-model="searchModifiers.status.withdrawn" />
                        Withdrawn ({{ results.length ? results.filter(r => r.status == 'Withdrawn').length : 0 }})
                    </label>
                </td>
                <td colspan="2"></td>
            </tr>
        </tbody>
    </table>
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