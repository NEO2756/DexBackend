var createError = require('http-errors');
var express = require('express');
var cors = require('cors');
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');

var Web3 = require('web3');
var Accounts = require('web3-eth-accounts');
var artifacts = require('./contracts/build/contracts/DEXHIGH2.json');

//var web3 = new Web3(new Web3.providers.HttpProvider('https://ropsten.infura.io/IhLG9qqYJAtwKaMkbXQU'));
var web3 = new Web3(new Web3.providers.HttpProvider('http://ec2-54-180-123-66.ap-northeast-2.compute.amazonaws.com:8545'));
const contractAddress = '0xecf46b8ec969efe8bb6d4dc209a274ae3f25210b';
const contractABI = artifacts.abi;

const contract = new web3.eth.Contract(contractABI, contractAddress);

var app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

app.use(logger('dev'));
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

//app.use('/', indexRouter);
//app.use('/users', usersRouter);

app.get('/', (req, res) => {
  res.status(200).send("Hey, I am alive and I don't bother if someone HIT me up..:P");
})

app.get('/createETHAccount', (req, res) => {

    web3.eth.personal.newAccount("password", function(err, result) {
      if (err) res.status(400).send("create ETH Account API Fails");
    }).then(result => {
      web3.eth.personal.unlockAccount(result, "password", function(err, r) {
        if (err) res.status(400).send("unlock Account API Fails");
        else res.status(200).json({"account": result});
    })
  });
})

app.get('/getBalance', (req, res) => {

  owner = req.body.owner;
  product = req.body.product;
  console.log(owner);
  contract.methods.getBalance(product).call({from: owner, to:contractAddress}, function (err, result) {
  if (err) {
	res.status(400).send("Error in getBalance");
  } else {
   res.status(200).json({"available": result, "reserve": result});
  }
 })
})

app.post('/buyETH', (req, res) => {
  owner = req.body.owner;
  web3.eth.getAccounts((err, accounts) => {
    if (err) res.status(400).send("Error in getAccounts()");
    else {
      web3.eth.sendTransaction({from: accounts[0], to: owner, value: 5, gas:21000} , (err, hash) => {
        if (err)
        res.status(400).send("ETH transfer fail");
        else
        res.status(200).json({"hash" : hash});
      });
    }
  });
})

app.post('/LimitOrder', (req, res) => {
  owner = req.body.owner;
  ownerId = req.body.ownerId;
  prTrade = req.body.prTrade;
  prBase = req.body.prBase;
  sell = req.body.sell;
  price = req.body.price;
  qty = req.body.qty;

  contract.methods.LimitOrder(owner, prTrade, prBase, sell, price, qty)
  .send({from: owner, to: contractAddress, value: amount, gas: 300000}, (err, result) => {
    if (err)
      res.status(400).send("Limit Order Fails");
    else
      res.status(200).json({"order_id" : result});
  });
})



app.post('/depositETH', (req, res) => {
  console.log(req.body);
  amount = req.body.amount;
  owner = req.body.owner;
  console.log(owner, amount);

  contract.methods.depositETH().send({from: owner, to: contractAddress, value: amount, gas: 300000}).on('transactionHash', function(hash) {
    res.status(200).json({"hash" : hash});
  }).on('error', function(error) {
    res.status(400).send("depositETH failed for" + owner);
  }).on ('receipt', function(receipt) {
    res.status(200).send(receipt);
  }).catch(e => {
      console.log(e);
  });
})

app.post('/withdrawETH', (req, res) => {
  //owner = web3.utils.toChecksumAddress(req.query.owner);
  amount = req.body.amount;
  owner = req.body.owner;
  console.log(owner, amount);

  contract.methods.withdrawETH(amount).send({from: owner, to: contractAddress}).once('transactionHash', function(hash) {
    res.status(200).json({"hash" : hash});
  }).on('error', function(error) {
    res.status(400).send("withdrawETH failed for" + owner);
  }).on ('receipt', function(receipt) {
    res.status(200).send(receipt);
  }).catch(e => {
      console.log(e);
  });
})

