// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";

interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Airbnb {

    address payable owner;
    address payable renter;
    uint256[] public validTokens;
    // uint256 public costPerNight = 1 ether;
    IdaoContract daoContract;


    using Counters for Counters.Counter;
    Counters.Counter private _PropertyIds;
    Counters.Counter private _StayIds;
    
    struct Stay {
        address customer;
        uint256 pricePaid;
        uint256 id;
        uint256 guests;
        uint256 lengthOfStay;
        bool active;
    }

    struct Property {
        uint256 propertyId;
        uint256 pricePerNight;
        uint256 allowedNumberOfGuests;
        bool available;
    }

    mapping(uint256 => Stay) public stayById;
    mapping(uint256 => Property) public propertyById;

    receive() external payable {}

    constructor() {
        owner = payable(msg.sender);
        validTokens = [100340120341164170221631022200023838234959650663591914751809794374919304249444];
        daoContract = IdaoContract(0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function checkRentEligibility(address _customer) public view returns(bool) {
        for(uint i=0; i < validTokens.length; i++) {
            if(daoContract.balanceOf(_customer, validTokens[i]) >= 1) {
                return true;
            }
        }
        return false;
    }

    function createProperty(uint256 _guests, uint256 amount) public onlyOwner {
        _PropertyIds.increment();
        uint propertyId = _PropertyIds.current();
        Property storage property = propertyById[propertyId];
        property.propertyId = propertyId;
        property.pricePerNight = amount;
        property.allowedNumberOfGuests = _guests;
        property.available = true;

    }

    function requestStay(uint256 _guests, uint256 duration, uint256 _propertyId) public payable {
        require(checkRentEligibility(msg.sender), "Purchase nft to gain access to this property.");
        renter = payable(msg.sender);
        Property storage property = propertyById[_propertyId];
        require(property.pricePerNight <= msg.value, "Please deposit more.");
        require(property.allowedNumberOfGuests >= _guests, "Too many guests.");
        require(property.available == true, "This unit is unavailable.");
        _StayIds.increment();
        uint stayId = _StayIds.current();
        Stay storage stay = stayById[stayId];
        stay.customer = renter;
        stay.pricePaid = property.pricePerNight * duration;
        stay.guests = _guests;
        stay.lengthOfStay = duration;

        owner.transfer(stay.pricePaid);

        stay.active = true;
        property.available = false;

    }

    function endStay(uint256 _stayId, uint256 _propertyId) public {
        Stay storage stay = stayById[_stayId];
        Property storage property = propertyById[_propertyId]; 
        require(msg.sender == stay.customer);
        stay.active = false;
        property.available = true;
    }

    function priceCalculator(uint propertyId, uint numberOfDays) public view returns (uint) {
        Property memory property = propertyById[propertyId];
        return property.pricePerNight * numberOfDays;
    }
}
