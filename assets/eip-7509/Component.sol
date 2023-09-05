// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0;
import "./IWorld.sol";
import "./IComponent.sol";
import "./Types.sol";

contract Component is IComponent {
    address public world;

    constructor(address _world) {
        world = _world;
    }

    struct Position {
        uint256 x;
        uint256 y;
    }
    mapping(uint256 => Position) public Positions;

    function set(uint256 _entityId, bytes memory _data) public {
        require(
            IWorld(world).getEntityState(_entityId) &&
                IWorld(world).getSystemState(msg.sender) &&
                IWorld(world).hasComponent(_entityId, address(this))
        );
        (uint256 x, uint256 y) = abi.decode(_data, (uint256,uint256));
        Position memory position = Position(x,y);
        Positions[_entityId] = position;
    }

    function get(uint256 _entityId) public view returns (bytes memory) {
        return abi.encode(Positions[_entityId].x,Positions[_entityId].y);
    }

    function get(uint256 _entityId, bytes memory _params)
        external
        view
        returns (bytes memory _data)
    {}

    function types()
        public
        pure
        returns (Types.Type[] memory, Types.Type[] memory)
    {
        Types.Type[] memory dataTypeArray = new Types.Type[](2);
        dataTypeArray[0] = Types.Type.UINT256;
        dataTypeArray[1] = Types.Type.UINT256;
        Types.Type[] memory paramsTypeArray = new Types.Type[](0);
        return (dataTypeArray, paramsTypeArray);
    }
}
