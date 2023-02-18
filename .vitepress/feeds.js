// You want feeds? You got feeds!
export default {
    'new': {
        title: 'New Ethereum Improvement Proposals',
        description: 'All new Ethereum Improvement Proposals (EIPs) in one feed.',
        filter: {}
    },
    'newCore': {
        title: 'New Core Ethereum Improvement Proposals',
        description: 'All new Core Ethereum Improvement Proposals (EIPs).',
        filter: {
            category: x => x == 'Core'
        }
    },
    'newNetworking': {
        title: 'New Networking Ethereum Improvement Proposals',
        description: 'All new Networking Ethereum Improvement Proposals (EIPs).',
        filter: {
            category: x => x == 'Networking'
        }
    },
    'newInterface': {
        title: 'New Interface Ethereum Improvement Proposals',
        description: 'All new Interface Ethereum Improvement Proposals (EIPs).',
        filter: {
            category: x => x == 'Interface'
        }
    },
    'newERC': {
        title: 'New Ethereum Requests for Comments',
        description: 'All new Ethereum Request for Comments (ERCs).',
        filter: {
            category: x => x == 'ERC'
        }
    },
    'newInformational': {
        title: 'New Informational Ethereum Improvement Proposals',
        description: 'All new Informational Ethereum Improvement Proposals (EIPs).',
        filter: {
            type: x => x == 'Informational'
        }
    },
    'newMeta': {
        title: 'New Meta Ethereum Improvement Proposals',
        description: 'All new Meta Ethereum Improvement Proposals (EIPs).',
        filter: {
            type: x => x == 'Meta'
        }
    },
    'review': {
        title: 'Ethereum Improvement Proposals in Review',
        description: 'All Ethereum Improvement Proposals (EIPs) in Review.',
        filter: {
            status: x => x == 'Review' || x == 'Last Call' || x == 'Final' || x == 'Living'
        }
    },
    'reviewCore': {
        title: 'Core Ethereum Improvement Proposals in Review',
        description: 'All Core Ethereum Improvement Proposals (EIPs) in Review.',
        filter: {
            category: x => x == 'Core',
            status: x => x == 'Review' || x == 'Last Call' || x == 'Final' || x == 'Living'
        }
    },
    'reviewNetworking': {
        title: 'Networking Ethereum Improvement Proposals in Review',
        description: 'All Networking Ethereum Improvement Proposals (EIPs) in Review.',
        filter: {
            category: x => x == 'Networking',
            status: x => x == 'Review' || x == 'Last Call' || x == 'Final' || x == 'Living'
        }
    },
    'reviewInterface': {
        title: 'Interface Ethereum Improvement Proposals in Review',
        description: 'All Interface Ethereum Improvement Proposals (EIPs) in Review.',
        filter: {
            category: x => x == 'Interface',
            status: x => x == 'Review' || x == 'Last Call' || x == 'Final' || x == 'Living'
        }
    },
    'reviewERC': {
        title: 'Ethereum Requests for Comments in Review',
        description: 'All Ethereum Request for Comments (ERCs) in Review.',
        filter: {
            category: x => x == 'ERC',
            status: x => x == 'Review' || x == 'Last Call' || x == 'Final' || x == 'Living'
        }
    },
    'reviewInformational': {
        title: 'Informational Ethereum Improvement Proposals in Review',
        description: 'All Informational Ethereum Improvement Proposals (EIPs) in Review.',
        filter: {
            type: x => x == 'Informational',
            status: x => x == 'Review' || x == 'Last Call' || x == 'Final' || x == 'Living'
        }
    },
    'reviewMeta': {
        title: 'Meta Ethereum Improvement Proposals in Review',
        description: 'All Meta Ethereum Improvement Proposals (EIPs) in Review.',
        filter: {
            type: x => x == 'Meta',
            status: x => x == 'Review' || x == 'Last Call' || x == 'Final' || x == 'Living'
        }
    },
    'lastCall': {
        title: 'Ethereum Improvement Proposals in Last Call',
        description: 'All Ethereum Improvement Proposals (EIPs) in Last Call.',
        filter: {
            status: x => x == 'Last Call' || x == 'Final' || x == 'Living'
        }
    },
    'lastCallCore': {
        title: 'Core Ethereum Improvement Proposals in Last Call',
        description: 'All Core Ethereum Improvement Proposals (EIPs) in Last Call.',
        filter: {
            category: x => x == 'Core',
            status: x => x == 'Last Call' || x == 'Final' || x == 'Living'
        }
    },
    'lastCallNetworking': {
        title: 'Networking Ethereum Improvement Proposals in Last Call',
        description: 'All Networking Ethereum Improvement Proposals (EIPs) in Last Call.',
        filter: {
            category: x => x == 'Networking',
            status: x => x == 'Last Call' || x == 'Final' || x == 'Living'
        }
    },
    'lastCallInterface': {
        title: 'Interface Ethereum Improvement Proposals in Last Call',
        description: 'All Interface Ethereum Improvement Proposals (EIPs) in Last Call.',
        filter: {
            category: x => x == 'Interface',
            status: x => x == 'Last Call' || x == 'Final' || x == 'Living'
        }
    },
    'lastCallERC': {
        title: 'Ethereum Requests for Comments in Last Call',
        description: 'All Ethereum Request for Comments (ERCs) in Last Call.',
        filter: {
            category: x => x == 'ERC',
            status: x => x == 'Last Call' || x == 'Final' || x == 'Living'
        }
    },
    'lastCallInformational': {
        title: 'Informational Ethereum Improvement Proposals in Last Call',
        description: 'All Informational Ethereum Improvement Proposals (EIPs) in Last Call.',
        filter: {
            type: x => x == 'Informational',
            status: x => x == 'Last Call' || x == 'Final' || x == 'Living'
        }
    },
    'lastCallMeta': {
        title: 'Meta Ethereum Improvement Proposals in Last Call',
        description: 'All Meta Ethereum Improvement Proposals (EIPs) in Last Call.',
        filter: {
            type: x => x == 'Meta',
            status: x => x == 'Last Call' || x == 'Final' || x == 'Living'
        }
    },
    'final': {
        title: 'Ethereum Improvement Proposals in Final',
        description: 'All Ethereum Improvement Proposals (EIPs) in Final.',
        filter: {
            status: x => x == 'Final' || x == 'Living'
        }
    },
    'finalCore': {
        title: 'Core Ethereum Improvement Proposals in Final',
        description: 'All Core Ethereum Improvement Proposals (EIPs) in Final.',
        filter: {
            category: x => x == 'Core',
            status: x => x == 'Final' || x == 'Living'
        }
    },
    'finalNetworking': {
        title: 'Networking Ethereum Improvement Proposals in Final',
        description: 'All Networking Ethereum Improvement Proposals (EIPs) in Final.',
        filter: {
            category: x => x == 'Networking',
            status: x => x == 'Final' || x == 'Living'
        }
    },
    'finalInterface': {
        title: 'Interface Ethereum Improvement Proposals in Final',
        description: 'All Interface Ethereum Improvement Proposals (EIPs) in Final.',
        filter: {
            category: x => x == 'Interface',
            status: x => x == 'Final' || x == 'Living'
        }
    },
    'finalERC': {
        title: 'Ethereum Requests for Comments in Final',
        description: 'All Ethereum Request for Comments (ERCs) in Final.',
        filter: {
            category: x => x == 'ERC',
            status: x => x == 'Final' || x == 'Living'
        }
    },
    'finalInformational': {
        title: 'Informational Ethereum Improvement Proposals in Final',
        description: 'All Informational Ethereum Improvement Proposals (EIPs) in Final.',
        filter: {
            type: x => x == 'Informational',
            status: x => x == 'Final' || x == 'Living'
        }
    },
    'finalMeta': {
        title: 'Meta Ethereum Improvement Proposals in Final',
        description: 'All Meta Ethereum Improvement Proposals (EIPs) in Final.',
        filter: {
            type: x => x == 'Meta',
            status: x => x == 'Final' || x == 'Living'
        }
    }
};
