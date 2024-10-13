// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Heath-Node (Decentralized Health Services Dapp)
/// @notice This contract allows hospitals and clinics to register and 
/// @notice request access to patient records, with explicit patient permission.
/// @author em@rc99 

contract HealthNode {

    /// @dev Structure to store hospital/clinic information.
    struct Hospital {
        address hospitalAddress;
        string name;
        string registrationNumber;
        bool verified;
        bool registered;
    }

    // // Structure to store patient record permissions
    // struct Record {
    //     string recordHash; // Reference to the medical record stored on decentralized storage (IPFS/Arweave)
    //     bool exists; // Ensure record exists
    // }

    /// @dev Structure to store record access request details.
    struct AccessRequest {
        address hospitalAddress;
        uint256 timestamp;
        bool approved;
    }

    // Mappings to store hospitals and patient permissions.

    // Registered hospitals/clinics.
    mapping(address => Hospital) public hospitals; 
    // Patients with list of hospitals granted access.
    mapping(address => address[]) public patientPermissions; 
    // Access requests by hospitals to patients.
    mapping(address => mapping(address => AccessRequest)) public accessRequests; 

    // Events for logging important actions
    event HospitalRegistered(address indexed hospitalAddress, string name, string registrationNumber);
    event AccessRequested(address indexed hospitalAddress, address indexed patientAddress);
    event AccessGranted(address indexed patientAddress, address indexed hospitalAddress);
    event AccessDenied(address indexed patientAddress, address indexed hospitalAddress);

    // Modifier to check if a hospital is verified by submitting proof of healthcare license
    modifier onlyVerifiedHospital() {
        require(hospitals[msg.sender].verified, "Hospital is not verified or licensed");
        _;
    }

    // Modifier to check if a hospital/clinic is already registered
    modifier notRegistered() {
        require(!hospitals[msg.sender].registered, "Hospital is already registered");
        _;
    }

    /// @notice Allows hospitals or clinics to register with their details.
    /// @param _name The name of the hospital/clinic.
    /// @param _registrationNumber The registration number or license of the hospital/clinic.
    function registerHospital(string memory _name, string memory _registrationNumber) external notRegistered {
        require(bytes(_name).length > 0, "Hospital name is required");
        require(bytes(_registrationNumber).length > 0, "Registration number is required");

        hospitals[msg.sender] = Hospital({
            hospitalAddress: msg.sender,
            name: _name,
            registrationNumber: _registrationNumber,
            verified: true, // In a real system, the verification process would be more rigorous
            registered: true
        });

        emit HospitalRegistered(msg.sender, _name, _registrationNumber);
    }

    /// @notice A hospital/clinic can request access to a patient's records, but the patient must grant permission.
    /// @param _patientAddress The address of the patient whose records are being requested.
    function requestRecordAccess(address _patientAddress) external onlyVerifiedHospital {
        require(_patientAddress != address(0), "Invalid patient address");
        
        // Check if a request already exists
        AccessRequest storage existingRequest = accessRequests[_patientAddress][msg.sender];
        require(existingRequest.timestamp == 0, "Access request already made");

        // Create a new access request
        accessRequests[_patientAddress][msg.sender] = AccessRequest({
            hospitalAddress: msg.sender,
            timestamp: block.timestamp,
            approved: false
        });

        emit AccessRequested(msg.sender, _patientAddress);
    }

    /// @notice Patients can approve or deny access requests from hospitals or clinics.
    /// @param _hospitalAddress The address of the hospital requesting access.
    /// @param _grantAccess Boolean value: true to grant access, false to deny.
    function respondToAccessRequest(address _hospitalAddress, bool _grantAccess) external {
        require(hospitals[_hospitalAddress].registered, "Hospital is not registered");
        require(hospitals[_hospitalAddress].hospitalAddress != address(0), "Zero address not allowed!");
        
        AccessRequest storage request = accessRequests[msg.sender][_hospitalAddress];
        require(request.timestamp != 0, "No access request from this hospital");
        require(!request.approved, "Access already granted");

        if (_grantAccess) {
            // Grant access and add the hospital to the patient's list of approved hospitals
            request.approved = true;
            patientPermissions[msg.sender].push(_hospitalAddress);

            emit AccessGranted(msg.sender, _hospitalAddress);
        } 
        else {
            // Deny the request
            delete accessRequests[msg.sender][_hospitalAddress];

            emit AccessDenied(msg.sender, _hospitalAddress);
        }
    }

    /// @notice Hospitals/clinics can check if they have permission to access a patient's records.
    /// @param _patientAddress The address of the patient.
    /// @return True if access is granted, false otherwise.
    function checkAccessPermission(address _patientAddress) external view returns (bool) {
        require(_patientAddress != address(0), "Zero address not allowed!");
        AccessRequest storage request = accessRequests[_patientAddress][msg.sender];
        return request.approved;
    }
    
    /// @notice Returns the list of hospitals/clinics with access to the patient's records.
    /// @param _patientAddress The address of the patient.
    /// @return List of addresses of hospitals that have access to the patient's records.
    function getApprovedHospitals(address _patientAddress) external view returns (address[] memory) {
        require(_patientAddress != address(0), "Zero address not allowed!");
        return patientPermissions[_patientAddress];
    }
}
