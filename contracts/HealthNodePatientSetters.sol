// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./HealthNodeHelpers.sol";
// import "./HealthNodePatientGetters.sol";

contract HealthNodePatientSetters is HealthNodeHelpers {
    
    constructor(address _storageAddress) HealthNodeHelpers(_storageAddress) {}

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

    function bookConsultation(address _doctorAddress, uint256 _price, uint256 _duration, ConsultationType _appointmentType) external {
        checkSelfPatientStatus();
        checkDoctorStatus(_doctorAddress);
        checkDoctorAvailability(_doctorAddress);

        require(hasRole(DOCTOR_ROLE, _doctorAddress), DoctorNotRegistered());

        Patient storage p = patients[msg.sender];
        uint256 consultId = p.consultationCount++;

        Consultation memory newConsult;

        newConsult.id = consultId;
        newConsult.price = _price;
        newConsult.patientAddress = msg.sender;
        newConsult.doctorAddress = payable(_doctorAddress);
        newConsult.deadline = uint32(block.timestamp + _duration);
        newConsult.appointmentType = _appointmentType;

        consultations[_doctorAddress][msg.sender][consultId] = newConsult;
        // consultationList.push(newConsult);

        emit ConsultationBooked(msg.sender, _doctorAddress, consultId);
    }

   // grant access to doctor. 
    function grantAccessToDoctor(address _doctorAddress, uint256 _accessDuration) internal onlyRole(PATIENT_ROLE) {
        checkSelfPatientStatus();
        checkDoctorStatus(_doctorAddress);

        uint256 expirationTime = block.timestamp + _accessDuration;
        allowedDoctors[msg.sender][_doctorAddress] = DoctorAccess(true, expirationTime);
        
        emit DoctorAccessGranted(msg.sender, _doctorAddress, expirationTime);
    }

    // revoke access
    function revokeAccessFromDoctor(address _doctorAddress) external onlyRole(PATIENT_ROLE) {
        checkSelfPatientStatus();

        verifyDoctorAccess(msg.sender, _doctorAddress);
        
        allowedDoctors[msg.sender][_doctorAddress].hasAccess = false;
        allowedDoctors[msg.sender][_doctorAddress].accessExpiration = block.timestamp;

        emit DoctorAccessRevoked(msg.sender, _doctorAddress);
    }

      function grantAccessToHospital(address _hospitalAddress, uint256 _accessDuration) internal onlyRole(PATIENT_ROLE) {
        checkSelfPatientStatus();
        checkHospitalStatus(_hospitalAddress);

        uint256 expirationTime = block.timestamp + _accessDuration;
        allowedHospitals[msg.sender][_hospitalAddress] = HospitalAccess(true, expirationTime);
        
        emit HospitalAccessGranted(msg.sender, _hospitalAddress, expirationTime);
    }

    // revoke access
    function revokeAccessFromHospital(address _hospitalAddress) internal onlyRole(PATIENT_ROLE) {
        checkSelfPatientStatus();

        verifyHospitalAccess(msg.sender, _hospitalAddress);
        
        allowedHospitals[msg.sender][_hospitalAddress].hasAccess = false;
        allowedHospitals[msg.sender][_hospitalAddress].accessExpiration = block.timestamp;

        emit HospitalAccessRevoked(msg.sender, _hospitalAddress);
    }

    function startConsultation(address _doctorAddress, uint256 _consultationId) external onlyRole(PATIENT_ROLE) {
        checkSelfPatientStatus();
        checkDoctorStatus(_doctorAddress);
        verifyDoctorAccess(msg.sender, _doctorAddress);

        Consultation storage con = consultations[_doctorAddress][msg.sender][_consultationId];
        checkConsultationValidity(con.isAccepted, con.deadline);

        (bool success,) = address(this).call{value: con.price}("");
        require(success, PaymentFailed());

        emit ConsultationStarted(msg.sender, _doctorAddress, _consultationId);
    }

      // confirm for payment
    function confirmConsultationFulfillment(address _doctorAddress, uint256 _consultationId) external {
        // Perform sanity check
        checkSelfPatientStatus();
        checkDoctorStatus(_doctorAddress);

        Consultation storage con = consultations[_doctorAddress][msg.sender][_consultationId];
        require(con.isAccepted, ConsultationRejected());
        require(con.isCompleted, ConsultationOngoing());
        con.isFulfilled = true;

        emit ConsultationFulfilled(msg.sender, _doctorAddress, _consultationId);
    }

    function scheduleExamination(address _hospitalAddress, uint256 _price, address _patientAddress, uint32 _date, string memory _name) external {
        // Perform sanity check
        checkSelfPatientStatus();
        checkHospitalStatus(_hospitalAddress);

        Patient storage pat = patients[msg.sender];
        uint256 examId = pat.examinationCount++;

        Examination memory newExam;

        newExam.id = examId;
        newExam.name = _name;
        newExam.price = _price;
        newExam.patientAddress = _patientAddress;
        newExam.hospitalAddress = payable(_hospitalAddress);
        newExam.deadline = _date;

        examinations[msg.sender].push(newExam);
       
        emit ExamBooked(msg.sender);
    }

    function payForExamination(uint256 _examId) external {
        checkSelfPatientStatus();

        Examination storage exam = examinations[msg.sender][_examId];
        uint256 price = exam.price;

        (bool success,) = payable(exam.hospitalAddress).call{value: price}("");
        require(success, PaymentFailed());

        emit ExamSettled(msg.sender, exam.hospitalAddress, price);
    }

    function admitToHospital(address _hospitalAddress) external onlyRole(DOCTOR_ROLE) {
        checkSelfPatientStatus();
        checkHospitalStatus(_hospitalAddress);

        admittedPatients[_hospitalAddress][msg.sender] = true;

        emit PatientAdmitted(msg.sender, _hospitalAddress);
    }

     function respondToAccessRequest(address _providerAddress, bool _action, uint256 _duration) external {
        // Perform sanity check
        checkSelfPatientStatus();

        if (hasRole(DOCTOR_ROLE, _providerAddress)) checkDoctorStatus(_providerAddress);
        if (hasRole(HOSPITAL_ROLE, _providerAddress)) checkHospitalStatus(_providerAddress);

        AccessRequest storage request = accessRequests[msg.sender][_providerAddress];
        require(request.timestamp != 0, RequestInvalid());
        require(!request.approved, RequestAlreadyApproved());

        if (_action) {
            // Grant access and add the hospital to the patient's list of approved hospitals
            request.approved = true;
            grantAccessToHospital(_providerAddress, _duration);

            emit RecordAccessGranted(msg.sender, _providerAddress);
        } 
        else {
            // Deny the request
            delete accessRequests[msg.sender][_providerAddress];
            revokeAccessFromHospital(_providerAddress);

            emit RecordAccessDenied(msg.sender, _providerAddress);
        }
    }
}