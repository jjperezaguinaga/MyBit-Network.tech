var bn = require('bignumber.js');

const Database = artifacts.require("./database/Database.sol");
const ContractManager = artifacts.require("./database/ContractManager.sol");
const SingleOwned = artifacts.require("./ownership/SingleOwned.sol");
const HashFunctions = artifacts.require("./test/HashFunctions.sol");

const owner = web3.eth.accounts[0];
const newOwner = web3.eth.accounts[1];

contract('SingleOwned', async() => {
  let db;
  let cm;
  let so;
  let hash;

  it('Deploy hash contract', async() => {
    hash = await HashFunctions.new();
  });

  it('Deploy Database', async() => {
    db = await Database.new([owner], true);
    cm = await ContractManager.new(db.address);
    await db.enableContractManagement(cm.address);
  });

  it('Deploy SingleOwned', async() => {
    so = await SingleOwned.new(db.address);
    await cm.addContract('SingleOwned', so.address);
  });

  it('Fail change owner', async() => {
    let err;
    try{
      await so.changeOwner(newOwner, {from:newOwner});
    } catch(e){
      err = e;
    }
    assert.notEqual(err, undefined);
  });

  it('Change owner', async() => {
    await so.changeOwner(newOwner, {from:owner});
    let ownerHash = await hash.stringAddress('owner', newOwner);
    let ownerBool = await db.boolStorage(ownerHash);
    assert.equal(ownerBool, true);
  });

});
