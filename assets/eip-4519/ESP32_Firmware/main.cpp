/***
 * This example of ESP32 (Pycom LoPy4) firmware was developed by Javier Arcenegui at "Instituto de 
 * Microelectrónica de Sevilla IMSE-CNM (Universidad de Sevilla-CSIC)" for the EIP4519. This firmware makes the device generate its own Ethereum account and save in the EEPROM the data required in the future to regenerate 
 * the same account. In the newest versions of ESP32 ("ESP32 S2" or 
 * "ESP32 S3") these data can be saved in a protected area. 
 * 
 * The Smart Contract is published on "0x6Dba58fF5AA2d8447C4460d2527033A81646Ae97".
 * It was proved in the Ethereum Kovan testnet.
 * 
 * This code was developed with the infuraIO extension for Visual Studio Code and the Arduino Framework. 
 * The alphawallet/Web3E@^1.22 library must be added in the configuration file (platformio.ini)
 * 
 * Helper data are employed to regenerate the same Ethereum account based on CTR-DRBG PRNG.
 * The helper data format is the following:
 * 
 * ------------------------- Helper data Format -----------------------
 *  |---------------|----------------|----------------|----|----|----|
 *  |     key_ctr   |Personalization | contex_counter | rc | el | ri |
 *  |---------------|----------------|----------------|----|----|----|
 * 51              35               19                3    2    1    0 (Byte)
 * 
 ***/

#include <Arduino.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "mbedtls/ctr_drbg.h"
#include "mbedtls/entropy.h"
#include <Web3.h>
#include <EEPROM.h>
#include "esp_wifi.h"
#include <WiFi.h>
#include <Contract.h>
#include <string>
#include <Util.h>
#include "Trezor/secp256k1.h"
#include "Trezor/ecdsa.h"
#include "Trezor/sha3.h"

#define EEPROM_SIZE 52 //The size required by the 51 bytes of helper data and the byte to know if the token is registered on the blockchain
#define EIP4519CONTRACT "0x6Dba58fF5AA2d8447C4460d2527033A81646Ae97"  //This is the reference for the EIP4519 Smart Non-Fungible Token on Kovan (IT MUST BE CHANGED)

//These are the states of the EIP4519
enum STATES{
    waitingForOwner = 0,
    engagedWithOwner = 1,
    waitingForUser = 2,
    engagedWithUser = 3
};

void setupWifi(); //This function is the same as the wifi example of the ESP32 Arduino Wifi
uint8_t HexTo4Bits(uint8_t Hex); //This function is used to change an hexadecimal defined in ASCII character to a uint8_t
STATES queryTokenStatus(); //This function is used to recover the information of the SmartNFT associated to this device
void hex2Char(unsigned char *inHex, unsigned char *charH, unsigned char *charL); //This function is needed to convert an uint8_t to two ASCII characters

void sendEngage(); //This function sends the hash of the shared key to complete the transaction in Ethereum

//Declaration of the variable to save the state of the SmartNFT
STATES tokenState;

//Declaration of the variables for the private/public Keys and the Address associated

unsigned char privateKey_ethAccount[32];
unsigned char publicKey_ethAccount[64];
unsigned char ethAddress[20];

//Declaration of the variable to save the helper data generated/recovered, which are employed to obtain the private Key of Ethereum account
uint8_t helperData[51];

//These variables are used to save the addresses in ASCII associated to the SmartNFT and the SmartNFT ID
unsigned char OwnerAddress[42];
unsigned char UserAddress[42];
unsigned char deviceAddress[43];
uint32_t tokenID;

//Wifi setup parameters: IT MUST BE CHANGED
int wificounter = 0;
const char *ssid = "<your SSID>";
const char *password = "<your password";

//Infura setup parameters: IT MUST BE CHANGED
const char *INFURA_HOST = "kovan.infura.io"; 
const char *INFURA_PATH = "/v3/c7df4c29472d4d54a39f7aa78f146843"; //Please, use your own path because maybe this path is disabled

Web3 web3(INFURA_HOST, INFURA_PATH);
Crypto crypto(&web3);

