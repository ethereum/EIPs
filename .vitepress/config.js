let debug = true;

export default {
    title: 'Ethereum Improvement Proposals',
    description: 'Ethereum Improvement Proposals (EIPs) describe standards for the Ethereum platform, including core protocol specifications, client APIs, and contract standards.',
    cleanUrls: true,
    base: '/',
    themeConfig: {
        repo: 'ethereum/EIPs',
        docsDir: 'EIPS',
        docsBranch: 'master',
        editLinks: true,
        editLinkText: 'Edit this page on GitHub',
        lastUpdated: 'Last Updated',
        nav: [
            { text: 'Home', link: '/' },
            { text: 'EIPs', link: '/eips/' },
        ],
    },
    appearance: true,
    titleTemplate: false,
    async transformHead({ siteConfig, siteData, pageData, title, description, head, content }) {
        if (debug) {
            console.log('siteConfig', siteConfig);
            console.log('siteData', siteData);
            console.log('pageData', pageData);
            console.log('title', title);
            console.log('description', description);
            debug = false;
        }
    }
}
