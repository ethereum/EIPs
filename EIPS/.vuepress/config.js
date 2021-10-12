const yamlHeaderParser = require('yaml-front-matter')
const fs = require('fs')
const path = require('path')
const allEipFiles = fs
  .readdirSync(path.resolve(__dirname, '../'))
  .filter(file => file.includes('eip'))

const EIP_STATUS = {}
const EIP_TYPE = {}
const EIP_CATE = {}

allEipFiles.map(file => {
  const meta = yamlHeaderParser.loadFront(
    fs.readFileSync(`${__dirname}/../${file}`, 'utf8')
  )
  if (meta.status) {
    EIP_STATUS[meta.status] = (EIP_STATUS[meta.status] || 0) + 1
  }
  if (meta.type) {
    EIP_TYPE[meta.type] = (EIP_TYPE[meta.type] || 0) + 1
  }
  if (meta.category) {
    EIP_CATE[meta.category] = (EIP_CATE[meta.category] || 0) + 1
  }
})

const getSidebarChildren = arr => {
  return Object.keys(arr).map(item => [
    `/summary/${item
      .split(' ')
      .join('-')
      .toLowerCase()}`,
    `${item} (${arr[item]})`,
  ])
}

console.log(getSidebarChildren(EIP_STATUS))
console.log(getSidebarChildren(EIP_TYPE))
console.log(getSidebarChildren(EIP_CATE))

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
