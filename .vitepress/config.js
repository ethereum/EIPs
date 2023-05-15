import fs from 'node:fs/promises';

import { createLogger } from 'vite-logger';
import { Feed } from 'feed';
import { withPwa } from '@vite-pwa/vitepress';
import { defineConfig } from 'vitepress';

import { fetchEips, filenameToEipNumber } from './parser';

const logger = createLogger('info', true);

logger.info('Fetching EIPs', { timestamp: true });
const eips = await fetchEips();
logger.info('Fetched EIPs', { timestamp: true });

async function copyDirectory(from, to) {
    // Recursively copy a directory, without overwriting existing files
    // Uses fs.constants.COPYFILE_EXCL to avoid overwriting files
    await fs.mkdir(to, { recursive: true });
    let files = await fs.readdir(from);
    for (let file of files) {
        let current = await fs.lstat(`${from}/${file}`);
        if (current.isDirectory()) {
            await copyDirectory(`${from}/${file}`, `${to}/${file}`);
        } else {
            try {
                await fs.copyFile(`${from}/${file}`, `${to}/${file}`, fs.constants.COPYFILE_EXCL);
            } catch (e) {
                if (e.code !== 'EEXIST') {
                    throw e; // If the error isn't because the file already exists, throw it
                }
            }
        }
    }
}

