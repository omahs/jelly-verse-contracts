// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {Ownable} from "./utils/Ownable.sol";
import {IChest} from "./IChest.sol";
import {IERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract InvestorDistribution is Ownable {
    struct Investor {
        address beneficiary;
        uint96 amount;
    }

    uint256 constant NUMBER_OF_INVESTORS = 87;
    uint256 constant JELLY_AMOUNT = 107_477_975;
    uint32 constant FREEZING_PERIOD = 18 * 30 days;
    uint32 constant VESTING_DURATION = 6 * 30 days;
    uint8 constant NERF_PARAMETER = 10; // no nerf
    
    uint64 private constant DECIMALS = 1e18;

    IERC20 public immutable i_jellyToken;

    uint32 index;

    Investor[NUMBER_OF_INVESTORS] internal investors;
    IChest public i_chest;

    event ChestSet(address chest);
    event BatchDistributed(uint256 indexed startIndex, uint256 batchLength);

    error InvestorDistribution__InvalidBatchLength();
    error InvestorDistribution__DistributionIndexOutOfBounds();
    error InvestorDistribution__ChestAlreadySet();

    constructor(
        address jellyToken,
        address owner,
        address pendingOwner
    ) Ownable(owner, pendingOwner) {
        i_jellyToken = IERC20(jellyToken);
        _initialize();
    }

    // not sure if we need onlyOwner here
    function distribute(uint32 batchLength) external onlyOwner {
        if (batchLength == 0) {
            revert InvestorDistribution__InvalidBatchLength();
        }

        uint32 currentIndex = index;

        uint32 endIndex = currentIndex + batchLength;
        if (endIndex > NUMBER_OF_INVESTORS) {
            revert InvestorDistribution__DistributionIndexOutOfBounds();
        }

        index = endIndex;
        
        for (uint256 i = currentIndex; i < endIndex; i++) {
            i_chest.stakeSpecial(
                investors[i].amount * DECIMALS,
                investors[i].beneficiary,
                FREEZING_PERIOD,
                VESTING_DURATION,
                NERF_PARAMETER
            );
        }

        emit BatchDistributed(currentIndex, batchLength);
    }

    function setChest(address chest) external onlyOwner {
        if (address(i_chest) != address(0)) {
            revert InvestorDistribution__ChestAlreadySet();
        }

        i_chest = IChest(chest);
        emit ChestSet(chest);
        // Approve the total amount once for the all investors
        uint256 totalFees = NUMBER_OF_INVESTORS * i_chest.fee();

        i_jellyToken.approve(
            address(i_chest),
            JELLY_AMOUNT * DECIMALS + totalFees
        );
    }

    function _initialize() private {
        investors[0] = Investor({
            beneficiary: 0x0928a4Debc0297A643ECA744b41b09512A32c0e1,
            amount: 2_000_000
        });
        investors[1] = Investor({
            beneficiary: 0x0e5E44D03996f14E469DEb2c0bE5b833bAC139a9,
            amount: 2_000_000
        });
        investors[2] = Investor({
            beneficiary: 0x09520EB2382f9Fd25f6bE7B1b20A693a8f8b493d,
            amount: 2_000_000
        });
        investors[3] = Investor({
            beneficiary: 0xB8c75DB43E891Da43E6B314D5F9949C9388cceE9,
            amount: 2_000_000
        });
        investors[4] = Investor({
            beneficiary: 0xeBcC1Bf83EE1764a87f968CedD71b477Cab5e81d,
            amount: 2_000_000
        });
        investors[5] = Investor({
            beneficiary: 0xc1ee290ab4586a75A95ef8CD3988431907Ddf058,
            amount: 2_000_000
        });
        investors[6] = Investor({
            beneficiary: 0xf02B1cfc65662DC6Fec8a339bCDb12a65f43c609,
            amount: 2_000_000
        });
        investors[7] = Investor({
            beneficiary: 0x72F3ee9Dc226578B88bd93276b8700B861aA4209,
            amount: 2_000_000
        });
        investors[8] = Investor({
            beneficiary: 0x20D1c442367FFe623ed331F5945fDDeF594bc920,
            amount: 2_000_000
        });
        investors[9] = Investor({
            beneficiary: 0xd8336c8Bc3Fa686c0b757294Bcc9038E79Cd6cE1,
            amount: 2_000_000
        });
        investors[10] = Investor({
            beneficiary: 0x32479b83c4e58a5d523a61E19309759ead3d0DDa,
            amount: 2_000_000
        });
        investors[11] = Investor({
            beneficiary: 0x23C538E1a4a88eE88Ef3A61844b046bF5f70238F,
            amount: 2_000_000
        });
        investors[12] = Investor({
            beneficiary: 0x075f3cD4C6eB50a425bfCF42B6A3F3d1A40cC68f,
            amount: 2_000_000
        });
        investors[13] = Investor({
            beneficiary: 0xb728aA268D3Cb7a62ecc03e4DBF307AE7FB841Ae,
            amount: 2_000_000
        });
        investors[14] = Investor({
            beneficiary: 0x3b096530De8D29F9003A01846aA03612Ab91B805,
            amount: 2_000_000
        });
        investors[15] = Investor({
            beneficiary: 0x7f8A9fAF5CF0796B856879242C879125fc9857EF,
            amount: 1_933_500
        });
        investors[16] = Investor({
            beneficiary: 0x3DBAf3F4a434228546f0c08902b592995Bd0e6D2,
            amount: 2_000_000
        });
        investors[17] = Investor({
            beneficiary: 0x1c20279F6A23ebc87D1b4556c67158B5FC2Fc714,
            amount: 2_000_000
        });
        investors[18] = Investor({
            beneficiary: 0xB5fA168678A04C7EB090BF868982222AeF0C3f31,
            amount: 2_000_000
        });
        investors[19] = Investor({
            beneficiary: 0x0898727C7812EcfaF1346117F45986D137b27769,
            amount: 2_000_000
        });
        investors[20] = Investor({
            beneficiary: 0x47FDB6C12533c71AE30609F5dd8A05A98E481E29,
            amount: 2_000_000
        });
        investors[21] = Investor({
            beneficiary: 0xDcC876EEB1189F9b4843a3E07d87e307C0ef4dC3,
            amount: 2_000_000
        });
        investors[22] = Investor({
            beneficiary: 0x0C5F37618A73dD14EbD0CAD44d13797f06b30E2F,
            amount: 2_000_000
        });
        investors[23] = Investor({
            beneficiary: 0x6a6c29d189C40E64D3Bc3eE5892006072EF047fD,
            amount: 2_000_000
        });
        investors[24] = Investor({
            beneficiary: 0x8Eff44b2D312bd66e568D41048DCBE23FF1EbcF0,
            amount: 2_000_000
        });
        investors[25] = Investor({
            beneficiary: 0xd8Ced559178ea66B23E2C0AD02E23aB20fe5785F,
            amount: 2_000_000
        });
        investors[26] = Investor({
            beneficiary: 0xd8Ced559178ea66B23E2C0AD02E23aB20fe5785F,
            amount: 2_000_000
        });
        investors[27] = Investor({
            beneficiary: 0xA2879Be7E5B699496d6a41BF41D9505fF9Ba1804,
            amount: 2_000_000
        });
        investors[28] = Investor({
            beneficiary: 0xA2879Be7E5B699496d6a41BF41D9505fF9Ba1804,
            amount: 2_000_000
        });
        investors[29] = Investor({
            beneficiary: 0x5fD704cDC9b5485A8ec4458681C59A863CCA09aA,
            amount: 1_750_000
        });
        investors[30] = Investor({
            beneficiary: 0xF7f0AC2557c8De0eC97c7c6fe3dc8F66c3Db20A4,
            amount: 2_000_000
        });
        investors[31] = Investor({
            beneficiary: 0xED124CAbc5D2f1dA6446D8a0F5f3e0FA506E84A4,
            amount: 2_000_000
        });
        investors[32] = Investor({
            beneficiary: 0x39f495892d9213bdC7eC6FA89F4BaE635D89135d,
            amount: 2_000_000
        });
        investors[33] = Investor({
            beneficiary: 0xF9148EB4fc1F4A5C9ba062EF7e9dF2fa6dba7191,
            amount: 2_000_000
        });
        investors[34] = Investor({
            beneficiary: 0xF1aD8C648D48d42967a5652c2A629f2f825fab59,
            amount: 2_000_000
        });
        investors[35] = Investor({
            beneficiary: 0x00092f4e819E7F304bc947e89aC585740AfC5688,
            amount: 2_000_000
        });
        investors[36] = Investor({
            beneficiary: 0x6Cbb4f6d1D34E4cd106397dFd8826000AAa46Fc7,
            amount: 2_000_000
        });
        investors[37] = Investor({
            beneficiary: 0x90Af6b2Ad02dbEba74236a23d45386e126c49b42,
            amount: 2_000_000
        });
        investors[38] = Investor({
            beneficiary: 0x18cA3b02f2CE2eBF97bA83dBf081e3Db9c7d1180,
            amount: 2_000_000
        });
        investors[39] = Investor({
            beneficiary: 0xf8c6110C1b1c03bD7BFBE267Cc9395b72D7d1d5A,
            amount: 2_000_000
        });
        investors[40] = Investor({
            beneficiary: 0xB284929c0C79C24AdfC607DE921f49187Bc2B0be,
            amount: 2_000_000
        });
        investors[41] = Investor({
            beneficiary: 0xFDAe0e73bE9D4Bb5439ed1724aF6435fE91C1c69,
            amount: 1_600_000
        });
        investors[42] = Investor({
            beneficiary: 0xfc33f5E0c2229c4693c17f10A2A7164f76Ed073b,
            amount: 2_000_000
        });
        investors[43] = Investor({
            beneficiary: 0x90f8939Ad48fa2798d31dDb5602B967660f7c2E2,
            amount: 1_600_000
        });
        investors[44] = Investor({
            beneficiary: 0xB1600ac28dc130f7186b546a0cbDA15Bde57F7e9,
            amount: 2_000_000
        });
        investors[45] = Investor({
            beneficiary: 0xf763daA4Da2ee73529A0cf1F533F81e0860F6aFC,
            amount: 700_000
        });
        investors[46] = Investor({
            beneficiary: 0xE1D86E65eB9F25ACdAA8Ff03aE55220d3e2e2d67,
            amount: 1_125_000
        });
        investors[47] = Investor({
            beneficiary: 0x82b290ae80cfC0365d0C4e4058Fe334b1E517659,
            amount: 1_125_000
        });
        investors[48] = Investor({
            beneficiary: 0x6A3b06129d5593768f85b0ec227031d169CbC0be,
            amount: 1_375_000
        });
        investors[49] = Investor({
            beneficiary: 0x0eFda0A73D01356e0863319E7610928BF63B989c,
            amount: 11_000
        });
        investors[50] = Investor({
            beneficiary: 0x2FE3f533D3734546b82A598A84e8A07573145C5E,
            amount: 96_250
        });
        investors[51] = Investor({
            beneficiary: 0x42D8a772Bf01A095e68FBeda4597567AE61d0376,
            amount: 412_500
        });
        investors[52] = Investor({
            beneficiary: 0x8197C0b1f12391B60a9DFc60e2dfF0E3D61b2903,
            amount: 440_000
        });
        investors[53] = Investor({
            beneficiary: 0x3793A90a843570bDd229ceF5d0bF9566b20a048E,
            amount: 220_000
        });
        investors[54] = Investor({
            beneficiary: 0x4e3E8e414F7Ebe03B4557db78c1CE825831E2Db0,
            amount: 8_800
        });
        investors[55] = Investor({
            beneficiary: 0x7efF613Bc9688B77b1104Ac2eF685E12C9D60D3A,
            amount: 66_000
        });
        investors[56] = Investor({
            beneficiary: 0x53cE98e433aA81e919A1579D88Fa0A3365B8bfF7,
            amount: 660_000
        });
        investors[57] = Investor({
            beneficiary: 0x58671E2FA2066D8AB323d6D1ED587f06B3078B2B,
            amount: 220_000
        });
        investors[58] = Investor({
            beneficiary: 0x9EA66c6ed59e118Ea7144341448Be58283c1B302,
            amount: 220_000
        });
        investors[59] = Investor({
            beneficiary: 0xc54DDEb4e7feBfB580942993f466C91FA37C0f11,
            amount: 687_500
        });
        investors[60] = Investor({
            beneficiary: 0xd92e7dF42919862231E39cA87bCFbcb6f76B7eA2,
            amount: 1_250_000
        });
        investors[61] = Investor({
            beneficiary: 0x90530B87D55EAC8C5f73Fc92187643Bec0DD2103,
            amount: 800_000
        });
        investors[62] = Investor({
            beneficiary: 0x06C55609EA7178409688774C816f3Ee59FBf0433,
            amount: 137_500
        });
        investors[63] = Investor({
            beneficiary: 0x9E74A32B297Ca54fe95fA7f2c58e7e3565231bA1,
            amount: 55_000
        });
        investors[64] = Investor({
            beneficiary: 0xBdea0cb47663ede5BBdb0b44Feb375Ea71993D3a,
            amount: 400_000
        });
        investors[65] = Investor({
            beneficiary: 0x47F48b1fA11b05a64F7Ac42Ff4ef285e555eb610,
            amount: 175_000
        });
        investors[66] = Investor({
            beneficiary: 0x86dFc56c83cFCF4Fb0781a81d361ca74431E56D3,
            amount: 100_000
        });
        investors[67] = Investor({
            beneficiary: 0x6582108c774B9394C6220c6C78a6B4bCdB7bd62E,
            amount: 100_000
        });
        investors[68] = Investor({
            beneficiary: 0xe7a0b59817D12cD44DaA3dcE874BF598BeC3feD5,
            amount: 412_500
        });
        investors[69] = Investor({
            beneficiary: 0x1e978C357169FA1A8ada7925dbd2D60dE4aE4b10,
            amount: 62_500
        });
        investors[70] = Investor({
            beneficiary: 0xB2027993c9dE9cAaD715c6Db9BFb083B62EC2746,
            amount: 675_000
        });
        investors[71] = Investor({
            beneficiary: 0x058Bb43f5828DD848b2d003C4745Cc65631b4635,
            amount: 27_500
        });
        investors[72] = Investor({
            beneficiary: 0x05256BD1225eC00E4340ff5714ce9b259B9DAecD,
            amount: 68_750
        });
        investors[73] = Investor({
            beneficiary: 0x6C1856AC12fa8bF9932270a06f87913d1498DE83,
            amount: 1_000_000
        });
        investors[74] = Investor({
            beneficiary: 0xb0185100D77dB21dD5FebBCf724147D025B33A61,
            amount: 250_000
        });
        investors[75] = Investor({
            beneficiary: 0xfFDf5cB1Bf43Fe82192cfD9d30a03D7A27ECda15,
            amount: 27_500
        });
        investors[76] = Investor({
            beneficiary: 0x4D9e3464F4ACf1b37eD42253f27F6b5FAF58dCE0,
            amount: 708_675
        });
        investors[77] = Investor({
            beneficiary: 0x0fBF8bC1B40640150293DDb75CCeFcF69D2Ab2b3,
            amount: 125_000
        });
        investors[78] = Investor({
            beneficiary: 0x1cfdEE1a0b420098167Bb315EA90BE9c4533452e,
            amount: 75_000
        });
        investors[79] = Investor({
            beneficiary: 0x049a239D809A7BD4D5C236d82456501115A15D2e,
            amount: 27_500
        });
        investors[80] = Investor({
            beneficiary: 0x5ece4Ec300191Baa794fF8F87c80Ac898b17fc97,
            amount: 275_000
        });
        investors[81] = Investor({
            beneficiary: 0xe7CaA11f4d4EDC9275f7741B3487C12149F8F286,
            amount: 300_000
        });
        investors[82] = Investor({
            beneficiary: 0x7Da77A3b8485B7472Fc2A23C594B3406EFc563aC,
            amount: 25_000
        });
        investors[83] = Investor({
            beneficiary: 0x44E04071b8eB38f1E8a177E98e2022DB6AAC93B5,
            amount: 25_000
        });
        investors[84] = Investor({
            beneficiary: 0x73C87dB70B06DAA7BA1f93B12f13601c815C4F97,
            amount: 125_000
        });
        investors[85] = Investor({
            beneficiary: 0xa014d79FeA4bC2b7Ea30a099f5408c60261b1349,
            amount: 2_000_000
        }); // change to real values
        investors[86] = Investor({
            beneficiary: 0x623d61239c7d4309aE61951De4f4FE42ECf2Df77,
            amount: 2_000_000
        }); // change to real values
    }
}
