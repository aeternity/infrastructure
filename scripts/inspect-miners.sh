#!/bin/bash

START_HEIGHT=$1
OFFSET=${2:-10}
API="https://mainnet.aeternity.io"

TWO_MINERS_ADDR="ak_dArxCkAsk1mZB1L9CX3cdz1GDN4hN84L3Q8dMLHN4v8cU85TF"
WOOLY_POOLY_ADDR="ak_wM8yFU8eSETXU7VSN48HMDmevGoCMiuveQZgkPuRn1nTiRqyv"

echo "2Miners:     $TWO_MINERS_ADDR   https://ae.2miners.com"
echo "Wooly Pooly: $WOOLY_POOLY_ADDR   https://woolypooly.com/en/coin/ae"
echo "-----------------------------------------------------------------"

printf "%-20s %-7s %-53s %-12s %-53s %-12s \n" "Time" "Height" "Keyblock" "Beneficiary" "Miner" "Micro-blocks"
echo -n "----------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------"
for ((HEIGHT = $START_HEIGHT; HEIGHT <= $START_HEIGHT+$OFFSET; HEIGHT++ )); do
    GEN=$(curl -s $API/v3/generations/height/$HEIGHT)
    KB=$(curl -s $API/v3/key-blocks/height/$HEIGHT)
    # echo $GEN | jq -r '.hash'

    read TIME KB_HASH BENEFICIARY_ADDR MINER < <( echo $KB | jq -r '.time,.hash,.beneficiary,.miner' | tr \\n ' ')
    MB_COUNT=$(echo $GEN | jq -r '.micro_blocks | length')

    DTIME=$(date -r $(($TIME/1000)) +'%Y-%m-%dT%H:%M:%S')
    BENEFICIARY=$(echo $BENEFICIARY_ADDR | sed "s/$TWO_MINERS_ADDR/2Miners/" | sed "s/$WOOLY_POOLY_ADDR/Wooly-Pooly/")
    printf "%-20s %-7s %-53s %-12s %-53s %-4s \n" $DTIME $HEIGHT $KB_HASH $BENEFICIARY $MINER $MB_COUNT
done
