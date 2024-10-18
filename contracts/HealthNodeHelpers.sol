// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./HealthNodeStorage.sol";

contract HealthNodeHelpers is HealthNodeStorage {

    // address admin;

    // ACCESS CONTROL ROLES
    // bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;
    // bytes32 public constant PATIENT_ROLE = keccak256("PATIENT_ROLE");
    // bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");
    // bytes32 public constant HOSPITAL_ROLE = keccak256("HOSPITAL_ROLE");

    HealthNodeStorage public immutable storageContract;

    constructor(address _storageAddress) {
        storageContract = HealthNodeStorage(payable(_storageAddress));
    }

    function checkUserRole(address _user) external view returns (uint8) {
        if (hasRole(ADMIN_ROLE, _user)) return 1;
        if (hasRole(PATIENT_ROLE, _user)) return 2;
        if (hasRole(DOCTOR_ROLE, _user)) return 3;
        if (hasRole(HOSPITAL_ROLE, _user)) return 4;

        return 0;
    }

    function isAdmin(bytes32 _adminRole, address _user) external view returns (bool) {
        return hasRole(_adminRole, _user);
    }

    function isPatient(bytes32 _patientRole, address _user) external view returns (bool) {
        return hasRole(_patientRole, _user);
    }

    function isDoctor(bytes32 _doctorRole, address _user) external view returns (bool) {
        return hasRole(_doctorRole, _user);
    }

    function isHospital(bytes32 _hospitalRole, address _user) external view returns (bool) {
        return hasRole(_hospitalRole, _user);
    }
}