import {
    Validator,
    Distributor,
    MockERC20,
    MockERC721
} from "../typechain-types";

export interface IContracts {
    distributor: Distributor
    validator: Validator,
    mock: {
        ERC20: MockERC20,
        ERC721: MockERC721
    }
}

export interface IContractAddresses {
    distributor: string,
    validator: string,
    mock: {
        ERC20: string,
        ERC721: string
    }
}