export default withPwa(defineConfig({
    title: 'Ethereum Improvement Proposals',
    description: 'Ethereum Improvement Proposals (EIPs) describe standards for the Ethereum platform, including core protocol specifications, client APIs, and contract standards.',
    cleanUrls: true,
    base: '/',
    themeConfig: {
        logo: '/assets/website/ethereum-logo.svg',
        outline: 'deep',
        editLink: {
          pattern: 'https://github.com/ethereum/EIPs/edit/main/docs/:path',
          text: 'Edit this page on GitHub'
        },
        lastUpdatedText: 'Last Updated',
        nav: [
            { text: 'All', link: '/all' },
            { text: 'Core', link: '/core' },
            { text: 'Networking', link: '/networking' },
            { text: 'Interface', link: '/interface' },
            { text: 'ERC', link: '/erc' },
            { text: 'Meta', link: '/meta' },
            { text: 'Informational', link: '/informational' }
        ],
    },
    head: [
        [ 'meta', { charset: 'utf-8' } ],
        [ 'meta', { name: 'viewport', content: 'width=device-width,initial-scale=1' } ],
        [ 'meta', { 'http-equiv': 'X-UA-Compatible', content: 'IE=edge,chrome=1' } ],
        [ 'meta', { name: 'Content-Type', content: 'text/html; charset=utf-8' } ],
        [ 'meta', { name: 'robots', content: 'index, follow' } ],
        [ 'meta', { name: 'google-site-verification', content: 'WS13rn9--86Zk6QAyoGH7WROxbaJWafZdaPlecJVGSo' } ], // Gives @Pandapip1 limited access (analytics & re-indexing) to Google Search Console; access can be revoked at any time by removing this line
        [ 'link', { rel: 'apple-touch-icon', sizes: '180x180', href: '/assets/website/apple-touch-icon.png' } ],
        [ 'link', { rel: 'icon', type: 'image/png', sizes: '32x32', href: '/assets/website/favicon-32x32.png' } ],
        [ 'link', { rel: 'icon', type: 'image/png', sizes: '16x16', href: '/assets/website/favicon-16x16.png' } ],
        [ 'link', { rel: 'mask-icon', href: '/assets/website/safari-pinned-tab.svg', color: '#5bbad5' } ],
        [ 'link', { rel: 'shortcut icon', href: '/assets/website/favicon.ico' } ],
        [ 'meta', { name: 'apple-mobile-web-app-title', content: 'Ethereum Improvement Proposals' } ],
        [ 'meta', { name: 'application-name', content: 'Ethereum Improvement Proposals' } ],
        [ 'meta', { name: 'msapplication-TileColor', content: '#da532c' } ],
        [ 'meta', { name: 'msapplication-config', content: '/assets/website/browserconfig.xml' } ],
        [ 'meta', { name: 'theme-color', content: '#ffffff' } ]
    ],
    appearance: true,
    titleTemplate: false,
    lastUpdated: true,
    async transformHead({ siteConfig, siteData, pageData, title, description, head, content }) {
        try { // Custom error handling needed because of the way VitePress handles errors (i.e. it doesn't)
            if (pageData.relativePath.match(/EIPS\/eip-\w+\.md/)) {
                logger.info(`Generating Metadata for ${pageData.relativePath}`);
                
                let eipN = filenameToEipNumber(pageData.relativePath.split('/')[1]);
                let frontmatter = eips.find(eip => eip.eip === eipN);
                if (!frontmatter) {
                    throw new Error(`EIP ${eipN} not found`);
                }
    
                return [
                    // Regular Metadata
                    [ 'title', {}, eipTitle ]
                    [ 'meta', { name: 'description', content: pageData.description }],
                    [ 'link', { rel: 'canonical', href: `https://eips.ethereum.org/${pageData.relativePath}` } ],
                    ...authors.map(author => [ 'meta', { name: 'author', content: author.name } ]),
                    [ 'meta', { name: 'date', content: frontmatter.created.replace('-', '/') } ],
                    [ 'meta', { name: 'copyright', content: 'CC0 1.0 Universal (Public Domain)' } ],
                    // Open Graph
                    [ 'meta', { property: 'og:title', content: eipTitle } ],
                    [ 'meta', { property: 'og:description', content: pageData.description } ],
                    [ 'meta', { property: 'og:url', content: `https://eips.ethereum.org/${pageData.relativePath}` } ],
                    [ 'meta', { property: 'og:locale', content: 'en_US' } ],
                    [ 'meta', { property: 'og:site_name', content: siteData.title } ],
                    [ 'meta', { property: 'og:type', content: 'article' } ],
                    // Twitter
                    [ 'meta', { name: 'twitter:card', content: 'summary' } ],
                    [ 'meta', { name: 'twitter:site_name', content: siteData.title } ],
                    [ 'meta', { name: 'twitter:site', content: '@ethereum' } ], // TODO: Replace with EIPs Twitter account, if one exists
                    [ 'meta', { name: 'twitter:description', content: pageData.description } ],
                    // Dublin Core
                    [ 'meta', { name: 'DC.title', content: eipTitle } ],
                    ...authors.map(author => [ 'meta', { name: 'DC.creator', content: author.name } ]),
                    [ 'meta', { name: 'DC.date', content: frontmatter.createdSlashSeperated } ],
                    frontmatter.finalized ? [ 'meta', { name: 'DC.issued', content: frontmatter.finalizedSlashSeperated } ] : [],
                    [ 'meta', { name: 'DC.format', content: 'text/html' } ],
                    [ 'meta', { name: 'DC.language', content: 'en-US' } ],
                    [ 'meta', { name: 'DC.publisher', content: siteData.title } ],
                    [ 'meta', { name: 'DC.rights', content: 'CC0 1.0 Universal (Public Domain)' } ],
                    // Citation
                    [ 'meta', { name: 'citation_title', content: eipTitle } ],
                    ...authors.map(author => [ 'meta', { name: 'citation_author', content: author.name } ]),
                    [ 'meta', { name: 'citation_online_date', content: frontmatter.createdSlashSeperated } ],
                    frontmatter.finalized ? [ 'meta', { name: 'citation_publication_date', content: frontmatter.finalizedSlashSeperated } ] : [],
                    [ 'meta', { name: 'citation_technical_report_institution', content: siteData.title } ],
                    [ 'meta', { name: 'citation_technical_report_number', content: frontmatter.eip } ],
                    // LD+JSON
                    [ 'script', { type: 'application/ld+json' }, JSON.stringify({
                        '@type': 'WebSite',
                        'url': `https://eips.ethereum.org/${pageData.relativePath}`,
                        'name': eipTitle,
                        'description': pageData.description,
                        '@context': 'https://schema.org'
                    })]
                ].filter(x => x?.length);
            } else {
                return [];
            }
        } catch (error) {
            logger.error(error);
            throw error;
        }
    },
    async transformPageData(pageData) {
        try { // Custom error handling needed because of the way VitePress handles runtime errors (i.e. it doesn't)
            logger.info(`Transforming ${pageData.relativePath}`, { timestamp: true });

            if (pageData.relativePath.match(/EIPS\/eip-\w+\.md/)) {
                pageData = { ...pageData };
                let eipN = filenameToEipNumber(pageData.relativePath.split('/')[1]);
                pageData.frontmatter = eips.find(eip => eip.eip === eipN);

                if (!pageData.frontmatter) {
                    throw new Error(`EIP ${eipN} not found`);
                }

                logger.info(`Transformed ${pageData.relativePath} (EIP)`, { timestamp: true });
                return pageData;
            } else if (pageData.frontmatter.listing) {
                pageData = { ...pageData };
                if (pageData.filter !== undefined) {
                    pageData.frontmatter.filteredEips = eips.filter(eip => {
                        return Object.keys(pageData.frontmatter.filter).every(key => pageData.frontmatter.filter[key].includes(eip[key]));
                    }).map(eip => {
                        return {
                            eip: eip.eip,
                            title: eip.title,
                            status: eip.status,
                            authorData: eip.authorData,
                        };
                    });
                    logger.info(`Transformed ${pageData.relativePath} (listing page)`, { timestamp: true });
                } else {
                    // Inject all EIPs into the search page (only a subset of the data is searchable)
                    pageData.frontmatter.allEips = eips.map(eip => {
                        return {
                            eip: eip.eip,
                            title: eip.title,
                            wrongTitle: eip.wrongTitle,
                            status: eip.status,
                            type: eip.type,
                            category: eip.category,
                            authors: eip.authors,
                            created: eip.created,
                        };
                    });
                    logger.info(`Transformed ${pageData.relativePath} (search page)`, { timestamp: true });
                }

                return pageData;
            } else {
                logger.info(`Transformed ${pageData.relativePath} (No special effects)`, { timestamp: true });

                return pageData;
            }
        } catch (e) {
            logger.error(`Error transforming ${pageData.relativePath}`, { timestamp: true });
            logger.error(e, { timestamp: true });
            throw e;
        }
    },
    async buildEnd(siteConfig) {
        logger.info('Making feeds');

        const url = 'https://eips.ethereum.org';

        try {
            const feed = new Feed({
                title: feedConfig[feedName].title,
                description: feedConfig[feedName].description,
                id: `${url}/rss/${feedName}.xml`,
                link: `${url}/rss/${feedName}.xml`,
                language: 'en',
                image: `${url}/assets/website/favicon-32x32.png`,
                favicon: `${url}/favicon.ico`,
                copyright: 'CC0 1.0 Universal (Public Domain)',
            });

            for (let eip in eips) {
                let eipData = eips[eip];

                let skip = false;

                for (let key of Object.keys(filter)) {
                    if (filter[key] && !filter[key](eipData[key])) {
                        skip = true;
                        break;
                    }
                }

                if (skip) {
                    continue;
                }
                feed.addItem({
                    title: eipData.title,
                    id: `${url}/EIPS/eip-${eip}`,
                    link: `${url}/EIPS/eip-${eip}`,
                    date: eipData.lastStatusChange,
                    description: eipData.description,
                    author: parseAuthorData(eipData.authors).map(author => author.name),
                    category: [
                        {
                            name: eipData.category ?? eipData.type,
                            term: eipData.category ?? eipData.type,
                            scheme: `${url}/category`,
                            domain: `${url}/category`
                        },
                        {
                            name: eipData.status,
                            term: eipData.status,
                            scheme: `${url}/status`,
                            domain: `${url}/status`
                        }
                    ],
                    content: eipData.content,
                    guid: eip,
                });
            }

            // Export the feed
            await fs.writeFile(`./.vitepress/dist/eips-rss.xml`, feed.rss2());
            await fs.writeFile(`./.vitepress/dist/eips.atom`, feed.atom1());

            logger.info(`Finished making \`${feedName}\` feed`);
        } catch (e) {
            logger.error(e);
            throw e;
        }

        // Copy ALL the assets
        logger.info('Copying assets');
        await copyDirectory('./assets', './.vitepress/dist/assets');
    },
    pwa: {
        injectRegister: 'script',
        workbox: {
            globPatterns: ['EIPS/*', '**/*.{js,css,html}'] // Items to save to offline cache
        },
        manifest: {
            "name": "Ethereum Improvement Proposals",
            "short_name": "EIPs",
            "description": "Ethereum Improvement Proposals (EIPs) describe standards for the Ethereum platform, including core protocol specifications, client APIs, and contract standards.",
            "icons": [
                {
                    "src": "/assets/website/android-chrome-192x192.png",
                    "sizes": "192x192",
                    "type": "image/png"
                },
                {
                    "src": "/assets/website/android-chrome-512x512.png",
                    "sizes": "512x512",
                    "type": "image/png"
                }
            ],
            "theme_color": "#ffffff",
            "background_color": "#ffffff",
            "display": "standalone"
        }
    }
}));
