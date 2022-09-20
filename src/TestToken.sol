pragma solidity ^0.8.0;




// DreamDex Token
contract TestToken {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    string public constant _name = "DreamAcadmey";
    string public constant _symbol = "DREAM";
    uint256 public constant _decimals = 18;
    uint256 public _totalSupply;
    address private _owner;

    mapping(address => uint) public balance;
    mapping(address => mapping(address => uint)) public allowances;

    modifier OnlyOnwer {
        require(msg.sender == _owner,"You are not owner");
        _;
    }
    constructor() {
        _owner = msg.sender;
    }

    function name() external pure returns (string memory) {
        return _name;
    }
    function symbol() external pure returns (string memory){
        return _symbol;
    }
    function decimals() external pure returns (uint) {
        return _decimals;
    }
    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address owner_) external view returns (uint) {
        return balance[owner_];
    }
    function allowance(address owner_, address spender_) external view returns (uint) {
        return allowances[owner_][spender_];
    }


    function _mint(address to_, uint256 amount_) public OnlyOnwer{

        _totalSupply += amount_;
        balance[to_] += amount_;
        
        emit Transfer(address(0), to_ , amount_);
    }


    function _burn(address from_ , uint256 amount_) public OnlyOnwer{
        balance[from_] -= amount_;
        _totalSupply -= amount_;
    }

    // Approve

    function approve(address to_, uint256 amount_) external returns(bool) {
        _approve(msg.sender, to_,amount_);
        return true;
    }
    function _approve(address owner_ , address spender_ , uint256 amount_) public{
        allowances[owner_][spender_] = amount_;
        emit Approval(owner_,spender_,amount_);
    }


    // Transfer

    function transfer(address to_,uint256 amount_) external returns(bool) {
        _transfer(msg.sender,to_,amount_);
        return true;
    }

    function transferFrom(address from_, address to_, uint256 amount_) external returns(bool) {
        assert(to_ != address(0));
        assert(from_ != address(0));
        require(allowances[from_][msg.sender] > 0,"Error TransferFrom");

        allowances[from_][msg.sender] -= amount_;
        _transfer(from_,to_,amount_);

        return true;

    }
    function _transfer(address from_, address to_,uint256 amount_) public {
        balance[from_] -= amount_;
        balance[to_] += amount_;
        emit Transfer(from_,to_,amount_); 
    }

}