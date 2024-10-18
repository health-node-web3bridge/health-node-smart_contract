import hre, { ethers } from "hardhat";

async function main() {
  try {
    console.log("Starting deployment sequence...");

    // Get the contract factories
    const Storage = await ethers.getContractFactory("HealthNodeStorage");
    const Helpers = await ethers.getContractFactory("HealthNodeHelpers");
    const PatientGetters = await ethers.getContractFactory("HealthNodePatientGetters");
    const PatientSetters = await ethers.getContractFactory("HealthNodePatientSetters");
    const Doctor = await ethers.getContractFactory("HealthNodeDoctor");
    const Hospital = await ethers.getContractFactory("HealthNodeHospital");

    // Deploy Storage first
    console.log("1. Deploying Storage contract...");
    const storage = await Storage.deploy();
    await storage.deployed();
    console.log("Storage deployed to:", storage.target);

    // Deploy Helpers with Storage address
    console.log("\n2. Deploying Helpers contract...");
    const helpers = await Helpers.deploy(storage.target);
    await helpers.deployed();
    console.log("Helpers deployed to:", helpers.target);

    // Deploy the remaining contracts with Storage address
    console.log("\n3. Deploying PatientGetters contract...");
    const patientGetters = await PatientGetters.deploy(storage.target);
    await patientGetters.deployed();
    console.log("PatientGetters deployed to:", patientGetters.target);

    console.log("\n4. Deploying PatientSetters contract...");
    const patientSetters = await PatientSetters.deploy(storage.target);
    await patientSetters.deployed();
    console.log("PatientSetters deployed to:", patientSetters.target);

    console.log("\n5. Deploying Doctor contract...");
    const doctor = await Doctor.deploy(storage.target);
    await doctor.deployed();
    console.log("Doctor deployed to:", doctor.target);

    console.log("\n6. Deploying Hospital contract...");
    const hospital = await Hospital.deploy(storage.target);
    await hospital.deployed();
    console.log("Hospital deployed to:", hospital.target);

    // Log all deployed addresses for verification
    console.log("\n=== Deployment Summary ===");
    console.log("Storage:", storage.target);
    console.log("Helpers:", helpers.target);
    console.log("PatientGetters:", patientGetters.target);
    console.log("PatientSetters:", patientSetters.target);
    console.log("Doctor:", doctor.target);
    console.log("Hospital:", hospital.target);

  } catch (error) {
    console.error("Deployment failed:", error);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
