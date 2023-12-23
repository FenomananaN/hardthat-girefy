// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Crowdsale {



    // The token being sold
    ERC20 private token;

    // Address where funds are collected
    address payable private wallet;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private rate;

    // Amount of wei raised
    uint256 private weiRaised;


    //presale contributor
    mapping (address => uint256) public contributions;

    //Crowdsale Stages
    enum CrowdsaleStage {PreIco, Ico}

    //default presale
    CrowdsaleStage public stage = CrowdsaleStage.PreIco;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    
    /**
     * Event for ctoken claim logging
     * @param purchaser who claim for the tokens
     * @param beneficiary who got the tokens
     * @param amount amount of tokens claimed
     */
    event TokensClaimed(address indexed purchaser, address indexed beneficiary, uint256 amount);

    /**
     * @param _rate Number of token units a buyer gets per wei
     * @dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param _wallet Address where collected funds will be forwarded to
     * @param _token Address of the token being sold
     */
    constructor (uint256 _rate, address payable _wallet, ERC20 _token) {
        require(_rate > 0, "Crowdsale: rate is 0");
        require(_wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(_token) != address(0), "Crowdsale: token is the zero address");

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
   /* receive() external payable {
        buyTokens(msg.sender);
    }*/

    /**
     * @return the token being sold.
     */
    function getToken() public view returns (ERC20) {
        return token;
    }

    /**
     * @return the address where funds are collected.
     */
    function getWallet() public view returns (address payable) {
        return wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function getRate() public view returns (uint256) {
        return rate;
    }

    function setRate(uint256 _rate) public {
        rate=_rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function getWeiRaised() public view returns (uint256) {
        return weiRaised;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public payable {
        uint256 weiAmount = msg.value;


        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        weiRaised +=weiAmount;

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased( msg.sender, beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        //token.allowance(wallet,beneficiary);
        token.approve(address(this),tokenAmount);
        token.transfer(beneficiary, tokenAmount);
        //token.transferFrom(wallet,beneficiary,tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount*rate;
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////Presale//////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Returns the amount the contributor buy token on presale
     * @param _beneficiary address of presale buyers 
     * @return User Contribution on presale
     */
    function getUserContribution(address _beneficiary) public view returns (uint256){
        return contributions[_beneficiary];
    }

    /**
     * @dev Buy token on presale
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokenOnPresale(address beneficiary) public payable {
        uint256 weiAmount = msg.value;


        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        weiRaised +=weiAmount;

        //
        contributions[beneficiary]= tokens;

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

    //////////////////////////////////////////////////////////////////////////////
    //////////////////////CLAIM///////////////////////////////////////////
    //////////////////////////////////////////////////////////////
    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function claimTokens(address beneficiary) public {


        // get token to be claimed
        uint256 tokens = contributions[beneficiary];
        _processPurchase(beneficiary, tokens);
        emit TokensClaimed( msg.sender, beneficiary, tokens);
        contributions[beneficiary]= 0;
        //_forwardFunds();
    }

}