//These variables are required to check the authentication with the Owner and the User
uint8_t ADDRESS_E[20];
uint8_t ADDRESS_E_C[20];
uint8_t ADDRESS_V[20];
uint8_t PUBLIC_KEY_E[64];
uint8_t NONCE_E[32];
uint8_t SIGNATURE_E[65];
uint8_t nonceDevice[32];
uint8_t signedDevice[65];
uint8_t PK_XD[64];
uint8_t K_XD[32];
uint8_t hash_K_XD[32];

uint8_t HDState; //This variable is needed to know if the device is registered. If the value is 0, then the helper data are saved

//This defines the string for the token address. It is needed to define correctly the string
string tokenDevice = "0x0000000000000000000000000000000000000000";

void setup() {
  //Initialization of the entropy context of the CTR-DRBG
  mbedtls_entropy_context entropy_context;    
  mbedtls_entropy_init( &entropy_context);    
  mbedtls_ctr_drbg_context ctr_drbg_context;  

  //Check if the device is already registered or a new Ethereum account must be generated
  EEPROM.begin(EEPROM_SIZE);
  HDState = EEPROM.read(0);
  printf("\n%d\n", HDState);
  
  if(HDState){
    //The device is no registered, then a new blockchain account is generated
    esp_fill_random(helperData,51); //esp_fill_random is a "TRNG" to generate all the helper data

    //Setup the startup values of the CT-DRBG PRNG
    char key_ctr[17];

    int i = 0;
  
    for (i = 0; i<16;i++){
      key_ctr[i] = helperData[i+35];
    }

    key_ctr[16] = 0;

    char personalization[17];
    for (i= 0; i<16;i++){
      personalization[i] = helperData[i+19];
    }
    personalization[16] = 0;

    mbedtls_ctr_drbg_init( &ctr_drbg_context);
    
    int ret = mbedtls_ctr_drbg_seed( &ctr_drbg_context , mbedtls_entropy_func, &entropy_context,(const unsigned char *) personalization,strlen( personalization ) );
  
    char ctr_drbg_context_counter[17];
    for (i= 0; i<16;i++){
      personalization[i] = helperData[i+19];
    }
    personalization[16] = 0;

    for (i = 0 ; i<16 ;i++){
      ctr_drbg_context.counter[i] = helperData[i+3];
    }
  
    ctr_drbg_context.reseed_counter = helperData[2];
    ctr_drbg_context.entropy_len = helperData[1];
    ctr_drbg_context.reseed_interval = helperData[0];

    if( ( ret = mbedtls_aes_setkey_enc( &ctr_drbg_context.aes_ctx, (const unsigned char*)&key_ctr, 256 ) ) != 0 ){
      printf("%d\n",ret);
    }
    
    //Generate the Private Key using CTR-DRBG
    ret = mbedtls_ctr_drbg_random( &ctr_drbg_context, privateKey_ethAccount, (size_t)32 );
    if (ret){
      ESP.restart(); //If ret = 0, the data generated is invalid
    }

    //Obtain the address associated to the Private Key
    crypto.PrivateKeyToPublic(privateKey_ethAccount, publicKey_ethAccount);
    crypto.PublicKeyToAddress(publicKey_ethAccount,ethAddress);

    //Share the address. Other information can be shared only at the development process
    printf("\nAddress = 0x");
    for(int i = 0 ; i < 20 ; i++){
      printf("%02x",ethAddress[i]);
    }
    printf("\n");
    //End of setup function at the registration process
  }else{
    //The device is registered
    //Helper data are recovered from EEPROM and set up the startup values of CTR-DRBG PRNG
    for(int i = 0 ; i < 51 ; i++){
      helperData[i] = EEPROM.read(i+1);
    }

    //Setup the startup values of CT-DRBG PRNG
    char key_ctr[17]; 

    int i = 0;
  
    for (i = 0; i<16;i++){
      key_ctr[i] = helperData[i+35];
    }

    key_ctr[16] = 0;

    char personalization[17];
    for (i= 0; i<16;i++){
      personalization[i] = helperData[i+19];
    }
    personalization[16] = 0;

    mbedtls_ctr_drbg_init( &ctr_drbg_context);

    int ret = mbedtls_ctr_drbg_seed( &ctr_drbg_context , mbedtls_entropy_func, &entropy_context,(const unsigned char *) personalization,strlen( personalization ) );
  
    char ctr_drbg_context_counter[17];
    for (i= 0; i<16;i++){
      personalization[i] = helperData[i+19];
    }
    personalization[16] = 0;

    for (i = 0 ; i<16 ;i++){
      ctr_drbg_context.counter[i] = helperData[i+3];
    }
  
    ctr_drbg_context.reseed_counter = helperData[2];
    ctr_drbg_context.entropy_len = helperData[1];
    ctr_drbg_context.reseed_interval = helperData[0];

    if( ( ret = mbedtls_aes_setkey_enc( &ctr_drbg_context.aes_ctx, (const unsigned char*)&key_ctr, 256 ) ) != 0 ){
      printf("%d\n",ret);
    }
    
    //The private Key is generated. The ret value is not needed to be checked
    ret = mbedtls_ctr_drbg_random( &ctr_drbg_context, privateKey_ethAccount, (size_t)32 );
    
    //The address associated to the private Key is generated
    crypto.PrivateKeyToPublic(privateKey_ethAccount, publicKey_ethAccount);
    crypto.PublicKeyToAddress(publicKey_ethAccount,ethAddress);

    //The address obtained is shared
    printf("Address = 0x");
    for(int i = 0 ; i < 20 ; i++){
      printf("%02x",ethAddress[i]);
    }
    printf("\n");

    //Setup wifi connection 
    setupWifi();

    //Obtain the state of the SmartNFT and the information about the SmartNFT
    tokenState = queryTokenStatus();
    //Setup of values needed on each execution state
    switch (tokenState)
    {
    case waitingForOwner:
      //The owner address must be saved to be verified
      printf("Waiting for owner...\n Address to verify = 0x");
      for(int i = 0 ; i < 20 ; i++){
        ADDRESS_V[i] = HexTo4Bits(OwnerAddress[2*i+2])*16+HexTo4Bits(OwnerAddress[2*i+3]);
        printf("%02x",ADDRESS_V[i]);
      }
      printf("\n");
      break;
    case engagedWithOwner:
      printf("Engaged with owner!\n");
      break;
    case waitingForUser:
      //The user address must be saved to be verified
      printf("Waiting for user...\n Address to verify = 0x");
      for(int i = 0 ; i < 20 ; i++){
        ADDRESS_V[i] = HexTo4Bits(UserAddress[2*i+2])*16+HexTo4Bits(UserAddress[2*i+3]);
        printf("%02x",ADDRESS_V[i]);
      }
      printf("\n");
      break;
    case engagedWithUser:
      printf("Engaged with user\n");
      break;
    default:
      break;
    }
  }
  //This message is the same whenever the device is registered or not
  printf("Ready\n");
}

