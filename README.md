# DexBackend
Rough Backend for Dex. We dont have authentication here!! Do not use this code in production env.

***********************************************************************

AddOwner:  Anybody can be a owner in dex by paying some amount of defined fees.
Right now it is kept to zero. You need to be an owner to list your product on Dex.


Func Parameters: owner: ETH account address of owners
            amount: Fee Amount


***********************************************************************
GetOnwerList: Get List of Owners and their Id's.

Fuc Params: owmer: ETH address of account

Return: Json object {"ownerList": result}, result is an array of array.
result[0] = Array of owner addresses
result[1] = Array of owner id's corresponding to owner address in result[0].
***********************************************************************

AddProduct: Once you are owner, you can list your product on exchange
i.e. listing of token.

Func Parameters:

Product = Product i.e token address;
owner = Owner ETH address which was used to call AddOwner!!;
amount = Fee amount, fee for listing token on Dex platform;

***********************************************************************
GetProductList: Get List of Products currently listed on exchange.

Fuc Params: No params

Return: Json object {"productList": result}, result is an array of array.
result[0] = Array of products
result[1] = Array of product id's corresponding to product in result[0].

***********************************************************************

GetAccountList: Return account addresses of users and their corresponding Id's
on dex.

Func Params: No params

Return: Json {"accountList": result}, result is array of array.
result[0] = address of account holders
result[1] = Id's corresponding to result[0].
***********************************************************************

depositETH & withdrawETH : Function for users/traders to add/withdraw ETHER to their/from
 account on dex.

 Func Params:

 amount = Amount to add/withdraw;
 owner =  ETH address;

 ***************************************************************************

depositERC20  & withdrawERC20 : Functions to add/withdraw ERC20 token their account on dex.

Func Params:

amount = Amount to add/withdraw;
owner =  ETH address;
token: token address
***********************************************************************
