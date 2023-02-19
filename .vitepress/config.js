import simpleGit from 'simple-git';
import fs from 'fs';
import grayMatter from 'gray-matter';
import { createLogger } from 'vite-logger';
import { Feed } from 'feed';

import feedConfig from './feeds.js';

const git = simpleGit();

const logger = createLogger('info', true);

const statuses = [ 'Living', 'Last Call', 'Final', 'Review', 'Draft', 'Withdrawn', 'Stagnant' ]
const eips = Promise.all(fs.readdirSync('./EIPS/').map(async file => {
    let eipContent = fs.readFileSync(`./EIPS/${file}`, 'utf8');
    let eipData = grayMatter(eipContent);
    let lastStatusChange = new Date((await git.raw(['blame', `EIPS/${file}`])).split('\n').filter(line => line.match(/status:/gi))?.pop()?.match(/(?<=\s)\d+-\d+-\d+/g)?.pop());
    return { ...eipData.data, lastStatusChange };
})).then(res => res.sort((a, b) => a.eip - b.eip));

function formatDateString(date) {
    return date.toISOString().split('T')[0];
}

export default {
    title: 'Ethereum Improvement Proposals',
    description: 'Ethereum Improvement Proposals (EIPs) describe standards for the Ethereum platform, including core protocol specifications, client APIs, and contract standards.',
    cleanUrls: true,
    base: '/',
    themeConfig: {
        logo: '/assets/images/ethereum-logo.svg',
        repo: 'ethereum/EIPs',
        docsDir: 'EIPS',
        docsBranch: 'master',
        editLinks: true,
        editLinkText: 'Edit this page on GitHub',
        lastUpdated: 'Last Updated',
        nav: [
            { text: 'Home', link: '/' },
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
        [ 'link', { rel: 'icon', type: 'image/svg', href: '/assets/images/ethereum-logo.svg' } ]
    ],
    appearance: true,
    titleTemplate: false,
    lastUpdated: true,
    async transformHead({ siteConfig, siteData, pageData, title, description, head, content }) {
        try { // Custom error handling needed because of the way VitePress handles errors (i.e. it doesn't)
            let { frontmatter } = pageData;
            if (frontmatter.eip) {
                logger.info(`Generating Metadata for ${pageData.relativePath}`);
    
                let eipPrefix = frontmatter?.category === 'ERC' ? 'ERC-' : 'EIP-';
                let eipTitle = `${eipPrefix}${frontmatter.eip}: ${frontmatter.title}`;
                let authors = frontmatter.author.match(/(?<=^|,\s*)[^\s]([^,"]|".*")+(?=(?:$|,))/g).map(author => author.match(/(?<![(<].*)[^\s(<][^(<]*\w/g)[0]);
    
                return [
                    // Regular Metadata
                    [ 'title', {}, eipTitle ]
                    [ 'meta', { name: 'description', content: pageData.description }],
                    [ 'link', { rel: 'canonical', href: `https://eips.ethereum.org/${pageData.relativePath}` } ],
                    ...authors.map(author => [ 'meta', { name: 'author', content: author } ]),
                    [ 'meta', { name: 'date', content: frontmatter.created.replace('-', '/') } ],
                    [ 'meta', { name: 'copyright', content: 'Public Domain' } ],
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
                    ...authors.map(author => [ 'meta', { name: 'DC.creator', content: author } ]),
                    [ 'meta', { name: 'DC.date', content: frontmatter.created.replace('-', '/') } ],
                    frontmatter.finalized ? [ 'meta', { name: 'DC.issued', content: frontmatter.finalized.replace('-', '/') } ] : [],
                    [ 'meta', { name: 'DC.format', content: 'text/html' } ],
                    [ 'meta', { name: 'DC.language', content: 'en-US' } ],
                    [ 'meta', { name: 'DC.publisher', content: siteData.title } ],
                    [ 'meta', { name: 'DC.rights', content: 'Public Domain' } ],
                    // Citation
                    [ 'meta', { name: 'citation_title', content: eipTitle } ],
                    ...authors.map(author => [ 'meta', { name: 'citation_author', content: author } ]),
                    [ 'meta', { name: 'citation_online_date', content: frontmatter.created.replace('-', '/') } ],
                    frontmatter.finalized ? [ 'meta', { name: 'citation_publication_date', content: frontmatter.finalized.replace('-', '/') } ] : [],
                    [ 'meta', { name: 'citation_technical_report_institution', content: siteData.title } ],
                    [ 'meta', { name: 'citation_technical_report_number', content: frontmatter.eip } ],
                    // LD+JSON
                    [ 'script', { type: 'application/ld+json' }, JSON.stringify({
                        '@type': 'WebSite',
                        'url': `https://eips.ethereum.org/${pageData.relativePath}`,
                        'name': eipTitle,
                        'description': pageData.description,
                        '@context': 'https://schema.org'
                    })],
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
            logger.info(`Transforming ${pageData.relativePath}`);
            
            pageData = { ...pageData };
            let { frontmatter } = pageData;

            if (frontmatter.eip) {
                // Try to read from cache
                try {
                    let cache = JSON.parse(fs.readFileSync(`./.vitepress/cache/eips/${frontmatter.eip}.json`));
                    frontmatter = { ...frontmatter, ...cache };
                } catch (e) {
                    logger.info(`Cache miss for ${pageData.relativePath}`);
                }
                // The below caused so much pain and suffering :|
                if (!frontmatter.created) {
                    let initial = new Date((await git.log(['--diff-filter=A', '--', pageData.relativePath])).latest.date); // Only one match, so this is fine to use latest
                    if (initial) {
                        frontmatter.created = formatDateString(initial);
                    }
                }
                if (!frontmatter.finalized && frontmatter.status === 'Final') {
                    let final = new Date((await git.raw(['blame', pageData.relativePath])).split('\n').filter(line => line.match(/status:\s+final/gi))?.pop()?.match(/(?<=\s)\d+-\d+-\d+/g)?.pop());
                    if (final) {
                        frontmatter.finalized = formatDateString(final);
                    }
                }
                if (frontmatter.created instanceof Date) {
                    frontmatter.created = formatDateString(frontmatter.created);
                }

                // Write to cache
                fs.mkdirSync('./.vitepress/cache/eips', { recursive: true });
                fs.writeFileSync(`./.vitepress/cache/eips/${frontmatter.eip}.json`, JSON.stringify({
                    created: frontmatter.created,
                    finalized: frontmatter.finalized,
                }));
            }
            if (frontmatter.listing) {
                frontmatter.eips = await eips;
                frontmatter.statuses = statuses;
            }
            
            logger.info(`Finished Transforming ${pageData.relativePath}`);

            pageData.frontmatter = frontmatter;
            return pageData;
        } catch (e) {
            logger.error(e);
            throw e;
        }
    },
    async buildEnd(siteConfig) {
        logger.info('Making feeds');

        const url = 'https://eips.ethereum.org';
        fs.mkdirSync('./.vitepress/dist/rss', { recursive: true });
        fs.mkdirSync('./.vitepress/dist/atom', { recursive: true });

        for (let feedName in feedConfig) {
            try {
                logger.info(`Making \`${feedName}\` feed`);
                const feed = new Feed({
                    title: feedConfig[feedName].title,
                    description: feedConfig[feedName].description,
                    id: `${url}/rss/${feedName}.xml`,
                    link: `${url}/rss/${feedName}.xml`,
                    language: 'en',
                    image: `${url}/assets/logo/favicon-32x32.png`,
                    favicon: `${url}/favicon.ico`,
                    copyright: 'Creative Commons Zero v1.0 Universal',
                });
                let { filter } = feedConfig[feedName];

                for (let eip in await eips) {
                    let eipData = (await eips)[eip];

                    let skip = false;

                    for (let key of Object.keys(filter)) {
                        if (filter[key] && !filter[key](eipData[key])) {
                            logger.info(`Skipping ${eip} in \`${feedName}\` because ${key} does not match filter`);
                            skip = true;
                            break;
                        }
                    }

                    if (skip) {
                        continue;
                    }
                    logger.info(`Adding ${eip} to feed \`${feedName}\``);
                    feed.addItem({
                        title: eipData.title,
                        id: `${url}/EIPS/eip-${eip}`,
                        link: `${url}/EIPS/eip-${eip}`,
                        date: eipData.lastStatusChange,
                        description: eipData.description,
                        //author: eipData.author.match(/(?<=^|,\s*)[^\s]([^,"]|".*")+(?=(?:$|,))/g).map(author => author.match(/(?<![(<].*)[^\s(<][^(<]*\w/g)[0]),
                        content: eipData.content,
                        guid: eip,
                    });
                }

                // Export the feed
                fs.writeFileSync(`./.vitepress/dist/rss/${feedName}.xml`, feed.rss2());
                fs.writeFileSync(`./.vitepress/dist/atom/${feedName}.atom`, feed.atom1());
            } catch (e) {
                logger.error(e);
                throw e;
            }
        }
    }
}
