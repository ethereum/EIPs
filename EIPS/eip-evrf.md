<pre>EIP: (to be assigned)
Title: Ethereum Vulnerability Reporting Framework
Author: Dick Olsson (dick.olsson@senzilla.com)
Type: Informational
Status: Draft
Created: 2017-07-21</pre>

<h1>Abstract</h1>

The decentralized autonomous organization called <em>Ethereum Security Consortium</em> (ESC) is the maintainer of the <em>Ethereum Vulnerabilities Reporting Framework</em> (EVRF), which defines standard procedures around reporting, identification and disclosure of security vulnerabilities for projects in the Ethereum ecosystem.

The goal of this framework, and the reason for standardization, is to offer users a consistent and reliable disclosure process that will improve responsiveness, information accuracy and ultimately security of the ecosystem as a whole.

The processes described in this framework are derived from projects such as <a href="https://www.debian.org/security/">Debian</a> and <a href="https://www.drupal.org/security/">Drupal</a> that have strong organization around security in their own ecosystems. This framework, however, has been adapted to the unique challenges of the decentralized web.

<h1>Motivation</h1>

On Ethereum, anyone is able to publish decentralized applications and smart contracts that store or handle lots of monetary value and other very important data. Secure best practices when writing software is of high importance. But even more important is a reliable protocol for reporting and disclosing security vulnerabilities when they are found. Because they will continue to be found as long as humans write software.

There are two aspects when dealing with security vulnerability disclosures: (1) how they are reported (2) how they are published to the general public. Today, there's a lack of standardization in this area and users are given little guidance. Users are having to rely on blogs, Twitter accounts, Slack channels etc. This leads to inaccurate communication, confusion and opportunities for exploitation.

In a decentralized ecosystem largely built on-top of <a href="https://www.usv.com/blog/fat-protocols">fat protocols</a>, consensus algorithms and contract standards, there is also lots of opportunity to standardize on common procedure protocols. This framework was created for projects in the Ethereum ecosystem to standardize around security vulnerability reporting and responsible disclosure.

The framework has been organized in such a way that there is no central organization to receive, judge or prioritize vulnerability reports. Although convenient and often efficient, such an organization could become a bottleneck and might not align with the interests of a decentralized ecosystem. This is why projects are responsible for organizing their own disclosure process according to this framework. A decentralized organization does exists, however, but merely to distribute said disclosures to the wider security community and to interact, on the behalf of the Ethereum community, with traditional central entities such as <a href="https://cve.mitre.org/index.html">MITRE's CVE database</a>.

<h1>Framework</h1>

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in <a href="http://tools.ietf.org/html/rfc2119">RFC 2119</a>.

<h2>Ethereum Security Consortium</h2>

<em>Ethereum Security Consortium</em> (ESC) is a decentralized autonomous organization of members that maintain this <em>Ethereum Vulnerability Reporting Framework</em> (EVRF) document, which defined standards processes around disclosure, identification and communication of security vulnerabilities for software projects in the Ethereum universe.

A unique identifier SHALL be assigned by the ESC for each security vulnerability published by projects according to the section <em>Disclosure Process for Projects</em>. A <a href="https://cve.mitre.org/index.html">CVE</a> identifier MAY also be requested by the ESC for identified vulnerabilities.

An XML repository, as defined by the <a href="https://oval.mitre.org/language/index.html">OVAL Language schema</a>, SHALL be provided by the ESC to allow for automated communication of vulnerabilities across tools and services of the wider security community.

An email address SHALL be provided by the ESC so that anyone MAY responsibly disclose security vulnerabilities in projects that do not follow <em>Disclosure Process for Projects</em> or do not provide other means for responsible disclosure. In this case advice SHALL be provided by the ESC for what the best course of action is.

A public OpenPGP key (as defined by <a href="https://tools.ietf.org/html/rfc4880">RFC 44880</a>) SHALL be provided by the ESC and any email communication from this email address SHALL be signed. Communication MAY be encrypted if the original sender also provides a public key.

<h2>Disclosure Process for Projects</h2>

The following sections describe the process by which any Ethereum projects are RECOMMENDED to (1) handle their security reporting process, and (2) how and in what format to publish security vulnerabilities.

<h3>1.a. Reporting Process Discovery</h3>

Every project MUST provide a link to its security reporting process in an obvious place. This SHOULD be on the root page the main domain of the given project. This MAY be a sub-domain in case it is a sub-project of a larger initiative. The link MAY use the custom link relation <code>vuln-reporting</code>, for example <code>&lt;link rel="vuln-reporting" href="http://example.org/security" /&gt;</code>.

Projects SHOULD make the location prominent by either creating a dedicated sub-domain like <code>http://security.example.org</code> or by making it a top level directory like <code>http://example.org/security</code>. Projects MAY choose to list any part of the procedures that is not a MUST, which they choose to omit.

Note that projects MAY not have a dedicated domain. For example a project hosted on Github, Bitbucket or other service SHOULD ensure that the process is referenced on the landing page. For example, <code>http://github.com/example/somedapp</code> should have a README file on the default branch which references the procedures used so that it is automatically displayed.

If necessary projects MAY have different reporting process for different major version number. In this case one URL MUST be provided for each major version. In the case a major version is no longer receiving security fixes, instead of a URL, a project MAY opt to instead simply note that the version is no longer receiving security fixes.

<h3>1.b. Reporting Process</h3>

Every project MUST publish an email address on the page where it is describing its <em>Reporting Process</em>. Projects SHALL NOT use contact forms for this purpose.

At the same location as the email address, projects SHOULD publish a public OpenPGP key by which all communication will be signed. Communication MAY be encrypted, if the original sender also provides an OpenPGP public key.

