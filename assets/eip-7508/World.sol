// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./IWorld.sol";
import "./IComponent.sol";

contract World is IWorld {
    uint256 private entityId = 0;
    address[] private components;
    address[] private systems;
    mapping(uint256 => address[]) private entityComponents;
    mapping(uint256 => bool) private entityStates;
    mapping(address => bool) private componentStates;
    mapping(address => bool) private systemStates;

    function createEntity(bool _entityState) public virtual returns (uint256) {
        uint256 currentEntityId = entityId;
        entityStates[currentEntityId] = _entityState;
        entityId++;
        return currentEntityId;
    }

    function entityExists(uint256 _entityId)
        public
        view
        virtual
        returns (bool)
    {
        if (_entityId < entityId) {
            return true;
        }
        return false;
    }

    function getEntityCount() public view virtual returns (uint256) {
        return entityId;
    }

    function setEntityState(uint256 _entityId, bool _entityState)
        public
        virtual
    {
        if (entityExists(_entityId)) {
            entityStates[_entityId] = _entityState;
        } else {
            revert("The entity does not exist");
        }
    }

    function getEntityState(uint256 _entityId)
        public
        view
        virtual
        returns (bool)
    {
        if (entityExists(_entityId)) {
            return entityStates[_entityId];
        } else {
            revert("The entity does not exist");
        }
    }

    function registerComponent(address _componentAddress, bool _componentState)
        public
        virtual
    {
        require(
            IComponent(_componentAddress).world() == address(this),
            "The component's world address does not match"
        );
        if (componentExists(_componentAddress)) {
            revert("The component has been registered");
        } else {
            components.push(_componentAddress);
            componentStates[_componentAddress] = _componentState;
        }
    }

    function componentExists(address _componentAddress)
        public
        view
        virtual
        returns (bool)
    {
        for (uint256 i = 0; i < components.length; i++) {
            if (components[i] == _componentAddress) {
                return true;
            }
        }
        return false;
    }

    function getComponents() public view virtual returns (address[] memory) {
        return components;
    }

    function setComponentState(address _componentAddress, bool _componentState)
        public
        virtual
    {
        if (componentExists(_componentAddress)) {
            componentStates[_componentAddress] = _componentState;
        } else {
            revert("The component does not exist");
        }
    }

    function getComponentState(address _componentAddress)
        public
        view
        virtual
        returns (bool)
    {
        return componentStates[_componentAddress];
    }

    function addComponent(uint256 _entityId, address _componentAddress)
        public
        virtual
    {
        require(entityStates[_entityId], "Entity is not available");
        require(
            componentStates[_componentAddress],
            "Component is not available"
        );
        if (hasComponent(_entityId, _componentAddress)) {
            revert("The component has been added");
        } else {
            entityComponents[_entityId].push(_componentAddress);
        }
    }

    function hasComponent(uint256 _entityId, address _componentAddress)
        public
        view
        virtual
        returns (bool)
    {
        require(entityExists(_entityId), "The entity does not exist");
        require(componentExists(_componentAddress), "Component not registered");
        for (uint256 i = 0; i < entityComponents[_entityId].length; i++) {
            if (entityComponents[_entityId][i] == _componentAddress) {
                return true;
            }
        }
        return false;
    }

    function removeComponent(uint256 _entityId, address _componentAddress)
        public
        virtual
    {
        require(entityStates[_entityId], "Entity is not available");
        require(
            hasComponent(_entityId, _componentAddress),
            "Component is not attached to entity"
        );

        uint256 removeIndex;
        for (uint256 i = 0; i < entityComponents[_entityId].length; i++) {
            if (entityComponents[_entityId][i] == _componentAddress) {
                removeIndex = i;
            }
        }
        for (
            uint256 i = removeIndex;
            i < entityComponents[_entityId].length - 1;
            i++
        ) {
            entityComponents[_entityId][i] = entityComponents[_entityId][i + 1];
        }
        entityComponents[_entityId].pop();
    }

    function getEntityComponents(uint256 _entityId)
        public
        view
        virtual
        returns (address[] memory)
    {
        if (entityExists(_entityId)) {
            return entityComponents[_entityId];
        } else {
            revert("The entity does not exist");
        }
    }

    function registerSystem(address _systemAddress, bool _componentState)
        public
        virtual
    {
        if (systemExists(_systemAddress)) {
            revert("The system has been registered");
        } else {
            systems.push(_systemAddress);
            systemStates[_systemAddress] = _componentState;
        }
    }

    function systemExists(address _systemAddress)
        public
        view
        virtual
        returns (bool)
    {
        for (uint256 i = 0; i < systems.length; i++) {
            if (systems[i] == _systemAddress) {
                return true;
            }
        }
        return false;
    }

    function getSystems() public view virtual returns (address[] memory) {
        return systems;
    }

    function setSystemState(address _systemAddress, bool _systemState)
        public
        virtual
    {   

        if (systemExists(_systemAddress)) {
             systemStates[_systemAddress] = _systemState;
        } else {
            revert("The system does not exist");
        }
       


    }

    function getSystemState(address _systemAddress)
        public
        view
        virtual
        returns (bool)
    {
        return systemStates[_systemAddress];
    }
}
