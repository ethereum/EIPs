// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

struct KeyValue {
    string key;
    string value;
}

interface IDecentralizedApp {
    /// @notice                     Send an HTTP GET-like request to this contract
    /// @param  resource            The resource to request (e.g. "/asdf/1234" turns in to `["asdf", "1234"]`)
    /// @param  params              The query parameters. (e.g. "?asdf=1234&foo=bar" turns in to `[{ key: "asdf", value: "1234" }, { key: "foo", value: "bar" }]`)
    /// @return statusCode          The HTTP status code (e.g. 200)
    /// @return body                The body of the response
    /// @return headers             A list of header names (e.g. [{ key: "Content-Type", value: "application/json" }])
    function request(string[] memory resource, KeyValue[] memory params) external view returns (uint16 statusCode, string memory body, KeyValue[] headers);
}
