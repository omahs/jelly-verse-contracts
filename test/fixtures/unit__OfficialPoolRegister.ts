import { ethers } from "hardhat";
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { OfficialPoolsRegister } from "../../typechain-types";

type UnitOfficialPoolRegisterFixtureType = {
  officialPoolsRegister: OfficialPoolsRegister;
  owner: SignerWithAddress;
  pendingOwner: SignerWithAddress;
};

export async function unitOficialPoolRegisterFixture(): Promise<UnitOfficialPoolRegisterFixtureType> {
  const [owner, pendingOwner] = await ethers.getSigners();

  const OfificialPoolRegisterFactory = await ethers.getContractFactory('OfficialPoolsRegister');
  const officialPoolsRegister = await OfificialPoolRegisterFactory.deploy(
    owner.address,
    pendingOwner.address
  );

  return { officialPoolsRegister, owner, pendingOwner };
}
