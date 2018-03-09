pragma solidity ^0.4.20;

import "./SimpleAuctionInterface.sol";

contract SimpleAuction is AuctionInterface {
    struct Lot {
        string name;
        uint timestamp;
        address owner;
        uint lastBid;
        address winner;
        uint buyItNowPrice;
        uint minBid;
        bool created;
        bool isEnded;
        bool isProcessed;
        bool isDeleted;
    }
    
    mapping (uint => Lot) internal lots;
    
    mapping (address => uint) internal uprate;
    mapping (address => uint) internal downrate;

    uint lotNonce = 0;

    /**
     * @notice  Creates a lot.
     * @param   _name The lot name.
     * @param   _price Amount (in Wei) needed to buy the lot immediately
     * @param   _minBid Amount (in Wei) needed to place a bid.
     */
    function createLot(string _name, uint _price, uint _minBid) public {
        lotNonce++;

        lots[lotNonce] = Lot(
            _name,
            block.timestamp,
            msg.sender,
            0,
            msg.sender,
            _price,
            _minBid,
            true,
            false,
            false,
            false
        );
    }
    
    function getLastLotId() public constant returns(uint){
        return lotNonce;
    }

    /**
     * @notice  Creates a lot.
     * @param   _name The lot name.
     * @param   _price Amount (in Wei) needed to buy the lot immediately
     * @param   _minBid Amount (in Wei) needed to place a bid.
     */
    function createLot(
        string _name,
        uint128 _price,
        uint128 _minBid
    ) external returns (uint) {
        createLot(_name, _price, _minBid);

        return getLastLotId();
    }
    
    /**
     * @notice  Removes lot, which has no bids.
     * @param   _lotID Integer identifier associated with target lot
     */
    function removeLot(uint _lotID) public {
        require(exists(_lotID));
        //require(!isEnded(_lotID));
        //require(!isProcessed(_lotID));
        require(lots[_lotID].lastBid == 0);
        
        delete lots[_lotID];
    }
    
    /**
     * @notice  Returns main information about lot.
     * @param   _lotID Integer identifier associated with target lot
     */
    function getLot(uint _lotID) public constant returns (
        string name,
        uint lastBid,
        uint buyItNowPrice,
        uint minBid
    ) {
        require(exists(_lotID));
        require(!isEnded(_lotID));
        
        return (
            lots[_lotID].name,
            lots[_lotID].lastBid,
            lots[_lotID].buyItNowPrice,
            lots[_lotID].minBid
        );
    }

    /**
     * @notice  Places a bid. Contract should return the wei value to previous
     *          bidder
     * @param  _lotID Integer identifier associated with target lot
     */
    function bid(uint _lotID) public payable {
        //require(_lotID <= lotNonce);
        //require(_lotID > 0);
        require(exists(_lotID));
        require(!isEnded(_lotID));
        
        require(lots[_lotID].minBid < msg.value);
        require(lots[_lotID].lastBid < msg.value);

        lots[_lotID].winner.transfer(lots[_lotID].lastBid);
            
        lots[_lotID].winner = msg.sender;
        lots[_lotID].lastBid = msg.value;
        
        if (lots[_lotID].lastBid >= lots[_lotID].buyItNowPrice) {
            _finishLot(_lotID);
        }
    }


    /**
     * @notice  Resolves the lot status if it's time is passed. Anyone should
     *          call the function when the lot ends to explicitly mark the lot
     *          as completed and transfer bid amount to the lot owner.
     * @param   _lotID Integer identifier associated with target lot
     */
    function processLot(uint _lotID) public {
        require(lots[_lotID].owner == msg.sender);
         
        _processLot(_lotID);
    }
    
    function _processLot(uint _lotID) internal {
        lots[_lotID].owner.transfer(lots[_lotID].lastBid);
        _finishLot(_lotID);
        lots[_lotID].isProcessed = true;
    }
    
    function _finishLot(uint _lotID) internal {
        lots[_lotID].isEnded = true;
    }

    /**
     * @notice  Shows the last bid owner (bidder) address.
     * @param   _lotID Integer identifier associated with target lot
     * @return  Bidder address
     */
    function getBidder(uint _lotID) public constant returns (address) {
        return lots[_lotID].winner;
    }

    /**
     * @notice  Determines if lot is ended.
     * @param   _lotID Integer identifier associated with target lot
     * @return  Boolean indication of whether the lot is ended.
     */
    function isEnded(uint _lotID) public constant returns (bool) {
        return lots[_lotID].isEnded;
    }

    /**
     * @notice  Determines if lot is processed.
     * @param   _lotID _lotID Integer identifier associated with target lot
     * @return  Boolean indication of whether the lot is processed.
     */
    function isProcessed(uint _lotID) public constant returns (bool) {
        return lots[_lotID].isProcessed;
    }

    /**
     * @notice  Determines if lot exists.
     * @param   _lotID Integer identifier associated with target lot
     * @return  Boolean indication of whether the lot exists.
     */
    function exists(uint _lotID) public constant returns (bool) {
        return lots[_lotID].created && !lots[_lotID].isDeleted;
    }

    // =======
    // Rating:
    // =======

    /**
     * @notice  Uprate or downrate the lot owner. Can be called by the lot buyer. 
     * @param   _lotID Integer identifier associated with target lot
     * @param   _option Boolean value which indicates the option (false - downrate, true - uprate)
     */
    function rate(uint _lotID, bool _option) public {
        require(exists(_lotID));
        require(isEnded(_lotID));
        require(getBidder(_lotID) == msg.sender);
        
        if (_option) {
            
        } else {
            downrate[lots[_lotID].owner]++;
        }
    }

    /**
     * @notice  Shows the rating for the provided user address.
     * @param   _owner User address.
     * @return  Amount of rating.
     */
    function getRating(address _owner) public constant returns (uint) {
        require(uprate[_owner] > 0);
        
        return (100 * uprate[_owner]) / (uprate[_owner] + downrate[_owner]);
    }
}