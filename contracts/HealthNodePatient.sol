// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract PatientNode is AccessControl {

    // roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");
    bytes32 public constant PATIENT_ROLE = keccak256("PATIENT_ROLE");

    // Patient
    struct Patient {
        bool registered;
        string name;
        uint256 age;
        string gender;
        string ipfsRecordHash;  // Hash to store medical records from IPFS
    }

    mapping(address => Patient) private patients;

    event PatientRegistered(address indexed patient, string name);
    event MedicalRecordUploaded(address indexed patient, string ipfsHash);

    constructor() {
        // _setupRole(ADMIN_ROLE, admin);
    }

    function registerPatient(string memory _name, uint256 _age, string memory _gender) public {
        require(!patients[msg.sender].registered, "Patient already registered");

        patients[msg.sender] = Patient({
            registered: true,
            name: _name,
            age: _age,
            gender: _gender,
            ipfsRecordHash: "" 
        });

        _grantRole(PATIENT_ROLE, msg.sender);

        emit PatientRegistered(msg.sender, _name);
    }

    // upload medical records to IPFS (by patient themselves)
    function uploadMedicalRecord(string memory _ipfsRecordHash) public onlyRole(PATIENT_ROLE) {
        require(patients[msg.sender].registered, "Patient not registered");

        patients[msg.sender].ipfsRecordHash = _ipfsRecordHash;

        emit MedicalRecordUploaded(msg.sender, _ipfsRecordHash);
    }

    function viewMedicalRecord(address patientAddr) public view onlyRole(DOCTOR_ROLE) returns (string memory) {
        require(patients[patientAddr].registered, "Patient not registered");

        return patients[patientAddr].ipfsRecordHash;
    }

    // Retrieve patient data (for frontend)
    function getPatientData(address patientAddr) public view returns (string memory, uint256, string memory, string memory) {
        require(patients[patientAddr].registered, "Patient not registered");

        Patient memory patient = patients[patientAddr];
        return (patient.name, patient.age, patient.gender, patient.ipfsRecordHash);
    }
}
