# Test Vectors for EIP-1057 - ProgPow

Many of these vectors are dervived from [chfast/ethash](https://github.com/chfast/ethash)

## fnv1a

|          `h` |          `d` |     _result_ |
| -----------: | -----------: | -----------: |
| `0X811C9DC5` | `0XDDD0A47B` | `0XD37EE61A` |
| `0XD37EE61A` | `0XEE304846` | `0XDEDC7AD4` |
| `0XDEDC7AD4` | `0X00000000` | `0XA9155BBC` |

## kiss99

For `z`=`362436069`, `w`=`521288629`, `jsr`=`123456789`, and `jcong`=`380116160` the result of each iterative call to `kiss99` is as follows:

| _iteration_ |     _result_ |kernel
| ----------: | -----------: |
|         `1` |  `769445856` |
|         `2` |  `742012328` |
|         `3` | `2121196314` |
|         `4` | `2805620942` |
|    `100000` |  `941074834` |

## fill_mix

For `hash_seed`=`0xEE304846DDD0A47B` and `lane_id`=`0` the values stored in the `mix` array will be

> ```
> 0x10C02F0D, 0x99891C9E, 0xC59649A0, 0x43F0394D,
> 0x24D2BAE4, 0xC4E89D4C, 0x398AD25C, 0xF5C0E467,
> 0x7A3302D6, 0xE6245C6C, 0x760726D3, 0x1F322EE7,
> 0x85405811, 0xC2F1E765, 0xA0EB7045, 0xDA39E821,
> 0x79FC6A48, 0x089E401F, 0x8488779F, 0xD79E414F,
> 0x041A826B, 0x313C0D79, 0x10125A3C, 0x3F4BDFAC,
> 0xA7352F36, 0x7E70CB54, 0x3B0BB37D, 0x74A3E24A,
> 0xCC37236A, 0xA442B311, 0x955AB27A, 0x6D175B7E
> ```

For the same hash and `lane_id`=`13` the value in the `mix` array will be

> ```
> 0x4E46D05D, 0x2E77E734, 0x2C479399, 0x70712177,
> 0xA75D7FF5, 0xBEF18D17, 0x8D42252E, 0x35B4FA0E,
> 0x462C850A, 0x2DD2B5D5, 0x5F32B5EC, 0xED5D9EED,
> 0xF9E2685E, 0x1F29DC8E, 0xA78F098B, 0x86A8687B,
> 0xEA7A10E7, 0xBE732B9D, 0x4EEBCB60, 0x94DD7D97,
> 0x39A425E9, 0xC0E782BF, 0xBA7B870F, 0x4823FF60,
> 0xF97A5A1C, 0xB00BCAF4, 0x02D0F8C4, 0x28399214,
> 0xB4CCB32D, 0x83A09132, 0x27EA8279, 0x3837DDA3
> ```

## keccak_f800_progpow

Test case 1:

|          |                                                                                                                   |
| -------- | ----------------------------------------------------------------------------------------------------------------- |
| header   | `0xCCDDEEFF`, `0x8899AABB`, `0x44556677`, `0x00112233`,<br>`0x33221100`, `0x77665544`, `0xBBAA9988`, `0xFFEEDDCC` |
| seed     | `0x123456789ABCDEF0`                                                                                              |
| digest   | `0x00000000`, `0x00000000`, `0x00000000`, `0x00000000`,<br>`0x00000000`, `0x00000000`, `0x00000000`, `0x00000000` |
| _result_ | `0x464830EE`, `0x7BA4D0DD`, `0x969E1798`, `0xCEC50EB6`,<br>`0x7872E2EA`, `0x597E3634`, `0xE380E73D`, `0x2F89D1E6` |

Test case 2:

|          |                                                                                                                   |
| -------- | ----------------------------------------------------------------------------------------------------------------- |
| header   | `0xCCDDEEFF`, `0x8899AABB`, `0x44556677`, `0x00112233`,<br>`0x33221100`, `0x77665544`, `0xBBAA9988`, `0xFFEEDDCC` |
| seed     | `0xEE304846DDD0A47B`                                                                                              |
| digest   | `0x0598F111`, `0x66B48AC5`, `0x719CFF10`, `0x5F0ACF9D`,<br>`0x162FFA18`, `0xEF8E7905`, `0x21470C77`, `0x7D767492` |
| _result_ | `0x47CD7C5B`, `0xD9FDBE2D`, `0xAC5C895B`, `0xFF67CE8E`,<br>`0x6B5AEB0D`, `0xE1C6ECD2`, `0x003D3862`, `0xCE8E72C3` |

## progPowInit

For ProgPow period 600 (block 30,000) the configurations should be

src array:

> `0x1A`, `0x1E`, `0x01`, `0x13`, `0x0B`, `0x15`, `0x0F`, `0x12`,
> `0x03`, `0x11`, `0x1F`, `0x10`, `0x1C`, `0x04`, `0x16`, `0x17`,
> `0x02`, `0x0D`, `0x1D`, `0x18`, `0x0A`, `0x0C`, `0x05`, `0x14`,
> `0x07`, `0x08`, `0x0E`, `0x1B`, `0x06`, `0x19`, `0x09`, `0x00`

dst array

> `0x00`, `0x04`, `0x1B`, `0x1A`, `0x0D`, `0x0F`, `0x11`, `0x07`,
> `0x0E`, `0x08`, `0x09`, `0x0C`, `0x03`, `0x0A`, `0x01`, `0x0B`,
> `0x06`, `0x10`, `0x1C`, `0x1F`, `0x02`, `0x13`, `0x1E`, `0x16`,
> `0x1D`, `0x05`, `0x18`, `0x12`, `0x19`, `0x17`, `0x15`, `0x14`

Kiss 99 state:
`z`=`0x6535921C` `w`=`0x29345B16`, `jsr`=`0xC0DD7F78`, `jcong`=`0x1165D7EB`

## merge

| `a`          | `b`          | `r`          | _result_     | _path exercised_ |
| ------------ | ------------ | ------------ | ------------ | ---------------- |
| `0x3B0BB37D` | `0xA0212004` | `0x9BD26AB0` | `0x3CA34321` | mul/add          |
| `0x10C02F0D` | `0x870FA227` | `0xD4F45515` | `0x91C1326A` | xor/mul          |
| `0x24D2BAE4` | `0x0FFB4C9B` | `0x7FDBC2F2` | `0x2EDDD94C` | rotl/xor         |
| `0xDA39E821` | `0x089C4008` | `0x8B6CD8C3` | `0x8A81E396` | rotr/xor         |

## math

| `a`          | `b`          | `r`          | _result_     | _operation exercised_   |
| ------------ | ------------ | ------------ | ------------ | ----------------------- |
| `0x8626BB1F` | `0xBBDFBC4E` | `0x883E5B49` | `0x4206776D` | add                     |
| `0x3F4BDFAC` | `0xD79E414F` | `0x36B71236` | `0x4C5CB214` | mul                     |
| `0x6D175B7E` | `0xC4E89D4C` | `0x944ECABB` | `0x53E9023F` | mul_hi32                |
| `0x2EDDD94C` | `0x7E70CB54` | `0x3F472A85` | `0x2EDDD94C` | min                     |
| `0x61AE0E62` | `0xe0596b32` | `0x3F472A85` | `0x61AE0E62` | min again (unsigned)    |
| `0x8A81E396` | `0x3F4BDFAC` | `0xCEC46E67` | `0x1E3968A8` | rotl32                  |
| `0x8A81E396` | `0x7E70CB54` | `0xDBE71FF7` | `0x1E3968A8` | rotr32                  |
| `0xA7352F36` | `0xA0EB7045` | `0x59E7B9D8` | `0xA0212004` | bitwise and             |
| `0xC89805AF` | `0x64291E2F` | `0x1BDC84A9` | `0xECB91FAF` | bitwise or              |
| `0x760726D3` | `0x79FC6A48` | `0xC675CAC5` | `0x0FFB4C9B` | bitwise xor             |
| `0x75551D43` | `0x3383BA34` | `0x2863AD31` | `0x00000003` | clz (leading zeros)     |
| `0xEA260841` | `0xE92C44B7` | `0xF83FFE7D` | `0x0000001B` | popcount (number of 1s) |

## progPowLoop

For the first loop iteration of block 30,000 the seed to use for `fill_mix`
would be `0xEE304846DDD0A47B`. A two dimensional `mix` array should be created
passing the rows into `fill_mix` witht he column number as the loop argument.

The state of the mix array after the call to `progPowLoop` for block 30,000, 
loop 1 are as follows.

`mix[0]` -

> ```
> 0x40E09E9C, 0x967A7DF0, 0x8626BB1F, 0x12C2392F,
> 0xA21D8305, 0x44C2702E, 0x94C93945, 0x6B66B158,
> 0x0CF00FAA, 0x26F5E6B5, 0x36EC0134, 0xC89805AF,
> 0x58118540, 0x8617DC4D, 0xC759F486, 0x8A81E396,
> 0x22443D4D, 0x64291E2F, 0x1998AB7F, 0x11C0FBBB,
> 0xBEA9C139, 0x82D1E47E, 0x7ED3E850, 0x2F81531A,
> 0xBBDFBC4E, 0xF58AEE4D, 0x3CA34321, 0x357BD48A,
> 0x2F9C8B5D, 0x2319B193, 0x2856BB38, 0x2E3C33E6
> ```

`mix[1]` -

> ```
> 0x4EB8A8F9, 0xD978BF17, 0x7D5074D4, 0x7A092D5D,
> 0x8682D1BE, 0xC3D2941C, 0xF1A1A38B, 0x54BB6D34,
> 0x2F0FB257, 0xB5464B50, 0x40927B67, 0xBB92A7E1,
> 0x1305A517, 0xE06C6765, 0xA75FD647, 0x9F232D6E,
> 0x0D9213ED, 0x8884671D, 0x54352B96, 0x6772E58E,
> 0x1B8120C9, 0x179F3CFB, 0x116FFC82, 0x6D019BCE,
> 0x1C26A750, 0x89716638, 0x02BEB948, 0x2E0AD5CE,
> 0x7FA915B2, 0x93024F2F, 0x2F58032E, 0xF02E550C
> ```

`mix[2]` -

> ```
> 0x008FF9BD, 0xC41F9802, 0x2E36FDC8, 0x9FBA2A91,
> 0x0A921670, 0x231308E6, 0xEF09A56E, 0x9657A64A,
> 0xF67723FE, 0x963DCD40, 0x354CBFDB, 0x57C07B9A,
> 0x06AF5B40, 0xBA5DE5A6, 0xDA5AAE7B, 0x9F8A5E4B,
> 0x7D6AFC9A, 0xE4783F78, 0x89B24946, 0x5EE94228,
> 0xA209DAAA, 0xDCC27C64, 0x3366FBED, 0x0FEFB673,
> 0x0FC205E3, 0xB61515B2, 0x70A45E9B, 0xBB225E5D,
> 0xB8C38EA0, 0xE01DE9B4, 0x866FAA5B, 0x1A125220
> ```

`mix[3]` -

> ```
> 0xE5F9C5CC, 0x6F75CFA2, 0xE0F50924, 0xE7B4F5EF,
> 0x779B903D, 0x5F068253, 0x05FF68E5, 0x39348653,
> 0x654B89E4, 0x0559769E, 0xA3D46B93, 0xD084454D,
> 0xCFC5CF7D, 0x8C11D8E4, 0x795BDB59, 0xD9E03113,
> 0xBAE8C355, 0x12B63814, 0x4046A018, 0xA269A32E,
> 0x54A57C4B, 0x2ED1065B, 0xB69A2C76, 0x4AEF0950,
> 0x6C2D187B, 0x8252FAE7, 0x3E9C0ED2, 0x26E47B15,
> 0xFEFB48E3, 0xDA088C7F, 0xA82B0379, 0xA49C6D86
> ```

`mix[4]` -

> ```
> 0xB926334C, 0x686A29AF, 0xD9E2EF15, 0x1C8A2D39,
> 0x307ED4F4, 0x2ABB1DB6, 0xD6F95128, 0xDFCA05F8,
> 0x904D9472, 0xEC09E200, 0x7143F47F, 0xEE488438,
> 0xFCA48DA8, 0xA64C7DD4, 0xC4AE9A30, 0xEBA30BC9,
> 0xB02630BF, 0xD1DF40CC, 0x4DFE8B7B, 0x205C97B3,
> 0xE40376F8, 0x2491117E, 0x34984321, 0xA01546A7,
> 0xB254F2F9, 0xC78A7C25, 0xFFC615E2, 0x5839FC88,
> 0x2A04DF6C, 0xC02A9A8A, 0x39238EAD, 0x7139060C
> ```

`mix[5]` -

> ```
> 0xC416E54B, 0x64AD1C57, 0xBF7CBA55, 0x176F714E,
> 0xBE733426, 0x995C4132, 0x5F50F779, 0x0F76FDF3,
> 0x526F7870, 0xE56A1A8A, 0xDCEB677E, 0xD471CC19,
> 0xA9ED60E4, 0x145E807F, 0x8D652E92, 0x80E8116F,
> 0xFF1A37EB, 0x1E0C49A1, 0x59D756DA, 0x39A8E761,
> 0x2F0F646F, 0x43F41278, 0x88CC48DA, 0x8FDFF7A4,
> 0x9AEACA2E, 0x59E7808C, 0x7F72E46B, 0xCA572333,
> 0xC6029C88, 0x7736E592, 0xF1338231, 0x262B2C7F
> ```

`mix[6]` -

> ```
> 0x3C554151, 0x70999423, 0x64BB49A8, 0xF9EBE9E9,
> 0x7D9C28CF, 0x23EE7659, 0xD6504FCF, 0x1C58C2A1,
> 0x62B9C627, 0x680AE248, 0xF196A153, 0x2A3C345A,
> 0x860E6EB2, 0x266D2652, 0x3C9F2420, 0xF790A538,
> 0x710A5523, 0xBEA2603A, 0x1C1CC272, 0xF91D482A,
> 0x1CA19931, 0x7A80ED37, 0x9572513D, 0x376F1CFE,
> 0xE57C1264, 0xE47BF931, 0xC7310E05, 0x7866CC9E,
> 0xC676BBD5, 0x4C167FEB, 0x0FE03D2B, 0x46C6D26C
> ```

`mix[7]` -

> ```
> 0x3395F65A, 0x7142A5B1, 0x97780661, 0xE5EE45B8,
> 0xCD9FDC42, 0x25BF044C, 0x0350F81B, 0x55D50703,
> 0xA8CB893E, 0xEE795201, 0xC2D6E598, 0xC2AC2D7A,
> 0xD2E81716, 0xAD876790, 0x0F3339C7, 0xEEC31E01,
> 0xA293ABF6, 0x28AE317D, 0x44A7AC05, 0xBEBA1C5E,
> 0x325ED29E, 0x4344131E, 0x921CD8DD, 0x08AB9E0B,
> 0xC18E66A6, 0x87E6BCA3, 0x24CE82AE, 0xC910B4F1,
> 0x9E513EC0, 0xA1B8CB76, 0xF0455815, 0x36BC0DCF
> ```

`mix[8]` -

> ```
> 0x0117C85F, 0xE018F2C6, 0x416C897D, 0x9D288A0F,
> 0x2AA9EA93, 0x5A6D3CEA, 0xAA99B726, 0x0A42DAB7,
> 0x72F6EA4A, 0x1DB074E6, 0x2E2A606C, 0xAC5D509B,
> 0x53F13E85, 0x1D44B521, 0x24234C42, 0xAD5BAD70,
> 0xAB2DA791, 0x6479546A, 0xD27B3771, 0xBB0A09DD,
> 0x6D3C8056, 0x96572D4B, 0x52DB6535, 0x3D242BC1,
> 0xF37D7C7A, 0xA60F7111, 0x59B59667, 0xF28635B0,
> 0xC2A8F9F5, 0x7CFB9CCB, 0xDF8697AA, 0xA3260D94
> ```

`mix[9]` -

> ```
> 0xA387FC4B, 0xC757D3A0, 0xA584E879, 0xB0A1EC29,
> 0x82CB2EC3, 0x6BF33664, 0x41FECC42, 0xF60C2AC5,
> 0xEA250BE5, 0x42BE9F33, 0x9227B0B3, 0x9080A6AB,
> 0xAF193598, 0xC708BC8A, 0x020CDEDB, 0x7FA2F773,
> 0x4338E670, 0x069E0242, 0x5AD87326, 0xD7A87124,
> 0x220D5C46, 0x26D3400D, 0x4899D1EE, 0x90EAD2F6,
> 0xFA3F1F74, 0x9C5A5D58, 0xAE20567C, 0x424B690D,
> 0xC9A4057A, 0x9F2A5CD1, 0xAA33CD5F, 0x18F58C00
> ```

`mix[10]` -

> ```
> 0xEAFE893C, 0x1ABB2971, 0x29803BB3, 0x5BC2F71F,
> 0x619DAFAD, 0xD9CFEFB6, 0xB4FEFAB5, 0x5EB249EC,
> 0x1A6E2B3A, 0xFB05DD28, 0xDCB33C2E, 0x630BB8AE,
> 0x43463B39, 0x3BD2F552, 0xFB20C0A2, 0x3383BA34,
> 0x2E9C1A99, 0x60A949B2, 0x861372AB, 0xC149D929,
> 0xA77A0A93, 0xE0CEE0D9, 0x791E7E82, 0x66A8D75A,
> 0x44D1845F, 0xE534DC4A, 0x2C7DD20C, 0xEEDAB329,
> 0x3209FE2A, 0x0C0406BC, 0xD6D4BD2A, 0x5FDB13CC
> ```

`mix[11]` -

> ```
> 0x2520ABB3, 0xCD942485, 0x9A2929BC, 0x0E10F18C,
> 0xDFB1815E, 0x8BEF05A3, 0x531A8837, 0x668838E4,
> 0xBACCE200, 0x003F85C2, 0x56226F05, 0xC2233173,
> 0x2F39A0D9, 0xF4466D0D, 0x0B9E686C, 0x82C69BDA,
> 0x0C8A8CD6, 0xA93F3001, 0x36A65EC1, 0x40CCFD7A,
> 0x84484E23, 0xF0896D45, 0x06D9F760, 0x6559142C,
> 0x9FFE2E88, 0x9593DC89, 0x89C9E3B9, 0x33285F41,
> 0x16F636C8, 0xA08169C7, 0xA5E1C956, 0xC22CCF52
> ```

`mix[12]` -

> ```
> 0xDC3B8CAA, 0xC6941197, 0x9969D596, 0x46453D3E,
> 0x568EAFEA, 0x5B823345, 0xDE606E8E, 0x7523C86D,
> 0x0EDAF441, 0x00C3D848, 0xAE5BAB99, 0xD705B9EE,
> 0x54B49E3D, 0xF364A6A4, 0x42C55975, 0xFE41EED5,
> 0xAD46170F, 0xAABE4868, 0x270379F9, 0xD33D0D7C,
> 0xF39C476C, 0xA449118E, 0x71BCC1E4, 0x5E300E77,
> 0x1CACD489, 0x4D82FABD, 0x090F9F80, 0xB2DB9626,
> 0xE12A973B, 0x1B77460C, 0xD25F89F5, 0x5753612E
> ```

`mix[13]` -

> ```
> 0x042D951C, 0x38833AA7, 0xBEA9894D, 0x7AE7F381,
> 0x42DB6723, 0x1FB0294F, 0x41452A28, 0xA7A97B9C,
> 0x228AA7EA, 0x781A7420, 0x4589736D, 0xB3C19349,
> 0x685EF9E6, 0xB4987DF6, 0xC9C3B188, 0x2DCA6A03,
> 0xE89A6D3D, 0x50EF7CF5, 0xF6274868, 0x8AA22824,
> 0x980FFDE3, 0xD4A6CB4E, 0x06FF9E1A, 0xBADB6DF5,
> 0xEDE3ADF3, 0xC9CF45F6, 0xFDFA194C, 0xAF076AA8,
> 0x7B876CEA, 0xB0C89575, 0x35A72155, 0x6CFDFC06
> ```

`mix[14]` -

> ```
> 0x0E3E28C8, 0xEC329DEC, 0x06D0A1D1, 0xF95ABEF8,
> 0x168DCF28, 0xDD7714C1, 0x769C119E, 0xA5530A7D,
> 0x1EEACB59, 0x30FD21BB, 0x082A3691, 0x1C4C9BCA,
> 0x420F27DE, 0xA8FDA3AE, 0xE182142E, 0x5102F0FF,
> 0x15B82277, 0x120C3217, 0x7BE714ED, 0xA251DCD5,
> 0x6FB4F831, 0xB71D7B32, 0xD5F7A04A, 0x763E1A20,
> 0x38E68B0C, 0xBB5A4121, 0x9340BF06, 0x948B03F8,
> 0xE71BF17B, 0x1BB5F06B, 0x26F2A200, 0x5F28C415
> ```

`mix[15]` -

> ```
> 0xC818CD64, 0xBC910343, 0xB18B7776, 0x7182DEBA,
> 0x9DB319EE, 0x9AE7F32F, 0x3CA9F8B5, 0xC63F48ED,
> 0x8321533A, 0x059C96B1, 0x8DCDA60A, 0x75B6C1D1,
> 0xC3406B57, 0x3DFE9E9B, 0xC01E1FD7, 0xC4643218,
> 0x6873F0BA, 0x8ABD36B9, 0xA74D0CBD, 0x8A637118,
> 0x6916416C, 0xB6E3A8DD, 0xB68DD4FA, 0xFBD543EE,
> 0x56F05592, 0x33D6DB82, 0x58D0A7DD, 0x18630C6E,
> 0xB33749CA, 0x5D2E87F7, 0x0F3C39DB, 0x3CAE9895
> ```

## progPowHash

### 0.9.2
[Machine-readable data](https://github.com/ethereum/EIPs/blob/ad4e73f239d53d72a21cfd8fdc89dc81eb9d2688/assets/eip-1057/test-vectors-0.9.3.json)

Block 30000:

- `prog_seed` - 600
- `nonce` - `123456789abcdef0`
- `header` - `ffeeddccbbaa9988776655443322110000112233445566778899aabbccddeeff`
- `mix_hash` - `11f19805c58ab46610ff9c719dcf0a5f18fa2f1605798eef770c47219274767d`
- `final_hash` - `5b7ccd472dbefdd95b895cac8ece67ff0deb5a6bd2ecc6e162383d00c3728ece`

Block 0:

- `prog_seed` - 0
- `nonce` - `0000000000000000`
- `header` - `0000000000000000000000000000000000000000000000000000000000000000`
- `mix_hash` - `faeb1be51075b03a4ff44b335067951ead07a3b078539ace76fd56fc410557a3`
- `final_hash` - `63155f732f2bf556967f906155b510c917e48e99685ead76ea83f4eca03ab12b`

Block 49:

- `prog_seed` - 0
- `nonce` - `0000000006ff2c47`
- `header` - `63155f732f2bf556967f906155b510c917e48e99685ead76ea83f4eca03ab12b`
- `mix_hash` - `c789c1180f890ec555ff42042913465481e8e6bc512cb981e1c1108dc3f2227d`
- `final_hash` - `9e7248f20914913a73d80a70174c331b1d34f260535ac3631d770e656b5dd922`

Block 50:

- `prog_seed` - 1
- `nonce` - `00000000076e482e`
- `header` - `9e7248f20914913a73d80a70174c331b1d34f260535ac3631d770e656b5dd922`
- `mix_hash` - `c7340542c2a06b3a7dc7222635f7cd402abf8b528ae971ddac6bbe2b0c7cb518`
- `final_hash` - `de37e1824c86d35d154cf65a88de6d9286aec4f7f10c3fc9f0fa1bcc2687188d`

Block 99:

- `prog_seed` - 1
- `nonce` - `000000003917afab`
- `header` - `de37e1824c86d35d154cf65a88de6d9286aec4f7f10c3fc9f0fa1bcc2687188d`
- `mix_hash` - `f5e60b2c5bfddd136167a30cbc3c8dbdbd15a512257dee7964e0bc6daa9f8ba7`
- `final_hash` - `ac7b55e801511b77e11d52e9599206101550144525b5679f2dab19386f23dcce`

Block 29,950:

- `prog_seed` - 599
- `nonce` - `005d409dbc23a62a`
- `header` - `ac7b55e801511b77e11d52e9599206101550144525b5679f2dab19386f23dcce`
- `mix_hash` - `07393d15805eb08ee6fc6cb3ad4ad1010533bd0ff92d6006850246829f18fd6e`
- `final_hash` - `e43d7e0bdc8a4a3f6e291a5ed790b9fa1a0948a2b9e33c844888690847de19f5`

Block 29,999:

- `prog_seed` - 599
- `nonce` - `005db5fa4c2a3d03`
- `header` - `e43d7e0bdc8a4a3f6e291a5ed790b9fa1a0948a2b9e33c844888690847de19f5`
- `mix_hash` - `7551bddf977491da2f6cfc1679299544b23483e8f8ee0931c4c16a796558a0b8`
- `final_hash` - `d34519f72c97cae8892c277776259db3320820cb5279a299d0ef1e155e5c6454`

Block 30,000:

- `prog_seed` - 600
- `nonce` - `005db8607994ff30`
- `header` - `d34519f72c97cae8892c277776259db3320820cb5279a299d0ef1e155e5c6454`
- `mix_hash` - `f1c2c7c32266af9635462e6ce1c98ebe4e7e3ecab7a38aaabfbf2e731e0fbff4`
- `final_hash` - `8b6ce5da0b06d18db7bd8492d9e5717f8b53e7e098d9fef7886d58a6e913ef64`

Block 30,049:

- `prog_seed` - 600
- `nonce` - `005e2e215a8ca2e7`
- `header` - `8b6ce5da0b06d18db7bd8492d9e5717f8b53e7e098d9fef7886d58a6e913ef64`
- `mix_hash` - `57fe6a9fbf920b4e91deeb66cb0efa971e08229d1a160330e08da54af0689add`
- `final_hash` - `c2c46173481b9ced61123d2e293b42ede5a1b323210eb2a684df0874ffe09047`

Block 30,050:

- `prog_seed` - 601
- `nonce` - `005e30899481055e`
- `header` - `c2c46173481b9ced61123d2e293b42ede5a1b323210eb2a684df0874ffe09047`
- `mix_hash` - `ba30c61cc5a2c74a5ecaf505965140a08f24a296d687e78720f0b48baf712f2d`
- `final_hash` - `ea42197eb2ba79c63cb5e655b8b1f612c5f08aae1a49ff236795a3516d87bc71`

Block 30,099:

- `prog_seed` - 601
- `nonce` - `005ea6aef136f88b`
- `header` - `ea42197eb2ba79c63cb5e655b8b1f612c5f08aae1a49ff236795a3516d87bc71`
- `mix_hash` - `cfd5e46048cd133d40f261fe8704e51d3f497fc14203ac6a9ef6a0841780b1cd`
- `final_hash` - `49e15ba4bf501ce8fe8876101c808e24c69a859be15de554bf85dbc095491bd6`

Block 59,950:

- `prog_seed` - 1,199
- `nonce` - `02ebe0503bd7b1da`
- `header` - `49e15ba4bf501ce8fe8876101c808e24c69a859be15de554bf85dbc095491bd6`
- `mix_hash` - `21511fbaa31fb9f5fc4998a754e97b3083a866f4de86fa7500a633346f56d773`
- `final_hash` - `f5c50ba5c0d6210ddb16250ec3efda178de857b2b1703d8d5403bd0f848e19cf`

Block 59,999:

- `prog_seed` - 1,199
- `nonce` - `02edb6275bd221e3`
- `header` - `f5c50ba5c0d6210ddb16250ec3efda178de857b2b1703d8d5403bd0f848e19cf`
- `mix_hash` - `653eda37d337e39d311d22be9bbd3458d3abee4e643bee4a7280a6d08106ef98`
- `final_hash` - `341562d10d4afb706ec2c8d5537cb0c810de02b4ebb0a0eea5ae335af6fb2e88`

Block 10,000,000:

- `prog_seed` - 200,000
- `nonce` - `005e30899481055e`
- `header` - `efda178de857b2b1703d8d5403bd0f848e19cff5c50ba5c0d6210ddb16250ec3`
- `mix_hash` - `b2403f56c426177856eaf0eedd707c86ae78a432b9169c3689a67058fcf2a848`
- `final_hash` - `206aee640c0fd21473d5cc3654d63c80442d9e2dfa676d2801d3ec1fbab38a6d`

Block 100,000,000:

- `prog_seed` - 2,000,000
- `nonce` - `02abe0589481055e`
- `header` - `49e15ba4bf501ce8fe88765403bd0f848e19cff5c50ba5c0d6210ddb16250ec3`
- `mix_hash` - `ac452084d6f4e6eacf4282ad58dbd4ce7ef2653fb5e6b5c877f56928c907432a`
- `final_hash` - `b879f84923e71b812ef5a42ece0b5b9366c31cab218f40afe65f8a2cae448a6f`

### 0.9.3
[Machine-readable data](https://github.com/ethereum/EIPs/blob/ad4e73f239d53d72a21cfd8fdc89dc81eb9d2688/assets/eip-1057/test-vectors-0.9.3.json)
