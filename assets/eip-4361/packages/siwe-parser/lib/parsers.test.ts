const parsingPositive: Object = require('../../../test/parsing_positive.json');
const parsingNegative: Object = require('../../../test/parsing_negative.json');

//
for (const client of ['abnf', 'regex'].values()) {
	describe(`${client.toUpperCase()} Client`, () => {
		let ParsedMessage;
		beforeEach(async () => ParsedMessage = (await import(`./${client}`)).ParsedMessage);

		test.concurrent.each(Object.entries(parsingPositive))('Parses message successfully: %s', (test_name, test) => {
			const parsedMessage = new ParsedMessage(test.message);
			for (const [field, value] of Object.entries(test.fields)) {
				if (typeof value === 'object') {
					expect(parsedMessage[field]).toStrictEqual(value);
				} else {
					expect(parsedMessage[field]).toBe(value);
				}
			}
		});

		test.concurrent.each(Object.entries(parsingNegative))('Fails to parse message: %s', (test_name, test) => {
			expect(() => new ParsedMessage(test)).toThrow();
		});
	});
}


describe("Parsers import works", () => {

	let ParsedMessage = require('./parsers').ParsedMessage;
	beforeEach(async () => ParsedMessage = (await import('./parsers')).ParsedMessage);

	test.concurrent.each(Object.entries(parsingPositive))('Parses message successfully: %s', (test_name, test) => {
		const parsedMessage = new ParsedMessage(test.message);
		for (const [field, value] of Object.entries(test.fields)) {
			if (typeof value === 'object') {
				expect(parsedMessage[field]).toStrictEqual(value);
			} else {
				expect(parsedMessage[field]).toBe(value);
			}
		}
	});

	test.concurrent.each(Object.entries(parsingNegative))('Fails to parse message: %s', (test_name, test) => {
		expect(() => new ParsedMessage(test)).toThrow();
	});
});
