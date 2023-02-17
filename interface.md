---
title: Interface
listing: true
---

<!-- markdownlint-disable no-inline-html reference-links-images no-reversed-links -->

<div v-for="status in $frontmatter.statuses">
    <h2>{{ status }}</h2>
    <table style="width: 100%; display: table;">
        <thead>
            <tr>
                <th>EIP</th>
                <th>Title</th>
                <th>Authors</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="eip of $frontmatter.eips.filter(eip => eip.status == status && eip.category == "Interface")">
                <td><a :href="`./eip-${eip.eip}`">{{ eip.category == "ERC" ? "ERC" : "EIP" }}-{{ eip.eip }}</a></td>
                <td>{{ eip.title }}</td>
                <td>{{ eip?.author.match(/(?<=^|,\s*)[^\s]([^,"]|".*")+(?=(?:$|,))/g).map(author => author.match(/(?<![(<].*)[^\s(<][^(<]*\w/g)[0]).join(", ") }}</td>
            </tr>
        </tbody>
    </table>
</div>
