// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/DreamDex.sol";
import "../src/TestToken.sol";
contract CounterTest is Test {
    DreamDex public dex;
    address public provider = address(1);
    address public provider2 = address(4);
    address public trader = address(1234);
    address public t1 = address(2);
    address public t2 = address(3);
    TestToken token1;
    TestToken token2;
    function setUp() public {
        
 
        token1 = new TestToken(); 
        token2 = new TestToken();
        dex = new DreamDex(address(token1),address(token2));

        token1._mint(provider,1000 ); 
        token2._mint(provider,1000 );

        token1._mint(provider2,10 ); 
        token2._mint(provider2,10 );

        
        token1._mint(trader,50 ); 
        token2._mint(trader,0 );

        vm.prank(provider);
        token1.approve(address(dex),10000 ether);
        vm.prank(provider);
        token2.approve(address(dex),10000 ether);

        vm.prank(provider2);
        token1.approve(address(dex),10000 ether);
        vm.prank(provider2);
        token2.approve(address(dex),10000 ether);

        vm.prank(trader);
        token1.approve(address(dex),10000 ether);
        vm.prank(trader);
        token2.approve(address(dex),10000 ether);
    }

    function testProviderToken() public {
        uint256 provider_amount_t1 = token1.balanceOf(provider);
        uint256 provider_amount_t2 = token2.balanceOf(provider);
        assertEq(provider_amount_t1 , 100);
        assertEq(provider_amount_t2, 100); 
    }

    function testDeposit() public {
        vm.prank(provider);
        uint256 lpT = dex.addLiquidity(20,20,5);
        assertEq(lpT,20);
        console.log(token1.balanceOf(provider));
        console.log(token2.balanceOf(provider));
        console.log(token1.balanceOf(address(dex)));
        console.log(token2.balanceOf(address(dex)));
        console.log("------------------------------");
        vm.prank(provider2);
        lpT = dex.addLiquidity(20,50,8);
        assertEq(lpT,20);
        console.log(token1.balanceOf(provider2));
        console.log(token2.balanceOf(provider2));
        console.log(token1.balanceOf(address(dex)));
        console.log(token2.balanceOf(address(dex)));
        console.log("--------------------------------");


    }


    function testBurn() public {
         vm.prank(provider);
        uint256 lpT = dex.addLiquidity(1000 ,1000 ,0);

        console.log(lpT);
        console.log(token1.balanceOf(provider));
        console.log(token2.balanceOf(provider));
        console.log(token1.balanceOf(address(dex)));
        console.log(token2.balanceOf(address(dex)));
        console.log("------------------------------");
        // vm.prank(provider2);s
        // lpT = dex.addLiquidity(20,50,8);
        // assertEq(lpT,20);
        // console.log(token1.balanceOf(provider2));
        // console.log(token2.balanceOf(provider2));
        // console.log(token1.balanceOf(address(dex)));
        // console.log(token2.balanceOf(address(dex)));
        // console.log("--------------------------------");





        console.log("-------------------------------");
        vm.prank(provider);
        dex.removeLiquidity(80,0,0);
        console.log(token1.balanceOf(provider));
        console.log(token2.balanceOf(provider));
        console.log(token1.balanceOf(address(dex)));
        console.log(token2.balanceOf(address(dex)));
        
    }

    function testSwap() public {
        vm.prank(provider);
        uint256 lpT = dex.addLiquidity(10 ether ,10 ether,0);
        assertEq(lpT,10 ether );
        console.log(token1.balanceOf(provider));
        console.log(token2.balanceOf(provider));
        console.log(token1.balanceOf(address(dex)));
        console.log(token2.balanceOf(address(dex)));
        console.log("------------------------------");

        vm.prank(trader);        
        dex.swap(0 ether,11 ether,0);
        console.log(token1.balanceOf(trader));
        console.log(token2.balanceOf(trader));
    }


    function testSwapBurn() public {
        vm.prank(provider);
        uint256 lpT = dex.addLiquidity(1000 ,1000 ,0);

        console.log(lpT);
        console.log(token1.balanceOf(provider));
        console.log(token2.balanceOf(provider));
        console.log(token1.balanceOf(address(dex)));
        console.log(token2.balanceOf(address(dex)));
        console.log("------------------------------");

        vm.prank(trader);        
        dex.swap(50 ,0 ,0);
        console.log(token1.balanceOf(trader));
        console.log(token2.balanceOf(trader));   
        console.log(token1.balanceOf(address(dex)));
        console.log(token2.balanceOf(address(dex)));

        console.log("-------------------------------");
        vm.prank(provider);
        dex.removeLiquidity(lpT,0,0);
        console.log(token1.balanceOf(provider));
        console.log(token2.balanceOf(provider));
        console.log(token1.balanceOf(address(dex)));
        console.log(token2.balanceOf(address(dex)));
    }

}


