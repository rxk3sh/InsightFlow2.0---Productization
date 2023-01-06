/*******************************************************************************************************
* 
* @ Name 			: IFv2_UpdateAccountName
* @ Purpose 		: Class handler to update account name with INF.
* @ Author			: Vivek
* @ Test Class Name : IFv2_UpdateAccountTypeTest
*
*   Date        |  Developer Name                 |  Version      |  Changes
* ======================================================================================================
*   01-07-2019  |  vivek.kothalanka@absyz.com     |  1.0          |  Initial Version

*******************************************************************************************************/
public class IFv2_UpdateAccountName {
    
    public static void UpdateAccountName(LIST<Account> accountLIST){
        
        LIST<Account> UpdateAccountLIST = new LIST<Account>();
        for(Account singleAccount : accountLIST) {
            
            // checking if record type is customer then change it to request extenison
            if(singleAccount.RecordType.name == 'Customer' &&  singleAccount.Name.contains('INF')) {
                Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Extension').getRecordTypeId();
                singleAccount.RecordTypeId = AccountRecordTypeId;
            }
            
            // replacing INF with ACC for extension and reques items records
            singleAccount.Name = singleAccount.Name.replace('INF','ACC');
            singleAccount.ownerid = Label.CLIFv20022;
            UpdateAccountLIST.add(singleAccount);
        }
        system.debug('UpdateAccountLIST'+UpdateAccountLIST);
        Database.SaveResult[] saveResult = Database.update(UpdateAccountLIST);
        system.debug('saveResult'+saveResult);
    }
}