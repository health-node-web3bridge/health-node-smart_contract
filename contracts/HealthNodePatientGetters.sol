// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./HealthNodeHelpers.sol";

contract HealthNodePatientGetters is HealthNodeHelpers {
    // HealthNodeStorage public immutable storageContract;

    HealthNodeStorage public sc = storageContract; 

    constructor(address _storageAddress) HealthNodeHelpers(_storageAddress) {
        // sc = storageContract;
    }

    // **************** VIEW FUNCTIONS ******************* //

    function viewMedicalRecords() external view onlyRole(PATIENT_ROLE) returns (string[] memory) {
        checkSelfPatientStatus();

        return patients[msg.sender].ipfsRecordHashes;
    }

    function viewMedicalRecord(uint256 _hashId) external view onlyRole(PATIENT_ROLE) returns (string memory) {
        // Perform sanity check
        checkSelfPatientStatus();

        return patients[msg.sender].ipfsRecordHashes[_hashId]; //??
    }

    function getMyData() external view onlyRole(PATIENT_ROLE) returns (string memory, string memory, string memory, uint256) {
        // Perform sanity check
        checkSelfPatientStatus();

        Patient storage patient = patients[msg.sender];
        return (patient.name, patient.email, patient.gender, patient.age);
    }

    function getPatient(address _patientAddress) public view returns (Patient memory) {
        // Perform sanity check
        checkZeroAddress();
        checkPatientStatus(_patientAddress);

        return patients[_patientAddress];
    }

    function getPatients() public view returns (Patient[] memory) {
        // Perform sanity check
        checkZeroAddress();

        return patientList;
    }
}
