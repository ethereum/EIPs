<pre>
  EIP: draft
  Title: sendTransaction authorization via html
  Author: Ronan Sandford <wighawag@gmail.com>
  Created: 2016-06-05
  Status: Draft
  Type: Standard
</pre>

Abstract
========
This draft EIP describes the details of an authorization method provided by rpc enabled ethereum node allowing regular website to to send transaction (via "eth_sendTransaction") without the need to enable CORS for the website domain but instead ask the user permission. This would allow user to safely unlock their account while interacting with web based app running in their everyday web browser.

Motivation
==========
Currently, if a user navigate to a dapp running on a website using his/her everyday browser, the dapp has either full access to "eth_sendTransaction" and "eth_sign" (if the user launched its node with CORS enabled for the website domain) or (more likely) none at all. In other word the user is forced to trust the dapp in order to use it. This is of course not acceptable and force existing dapp to rely on the use of workarround like:
- if the transaction is plain ether transfer the user is asked to enter it in the mist wallet 
- For more complex case, the user is asked to enter the transaction manually via the node command line interface.

Specification
=============
The dapp instead of connecting directly to the node, will instead communicate via 2 channels (a embeded invisible iframe for call that do not require an unlocked keys (most rpc calls) and a window for call to "eth_sendTransaction". call to "eth_sign" are not authorized since there is no way to display to the user the meaningfull content of the transaction in a safe way.
The invisible iframe allow teh dapp to continue making rpc call to the node without any CORS enabled.
The window on the other hand provide the dapp the only way to make a call to "eth_sendTransaction" by asking the user to confirm or cancel the transaction via a html dialog.


Rationale
=========

Backward Compatibility
=================

Implementations
===============
