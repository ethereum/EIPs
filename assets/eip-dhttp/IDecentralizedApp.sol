// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IDecentralizedApp {
    /// @notice                     Send an HTTP-like request to this contract
    /// @param  method              The HTTP method to use (e.g. GET, POST, PUT, DELETE)
    /// @param  resource            The resource to request (e.g. "/asdf/1234" turns in to ["asdf", "1234"], and "/demo?qwerty=uiop" turns in to ["demo"])
    /// @param  parameters          The parameters to send with the request (e.g. "querty=uiop&1234=5678" would be ["qwerty", "1234"])
    /// @param  values              The values to send with the request (e.g. "querty=uiop&1234=5678" would be ["uiop", "5678"])
    /// @param  headers             A list of header names (e.g. ["X-Foo-Bar"])
    /// @param  headerValues        A list of header values (e.g. ["asdf"])
    /// @return body                The body of the response
    /// @return resultHeaders       A list of header names (e.g. ["Content-Type"])
    /// @return resultHeaderValues  A list of header values (e.g. ["application/json"])
    function request(string memory method, string[] memory resource, string[] memory parameters, string[] memory values, string[] memory headers, string[] memory headerValues) external view returns (string memory body, string[] memory resultHeaders, string[] memory resultHeaderValues);
}