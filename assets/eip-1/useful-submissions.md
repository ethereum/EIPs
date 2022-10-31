# Useful submissions

A *standard*, in technical settings, is an established specification that allows any compliant thing to work with any compliant user of that thing, also known as cross-connect. It is a set of restrictions or marketing claims, incumbent upon the standardized product.

We call the compliant thing a *producer*. And the thing that is relying on those specifications is the *consumer*.

And in technical circles, we call the specific parts that are standardized as its *surface area*.

As always, to understand the tech world, we should also compare with the rest of the world. Then we'll apply it to blockchain standards processes.

| Standard                                                     | Producers                                                 | Consumers                                                    |
| ------------------------------------------------------------ | --------------------------------------------------------- | ------------------------------------------------------------ |
| [ERC-721](https://eips.ethereum.org/EIPS/eip-721) (i.e. NFTs) | Smart contracts on Ethereum, TRON, etc.                   | Crypto wallets, marketplaces, real-life parties that confirm ownership to let you in |
| US Letter sized paper (common spec, no authoritative reference) | Hammermill, Staples, other paper brands                   | Printers, copy machines, manilla folders, #10 envelopes      |
| [USB 80Gbps](https://www.usb.org/sites/default/files/2022-09/USB%20PG%20USB4%20Version%202.0%2080Gbps%20Announcement_FINAL.pdf) (formerly "USB4" or "SuperSpeed") | USB cables, USB ports in various electronic devices       | USB cables, USB ports in various electronic devices          |
| [USPS postcard size](https://pe.usps.com/businessmail101?ViewName=Cards) | Printers sending mass mailers, travel memoriabelia makers | The US Postal Service, postal inspectors (for rate collection), postal equipment manufactures, [printers](https://www.addrex.com/rena_xps_promail.html) |
| Food nutrition labels ([US](https://www.fda.gov/food/nutrition-education-resources-materials/new-nutrition-facts-label), [EU](https://food.ec.europa.eu/safety/labelling-and-nutrition/food-information-consumers-legislation/nutrition-labelling_en), [Shanghai, CN](https://www.shanghai.gov.cn/nw42885/index.html)) | Commercial preparers of packaged food                     | Government and commercial food inspectors, people that eat food |
| People drive on the left side of the road (in some countries) | Drivers, car manufacturers, traffic signage               | Other drivers on the road, pedestrians                       |

Let's look a little closer at things that are and are not standardized:

| Standard                                  | Origin of standard                                           |
| ----------------------------------------- | ------------------------------------------------------------ |
| Food labeled as "USDA organic" in USA     | [USDA enforces](https://www.ams.usda.gov/rules-regulations/organic) usage of this word |
| Cherios box claims its oats are "toasted" | There is no applicable definition or enforcement of what "toasting" is, your recourse is may only include a civil action |

We have looked at a few example of things that have been standardized, different kinds of standards. And you might think, anything can be rewritten as a standard if you really wanted to. And you're right. Here are some contrived examples:

* When I walk down the street, I don't skip. That's **a walking standard**.
* My smart contract allows to mint pictures of tables using a `mintTable` function. This is **a minting standard for NFTs**.
* I wrote some software and created test cases. All of those test cases are **a software standard**.

Some of these behaviors might be important. Maybe you don't like skipping, you can adopt that behavior. But as a standard these are useless, I hope you understand. But let's articulate why.

**A standard only deserves to be written if multiple people adhere to it and people depend on its surface area.**

FYI, in the United States, the post office has their own police. Watch out for that.

✅ If you routinely use postcard stamps to mail letters that are not postcard size you will go to jail. Multiple people mail postcards and depend on not going to jail... this deserves to be standardized.

❌ Your smart contract uses a specific way to track inclusion of addresses in a set. Nobody cares or is affected by which specific way you track inclusion of addresses in a set. This does not deserve to be standardized.

An easy, low-effort, low-quality way to find a bunch of things to standardize is to find a popular repository of smart contracts, and then write every one of them up with a short rationale. This is fun for practice, but please do not publish these as it will be a waste of other people's time to read. Nobody depends on these details.

But if you really WANT to make something and standardize it, here's how.

1. Go make a thing that is useful
2. Make it successful
3. Make other people want to interoperate with your thing
4. Make other people want to copy you
5. Then go standardize it

Remember, CryptoKitties and CryptoPunks came first, the blockchain NFT standard come afterwards. Don't think that having some standard will make your product successful, that causality is backwards.

William Entriken / 2022-09-30 / Derived from a [phor.net](https://blog.phor.net/2022/09/30/What-kinds-of-things-should-be-standardized.html) article