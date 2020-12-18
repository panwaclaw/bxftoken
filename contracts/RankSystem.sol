// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;
pragma abicoder v2;


contract RankSystem {

    struct Rank {
        string name;
        uint256 selfBuy;
        uint256 turnover;
        uint256 percent;
        uint256 splitRulePercent;
    }

    Rank[] private AFFILIATE_RANKS;

    constructor() {
        AFFILIATE_RANKS.push(Rank("User",         0 ether,   0 ether,    0,  100));
        AFFILIATE_RANKS.push(Rank("Member",       0.2 ether, 2 ether,    2,  100));
        AFFILIATE_RANKS.push(Rank("Affiliate",    0.5 ether, 5 ether,    3,  100));
        AFFILIATE_RANKS.push(Rank("Pro",          1 ether,   10 ether,   4,  100));
        AFFILIATE_RANKS.push(Rank("Shepherd",     2 ether,   20 ether,   5,  100));
        AFFILIATE_RANKS.push(Rank("VIP",          4 ether,   40 ether,   6,  100));
        AFFILIATE_RANKS.push(Rank("Gold VIP",     8 ether,   100 ether,  7,  100));
        AFFILIATE_RANKS.push(Rank("Platinum VIP", 16 ether,  400 ether,  8,   60));
        AFFILIATE_RANKS.push(Rank("Red Diamond",  32 ether,  1000 ether, 9,   60));
        AFFILIATE_RANKS.push(Rank("Blue Diamond", 50 ether,  3000 ether, 10,  60));
    }


    function getRanksCount() public view returns(uint) {
        return AFFILIATE_RANKS.length;
    }


    function getRankDetails(uint rank) public view returns(Rank memory) {
        return AFFILIATE_RANKS[rank];
    }
}