void loop() {
  //This function is executed in a loop 
  //The device checks if the SmartNFT is registered
  if(HDState){
    //If the SmartNFT is not registered then the device waits for the manufacturer to register it 
    uint8_t value = 0;
    scanf("%c",&value);
    if(value == '1'){
      //If character '1' is received, then the device shares its Ethereum address
      printf("{\n");
      printf("\"BCA_Address\" : \"0x");
      for(int i = 0 ; i < 20 ; i++){
        printf("%02x",ethAddress[i]);
      }
      printf("\"\n}\n");
    }
    if(value == '0'){
      //This condition is to check the device status
      printf("ready\n");
    }
    if(value == 'S'){
      //If 'S' is received, the device saves the helper data and changes the EEPROM to be registered
      //and the stated is saved
      EEPROM.write(0,0);
      EEPROM.commit();
      //Save the helper data
      for(int i = 0; i<51; i++){
        EEPROM.write(i+1, helperData[i]);
        EEPROM.commit();
      }
      //After that, the device restarts to change its state
      printf("\nRegistered");
      ESP.restart();

      //This is the end of the loop function if the device is no registered.
    }
  }else{
    //The device is registered 
    setupWifi(); //The Wifi connection is checked
    //The device is waiting for a message from the owner or the user
    uint8_t value;
    scanf("%c",&value);
    if(value == 'Z'){
      //If 'Z' is received, the device starts the verification process
      value = 0;
      while(value == 0){
          scanf("%c",&value);
      }        
      if(value == '0'){
        value = 0;
        while(value == 0){
          scanf("%c",&value);
        }if(value == 'x'){
          for(int i = 0; i <20;i++){
            value = 0;
            while(value == 0){
               scanf("%c",&value);
            }
            ADDRESS_E[i] = HexTo4Bits(value)*16;
            value = 0;
            while(value == 0){
              scanf("%c",&value);
            }
            ADDRESS_E[i] = ADDRESS_E[i] + HexTo4Bits(value);
          }
        } 
        //The device checks if the address received coincides
        bool sameAddress = true;
        for(int i = 0 ; i < 20 ; i++){
          if(ADDRESS_E[i] != ADDRESS_V[i]){
            sameAddress = false;
          }
        }
        if(sameAddress){
          //If the address received coincides, this process continues
          printf("{ \"nonceDevice\" : \"0x");
          for(int i = 0 ; i < 32 ; i++){
            nonceDevice[i]=esp_random();
            printf("%02x",nonceDevice[i]);
          }
          printf("\",");
          printf(" \"type\" : 0}\n");
        }
      }
    }if(value == 'Y'){
      //The new nonce and the signed old nonce are received
      value = 0;
      while(value == 0){
        scanf("%c",&value);
      }
      if(value == '0'){
        value = 0;
        while(value == 0){
          scanf("%c",&value);
        }
        if(value == 'x'){
          for(int i = 0; i <65;i++){
            value = 0;
            while(value == 0){
              scanf("%c",&value);
            }
            SIGNATURE_E[i] = HexTo4Bits(value)*16;
            value = 0;
            while(value == 0){
              scanf("%c",&value);
            }
            SIGNATURE_E[i] = SIGNATURE_E[i] + HexTo4Bits(value);
          }
          
          value = 0;
          while(value == 0){
            scanf("%c",&value);
          }
          if(value == '#'){
            value = 0;
            while(value == 0){
              scanf("%c",&value);
            }
            if(value == '0'){
              value = 0;
              while(value == 0){
                scanf("%c",&value);
              }
              if(value == 'x'){
                for(int i = 0; i <32;i++){
                  value = 0;
                  while(value == 0){
                    scanf("%c",&value);
                  }
                  NONCE_E[i] = HexTo4Bits(value)*16;
                  value = 0;
                  while(value == 0){
                    scanf("%c",&value);
                  }
                  NONCE_E[i] = NONCE_E[i] + HexTo4Bits(value);
                }
              }
            }
          }
          //The signature is checked with the nonce generated by the device
          crypto.ECRecover(SIGNATURE_E,PUBLIC_KEY_E,nonceDevice);
          crypto.PublicKeyToAddress(PUBLIC_KEY_E,ADDRESS_E_C);
          //The address obtained from the signature is checked
          bool sameAddressSig = true;
          for(int i = 0 ; i < 20 ; i++){
            if(ADDRESS_E[i] != ADDRESS_E_C[i]){
              sameAddressSig = false;
            }
          }
          if(crypto.Verify(PUBLIC_KEY_E,nonceDevice,SIGNATURE_E) && sameAddressSig){
            //The signature is verified
            const ecdsa_curve *curve = &secp256k1;
            uint8_t pby;
            //The device signs the nonce received and shares a JSON with this signature
            ecdsa_sign_digest(curve, privateKey_ethAccount, NONCE_E, signedDevice, &pby, NULL);
            printf("{ \"signature\" : \"0x");
            for(int i = 0 ; i < 64 ; i++){
              printf("%02x",signedDevice[i]);
            }
            printf("\", ");
            printf(" \"recNum\" : %d , \"type\" : 1}\n",pby);
          }else{
            //Error
            printf("ERROR");
          }
        }
      }
    }if (value == 'K'){
      //The public Key is received to generate a shared key
	  //The public key allows checking if the message is from the owner or from the user
      value = 0;
      while(value == 0){
        scanf("%c",&value);
      }
      if(value == '0'){
        value = 0;
        while(value == 0){
          scanf("%c",&value);
        }
        if(value == 'x'){
          for(int i = 0; i <65;i++){
            value = 0;
            while(value == 0){
              scanf("%c",&value);
            }
            SIGNATURE_E[i] = HexTo4Bits(value)*16;
            value = 0;
            while(value == 0){
              scanf("%c",&value);
            }
            SIGNATURE_E[i] = SIGNATURE_E[i] + HexTo4Bits(value);
          }
          
          value = 0;
          while(value == 0){
            scanf("%c",&value);
          }
          if(value == '#'){
            value = 0;
            while(value == 0){
              scanf("%c",&value);
            }
            if(value == '0'){
              value = 0;
              while(value == 0){
                scanf("%c",&value);
              }
              if(value == 'x'){
                for(int i = 0; i <64;i++){
                  value = 0;
                  while(value == 0){
                    scanf("%c",&value);
                  }
                  PK_XD[i] = HexTo4Bits(value)*16;
                  value = 0;
                  while(value == 0){
                    scanf("%c",&value);
                  }
                  PK_XD[i] = PK_XD[i] + HexTo4Bits(value);
                }
              }
            }
          }
          //Check signature
          if(crypto.Verify(PUBLIC_KEY_E,PK_XD,SIGNATURE_E)){
            //Verified
            const ecdsa_curve *curve = &secp256k1;
            uint8_t pby;
            ecdsa_sign_digest(curve, privateKey_ethAccount, NONCE_E, signedDevice, &pby, NULL);
            ecdh_multiply(curve, privateKey_ethAccount, PK_XD, K_XD);
            sendEngage();
            //Generate a JSON
            printf("{ \"Shared Key\" : \"0x");
            for(int i = 0 ; i < 32 ; i++){
              printf("%02x",K_XD[i]);
            }
            printf("\", ");
            printf(" \"recNum\" : %d , \"type\" : 3}\n",pby);

          }else{
            //Error
            printf("ERROR");
          }
        }
      }
    }if(value == 'C'){
    <  //Clear EEPROM. This command is only for debug process
      EEPROM.write(0,0xFF);
      EEPROM.commit();
      printf("RESTARTING DEVICE...");
      ESP.restart();
    }if(value == 'R'){
      //Restart device. This command is only for debug process
      printf("RESTARTING DEVICE...");
      ESP.restart();
    }
    //This is the end of the loop function if device is registered
  }
}

