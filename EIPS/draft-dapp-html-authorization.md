<pre>
  EIP: draft
  Title: safe "eth_sendTransaction" authorization via html popup
  Author: Ronan Sandford <wighawag@gmail.com>
  Created: 2016-06-05
  Status: Draft
  Type: Standard
</pre>

Abstract
========
This draft EIP describes the details of an authorization method provided by rpc enabled ethereum nodes allowing regular websites to send transactions (via ```eth_sendTransaction```) without the need to enable CORS for the website's domain. This is done by asking the user permission via an html popup served by the node itself. This allow users to to safely unlock their account while interacting with web based dapps running in their everyday web browser.

Motivation
==========
Currently, if a user navigate to a dapp running on a website using her/his everyday browser, the dapp will have by default no access to the rpc node for security reason. The user will have to enable CORS for the website's domain in order for the dapp to work. Unfortunately if the user do so, the dapp will be able to send transaction from any unlocked account without the need for any user consent. In other word not only the user need to change its node default setting but the user is also forced to trust the dapp in order to use it. This is of course not acceptable and force existing dapps to rely on the use of workarround like:
- if the transaction is a plain ether transfer the user is asked to enter it in a dedicated trusted wallet like "Mist"
- For more complex case, the user is asked to enter the transaction manually via the node command line interface.
This proposal aims to provide a safe and user friendly alternative.

Specification
=============
In order for the mechanism to work, the node need to serve a static html file via http at the url <node url>/authorization 
This file will then be used by the dapp in 2 different modes (invisible iframe and popup window).
The invisible iframe will be embeded in the dapp to allow the dapp to send its rpc call without having to enable CORS for the dapp's website domain. This is done by sending message to the iframe (via javascript ```window.postMessage```) which in turn execute the rpc call. This works since the iframe and the node share the same domain/port.
In iframe node the html file's javascript code will ensure that no call requiring an unlocked key can be made. This is to prevent dapp for embedding the visible iframe and tricking the user into clicking the confirm button.
If the dapp requires to make an ```eth_sendTransaction``` call, the dapp will instead open a new window using the same url.
In this popup window mode, the html file's javascript code will alow ```eth_sendTransaction``` (not  ```eth_sign``` as there is no way to display to the user the meaningfull content of the transaction to sign in a safe way) to be called. But instead of sending the call to the node directly, a confirmation dialog will be presented showing the sender and recipient addresses as well the amount being transfered along with the potential gas cost. Upon the user approving, the request will be sent and the result returned to the dapp. An error will be returned in case the user cancel the request.


Rationale
=========
The design for that proposal was chosen for its simplicity and security. A previous idea was to use an oauth-like protocol in order for the user to accept or deny a transaction request. It would have required deeper code change in the node and some geth contributors argues that such change did not fit into geth code base as it would have required dapp aware code. 
The current design, instead has a very simple implementation (static html file that can be shared across node's implementation) and its safeness is guarantess by browsers' cross domain policies.
The use of iframe/ window was required to have both security and user friendliness. The invisble iframe allow the dapp to execute read only calls without the need for user input and the window ensure the user approve before making a call. While we could have made it without the window mode by making the iframe confirmation use the native browser "window.confirm" dialog, this would have prevented the use of a more elegant confirmation popup that the current design allow.


Implementations
===============
In order to implement this design, the following html file need to be served at the url <node url>/authorization
That's it


```
<html></html>
```