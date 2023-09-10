---
eip: 7515
title: NFT Alternative Text in Metadata
description: Populate alternative text field in NFT Metadata with image description for screen reader.
author: Mona Rassouli (@DecoratedWings)
discussions-to: https://ethereum-magicians.org/t/proposal-for-informational-eip-simple-accessibility-recommendation/14639
status: Draft
type: Informational
created: 2023-08-15
---

## Abstract

This informational EIP advocates for the consistent inclusion of alternative text in NFT metadata. Marketplaces, creators, and decentralized applications should adopt this best practice to improve accessibility. When rendering NFT images on frontend interfaces, these platforms can leverage the `alt` attribute effectively.

## Motivation

Alternative text assists different users who leverage assistive technology. Users who leverage screen readers for instance, benefit from an accurate, concise description of the image.

Given that NFTs are portable between marketplaces, websites, and dapps, it is more efficient to create a suitable description upon creation (minting) of the NFT. In this way, the description can be attached to the image and ported between interfaces. The alternative text only needs to be written one time, eliminating the need to recreate it from scratch on every interface.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.


The `alt` attribute should be positioned at the root level within the metadata structure. It MUST provide a concise and accurate description of the image.

```
{
  "name": "NFT Name",
  "alt": "Alternative text describing the image.",
  "description": "Short description of the NFT image.",
  "image": "ipfs://path_to_image",
}

```

When the metadata is fetched for the NFT in the frontend, the alternative text for the image can simply be rendered as: 

```
<img src={metadata.image} alt={metadata.alt} />
```

In this context, `metadata` refers to the JSON response obtained from some fetch operation or method of retrieval. This retrieval can be executed through various means, such as using a specific library or a node provider SDK.


## Rationale

1. <b>Guaranteed Alternative Text at Inception</b>: By embedding the alternative text during the minting phase, NFTs are equipped with accessibility features from the start. This method ensures that the foundation of accessibility is built into the NFT from the very beginning.

2. <b>Responsibility & Simplicity</b>: By placing the responsibility on the collection creator, we ensure that those who are most familiar with the content craft the alternative text. This not only ensures accuracy but also empowers creators to adhere to best alternative text practices—a task that, with proper guidance, is straightforward and simple.

3. <b>Optimal Approach</b>: This approach eliminates the potentially overwhelming task for interfaces to manually add alternative text for thousands of images and collections. The interfaces, such as marketplaces, simply need to validate that the alt field is present. 

4. <b>Flexibility</b>: While the alt text is provided, it's not a strict imposition. Dapps retain the freedom to use the supplied alternative text, modify it, or even replace it altogether, depending on their specific needs or circumstances.


## Backwards Compatibility

While this EIP does not introduce a protocol-level change to existing ERC standards, there are two primary scenarios to consider:

* This proposed method is not applicable to NFTs that have their metadata frozen or locked. Such NFTs will necessitate manual adjustments on the frontend to incorporate alternative text.

* For NFTs that have already been minted but possess non-frozen (modifiable) metadata, updates can be made to introduce or adjust the alternative text as deemed appropriate.

## Test Cases

### Best Practices For Alternative Text

The guidelines below are derived from the established Web Content Accessibility Guide (WCAG) standards.

1. <b>Avoid Redundancy</b>: Screen readers inherently detect content as an image due to the <img> tag. Avoid phrases like "image of" or "picture of".

2. <b>Concise & Relevant Descriptions</b>:  Ideally, aim for descriptions around 150 characters, though this isn't a strict limit. 

3. <b>Correct Sentence Structure & Punctuation</b>: Ensure that descriptions are grammatically accurate and punctuated correctly.

4. <b>Include Text Within the Image</b>: If the NFT image embeds any text, ensure it's reflected in the alt description.

5. <b>Simple Sentences</b>: Use straightforward sentences and avoid run-on sentences.

6. <b>Generative Collections</b>: Begin with a description of the base image and dynamically add specific attributes. For instance: "Penguin wearing a {hat_type} and a {color} t-shirt."

7. <b>Separate Description</b>:  The alt text should solely depict the image's content. Reserve collection-specific details for the description field in the metadata.

8. <b>Human Review</b>: Always have the content reviewed to ensure its accuracy.

### Note On Audio or Video Content
* While this EIP centers on alternative text for static images, the significance of captions for video or music-based NFTs should not be overlooked. It's crucial to adhere to captioning best practices for such content.

* When applicable, captions should be embedded directly within the video or music content, separate from the metadata. Refer to WCAG for comprehensive guidelines and resources on proper captioning.

## Security Considerations

A primary concern is cross-site scripting (XSS) since the process involves fetching and displaying text. Some frameworks, like React, mitigate this risk by default through automatic content escaping. To bolster security, implement proper XSS mitigation strategies, which include both sanitizing input and escaping output.


It is worth noting that this potential vulnerability isn't limited to alternative text but extends to any text data sourced from metadata.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
