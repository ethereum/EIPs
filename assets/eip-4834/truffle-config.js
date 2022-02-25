module.exports = {
    networks: {
      development: {
        host: "127.0.0.1",
        port: 8545,
        network_id: "*" // Match any network id
      },
      dashboard: {
        host: "127.0.0.1",
        port: 8545,
        network_id: "*", // Match any network id
        networkCheckTimeout: 120000
      }
    },
    dashboard: {
      port: 24012,
    },   
    compilers: {
      solc: {
        version: "^0.8.9"
      }
    }
  };