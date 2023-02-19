<script setup>
import DefaultTheme from 'vitepress/theme'; // Gets rid of compiler error for $frontmatter
</script>
<template>
    <div class="vp-doc">
        <h2>Citation</h2>
        <p>Please cite this document as:</p>
        <p>{{ $frontmatter?.authorData?.map(author => author.name).join(", ") }}, "{{ $frontmatter?.category == "ERC" ? "ERC" : "EIP" }}-{{ $frontmatter?.eip }}: {{ $frontmatter?.title }}{{ $frontmatter?.status == "Draft" || $frontmatter?.status == "Stagnant" || $frontmatter?.status == "Withdrawn" || $frontmatter?.status == "Review" || $frontmatter?.status == "Last Call" ? "[DRAFT]" : "" }}," <em>Ethereum Improvement Proposals</em>, no. {{ $frontmatter?.eip }}, {{ $frontmatter?.created.split("-")[0] }}. [Online serial]. Available: https://eips.ethereum.org/EIPS/eip-{{ $frontmatter?.eip }}.</p>
    </div>
</template>
