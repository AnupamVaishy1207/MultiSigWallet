//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    /*Event are fired when if is deposit is needed when eth is deposit into this multi-sig wallet*/
    event Deposit(address indexed sender, uint256 amount);
    /*Emit the submit event when transaction is submitted waiting for other owners to approve*/
    event Submit(uint256 indexed txId);
    /*Other owners will be able to approve the transaction */
    event Approve(address indexed owner, uint256 indexed txId);
    /*Once the transtion is approved maybe they've changed there mind so they might want to revoke the transaction*/
    event Revoke(address indexed owner, uint256 indexed txId);
    /*Once's there's sufficient amount of approvals then contract can be executed*/
    event Execute(uint256 indexed txId);
    /*Struct that's gonna store the transaction */
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    address[] public owners; //store the address of number of owners.
    mapping(address => bool) public isOwner; //if address of a owner of multi-sig wallet then it will return true otherwise false.
    uint256 public required; //This will be the number of approvals required before a transaction can be executed.

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public approved;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner"); //Check address of submitted requiest is owner or not
        _; //if msg.sender is the owner of the contract then go ahead and allow execution of the rest of the function.
    }

    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    modifier notApproved(uint256 _txId) {
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "tx already approved");
        _;
    }

    /*For the input of the constructor we'll put in two parameters addresses of owners and the required (line 24) */
    constructor(address[] memory _owners, uint256 _required) {
        require(owners.length > 0, "owners required");
        require(
            _required > 0 && _required <= _owners.length,
            "Invalid required number of owners"
        );
        /*Run for loop to save the owners to the state variable*/
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner); //push the owner into the state variable
        }
        required = _required;
    }

    /*With this function we are enable to recieve ether*/
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /*Only the owners will be able to submit a transaction once a transaction is submitted any if the owner will be able to execute transction*/
    function submit(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner {
        transactions.push(
            Transaction({to: _to, value: _value, data: _data, executed: false})
        );
        emit Submit(transactions.length - 1); //Parametre of these event is txId is a index where transaction is stored.
    }

    /*Once the transaction is submitted other owners will be able to approve the transaction */
    function approve(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    /*Before the owner can execute a transaction they'll need to make sure that the number of approved is greater than required*/
    function _getApprovalCount(uint256 _txId)
        private
        view
        returns (uint256 count)
    {
        for (uint256 i; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

    /*Function will execute the transaction*/
    function execute(uint256 _txId)
        external
        txExists(_txId)
        notExecuted(_txId)
    {
        require(_getApprovalCount(_txId) >= required, "approcals < required");
        Transaction storage transaction = transactions[_txId]; // we'll need to get the data stored in transaction struct
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");
        emit Execute(_txId);
    }

    /* Lets say the owner approves a transaction and before the transaction is executed he changes his mind and he want to now undo the approval*/
    function revoke(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(approved[_txId][msg.sender], "tx not approved");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}
