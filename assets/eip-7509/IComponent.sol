// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0;
import "./Types.sol";

interface IComponent {
    /**
     * The world contract address registered by the component.
     * @return world contract address.
     */
    function world() external view returns (address);

    /**
     *Get the data type and get() parameter type of the component
     * @dev SHOULD Import Types Library, which is an enumeration Library containing all data types.
     * Entity data can be stored according to the data type.
     * The get() parameter data type can be used to get entity data.
     * @return the data type array of the entity
     * @return get parameter data type array
     */
    function types()
        external
        view
        returns (Types.Type[] memory, Types.Type[] memory);

    /**
     *Store entity data.
     * @dev entity MUST be available. The system that operates on it MUST be available.
     * The entity has the component attached.
     * @param _entityId is the Id of the entity.
     * @param _data is the data to be stored.
     */
    function set(uint256 _entityId, bytes memory _data) external;

    /**
     *Get the data of the entity according to the entity Id.
     * @param _entityId is the Id of the entity.
     * @return Entity data.
     */
    function get(uint256 _entityId) external view returns (bytes memory);

    /** Get the data of the entity according to the entity Id and parameters.
     * @param _entityId is the Id of the entity.
     * @param _params is an extra parameter, it SHOULD depend on whether you need it.
     * @return Entity data.
     */
    function get(uint256 _entityId, bytes memory _params)
        external
        view
        returns (bytes memory);
}
