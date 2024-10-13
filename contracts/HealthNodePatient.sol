// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";

// interface IDoctorNode {
//     function isDoctorAvailable(address doctorAddr) external view returns (bool);
//     function getDoctorServices(address doctorAddr) external view returns (bool homeVisit, bool liveConsultation);
// }


contract PatientNode is AccessControl {

    IDoctorNode public doctorNode;

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

    // Doctor Access
    struct DoctorAccess {
        bool hasAccess;
        uint256 accessExpiration;
    }

    mapping(address => Patient) private patients;
    mapping(address => mapping(address => DoctorAccess)) private doctorAccess;
    


    event PatientRegistered(address indexed patient, string name);
    event MedicalRecordUploaded(address indexed patient, string ipfsHash);
    event DoctorAccessGranted(address indexed patient, address indexed doctor, uint256 expirationTime);
    event DoctorAccessRevoked(address indexed patient, address indexed doctor);


    constructor() {
        // _setupRole(ADMIN_ROLE, admin);
        // doctorNode = IDoctorNode(_doctorNodeAddress);
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
        require(
                isDoctorAuthorized(patientAddr, msg.sender),
                "Doctor does not have active access to this patient's data"
            );

        Patient memory patient = patients[patientAddr];
        return (patient.name, patient.age, patient.gender, patient.ipfsRecordHash);
    }


    // grant access to doctor. 
    function grantAccessToDoctor(address doctorAddr, uint256 accessDuration) external onlyRole(PATIENT_ROLE) {
        require(patients[msg.sender].registered, "Only registered patients can grant access");
        require(doctorNode.isDoctorAvailable(doctorAddr), "Doctor not available");
        require(hasRole(DOCTOR_ROLE, doctorAddr), "Address is not a registered doctor");
        
        uint256 expirationTime = block.timestamp + accessDuration;
        doctorAccess[msg.sender][doctorAddr] = DoctorAccess(true, expirationTime);
        
        emit DoctorAccessGranted(msg.sender, doctorAddr, expirationTime);
    }


    // revoke access
    function revokeAccessFromDoctor(address doctorAddr) external onlyRole(PATIENT_ROLE) {
        require(patients[msg.sender].registered, "Only registered patients can revoke access");
        require(doctorAccess[msg.sender][doctorAddr].hasAccess, "Doctor does not have access");
        
        delete doctorAccess[msg.sender][doctorAddr];
        
        emit DoctorAccessRevoked(msg.sender, doctorAddr);
    }

    function isDoctorAuthorized(address patientAddr, address doctorAddr) internal view returns (bool) {
        return (
            doctorAccess[patientAddr][doctorAddr].hasAccess &&
            doctorAccess[patientAddr][doctorAddr].accessExpiration > block.timestamp
        );
    }

    
}
