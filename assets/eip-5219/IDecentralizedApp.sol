// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

struct KeyValue {
    string key;
    string value;
}

interface IDecentralizedApp {
    /// @notice                     Send an HTTP-like request to this contract
    /// @param  method              The HTTP method to use (e.g. GET, POST, PUT, DELETE)
    /// @param  resource            The resource to request (e.g. "/asdf/1234" turns in to ["asdf", "1234"], and "/demo?qwerty=uiop" turns in to ["demo"])
    /// @param  parameters          The parameters to send with the request (e.g. "querty=uiop&1234=5678" would be [{ key: "qwerty", value: "uiop"}, { key: "1234", value: "5678"}])
    /// @param  headers             A list of header names (e.g. [{ key: "X-Foo-Bar", value: "asdf" }])
    /// @return statusCode          The HTTP status code (e.g. 200)
    /// @return body                The body of the response
    /// @return resultHeaders       A list of header names (e.g. [{ key: "Content-Type", value: "application/json" }])
    function request(string memory method, string[] memory resource, KeyValue[] memory parameters, KeyValue[] memory headers) external view returns (uint8 statusCode, string memory body, KeyValue[] resultHeaders);
}
