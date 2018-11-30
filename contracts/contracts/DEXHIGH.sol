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
    event NewTrade(uint32 prTrade, uint32 prBase, uint32 indexed bidId, uint32 indexed askId, bool isSell, uint price, uint amount);//, uint64 timestamp);

    uint256 public constant  basePrice = 10000000000;

    constructor() public
    {
        owner = msg.sender;
        AddOwner();
        lastProductId = 1; // productId == 1 -> ETH 0x0
        SetOwnerFee(10000000000000000000);
    }

    address owner;
    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    uint32 public lastOwnerId;
    uint256 public newOwnerFee;
    mapping (uint32 => address) id_owner;
    mapping (address => uint32) owner_id;

    function AddOwnerByOwner(address newOwner) onlyOwner public
    {
        require(owner_id[newOwner] == 0);

        owner_id[newOwner] = ++lastOwnerId;
        id_owner[lastOwnerId] = newOwner;
    }
    function AddOwner() public payable
    {
        require(msg.value >= newOwnerFee);
        require(owner_id[msg.sender] == 0);

        owner_id[msg.sender] = ++lastOwnerId;
        id_owner[lastOwnerId] = msg.sender;

        ownerId_accountId[lastOwnerId] = FindOrAddAccount();
    }
    function SetOwnerFee(uint256 ownerFee) onlyOwner public
    {
        newOwnerFee = ownerFee;
    }
    function GetOnwerList() constant public returns (address[] owners, uint32[] ownerIds)
    {
        owners = new address[](lastOwnerId);
        ownerIds = new uint32[](lastOwnerId);

        for (uint32 i = 1; i <= lastOwnerId; i++)
        {
            owners[i - 1] = id_owner[i];
            ownerIds[i - 1] = i;
        }
    }
    function setMakerFeeRateLocal(uint256 _makerFeeRate) public
    {
        require (_makerFeeRate <= 100);
        uint32 ownerId = owner_id[msg.sender];
        require(ownerId != 0);
        ownerId_makerFeeRateLocal[ownerId] = _makerFeeRate;//bp
    }
    function setTakerFeeRateLocal(uint256 _takerFeeRate) public
    {
        require (_takerFeeRate <= 100);
        uint32 ownerId = owner_id[msg.sender];
        require(ownerId != 0);
        ownerId_takerFeeRateLocal[ownerId] = _takerFeeRate;//bp
    }


    struct ProductInfo
    {
        uint256 divider;
        string name;
        string symbol;
        bool isAccepted;
    }

    uint32 public lastProductId;
    uint256 public newProductFee;
    mapping (uint32 => address) prCode_product;
    mapping (address => uint32) product_prCode;
    mapping (uint32 => ProductInfo) prCode_productInfo;
    mapping (uint32 => uint32) prCode_ownerId;
    function AddProduct(address product, string name, uint256 decimals) payable public
    {
        require(msg.value >= newProductFee);
        require(product_prCode[product] == 0);
        require(decimals <= 30);

        uint32 ownerId = owner_id[msg.sender];
        require(ownerId != 0);

        product_prCode[product] = ++lastProductId;
        prCode_product[lastProductId] = product;
        prCode_ownerId[lastProductId] = ownerId;

        ProductInfo memory productInfo;
        productInfo.name = name;
        productInfo.divider = 10 ** decimals;
        prCode_productInfo[lastProductId] = productInfo;
    }
    function SetProductFee(uint productFee) onlyOwner public
    {
        newProductFee = productFee;
    }
    function GetProductList() constant public returns (address[] products, uint32[] productIds)
    {
        products = new address[](lastProductId);
        productIds = new uint32[](lastProductId);

        for (uint32 i = 1; i <= lastProductId; i++)
        {
            products[i - 1] = prCode_product[i];
            productIds[i - 1] = i;
        }
    }
    function GetProductInfo(address product) view public returns (uint32 prCode, uint256 divider, string name, string symbol, bool isAccepted)
    {
        prCode = product_prCode[product];
        require(prCode != 0);

        divider = prCode_productInfo[prCode].divider;
        name = prCode_productInfo[prCode].name;
        symbol = prCode_productInfo[prCode].symbol;
        isAccepted = prCode_productInfo[prCode].isAccepted;
    }
    function AcceptProduct(uint32 prCode, bool isAccept) onlyOwner public
    {
        if (prCode_ownerId[prCode] != 0)
        {
            prCode_productInfo[prCode].isAccepted = isAccept;
        }
    }

    uint32 public lastAcccountId;
    mapping (uint32 => address) id_account;
    mapping (address => uint32) account_id;
    mapping (uint256 => uint256) ownerId_makerFeeRateLocal;
    mapping (uint256 => uint256) ownerId_takerFeeRateLocal;
    mapping (uint256 => uint32) ownerId_accountId;

    function FindOrAddAccount() private returns (uint32)
    {
        if (account_id[msg.sender] == 0)
        {
            account_id[msg.sender] = ++lastAcccountId;
            id_account[lastAcccountId] = msg.sender;
        }
        return account_id[msg.sender];
    }
    function GetAccountList() constant public returns (address[] owners, uint32[] Ids)
    {
        owners = new address[](lastAcccountId);
        Ids = new uint32[](lastAcccountId);

        for (uint32 i = 1; i <= lastAcccountId; i++)
        {
            owners[i - 1] = id_account[i];
            Ids[i - 1] = i;
        }
    }

    struct Balance
    {
        uint reserved;
        uint available;
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

    struct Order
    {
        uint32 ownerId;
        uint32 accountId;
        uint32 prTrade;
        uint32 prBase;
        uint256 qty;
        uint256 price;
        bool isSell;
        uint64 timestamp;
    }

    uint32 lastOrderId;
    mapping (uint32 => Order) id_Order;

    struct OrderBook
    {
        uint256 bestBidPrice;
        uint256 bestAskPrice;

        mapping (uint256 => OrderLink) bidPrice_Order;
        mapping (uint256 => OrderLink) askPrice_Order;
    }
    mapping (uint32 => mapping (uint32 => OrderBook)) basePID_tradePID_orderBook;

    mapping (uint32 => mapping (uint32 => Balance)) prCode_AccountId_Balance;

    //trading fee
    uint256 makerFeeRateMain;
    uint256 takerFeeRateMain;
    function setMakerFeeRateMain(uint256 _makerFeeRateMain) onlyOwner public
    {
        require (_makerFeeRateMain <= 100);
        makerFeeRateMain = _makerFeeRateMain;//bp
    }
    function setTakerFeeRateMain(uint256 _takerFeeRateMain) onlyOwner public
    {
        require (_takerFeeRateMain <= 100);
        takerFeeRateMain = _takerFeeRateMain;//bp
    }

    function depositETH() payable public
    {
        uint32 accountId = FindOrAddAccount();

        Balance storage balance = prCode_AccountId_Balance[0][accountId];
        balance.available = SafeMath.Add(balance.available, msg.value);
        emit Deposit(0, msg.sender, msg.value);
    }

    function withdrawETH(uint256 amount) public
    {
        uint32 accountId = account_id[msg.sender];
        require (accountId != 0);

        Balance storage balance = prCode_AccountId_Balance[0][accountId];
        balance.available = SafeMath.Sub(balance.available, amount);
        require(msg.sender.call.value(amount)());
        emit Withdraw(0, msg.sender, amount);
    }

    function depositToken(address prAddress, uint256 amount) public
    {
        uint32 prCode = product_prCode[prAddress];
        require(prCode != 0);

        uint32 accountId = FindOrAddAccount();
        require(accountId != 0);

        require(Token(prAddress).transferFrom(msg.sender, this, amount));

        Balance storage balance = prCode_AccountId_Balance[prCode][accountId];
        balance.available = SafeMath.Add(balance.available, amount);
        emit Deposit(prCode, msg.sender, amount);
    }

    function withdrawToken(address prAddress, uint256 amount) public
    {
        uint32 prCode = product_prCode[prAddress];
        require(prCode != 0);

        uint32 accountId = account_id[msg.sender];
        require(accountId != 0);

        Balance storage balance = prCode_AccountId_Balance[prCode][accountId];
        balance.available = SafeMath.Sub(balance.available, amount);
        require(Token(prAddress).transfer(msg.sender, amount));
        emit Withdraw(prCode, msg.sender, amount);
    }

    function LimitOrder(uint32 ownerId, uint32 prTrade, uint32 prBase, bool isSell, uint256 price, uint256 qty) public returns (uint32)
    {
        uint32 accountId = account_id[msg.sender];
        require(accountId != 0);

        if (isSell == true)
        {
            price = GetUpTick(price);
        }
        else
        {
            price = GetDownTick(price);
        }

        Order memory order;
        order.ownerId = ownerId;
        order.isSell = isSell;
        order.prTrade = prTrade;
        order.prBase = prBase;
        order.accountId = accountId;
        order.price = price;
        order.qty = qty;
        order.timestamp = uint64(now);

        BalanceUpdateByLimit(order);

        emit NewOrder(prTrade, prBase, msg.sender, lastOrderId, order.isSell, order.price, order.qty, order.timestamp);

        OrderBook storage orderBook = basePID_tradePID_orderBook[prBase][prTrade];
        matchOrder(prTrade, prBase, orderBook, order, lastOrderId);

        uint256 temp;
        uint256 price0;
        if (order.qty != 0)
        {
            OrderLink storage orderLink;

            if (isSell == true)
            {
                if (orderBook.bestAskPrice == 0)
                {
                    orderBook.bestAskPrice = price;
                    //orderBook.askPrice_Order.Add(price, new OrderLink());
                }
                else if(price < orderBook.bestAskPrice)
                {
                    //orderBook.askPrice_Order.Add(price, new OrderLink());
                    orderBook.askPrice_Order[orderBook.bestAskPrice].prevPrice = price;
                    orderBook.askPrice_Order[price].nextPrice = orderBook.bestAskPrice;
                    orderBook.bestAskPrice = price;
                }
                else if (orderBook.askPrice_Order[price].orderN == 0)
                {
                    price0 = orderBook.bestAskPrice;
                    temp = price0;

                    while (temp != 0 && price0 < price)
                    {
                        price0 = temp;
                        temp = orderBook.askPrice_Order[price0].nextPrice;
                    }

                    orderBook.askPrice_Order[price0].nextPrice = price;
                    orderBook.askPrice_Order[price].prevPrice = price0;
                }

                orderLink = orderBook.askPrice_Order[price];
            }
            else
            {
                if (orderBook.bestBidPrice == 0)
                {
                    orderBook.bestBidPrice = price;
                    //orderBook.bidPrice_Order.Add(price, new OrderLink());
                }
                else if (price > orderBook.bestBidPrice)
                {
                    //orderBook.bidPrice_Order.Add(price, new OrderLink());
                    orderBook.bidPrice_Order[orderBook.bestBidPrice].prevPrice = price;
                    orderBook.bidPrice_Order[price].nextPrice = orderBook.bestBidPrice;
                    orderBook.bestBidPrice = price;
                }
                else if (orderBook.bidPrice_Order[price].orderN == 0)
                {
                    price0 = orderBook.bestBidPrice;
                    temp = price0;

                    while (temp != 0 && price0 > price)
                    {
                        price0 = temp;
                        temp = orderBook.bidPrice_Order[price0].nextPrice;
                    }

                    orderBook.bidPrice_Order[price0].nextPrice = price;
                    orderBook.bidPrice_Order[price].prevPrice = price0;

                }

                orderLink = orderBook.bidPrice_Order[price];
            }

            ListItem memory listItem;// = new ListItem();

            uint32 id = ++lastOrderId;
            if (id != 0)
            {
                if (orderLink.firstId != 0)
                {
                    listItem.prev = orderLink.lastId;// .firstID;
                    orderLink.id_orderList[orderLink.lastId].next = id;
                }
                else
                {
                    orderLink.firstId = id;
                }
                orderLink.lastId = id;
            }

            //orderLink.id_orderList.Add(id, listItem);
            //id_Order.Add(id, order);
            orderLink.id_orderList[id] = listItem;
            orderLink.orderN += 1;
            id_Order[id] = order;
        }

        return lastOrderId;
    }

    function BalanceUpdateByLimit(Order order) view private
    {
        Balance memory balance;
        if (order.isSell)
        {
            balance = prCode_AccountId_Balance[order.prTrade][order.accountId];
            balance.available = SafeMath.Sub(balance.available, order.qty);
            balance.reserved = SafeMath.Add(balance.reserved, order.qty);
        }
        else
        {
            balance = prCode_AccountId_Balance[order.prBase][order.accountId];
            uint256 temp = SafeMath.Mul(SafeMath.Mul(order.qty, order.price) / basePrice, prCode_productInfo[order.prTrade].divider) / prCode_productInfo[order.prBase].divider;
            balance.available = SafeMath.Sub(balance.available, temp);
            balance.reserved = SafeMath.Add(balance.reserved, temp);
        }
    }

    function matchOrder(uint32 prTrade, uint32 prBase, OrderBook storage orderBook, Order order, uint32 id) private
    {
        uint256 tradePrice;

        if (order.isSell == true)
            tradePrice = orderBook.bestBidPrice;
        else
            tradePrice = orderBook.bestAskPrice;

        if (tradePrice == 0)
            return;

        bool isBestPriceUpdate = false;

        OrderLink memory orderLink;// = price_OrderLink[tradePrice];

        while (tradePrice != 0 && order.qty > 0 && (
            (order.isSell && order.price <= tradePrice) ||
            (!order.isSell && order.price >= tradePrice)
            ))
        {
            if (order.isSell == true)
                orderLink = orderBook.bidPrice_Order[tradePrice];
            else
                orderLink = orderBook.askPrice_Order[tradePrice];

            uint32 orderId = orderLink.firstId;
            while (orderLink.orderN != 0 && orderId != 0 && order.qty != 0)
            {
                Order memory matchingOrder = id_Order[orderId];
                uint256 tradeAmount;
                if (matchingOrder.qty >= order.qty)
                {
                    tradeAmount = order.qty;
                    matchingOrder.qty = SafeMath.Sub(matchingOrder.qty, order.qty);
                    order.qty = 0;
                }
                else
                {
                    tradeAmount = matchingOrder.qty;
                    order.qty = SafeMath.Sub(order.qty, matchingOrder.qty);
                    matchingOrder.qty = 0;
                }

                BalanceUpdateByTrade(prTrade, prBase, order, matchingOrder, tradeAmount);

                if (order.isSell == true)
                    emit NewTrade(prTrade, prBase, orderId, id, order.isSell, tradePrice,  tradeAmount);//, order.timestamp);
                else
                    emit NewTrade(prTrade, prBase, id, orderId, order.isSell, tradePrice,  tradeAmount);//, order.timestamp);

                if (matchingOrder.qty != 0)
                {
                    //id_Order[tradePrice] = matchingOrder;
                    break;
                }
                else
                {
                    RemoveOrder(prTrade, prBase, !order.isSell, tradePrice, orderId);
                    orderId = orderLink.firstId;
                }
            }

            if (orderLink.orderN == 0)
            {
                tradePrice = orderLink.nextPrice;
                isBestPriceUpdate = true;
            }

            //ListItem item = excludeItem(pair, currentOrderId, matchingOrder.sell);
            //RemoveOpenOrder(currentOrderId, msg);
            //currentOrderId = item.next;
        }

        if (isBestPriceUpdate == true)
        {
            if (order.isSell)
            {
                orderBook.bestBidPrice = tradePrice;
                if (tradePrice != 0)
                    emit NewBid(prTrade, prBase, tradePrice);
                else
                    emit NewBid(prTrade, prBase, 0);
            }
            else
            {
                orderBook.bestAskPrice = tradePrice;
                if (tradePrice != 0)
                    emit NewAsk(prTrade, prBase, tradePrice);
                else
                    emit NewAsk(prTrade, prBase, 0);
            }
        }
    }

    function BalanceUpdateByTrade(uint32 prTrade, uint32 prBase, Order order, Order matchingOrder, uint256 tradeAmount) private
    {
        Balance memory balance;

        uint256 qtyBase = SafeMath.Mul(tradeAmount, matchingOrder.price) / basePrice;

        Balance memory balTrade = prCode_AccountId_Balance[prTrade][order.accountId];
        Balance memory balBase = prCode_AccountId_Balance[prBase][order.accountId];

        Balance memory balTradeCp = prCode_AccountId_Balance[prTrade][matchingOrder.accountId];
        Balance memory balBaseCp = prCode_AccountId_Balance[prBase][matchingOrder.accountId];

        if (order.isSell == true)
        {
            balTrade.reserved = SafeMath.Sub(balTrade.reserved, tradeAmount);
            balBase.available = SafeMath.Add(balBase.available, qtyBase);

            balTradeCp.available = SafeMath.Add(balTradeCp.available, tradeAmount);
            balBaseCp.reserved = SafeMath.Sub(balBaseCp.reserved, qtyBase);
        }
        else
        {
            balTradeCp.reserved = SafeMath.Sub(balTradeCp.reserved, tradeAmount);
            balBaseCp.available = SafeMath.Add(balBaseCp.available, qtyBase);

            balTrade.available = SafeMath.Add(balTrade.available, tradeAmount);
            balBase.reserved = SafeMath.Sub(balBase.reserved, qtyBase);
        }
    }

    function PayFee(uint32 prTrade, uint32 prBase, Order order, uint256 tradeAmount) private
    {
        uint256 takeFeeMain = tradeAmount * takeFeeMain / 10000;
        uint256 takeFeeLocal = tradeAmount * ownerId_takerFeeRateLocal[order.ownerId] / 10000;

        Balance memory balance;
        if (order.isSell == true)
        {
            balance = prCode_AccountId_Balance[prBase][order.accountId];
            balance.available = SafeMath.Sub(SafeMath.Sub(balance.available, takeFeeMain), takeFeeLocal);

            prCode_AccountId_Balance[prBase][ownerId_accountId[1]].available += takeFeeMain;
            prCode_AccountId_Balance[prBase][ownerId_accountId[order.ownerId]].available += takeFeeLocal;
        }
        else
        {
            balance = prCode_AccountId_Balance[prTrade][order.accountId];
            balance.available = SafeMath.Sub(SafeMath.Sub(balance.available, takeFeeMain), takeFeeLocal);

            prCode_AccountId_Balance[prTrade][ownerId_accountId[1]].available += takeFeeMain;
            prCode_AccountId_Balance[prTrade][ownerId_accountId[order.ownerId]].available += takeFeeLocal;
        }
    }


    function RemoveOrder(uint32 tradePrCode, uint32 basePrCode, bool isSell, uint256 price, uint32 id) public
    {
        OrderLink storage orderLink;
        OrderBook storage orderBook = basePID_tradePID_orderBook[basePrCode][tradePrCode];

        if (isSell == false)
        {
            orderLink = orderBook.bidPrice_Order[price];
        }
        else
        {
            orderLink = orderBook.askPrice_Order[price];
        }

        if (id != 0)
        {
            ListItem storage removeItem = orderLink.id_orderList[id];
            ListItem storage replaceItem;
            if (removeItem.next != 0)
            {
                replaceItem = orderLink.id_orderList[removeItem.next];
                replaceItem.prev = removeItem.prev;
            }

            if (removeItem.prev != 0)
            {
                replaceItem = orderLink.id_orderList[removeItem.prev];
                replaceItem.next = removeItem.next;
            }

            if (id == orderLink.lastId)
            {
                orderLink.lastId = removeItem.prev;
            }

            if (id == orderLink.firstId)
            {
                orderLink.firstId = removeItem.next;
            }


            delete orderLink.id_orderList[id];
            orderLink.orderN -= 1;

            if (orderLink.orderN == 0)
            {
                OrderLink storage replaceLink;
                if (orderLink.nextPrice != 0)
                {
                    if (isSell == true)
                        replaceLink = orderBook.askPrice_Order[orderLink.nextPrice];
                    else
                        replaceLink = orderBook.bidPrice_Order[orderLink.nextPrice];

                    replaceLink.prevPrice = orderLink.prevPrice;
                }
                if (orderLink.prevPrice != 0)
                {
                    if (isSell == true)
                        replaceLink = orderBook.askPrice_Order[orderLink.prevPrice];
                    else
                        replaceLink = orderBook.bidPrice_Order[orderLink.prevPrice];

                    replaceLink.nextPrice = orderLink.nextPrice;
                }

                if (price == orderBook.bestAskPrice)
                {
                    orderBook.bestAskPrice = orderLink.nextPrice;
                }
                if (price == orderBook.bestBidPrice)
                {
                    orderBook.bestBidPrice = orderLink.nextPrice;
                }
            }
        }
    }

    function cancelOrder(uint32 prTrade, uint32 prBase, bool isSell, uint256 price, uint32 id) public
    {
        Order memory order = id_Order[id];
        uint32 accountId = account_id[msg.sender];
        require(order.accountId == accountId);

        Balance memory balance;

        if (order.isSell)
        {
            balance = prCode_AccountId_Balance[order.prTrade][order.accountId];
            balance.available = SafeMath.Add(balance.available, order.qty);
            balance.reserved = SafeMath.Sub(balance.reserved, order.qty);
        }
        else
        {
            balance = prCode_AccountId_Balance[order.prBase][order.accountId];
            uint256 temp = SafeMath.Mul(SafeMath.Mul(order.qty, order.price) / basePrice, prCode_productInfo[order.prTrade].divider) / prCode_productInfo[order.prBase].divider;
            balance.available = SafeMath.Add(balance.available, temp);
            balance.reserved = SafeMath.Sub(balance.reserved, temp);
        }

        RemoveOrder(prTrade, prBase, isSell, price, id);//, msg);
    }

    function getBalance(uint32 prCode) view public returns (uint256 available, uint256 reserved)
    {
        uint32 accountId = account_id[msg.sender];

        if (accountId != 0)
        {
            available = prCode_AccountId_Balance[prCode][accountId].available;
            reserved = prCode_AccountId_Balance[prCode][accountId].reserved;
        }
        else
        {
            available = 0;
            reserved = 0;
        }
    }

    function getOrderBookInfo(uint32 prTrade, uint32 prBase) view public returns (uint256 bidPrice, uint256 askPrice)
    {
        OrderBook memory orderBook = basePID_tradePID_orderBook[prBase][prTrade];// iCode_OrderBook[prCode];
        bidPrice = orderBook.bestBidPrice;
        askPrice = orderBook.bestAskPrice;
    }

    function getOrder(uint32 id) view public returns (bool sell, uint256 price, uint256 qty, uint64 timestamp)
    {
        Order memory order = id_Order[id];

        price = order.price;
        sell = order.isSell;
        qty = order.qty;
        timestamp = order.timestamp;
    }
    /*
    function GetMyOrders() public returns (uint32[] prTrade, uint32[] prBase, uint256[] qtys, uint256[] prices, bool[] sells, uint64[] timestamp)
    {
        OpenOrder openOrder = holder_OpenOrder[msg.sender];

        ulong id;

        prTrade = new ulong[openOrder.orderN];
        prBase = new ulong[openOrder.orderN];
        qtys = new ulong[openOrder.orderN];
        prices = new ulong[openOrder.orderN];
        sells = new bool[openOrder.orderN];
        timestamp = new ulong[openOrder.orderN];

        id = openOrder.startId;
        if (id != 0)
        {
            Order order;
            int i = 0;
            while (id != 0)
            {
                order = id_Order[id];

                prTrade[i] = order.prTrade;
                prBase[i] = order.prBase;
                qtys[i] = order.qty;
                prices[i] = order.price;
                sells[i] = order.isSell;
                timestamp[i] = order.timestamp;

                id = openOrder.id_orderList[id].next;
                i++;
            }
        }
    }*/

    function GetHogaDetail(uint32 prTrade, uint32 prBase, uint256 price, bool isSell) view public returns (uint32[] orderIds, uint256[] volumes)
    {
        OrderLink storage orderLink;
        if (isSell == false)
        {
            orderLink = basePID_tradePID_orderBook[prBase][prTrade].bidPrice_Order[price];

        }
        else if (isSell == true)
        {
            orderLink = basePID_tradePID_orderBook[prBase][prTrade].askPrice_Order[price];
        }
        else
        {
            return;
        }

        orderIds = new uint32[](orderLink.orderN);
        volumes = new uint256[](orderLink.orderN);

        uint32 n = 0;
        uint32 id0 = orderLink.firstId;
        while (id0 != 0)
        {
            orderIds[n] = id0;
            volumes[n] = id_Order[id0].qty;
            id0 = orderLink.id_orderList[id0].next;
            n++;
        }
    }

    function GetHogaBid(OrderBook storage ob, uint32 hogaN) private view returns (uint256[] prices, uint256[] volumes, uint256[] orderNums)
    {
        prices = new uint256[](hogaN);
        volumes = new uint256[](hogaN);
        orderNums = new uint256[](hogaN);

        uint32 n;
        uint32 id0;
        uint256 price;
        uint256 sum;
        if (ob.bestBidPrice != 0)
        {
            price = ob.bestBidPrice;
            OrderLink storage orderLink = ob.bidPrice_Order[price];
            id0 = orderLink.firstId;
            sum = 0;
            n = 0;
            while (price != 0 && n < hogaN)
            {
                id0 = orderLink.firstId;
                sum = 0;
                while (id0 != 0)
                {
                    sum += id_Order[id0].qty;
                    id0 = orderLink.id_orderList[id0].next;
                }
                prices[n] = price;
                volumes[n] = sum;
                orderNums[n] = orderLink.orderN;
                price = orderLink.nextPrice;
                if (price != 0)
                    orderLink = ob.bidPrice_Order[price];
                n++;
            }

            if (n > 0)
            {
                while (n < hogaN)
                {
                    prices[n] = GetDownTick(prices[n - 1] - 1);
                    n++;
                }
            }
        }
        else if (ob.bestAskPrice != 0)
        {
            prices[0] = GetDownTick(ob.bestAskPrice - 1);
            n = 1;
            while (n < hogaN)
            {
                prices[n] = GetDownTick(prices[n - 1] - 1);
                n++;
            }
        }
    }

    function GetHogaAsk(OrderBook storage ob, uint32 hogaN) private view returns (uint256[] prices, uint256[] volumes, uint256[] orderNums)
    {
        prices = new uint256[](hogaN);
        volumes = new uint256[](hogaN);
        orderNums = new uint256[](hogaN);

        uint32 n;
        uint32 id0;
        uint256 price;
        uint256 sum;

        if (ob.bestAskPrice != 0)
        {
            price = ob.bestAskPrice;
            OrderLink storage orderLink = ob.askPrice_Order[price];
            id0;// = orderLink.firstId;
            sum;// = 0;

            n = 0;
            while (price != 0 && n < hogaN)
            {
                id0 = orderLink.firstId;
                sum = 0;
                while (id0 != 0)
                {
                    sum += id_Order[id0].qty;
                    id0 = orderLink.id_orderList[id0].next;
                }
                //id0 = orderLink.id_orderList[id0].next;
                prices[n] = price;
                volumes[n] = sum;
                orderNums[n] = orderLink.orderN;
                price = orderLink.nextPrice;
                if (price != 0)
                    orderLink = ob.askPrice_Order[price];
                n++;
            }

            if (n > 0)
            {
                while (n < hogaN)
                {
                    prices[n] = GetUpTick(prices[n - 1] + 1);
                    n++;
                }
            }
        }
        else if (ob.bestBidPrice != 0)
        {
            prices[0] = GetUpTick(ob.bestBidPrice + 1);
            n = 1;
            while (n < hogaN)
            {
                prices[n] = GetUpTick(prices[n - 1] + 1);
                n++;
            }
        }
    }

    function GetHoga(uint32 prTrade, uint32 prBase, uint32 hogaN) public view
    returns (uint256[] priceB, uint256[] volumeB, uint256[] orderNumB, uint256[] priceA, uint256[] volumeA, uint256[] orderNumA)
    {
        OrderBook storage ob = basePID_tradePID_orderBook[prBase][prTrade];

        (priceB, volumeB, orderNumB) = GetHogaBid(ob, hogaN);
        (priceA, volumeA, orderNumA) = GetHogaAsk(ob, hogaN);
    }

    function GetDownTick(uint price) public pure returns (uint)
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

    function GetUpTick(uint price) public pure returns (uint)
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
