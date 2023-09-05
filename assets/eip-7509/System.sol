// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0;
import "./IComponent.sol";
import "./IWorld.sol";

contract System {
    address world;
    address componentAddress;

    constructor(address _world, address _componentAddress) {
        world = _world;
        componentAddress = _componentAddress;
    }

    function move(
        uint256 _entityId,
        uint256 _x,
        uint256 _y
    ) public {
        require(
            IWorld(world).getEntityState(_entityId),
            "The entity is unavailable"
        );
        require(
            IWorld(world).getComponentState(componentAddress),
            "The component is unavailable"
        );
        IComponent(componentAddress).set(_entityId, abi.encode(_x, _y));
    }
}
