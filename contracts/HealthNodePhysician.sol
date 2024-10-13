// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IPatientNode {
    function viewMedicalRecord(address patientAddr) external view returns (string memory);
    function getPatientData(address patientAddr) external view returns (string memory, uint256, string memory, string memory);
    function updateMedicalRecord(address patientAddr, string memory consultationNotes) external;
}

contract DoctorNode is AccessControl {

    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");

    IPatientNode patientNode;  // Instance of the PatientNode contract

    constructor(address _patientNodeAddress) {
        patientNode = IPatientNode(_patientNodeAddress);
        _grantRole(DOCTOR_ROLE, msg.sender);  // Granting Doctor Role
    }

    // Doctor viewing a patient's medical record
    function viewPatientRecord(address patientAddr) public view onlyRole(DOCTOR_ROLE) returns (string memory) {
        return patientNode.viewMedicalRecord(patientAddr);
    }

    // Conduct the service and update the medical record with consultation notes
    function updatePatientRecord(address patientAddr, string memory consultationNotes) public onlyRole(DOCTOR_ROLE) {
        // Update the patient's medical record with consultation notes or prescriptions
        patientNode.updateMedicalRecord(patientAddr, consultationNotes);
    }
}
