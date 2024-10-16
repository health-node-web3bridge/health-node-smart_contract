// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./HealthNodeHelpers.sol";

contract HealthNodePatient is HealthNodeHelpers {

    constructor() {
        // _setupRole(ADMIN_ROLE, admin);
        // doctorNode = IDoctorNode(_doctorNodeAddress);
    }

   // **************** WRITE FUNCTIONS ******************* //
    function registerPatient(string memory _name, string memory _email, string memory _gender, uint8 _age) external { 
        // Perform sanity check
        checkZeroAddress();
        require(!patients[msg.sender].isRegistered, PatientAlreadyRegistered());

        //
        checkStringLength(_name);
        checkStringLength(_email);
        checkStringLength(_gender);

        uint256 patientId = patientCounter++;

        Patient memory newPatient;

        newPatient.id = patientId;
        newPatient.name = _name;
        newPatient.email = _email;
        newPatient.gender = _gender;
        newPatient.age = _age;
        newPatient.isRegistered = true;
        newPatient.isActive = true;

        patients[msg.sender] = newPatient;
        patientList.push(newPatient);

        _grantRole(PATIENT_ROLE, msg.sender);

        emit PatientRegistered(msg.sender, _name);
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

        Patient memory patient = patients[msg.sender];
        return (patient.name, patient.email, patient.gender, patient.age);
    }
}


/*

Patient Flow:
● Register on the platform and upload medical records to decentralized storage. - levi 
● Browse available doctors and select the service (home visit or live consultation). - koxy
● Grant the selected doctor temporary access to medical records. - koxy
● Conduct live consultation or receive home service. -  levi
● Pay for the service via cryptocurrency, and have the doctor’s notes added to their records. - dike

*/