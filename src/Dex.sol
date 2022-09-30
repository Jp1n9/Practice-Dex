// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/Test.sol";
contract Dex is ERC20 {
    using SafeERC20 for IERC20;

    IERC20 _tokenX;
    IERC20 _tokenY;
    uint256 private _reserveX;
    uint256 private _reserveY;
    uint256 private _k;

    constructor(address tokenX, address tokenY) ERC20("DreamAcademy DEX LP token", "DA-DEX-LP") {
        require(tokenX != tokenY, "DA-DEX: Tokens should be different");

        _tokenX = IERC20(tokenX);
        _tokenY = IERC20(tokenY);
    }


    function swap(uint256 tokenXAmount, uint256 tokenYAmount, uint256 tokenMinimumOutputAmount)
        external
        returns (uint256 outputAmount)
    {
        require(tokenXAmount ==  0 || tokenYAmount == 0);

        uint256 amount;
        uint256 inputReserve;
        uint256 outputReserve;
        address inputTokenAddress;
        address outputTokenAddress;

        if(tokenXAmount > 0 ) {
            amount = tokenXAmount;
            outputReserve = _reserveY;
            inputTokenAddress = address(_tokenX);
            outputTokenAddress = address(_tokenY);
        }
        if(tokenYAmount > 0 ) {
            amount = tokenYAmount;
            outputReserve = _reserveX;
            inputTokenAddress = address(_tokenY);
            outputTokenAddress =address(_tokenX);

        }
            
        IERC20(inputTokenAddress).safeTransferFrom(msg.sender,address(this),amount);
        inputReserve = IERC20(inputTokenAddress).balanceOf(address(this));

        uint256 denominator = _k % inputReserve == 0? _k / inputReserve : _k / inputReserve + 1;
        outputAmount = outputReserve - denominator ;
        outputAmount = calculateFee(outputAmount);
        require(outputAmount >= tokenMinimumOutputAmount," outputAmount is less than MinimumOutputAmount" );
        IERC20(outputTokenAddress).safeTransfer(msg.sender,outputAmount);

        update(_tokenX.balanceOf(address(this)),_tokenY.balanceOf(address(this)));
    }

    function addLiquidity(uint256 tokenXAmount, uint256 tokenYAmount, uint256 minimumLPTokenAmount)
        external
        returns (uint256 LPTokenAmount)
    {
        IERC20 tokenX =_tokenX;
       IERC20 tokenY = _tokenY;

       uint256 reserveX = _tokenX.balanceOf(address(this));
       uint256 reserveY = _tokenY.balanceOf(address(this));


        uint256 totalToken = totalSupply();
       if(totalToken == 0) {
        LPTokenAmount= sqrt(tokenXAmount * tokenYAmount);

       }
       else {
        if(tokenXAmount <= tokenYAmount) {
            LPTokenAmount = tokenXAmount * totalToken / reserveX;
        } else {

            LPTokenAmount = tokenYAmount* totalToken / reserveY ; 
        }
       }
       tokenX.safeTransferFrom(msg.sender,address(this),tokenXAmount);
       tokenY.safeTransferFrom(msg.sender,address(this),tokenYAmount);

       reserveX += tokenXAmount;
       reserveY += tokenYAmount;

       require(LPTokenAmount > 0 , "LP token <= 0");
       require( LPTokenAmount >= minimumLPTokenAmount,"LP token < minimumLPToken");
        _mint(msg.sender,LPTokenAmount);
        update(reserveX, reserveY);

    }

    function removeLiquidity(uint256 LPTokenAmount, uint256 minimumTokenXAmount, uint256 minimumTokenYAmount)
        external returns (uint256 transferX, uint256 transferY)
    {
        require(LPTokenAmount > 0 );

        IERC20 tokenX = _tokenX;
        IERC20 tokenY = _tokenY;

        uint256 reserveX= _reserveX;
        uint256 reserveY= _reserveY;
        transferX = LPTokenAmount * reserveX / totalSupply();
        transferY = LPTokenAmount * reserveY / totalSupply();

        
        require(transferX >= minimumTokenXAmount && transferY >= minimumTokenYAmount);

        _burn(msg.sender,LPTokenAmount);

        tokenX.safeTransfer(msg.sender,transferX);
        tokenY.safeTransfer(msg.sender,transferY);

        reserveX -= transferX;
        reserveY -= transferY;
        update(reserveX,reserveY);

    }

    function calculateFee(uint256 amount) private returns(uint256 fee) {
        fee = amount * 999 / 1000;
     
    }

    function update(uint256 curReserveX, uint256 curReserveY) private{
        _reserveX = curReserveX;
        _reserveY = curReserveY;
        _k = curReserveX * curReserveY;

    }
    // From UniSwap core
    function sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }


}
