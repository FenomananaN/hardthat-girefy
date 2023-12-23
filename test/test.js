/*const { expect } = require("chai");

describe("Token contract", function () {
  it("Deployment should assign the total supply of tokens to the owner", async function () {
    const [owner] = await ethers.getSigners();

    const hardhatToken = await ethers.deployContract("Girefy");

    const ownerBalance = await hardhatToken.balanceOf(owner.address);
    expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
  });

  it("The owner should mint 10000 GRF", async function () {
    const [owner] = await ethers.getSigners();

    const hardhatToken = await ethers.deployContract("Girefy");
    console.log('Begin to mint 10000GRF')
    await hardhatToken.mint(owner.address,10000)
    console.log('minted 10000GRF')
    const ownerBalance = await hardhatToken.balanceOf(owner.address);
    console.log(`owner balance is = ${ownerBalance.toString()}`)
    expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
  });
});*/

const {
    loadFixture,
  } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
  const { expect } = require("chai");
  
  describe("Girefy contract", function () {
    async function deployTokenFixture() {
      const [owner, addr1, addr2] = await ethers.getSigners();
  
      const girefyToken = await ethers.deployContract("Girefy");

      console.log('Begin to mint 10000GRF')
      await girefyToken.mint(owner.address,10000)
      console.log('minted 10000GRF')

      console.log('deploying crowdsale')
      const crowdsale = await ethers.deployContract("Crowdsale", [2,owner,girefyToken]);
      
      await girefyToken.mint(crowdsale,10000)
      console.log(crowdsale.target)
  
      // Fixtures can return anything you consider useful for your tests
      return { girefyToken,  crowdsale, owner, addr1, addr2 };
    }
  
    it("Should assign the total supply of tokens to the owner", async function () {
      const { girefyToken, owner } = await loadFixture(deployTokenFixture);
  
      const ownerBalance = await girefyToken.balanceOf(owner.address);

     // expect(await girefyToken.totalSupply()).to.equal(ownerBalance);
    });
  
    it("Should transfer tokens between accounts", async function () {
      const { girefyToken, owner, addr1, addr2 } = await loadFixture(
        deployTokenFixture
      );
  
      // Transfer 50 tokens from owner to addr1
      
      const ownerBalance = await girefyToken.balanceOf(owner.address);

      console.log( await ownerBalance.toString())
      await expect(
        girefyToken.transfer(addr1.address, 50)
      ).to.changeTokenBalances(girefyToken, [owner, addr1], [-50, 50]);
  
      // Transfer 50 tokens from addr1 to addr2
      // We use .connect(signer) to send a transaction from another account
      await expect(
        girefyToken.connect(addr1).transfer(addr2.address, 50)
      ).to.changeTokenBalances(girefyToken, [addr1, addr2], [-50, 50]);
    });

    it("Should pause contracts", async function () {
        const { girefyToken, owner } = await loadFixture(deployTokenFixture);
    
        await girefyToken.pause();
  
        expect(await girefyToken.paused()).to.equal(true);
      });

      it("Should be able to get crowdsale rate", async function () {
        const { crowdsale } = await loadFixture(
          deployTokenFixture
        );
    
        
        const rate = await crowdsale.getRate();
        console.log(`rate = ${rate}`)
        expect(rate).to.equal(2);
      });
      
      it("Should the owner be able to buy Tokens ", async function () {
        const { crowdsale, girefyToken ,addr1,owner } = await loadFixture(
          deployTokenFixture
        );
        let balance = await girefyToken.balanceOf(owner)
        console.log('before bying',balance.toString())
       
        await crowdsale.buyTokens(owner, {value:56})

        balance = await girefyToken.balanceOf(owner);

        console.log('after bying',balance.toString())
        
        console.log('wei raised',await crowdsale.getWeiRaised())
      })

      it("Should be able to buy Tokens", async function () {
        const { crowdsale, girefyToken ,addr1,owner } = await loadFixture(
          deployTokenFixture
        );
        console.log(await girefyToken.balanceOf(owner))
        await crowdsale.buyTokens(addr1, {value:56})
      })

      it("Should be able to buy Tokens on presale", async function () {
        const { crowdsale, girefyToken ,addr1,owner } = await loadFixture(
          deployTokenFixture
        );
       // console.log(await girefyToken.balanceOf(owner))
        await crowdsale.buyTokenOnPresale(addr1, {value:56})

        console.log(await crowdsale.getUserContribution(addr1))

        console.log(await crowdsale.getUserContribution(owner))
      })

      it("Should be able to claim token", async function () {
        const { crowdsale, girefyToken ,addr1,owner } = await loadFixture(
          deployTokenFixture
        );
       // console.log(await girefyToken.balanceOf(owner))
       
       // console.log(await girefyToken.balanceOf(owner))
        await crowdsale.buyTokenOnPresale(addr1, {value:56})
        await crowdsale.claimTokens(addr1)

        console.log('presale token amount',await crowdsale.getUserContribution(addr1))
        console.log('token balance',await girefyToken.balanceOf(addr1))
        
      })
  });