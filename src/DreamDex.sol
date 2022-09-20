pragma solidity ^0.8.0;

import "./DreamERC20.sol";
import "./TestToken.sol"; //Test Token token1, token2
contract DreamDex is DreamERC20{

    //LP Token    
    DreamERC20 private LPtoken;

    //Swap Token 
    address private _tokenX;
    address private _tokenY;

    // the number of token
    uint256 private _tX_reserve; 
    uint256 private _tY_reserve;

    // t0_reserver * t1_reserver = k;
    uint256 private _k; 

    // 0.1%
    uint256 _fee = 100; 
    uint256 private constant BASIS_POINT = 1000;
    uint256 private constant MINIMUM_AMOUNT = 1 gwei;


    event LogAddress(address addr);
    event LogAmount(uint256 num);


    
    constructor(address tokenX_ , address tokenY_)  {
        LPtoken = new DreamERC20();
        _tokenX = tokenX_;
        _tokenY = tokenY_;      
    }

    function addLiquidity(uint256 tokenXAmount, uint256 tokenYAmount, uint256 minimumLPTokenAmount) external returns (uint256 LPTokenAmount) {
        require(tokenXAmount != 0 && tokenYAmount !=0);
        // require(tokenXAmount >= MINIMUM_AMOUNT && tokenYAmount >= MINIMUM_AMOUNT, "Minimum amount is 1 gwei");

        address tokenX = _tokenX;
        address tokenY = _tokenY;

        // 현재 가지고 있는 양
        uint256 reserveX = _tX_reserve;
        uint256 reserveY = _tY_reserve;

        // 실제 deposit되는 양
        uint256 amountX;
        uint256 amountY;

        // reserve가 비어있을 때 , Liquidity가 새로생성될 때 그대로 예치
        if(reserveX == 0 && reserveY == 0) {
            // 풀을 생성하고 처음 예치할 떄 1대1 비율로 넣어야 Trade가 생길 떄 손해를 안봄 
            require(tokenXAmount == tokenYAmount);
            amountX = tokenXAmount;
            amountY = tokenYAmount;

        }
        else {
            // X토큰을 기준으로 y를 넣어야할 개수
            uint256 yOpAmount = qoute(tokenXAmount,reserveX,reserveY);

            // provider가 y토큰을 더많이 주면 x에 대한 비율에 맞쳐 y를 예치 , 많이 넣은게 잘못 
            if(yOpAmount <= tokenYAmount) {
                (amountX, amountY) = (tokenXAmount, yOpAmount);
            }
            else {
                // Y토큰을 기준으로 x를 넣어야할 개수
                uint256 xOpAmount = qoute(tokenYAmount,reserveY,reserveX);

                // Y도 안맞고 X도 공급자가 주어진 양에 맞지 않을 때 revert
                assert( xOpAmount <= tokenXAmount);
                (amountX, amountY) = (xOpAmount,tokenYAmount);
                uint256 _totalSupply = LPtoken.totalSupply();
                LPTokenAmount = min((amountX * _totalSupply)/reserveX , (amountY * _totalSupply) / reserveY ); 
            }
        }

     



        // liquidity pool에 token 지불
        TestToken(tokenX).transferFrom(msg.sender, address(this),amountX);
        TestToken(tokenY).transferFrom(msg.sender, address(this),amountY);

        uint256 curReserveX = TestToken(tokenX).balanceOf(address(this));
        uint256 curReserveY = TestToken(tokenY).balanceOf(address(this));

        // pool이 생성되고 처음 예치 할 때
        if(amountX == amountY) {
            LPTokenAmount= sqrt(amountX * amountY); // 처음 LP토큰의 기준이 되는 양
        }
        // Pool에 X, Y가 존재 할 때
        // LP Token Mint해야 될 값 : deposit 한 값 * LPtoken 총 수량 / deposit하기 전의 reserve값
        if(LPTokenAmount== 0){

            uint256 _totalSupply = LPtoken.totalSupply();
            LPTokenAmount = min((amountX * _totalSupply)/reserveX , (amountY * _totalSupply) / reserveY ); 
        }


        require(LPTokenAmount > 0);
        require(minimumLPTokenAmount < LPTokenAmount);
        
        LPtoken._mint(msg.sender,LPTokenAmount);
        // 개수 업데이트
        update(curReserveX,curReserveY);    

    }





    // root
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }


    function removeLiquidity(uint256 LPTokenAmount, uint256 minimumTokenXAmount, uint256 minimumTokenYAmount) external {
        require(LPTokenAmount > 0 );
        uint256 curLPTAmount = LPtoken.balanceOf(msg.sender);
        if(LPTokenAmount > curLPTAmount) {
            LPTokenAmount = curLPTAmount; 
        }
        address tokenX = _tokenX;
        address tokenY = _tokenY;

        uint256 curReserveX = TestToken(tokenX).balanceOf(address(this));
        uint256 curReserveY = TestToken(tokenY).balanceOf(address(this)); 
        uint256 _totalSupply = LPtoken.totalSupply();

        require(_totalSupply > 0);
        //  provider LPT * X_reserve / LPT totalSupply 식으로 반환되는 X,Y 토큰의 수
        uint256 amountX = LPTokenAmount * curReserveX / _totalSupply;
        uint256 amountY = LPTokenAmount * curReserveY / _totalSupply;



        
        require(amountX > 0 && amountY > 0);
        require(amountX >= minimumTokenXAmount && amountY >= minimumTokenYAmount);

        LPtoken._burn(msg.sender,LPTokenAmount);
        TestToken(tokenX).approve(msg.sender,amountX);
        TestToken(tokenY).approve(msg.sender,amountY);

        TestToken(tokenX).transfer(msg.sender,amountX);
        TestToken(tokenY).transfer(msg.sender,amountY);

        update(curReserveX-amountX , curReserveY - amountY);
        emit LogAmount(_tX_reserve);  
        emit LogAmount(_tY_reserve);  
        emit LogAmount(_k);  

    }

    function swap(uint256 tokenXAmount, uint256 tokenYAmount, uint256 tokenMinimumOutputAmount) external returns (uint256 outputAmount){
        require(tokenXAmount ==  0 || tokenYAmount == 0);
        // require(tokenXAmount >= MINIMUM_AMOUNT || tokenYAmount >= MINIMUM_AMOUNT,  "Minimum amount is 1 gwei");
        uint256 reserveX = _tX_reserve;
        uint256 reserveY = _tY_reserve;
        
        require(reserveX !=  0 && reserveY != 0);
        
        address tokenX = _tokenX;
        address tokenY = _tokenY;

        // stak too deep
        //address token = tokenXAmount > tokenYAmount ? tokenY : tokenX;    

        uint256 curReserveX = TestToken(tokenX).balanceOf(address(this));
        uint256 curReserveY = TestToken(tokenY).balanceOf(address(this)); 
        uint256 price;
        uint256 afterAmount;
        // send to pool
        if(tokenXAmount > 0 ) {
            
            TestToken(tokenX).transferFrom(msg.sender,address(this),tokenXAmount);
            curReserveX = TestToken(tokenX).balanceOf(address(this));
            afterAmount = _k /  curReserveX;
            price = getPrice(curReserveY,afterAmount);
            uint256 price_fee = price - ((price * _fee)/BASIS_POINT);
            require(price_fee <= reserveY && price >= tokenMinimumOutputAmount);
            TestToken(tokenY).transfer(msg.sender,price_fee);
        }
        if(tokenYAmount > 0 ) {

            TestToken(tokenY).transferFrom(msg.sender,address(this),tokenYAmount);
            curReserveY = TestToken(tokenY).balanceOf(address(this)); 
            afterAmount = _k /  curReserveY;
            price = getPrice(curReserveX,afterAmount );
            uint256 price_fee = price - ((price * _fee)/BASIS_POINT);
            require(price_fee <= reserveX && price >= tokenMinimumOutputAmount);
            TestToken(tokenX).transfer(msg.sender,price_fee);
    
        }
 

        emit LogAmount(price);

        // TestToken(token).transfer(msg.sender,price);


    }

    // 수수료 없을 때
    // X의 가격 : Y_prev_reserve - ( k / (X_prev_reserve + X_amount) )
    // Y의 가격 :  X_prev_reserve - ( k / (Y_prev_reserve + Y_amount) )
    function getPrice(uint256 prevReserve,uint256 afterReserve )public returns(uint256 amount){
        amount = prevReserve - afterReserve;
    }
    // X의 값을 기준으로 예치하는 기준에 따라  비율에 맞는 Y의 값을 구하는 함수
    function qoute(uint256 amountX,uint256 reserveX, uint256 reserveY) internal pure returns(uint256 amountY) {
        require(amountX > 0);
        require(reserveX > 0 && reserveY >0);
        amountY = amountX * reserveY / reserveX;
    }

    function update(uint256 curReserveX, uint256 curReserveY) public {
        _tX_reserve = curReserveX;
        _tY_reserve = curReserveY;
        _k = curReserveX * curReserveY;
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    function transfer(address to, uint256 lpAmount) public returns (bool) {
        LPtoken._mint(to,lpAmount );
        return true;
    }    



}