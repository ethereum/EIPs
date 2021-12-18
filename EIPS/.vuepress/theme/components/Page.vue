<template>
  <main class="page">
    <slot name="top" />

    <main>
      <header v-if="$pageHeader" class="theme-default-content page-title">
        <h1>{{ $pageHeader }}</h1>
      </header>
      <Content class="theme-default-content" />
    </main>
    <PageEdit />

    <PageNav v-bind="{ sidebarItems }" />

    <template v-if="$pageHeader">
      <div class="giscus theme-default-content" />
      <script
        src="https://giscus.app/client.js"
        data-repo="ethlibrary/EIPS"
        data-repo-id="R_kgDOGMqduA"
        data-category="Announcements"
        data-category-id="DIC_kwDOGMqduM4CAU6x"
        data-mapping="url"
        data-reactions-enabled="1"
        data-emit-metadata="0"
        data-theme="preferred_color_scheme"
        data-lang="zh-CN"
        crossorigin="anonymous"
        async
      ></script>
    </template>

    <a
      class="vercel"
      href="https://vercel.com?utm_source=ethlibrary&utm_campaign=oss"
      target="_blank"
    >▲ Powered by Vercel</a>
    <slot name="bottom" />
  </main>
</template>

<script>
import PageEdit from '@theme/components/PageEdit.vue'
import PageNav from '@theme/components/PageNav.vue'

export default {
  components: { PageEdit, PageNav },
  props: ['sidebarItems'],
}
</script>

<style lang="stylus">
@require '../styles/wrapper.styl'

.page
  padding-bottom 2rem
  display block

.page-title 
  margin-bottom: -4rem !important;
  margin-top: 2rem !important;

.vercel
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ccc;

.vercel:hover
  color: #000;
</style>
