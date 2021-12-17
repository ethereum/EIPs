# 以太坊改进提案（中文翻译） (EIPs)

以太坊改进提案（Ethereum Improvement Proposals (EIPs)）描述了以太坊的标准化改进，包括核心协议、规范、客户端 API 接口和合约标准。更多关于 EIPS 的概念，请参见 [以太坊中文官网描述](https://ethereum.org/zh/eips/)。

本项目是由 [EIPs 英文官方仓库](https://github.com/ethereum/EIPs) 翻译而来，后续版本将会持续和英文版本保持一致更新。

查看所有 EIPs 中文翻译：<https://eips.ethlibrary.io/zh>


## 参与贡献翻译

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

<a href="https://vercel.com?utm_source=ethlibrary&utm_campaign=oss"><img src="https://www.datocms-assets.com/31049/1618983297-powered-by-vercel.svg" /></a>