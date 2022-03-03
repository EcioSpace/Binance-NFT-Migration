// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// *************** Interfaces ***************** //

interface ECIOERC721 {
    function tokenInfo(uint256 _tokenId)
        external
        view
        returns (string memory, uint256);

    function safeMint(address to, string memory partCode) external;
}

interface BNBERC721 {
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract ECIONFTMigrateBNB is Ownable {
    address public NFTCoreV2;
    address public BNBAddress;
    BNBERC721 BNBECIO;
    ECIOERC721 ECIONFTV2;
    uint256 public totalFee = 0.005 ether;

    // *************** Event ***************** //
    event returnTokenURI(string[] uri);

    // *************** View Function ***************** //

    function setupContract(address bnbAddress, address nftCoreV2)
        public
        onlyOwner
    {
        NFTCoreV2 = nftCoreV2;
        BNBAddress = bnbAddress;
        BNBECIO = BNBERC721(bnbAddress);
        ECIONFTV2 = ECIOERC721(nftCoreV2);
    }
 
    // return tokenURI for backEnd;
    function validateUserToken(address userAddr, uint256 tokenId) public {
        uint256 userToken;
        uint256 userBalance = BNBECIO.balanceOf(userAddr); //number of total token
        string[] memory tokenURI;

        for (uint32 i = 0; i < userBalance; i++) {
            userToken = BNBECIO.tokenOfOwnerByIndex(userAddr, i);
            if (tokenId == userToken) {
                tokenURI[i] = getTokenURI(userToken);
            } else {
                tokenURI[i] = "";
            }
        }

        emit returnTokenURI(tokenURI);
    }

    //check TokenURI for backEnd
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return BNBECIO.tokenURI(tokenId);
    }

    // *************** Action Function ***************** //

    function mirgrate(uint256[] memory tokenId, string[] memory partCode)
        external
        payable
    {
        require(
            tokenId.length == partCode.length,
            "TokenId: Should have the same length"
        );
        // charge more fee
        (bool sent, bytes memory data) = address(this).call{value: totalFee}(
            ""
        );
        require(sent, "Failed to send Ether");

        for (uint32 i = 0; i < tokenId.length; i++) {
            //transfer token from BNBContract to this address.
            BNBECIO.safeTransferFrom(BNBAddress, address(this), tokenId[i]);
            // mint token NFTV2 for user.
            ECIONFTV2.safeMint(msg.sender, partCode[i]);
        }
    }
}
