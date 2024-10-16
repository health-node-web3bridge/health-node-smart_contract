// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract HealthNodeHelpers is AccessControl {

    // address admin;

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
        string name;
        string email;
        string gender;
        uint256 hospital; //
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

    struct Consultation  {
        address patientAddress;
        address doctorAddress;
        ConsultationType appointmentType;
        uint32 deadline;
        bool isAccepted;
        bool isFulfilled;
    }
    Consultation[] public consultations;

    enum ConsultationType {
        Online,
        Onsite
    }

    struct DoctorAccess {
        bool hasAccess;
        uint256 accessExpiration;
    }

    struct HospitalAccess {
        bool hasAccess;
        uint256 accessExpiration;
    }

    // Available Doctor Info
    struct AvailableDoctor {
        address doctorAddress;
        bool offersService;
    }

    // ARRAYS
    Patient[] public patientList;
    Doctor[] public doctorList;
    Hospital[] public hospitalList;

    // MAPPINGSÍ
    mapping(address => Patient) public patients;
    mapping(address => Doctor) public doctors;
    mapping(address => Hospital) public hospitals;
    
    mapping(address patient => mapping(address doctor => DoctorAccess)) allowedDoctors;
    mapping(address patient => mapping(address hospital => HospitalAccess)) allowedHospitals;

    mapping(address => mapping(address => DoctorAccess)) private doctorAccess;

    // mapping(address patient => mapping(address doctor => mapping(Consultation => string recordHash))) private consultationRecords;

    // CUSTOM ERRORS
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
    error StringLengthZeroBytes();
    error PatientAlreadyRegistered();
    error PatientNotActive();
    error PatientNotRegistered();
    error UnauthorizedSender();
    error ZeroAddressDetected();

    // EVENTS
    event PatientRegistered(address indexed patient, string name);
    event MedicalRecordSaved(address indexed patient);
    event MedicalRecordUpdated(address indexed patient, string consultationRecord);
    event DoctorRegistered(address indexed doctor, string indexed name);
    event DoctorVerified(address indexed doctor);
    event HospitalRegistered(address indexed hospitalAddress, string name, string registrationNumber);
    
    event DoctorAccessGranted(address indexed patient, address indexed doctor, uint256 expirationTime);
    event DoctorAccessRevoked(address indexed patient, address indexed doctor);
    event ServiceSelected(address indexed patient, address indexed doctor, bool offersService);

    event AccessRequested(address indexed hospitalAddress, address indexed patientAddress);
    event AccessGranted(address indexed patientAddress, address indexed hospitalAddress);
    event AccessDenied(address indexed patientAddress, address indexed hospitalAddress);


    constructor() {
        // admin = msg.sender;
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    // HELPER FUNCTIONS
    // function onlyAdmin () internal view {
    //     require(msg.sender == admin, UnauthorizedSender()); // hasRole
    // }

    function checkZeroAddress() internal view {
        require(msg.sender != address(0), ZeroAddressDetected());
    }

    function checkAddressZero(address _user) internal pure {
        require(_user != address(0), ZeroAddressDetected());
    }

    function checkSelfPatientStatus() internal view {
        require(msg.sender != address(0), ZeroAddressDetected());
        require(patients[msg.sender].isRegistered, PatientNotRegistered());
        require(patients[msg.sender].isActive, PatientNotActive());
    }

    function checkPatientStatus(address _patient) internal view {
        require(_patient != address(0), ZeroAddressDetected());
        require(patients[_patient].isRegistered, PatientNotRegistered());
        require(patients[_patient].isActive, PatientNotActive());
    }

    function checkSelfDoctorStatus() internal view {
        require(msg.sender != address(0), ZeroAddressDetected());
        require(doctors[msg.sender].isRegistered, DoctorNotRegistered());
        require(doctors[msg.sender].isVerified, DoctorNotVerified());
        require(doctors[msg.sender].isActive, DoctorNotActive());
    }

    function checkDoctorStatus(address _doctor) internal view {
        require(_doctor != address(0), ZeroAddressDetected());
        require(doctors[_doctor].isRegistered, DoctorNotRegistered());
        require(doctors[_doctor].isVerified, DoctorNotVerified());
        require(doctors[_doctor].isActive, DoctorNotActive());
    }

    function checkDoctorAvailability(address _doctor) external view {
        require(doctors[_doctor].isAvailable, DoctorUnavailable());
    }

    function validateDoctor(address _doctorAddress) internal view {
        require(doctors[_doctorAddress].isVerified, DoctorNotVerified());
    }

    function checkSelfHospitalStatus() internal view {
        require(msg.sender != address(0), ZeroAddressDetected());
        require(hospitals[msg.sender].isRegistered, HospitalNotRegistered());
        require(hospitals[msg.sender].isActive, HospitalNotActive());
    }

    function checkHospitalStatus(address _hospital) internal view {
        require(_hospital != address(0), ZeroAddressDetected());
        require(hospitals[_hospital].isRegistered, HospitalNotRegistered());
        require(hospitals[_hospital].isActive, HospitalNotActive());
    }

    function checkStringLength(string memory _stringInput) internal pure {
        require(bytes(_stringInput).length > 0, StringLengthZeroBytes());
    }

    function checkUserRole(address _user) public view returns (bool) {
        return hasRole(PATIENT_ROLE, _user) || 
            hasRole(DOCTOR_ROLE, _user) || 
            hasRole(HOSPITAL_ROLE, _user);
    }

    modifier onlyHealthProviderRole() {
        require(
            hasRole(DOCTOR_ROLE, msg.sender) || 
            hasRole(HOSPITAL_ROLE, msg.sender),
            UnauthorizedSender()
        );
        _;
    }

    function isDoctorAuthorized(address _patientAddress, address _doctorAddress) internal view returns (bool) {
        return (
            allowedDoctors[_patientAddress][_doctorAddress].hasAccess &&
            allowedDoctors[_patientAddress][_doctorAddress].accessExpiration > block.timestamp
        );
    }
    function isHospitalAuthorized(address _patientAddress, address _hospitalAddress) internal view returns (bool) {
        return (
            allowedHospitals[_patientAddress][_hospitalAddress].hasAccess &&
            allowedHospitals[_patientAddress][_hospitalAddress].accessExpiration > block.timestamp
        );
    }

    function verifyDoctorAccess(address _patientAddress, address _doctorAddress) internal view {
        require(isDoctorAuthorized(_patientAddress, _doctorAddress), DoctorNotAuthorized());
    }

    function verifyHospitalAccess(address _patientAddress, address _hospitalAddress) internal view {
        require(isHospitalAuthorized(_patientAddress, _hospitalAddress), HospitalNotAuthorized());
    }
}