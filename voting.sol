// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0<0.9.0;

contract Vote {
    address electionComision;
    address public winner;

    struct Voter {
        string name;
        uint age;
        uint voterId;
        string gender;
        bool voted;
        address voterAddress;
    }

    struct Candidate {
        string name;
        string party;
        uint age;
        string gender;
        uint candidateId;
        address candidateAddress;
        uint votes;
    }

    uint nextVoterId = 1; // Voter ID for voters
    uint nextCandidateId = 1; // Candidate ID for candidates

    uint startTime; // Start time of election
    uint endTime; // End time of election

//mapping from voter id to=> voter details
    mapping(uint => Voter) voterDetails; // Details of voters

//mapping from candidate id to=> candidate details
    mapping(uint => Candidate) candidateDetails; // Details of candidates
    bool stopVoting; // This is for emergency situation to stop voting

    constructor() {
            electionComision = msg.sender; // Assigning the deployer of contract as election commission
        }

        modifier votingNotOver() {
            require(block.timestamp < endTime || stopVoting == false, "Voting is over");
            _;
        }

        modifier onlyCommisioner() {
            require(electionComision == msg.sender, "Not from election commission");
            _;
        }

        function candidateRegister(
            string calldata _name,
            string calldata _party,
            uint _age,
            string calldata _gender
        ) external {
//election commission people can not register as voter
            require(msg.sender!=electionComision, "You are from election commision");
//candidate verification. so, that any candidate can not register twice
            require(candidateVerification(msg.sender),"Candidate Alrady Registered");
//age verification
            require(_age>18, "You are not eligible");
//will not take more than two candidate
            require(nextCandidateId<3, "Candidate Slot Full");

            candidateDetails[nextCandidateId]=Candidate(_name,_party,_age,_gender,nextCandidateId,msg.sender,0);
            nextCandidateId++;
        }

//one person can not register 2 times
        function candidateVerification(address _person) internal view returns (bool) {
            for(uint i=1; i<nextCandidateId; i++){
                if(candidateDetails[i].candidateAddress==_person){
                    return false;
                }
            }
            return true;
        }

//to get array of mapping
        function candidateList() public view returns (Candidate[] memory) {
            Candidate[] memory array =new Candidate[](nextCandidateId-1);
            for(uint i=1; i<nextCandidateId; i++){
                array[i-1]= candidateDetails[i];
            }
            return array;
        }

        function voterRegister(string calldata _name, uint _age, string calldata _gender) external {
            require(voterVerification(msg.sender),"Voter Already Registered");
            require(_age>18,"Voter not elligible");

            voterDetails[nextVoterId]= Voter(_name, _age, nextVoterId, _gender, false, msg.sender);
            nextVoterId++;
        }

        function voterVerification(address _person) internal view returns (bool) {
            for(uint i=1; i<nextVoterId; i++){
                if(voterDetails[i].voterAddress== _person){
                    return false;
                }
            }
            return true;
        }

        function voterList() public view returns (Voter[] memory) {
            Voter[] memory array = new Voter[](nextVoterId-1);
            for(uint i=1; i<nextVoterId; i++){
                array[i-1]= voterDetails[i];
            }
            return array;
        }

//function for voting
        function vote(uint _voterId, uint _candidateId) external{
        //checking if the voter has already voted or not
            require(voterDetails[_voterId].voted==false,"You have already voted");
        //someone may try to vote on behalf others using their voter id
            require(voterDetails[_voterId].voterAddress==msg.sender,"You can not vote on behalf of others");
        //checking if voting started or not
            require(startTime!=0,"Voting has not started yet");
        //checking if 2 candidates registered or not
            require(nextCandidateId>=2,"Candidates not registered yet");

            voterDetails[_voterId].voted = true;
            candidateDetails[_candidateId].votes++;
        }

//these are controlling functions of the whole voting system.
//all these are controlled by election commision. All of them holds "onlyCommisioner" modifier

//setting the voting start and end time
        function voteTime(uint _startTime, uint _endTime) external onlyCommisioner() {
            startTime = block.timestamp+_startTime;
            endTime = startTime+_endTime;
        }

//checking the voting status
        function votingStatus() public view returns (string memory) {
            if(startTime==0){
                return "Voting not started yet";
            }else if((startTime!=0 && endTime>block.timestamp)&& stopVoting==false){
                return "Voting in Progress";
            }else{
                return "Voting Ended";
            }
        }

//chesking the voting result
        function result() external onlyCommisioner() {
            require(nextCandidateId>1,"No candidate registered");
            uint maxVotes=0;
            address currentWinner;
            for(uint i=1; i<nextCandidateId; i++){
                if(candidateDetails[i].votes>maxVotes){
                    maxVotes=candidateDetails[i].votes;
                    currentWinner = candidateDetails[i].candidateAddress;
                }
            }
            winner= currentWinner;
        }

        function emergency() public onlyCommisioner() {
            stopVoting = true;
        }
}