// SPDX-License-Identifier: MIT;
pragma solidity =0.6.12;

import "https://github.com/sushiswap/sushiswap/blob/canary/contracts/uniswapv2/libraries/UniswapV2Library.sol";
import "https://github.com/sushiswap/sushiswap/blob/canary/contracts/uniswapv2/libraries/TransferHelper.sol";
import "https://github.com/sushiswap/sushiswap/blob/canary/contracts/uniswapv2/interfaces/IERC20.sol";
import "https://github.com/sushiswap/sushiswap/blob/canary/contracts/uniswapv2/interfaces/IWETH.sol";
import "https://github.com/sushiswap/sushiswap/blob/canary/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";

contract PaymentContract {
	
    address public owner;
    address public swapRouter;
    address public WBNB;
    address public stableCoin;
    uint public slippage;

    // Defining the vendors array
    struct vendor {
        address vendorAddress;
        uint vendorBalance;
    }

    vendor[] public vendors;

    // Keeps track of vendors
    mapping(address=>bool) public isVendor;

    modifier onlyVendors() {
        require(isVendor[msg.sender] == true);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Events
    event paymentSuccessful(uint _transactionId, uint _amountInUSD, uint _vendorId);
    event newVendorRegistered(uint _vendorId, address _address);


    constructor(address _swapRouter, address _WBNB, address _stableCoin, uint _slippage) public {
    swapRouter = _swapRouter;
    WBNB = _WBNB;
    stableCoin = _stableCoin;
    slippage = _slippage;
    owner = msg.sender;
    }

    function setRouter(address _swapRouter, address _WBNB) public onlyOwner{
    swapRouter = _swapRouter;
    WBNB = _WBNB;
    }

    function setStableCoin(address _stableCoin) public onlyOwner{
    stableCoin = _stableCoin;
    }

    function setSlippage(uint _slippage) public onlyOwner{
    slippage = _slippage;
    }


    function registerAsAVendor() public returns(uint){
        uint _Id = vendors.length - 1;
        vendor memory newVendor;
        newVendor.vendorAddress = msg.sender;
        newVendor.vendorBalance = 0;
        
        vendors.push(newVendor);
        emit newVendorRegistered(_Id, msg.sender);
        isVendor[msg.sender] = true;
        return _Id;
    }


	// Allows a buyer to make payment 
	function makePayment(uint _vendorId, uint _transactionId, address _token, uint _amountInUSD) public {
        require(_vendorId < vendors.length, "vendor does not exist!");

        // Always take WBNB path to get a better rate 
        address[] memory _path;
        if (_token == WBNB) {
             _path = new address[](2);
            _path[0] = _token;
            _path[1] = stableCoin;
        } else{
            _path = new address[](3);
            _path[0] = _token;
            _path[1] = WBNB;
            _path[2] = stableCoin;
        }


        // msg.sender must approve this contract to spend their tokens

        
        if (_token != stableCoin) {
            // Get the amount of token to swap
            uint _tokenAmount = _requiredTokenAmount(_amountInUSD, _path);
        
            // Takes the tokens from buyer account
            TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _tokenAmount);
        
        
            // Swap to stableCoin
		    _swap(_tokenAmount, _amountInUSD, _path);
        }
        
        else {
            TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _amountInUSD);
        }
        // Updates vendor's balance
        vendors[_vendorId].vendorBalance = _amountInUSD;

        // emit payment recieve event
        emit paymentSuccessful(_transactionId, _amountInUSD, _vendorId);
	}


    // Internal funtions

    function _requiredTokenAmount(uint _amountInUSD, address[] memory _path) public view returns(uint256) {
        uint256[] memory _tokenAmount = IUniswapV2Router02(swapRouter).getAmountsIn(_amountInUSD, _path);
        return _tokenAmount[0];
    }

    // Swap from tokens to a stablecoin
	function _swap(uint256 _tokenAmount, uint256 _amountInUSD, address[] memory _path) internal {
        
        // Approve the router to swap token.
        TransferHelper.safeApprove(_path[0], swapRouter, _tokenAmount);

        IUniswapV2Router02(swapRouter).swapTokensForExactTokens(
            _amountInUSD,
            _tokenAmount + (slippage / 100) * _tokenAmount,
            _path,
            address(this),
            block.timestamp
        );
    }
}
