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
        title: 'All EIPs',
        path: '/all',
        collapsable: false,
      },
      {
        title: 'Status',
        collapsable: false,
        children: [
          ['/draft', 'Draft'],
          ['/review', 'Review'],
          ['/lastCall', 'Last Call'],
          ['/accepted', 'Accepted'],
          ['/final_and_living', 'Final and Living'],
        ],
      },
      {
        title: 'Type',
        collapsable: false,
        children: [
          ['/core', 'Core (165)'],
          ['/networking', 'Networking (11)'],
          ['/interface', 'Interface (38)'],
          ['/erc', 'ERC (153)'],
          ['/meta', 'Meta (18)'],
          ['/informational', 'Informational (6)'],
        ],
      },
    ],
  },
}
