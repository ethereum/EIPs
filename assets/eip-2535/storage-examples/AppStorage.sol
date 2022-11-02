// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Diamond Storage is particularly good for isolating or compartmenting state variables to specific 
// facets or functionality. This is great for creating modular facets that can be understood as their 
// own units and be added to diamonds. A diamond with a lot of functionality is well organized and 
// understandable if each of its facets can be understood in isolation. Diamond Storage helps make that 
// possible.

// However, you may want to share state variables specific to your application with facets that are specific 
// to your application. It can get somewhat tedious to call a `diamondStorage()` function in every function 
// that you want to access state variables. 

// `AppStorage` is a specialized version of Diamond Storage. It is a more convenient way to access 
// application specific state variables that are shared among facets.

// The pattern works in the following way:

// 1. Define a struct called AppStorage that contains all the state variables specific to your application 
//    and that you plan to share with different facets. Store AppStorage in a file. Any of your facets can 
//    now import this file to access the state variables.

struct AppStorage {
    uint256 secondVar;
    uint256 firstVar;
    uint256 lastVar;
    // add other state variables ...
}


// 2. In a facet that imports the AppStorage struct declare an AppStorage state variable called `s`. 
//    This should be the only state variable declared in the facet. 

// 3. In your facet you can now access all the state variables in AppStorage by prepending state variables 
//    with `s.`. Here is example code:


// import { AppStorage } from "./LibAppStorage.sol";

contract AFacet {
    AppStorage internal s;

    function sumVariables() external {
        s.lastVar = s.firstVar + s.secondVar;
    }

    function getFirsVar() external view returns (uint256) {
        return s.firstVar;
    }

    function setLastVar(uint256 _newValue) external {
        s.lastVar = _newValue;
    }
}

// Sharing AppStorage in another facet:

// import { AppStorage } from "./LibAppStorage.sol";

contract SomeOtherFacet {
    AppStorage internal s;

    function getLargerVar() external view returns (uint256) {
        uint256 firstVar = s.firstVar;
        uint256 secondVar = s.secondVar;
        if(firstVar > secondVar) {
            return firstVar;
        }
        else {
            return secondVar;
        }
    }
}

// Using the 's.' prefix to access AppStorage is a nice convention because it makes state variables 
// concise, easy to access, and it distinguishes state variables from local variables and prevents 
// name clashes/shadowing with local variables and function names. It helps identify and make 
// explicit state variables in a convenient and concise way. AppStorage can be used in regualar 
// contracts as well as proxy contracts, diamonds, implementation contracts, Solidity libraries and 
// facets.

// Since `AppStorage s` is the first and only state variable declared in facets its position in 
// contract storage is `0`. This fact can be used to access AppStorage in Solidity libraries using 
// diamond storage access. Here's an example of that:

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage ds) {    
        assembly { ds.slot := 0 }
    }

    function someFunction() internal {
        AppStorage storage s = appStorage();
        s.firstVar = 8;
        //... do more stuff
    }
}

// `AppStorage s` can be declared as the one and only state variable in facets or it can be declared in a 
// contract that facets inherit.

// AppStorage won't work if state variables are declared outside of AppStorage and outside of Diamond Storage. 
// It is a common error for a facet to inherit a contract that declares state variables outside AppStorage and 
// Diamond Storage. This causes a misalignment of state variables.

// One downside is that state variables can't be declared public in structs so getter functions can't 
// automatically be created this way. But it can be nice to make your own getter functions for 
// state variables because it is explicit.

// The rules for upgrading AppStorage are the same for Diamond Storage. These rules can be found at 
// the end of the file ./DiamondStorage.sol