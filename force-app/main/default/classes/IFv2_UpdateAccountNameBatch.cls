/*******************************************************************************************************
* 
* @ Name 			: IFv2_UpdateAccountType
* @ Purpose 		: Class to update account name with INF.
* @ Author			: Vivek
* @ Test Class Name : IFv2_UpdateAccountTypeTest
*
*   Date        |  Developer Name                 |  Version      |  Changes
* ======================================================================================================
*   01-07-2019  |  vivek.kothalanka@absyz.com     |  1.0          |  Initial Version

*******************************************************************************************************/
global class IFv2_UpdateAccountNameBatch implements Database.Batchable<sObject>  {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id,Name,ownerId,IFv2_Request__r.Name,RecordType.name,IFv2_ContentType__c FROM ACCOUNT WHERE (recordtype.Name = \'Request Extension\' OR recordtype.Name = \'Customer\' OR recordtype.Name =\'Request Items\') and ownerId !=\''+Label.CLIFv20022 +'\' and NAME like \'%INF%\'';
        system.debug('query'+query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, list<Account> AccountUpdateList) {
        try{
            system.debug('AccountUpdateList'+AccountUpdateList);
            IFv2_UpdateAccountName.UpdateAccountName(AccountUpdateList);            
        } catch(Exception e){
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }
    }
    global void finish(Database.BatchableContext bc) {
        
    }
}