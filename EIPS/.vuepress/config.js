const yamlHeaderParser = require('yaml-front-matter')
const tablemark = require('tablemark')
const { format } = require('date-fns')
const fs = require('fs')
const path = require('path')
const _ = require('lodash')
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

const getSummaryPath = item =>
  `/summary/${item
    .split(' ')
    .join('-')
    .toLowerCase()}`

const getSidebarChildren = arr => {
  return Object.keys(arr)
    .filter(k => k !== 'undefined')
    .map(item => [getSummaryPath(item), `${item} (${arr[item].length})`])
}

const genSummary = summary => {
  const keys = Object.keys(summary).filter(k => k !== 'undefined')
  keys.map(key => {
    const content = _.sortBy(summary[key], 'eip').map(s => {
      return {
        eip: `[${s.eip}](./${s.filename})`,
        title: s.title,
        created: s.created,
        status: s.status,
        category: s.category,
        type: s.type,
      }
    })
    const tableJSON = tablemark(content)
    const markdown = `
# ${key} (${content.length})
---
${tableJSON}
    `
    fs.writeFileSync(
      path.resolve(__dirname, `../${getSummaryPath(key)}.md`),
      markdown
    )
  })
}
genSummary(EIP_STATUS)
genSummary(EIP_TYPE)
genSummary(EIP_CATE)

module.exports = {
  title: '以太坊改进提案 EIPs',
  description:
    '以太坊改进提案（EIPs）描述了以太坊平台的标准，包括核心协议规范，客户端API和合约标准。',
  ga: '',
  markdown: {
    lineNumbers: true,
  },

  themeConfig: {
    repo: 'ethlibrary/EIPs',
    editLinks: true,
    docsDir: 'EIPS',
    docsBranch: 'master',
    editLinkText: '帮助完善文档',
    lastUpdated: true,
    algolia: {
      apiKey: '',
      indexName: '',
      debug: false,
    },
    nav: [{ text: 'About us', link: 'https://ethlibrary.io' }],
    sidebar: [
      {
        title: 'All EIPs List',
        path: '/summary/all',
        collapsable: false,
      },
      {
        title: 'EIPs by Status',
        collapsable: false,
        children: getSidebarChildren(EIP_STATUS),
      },
      {
        title: 'EIPs by Types',
        collapsable: false,
        children: getSidebarChildren(EIP_TYPE),
      },
      {
        title: 'EIPs by Category',
        collapsable: false,
        children: getSidebarChildren(EIP_CATE),
      },
    ],
  },
}