void setupWifi(){
  //Same function of ESP32 wifi Example
  if (WiFi.status() == WL_CONNECTED)
    {
        return;
    }

    printf("\n");
    printf("Connecting to ");
    printf(ssid);
    printf("\n");

    if (WiFi.status() != WL_CONNECTED)
    {
        WiFi.persistent(false);
        WiFi.mode(WIFI_OFF);
        WiFi.mode(WIFI_STA);

        WiFi.begin(ssid, password);
    }

    wificounter = 0;
    while (WiFi.status() != WL_CONNECTED && wificounter < 10)
    {
        for (int i = 0; i < 500; i++)
        {
            delay(1);
        }
        printf(".");
        wificounter++;
    }

    if (wificounter >= 10)
    {
        printf("Restarting ...\n");
        ESP.restart(); //Targeting 8266 & ESP32. You may need to replace this

    }

    delay(10);

    printf("\n");
    printf("WiFi connected.\n");
    printf("IP address: %d.%d.%d.%d\n",WiFi.localIP()[0],WiFi.localIP()[1],WiFi.localIP()[2],WiFi.localIP()[3]);
}

STATES queryTokenStatus(){
  Contract contract(&web3, EIP4519CONTRACT);
  //Generate the JSON to check the status  
  deviceAddress[0] = '0';
  deviceAddress[1] = 'x';
  for(int i = 0 ; i < 20 ; i++){
    hex2Char(&ethAddress[i], &deviceAddress[2*i+2], &deviceAddress[2*i+3]);
  }

  String tokenAddress;

  printf("Query Status from token : ");
  for(int i = 0 ; i < 40 ; i++){
    printf("%c",deviceAddress[i+2]);
    tokenDevice[i+2] = deviceAddress[i+2];
  }
  printf("\n");
  

  //Call the function to get SmartNFT information
  String func = "getInfoTokenFromBCA(address)";
  string param = contract.SetupContractData(func.c_str(), &tokenDevice);
  string result = contract.ViewCall(&param);
  
  //When data from blockchain are received, the SmartNFT information is saved
  printf("%s\n",result.c_str());
  int i = 0;
  while(result[i] != 'x'){
    i++;
  }
  i++;
  OwnerAddress[0] = UserAddress[0] = '0';
  OwnerAddress[1] = UserAddress[1] = 'x';
  //Owner address
  for(int j =24;j<64;j++){
    OwnerAddress[j-22] = result[i+j];
  }
  i +=64;
  //User address
  for(int j =24;j<64;j++){
    UserAddress[j-22] = result[i+j];
  }

  printf("\nOwner of token : 0x");
  for(int j = 0 ; j < 40 ; j++){
      printf("%c",OwnerAddress[j+2]);
  }
  printf("\nUser of token : 0x");
  for(int j = 0 ; j < 40 ; j++){
      printf("%c",UserAddress[j+2]);
  }
  i +=64;
  
  //tokenID
  tokenID = HexTo4Bits(result[i+56])*268435456+HexTo4Bits(result[i+57])*16777216+HexTo4Bits(result[i+58])*1048576+HexTo4Bits(result[i+59])*65536+HexTo4Bits(result[i+60])*4096+HexTo4Bits(result[i+61])*256+HexTo4Bits(result[i+62])*16+HexTo4Bits(result[i+63]);
  printf("\nToken ID = %d\n",tokenID);

  //SmartNFT state
  switch ((result[i+63])
  {
  case '1':
    return engagedWithOwner;
    break;
  case '2':
    return waitingForUser;
    break;
  case '3':
    return engagedWithUser;
    break;
  default:
    return waitingForOwner
    break;
  }
}


uint8_t HexTo4Bits(uint8_t Hex){
  if (Hex>='0'&&Hex<='9'){
    return (Hex-'0');
  }else if(Hex>='a'&&Hex<='f'){
    return Hex-'a'+10;
  }else if(Hex>='A'&&Hex<='F'){
    return Hex-'A'+10;
  }
}

void hex2Char(unsigned char *inHex, unsigned char *charH, unsigned char *charL){
  uint8_t charIN[2];
  charIN[0] = (inHex[0] / 16);
  charIN[1] = (inHex[0] % 16);
  if (charIN[0] < 10){
    charH[0] = charIN[0] + '0';
  }else{
    charH[0] = charIN[0] + 'a' - 10;
  }
  if (charIN[1] < 10){
    charL[0] = charIN[1] + '0';
  }else{
    charL[0] = charIN[1] + 'a' - 10;
  }
}

void sendEngage(){
  Contract contract(&web3, EIP4519CONTRACT);
  //Define the function to call the blockchain. This function depends on the SmartNFT state
  string func;  
  if(tokenState == waitingForOwner){
    func = "ownerEngagement(uint256)";  
  }else if(tokenState == waitingForUser){
    func = "userEngagement(uint256)";  
  }

  //Generate the hash of the shared key
  keccak_256(K_XD,32,hash_K_XD);

  //Put this hash as a uint256 variable
  uint256_t hash_K_XD_uin256 = 0;  
  for(int i =0 ; i < 32 ; i++){
    hash_K_XD_uin256 += (uint256_t)hash_K_XD[i]<<8*(7-i); 
  }

  //Call the function
  string param = contract.SetupContractData(func.c_str(), &hash_K_XD_uin256);
  string result = contract.Call(&param);

}
