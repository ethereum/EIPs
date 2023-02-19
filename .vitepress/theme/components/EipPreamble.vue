<script setup>
import DefaultTheme from 'vitepress/theme'; // Gets rid of compiler error for $frontmatter
</script>
<template>
    <div class="vp-doc">
        <h1 v-if="$frontmatter?.category != 'erc'">
            <a :href="$frontmatter['discussions-to']" class="no-underline" v-if="$frontmatter['discussions-to']">
                <svg role="img" aria-label="Discuss" class="inline-svg" xmlns="https://www.w3.org/2000/svg" viewBox="0 0 16 16">
                    <use xlink:href="#bi-chat"/>
                </svg>
            </a>
            EIP-{{ $frontmatter.eip }}: {{ $frontmatter.title }}
        </h1>
        <h3 v-if="$frontmatter.description" style="margin-top: 0.1em;">{{ $frontmatter.description }}</h3>
        <p style="margin-bottom: 1em;">
            <Badge type="danger" text="🚧 Stagnant" v-if="$frontmatter.status == 'Stagnant'"/>
            <Badge type="danger" text="🛑 Withdrawn" v-if="$frontmatter.status == 'Withdrawn'"/>
            <Badge type="warning" text="⚠️ Draft" v-if="$frontmatter.status == 'Draft'"/>
            <Badge type="warning" text="⚠️ Review" v-if="$frontmatter.status == 'Review'"/>
            <Badge type="warning" text="📢 Last Call" v-if="$frontmatter.status == 'Last Call'"/>
            <Badge type="tip" text="Final" v-if="$frontmatter.status == 'Final'"/>
            <Badge type="tip" text="Living" v-if="$frontmatter.status == 'Living'"/>
            <Badge type="info" text="Core" v-if="$frontmatter.category == 'Core'"/>
            <Badge type="info" text="Networking" v-if="$frontmatter.category == 'Networking'"/>
            <Badge type="info" text="Interface" v-if="$frontmatter.category == 'Interface'"/>
            <Badge type="info" text="ERC" v-if="$frontmatter.category == 'ERC'"/>
            <Badge type="info" text="Meta" v-if="$frontmatter.type == 'Meta'"/>
            <Badge type="info" text="Informational" v-if="$frontmatter.type == 'Informational'"/>
        </p>
        <div class="tip custom-block" v-if="$frontmatter.status == 'Review' || $frontmatter.status == 'Last Call'">
            <p class="custom-block-title">
                <svg class="inline-svg"><use xlink:href="#bi-megaphone-fill"/></svg>
                <span>Peer Review Notice</span>
            </p>
            <p>This EIP is in the process of being peer-reviewed. <a :href="$frontmatter['discussions-to']">If you are interested in this EIP, and have feedback to share, please participate using this discussion link.</a> Thank you!</p>
        </div>
        <table class="preamble-table">
            <tbody>
                <tr>
                    <th>Authors</th>
                    <td v-html="$frontmatter?.authorData?.map(author => author.name + (author.email ? ` \<<a href='mailto:${author.email}'>${author.email}</a>\>` : (author.github ? ` (<a href='https://github.com/${author.github}'>@${author.github}</a>)` : ''))).join(', ')"></td>
                </tr>
                <tr v-if="$frontmatter.finalized">
                    <th>Finalized</th>
                    <td>{{ $frontmatter?.finalized }}</td>
                </tr>
                <tr>
                    <th>Created</th>
                    <td>{{ $frontmatter?.created }}</td>
                </tr>
            </tbody>
        </table>
    </div>
</template>
