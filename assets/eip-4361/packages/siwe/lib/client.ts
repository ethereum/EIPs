import { randomStringForEntropy } from '@stablelib/random';
// TODO: Figure out how to get types from this lib:
import { Contract, ethers, utils } from 'ethers';
import { ParsedMessage, ParsedMessageRegExp } from '@spruceid/siwe-parser';

/**
 * Possible message error types.
 */
export enum ErrorTypes {
	/**Thrown when the `validate()` function can verify the message. */
	INVALID_SIGNATURE = 'Invalid signature.',
	/**Thrown when the `expirationTime` is present and in the past. */
	EXPIRED_MESSAGE = 'Expired message.',
	/**Thrown when some required field is missing. */
	MALFORMED_SESSION = 'Malformed session.',
}

/**@deprecated
 * Possible signature types that this library supports.
 *
 * This enum will be removed in future releases. And signature type will be
 * inferred from version.
 */
export enum SignatureType {
	/**EIP-191 signature scheme */
	PERSONAL_SIGNATURE = 'Personal signature',
}

export class SiweMessage {
	/**RFC 4501 dns authority that is requesting the signing. */
	domain: string;
	/**Ethereum address performing the signing conformant to capitalization
	 * encoded checksum specified in EIP-55 where applicable. */
	address: string;
	/**Human-readable ASCII assertion that the user will sign, and it must not
	 * contain `\n`. */
	statement?: string;
	/**RFC 3986 URI referring to the resource that is the subject of the signing
	 *  (as in the __subject__ of a claim). */
	uri: string;
	/**Current version of the message. */
	version: string;
	/**EIP-155 Chain ID to which the session is bound, and the network where
	 * Contract Accounts must be resolved. */
	chainId: number;
	/**Randomized token used to prevent replay attacks, at least 8 alphanumeric
	 * characters. */
	nonce: string;
	/**ISO 8601 datetime string of the current time. */
	issuedAt: string;
	/**ISO 8601 datetime string that, if present, indicates when the signed
	 * authentication message is no longer valid. */
	expirationTime?: string;
	/**ISO 8601 datetime string that, if present, indicates when the signed
	 * authentication message will become valid. */
	notBefore?: string;
	/**System-specific identifier that may be used to uniquely refer to the
	 * sign-in request. */
	requestId?: string;
	/**List of information or references to information the user wishes to have
	 * resolved as part of authentication by the relying party. They are
	 * expressed as RFC 3986 URIs separated by `\n- `. */
	resources?: Array<string>;
	/**@deprecated
	 * Signature of the message signed by the wallet.
	 *
	 * This field will be removed in future releases, an additional parameter
	 * was added to the validate function were the signature goes to validate
	 * the message.
	 */
	signature?: string;
	/**@deprecated Type of sign message to be generated.
	 *
	 * This field will be removed in future releases and will rely on the
	 * message version
	 */
	type?: SignatureType;

	/**
	 * Creates a parsed Sign-In with Ethereum Message (EIP-4361) object from a
	 * string or an object. If a string is used an ABNF parser is called to
	 * validate the parameter, otherwise the fields are attributed.
	 * @param param {string | SiweMessage} Sign message as a string or an object.
	 */
	constructor(param: string | Partial<SiweMessage>) {
		if (typeof param === 'string') {
			const parsedMessage = new ParsedMessage(param);
			this.domain = parsedMessage.domain;
			this.address = parsedMessage.address;
			this.statement = parsedMessage.statement;
			this.uri = parsedMessage.uri;
			this.version = parsedMessage.version;
			this.nonce = parsedMessage.nonce;
			this.issuedAt = parsedMessage.issuedAt;
			this.expirationTime = parsedMessage.expirationTime;
			this.notBefore = parsedMessage.notBefore;
			this.requestId = parsedMessage.requestId;
			this.chainId = parsedMessage.chainId;
			this.resources = parsedMessage.resources;
		} else {
			Object.assign(this, param);
			if (typeof this.chainId === 'string') {
				this.chainId = parseInt(this.chainId)
			}
		}
	}

	/**
	 * Given a sign message (EIP-4361) returns the correct matching groups.
	 * @param message {string}
	 * @returns {RegExpExecArray} The matching groups for the message
	 */
	regexFromMessage(message: string): RegExpExecArray {
		const parsedMessage = new ParsedMessageRegExp(message);
		return parsedMessage.match;
	}

