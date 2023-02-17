import simpleGit from "simple-git";
import fs from 'fs';
import grayMatter from 'gray-matter';

const git = simpleGit();

const statuses = [ 'Living', 'Last Call', 'Final', 'Review', 'Draft', 'Withdrawn', 'Stagnant' ]
const eips = fs.readdirSync('./EIPS/').map(file => {
    let eipContent = fs.readFileSync(`./EIPS/${file}`, 'utf8');
    let eipData = grayMatter(eipContent);
    return eipData.data;
}).sort((a, b) => a.eip - b.eip);

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
        [ 'meta', { name: "google-site-verification", content: "WS13rn9--86Zk6QAyoGH7WROxbaJWafZdaPlecJVGSo" } ], // Gives @Pandapip1 limited access (analytics & re-indexing) to Google Search Console; access can be revoked at any time by removing this line
    ],
    appearance: true,
    titleTemplate: false,
    async transformHead({ siteConfig, siteData, pageData, title, description, head, content }) {
        let { frontmatter } = pageData;
        if (frontmatter.eip) {
            console.log(`\nGenerating Metadata for ${pageData.relativePath}\n`);

            let eipPrefix = frontmatter?.category === 'ERC' ? 'ERC-' : 'EIP-';
            let eipTitle = `${eipPrefix}${frontmatter.eip}: ${frontmatter.title}`;
            let authors = frontmatter.author.match(/(?<=^|,\s*)[^\s]([^,"]|".*")+(?=(?:$|,))/g).map(author => author.match(/(?<![(<].*)[^\s(<][^(<]*\w/g)[0]);

            return [
                // Regular Metadata
                [ 'title', {}, eipTitle ]
                [ 'meta', { name: 'description', content: description }],
                [ 'link', { rel: 'canonical', href: `https://eips.ethereum.org${pageData.path}` } ],
                ...authors.map(author => [ 'meta', { name: 'author', content: author } ]),
                [ 'meta', { name: 'date', content: frontmatter.created.replace("-", "/") } ],
                [ 'meta', { name: 'copyright', content: 'Public Domain' } ],
                // Open Graph
                [ 'meta', { property: 'og:title', content: eipTitle } ],
                [ 'meta', { property: 'og:description', content: description } ],
                [ 'meta', { property: 'og:url', content: `https://eips.ethereum.org${pageData.path}` } ],
                [ 'meta', { property: 'og:locale', content: 'en_US' } ],
                [ 'meta', { property: 'og:site_name', content: siteConfig.title } ],
                [ 'meta', { property: 'og:type', content: 'article' } ],
                // Twitter
                [ 'meta', { name: 'twitter:card', content: 'summary' } ],
                [ 'meta', { name: 'twitter:site_name', content: siteConfig.title } ],
                [ 'meta', { name: 'twitter:site', content: '@ethereum' } ], // TODO: Replace with EIPs Twitter account, if one exists
                [ 'meta', { name: 'twitter:description', content: description } ],
                // Dublin Core
                [ 'meta', { name: 'DC.title', content: eipTitle } ],
                ...authors.map(author => [ 'meta', { name: 'DC.creator', content: author } ]),
                [ 'meta', { name: 'DC.date', content: frontmatter.created.replace("-", "/") } ],
                frontmatter.finalized ? [ 'meta', { name: 'DC.issued', content: frontmatter.finalized.replace("-", "/") } ] : [],
                [ 'meta', { name: 'DC.format', content: 'text/html' } ],
                [ 'meta', { name: 'DC.language', content: 'en-US' } ],
                [ 'meta', { name: 'DC.publisher', content: siteConfig.title } ],
                [ 'meta', { name: 'DC.rights', content: 'Public Domain' } ],
                // Citation
                [ 'meta', { name: 'citation_title', content: eipTitle } ],
                ...authors.map(author => [ 'meta', { name: 'citation_author', content: author } ]),
                [ 'meta', { name: 'citation_online_date', content: frontmatter.created.replace("-", "/") } ],
                frontmatter.finalized ? [ 'meta', { name: 'citation_publication_date', content: frontmatter.finalized.replace("-", "/") } ] : [],
                [ 'meta', { name: 'citation_technical_report_institution', content: siteConfig.title } ],
                [ 'meta', { name: 'citation_technical_report_number', content: frontmatter.eip } ],
                // LD+JSON
                [ 'script', { type: 'application/ld+json' }, JSON.stringify({
                    "@type": "WebSite",
                    "url": "{{site.url}}",
                    "name": "{{site.title}}",
                    "description": "{{site.description}}",
                    "@context": "https://schema.org"
                })],
            ].filter(x => x.length > 0);
        } else {
            return [];
        }
    },
    async transformPageData(pageData) {
        console.log(`\nTransforming ${pageData.relativePath}\n`);
        
        pageData = { ...pageData };
        let { frontmatter } = pageData;

        if (frontmatter.eip) {
            // Try to read from cache
            try {
                let cache = JSON.parse(fs.readFileSync(`./.vitepress/cache/eips/${frontmatter.eip}.json`));
                frontmatter = { ...frontmatter, ...cache };
            } catch (e) {
                console.log(`\nCache miss for ${pageData.relativePath}\n`);
            }
            // The below caused so much pain and suffering :|
            if (!frontmatter.created) {
                let initial = new Date((await git.log(["--diff-filter=A", "--", pageData.relativePath])).latest.date); // Only one match, so this is fine to use latest
                if (initial) {
                    frontmatter.created = initial.toISOString().split('T')[0];
                }
            }
            if (!frontmatter.finalized && frontmatter.status === 'Final') {
                let final = new Date((await git.raw(['blame', pageData.relativePath])).split('\n').filter(line => line.match(/status:\s+final/gi))?.pop()?.match(/(?<=\s)\d+-\d+-\d+/g)?.pop());
                if (final) {
                    frontmatter.finalized = final.toISOString().split('T')[0];
                }
            }
            if (frontmatter.created.toISOString) { // It's a date object. We don't want that.
                frontmatter.created = frontmatter.created.toISOString().split('T')[0];
            }

            // Write to cache
            if (!fs.existsSync('./.vitepress/cache/eips')) {
                fs.mkdirSync('./.vitepress/cache/eips', { recursive: true });
            }
            fs.writeFileSync(`./.vitepress/cache/eips/${frontmatter.eip}.json`, JSON.stringify({
                created: frontmatter.created,
                finalized: frontmatter.finalized,
            }));
        }
        if (frontmatter.listing) {
            frontmatter.eips = eips;
            frontmatter.statuses = statuses;
        }
        
        console.log(`\nFinished Transforming ${pageData.relativePath}\n`);

        pageData.frontmatter = frontmatter;
        return pageData;
    }
}
