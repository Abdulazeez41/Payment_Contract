const EasySwap = artifacts.require("EasySwap");

const Web3 = require("web3");
const web3 = new Web3('https://ropsten.infura.io/v3/ef3743737ce5471d8f7130dd09faa7a3');

const DAI = new web3.eth.Contract(ERC20ABI, "0xc2118d4d90b274016cB7a54c03EF52E6c537D957");
const WETH = new web3.eth.Contract(ERC20ABI, "0xc778417E063141139Fce010982780140Aa0cD5Ab");

const ERC20ABI = [{
        "constant": true,
        "inputs": [
            {
                "name": "_owner",
                "type": "address"
            }
        ],
        "name": "balanceOf",
        "outputs": [
            {
                "name": "balance",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    }];

	
contract("EasySwap", async accounts => {
  it("Should wrap 0.25 ether to WETH", async () => {
    const es = await EasySwap.deployed();
	
	await WETH.methods.deposit(2500000000000000000).send();
	
    const WETHBalance = await WETH.methods.balanceOf(accounts[0]).call();
    assert.equal(WETHBalance, 2500000000000000000);
  });

  it("should swap 0.2 WETH to DAI", async () => {
    const es = await EasySwap.deployed();
	
    const initialWETHBalance = await WETH.methods.balanceOf(accounts[0]).call();
	
	await es.swapWETHToDAI(200000000000000000);
	
    const finalWETHBalance = await WETH.methods.balanceOf(accounts[0]).call();
	
    assert.equal(finalWETHBalance, initialWETHBalance - 0.2);
  });

  it("should swap 200 DAI to WETH", async () => {
    const es = await EasySwap.deployed();
	
    const initialDAIBalance = await DAI.methods.balanceOf(accounts[0]).call();
	
	await es.swapDAIToWETH(200000000000000000000);
	
    const finalDAIBalance = await DAI.methods.balanceOf(accounts[0]).call();
	
    assert.equal(finalDAIBalance, initialDAIBalance - 200);
  });
});