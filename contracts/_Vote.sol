// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

contract VotingDApp {
    address public admin;

    // candidate
    struct Candidate {
        string id;
        string name;
        string image;
        uint voteCount;
    }

    // storing candidate id
    string[] public candidateIDs;

    // voter
    struct Voter {
        bool hasVoted;
        string votedFor;
    }

    // total vote cast
    uint public totalVotes;
    // time restrictions
    uint public voting_start_time;
    uint public voting_end_time;

    // mapping from voter address to Voter struct
    mapping(address => Voter) public voters;

    // store all candidates
    // Candidate[] public candidates;
    mapping(string => Candidate) public candidates;

    // event when a candidate is added
    event CandidateAdded(string id, string name, string image);

    // when event is casted
    event VoteCast(address voter, string candidateID);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin previlages required");
        _;
    }

    modifier votingActive() {
        require(
            block.timestamp >= voting_start_time &&
                block.timestamp <= voting_end_time,
            "Voting is not open"
        );
        _;
    }

    modifier votingClosed() {
        require(block.timestamp > voting_end_time, "Voting is still open");
        _;
    }

    function setVotingPeriod(uint startTime, uint endTime) external onlyAdmin {
        require(startTime < endTime, "Start time must be before end time");
        require(block.timestamp < endTime, "End time must be in the future");

        voting_end_time = startTime;
        voting_end_time = endTime;
    }

    function createCandidate(
        string memory id,
        string memory name,
        string memory image
    ) external onlyAdmin {
        require(
            bytes(candidates[id].id).length == 0,
            "Candidate ID already exists."
        );

        candidates[id] = (
            Candidate({id: id, name: name, image: image, voteCount: 0})
        );

        candidateIDs.push(id);

        emit CandidateAdded(id, name, image);
    }

    function vote(
        address voterID,
        string memory candidateID
    ) external votingActive {
        // ensuring voter hasn't voted
        require(!voters[voterID].hasVoted, "You have already voted");
        // checking if the user existed
        require(
            bytes(candidates[candidateID].id).length != 0,
            "Candidate ID does not exist."
        );

        voters[voterID].hasVoted = true;
        voters[voterID].votedFor = candidateID;

        candidates[candidateID].voteCount += 1;
        totalVotes += 1;

        emit VoteCast(voterID, candidateID);
    }

    function getAllCandidates() external view returns (Candidate[] memory) {
        uint candidateCount = candidateIDs.length;

        Candidate[] memory allCandidates = new Candidate[](candidateCount);

        for (uint i = 0; i < candidateCount; i++) {
            string memory candidateId = candidateIDs[i];

            Candidate memory candidate = candidates[candidateId];

            allCandidates[i] = candidate;
        }

        return allCandidates;
    }

    function Tallying()
        external
        view
        votingClosed
        returns (Candidate[] memory)
    {
        uint candidateCount = candidateIDs.length;

        Candidate[] memory allCandidates = new Candidate[](candidateCount);

        for (uint i = 0; i < candidateCount; i++) {
            string memory candidateId = candidateIDs[i];

            Candidate memory candidate = candidates[candidateId];

            allCandidates[i] = candidate;
        }

        return allCandidates;
    }

    function computerWinner() external view returns (Candidate[] memory) {
        uint maxVotes = 0;
        uint winnerCount = 0;
        Candidate[] memory tempWinners = new Candidate[](candidateIDs.length);

        for (uint i = 0; i < candidateIDs.length; i++) {
            string memory candidateID = candidateIDs[i];

            require(
                bytes(candidates[candidateID].id).length != 0,
                "Candidate ID does not exist"
            );

            uint currentCandidateVotes = candidates[candidateID].voteCount;

            if (currentCandidateVotes > maxVotes) {
                maxVotes = currentCandidateVotes;
                winnerCount = 0; //reset winner count
                tempWinners[winnerCount] = candidates[candidateID];

                winnerCount++;
            } else if (currentCandidateVotes == maxVotes) {
                tempWinners[winnerCount] = candidates[candidateID];
                winnerCount++;
            }
        }

        Candidate[] memory winners = new Candidate[](winnerCount);

        for (uint i = 0; i < winnerCount; i++) {
            winners[i] = tempWinners[i];
        }

        return winners;
    }

    function getCandidateDetails(
        string memory candidateID
    ) external view returns (Candidate memory) {
        require(
            bytes(candidates[candidateID].id).length != 0,
            "Candidate doesnt exist"
        );

        Candidate memory candidate = candidates[candidateID];

        return candidate;
    }
}
