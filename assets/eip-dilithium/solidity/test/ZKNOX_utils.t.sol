// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ZKNOX_Expand, ZKNOX_Expand_Vec, ZKNOX_Expand_Mat, ZKNOX_Compact} from "../src/ZKNOX_dilithium_utils.sol";

contract UtilsTest is Test {
    function testCompactExpand() public {
        // test of expanding and compacting an element of Fq²⁵⁶ (Dilithium)
        // c is given by 256 Fq element (256 * 32 bits)
        // in compact form, c is given in 32 256-bit integers
        // 1. Expand and get back the 256 Fq elements
        // 2. Compact again
        // 3. Verify the equality with initial value
        uint256[] memory c_ntt = new uint256[](32);
        c_ntt[0] = uint256(0x00b3e4e0025f3f40036eecb002713c5002bc6d400781b0d003c185500329700);
        c_ntt[1] = uint256(0x007803bc006798b8007055c500151f2e00430b7c003d96d10038c7b400145b0a);
        c_ntt[2] = uint256(0x00103e97002e0bb200061e7f003ea088001c0fc900357b80001610fb001a0a92);
        c_ntt[3] = uint256(0x006af2b9006cce480044170a007351fb0060f3450051017a00668c05007d08a6);
        c_ntt[4] = uint256(0x0056d360007dd0af002f7e520039e6cc00227c39007050c4002d5d3e0024a090);
        c_ntt[5] = uint256(0x002506d800575ece00428609003c2ad6005288570073287a0025734f007e0a8b);
        c_ntt[6] = uint256(0x00102eec007b60e5006d4cb4005439a0005a29ef0066f216005bb0f400455f37);
        c_ntt[7] = uint256(0x0040e973003f858800347cf10036cf20005fd870006dccfe0018eedc0074f540);
        c_ntt[8] = uint256(0x00185c60000f06c8006833460044cc0d003c837000184ed3002dd3e500002e1b);
        c_ntt[9] = uint256(0x001be157002e1eb2004684c80026fbbb006477d6002e1eb9001b0b7a004d3b45);
        c_ntt[10] = uint256(0x0070280c003e53e70034694f001bed3e0057832a0048e4e8004ee2be000800c4);
        c_ntt[11] = uint256(0x00481da4003c8e16002f70410050a5ce00488c9f004f2a89003bdae40026398d);
        c_ntt[12] = uint256(0x003f87c10029fda4002929c80008d7aa00662eb8003b7dde0023c7dc0018dce3);
        c_ntt[13] = uint256(0x00669bd800426e99003ffc77002c9c7c000f5aff000469ac005bdf09001828eb);
        c_ntt[14] = uint256(0x0020a159002d1dd300786e84004520ca00495e54004bf1b1003760b90068b666);
        c_ntt[15] = uint256(0x00207fe1000362580059f50000083bce000dcb7b002d4a8c0023b34e004185e4);
        c_ntt[16] = uint256(0x00d996e0028514300097eb5007662ba001e59ab005632450052b7f4007e042b);
        c_ntt[17] = uint256(0x006efb0a006b003400715e25006d6de1007d3a600007c9b2006baf490062af78);
        c_ntt[18] = uint256(0x0020ff7000037cab006b4878007add9f0011f56c000cb17b002507b50053e1df);
        c_ntt[19] = uint256(0x003bc2e1001142bd00613a20003eb2ce0017a9da005a82840066ac74000ea3c0);
        c_ntt[20] = uint256(0x006474d3002487f1000e5c6a007fd72e001ccc9d004f0cdd006115eb003135e5);
        c_ntt[21] = uint256(0x0055c040006beed0002c0da900551daa006cce610010e3950032ee370005aacd);
        c_ntt[22] = uint256(0x006c701100249dec000fc74e0037a81400125bb3004ffa0300002cbc007c48a2);
        c_ntt[23] = uint256(0x002c4d1c0048edd800692551003f7f0d0034854800244fa0002324d3001e838c);
        c_ntt[24] = uint256(0x0058f2f700148f2600750a2f001b44b10040adf0007f9c51000adbd3000b7de3);
        c_ntt[25] = uint256(0x0064f2470072170e003b8e4e0010e6b4006f7cfe0067ea16007be9cc00155927);
        c_ntt[26] = uint256(0x0057cad50061b96f000b753d006fde8100434b45007b16a60030371e001e9f4f);
        c_ntt[27] = uint256(0x002207d90022b1f3000ac8a100227771004f6b6d0021c974007f29850078da21);
        c_ntt[28] = uint256(0x002753920057bb2500291e520029e83b0066c8a9004f04ed0037129900217351);
        c_ntt[29] = uint256(0x006473290071095a0050eb140073c40d0004b5ae00782a070074561e0000109f);
        c_ntt[30] = uint256(0x0018d51c0048847000583a13003aacb7007289ef000d69750014ead3000e1574);
        c_ntt[31] = uint256(0x0072d0ce007c8fb300563b500016500d005c0ede000f93640035797e007dc998);
        uint256[] memory c_ntt_expand = ZKNOX_Expand(c_ntt);
        uint256[] memory c_ntt_back = ZKNOX_Compact(c_ntt_expand);
        for (uint256 i = 0; i < 32; i++) {
            assertEq(c_ntt[i], c_ntt_back[i]);
        }
    }
}
