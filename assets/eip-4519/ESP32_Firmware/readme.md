#EIP4519 Proof of Concept - Firmware
This firmware is designed for a device using an ESP32 as a smart asset associated with an EIP4519 SmartNFT. The device has two operation modes: registration mode and application mode.
##Registration mode 
In this mode, the device generates 51 bytes  with the TRNG of the ESP32 core. Those bytes are used for the initial values of a CTR-DRBG PRNG to generate the private key of the Ethereum account. Only the address of this account is shared. The UART port is needed for communications with this device.
The commands in this mode are:
>‘0’ – Check if the device is ready.
>‘1’ – Share the address of the account.
>‘2’ – Save the initial values of CTR-DRBG PRNG in an EEPROM and changes the operation mode.
##Application Mode
The device reads the EEPROM to obtain the initial values of the CTR-DRBG PRNG and recover the Ethereum account. The device connects to a WiFi station. With Infura, the device checks the state of its associated SmartNFT registered on an EIP4519 Smart Contract and also checks if the device must be engaged with the owner or the user. The UART port is needed for communications with this device.
The commands in this mode are:
>'Z'+OWNER/USER_ADDRESS – The device checks if the address must be authenticated and generates a nonce.
>'Y'+SIGN_D+'#'+NONCE_D – The device checks the signature, signs NONCE_D, and sends the signature.
>'Y'+SIGNED_PK+'#'+PK – The device checks the signature, generates the shared key, and sends the transaction to the EIP4519 Smart Contract.
>'C' – The EEPROM is cleared, only for debug process.
>'R' – The device is restarted to refresh the SmartNFT state, only for debug process.
