// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const HealthNodePatientModule = buildModule("HealthNodePatientModule", (m) => {
    const healthNodePatient = m.contract("HealthNodePatient");

    return { healthNodePatient };
});

export default HealthNodePatientModule;
