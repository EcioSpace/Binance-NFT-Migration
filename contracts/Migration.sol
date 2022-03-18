// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// *************** Interfaces ***************** //

interface ECIOERC721 {
    function tokenInfo(uint256 _tokenId)
        external
        view
        returns (string memory, uint256);

    function safeMint(address to, string memory partCode) external;
}

contract ECIONFTMigrateBNB is Ownable, ERC721Holder, ReentrancyGuard {
    address public NFTCoreV2;
    address public BNBAddress;
    address private _minter;

    uint256 public totalFee = 0.005 ether;

    // *************** Event ***************** //
    event returnTokenURI(address user, uint256[], string[]);

    // *************** Setup Function ***************** //
    function setupContract(address bnbAddress, address nftCoreV2)
        public
        onlyOwner
    {
        NFTCoreV2 = nftCoreV2;
        BNBAddress = bnbAddress;
    }

    function setupMinter(address minter) public onlyOwner {
        _minter = minter;
    }

    // *************** View Function ***************** //

    function getUserTokenId(address user, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        uint256 userTokenId = IERC721Enumerable(BNBAddress).tokenOfOwnerByIndex(
            user,
            tokenId
        );
        return userTokenId;
    }

    function checkUserBalance(address user) public view returns (uint256) {
        uint256 userBalance = IERC721(BNBAddress).balanceOf(user); //number of total token
        return userBalance;
    }

    // check TokenURI for backEnd
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return IERC721Metadata(BNBAddress).tokenURI(tokenId);
    }

    // *************** Action Function ***************** //

    // return tokenURI for backEnd;
    function claimAll() external payable nonReentrant {
        uint256 userBalance = checkUserBalance(msg.sender); //number of total token
        uint256[] memory tokenId = new uint256[](userBalance);
        string[] memory tokenURI = new string[](userBalance);

        require(userBalance > 0, "Token: you do not have tokens");
        // Charges fee for mintin'
        require(msg.value >= totalFee, "Fee: you have not enough Ether");

        for (uint32 i = 0; i < userBalance; i++) {
            // string tokenURIcur =
            // sned tokenURI to backEnd
            tokenId[i] = getUserTokenId(msg.sender, i); // works if no transfer
            tokenURI[i] = getTokenURI(tokenId[i]); // // works if no transfer
        }

        for (uint32 i = 0; i < tokenId.length; i++) {
            //transfer token from Owner to this address.
            IERC721(BNBAddress).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId[i]
            );
        }

        // send fee to minter
        (bool sent, ) = _minter.call{value: 0.004 ether}("");
        require(sent, "Failed to send Ether");

        // return (userBalance, tokenId, tokenURI);
        emit returnTokenURI(msg.sender, tokenId, tokenURI);
    }

    // mint token NFTV2 for user.
    function mirgrate(address user, string[] memory partCode)
        external
        onlyOwner
        nonReentrant
    {
        for (uint32 i = 0; i < partCode.length; i++) {
            ECIOERC721(NFTCoreV2).safeMint(user, partCode[i]);
        }
    }

    //
    function sendEth(address payable _to, uint _amount) external onlyOwner {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
}
