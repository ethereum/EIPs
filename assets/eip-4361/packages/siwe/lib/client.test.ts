const parsingPositive: Object = require('../../../test/parsing_positive.json');
const validationPositive: Object = require('../../../test/validation_positive.json');
const validationNegative: Object = require('../../../test/validation_negative.json');

import { Wallet } from 'ethers';
import { SiweMessage } from './client';

describe(`Message Generation`, () => {
	test.concurrent.each(Object.entries(parsingPositive))(
		'Generates message successfully: %s',
		(_, test) => {
			const msg = new SiweMessage(test.fields);
			expect(msg.toMessage()).toBe(test.message);
		}
	);
});

describe(`Message Validation`, () => {
	test.concurrent.each(Object.entries(validationPositive))(
		'Validates message successfully: %s',
		async (_, test_fields) => {
			const msg = new SiweMessage(test_fields);
			await expect(
				msg.validate(test_fields.signature)
			).resolves.not.toThrow();
		}
	);
	test.concurrent.each(Object.entries(validationNegative))(
		'Fails to validate message: %s',
		async (_, test_fields) => {
			const msg = new SiweMessage(test_fields);
			await expect(msg.validate(test_fields.signature)).rejects.toThrow();
		}
	);
});

describe(`Round Trip`, () => {
	let wallet = Wallet.createRandom();
	test.concurrent.each(Object.entries(parsingPositive))(
		'Generates a Successfully Verifying message: %s',
		async (_, test) => {
			const msg = new SiweMessage(test.fields);
			msg.address = wallet.address;
			const signature = await wallet.signMessage(msg.toMessage());
			await expect(msg.validate(signature)).resolves.not.toThrow();
		}
	);
});
