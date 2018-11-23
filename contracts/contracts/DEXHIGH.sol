pragma solidity ^0.4.24;

contract SafeMath {
  function Mul(uint a, uint b) pure public returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function Sub(uint a, uint b) pure public returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function Add(uint a, uint b) pure public returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract Token {
  /// @return total amount of tokens
  function totalSupply() constant public returns (uint256 supply) {}

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) constant public returns (uint256 balance) {}

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) public returns (bool success) {}

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) returns (bool success) {}

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

contract DEXHIGH2 is SafeMath
{
    event Deposit(uint32 indexed prCode, address indexed owner, uint amount);
    event Withdraw(uint32 indexed prCode, address indexed owner, uint amount);

    event NewOrder(uint32 indexed prTrade, uint32 indexed prBase, address indexed owner, uint32 id, bool isSell, uint price, uint amount, uint64 timestamp);
    event NewAsk(uint32 indexed prTrade, uint32 indexed prBase, uint price);
    event NewBid(uint32 indexed prTrade, uint32 indexed prBase, uint price);
    event NewTrade(uint32 prTrade, uint32 prBase, uint32 indexed bidId, uint32 indexed askId, bool isSell, uint price, uint amount, uint64 timestamp);

    function DEXHIGH2() public
    {
        owner = msg.sender;
        AddOwner();
        productId = 1; // productId == 1 -> ETH 0x0
    }

    address owner;
    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    uint32 public ownerId;
    uint256 public newOwnerFee;
    mapping (uint32 => address) id_owner;
    mapping (address => uint32) owner_id;

    function AddOwner() public payable
    {
        require(msg.value >= newOwnerFee);
        require(owner_id[msg.sender] == 0);

        owner_id[msg.sender] = ++ownerId;
        id_owner[ownerId] = msg.sender;
    }

    function SetOwnerFee(uint256 ownerFee) onlyOwner public
    {
        newOwnerFee = ownerFee;
    }

    function GetOnwerList() view public returns (address[] owners, uint32[] ownerIds)
    {
        owners = new address[](ownerId);
        ownerIds = new uint32[](ownerId);

        for (uint32 i = 1; i <= ownerId; i++)
        {
            owners[i - 1] = id_owner[i];
            ownerIds[i - 1] = i;
        }
    }

    uint32 public productId;
    uint256 public newProductFee;
    mapping (uint32 => address) prCode_product;
    mapping (address => uint32) product_prCode;
    mapping (uint32 => uint32) prCode_ownerId;

    function AddProduct(address product) payable public
    {
        require(msg.value >= newProductFee);
        require(product_prCode[product] == 0);
        uint32 ownerId = owner_id[msg.sender];
        require(ownerId != 0);

        product_prCode[product] = ++productId;
        prCode_product[productId] = product;
        prCode_ownerId[productId] = ownerId;
    }
    function SetProductFee(uint productFee) onlyOwner public
    {
        newProductFee = productFee;
    }
    function GetProductList() constant public returns (address[] products, uint32[] productIds)
    {
        products = new address[](productId);
        productIds = new uint32[](productId);

        for (uint32 i = 1; i <= productId; i++)
        {
            products[i - 1] = prCode_product[i];
            productIds[i - 1] = i;
        }
    }

    uint32 public acccountId;
    mapping (uint32 => address) id_account;
    mapping (address => uint32) account_id;
    function FindOrAddAccount() private returns (uint32)
    {
        if (account_id[msg.sender] == 0)
        {
            account_id[msg.sender] = ++acccountId;
            id_account[acccountId] = msg.sender;
        }
        return account_id[msg.sender];
    }
    function GetAccountList() constant public returns (address[] owners, uint32[] Ids)
    {
        owners = new address[](acccountId);
        Ids = new uint32[](acccountId);

        for (uint32 i = 1; i <= acccountId; i++)
        {
            owners[i - 1] = id_account[i];
            Ids[i - 1] = i;
        }
    }


    struct ListItem
    {
        uint32 prev;
        uint32 next;
    }

    struct OrderLink
    {
        uint32 orderN;
        uint32 firstId;
        uint32 lastId;
        uint256 nextPrice;
        uint256 prevPrice;
        mapping (uint32 => ListItem) id_orderList;
    }

    struct OrderBook
    {
        uint256 bestBidPrice;
        uint256 bestAskPrice;

        mapping (uint32 => OrderLink) bidPrice_Order;
        mapping (uint32 => OrderLink) askPrice_Order;
    }
    mapping (uint32 => mapping (uint32 => OrderBook)) basePID_tradePID_orderBook;

    struct Balance
    {
        uint reserved;
        uint available;
    }

    struct Order
    {
        uint32 accountID;
        address token;
        uint256 qty;
        uint64 price;
        bool sell;
        uint64 timestamp;
    }

    mapping (uint32 => mapping (uint32 => Balance)) prCode_AccountId_Balance;

    function depositETH() payable public
    {
        uint32 accountId = FindOrAddAccount();

        Balance storage balance = prCode_AccountId_Balance[0][accountId];
        balance.available = SafeMath.Add(balance.available, msg.value);
        Deposit(0, msg.sender, msg.value);
    }

    function withdrawETH(uint amount) public
    {
        uint32 accountId = account_id[msg.sender];
        if (accountId != 0)
        {
            Balance storage balance = prCode_AccountId_Balance[0][accountId];
            balance.available = SafeMath.Sub(balance.available, amount);
            require(msg.sender.call.value(amount)());
            Withdraw(0, msg.sender, amount);
        }
    }

    function depositERC20(address token, uint amount) public
    {
        uint32 prCode = product_prCode[token];
        require(prCode != 0);

        uint32 accountId = FindOrAddAccount();

        require(Token(token).transferFrom(msg.sender, this, amount));

        Balance storage balance = prCode_AccountId_Balance[prCode][accountId];
        balance.available = SafeMath.Add(balance.available, amount);
        Deposit(prCode, msg.sender, amount);
    }

    function withdrawERC20(address token, uint amount) public
    {
        uint32 prCode = product_prCode[token];
        require(prCode != 0);

        uint32 accountId = account_id[msg.sender];

        if (accountId != 0)
        {
            Balance storage balance = prCode_AccountId_Balance[prCode][accountId];
            balance.available = SafeMath.Sub(balance.available, amount);
            require(Token(token).transfer(msg.sender, amount));
            Withdraw(prCode, msg.sender, amount);
        }
    }

    function GetDownTick(uint price) public returns (uint)
    {
        uint tick = 10000;

        uint priceTenPercent = price / 10;

        while (priceTenPercent > tick)
        {
            tick *= 10;
        }

        while (priceTenPercent < tick)
        {
            tick /= 10;
        }

        if (price >= 50 * tick)
        {
            tick *= 5;
        }

        return (price / tick) * tick;
    }

    function GetUpTick(uint price) public returns (uint)
    {
        uint tick = 10000;

        uint priceTenPercent = price / 10;

        while (priceTenPercent > tick)
        {
            tick *= 10;
        }

        while (priceTenPercent < tick)
        {
            tick /= 10;
        }

        if (price >= 50 * tick)
        {
            tick *= 5;
        }

        return (((price - 1) / tick) + 1) * tick;
    }
}