<h3>2.a. Publishing Process Discovery</h3>

Every project MUST provide a link to its vulnerability information database in an obvious place. This SHOULD be on the root page of the main domain of the given project. This MAY be a sub-domain in case it is a sub-project of a larger initiative. If the project has a dedicated page for its <em>Reporting Process Discovery,</em> then this is also considered a good place for this link. The link MAY use the custom link relation <code>vuln-publishing</code>, for example <code>&lt;link rel="vuln-publishing" href="http://example.org/disclosures" /&gt;</code>.

Note that projects MAY choose to host their disclosure files on a domain other than their main project page. It is not RECOMMENDED to store the disclosures in a VCS, as this can lead to confusion about which branch is the relevant branch. If a VCS is used, then additional steps SHOULD be taken to clearly document to users which branch contains all vulnerabilities for all versions. Projects with multiple major versions MAY split disclosure files by major version number, which SHOULD be clearly documented.

<h3>2.b. Publishing Process</h3>

Disclosures SHOULD first be published in the disclosure file (as described by the <em>Publishing Format</em>) before any other communication is published, for example, on social media.

For vulnerabilities that knowingly have not yet been exploited, it is RECOMMENDED to publish disclosures on Tuesdays around 17:00 UTC. This recommendation exists to maximize the potential availability of organizations and individuals to react to disclosures.

<h3>2.c. Publishing Format</h3>

Every project MUST provide its disclosure file formatted as JSON (as defined by <a href="https://tools.ietf.org/html/rfc7159">RFC 7159</a>).

<h4>2.c.1. Root object</h4>

The disclosure file MUST be a JSON document and MUST contain the following top-level keys with corresponding values:

<dl>
  <dt>name</dt>
  <dd>MUST contain the name of the project.</dd>
  <dt>description</dt>
  <dd>MUST contain a short description of the project.</dd>
  <dt>homepage</dt>
  <dd>MUST contain a URL to the project homepage.</dd>
  <dt>vulnerabilities</dt>
  <dd>MUST be an array of zero or more JSON objects.</dd>
</dl>

<h4>2.c.2. Vulnerability objects</h4>

Keys and corresponding values for each object in the top-level <em>vulnerabilities</em> key:

<dl>
  <dt>id</dt>
  <dd>MUST be a per-project unique vulnerability ID integer.</dd>
  <dt>title</dt>
  <dd>MUST contain short description of the vulnerability and affected versions.</dd>
  <dt>description</dt>
  <dd>MUST contain description of the vulnerability.</dd>
  <dt>affected</dt>
  <dd>MUST be an array of affected version(s) expressed as [npm's semver ranges][npm].</dd>
  <dt>severity</dt>
  <dd>MUST be expressed as a <a href="https://www.first.org/cvss/">CVSS 3.0</a> vector string. It's RECOMMENDED to use the <a href="https://www.first.org/cvss/calculator/3.0">CVSS 3.0 calculator</a> for this purpose.</dd>
  <dt>remediationType</dt>
  <dd>MUST be either "workaround", "mitigation", "vendor fix", "none available" or "will not fix" as defined by the <a href="http://www.icasi.org/cvrf-v1-1-dictionary-of-elements/#40rem">CVRF v1.1 remediation types</a>.</dd>
  <dt>remediation</dt>
  <dd>MAY contain a textual description for how to fix an affected system.</dd>
  <dt>published</dt>
  <dd>MUST be date and time of initial publication, formatted according to <a href="https://tools.ietf.org/html/rfc3339">RFC 3339</a>.</dd>
  <dt>updated</dt>
  <dd>MAY be date and time when the publication was updated, formatted according to <a href="https://tools.ietf.org/html/rfc3339">RFC 3339</a>.</dd>
  <dt>authors</dt><dd>MAY contain an array of contact information about the authors of the remediation.</dd>
  <dt>reporters</dt>
  <dd>MAY contain an array of contact information about the reporters of the vulnerability.</dd>
  <dt>links</dt>
  <dd>MAY contain an array of URLs referencing more information. It is RECOMMENDED to include a link to the VCS reference of the remediation.</dd>
</dl>

<h1>Appendix A: Sample publishing format</h1>

Below is an example implementation of the disclosure file format:

<pre>{
  "name": "somedapp",
  "description": "Some decentralized application doing something very useful.",
  "homepage": "http://somedapp.org",
  "vulnerabilities": [
    {
      "id": 2,
      "title": "Re-entry vector in FooBar contract",
      "description": "Re-entry attack vector in the FooBar constructor that'll lock out contributions to the contract.",
      "affected": "&gt;=0.2.0",
      "severity": "CVSS:3.0/AV:N/AC:L/PR:N/UI:R/S:C/C:H/I:H/A:H",
      "remediationType": "workaround",
      "remediation": "You must move funds in FooBar to another contract.",
      "published": "2017-07-20T18:00:00Z",
      "updated": "2017-07-20T20:00:00Z",
      "authors": ["maintainerX"],
      "reporters": ["researcherY", "researcherZ"],
      "links": ["http://somedapp.org/security/vuln-2"]
    },
    {
      "id": 1,
      "title": "Information enumeration in FooBar contract",
      "description": "Enumeration of property ABC is possible due to improper hashing.",
      "affected": "&gt;=0.1.0",
      "severity": "CVSS:3.0/AV:N/AC:H/PR:N/UI:R/S:C/C:L/I:N/A:N",
      "remediationType": "workaround",
      "remediation": "You must move funds in FooBar to another contract.",
      "published": "2017-07-15T18:00:00Z",
      "authors": ["maintainerX"],
      "reporters": ["researcherY"],
      "links": ["http://somedapp.org/security/vuln-1"]
    }
  ]
}</pre>
