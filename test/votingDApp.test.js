const VotingDApp = artifacts.require('VotingDApp')

const {expectRevert,time} = require('@openzeppelin/test-helpers');


contract('VotingDApp',(accounts)=>{
    let votingDApp;
    let currentTimestamp = Date.now();

    // simulated wallet addresses
    const [admin,voter1,voter2] = accounts;

    // deploying the VotingDApp contract before each test
    beforeEach(async()=>{
        votingDApp = await VotingDApp.new({from:admin})
    })

    it("Should set the admin correctly",async()=>{
        const contractAdmin = await votingDApp.admin();

        assert.equal(contractAdmin,admin,"Admin address mismatch");
    });

    it("Should allow admin to create candidates",async()=>{
        await votingDApp.createCandidate("1","John Doe","profile imageurl",{from:admin})

        const candidate = await votingDApp.getCandidateDetails("1")

        assert.equal(candidate.name,"John Doe","Candidate name mismatch");

        assert.equal(candidate.image,"profile imageurl","Candidate image mismatch");

        assert.equal(candidate.voteCount,0,"Initial vote should be zero")
    });

    it("Should prevent non-admins from creating candidate",async()=>{
        // used to verify that a specific action or transaction fails (reverts with a given error message)
        await expectRevert(votingDApp.createCandidate("2","Jane Doe","Profile imageUrl",{from:voter1}),"Admin previlages required")
    });

    it("Should allow voters to cast votes",async()=>{

        
        await votingDApp.createCandidate("1","John Doe","profile imageurl",{from:admin});
          
        // setting the voting to be one hour
        await votingDApp.setVotingPeriod(currentTimestamp,currentTimestamp + 3600000)

        await votingDApp.vote(voter1,"1",{from:voter1});

        const voter = await votingDApp.voters(voter1);

        assert.equal(voter.hasVoted,true,"Voter should be marked as voted");

        assert.equal(voter.votedFor,"1","Voter's voted candidate mismatch");

        const candidate = await votingDApp.getCandidateDetails("1")

        assert.equal(candidate.voteCount,1,"Candidate vote should increase")
    });

    it("Should prevent voters from voting twice",async()=>{
        await votingDApp.createCandidate("1","John Doe","profile imageurl",{from:admin});

        // setting the voting to be one hour
        await votingDApp.setVotingPeriod(currentTimestamp,currentTimestamp + 3600000)

        await votingDApp.vote(voter1,"1",{from:voter1});

        await expectRevert(
            votingDApp.vote(voter1,"1",{from:voter1}),
            "You have already voted"
        )
    });

    it("Should compute the correct winner",async()=>{
         await votingDApp.createCandidate("1","John Doe","profile imageurl",{from:admin});

         await votingDApp.createCandidate("2","Jane Doe","profile imageurl",{from:admin});

         // setting the voting to be one hour
        await votingDApp.setVotingPeriod(currentTimestamp,currentTimestamp + 3600000)

          votingDApp.vote(voter1,"1",{from:voter1})

          votingDApp.vote(voter2,"2",{from:voter2})

          const winner = await votingDApp.computerWinner();

          assert.equal(winner.length,2,"There should be a tie");

          assert.equal(winner[0].id,"1","Winner 1 ID mismatch");

          assert.equal(winner[1].id,"2","Winner 2 ID mismatch");
    });

    it("Should prevent voting beyond the set period",async()=>{
         await votingDApp.createCandidate("1","John Doe","profile imageurl",{from:admin});

         const startTime = (await time.latest()).add(time.duration.hours(1));

         const endTime = startTime.add(time.duration.hours(2));

         await votingDApp.setVotingPeriod(startTime,endTime)

         
         await time.increase(time.duration.hours(5));

         await expectRevert(votingDApp.vote(voter1,"1",{from:voter1}),"Voting is not open");
         
    })

})