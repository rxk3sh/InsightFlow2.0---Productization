/*******************************************************************************************************
* 
* @ Name 			: IFv2_UpdateAccountTypeTest
* @ Author			: Vivek
* @ Test Class Name : IFv2_UpdateAccountName
*
*   Date        |  Developer Name                 |  Version      |  Changes
* ======================================================================================================
*   01-07-2019  |  vivek.kothalanka@absyz.com     |  1.0          |  Initial Version

*******************************************************************************************************/
@istest
public class IFv2_UpdateAccountTypeTest {
    
    public static testmethod void testMethod1() {
        
        Test.startTest();
        
        IFv2_Workflow__c workflowRecord = IFv2_testDataUtility.createWorkflowCustomSetting();
        
        workflowRecord.Name = 'eSignature';
        workflowRecord.Workflow__c = 'eSignature';
        insert workflowRecord;
        System.assertEquals(true, workflowRecord != Null);
        
        User loggedInUser = IFv2_testDataUtility.createUser();
        loggedInUser.IFv2_ByPassValidation__c = true;
        insert loggedInUser;
        System.assertEquals(true, loggedInUser != Null);
        
        system.runas(loggedInUser){
            IFv2_WorkflowListviewController.createRequestRecord(workflowRecord);
        }
        loggedInUser.IFv2_ByPassValidation__c = false;
        update loggedInUser;
        System.assertEquals(true, loggedInUser.IFv2_ByPassValidation__c == false);
        
        Account accountRecord = [SELECT Id, Name,RecordTypeId,RecordType.Name 
                                 FROM Account LIMIT 1];
        
        accountRecord.ownerId = UserInfo.getUserID();
        accountRecord.Name =  accountRecord.Name.replace('ACC','INF');
        update accountRecord;
        
        IFv2_UpdateAccountNameBatch obj = new IFv2_UpdateAccountNameBatch();
        DataBase.executeBatch(obj); 
        
        Test.stopTest();
    }
    
    public static testmethod void testMethod2() {
        
        Test.startTest();
        
        IFv2_Workflow__c workflowRecord = IFv2_testDataUtility.createWorkflowCustomSetting();
        
        workflowRecord.Name = 'eSignature';
        workflowRecord.Workflow__c = 'eSignature';
        insert workflowRecord;
        System.assertEquals(true, workflowRecord != Null);
        
        User loggedInUser = IFv2_testDataUtility.createUser();
        loggedInUser.IFv2_ByPassValidation__c = true;
        insert loggedInUser;
        System.assertEquals(true, loggedInUser != Null);
        
        system.runas(loggedInUser){
            IFv2_WorkflowListviewController.createRequestRecord(workflowRecord);
        }
        loggedInUser.IFv2_ByPassValidation__c = false;
        update loggedInUser;
        System.assertEquals(true, loggedInUser.IFv2_ByPassValidation__c == false);
        
        Account accountRecord = [SELECT Id, Name,RecordTypeId,RecordType.Name 
                                 FROM Account LIMIT 1];
        Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        system.debug(AccountRecordTypeId);
        accountRecord.RecordTypeId = AccountRecordTypeId;
        accountRecord.ownerId = UserInfo.getUserID();
        accountRecord.Name =  accountRecord.Name.replace('ACC','INF');
        update accountRecord;          
        
        IFv2_UpdateAccountNameBatch obj = new IFv2_UpdateAccountNameBatch();
        DataBase.executeBatch(obj); 
        
        Test.stopTest();
    }
}