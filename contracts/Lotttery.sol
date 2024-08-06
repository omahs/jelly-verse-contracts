// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {Ownable} from "./utils/Ownable.sol";
import {IChest} from "./interfaces/IChest.sol";
import {IDragonBall} from "./interfaces/IDragonBall.sol";
import {IERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";
import {IERC721} from "./vendor/openzeppelin/v4.9.0/token/ERC721/IERC721.sol";

/**
 * @title Lottery contract
 * @notice Contract for distrubtiong chests
 */

contract Lottery is Ownable {

    uint96 public numberOfChests;
    uint96 public numberOfDragonChests;
    uint96 public numberOfGoldenChests;
    uint96 public numberOfSilverChests;
    uint96 public numberOfBronzeChests;

    address public dragonBallContract;//immutable?
    address public immutable chestContract;
    address public immutable jellyToken;


    uint256 public constant DRAGON_AMOUNT=  1_000_000;
    uint256 public constant GOLDEN_AMOUNT = 500_000;
    uint256 public constant SILVER_AMOUNT = 100_000;    
    uint256 public constant BRONZE_AMOUNT = 50_000;

    uint64 private constant DECIMALS = 1e18;


    event ChestAwarded(uint96 chestId);
    event ChestsAdded(uint96 numberOfDragonChests, uint96 numberOfGoldenChests, uint96 numberOfSilverChests, uint96 numberOfBronzeChests);
    event DragonChestAwarded();
    event GoldenChestAwarded();
    event SilverChestAwarded();
    event BronzeChestAwarded();

    error Lottery__LenMissmatch();
    error Lottery__NotOwner();
    error Lottery__WrongIDs();

    constructor(
        address _owner,
        address _pendingOwner,
        address _dragonBallContract,
        address _chestContract,
        address _jellyToken
    ) Ownable(_owner, _pendingOwner) {
        dragonBallContract = _dragonBallContract;
        chestContract = _chestContract;
        jellyToken = _jellyToken;
    }

    /**
     * @notice Burn balls to get chest
     *
     * @param _ids - ids of chest the user wants to burn
     *
     * No return value
     */
    function burnBalls(uint256[] memory _ids) public {
        if (_ids.length != 7) revert Lottery__LenMissmatch();
        bool joker=false;

        for (uint256 i = 0; i < _ids.length; i++) {
            if(IERC721(dragonBallContract).ownerOf(_ids[i]) != msg.sender) revert Lottery__NotOwner();

          if (IDragonBall(dragonBallContract).getBallNumber(_ids[i]) != i + 1) {
            if(!joker && IDragonBall(dragonBallContract).getBallNumber(_ids[i]) == 0){
                joker=true;
             
            } else {
                revert Lottery__WrongIDs();
                }
        }
        }

        for (uint256 i = 0; i < _ids.length; i++) {
            IDragonBall(dragonBallContract).burn(_ids[i]);
        }

        _awardChest();

        
    }

    /**
     * @notice add chests to the lottery
     *
     * @param _numberOfDragonChests - number of dragon chests to add
     * @param _numberOfGoldenChests - number of golden chests to add
     * @param _numberOfSilverChests - number of silver chests to add
     * @param _numberOfBronzeChests - number of bronze chests to add
     *
     * No return only owner can call
     */
    function addChests(uint96 _numberOfDragonChests,uint96 _numberOfGoldenChests, uint96 _numberOfSilverChests, uint96 _numberOfBronzeChests) public onlyOwner {
        numberOfDragonChests += _numberOfDragonChests;
        numberOfGoldenChests += _numberOfGoldenChests;
        numberOfSilverChests += _numberOfSilverChests;
        numberOfBronzeChests += _numberOfBronzeChests;
        numberOfChests += _numberOfDragonChests + _numberOfGoldenChests + _numberOfSilverChests + _numberOfBronzeChests;

        emit ChestsAdded(_numberOfDragonChests, _numberOfGoldenChests, _numberOfSilverChests, _numberOfBronzeChests);
    }

    function _getRadomNumber() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % numberOfChests;
    }

    function _awardChest() internal {
        uint256 randomNumber = _getRadomNumber();
        if (randomNumber < numberOfDragonChests) {
            _awardDragonChest();
            numberOfDragonChests--;
        } else if (randomNumber < numberOfDragonChests + numberOfGoldenChests) {
            _awardGoldenChest();
            numberOfGoldenChests--;
        } else if (randomNumber < numberOfDragonChests + numberOfGoldenChests + numberOfSilverChests) {
            _awardSilverChest();
            numberOfSilverChests--;
        } else {
            _awardBronzeChest();
            numberOfBronzeChests--;
        } 
        numberOfChests--;
    }

    

    function _awardDragonChest() internal {
        IERC20(jellyToken).approve(chestContract, DRAGON_AMOUNT * DECIMALS + IChest(chestContract).fee());
        IChest(chestContract).stake(DRAGON_AMOUNT * DECIMALS, msg.sender, 0);

        emit DragonChestAwarded();
    }

    function _awardGoldenChest() internal {
        IERC20(jellyToken).approve(chestContract, GOLDEN_AMOUNT * DECIMALS + IChest(chestContract).fee());
        IChest(chestContract).stake(GOLDEN_AMOUNT * DECIMALS, msg.sender, 0);

        emit GoldenChestAwarded();
    }

    function _awardSilverChest() internal {
        IERC20(jellyToken).approve(chestContract, SILVER_AMOUNT * DECIMALS + IChest(chestContract).fee());
        IChest(chestContract).stake(SILVER_AMOUNT * DECIMALS, msg.sender, 0);

        emit SilverChestAwarded();
    }

    function _awardBronzeChest() internal {
        IERC20(jellyToken).approve(chestContract, BRONZE_AMOUNT * DECIMALS + IChest(chestContract).fee());
        IChest(chestContract).stake(BRONZE_AMOUNT * DECIMALS, msg.sender, 0);

        emit BronzeChestAwarded();
    }
}