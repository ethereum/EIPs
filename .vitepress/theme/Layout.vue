<script setup>
import DefaultTheme from 'vitepress/theme';

const { Layout } = DefaultTheme;
</script>

<template>
    <svg xmlns="http://www.w3.org/2000/svg" style="display: none;">
        <symbol id="bi-megaphone-fill" fill="currentColor" viewBox="0 0 16 16">
            <title>Alert</title>
            <path d="M13 2.5a1.5 1.5 0 0 1 3 0v11a1.5 1.5 0 0 1-3 0v-11zm-1 .724c-2.067.95-4.539 1.481-7 1.656v6.237a25.222 25.222 0 0 1 1.088.085c2.053.204 4.038.668 5.912 1.56V3.224zm-8 7.841V4.934c-.68.027-1.399.043-2.008.053A2.02 2.02 0 0 0 0 7v2c0 1.106.896 1.996 1.994 2.009a68.14 68.14 0 0 1 .496.008 64 64 0 0 1 1.51.048zm1.39 1.081c.285.021.569.047.85.078l.253 1.69a1 1 0 0 1-.983 1.187h-.548a1 1 0 0 1-.916-.599l-1.314-2.48a65.81 65.81 0 0 1 1.692.064c.327.017.65.037.966.06z"/>
        </symbol>
        <symbol id="bi-code" fill="currentColor" viewBox="0 0 16 16">
            <title>Source</title>
            <path d="M5.854 4.854a.5.5 0 1 0-.708-.708l-3.5 3.5a.5.5 0 0 0 0 .708l3.5 3.5a.5.5 0 0 0 .708-.708L2.707 8l3.147-3.146zm4.292 0a.5.5 0 0 1 .708-.708l3.5 3.5a.5.5 0 0 1 0 .708l-3.5 3.5a.5.5 0 0 1-.708-.708L13.293 8l-3.147-3.146z"/>
        </symbol>
        <svg id="bi-chat" fill="currentColor" viewBox="0 0 16 16">
            <title>Discuss</title>
            <path d="M2.678 11.894a1 1 0 0 1 .287.801 10.97 10.97 0 0 1-.398 2c1.395-.323 2.247-.697 2.634-.893a1 1 0 0 1 .71-.074A8.06 8.06 0 0 0 8 14c3.996 0 7-2.807 7-6 0-3.192-3.004-6-7-6S1 4.808 1 8c0 1.468.617 2.83 1.678 3.894zm-.493 3.905a21.682 21.682 0 0 1-.713.129c-.2.032-.352-.176-.273-.362a9.68 9.68 0 0 0 .244-.637l.003-.01c.248-.72.45-1.548.524-2.319C.743 11.37 0 9.76 0 8c0-3.866 3.582-7 8-7s8 3.134 8 7-3.582 7-8 7a9.06 9.06 0 0 1-2.347-.306c-.52.263-1.639.742-3.468 1.105z"/>
        </svg>
    </svg>
    <Layout>
        <template #doc-before v-if="$frontmatter.eip">
            <div class="vp-doc">
                <h1 v-if="$frontmatter?.category != 'erc'">
                    <a :href="$frontmatter['discussions-to']" class="no-underline" v-if="$frontmatter['discussions-to']">
                        <svg role="img" aria-label="Discuss" class="inline-svg" xmlns="https://www.w3.org/2000/svg" viewBox="0 0 16 16">
                            <use xlink:href="#bi-chat"/>
                        </svg>
                    </a>
                    EIP-{{ $frontmatter.eip }}: {{ $frontmatter.title }}
                    <Badge type="danger" text="🚧 Stagnant" v-if="$frontmatter.status == 'Stagnant'"/>
                    <Badge type="danger" text="🛑 Withdrawn" v-if="$frontmatter.status == 'Withdrawn'"/>
                    <Badge type="warning" text="⚠️ Draft" v-if="$frontmatter.status == 'Draft'"/>
                    <Badge type="warning" text="⚠️ Review" v-if="$frontmatter.status == 'Review'"/>
                    <Badge type="info" text="📢 Last Call" v-if="$frontmatter.status == 'Last Call'"/>
                    <Badge type="info" text="Standards Track" v-if="$frontmatter.type == 'Standards Track'"/>
                    <Badge type="info" text="Core" v-if="$frontmatter.category == 'Core'"/>
                    <Badge type="info" text="Networking" v-if="$frontmatter.category == 'Networking'"/>
                    <Badge type="info" text="Interface" v-if="$frontmatter.category == 'Interface'"/>
                    <Badge type="info" text="ERC" v-if="$frontmatter.category == 'ERC'"/>
                    <Badge type="info" text="Meta" v-if="$frontmatter.type == 'Meta'"/>
                    <Badge type="info" text="Informational" v-if="$frontmatter.type == 'Informational'"/>
                </h1>
                <h3 v-if="$frontmatter.description">{{ $frontmatter.description }}</h3>
                <a :href="$frontmatter['discussions-to']" target="__blank">
                    <Badge type="tip" v-if="$frontmatter.status == 'Review' || $frontmatter.status == 'Last Call'" style="width: 100%;">
                        <svg class="inline-svg" style="width:2.5em;height:1.5em;">
                            <use xlink:href="#bi-megaphone-fill"/>
                        </svg>This EIP is in the process of being peer-reviewed.<br/>
                        If you are interested in this EIP, please participate using this discussion link.
                    </Badge>
                </a>
                <table>
                    <tbody>
                        <tr>
                            <th>Authors</th>
                            <td>
                                <span v-for='author in $frontmatter?.author.match(/(?<=^|,\s*)[^\s]([^,"]|".*")+(?=(?:$|,))/g)'>
                                    <span v-if="author.match(/(?<=\<).*(?=\>)/g)">
                                        <a :href="`mailto:${author.match(/(?<=\<).*(?=\>)/g).pop()}`">
                                            {{ author.match(/(?<![(<].*)[^\s(<][^(<]*\w/g).pop() }}
                                        </a>
                                    </span>
                                    <span v-else-if="author.match(/(?<=\(@)[\w-]+(?=\))/g)">
                                        <a :href="`https://github.com/${author.match(/(?<=\(@)[\w-]+(?=\))/g).pop()}`">
                                            {{ author.match(/(?<![(<].*)[^\s(<][^(<]*\w/g).pop() }}
                                        </a>
                                    </span>
                                    <span v-else>
                                        {{ author }}
                                    </span>
                                    &nbsp;
                                </span>
                            </td>
                        </tr>
                        <tr>
                            <td>Created</td>
                            <td>{{ $frontmatter?.created }}</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </template>
        <template #doc-after v-if="$frontmatter.eip">
            <div class="vp-doc">
                <h2>Citation</h2>
                <p>Please cite this document as:</p>
                <p>{{ $frontmatter?.author.match(/(?<=^|,\s*)[^\s]([^,"]|".*")+(?=(?:$|,))/g).map(author => author.match(/(?<![(<].*)[^\s(<][^(<]*\w/g)[0]).join(", ") }}, "{{ $frontmatter?.category == "ERC" ? "ERC" : "EIP" }}-{{ $frontmatter?.eip }}: {{ $frontmatter?.title }}{{ $frontmatter?.status == "Draft" || $frontmatter?.status == "Stagnant" || $frontmatter?.status == "Withdrawn" || $frontmatter?.status == "Review" || $frontmatter?.status == "Last Call" ? "[DRAFT]" : "" }}," <em>Ethereum Improvement Proposals</em>, no. {{ $frontmatter?.eip }}, {{ $frontmatter?.created.split("-")[0] }}. [Online serial]. Available: https://eips.ethereum.org/EIPS/eip-{{ $frontmatter?.eip }}.</p>
            </div>
        </template>
    </Layout>
</template>

<style>
.inline-svg {
  display: inline-block;
  fill: currentColor;
  width: 1.5ex;
  height: 100%;
  object-fit: cover;
}
</style>