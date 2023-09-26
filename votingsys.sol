pragma solidity ^0.4.0;

import "browser/IRegister.sol";

contract VotingContract {
    // State variables for election details
    bytes32 public ElectionWinner;
    bytes32 public ElectionQuestion;
    address public ElectionAdmin;
    uint public NumberOfCandidates;
    bool public isElectionCompleted;
    uint public totalVotes;
    address public votingSystem = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;
    address public registrationContractAddress = 0x0c762d861a8873c54ed938c68ea1d5f627b562aa;
    mapping(address => bool) public eligibility;
    mapping(bytes32 => uint) public candidateVotes;
    mapping(uint => bytes32) public candidateOptions;

    // Modifier to restrict access to only the owner (Election Admin)
    modifier onlyOwner {
        require(msg.sender == ElectionAdmin);
        _;
    }

    // Get the total number of votes in the election
    function getNumberOfVotes() public view returns(uint) {
        return totalVotes;
    }

    // Get the total number of candidates in the election
    function getNumberOfCandidates() public view returns(uint) {
        return NumberOfCandidates;
    }

    // Get the election question
    function getElectionQuestion() public view returns(bytes32) {
        return ElectionQuestion;
    }

    // Check if an address is eligible to vote
    function isVoterEligible(address _address) public view returns(bool) {
        Register reg = Register(registrationContractAddress);
        return reg.isEligible(_address);
    }

    // Constructor to initialize the election with a question and candidate names
    function VotingContract(bytes32 question, bytes32[] memory candidateNames) {
        ElectionQuestion = question;
        ElectionAdmin = msg.sender;
        NumberOfCandidates = candidateNames.length;
        for (uint i = 0; i < candidateNames.length; i++) {
            candidateOptions[i] = candidateNames[i];
            candidateVotes[candidateNames[i]] = 0;
        }
    }

    // Get the name of a candidate based on candidate index
    function getCandidate(uint candidateIndex) public view returns(bytes32) {
        if (candidateIndex > NumberOfCandidates - 1)
            return (0);
        else
            return (candidateOptions[candidateIndex]);
    }

    // Check if the caller is eligible to vote
    function canVote() public onlyOwner view returns(bool) {
        if (eligibility[msg.sender] == true || isElectionCompleted == true || !isVoterEligible(msg.sender))
            return false;
        else
            return true;
    }

    // Get the total votes received for a candidate
    function getTotalVotesFor(bytes32 candidate) public view returns(uint) {
        return candidateVotes[candidate];
    }

    // Vote for a candidate
    function vote(bytes32 candidate) public payable {
        require(canVote() && (msg.value > 0));
        candidateVotes[candidate] += 1;
        totalVotes += 1;
        eligibility[msg.sender] = true;
    }

    // Get the election's total funds
    function getElectionPot() public onlyOwner view returns(uint) {
        return address(this).balance;
    }

    // Finish the election and distribute funds to admin and voting system
    function finishAndDistributeElectionFunds(bytes32 winner) public onlyOwner returns(uint, uint) {
        ElectionAdmin.transfer(address(this).balance / 3);
        votingSystem.transfer(address(this).balance);
        ElectionWinner = winner;
        isElectionCompleted = true;
        return (address(ElectionAdmin).balance, address(votingSystem).balance);
    }
}
