pragma solidity ^0.5.0;

    /*
        The EventTickets contract keeps track of the details and ticket sales of one event.
     */

contract EventTickets {

    /*
        Create a public state variable called owner.
        Use the appropriate keyword to create an associated getter function.
        Use the appropriate keyword to allow ether transfers.
     */
    address payable public owner;

    uint   TICKET_PRICE = 100 wei;

    /*
        Create a struct called "Event".
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        bool isOpen;
        mapping (address => uint) buyers;
    }

    Event myEvent;

    /*
        Define 3 logging events.
        LogBuyTickets should provide information about the purchaser and the number of tickets purchased.
        LogGetRefund should provide information about the refund requester and the number of tickets refunded.
        LogEndSale should provide infromation about the contract owner and the balance transferred to them.
    */
    event LogBuyTickets(address addr, uint numTickets);
    event LogGetRefund(address addr, uint numTicketsRefunded);
    event LogEndSale(address addr, uint balanceTransferred);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier isOwner(address _address) { require (owner == _address); _;}
    modifier isOpen() { require (myEvent.isOpen == true); _; }

    modifier paidEnough(uint _numTicketsToBuy) { require(msg.value >= (TICKET_PRICE * _numTicketsToBuy )); _;}

    modifier enoughTickets(uint _numTicketsToBuy) { require(_numTicketsToBuy <= myEvent.totalTickets); _; }

    modifier checkValue(uint _numTicketsToBuy, address payable _addr)  {
    //refund them after pay for item
        _;
        uint _price = TICKET_PRICE * _numTicketsToBuy;
        uint amountToRefund = msg.value - _price;
        _addr.transfer(amountToRefund);
    }

    modifier refund(uint _numTicketsToRefund, address payable _addr) {
        _;
        uint amountToRefund = TICKET_PRICE * myEvent.buyers[_addr];
        _addr.transfer(amountToRefund);
    }

    modifier hasPurchasedTickets() { require(myEvent.buyers[msg.sender] > 0); _; }

    modifier withdrawBalance() {
        _;
        owner.transfer(address(this).balance);
    }

    /*
        Define a constructor.
        The constructor takes 3 arguments, the description, the URL and the number of tickets for sale.
        Set the owner to the creator of the contract.
        Set the appropriate myEvent details.
    */
    constructor(string memory _description, string memory _websiteURL, uint _tickets4Sale) public payable {
       owner = msg.sender;
       myEvent.isOpen = true;
       myEvent.description = _description;
       myEvent.website = _websiteURL;
       myEvent.totalTickets = _tickets4Sale;
       myEvent.sales = 0;
    }

    /*
        Define a function called readEvent() that returns the event details.
        This function does not modify state, add the appropriate keyword.
        The returned details should be called description, website, uint totalTickets, uint sales, bool isOpen in that order.
    */
    function readEvent()
        public
        view
        returns(string memory description, string memory website, uint totalTickets, uint sales, bool isEventOpen)
    {
        description = myEvent.description;
        website = myEvent.website;
        totalTickets = myEvent.totalTickets;
        sales = myEvent.sales;
        isEventOpen = myEvent.isOpen;
        return (description, website, totalTickets, sales, isEventOpen);
    }

    /*
        Define a function called getBuyerTicketCount().
        This function takes 1 argument, an address and
        returns the number of tickets that address has purchased.
    */
    function getBuyerTicketCount(address _addr)
    public
    returns(uint ticketsPurchased)
    {
        return (myEvent.buyers[_addr]);
    }


    /*
        Define a function called buyTickets().
        This function allows someone to purchase tickets for the event.
        This function takes one argument, the number of tickets to be purchased.
        This function can accept Ether.
        Be sure to check:
            - That the event isOpen
            - That the transaction value is sufficient for the number of tickets purchased
            - That there are enough tickets in stock
        Then:
            - add the appropriate number of tickets to the purchasers count
            - account for the purchase in the remaining number of available tickets
            - refund any surplus value sent with the transaction
            - emit the appropriate event
    */
    function buyTickets(uint _numTicketsToBuy)
    public
    payable
    isOpen()
    paidEnough(_numTicketsToBuy)
    enoughTickets(_numTicketsToBuy)
    checkValue(_numTicketsToBuy, msg.sender)
    {
        myEvent.buyers[msg.sender] += _numTicketsToBuy;
        myEvent.totalTickets -= _numTicketsToBuy;
        myEvent.sales += _numTicketsToBuy;
        emit LogBuyTickets(msg.sender, _numTicketsToBuy);
    }



    /*
        Define a function called getRefund().
        This function allows someone to get a refund for tickets for the account they purchased from.
        TODO:
            - Check that the requester has purchased tickets.
            - Make sure the refunded tickets go back into the pool of avialable tickets.
            - Transfer the appropriate amount to the refund requester.
            - Emit the appropriate event.
    */
    function getRefund(uint _numTicketsToRefund)
    public
    payable
    hasPurchasedTickets()
    refund(_numTicketsToRefund, msg.sender)
    {
        myEvent.totalTickets += _numTicketsToRefund;
        emit LogGetRefund(msg.sender, _numTicketsToRefund);
    }

    /*
        Define a function called endSale().
        This function will close the ticket sales.
        This function can only be called by the contract owner.
        TODO:
            - close the event
            - transfer the contract balance to the owner
            - emit the appropriate event
    */
    function endSale()
    public
    payable
    isOwner(msg.sender)
    //withdrawBalance()
    {
        myEvent.isOpen = false;
        uint eventBalance = myEvent.sales * TICKET_PRICE;
        owner.transfer(eventBalance);
        emit LogEndSale(msg.sender, eventBalance);
        myEvent.sales = 0;
    }


    function() external payable {
    }
}
