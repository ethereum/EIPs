export default ({ Vue }) => {
  Vue.mixin({
    computed: {
      $pageHeader() {
        const frontmatter = this.$page.frontmatter
        const { eip, title, home } = frontmatter
        const pageHeader = home ? '' : `EIP${eip} - ${title}`
        return pageHeader
      },
      $title() {
        return this.$pageHeader
          ? `${this.$pageHeader} | ${this.$siteTitle}`
          : this.$siteTitle
      },
    },
  })
}
