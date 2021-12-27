# 以太坊改进提案（中文翻译） (EIPs)

以太坊改进提案（Ethereum Improvement Proposals (EIPs)）描述了以太坊的标准化改进，包括核心协议、规范、客户端 API 接口和合约标准。更多关于 EIPS 的概念，请参见 [以太坊中文官网描述](https://ethereum.org/zh/eips/)。

本项目是由 [EIPs 英文官方仓库](https://github.com/ethereum/EIPs) 翻译而来，后续版本将会持续和英文版本保持一致更新。

查看所有 EIPs 中文翻译：<https://eips.ethlibrary.io/zh>

## 推荐翻译

以太坊升级当前已经转变到以 EIP 为中心，我们建议优先翻译以下硬分叉相关的 EIP。

### Ethereum Protocol Releases

| 硬分叉升级 | 区块高度 | 硬分叉时间 | 包含的 EIPs | Specs | 博客 |
|-----------------------|-----------|----------|-----------|-------|-------|
| Arrow Glacier | 13773000 | 2021-12-09 | [EIP-4345](https://eips.ethereum.org/EIPS/eip-4345) | [Specification](./network-upgrades/mainnet-upgrades/arrow-glacier.md) | [Blog](https://blog.ethereum.org/2021/11/10/arrow-glacier-announcement/) |
| London | 12965000 |  2021-08-05 | [EIP-1559](https://eips.ethereum.org/EIPS/eip-1559) <br> [EIP-3198](https://eips.ethereum.org/EIPS/eip-3198) <br/> [EIP-3529](https://eips.ethereum.org/EIPS/eip-3529) <br/> [EIP-3541](https://eips.ethereum.org/EIPS/eip-3541) <br> [EIP-3554](https://eips.ethereum.org/EIPS/eip-3554)| [Specification](https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/london.md) | [Blog](https://blog.ethereum.org/2021/07/15/london-mainnet-announcement/) |
| Berlin | 12244000 | 2021-04-15 | [EIP-2565](https://eips.ethereum.org/EIPS/eip-2565) <br/> [EIP-2929](https://eips.ethereum.org/EIPS/eip-2929) <br/> [EIP-2718](https://eips.ethereum.org/EIPS/eip-2718) <br/> [EIP-2930](https://eips.ethereum.org/EIPS/eip-2930) | ~[HFM-2070](https://eips.ethereum.org/EIPS/eip-2070)~ <br/> [Specification](https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/berlin.md) | [Blog](https://blog.ethereum.org/2021/03/08/ethereum-berlin-upgrade-announcement/) |
| Muir Glacier | 9200000 | 2020-01-02 | [EIP-2384](https://eips.ethereum.org/EIPS/eip-2384) | [HFM-2387](https://eips.ethereum.org/EIPS/eip-2387) | [Blog](https://blog.ethereum.org/2019/12/23/ethereum-muir-glacier-upgrade-announcement/) |
| Istanbul | 9069000 | 2019-12-07 | [EIP-152](https://eips.ethereum.org/EIPS/eip-152) <br/> [EIP-1108](https://eips.ethereum.org/EIPS/eip-1108) <br/> [EIP-1344](https://eips.ethereum.org/EIPS/eip-1344) <br/> [EIP-1884](https://eips.ethereum.org/EIPS/eip-1884) <br/> [EIP-2028](https://eips.ethereum.org/EIPS/eip-2028) <br/> [EIP-2200](https://eips.ethereum.org/EIPS/eip-2200) | [HFM-1679](https://eips.ethereum.org/EIPS/eip-1679) | [Blog](https://blog.ethereum.org/2019/11/20/ethereum-istanbul-upgrade-announcement/)
| Petersburg | 7280000 | 2019-02-28 | [EIP-145](https://eips.ethereum.org/EIPS/eip-145) <br/> [EIP-1014](https://eips.ethereum.org/EIPS/eip-1014) <br/> [EIP-1052](https://eips.ethereum.org/EIPS/eip-1052) <br/> [EIP-1234](https://eips.ethereum.org/EIPS/eip-1234) | [HFM-1716](https://eips.ethereum.org/EIPS/eip-1716) | [Blog](https://blog.ethereum.org/2019/02/22/ethereum-constantinople-st-petersburg-upgrade-announcement/) |
| Constantinople | 7280000 | 2019-02-28 | [EIP-145](https://eips.ethereum.org/EIPS/eip-145) <br/> [EIP-1014](https://eips.ethereum.org/EIPS/eip-1014) <br/> [EIP-1052](https://eips.ethereum.org/EIPS/eip-1052) <br/> [EIP-1234](https://eips.ethereum.org/EIPS/eip-1234) <br/> [EIP-1283](https://eips.ethereum.org/EIPS/eip-1283) | [HFM-1013](https://eips.ethereum.org/EIPS/eip-1013) | [Blog](https://blog.ethereum.org/2019/02/22/ethereum-constantinople-st-petersburg-upgrade-announcement/) |
| Byzantium | 4370000 | 2017-10-16 | [EIP-100](https://eips.ethereum.org/EIPS/eip-100) <br/> [EIP-140](https://eips.ethereum.org/EIPS/eip-140) <br/> [EIP-196](https://eips.ethereum.org/EIPS/eip-196) <br/> [EIP-197](https://eips.ethereum.org/EIPS/eip-197) <br/> [EIP-198](https://eips.ethereum.org/EIPS/eip-198) <br/> [EIP-211](https://eips.ethereum.org/EIPS/eip-211) <br/> [EIP-214](https://eips.ethereum.org/EIPS/eip-214) <br/> [EIP-649](https://eips.ethereum.org/EIPS/eip-649) <br/> [EIP-658](https://eips.ethereum.org/EIPS/eip-658) | [HFM-609](https://eips.ethereum.org/EIPS/eip-609) | [Blog](https://blog.ethereum.org/2017/10/12/byzantium-hf-announcement/) |
| Spurious Dragon | 2675000 | 2016-11-22 | [EIP-155](https://eips.ethereum.org/EIPS/eip-155) <br/> [EIP-160](https://eips.ethereum.org/EIPS/eip-160) <br/> [EIP-161](https://eips.ethereum.org/EIPS/eip-161) <br/> [EIP-170](https://eips.ethereum.org/EIPS/eip-170) | [HFM-607](https://eips.ethereum.org/EIPS/eip-607) | [Blog](https://blog.ethereum.org/2016/11/18/hard-fork-no-4-spurious-dragon/) |
| Tangerine Whistle | 2463000 | 2016-10-18 | [EIP-150](https://eips.ethereum.org/EIPS/eip-150) | [HFM-608](https://eips.ethereum.org/EIPS/eip-608) | [Blog](https://blog.ethereum.org/2016/10/13/announcement-imminent-hard-fork-eip150-gas-cost-changes/) |
| DAO Fork | 1920000 | 2016-07-20 |  | [HFM-779](https://eips.ethereum.org/EIPS/eip-779) | [Blog](https://blog.ethereum.org/2016/07/15/to-fork-or-not-to-fork/) |
| DAO Wars | aborted | aborted |  |  | [Blog](https://blog.ethereum.org/2016/06/24/dao-wars-youre-voice-soft-fork-dilemma/) |
| Homestead | 1150000 | 2016-03-14 | [EIP-2](https://eips.ethereum.org/EIPS/eip-2) <br/> [EIP-7](https://eips.ethereum.org/EIPS/eip-7) <br/> [EIP-8](https://eips.ethereum.org/EIPS/eip-8) | [HFM-606](https://eips.ethereum.org/EIPS/eip-606) | [Blog](https://blog.ethereum.org/2016/02/29/homestead-release/) |
| Frontier Thawing | 200000 | 2015-09-07 | | | [Blog](https://blog.ethereum.org/2015/08/04/the-thawing-frontier/) |
| Frontier | 1 | 2015-07-30 | | | [Blog](https://blog.ethereum.org/2015/07/22/frontier-is-coming-what-to-expect-and-how-to-prepare/) |


## 翻译资源

请查看：
- [区块链术语的翻译对照 - by EthFans](https://github.com/editor-Ajian/List-of-translation-of-crypto-terms-by-EthFans/blob/under-finalized/Blockchain%20and%20Ethereum%20Terminology.md)
- [EIPs 中文新手翻译指南](https://github.com/ethlibrary/EIPs/wiki/EIPs-%E4%B8%AD%E6%96%87%E6%96%B0%E6%89%8B%E7%BF%BB%E8%AF%91%E6%8C%87%E5%8D%97)。


## 本地运行

如果你只参与翻译，可以忽略以下内容。

如果你需要在你本地预览所有页面，或者自己部署在服务器上，你可以参考以下步骤：

## 安装

1. 打开终端

2. 检查是否已经安装了 `node` 和 `yarn`:

```sh
$ node -v

$ yarn -v
```

3. 如果没有安装 `node`，请到 [安装页面](https://nodejs.org/en/) 下载并安装。
   如果没有安装 `yarn`, 请到 [安装页面](https://yarnpkg.com/lang/en/docs/install/) 下载并安装。

5. 安装项目依赖:

```sh
$ yarn
```

## 本地运行

1. 执行 `yarn run dev` 命令开启本地服务器。

```sh
$ yarn run dev
```

2. 在你的浏览器里访问 `http://localhost:8000`，进行预览

## 打包构建

```sh
$ yarn run build
```



<p align="center"><a href="https://vercel.com?utm_source=ethlibrary&utm_campaign=oss" align="center"><img src="https://www.datocms-assets.com/31049/1618983297-powered-by-vercel.svg" /></a></p>
