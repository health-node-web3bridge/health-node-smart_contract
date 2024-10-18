// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./HealthNodeHelpers.sol";
// import "./HealthNodePatientSetters.sol";

contract HealthNodeDoctor is HealthNodeHelpers {

    constructor(address _storageAddress) HealthNodeHelpers(_storageAddress) {}

    // **************** WRITE FUNCTIONS ******************* //

    function registerDoctor(
        uint256 _rate,
        string memory _name,
        string memory _email,
        string memory _specialty
    ) public {
        // Perform sanity check
        checkZeroAddress();
        require(!doctors[msg.sender].isRegistered, DoctorAlreadyRegistered());

        checkStringLength(_name);
        checkStringLength(_email);
        checkStringLength(_specialty);

        uint256 doctorId = doctorCounter++;

        Doctor memory newDoctor;

        newDoctor.id = doctorId;
        newDoctor.rate = _rate;
        newDoctor.name = _name;
        newDoctor.email = _email;
        newDoctor.specialty = _specialty;
        newDoctor.isRegistered = true;
        newDoctor.isActive = true;
        newDoctor.isVerified = false;

        doctors[msg.sender] = newDoctor;
        doctorList.push(newDoctor);

        _grantRole(DOCTOR_ROLE, msg.sender);

        emit DoctorRegistered(msg.sender, _name);
    }

    function verifyDoctor(string memory _licenseHash) public {
        // Perform sanity check
        checkSelfDoctorStatus();

        Doctor storage doc = doctors[msg.sender];
        uint256 index = doc.id;

        doc.isVerified = true;
        doc.licenseHash = _licenseHash;
        doctorList[index].licenseHash = _licenseHash;
        doctorList[index].isVerified = true;

        emit DoctorVerified(msg.sender);
    }

    function acceptConsultation(address _patientAddress, uint256 _consultationId) external {
        checkSelfDoctorStatus();
        checkPatientStatus(_patientAddress);

        require(hasRole(PATIENT_ROLE, _patientAddress), PatientNotRegistered());

        Consultation storage con = consultations[msg.sender][_patientAddress][_consultationId];
        con.isAccepted = true;

        emit ConsultationAccepted(msg.sender, _patientAddress, _consultationId);
    }

    function endConsultation(address _patientAddress, uint256 _consultationId) external onlyRole(DOCTOR_ROLE) {
        checkSelfDoctorStatus();
        checkPatientStatus(_patientAddress);

        Consultation storage con = consultations[msg.sender][_patientAddress][_consultationId];
        checkConsultationValidity(con.isAccepted, con.deadline);
        con.isCompleted = true;

        emit ConsultationEnded(msg.sender, _patientAddress, _consultationId);
    }

    function savePatientRecord(address _patientAddress, string memory _ipfsRecordHash) public onlyRole(DOCTOR_ROLE) {
        // Perform sanity check
        checkSelfDoctorStatus();
        checkPatientStatus(_patientAddress);
        checkStringLength(_ipfsRecordHash);

        verifyDoctorAccess(_patientAddress, msg.sender);

        //  confirm acccess!!
        patients[_patientAddress].ipfsRecordHashes.push(_ipfsRecordHash);

        emit MedicalRecordSaved(_patientAddress);
    }

    function requestPayment(address _patientAddress, uint256 _consultationId) external {
        // Perform sanity check
        checkSelfDoctorStatus();
        checkPatientStatus(_patientAddress);

        verifyDoctorAccess(_patientAddress, msg.sender);

        Consultation storage con = consultations[msg.sender][msg.sender][_consultationId];

        require(con.isAccepted, ConsultationRejected());
        require(con.isCompleted, ConsultationOngoing());
        require(con.isFulfilled, ConsultationUnfulfilled());

        (bool success,) = payable(msg.sender).call{value: con.price}("");
        require(success, PaymentFailed());

        emit ConsultationResolved(_patientAddress, msg.sender, _consultationId);
    }

    function attachToHospital(address _hospitalAddress) external onlyRole(DOCTOR_ROLE) {
        checkSelfDoctorStatus();
        checkHospitalStatus(_hospitalAddress);

        Hospital storage hospice = hospitals[_hospitalAddress];
        Doctor storage doc = doctors[msg.sender];
        doc.hospitalId = hospice.id;
    }

  // **************** VIEW FUNCTIONS ******************* //

    function viewPatientRecords(address _patientAddress) external view onlyRole(DOCTOR_ROLE) returns (string[] memory) {
        // Perform sanity check
        checkSelfDoctorStatus();
        checkPatientStatus(_patientAddress);
        verifyDoctorAccess(_patientAddress, msg.sender);

        return patients[_patientAddress].ipfsRecordHashes;
    }

    function viewPatientRecord(address _patientAddress, uint256 _hashId) external view onlyRole(DOCTOR_ROLE) returns (string memory) {
        // Perform sanity check
        checkSelfDoctorStatus();
        checkPatientStatus(_patientAddress);
        verifyDoctorAccess(_patientAddress, msg.sender);

        return patients[msg.sender].ipfsRecordHashes[_hashId];
    }

        // Retrieve patient data (for frontend)
    function getPatientData(address _patientAddress) external view onlyRole(DOCTOR_ROLE) returns (string memory, string memory, string memory, uint256) {
        // Perform sanity check
        checkSelfDoctorStatus();
        checkPatientStatus(_patientAddress);
        verifyDoctorAccess(_patientAddress, msg.sender);

        Patient memory patient = patients[_patientAddress];
        return (patient.name, patient.email, patient.gender, patient.age);
    }

    function getDoctor(address _doctorAddress) public view returns (Doctor memory) {
        // Perform sanity check
        checkZeroAddress();
        checkDoctorStatus(_doctorAddress);

        return doctors[_doctorAddress];
    }

    function getDoctors() public view returns (Doctor[] memory) {
        // Perform sanity check
        checkZeroAddress();

        return doctorList;
    }
}
