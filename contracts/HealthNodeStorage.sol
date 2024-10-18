// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract HealthNodeStorage is AccessControl {

    address admin;

    // ACCESS CONTROL ROLES
    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;
    bytes32 public constant PATIENT_ROLE = keccak256("PATIENT_ROLE");
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");
    bytes32 public constant HOSPITAL_ROLE = keccak256("HOSPITAL_ROLE");

    // ENTITY COUNTERS
    uint256 public patientCounter;
    uint256 public doctorCounter;
    uint256 public hospitalCounter;

    // STRUCTS
    struct Patient {
        uint256 id;
        uint256 consultationCount;
        uint256 examinationCount;
        string name;
        string email;
        string gender;
        string[] ipfsRecordHashes;  // Hash to store medical records from IPFS
        uint8 age;
        bool isRegistered;
        bool isActive;
    }

    struct Doctor {
        uint256 id;
        uint256 hospitalId;
        uint256 rate;
        string name;
        string email;
        string gender;
        string specialty;
        string licenseHash;  // Hash to store medical license from IPFS
        bool isRegistered;
        bool isVerified;
        bool isAvailable;
        bool isActive;
    }

     struct Hospital {
        uint256 id;
        string name;
        string city;
        string country;
        bool isRegistered;
        bool isActive;
    }

    struct Consultation {
        uint256 id;
        uint256 price;
        address patientAddress;
        address payable doctorAddress;
        uint32 deadline;
        bool isAccepted;
        bool isCompleted;
        bool isFulfilled;
        ConsultationType appointmentType;
    }

    enum ConsultationType {
        Online,
        Onsite
    }
    // Online=0, Onsite=1

    struct Examination {
        uint256 id;
        uint256 price;
        address patientAddress;
        address payable hospitalAddress;
        uint32 deadline;
        string name;
    }

    struct DoctorAccess {
        bool hasAccess;
        uint256 accessExpiration;
    }

    struct HospitalAccess {
        bool hasAccess;
        uint256 accessExpiration;
    }

    struct AccessRequest {
        uint256 timestamp;
        address providerAddress;
        bool approved;
    }

    // ARRAYS
    Patient[] public patientList;
    Doctor[] public doctorList;
    Hospital[] public hospitalList;
    // Consultation[] public consultationList;

    // MAPPINGS
    mapping(address => Patient) public patients;
    mapping(address => Doctor) public doctors;
    mapping(address => Hospital) public hospitals;
    
    mapping(address patient => mapping(address doctor => DoctorAccess)) public allowedDoctors;
    mapping(address patient => mapping(address hospital => HospitalAccess)) public allowedHospitals;
    mapping(address hospital => mapping(address patient => bool)) public admittedPatients;
    mapping(address doctor => mapping(address patient => mapping(uint256 consultationId => Consultation))) public consultations;
    mapping(address patient => Examination[]) public examinations;
    mapping(address patient => mapping(address healthProvider => AccessRequest)) public accessRequests;

    // CUSTOM ERRORS
    error ConsultationExpired();
    error ConsultationRejected();
    error ConsultationUnfulfilled();
    error ConsultationOngoing();

    error DoctorAlreadyRegistered();
    error DoctorAlreadyVerified();
    error DoctorNotActive();
    error DoctorNotAuthorized();
    error DoctorNotRegistered();
    error DoctorNotVerified();
    error DoctorUnavailable();

    error HospitalAlreadyRegistered();
    error HospitalNotActive();
    error HospitalNotAuthorized();
    error HospitalNotRegistered();

    error PatientAlreadyRegistered();
    error PatientNotActive();
    error PatientNotRegistered();

    error RequestAlreadyExists();
    error RequestInvalid();
    error RequestAlreadyApproved();
    error RequestNotApproved();

    error InsufficientBalance();
    error PaymentFailed();
    error StringLengthZeroBytes();
    error UnauthorizedSender();
    error ZeroAddressDetected();

    // EVENTS
    event PatientRegistered(address indexed patient, string name);
    event PatientAdmitted(address indexed patient, address indexed hospital);
    event PatientDischarged(address indexed patient, address indexed hospital);

    event MedicalRecordSaved(address indexed patient);
    event MedicalRecordUpdated(address indexed patient, string consultationRecord);

    event DoctorRegistered(address indexed doctor, string indexed name);
    event DoctorVerified(address indexed doctor);
    event DoctorAccessGranted(address indexed patient, address indexed doctor, uint256 expirationTime);
    event DoctorAccessRevoked(address indexed patient, address indexed doctor);

    event HospitalRegistered(address indexed hospitalAddress, string name);
    event HospitalAccessGranted(address indexed patient, address indexed hospital, uint256 expirationTime);
    event HospitalAccessRevoked(address indexed patient, address indexed hospital);

    event ConsultationBooked(address indexed patient, address indexed doctor, uint256 consultationId);
    event ConsultationAccepted(address indexed doctor, address indexed patient, uint256 consultationId);
    event ConsultationStarted(address indexed patient, address indexed doctor, uint256 consultationId);
    event ConsultationEnded(address indexed doctor, address indexed patient, uint256 consultationId);
    event ConsultationFulfilled(address indexed patient, address indexed doctor, uint256 consultationId);
    event ConsultationResolved(address indexed patient, address indexed doctor, uint256 consultationId);

    event ExamBooked(address indexed patient);
    event ExamSettled(address indexed patient, address indexed hospital, uint256 indexed price);

    event RecordAccessRequested(address indexed hospital, address indexed patient);
    event RecordAccessGranted(address indexed hospital, address indexed patient);
    event RecordAccessDenied(address indexed hospital, address indexed patient);


    constructor() {
        _grantRole(ADMIN_ROLE, msg.sender);
        admin = msg.sender;
    }

    // INTERNAL HELPER FUNCTIONS

    function _onlyAdmin() internal view {
        require(msg.sender == admin, UnauthorizedSender());
    }

    function checkZeroAddress() internal view {
        require(msg.sender != address(0), ZeroAddressDetected());
    }

    function checkAddressZero(address _user) internal pure {
        require(_user != address(0), ZeroAddressDetected());
    }

    function checkSelfPatientStatus() internal view {
        checkZeroAddress();
        require(patients[msg.sender].isRegistered, PatientNotRegistered());
        require(patients[msg.sender].isActive, PatientNotActive());
    }

    function checkPatientStatus(address _patient) internal view {
        checkAddressZero(_patient);
        require(patients[_patient].isRegistered, PatientNotRegistered());
        require(patients[_patient].isActive, PatientNotActive());
    }

    function checkSelfDoctorStatus() internal view {
        checkZeroAddress();
        require(doctors[msg.sender].isRegistered, DoctorNotRegistered());
        require(doctors[msg.sender].isVerified, DoctorNotVerified());
        require(doctors[msg.sender].isActive, DoctorNotActive());
    }

    function checkDoctorStatus(address _doctor) internal view {
        checkAddressZero(_doctor);
        require(doctors[_doctor].isRegistered, DoctorNotRegistered());
        require(doctors[_doctor].isVerified, DoctorNotVerified());
        require(doctors[_doctor].isActive, DoctorNotActive());
    }

    function checkSelfHospitalStatus() internal view {
        checkZeroAddress();
        require(hospitals[msg.sender].isRegistered, HospitalNotRegistered());
        require(hospitals[msg.sender].isActive, HospitalNotActive());
    }

    function checkHospitalStatus(address _hospital) internal view {
        checkAddressZero(_hospital);
        require(hospitals[_hospital].isRegistered, HospitalNotRegistered());
        require(hospitals[_hospital].isActive, HospitalNotActive());
    }

    function verifyDoctorAccess(address _patientAddress, address _doctorAddress) internal view {
        require(
            allowedDoctors[_patientAddress][_doctorAddress].hasAccess &&
            allowedDoctors[_patientAddress][_doctorAddress].accessExpiration > block.timestamp
        , DoctorNotAuthorized());
    }

    function verifyHospitalAccess(address _patientAddress, address _hospitalAddress) internal view {
        require(
            allowedHospitals[_patientAddress][_hospitalAddress].hasAccess &&
            allowedHospitals[_patientAddress][_hospitalAddress].accessExpiration > block.timestamp
        , HospitalNotAuthorized());
    }

    function validateDoctor(address _doctorAddress) internal view {
        require(doctors[_doctorAddress].isVerified, DoctorNotVerified());
    }

    function checkDoctorAvailability(address _doctor) internal view {
        require(doctors[_doctor].isAvailable, DoctorUnavailable());
    }

    function checkConsultationValidity(bool isAccepted, uint32 deadline) internal view {
        require(isAccepted, ConsultationRejected());
        require(uint32(block.timestamp) < deadline, ConsultationExpired());
    }

    function checkStringLength(string memory _stringInput) internal pure {
        require(bytes(_stringInput).length > 0, StringLengthZeroBytes());
    }

    // EXTERNAL FUNCTIONS

    // function checkUserRole(address _user) external view returns (uint8) {
    //     if (hasRole(ADMIN_ROLE, _user)) return 1;
    //     if (hasRole(PATIENT_ROLE, _user)) return 2;
    //     if (hasRole(DOCTOR_ROLE, _user)) return 3;
    //     if (hasRole(HOSPITAL_ROLE, _user)) return 4;

    //     return 0;
    // }

    // function isAdmin(bytes32 _adminRole, address _user) external view returns (bool) {
    //     return hasRole(_adminRole, _user);
    // }

    // function isPatient(bytes32 _patientRole, address _user) external view returns (bool) {
    //     return hasRole(_patientRole, _user);
    // }

    // function isDoctor(bytes32 _doctorRole, address _user) external view returns (bool) {
    //     return hasRole(_doctorRole, _user);
    // }

    // function isHospital(bytes32 _hospitalRole, address _user) external view returns (bool) {
    //     return hasRole(_hospitalRole, _user);
    // }

    function withdraw(uint256 _amount) external{
        _onlyAdmin();
        require(address(this).balance > _amount, InsufficientBalance());

        (bool success,) = address(this).call{value: _amount}("");
        require(success, PaymentFailed());
    }

    // CUSTOM FUNCTION MODIFIERS

    modifier onlyHealthProviderRole() {
        require(
            hasRole(DOCTOR_ROLE, msg.sender) || 
            hasRole(HOSPITAL_ROLE, msg.sender),
            UnauthorizedSender()
        );
        _;
    }

    // FALLBACK FUNCTION
    receive() external payable {}
}