	/**
	 * This function can be used to retrieve an EIP-4361 formated message for
	 * signature, although you can call it directly it's advised to use
	 * [signMessage()] instead which will resolve to the correct method based
	 * on the [type] attribute of this object, in case of other formats being
	 * implemented.
	 * @returns {string} EIP-4361 formated message, ready for EIP-191 signing.
	 */
	toMessage(): string {
		const header = `${this.domain} wants you to sign in with your Ethereum account:`;
		const uriField = `URI: ${this.uri}`;
		let prefix = [header, this.address].join('\n');
		const versionField = `Version: ${this.version}`;

		if (!this.nonce) {
			this.nonce = generateNonce();
		}

		const chainField = `Chain ID: ` + this.chainId || '1';

		const nonceField = `Nonce: ${this.nonce}`;

		const suffixArray = [uriField, versionField, chainField, nonceField];

		if (this.issuedAt) {
			Date.parse(this.issuedAt);
		}
		this.issuedAt = this.issuedAt
			? this.issuedAt
			: new Date().toISOString();
		suffixArray.push(`Issued At: ${this.issuedAt}`);

		if (this.expirationTime) {
			const expiryField = `Expiration Time: ${this.expirationTime}`;

			suffixArray.push(expiryField);
		}

		if (this.notBefore) {
			suffixArray.push(`Not Before: ${this.notBefore}`);
		}

		if (this.requestId) {
			suffixArray.push(`Request ID: ${this.requestId}`);
		}

		if (this.resources) {
			suffixArray.push(
				[`Resources:`, ...this.resources.map((x) => `- ${x}`)].join(
					'\n'
				)
			);
		}

		let suffix = suffixArray.join('\n');
		prefix = [prefix, this.statement].join('\n\n');
		if (this.statement) {
			prefix += '\n'
		}
		return [prefix, suffix].join('\n');
	}

	/** @deprecated
	 * signMessage method is deprecated, use prepareMessage instead.
	 *
	 * This method parses all the fields in the object and creates a sign
	 * message according with the type defined.
	 * @returns {string} Returns a message ready to be signed according with the
	 * type defined in the object.
	 */
	signMessage(): string {
		console &&
			console.warn &&
			console.warn(
				'signMessage method is deprecated, use prepareMessage instead.'
			);
		return this.prepareMessage();
	}

	/**
	 * This method parses all the fields in the object and creates a sign
	 * message according with the type defined.
	 * @returns {string} Returns a message ready to be signed according with the
	 * type defined in the object.
	 */
	prepareMessage(): string {
		let message: string;
		switch (this.version) {
			case '1': {
				message = this.toMessage();
				break;
			}

			default: {
				message = this.toMessage();
				break;
			}
		}
		return message;
	}

	/**
	 * Validates the integrity of the fields of this objects by matching it's
	 * signature.
	 * @param provider A Web3 provider able to perform a contract check, this is
	 * required if support for Smart Contract Wallets that implement EIP-1271 is
	 * needed.
	 * @returns {Promise<SiweMessage>} This object if valid.
	 */
	async validate(
		signature: string = this.signature,
		provider?: ethers.providers.Provider | any
	): Promise<SiweMessage> {
		return new Promise<SiweMessage>(async (resolve, reject) => {
			const message = this.prepareMessage();
			try {
				let missing: Array<string> = [];
				if (!message) {
					missing.push('`message`');
				}

				if (!signature) {
					missing.push('`signature`');
				}
				if (!this.address) {
					missing.push('`address`');
				}
				if (missing.length > 0) {
					throw new Error(
						`${ErrorTypes.MALFORMED_SESSION
						} missing: ${missing.join(', ')}.`
					);
				}

				let addr;
				try {
					addr = ethers.utils.verifyMessage(message, signature);

				} catch (_) { } finally {
					if (addr !== this.address) {
						try {
							//EIP-1271
							const isValidSignature =
								await checkContractWalletSignature(this, signature, provider);
							if (!isValidSignature) {
								throw new Error(
									`${ErrorTypes.INVALID_SIGNATURE}: ${addr} !== ${this.address}`
								);
							}
						} catch (e) {
							throw e;
						}
					}
				}

				const parsedMessage = new SiweMessage(message);

				if (parsedMessage.expirationTime) {
					const exp = new Date(
						parsedMessage.expirationTime
					).getTime();
					if (isNaN(exp)) {
						throw new Error(
							`${ErrorTypes.MALFORMED_SESSION} invalid expiration date.`
						);
					}
					if (new Date().getTime() >= exp) {
						throw new Error(ErrorTypes.EXPIRED_MESSAGE);
					}
				}
				resolve(parsedMessage);
			} catch (e) {
				reject(e);
			}
		});
	}
}

/**
 * This method calls the EIP-1271 method for Smart Contract wallets
 * @param message The EIP-4361 parsed message
 * @param provider Web3 provider able to perform a contract check (Web3/EthersJS).
 * @returns {Promise<boolean>} Checks for the smart contract (if it exists) if
 * the signature is valid for given address.
 */
export const checkContractWalletSignature = async (
	message: SiweMessage,
	signature: string,
	provider?: any
): Promise<boolean> => {
	if (!provider) {
		return false;
	}

	const abi = [
		'function isValidSignature(bytes32 _message, bytes _signature) public view returns (bool)',
	];
	try {
		const walletContract = new Contract(message.address, abi, provider);
		const hashMessage = utils.hashMessage(message.signMessage());
		return await walletContract.isValidSignature(
			hashMessage,
			signature,
		);
	} catch (e) {
		throw e;
	}
};

/**
 * This method leverages a native CSPRNG with support for both browser and Node.js
 * environments in order generate a cryptographically secure nonce for use in the
 * SiweMessage in order to prevent replay attacks.
 *
 * 96 bits has been chosen as a number to sufficiently balance size and security considerations
 * relative to the lifespan of it's usage.
 *
 * @returns cryptographically generated random nonce with 96 bits of entropy encoded with
 * an alphanumeric character set.
 */
export const generateNonce = (): string => {
	return randomStringForEntropy(96);
};
