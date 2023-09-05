// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0;

interface IWorld {
    /**
     * Create a new entity.
     * @dev The entity MUST be assigned a unique Id.
     * If the state of the entity is true, it means it is available, and if it is false, it means it is not available.
     * When the state of the entity is false, you cannot add or remove components for the entity.
     * @param _entityState is the state of the entity.
     * @return New entity id.
     */
    function createEntity(bool _entityState) external returns (uint256);

    /**
     * Does the entity exist in the world.
     * @param _entityId is the Id of the entity.
     * @return true exists, false does not exist.
     */
    function entityExists(uint256 _entityId) external view returns (bool);

    /**
     * Get the total number of entities in the world.
     * @return The total number of entities.
     */
    function getEntityCount() external view returns (uint256);

    /**
     * Set the state of an entity.
     * @dev Entity MUST exist.
     * @param _entityId is the Id of the entity.
     * @param _entityState is the state of the entity, true means available, false means unavailable.
     */
    function setEntityState(uint256 _entityId, bool _entityState) external;

    /**
     * Get the state of an entity.
     * @param _entityId Id of the entity.
     * @return The current state of the entity.
     */
    function getEntityState(uint256 _entityId) external view returns (bool);

    /**
     * Register a component to the world.
     * @dev A component MUST be registered with the world before it can be attached to an entity.
     * MUST NOT register the same component to the world repeatedly.
     * It SHOULD be checked that the contract address returned by world() of the component contract is the same as the current world contract.
     * The state of the component is true means it is available, and false means it is not available. When the component state is set to false, it cannot be attached to the entity.
     * @param _componentAddress is the contract address of the component.
     * @param _componentState is the state of the component.
     */
    function registerComponent(address _componentAddress, bool _componentState)
        external;

    /**
     * Does the component exist in the world.
     * @param _componentAddress is the contract address of the component.
     * @return true exists, false does not exist.
     */
    function componentExists(address _componentAddress)
        external
        view
        returns (bool);

    /**
     * Get the contract addresses of all components registered in the world.
     * @return Array of contract addresses.
     */
    function getComponents() external view returns (address[] memory);

    /**
     * Set component state.
     * @dev Component MUST exist.
     * @param _componentAddress is the contract address of the component.
     * @param _componentState is the state of the component, true means available, false means unavailable.
     */
    function setComponentState(address _componentAddress, bool _componentState)
        external;

    /**
     * Get the state of a component.
     * @param _componentAddress is the contract address of the component.
     * @return true means available, false means unavailable.
     */
    function getComponentState(address _componentAddress)
        external
        view
        returns (bool);

    /**
     * Attach a component to the entity.
     * @dev Entity MUST be available.Component MUST be available.A component MUST NOT be added to an entity repeatedly.
     * @param _entityId is the Id of the entity.
     * @param _componentAddress is the address of the component to be attached.
     */
    function addComponent(uint256 _entityId, address _componentAddress)
        external;

    /**
     * Whether the entity has a component attached,
     * @dev Entity MUST exist.Component MUST be registered.
     * @param _entityId is the Id of the entity.
     * @param _componentAddress is the component address.
     * @return true is attached, false is not attached
     */
    function hasComponent(uint256 _entityId, address _componentAddress)
        external
        view
        returns (bool);

    /**
     * Remove a component from the entity.
     * @dev Entity MUST be available.The component MUST have been added to the entity before.
     * @param _entityId is the Id of the entity.
     * @param _componentAddress is the address of the component to be removed.
     */
    function removeComponent(uint256 _entityId, address _componentAddress)
        external;

    /**
     * Get the contract addresses of all components attached to the entity.
     * @dev Entity MUST exist.
     * @param _entityId is the Id of the entity.
     * @return An array of contract addresses of the components owned by this entity.
     */
    function getEntityComponents(uint256 _entityId)
        external
        view
        returns (address[] memory);

    /**
     * Register a system to the world.
     * @dev MUST NOT register the same system to the world repeatedly.The system state is true means available, false means unavailable.
     * @param _systemAddress is the contract address of the system.
     * @param _systemState is the state of the system.
     */
    function registerSystem(address _systemAddress, bool _systemState) external;

    /**
     * Does the system exist in the world.
     * @param _systemAddress is the contract address of the system.
     * @return true exists, false does not exist.
     */
    function systemExists(address _systemAddress) external view returns (bool);

    /**
     * Get the contract addresses of all systems registered in the world.
     * @return Array of contract addresses.
     */
    function getSystems() external view returns (address[] memory);

    /**
     * Set the system State.
     * @dev System MUST exist.
     * @param _systemAddress is the contract address of the system.
     * @param _systemState is the state of the system.
     */
    function setSystemState(address _systemAddress, bool _systemState) external;

    /**
     * Get the state of a system.
     * @param _systemAddress is the contract address of the system.
     * @return The state of the system.
     */
    function getSystemState(address _systemAddress)
        external
        view
        returns (bool);
}
