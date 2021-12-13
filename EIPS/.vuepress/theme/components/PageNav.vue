<template>
  <div>
    <page-nav v-bind="$props" />
    <a
      class="vercel"
      href="https://vercel.com?utm_source=ethlibrary&utm_campaign=oss"
      target="_blank"
    >▲ Powered by Vercel</a>
  </div>
</template>

<script>
import PageNav from '@theme/components/PageNav.vue'
export default {
  // components: { PageNav },
}
</script>

<style>
.vercel {
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ccc;
}

.vercel:hover {
  color: #000;
}
</style>