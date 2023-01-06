/*******************************************************************************************************
* 
* @ Name    	:   IFv2_MaterialBatchTest
* @ Purpose 	:   Test class for IFv2_MaterialController
* @ Author  	:   Anoop Ravindran
* @ Class Name	:	IFv2_MaterialBatch
*
*   Date        |  Developer Name                   	|  Version      |  Changes
* ======================================================================================================
*   21-05-2019  |  anoop.ravindran@absyz.com.seg     	|  1.0          |  Initial Version
*
*******************************************************************************************************/
@isTest
public class IFv2_MaterialBatchTest {
    
    @TestSetup
    static void makeData(){
        Profile prof = [SELECT Id FROM Profile WHERE Name='SG Standard User']; 
        User usr = new User(Alias = 'standt', Email='standarduser@testorg.com.seg', 
                            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', ProfileId = prof.Id, 
                            TimeZoneSidKey='Asia/Kolkata', UserName='standarduser@testorg.com.seg');
        usr.Country = 'India';
        Database.insert(usr);
    }
    
    public @IsTest static void materialBatchTest(){
        Test.startTest();
        User usr = [SELECT Id FROM User WHERE UserName = 'standarduser@testorg.com.seg'];
        IFv2_RequestExtension1__c ext = new IFv2_RequestExtension1__c();
        
        
        IFv2_Request__c nonRetreq = new IFv2_Request__c(Workflow__c = Label.CLIFv20199);
        nonRetreq.ChallanTypeofGatePass__c = 'Returnable';
        nonRetreq.Approver1__c = usr.Id;
        nonRetreq.Approver2__c = usr.Id;
        nonRetreq.Approver3__c = usr.Id;
        nonRetreq.Approver4__c = usr.Id;
        nonRetreq.Approver8__c = usr.Id;
        nonRetreq.Approver9__c = usr.Id;
        nonRetreq.Approver10__c = usr.Id;
        nonRetreq.Customer_Name__c = 'Test Customer';
        nonRetreq.DueDateofReturn__c = System.today();
        
        Database.insert(ext);
        System.assertNotEquals(null, ext.Id);
        
        nonRetreq.RequestExtension1__c = ext.Id;
        Database.insert(nonRetreq);
        System.assertNotEquals(null, nonRetreq.Id);
        

        IFv2_Request__c reqChild = new IFv2_Request__c(Workflow__c = Label.CLIFv20200);
        reqChild.ChallanTypeofGatePass__c = 'Returnable';
        reqChild.Approver1__c = usr.Id;
        reqChild.ParentRequest__c = nonRetreq.Id;
        reqChild.RequestExtension1__c = ext.Id;
        reqChild.DueDateofReturn__c = System.today();
        reqChild.Status__c = 'Submitted';

        Database.insert(reqChild);
        System.assertNotEquals(null, reqChild.Id);

        Id acctRecType = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordtypeinfosbydevelopername().get('IFv2_RequestItems').getRecordTypeId();
        Account mat = new Account(RecordTypeId = acctRecType);
        mat.Name = 'Test Material';
        mat.IFv2_Quantity__c = 200;
        mat.IFv2_Amount__c = 15000;
        mat.IFv2_Request__c = nonRetreq.Id;
        Database.insert(mat);
        System.assertNotEquals(null, mat.Id);
        Database.executeBatch(new IFv2_MaterialBatch());
        
        Test.stopTest();
    }
}