app.post('/depositERC20', (req, res) => {
  //owner = web3.utils.toChecksumAddress(req.query.owner);
  amount = req.body.amount;
  owner = req.body.owner;
  token = req.body.token;
  console.log(owner, amount, token);

  contract.methods.depositERC20(token, amount).send({from: owner, to: contractAddress}).once('transactionHash', function(hash) {
    res.status(200).json({"hash" : hash});
  }).on('error', function(error) {
    res.status(400).send("depositETH failed for" + owner);
  }).on ('receipt', function(receipt) {
    res.status(200).send(receipt);
  }).catch(e => {
      console.log(e);
  });
})

app.post('/withdrawERC20', (req, res) => {
  //owner = web3.utils.toChecksumAddress(req.query.owner);
  amount = req.body.amount;
  owner = req.body.owner;
  token = req.body.token;
  console.log(owner, amount, token);

  contract.methods.withdrawERC20(token, amount).send({from: owner, to: contractAddress}).once('transactionHash', function(hash) {
    res.status(200).json({"hash" : hash});
  }).on('error', function(error) {
    res.status(400).send("depositETH failed for" + owner);
  }).on ('receipt', function(receipt) {
    res.status(200).send(receipt);
  }).catch(e => {
      console.log(e);
  });
})



app.post('/AddOwner', (req, res) => {
  owner = req.body.owner;
  amount = req.body.amount;
  console.log(owner, amount);
  contract.methods.AddOwner().send({from: owner, to:contractAddress, value:amount}).once('transactionHash', function(hash) {
    res.status(200).json({"hash" : hash});
  }).on('error', function(error) {
    res.status(400).send("AddOwner failed for" + owner);
  }).on ('receipt', function(receipt) {
    res.status(200).send(receipt);
  }).catch(e => {
      console.log(e);
  });
})

app.get('/GetOwnerList', (req, res) => {
  owner = req.body.owner;
  console.log(owner);

  contract.methods.GetOnwerList().call({to:contractAddress}, function (err, result) {
    if (err) {
      res.status(400).send("Error GetOnwerList");
    } else {
      res.status(200).json({"ownerList": result});
    }
  })
})

app.get('/AddProduct', (req, res) => {
  product = req.body.product;
  owner = req.body.owner;
  amount = req.body.amount;
  name = req.body.name;
  decimals = req.body.decimals;
  console.log(owner, amount, product);
  contract.methods.AddProduct(product, name, decimals).send({from: owner, to:contractAddress, value:amount, gas:3000000}).once('transactionHash', function(hash) {
    res.status(200).json({"hash" : hash});
  }).on('error', function(error) {
    res.status(400).send("depositETH failed for" + owner);
  }).on ('receipt', function(receipt) {
    res.status(200).send(receipt);
  }).catch(e => {
      console.log(e)
  });
})


app.post('/GetProductInfo', (req, res) => {
  owner = req.body.owner;
  product = req.body.product;

  contract.methods.GetProductInfo(product).call({from: owner, to:contractAddress}, function (err, result) {
    if (err) {
      res.status(400).send("Error GetProductInfo");
    } else {
      res.status(200).send(result);
    }
  });
})

app.get('/GetProductList', (req, res) => {
  owner = req.body.owner;
  console.log(owner);

  contract.methods.GetProductList().call({to:contractAddress}, function (err, result) {
    if (err) {
      res.status(400).send("Error GetProductList");
    } else {
      res.status(200).json({"productList": result});
    }
  })
})

app.get('/GetAccountList', (req, res) => {
  owner = req.body.owner;
  console.log(owner);

  contract.methods.GetAccountList().call({to:contractAddress}, function (err, result) {
    if (err) {
      res.status(400).send("Error GetProductList");
    } else {
      res.status(200).json({"accountList": result});
    }
  })
})


// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

module.exports = app;
