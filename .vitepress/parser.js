import fs from 'node:fs/promises';

import yaml from 'js-yaml';
import simpleGit from 'simple-git';
import grayMatter from 'gray-matter';

const git = simpleGit();

export async function fetchEips() {
    let eipsDir = await fs.readdir('./EIPS/');
    let eipsUnsorted = await Promise.all(eipsDir.map(getEipTransformedPremable));
    return eipsUnsorted.sort(sortEips);
}

export async function getEipTransformedPremable(file) {
    try {
        let eipContent = await fs.readFile(`./EIPS/${file}`, 'utf-8');
        let eipData = (grayMatter(eipContent)).data;

        let { created, lastStatusChange } = await getGitData(`EIPS/${file}`);
        
        let newEipData = { ...eipData };

        newEipData.eip = await filenameToEipNumber(file);

        newEipData.title = `${eipData.category === 'ERC' ? 'ERC' : 'EIP'}-${eipData.eip}: ${eipData.title}`;
        newEipData.wrongTitle = `${eipData.category === 'ERC' ? 'EIP' : 'ERC'}-${eipData.eip} ${eipData.title}`; // Since some people search using the wrong prefix, make sure that the wrong prefix is also searchable
        newEipData.onlyTitle = eipData.title;
        
        newEipData.authorData = await parseAuthorData(eipData.author);

        newEipData.lastStatusChange = formatDateString(lastStatusChange);
        newEipData.created = formatDateString(created);
        newEipData.relativePath = `EIPS/${file}`;

        newEipData.link = `/EIPS/eip-${newEipData.eip}`;

        newEipData.createdSlashSeperated = formatDateStringSlashSeperated(created);

        if (eipData.status === 'Final' || eipData.status === 'Living') {
            newEipData.finalized = formatDateString(lastStatusChange);
            newEipData.finalizedSlashSeperated = formatDateStringSlashSeperated(lastStatusChange);
        }

        if (newEipData.eip == 1) {
            newEipData = { ...newEipData, ...(await getEip1Data()) };
        }

        return newEipData;
    } catch (error) {
        console.error(`Error while parsing ${file}`);
        throw error;
    }
}

export async function filenameToEipNumber(filename) {
    if (!filename || !filename.match(/(?<=^EIPS\/eip-)[\w_]+(?=.md)/)?.[0]) return false;
    return filename.match(/(?<=^EIPS\/eip-)[\w_]+(?=.md)/)?.[0];
}

export async function parseAuthorData(authorData) {
    let authors = [];
    for (let author of authorData.match(/(?<=^|,\s*)[^\s]([^,"]|".*")+(?=(?:$|,))/g)) {
        let authorName = author.match(/(?<![(<].*)[^\s(<][^(<]*\w/g);
        let emailData = author.match(/(?<=\<).*(?=\>)/g);
        let githubData = author.match(/(?<=\(@)[\w-]+(?=\))/g);
        if (emailData) {
            authors.push({
                name: authorName.pop(),
                email: emailData.pop()
            });
        } else if (githubData) {
            authors.push({
                name: authorName.pop(),
                github: githubData.pop()
            });
        } else {
            authors.push({
                name: authorName.pop()
            });
        }
    }
    return authors;
}

export async function getGitData(relativePath) {
    let gitLogAdded = await git.log(['--diff-filter=A', '--', relativePath]);
    let addedDate = new Date(gitLogAdded.latest.date);

    let gitBlame = await git.raw(['blame', relativePath]);
    let gitBlameLines = gitBlame.split('\n');
    let lastStatusChange = gitBlameLines.filter(line => line.match(/status:/gi))?.pop()?.match(/(?<=\s)\d+-\d+-\d+/g)?.pop();
    let lastStatusChangeDate = new Date(lastStatusChange);

    return {
        created: addedDate,
        lastStatusChange: lastStatusChangeDate
    }
}

export async function getEip1Data() {
    let editorfile = await fs.readFile('./config/eip-editors.yml', 'utf8');
    let editordata = yaml.load(editorfile);
    let editorUsernames = [];
    let inactiveEditorUsernames = [];
    for (let editorType in editordata) {
        for (let editor of editordata[editorType]) {
            if (editorUsernames.includes(editor)) continue;

            if (editorType === 'inactive') {
                inactiveEditorUsernames.push(editor);
            } else {
                editorUsernames.push(editor);
            }
        }
    }

    let editors = [];
    for (let username of editorUsernames) {
        let editorTypes = [];
        for (let editorType in editordata) {
            if (editordata[editorType].includes(username)) {
                editorTypes.push(editorType.charAt(0).toUpperCase() + editorType.slice(1));
            }
        }
        editors.push({
            avatar: `https://github.com/${username}.png`,
            name: username,
            title: editorTypes.join(', '),
            links: [
                { icon: 'github', link: `https://github.com/${username}` }
            ]
        });
    }

    let emeritusEditors = [];
    for (let username of inactiveEditorUsernames) {
        emeritusEditors.push({
            avatar: `https://github.com/${username}.png`,
            name: username,
            title: 'Emeritus Editor',
            links: [
                { icon: 'github', link: `https://github.com/${username}` }
            ]
        });
    }

    return {
        editors,
        emeritusEditors
    }
}

export function sortEips(a, b) {
    // If both EIP numbers are strings and can't be turned to integers, sort by creation date
    if (isNaN(parseInt(a.eip)) && isNaN(parseInt(b.eip))) {
        return a.lastStatusChange - b.lastStatusChange;
    }
    // If only one of the EIP numbers is a string, sort the string to the end
    if (isNaN(parseInt(a.eip))) {
        return 1;
    }
    if (isNaN(parseInt(b.eip))) {
        return -1;
    }
    // If both EIP numbers are integers, sort by EIP number
    return a.eip - b.eip;
}


function formatDateString(date) {
    return date.toISOString().split('T')[0];
}

function formatDateStringSlashSeperated(date) {
    return `${date.getFullYear()}/${date.getMonth() + 1}/${date.getDate()}`;
}
