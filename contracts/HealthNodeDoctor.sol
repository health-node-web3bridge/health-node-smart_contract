// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DoctorNode is AccessControl {
    struct Doctor {
        string firstName;
        string lastName;
        string email;
        string city;
        string country;
        string hospital;
        string specialty;
        bool isRegistered;
        bool isVerified;
        bool isActive;
        string licenseHash;
    }

    mapping(address => Doctor) private doctors;
    mapping(address => uint256) private doctorIndex; // Track the index of each doctor
    Doctor[] public doctorList;

    event DoctorRegistered(
        string indexed _firstName,
        string indexed _lastName,
        string indexed _email,
        string _city,
        string _country,
        string _hospital,
        string _specialty
    );

    event DoctorVerified(address indexed _doctorAddress, string _licenseHash);

    constructor() {}

    function registerDoctor(
        string memory _firstName,
        string memory _lastName,
        string memory _email,
        string memory _city,
        string memory _country,
        string memory _hospital,
        string memory _specialty
    ) public {
        require(!doctors[msg.sender].isRegistered, "Doctor already registered");
        require(msg.sender != address(0), "Invalid address");

        Doctor memory newDoctor = Doctor({
            firstName: _firstName,
            lastName: _lastName,
            email: _email,
            city: _city,
            country: _country,
            hospital: _hospital,
            specialty: _specialty,
            isRegistered: true,
            isVerified: false,
            isActive: true,
            licenseHash: ""
        });

        doctors[msg.sender] = newDoctor;
        doctorList.push(newDoctor);
        doctorIndex[msg.sender] = doctorList.length - 1; // Store the index

        emit DoctorRegistered(
            _firstName,
            _lastName,
            _email,
            _city,
            _country,
            _hospital,
            _specialty
        );
    }

    function verifyDoctor(string memory _licenseHash) public {
        require(msg.sender != address(0), "Invalid address");
        require(doctors[msg.sender].isRegistered, "Doctor is not registered");
        require(!doctors[msg.sender].isVerified, "Doctor is already verified");

        uint256 index = doctorIndex[msg.sender];

        doctors[msg.sender].isVerified = true;
        doctors[msg.sender].licenseHash = _licenseHash;
        doctorList[index].licenseHash = _licenseHash;
        doctorList[index].isVerified = !doctors[msg.sender].isVerified;

        emit DoctorVerified(msg.sender, _licenseHash);
    }

    function activateDoctor(address _doctorAddress) public {
        require(msg.sender != address(0), "Invalid address");
        require(doctors[msg.sender].isVerified, "Doctor is not verified");
        require(!doctors[msg.sender].isActive, "Doctor is already active");

        uint256 index = doctorIndex[_doctorAddress];

        doctors[msg.sender].isActive = true;
        doctorList[index].isActive = !doctors[_doctorAddress].isActive;
    }

    function getDoctors() public view returns (Doctor[] memory) {
        return doctorList;
    }

    function getDoctor(
        address _doctorAddress
    ) public view returns (Doctor memory) {
        return doctors[_doctorAddress];
    }
}
