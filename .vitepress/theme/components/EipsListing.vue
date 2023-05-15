<script setup>
import DefaultTheme from 'vitepress/theme'; // Gets rid of compiler error for $frontmatter
import { getCurrentInstance } from 'vue';

let vm = getCurrentInstance();
let app = vm.appContext.app;
const frontmatter = app.config.globalProperties.$frontmatter;

// Filter out EIPs that are not in the filter
const { filteredEips } = frontmatter;

// Get all unique statuses
const allStatuses = [ 'Living', 'Last Call', 'Final', 'Review', 'Draft', 'Withdrawn', 'Stagnant' ];

for (let status of [...new Set(filteredEips.map(eip => eip.status))]) {
    // If there's a new status, display warning
    if (!allStatuses.includes(status)) {
        throw new Error(`Unknown status: ${status}`);
    }
}
</script>
<template>
    <div v-for="status in allStatuses">
        <div v-if="filteredEips.some(eip => eip.status == status)">
            <h2>{{ status }}</h2>
            <table style="width: 100%; display: table;">
                <thead>
                    <tr>
                        <th>EIP / Title</th>
                        <th>Authors</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="eip of filteredEips.filter(eip => eip.status == status)">
                        <td><a :href="`./EIPS/eip-${eip.eip}`">{{ eip.title }}</a></td>
                        <td>{{ eip?.authorData.map(author => author.name).join(', ') }}</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>
