<script setup>
import DefaultTheme from 'vitepress/theme'; // Gets rid of compiler error for $frontmatter
</script>
<template>
    <div v-for="status in $frontmatter.allStatuses">
        <h2 v-if="$frontmatter.allEips.filter(eip => eip.status == status && Object.keys($frontmatter.filter).every(key => $frontmatter.filter[key].includes({ ...eip }[key]))).length">{{ status }}</h2>
        <table style="width: 100%; display: table;" v-if="$frontmatter.allEips.filter(eip => eip.status == status && Object.keys($frontmatter.filter).every(key => $frontmatter.filter[key].includes({ ...eip }[key]))).length">
            <thead>
                <tr>
                    <th>EIP</th>
                    <th>Title</th>
                    <th>Authors</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="eip of $frontmatter.allEips.filter(eip => eip.status == status && Object.keys($frontmatter.filter).every(key => $frontmatter.filter[key].includes({ ...eip }[key])))">
                    <td><a :href="`./EIPS/eip-${eip.eip}`">{{ eip.category == 'ERC' ? 'ERC' : 'EIP' }}-{{ eip.eip }}</a></td>
                    <td>{{ eip.onlyTitle }}</td>
                    <td>{{ eip?.author.match(/(?<=^|,\s*)[^\s]([^,"]|".*")+(?=(?:$|,))/g).map(author => author.match(/(?<![(<].*)[^\s(<][^(<]*\w/g)[0]).join(", ") }}</td>
                </tr>
            </tbody>
        </table>
    </div>
</template>
