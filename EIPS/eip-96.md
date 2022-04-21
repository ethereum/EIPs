---
eip: 96
title: Standardize Lighthouse panda banner as official banner for "The Merge"
description: Logging a panda banner once we reach transition to mark the transition to Proof-Of-Stake
author: Giulio Rebuffo (@Giulio2002)
status: Draft
type: Draft
---

## Abstract

Once reached the point of transition, Consensus Layer clients and Execution Layer Client will be required to log a cool panda banner (kindly stolen by lighthouse), in order to finalize the transition in stone.
## Motivation

Proof-of-Meme

## Specification

Once reached transition, the following message will be printed:
```sh
    ,,,         ,,,                                               ,,,         ,,,
  ;"   ^;     ;'   ",                                           ;"   ^;     ;'   ",
  ;    s$$$$$$$s     ;                                          ;    s$$$$$$$s     ;
  ,  ss$$$$$$$$$$s  ,'  ooooooooo.    .oooooo.   .oooooo..o     ,  ss$$$$$$$$$$s  ,'
  ;s$$$$$$$$$$$$$$$     '888   'Y88. d8P'  'Y8b d8P'    'Y8     ;s$$$$$$$$$$$$$$$
  $$$$$$$$$$$$$$$$$$     888   .d88'888      888Y88bo.          $$$$$$$$$$$$$$$$$$
 $$$$P""Y$$$Y""W$$$$$    888ooo88P' 888      888 '"Y8888o.     $$$$P""Y$$$Y""W$$$$$
 $$$$  p"$$$"q  $$$$$    888        888      888     '"Y88b    $$$$  p"$$$"q  $$$$$
 $$$$  .$$$$$.  $$$$     888        '88b    d88'oo     .d8P    $$$$  .$$$$$.  $$$$
  $$DcaU$$$$$$$$$$      o888o        'Y8bood8P' 8""88888P'      $$DcaU$$$$$$$$$$
    "Y$$$"*"$$$Y"                                                 "Y$$$"*"$$$Y"
        "$b.$$"                                                       "$b.$$"
       .o.                   .   o8o                         .                 .o8
      .888.                .o8   '"'                       .o8                "888
     .8"888.     .ooooo. .o888oooooo oooo    ooo .oooo.  .o888oo .ooooo.  .oooo888
    .8' '888.   d88' '"Y8  888  '888  '88.  .8' 'P  )88b   888  d88' '88bd88' '888
   .88ooo8888.  888        888   888   '88..8'   .oP"888   888  888ooo888888   888
  .8'     '888. 888   .o8  888 . 888    '888'   d8(  888   888 .888    .o888   888
 o88o     o8888o'Y8bod8P'  "888"o888o    '8'    'Y888""8o  "888"'Y8bod8P''Y8bod88P
```
## Rationale

I like panda.

## Backwards Compatibility

Backward Compatible.

## Reference Implementation

https://github.com/ledgerwatch/erigon/blob/58c86d550d696cb04f8ba76ea7c41b1b3793e551/turbo/stages/headerdownload/header_algos.go#L34

## Security Considerations

none

## Copyright

Lighthouse made the banner, so it is lincensed under Apache.
