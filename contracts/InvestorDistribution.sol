// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {Ownable} from "./utils/Ownable.sol";

contract InvestorDistribution is Ownable {
    struct Investor {
        address beneficiary;
        uint96 amount;
    }

    uint256 constant NUMBER_OF_INVESTORS = 90;
    uint256 constant JELLY_AMOUNT = 122_211_142;
    uint32 constant FREEZING_PERIOD = 18 * 30 days;
    uint32 constant VESTING_DURATION = 6 * 30 days;
    uint8 constant NERF_PARAMETER = 10; // no nerf

    IJellyToken public immutable i_jellyToken;

    uint256 index;
    Investor[NUMBER_OF_INVESTORS] internal investors;
    IChest public i_chest;

    error InvestorDistribution__InvalidBatchLength();
    error InvestorDistribution__DistributionIndexOutOfBounds();
    error InvestorDistribution__ZeroAddress();
    error InvestorDistribution__ChestAlreadySet();
    

    constructor(address jellyToken, address owner, address pendingOwner) Ownable(owner, pendingOwner) {
        i_jellyToken = IJellyToken(jellyToken);
        _initialize();
    }

    function distribute(uint256 batchLength) external onlyOwner {
        if (batchLength == 0) {
            revert InvestorDistribution__InvalidBatchLength();
        }

        uint256 endIndex = index + batchLength;
        if (endIndex > NUMBER_OF_INVESTORS) {
            revert InvestorDistribution__DistributionIndexOutOfBounds();
        }
        
        for (uint256 i = index; i < endIndex; i++) {
            i_chest.stakeSpecial(
                investors[i].amount, investors[i].beneficiary, FREEZING_PERIOD, VESTING_DURATION, NERF_PARAMETER
            );
        }

        index = endIndex;
    }

    function setChest(address chest) external onlyOwner {
        if (chest == address(0)) {
            revert InvestorDistribution__ZeroAddress();
        }
        if (address(i_chest) != address(0)) {
            revert InvestorDistribution__ChestAlreadySet();
        }
        i_chest = IChest(chest);
        // Approve the total amount once for the all investors
        uint256 totalFees = NUMBER_OF_INVESTORS * i_chest.fee();
        i_jellyToken.approve(address(i_chest), JELLY_AMOUNT + totalFees);
    }

    function _initialize() private {
        investors[0] = Investor({beneficiary: 0x11aFD7d87a91652603d20369d93bDf8c37396641, amount: 2_000_000});
        investors[1] = Investor({beneficiary: 0x57bDD74926d44a362f925ba83c3E7310B8855c2B, amount: 2_000_000});
        investors[2] = Investor({beneficiary: 0x2A52286C4C48f1923953103fbffD5f5cb6a6B067, amount: 2_000_000});
        investors[3] = Investor({beneficiary: 0x29427AAe1DF925B2D139B46ebF4ECF453275d492, amount: 2_000_000});
        investors[4] = Investor({beneficiary: 0x4aCB6135A877Ca7714E320e60283CB633afd8E60, amount: 2_000_000});
        investors[5] = Investor({beneficiary: 0xb7ee3144832Bd9A8312E9BFc2B351c00b984e03E, amount: 2_000_000});
        investors[6] = Investor({beneficiary: 0x96E8FEe0b9dFc0BBf9BFf0b1682A0c5299f6FFeF, amount: 2_000_000});
        investors[7] = Investor({beneficiary: 0xA72b13c0431E49676cEC8E76cafC2d94649DBd5E, amount: 2_000_000});
        investors[8] = Investor({beneficiary: 0x92E14B96DD25024c57F6641500D39e9D10321Fc1, amount: 2_000_000});
        investors[9] = Investor({beneficiary: 0x2A65Ae60A014126B3089B5802835601080Fcf8A4, amount: 2_000_000});
        investors[10] = Investor({beneficiary: 0x3A054785B75Eb7A9fDc0430A789208869c94718f, amount: 2_000_000});
        investors[11] = Investor({beneficiary: 0xAd73c78a336d21afa98F6fB5AC05998d176361b3, amount: 2_000_000});
        investors[12] = Investor({beneficiary: 0xE8E0E9d8E1d621861A7F2E725694fC39bd0d2Eb4, amount: 2_000_000});
        investors[13] = Investor({beneficiary: 0x3E88F94bb5C83cAA2C1c6d7bcCD27DEfc9E01738, amount: 2_000_000});
        investors[14] = Investor({beneficiary: 0xF22Aed5c92eA9fD443fCeDA610b22bA4F1640862, amount: 2_000_000});
        investors[15] = Investor({beneficiary: 0x100F0e43324981b34D2e0e560d2cecEe992e9876, amount: 2_000_000});
        investors[16] = Investor({beneficiary: 0xc0307940D56D22F909183DC7e3abb11C6213761E, amount: 2_000_000});
        investors[17] = Investor({beneficiary: 0x79Db5792C5a84C0932EE87A41573866aBc93B320, amount: 2_000_000});
        investors[18] = Investor({beneficiary: 0xb341406e30F4f7B50987Ab8Dd6B9b13d123D6055, amount: 2_000_000});
        investors[19] = Investor({beneficiary: 0x070791aBc2cd4C9883CFd698AA5d74F78594E6AB, amount: 2_000_000});
        investors[20] = Investor({beneficiary: 0xFa676217E233AdAe28eCF45829c51c39aC0904a1, amount: 2_000_000});
        investors[21] = Investor({beneficiary: 0x26F083097A73e4Ea8Dc76D3bA21E4450A3cE4af2, amount: 2_000_000});
        investors[22] = Investor({beneficiary: 0xDBfdB48956a2BF329Ddf237E5a5297BeC3290A6A, amount: 2_000_000});
        investors[23] = Investor({beneficiary: 0x1564181dE218E614a938FBa2A3f9530509e18F79, amount: 2_000_000});
        investors[24] = Investor({beneficiary: 0x823f7ee923C1cA7DdaB1D0139a8994589597e1E2, amount: 2_000_000});
        investors[25] = Investor({beneficiary: 0x178524971fE87af7f652706021c1DAd92C5500DE, amount: 2_000_000});
        investors[26] = Investor({beneficiary: 0xE223b3dD2E2FAc7171d4b21Ff1284e2ffA3b19C7, amount: 2_000_000});
        investors[27] = Investor({beneficiary: 0x2D7610524BA318f90421134DdB678B8E64b1CD9A, amount: 2_000_000});
        investors[28] = Investor({beneficiary: 0x152297e0977154805Ddcda8e1f5F81754727E2b5, amount: 2_000_000});
        investors[29] = Investor({beneficiary: 0x0F3612a27B24EE23C4097e60653D1b02F970bD6F, amount: 2_000_000});
        investors[30] = Investor({beneficiary: 0x8Ce02Eb1A3C3e176D3bC0cBdaAAcE64715D018b5, amount: 2_000_000});
        investors[31] = Investor({beneficiary: 0xdDDe1253921669c26EfeC452e2fe172d74531fe4, amount: 2_000_000});
        investors[32] = Investor({beneficiary: 0x394763F58E7ac74fa0582c72154c80f37e76a232, amount: 2_000_000});
        investors[33] = Investor({beneficiary: 0x044F78BB51CdF3F069dF5B0430029B87987a8aA6, amount: 2_000_000});
        investors[34] = Investor({beneficiary: 0x289B39f605d6e582A116E90d4De7EEdD5A6C9ceD, amount: 2_000_000});
        investors[35] = Investor({beneficiary: 0x59faBa446741920487D7108BFE7C45d3f99d6983, amount: 2_000_000});
        investors[36] = Investor({beneficiary: 0xefd7EB4FdB72D6B504A817D9bED914eE17D8c3bf, amount: 2_000_000});
        investors[37] = Investor({beneficiary: 0xc659Bb6727de88D159409539eb2feDE4E953faB5, amount: 2_000_000});
        investors[38] = Investor({beneficiary: 0xd1556cc3116D3e1b792aDbAC529d583c603D6AE4, amount: 2_000_000});
        investors[39] = Investor({beneficiary: 0x8fA71fA2Ecbd927045000d11aeF86e2F9cf8fb1E, amount: 2_000_000});
        investors[40] = Investor({beneficiary: 0x5d4b8d5d460eC03bdF213Ff9fF715888a49D4604, amount: 2_000_000});
        investors[41] = Investor({beneficiary: 0x308c3c988EFD71E6E67A93661Ce1AAE9D659eEc3, amount: 2_000_000});
        investors[42] = Investor({beneficiary: 0x9aBff7De3B7db3Cd2008D3319fDd28d1e5874074, amount: 2_000_000});
        investors[43] = Investor({beneficiary: 0xf73C93cfE8407c8D3B1ecDaf88B2591aF2243CFb, amount: 2_000_000});
        investors[44] = Investor({beneficiary: 0x51276c786dc9f2d72Ee81DE847AF98514954523E, amount: 2_000_000});
        investors[45] = Investor({beneficiary: 0x93c407468a882FfAEF2F6D2e7226aCaECd977Ab2, amount: 2_000_000});
        investors[46] = Investor({beneficiary: 0xcC18097A21c461F919E0e95f53E4a09E543754d6, amount: 2_000_000});
        investors[47] = Investor({beneficiary: 0x2a354A92669b4FDf1a5F6aB8A75875f07EBDe61D, amount: 2_000_000});
        investors[48] = Investor({beneficiary: 0x7395867e1FF19fA40b5262bd5a1c64Cf332EEB42, amount: 2_000_000});
        investors[49] = Investor({beneficiary: 0xEf3F40B0577dE01B286C6bf75DdaE6a81E3587b3, amount: 2_000_000});
        investors[50] = Investor({beneficiary: 0x0e5ae814409CCF6E36E16cA63D439CEd24210f75, amount: 2_000_000});
        investors[51] = Investor({beneficiary: 0x454520E796B3Ce4E7a28E0E30784012F0b5A7C04, amount: 2_000_000});
        investors[52] = Investor({beneficiary: 0xf7E8B975EbdffB14fAC35CB901ff74De51F558a9, amount: 2_000_000});
        investors[53] = Investor({beneficiary: 0xe1bd5DdCb3Fdb24560F8b225b8ae7b1f7AAACE5A, amount: 2_000_000});
        investors[54] = Investor({beneficiary: 0x73B58e29146593D3646C733ea4DB2b2122B4A725, amount: 2_000_000});
        investors[55] = Investor({beneficiary: 0x653946E0DD9617E99D3E569d763fc853dC417464, amount: 2_000_000});
        investors[56] = Investor({beneficiary: 0x7eb7b74422fe5CDCA2fE7F9eA67B7AF31BD793Cb, amount: 2_000_000});
        investors[57] = Investor({beneficiary: 0xb5d0C86ba635b10f80fd36364D8e194e4c659f5D, amount: 2_000_000});
        investors[58] = Investor({beneficiary: 0xe32DAaF097118A3482983129279eEC9e755D5993, amount: 2_000_000});
        investors[59] = Investor({beneficiary: 0x92B85b62d2b5EBD28C94c1e4e673c8b0f90D7C1F, amount: 2_000_000});
        investors[60] = Investor({beneficiary: 0x7C4E324030868C01Aa02fD5B35d2cf590437413D, amount: 2_000_000});
        investors[61] = Investor({beneficiary: 0x26Aa13748AD7255a3100483d4832a66493B1205e, amount: 2_000_000});
        investors[62] = Investor({beneficiary: 0xd3daB30FAAb8beb2de9894aAa10E49038c8802E4, amount: 2_000_000});
        investors[63] = Investor({beneficiary: 0x6447B5477Fca32240BCBC2f76ED2517BFdC24E04, amount: 2_000_000});
        investors[64] = Investor({beneficiary: 0x1619BFADE3b222A1464F694Db6B961AEA39F0cc4, amount: 2_000_000});
        investors[65] = Investor({beneficiary: 0xdeb8F229E95c963A468ed050f73002bA5C5657D3, amount: 2_000_000});
        investors[66] = Investor({beneficiary: 0xFd296cf16daE71eb21Bd245613F7B236Dff1C098, amount: 2_000_000});
        investors[67] = Investor({beneficiary: 0xcA44cA3e461Aa2429b9F14e87dC8e435ee90F931, amount: 2_000_000});
        investors[68] = Investor({beneficiary: 0x61055C5E5c960984dfAE6E0dCBCcB76C80598658, amount: 2_000_000});
        investors[69] = Investor({beneficiary: 0x46B129a03C88039CE844ab0a53D06E2c6f8aebF8, amount: 2_000_000});
        investors[70] = Investor({beneficiary: 0xF30615A216f2B37959550321695Ca1575579b5EB, amount: 2_000_000});
        investors[71] = Investor({beneficiary: 0xE036b5961cacC46CE4e3B5DA716Dd91E461e0833, amount: 2_000_000});
        investors[72] = Investor({beneficiary: 0x0bCC4427020739685471Db312b943f8a1c041a18, amount: 2_000_000});
        investors[73] = Investor({beneficiary: 0x2Aa1FC532d6De950FfB21Bdc45dfF5777b4d7657, amount: 2_000_000});
        investors[74] = Investor({beneficiary: 0x5036Dd5264C72d4074134Ffa1Bc789F4D94a9a43, amount: 2_000_000});
        investors[75] = Investor({beneficiary: 0x41C24faD612D08B36aCc3B231bD2de2830921e6F, amount: 2_000_000});
        investors[76] = Investor({beneficiary: 0x17780f91e1F22562b2b74cC4EF4C6869BadD7D7a, amount: 2_000_000});
        investors[77] = Investor({beneficiary: 0xFCD4214061548880c09e51c3C31D937b4A46600B, amount: 2_000_000});
        investors[78] = Investor({beneficiary: 0x808d5cc513c1E2B2B4babE398207772AfA822430, amount: 2_000_000});
        investors[79] = Investor({beneficiary: 0xAAc0FC18468e2076F4E2e8053b447707F9d177be, amount: 2_000_000});
        investors[80] = Investor({beneficiary: 0x5d8916f63b0c3FCB97EAf4c373f79DFf3ef2d051, amount: 2_000_000});
        investors[81] = Investor({beneficiary: 0x255d7B9AA14Ff9a6a48af280972d9594c1858b8C, amount: 2_000_000});
        investors[82] = Investor({beneficiary: 0x8c746aD706C4B2B688cD4d02055cdF7241BD5621, amount: 2_000_000});
        investors[83] = Investor({beneficiary: 0x1AE8a50108230Ce7CA865003A85fbF6b52e72982, amount: 2_000_000});
        investors[84] = Investor({beneficiary: 0x016F8C20C48f027da515B907814D84d720b2654C, amount: 2_000_000});
        investors[85] = Investor({beneficiary: 0xa014d79FeA4bC2b7Ea30a099f5408c60261b1349, amount: 2_000_000});
        investors[86] = Investor({beneficiary: 0x623d61239c7d4309aE61951De4f4FE42ECf2Df77, amount: 2_000_000});
        investors[87] = Investor({beneficiary: 0x76F630c25F2Ec1ccA02c7790F46216F0430829bF, amount: 2_000_000});
        investors[88] = Investor({beneficiary: 0x5ecB6fD02dC43C021Cbca740bA7a045AC6e0a74b, amount: 2_000_000});
        investors[89] = Investor({beneficiary: 0xa4f2c4D0DdB17aebd9e5FDDBC9b83489ae44e197, amount: 2_000_000});
    }
}

interface IJellyToken {
    function approve(address spender, uint256 amount) external;
}

interface IChest {
    function stakeSpecial(
        uint256 amount,
        address beneficiary,
        uint32 freezingPeriod,
        uint32 vestingDuration,
        uint8 nerfParameter
    ) external;
    function fee() external view returns (uint256);
}
