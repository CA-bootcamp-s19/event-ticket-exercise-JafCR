pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;
    uint   PRICE_TICKET = 100 wei;

    constructor() public payable {
        owner = msg.sender;
    }

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping (uint => Event) public events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier isOwner(address _address) { require (owner == _address); _;}
    modifier isOpen(uint _eventID) { require (events[_eventID].isOpen); _; }
    modifier paidEnough(uint _numTicketsToBuy) { require(msg.value >= (PRICE_TICKET * _numTicketsToBuy )); _;}
    modifier enoughTickets(uint _eventID, uint _numTicketsToBuy) { require(_numTicketsToBuy <= events[_eventID].totalTickets); _; }
    modifier hasPurchasedTickets(uint _eventId) { require(events[_eventId].buyers[msg.sender] > 0); _; }

    modifier refund(uint _eventId, address payable _addr) {
        _;
        uint amountToRefund = PRICE_TICKET * events[_eventId].buyers[msg.sender];
        events[_eventId].buyers[msg.sender] = 0;
        _addr.transfer(amountToRefund);
    }

    modifier checkValue(uint _numTicketsToBuy, address payable _addr)  {
    //refund them after pay for item
        _;
        uint _price = PRICE_TICKET * _numTicketsToBuy;
        uint totalTicketsPrice = msg.value - _price;
        _addr.transfer(totalTicketsPrice);
        //revert();
    }


    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory _description, string memory _websiteURL, uint _tickets4Sale)
    public payable
    isOwner(msg.sender)
    returns (uint)
    {
        Event memory myEvent;
        myEvent.description = _description;
        myEvent.website = _websiteURL;
        myEvent.totalTickets = _tickets4Sale;
        myEvent.isOpen = true;
        events[idGenerator] = myEvent;
        idGenerator = idGenerator + 1;
        emit LogEventAdded(_description, _websiteURL, _tickets4Sale, idGenerator);
        return (idGenerator);
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint _eventID)
        public
        view
        returns(string memory description, string memory website, uint totalTickets, uint sales, bool isEventOpen)
    {
        description = events[_eventID].description;
        website = events[_eventID].website;
        totalTickets = events[_eventID].totalTickets;
        sales = events[_eventID].sales;
        isEventOpen = events[_eventID].isOpen;
        return (description, website, totalTickets, sales, isEventOpen);
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint _eventID, uint _numTicketsToBuy)
    public
    payable
    isOpen(_eventID)
    paidEnough(_numTicketsToBuy) //there is no price per event. Its a global ticket price
    enoughTickets(_eventID, _numTicketsToBuy)
    checkValue(_numTicketsToBuy, msg.sender)
    {
        events[_eventID].buyers[msg.sender] += _numTicketsToBuy;
        events[_eventID].totalTickets -= _numTicketsToBuy;
        events[_eventID].sales += _numTicketsToBuy;
        emit LogBuyTickets(msg.sender, _eventID, _numTicketsToBuy);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint _eventId)
    public
    payable
    hasPurchasedTickets(_eventId)
    refund(_eventId, msg.sender)
    {
        events[_eventId].totalTickets += events[_eventId].buyers[msg.sender];
        emit LogGetRefund(msg.sender, _eventId, events[_eventId].buyers[msg.sender]);
    }

    
    

    
    

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint eventId)
    public
    view
    returns(uint totalTickets)
    {
        return (events[eventId].buyers[msg.sender]);
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint _eventId)
    public
    payable
    isOwner(msg.sender)
    {
        uint eventBalance = events[_eventId].sales * PRICE_TICKET;
        events[_eventId].isOpen = false;
        owner.transfer(eventBalance);
        emit LogEndSale(owner, eventBalance, _eventId);
    }
}
