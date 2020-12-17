/*
export function getRandomInt(min, max) {
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min)) + min; //Максимум не включается, минимум включается
}*/

/*
export async function Deploy(accounts) {
  let instance = await BXFToken.deployed();
  await instance.grantRole(await instance.MIGRATION_MANAGER_ROLE(), accounts[0]);
  await instance.grantRole(await instance.SALE_MANAGER_ROLE(), accounts[0]);
  await instance.finishAccountMigration({from: accounts[0]});
  return instance;
}*/
