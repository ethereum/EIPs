const yamlHeaderParser = require('yaml-front-matter')
const tablemark = require('tablemark')
const { format } = require('date-fns')
const fs = require('fs')
const path = require('path')
const _ = require('lodash')
const { en, zh } = require('./locales')

const allEipFiles = fs
  .readdirSync(path.resolve(__dirname, '../'))
  .filter(file => file.includes('eip'))

const metas = allEipFiles.map(file => {
  const meta = yamlHeaderParser.loadFront(
    fs.readFileSync(`${__dirname}/../${file}`, 'utf8')
  )
  delete meta.__content
  const filename = path.parse(file).name
  return {
    ...meta,
    filename,
    // eip: `[${meta.eip}](./${filename})`,
    created: meta.created ? format(new Date(meta.created), 'yyyy-MM-dd') : '-',
  }
})

const EIP_STATUS = _.groupBy(metas, 'status')
const EIP_CATE = _.groupBy(metas, 'category')
const EIP_TYPE = _.groupBy(metas, 'type')

const getSummaryPath = (item, lang) => {
  let root
  if (typeof lang === 'undefined') {
    root = '/'
  } else {
    root = lang === 'en' ? '/' : `/${lang}/`
  }

  return `${root}summary/${item
    .split(' ')
    .join('-')
    .toLowerCase()}`
}

const getSidebarChildren = (arr, locale) => {
  return Object.keys(arr)
    .filter(k => k !== 'undefined')
    .map(item => [
      getSummaryPath(item, locale.language),
      `${locale[item]} (${arr[item].length})`,
    ])
}

const genSummary = (summary, locale) => {
  const keys = Object.keys(summary).filter(k => k !== 'undefined')

  keys.map(key => {
    const content = _.sortBy(summary[key], 'eip').map(s => {
      return {
        eip: `[${s.eip}](/${s.filename})`,
        title: s.title,
        created: s.created,
        status: s.status,
        category: s.category,
        type: s.type,
      }
    })
    const tableJSON = tablemark(content)
    const markdown = `
# Ethereum EIPs: ${key} (${content.length})
---
${tableJSON}
    `
    fs.writeFileSync(
      path.resolve(__dirname, `..${getSummaryPath(key, locale.language)}.md`),
      markdown
    )
  })
}
genSummary(EIP_STATUS, en)
genSummary(EIP_STATUS, zh)
genSummary(EIP_TYPE, en)
genSummary(EIP_TYPE, zh)
genSummary(EIP_CATE, en)
genSummary(EIP_CATE, zh)

const getSidebar = locale => {
  return [
    {
      title: locale.allListSubTitle,
      path: '/',
      collapsable: false,
    },
    {
      title: locale.eipsByStatus,
      collapsable: false,
      children: getSidebarChildren(EIP_STATUS, locale),
    },
    {
      title: locale.eipsByTypes,
      collapsable: false,
      children: getSidebarChildren(EIP_TYPE, locale),
    },
    {
      title: locale.eipsByCategory,
      collapsable: false,
      children: getSidebarChildren(EIP_CATE, locale),
    },
  ]
}

var a = (module.exports = {
  locales: {
    '/': {
      lang: 'en-US', // 将会被设置为 <html> 的 lang 属性
      title: en.siteTitle,
      description: en.siteDescription,
    },
    '/zh/': {
      lang: 'zh-CN',
      title: zh.siteTitle,
      description: zh.siteDescription,
    },
  },
  ga: '',
  markdown: {
    lineNumbers: true,
  },

  themeConfig: {
    repo: 'ethlibrary/EIPs',
    docsDir: 'EIPS',
    lastUpdated: true,
    editLinks: true,
    smoothScroll: true,
    algolia: {
      apiKey: '',
      indexName: '',
      debug: false,
    },
    locales: {
      '/': {
        label: 'English',
        selectText: 'Languages',
        ariaLabel: 'Select language',
        editLinkText: 'Edit this page on GitHub',
        lastUpdated: 'Last Updated',
        nav: [{ text: en.aboutUs, link: 'https://ethlibrary.io' }],
        sidebar: {
          '/': getSidebar(en),
        },
      },
      '/zh/': {
        label: '简体中文',
        selectText: '选择语言',
        ariaLabel: '选择语言',
        editLinkText: '在 GitHub 上帮助翻译此文档',
        lastUpdated: '上次更新',
        nav: [{ text: zh.aboutUs, link: 'https://ethlibrary.io' }],
        sidebar: {
          '/zh/': getSidebar(zh),
        },
      },
    },
  },
})
