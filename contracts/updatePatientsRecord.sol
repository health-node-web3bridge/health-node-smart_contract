// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

contract MedicalRecord{

struct Patient{
string name;
uint age;
string[] conditions;
string[] allergies;
string[] medication;


mapping (address => Patient)public patients;

function addPateint(
    string memory _name,
    uint _age,
string[] memory _conditions,
string[] memory _allergies,
string[] memory _medications , 
)public {

    Patient memory patient = Patient(_name,_age,_conditions,_allergies,_medications,)
    Patients[msg.sender] = patient;

}

function updatePatient(
string[] memory _conditions,
string[] memory _allergies,
string[] memory _medications , 
) public {
Patient memory patient = patients[msg.sender];
Patient.conditions = _conditions;
Patient.allergies = _allergies;
Patient.medication = _medications;

}

function getPatient(address _patientAddress) public view returns (
    string memory,
    uint,
    string[] memory,
    string[] memory,
    string[] memory
) {
    Patient memory patient = patients[_patientAddress];
    return (patient.name, patient.age, patient.conditions, patient.allergies, patient.medication);
}
}
}