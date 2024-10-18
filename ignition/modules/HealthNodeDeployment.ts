import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const HealthNodeModule = buildModule("HealthNodeDeployment", (m) => {
    // First deploy storage
    const storage = m.contract("HealthNodeStorage");

    // Deploy helpers with storage address
    const helpers = m.contract("HealthNodeHelpers", [storage]);

    // Deploy remaining contracts, all using storage address
    const patientGetters = m.contract("HealthNodePatientGetters", [storage]);
    const patientSetters = m.contract("HealthNodePatientSetters", [storage]);
    const doctor = m.contract("HealthNodeDoctor", [storage]);
    const hospital = m.contract("HealthNodeHospital", [storage]);

    return {
        storage,
        helpers,
        patientGetters,
        patientSetters,
        doctor,
        hospital
    };
});

export default HealthNodeModule;