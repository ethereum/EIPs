# Ethereum Entity Component System

World contracts are containers for entities, component contracts, and system contracts. Its core principle is to establish the relationship between entities and component contracts, and different entities will attach different components. And use the system contract to dynamically change the data of the entity in the component.
Usual workflow when building ECS-based programs

1. Implement the `IWorld` interface to create a world contract.
2. Call `createEntity()` of the world contract to create an entity.
3. Implement the `IComponent` interface to create a Component contract.
4. Call `registerComponent()` of the world contract to register the component contract.
5. Call `addComponent()` of the world contract to attach the component to the entity.
6. Create a system contract, which is a contract without interface restrictions, and you can define any function in the system contract.
7. Call `registerSystem()` of the world contract to register the system contract.
8. Run the system.

- [`System.sol`](./System.sol)
- [`Types.sol`](./Types.sol)
- [`World.sol`](./World.sol)
- [`Component.sol`](./Component.sol)