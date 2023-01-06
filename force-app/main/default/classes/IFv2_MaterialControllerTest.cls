/*******************************************************************************************************
* 
* @ Name    	:   IFv2_MaterialControllerTest
* @ Purpose 	:   Test class for IFv2_MaterialController
* @ Author  	:   Anoop Ravindran
* @ Class Name	:	IFv2_MaterialController
*
*   Date        |  Developer Name                   	|  Version      |  Changes
* ======================================================================================================
*   21-05-2019  |  anoop.ravindran@absyz.com.seg     	|  1.0          |  Initial Version
*
*******************************************************************************************************/
@isTest
public class IFv2_MaterialControllerTest {
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
    public @IsTest
    static void materialControllerTest(){
        
        Test.startTest();
        User usr = [SELECT Id FROM User WHERE UserName = 'standarduser@testorg.com.seg'];
        IFv2_RequestExtension1__c ext = new IFv2_RequestExtension1__c();

        
        
        IFv2_Request__c nonRetreq = new IFv2_Request__c(Workflow__c = Label.CLIFv20199);
        nonRetreq.ChallanTypeofGatePass__c = 'Non - Returnable';
        nonRetreq.Approver1__c = usr.Id;
        nonRetreq.Approver2__c = usr.Id;
        nonRetreq.Approver3__c = usr.Id;
        nonRetreq.Approver4__c = usr.Id;
        nonRetreq.Approver8__c = usr.Id;
        nonRetreq.Approver9__c = usr.Id;
        nonRetreq.Approver10__c = usr.Id;
        nonRetreq.Customer_Name__c = 'Test Customer';
        Database.insert(ext);
        System.assertNotEquals(null, ext.Id);
        
        nonRetreq.RequestExtension1__c = ext.Id;
        Database.insert(nonRetreq);
        System.assertNotEquals(null, nonRetreq.Id);
        
        Id acctRecType = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordtypeinfosbydevelopername().get('IFv2_RequestItems').getRecordTypeId();
        Account mat = new Account(RecordTypeId = acctRecType);
        mat.Name = 'Test Material';
        mat.IFv2_Quantity__c = 200;
        mat.IFv2_Amount__c = 15000;
        mat.IFv2_Request__c = nonRetreq.Id;
        Database.insert(mat);
        System.assertNotEquals(null, mat.Id);

        IFv2_MaterialController.MaterialDisplayWrapper dispWrapper = IFv2_MaterialController.getMaterialDetails(nonRetreq.Id);
        System.assertEquals(1, dispWrapper.materialDetailLIST.size());
        System.assertEquals(true, dispWrapper.isParent);

        IFv2_MaterialController.MaterialWrapper wrap = new IFv2_MaterialController.MaterialWrapper();
        wrap.currentQty = 100;
        wrap.material = mat;
        LIST<IFv2_MaterialController.MaterialWrapper> wrapList = IFv2_MaterialController.updateMaterialDetails(nonRetreq.Id, new LIST<IFv2_MaterialController.MaterialWrapper>{wrap});
        
        wrap = wrapList[0];
        system.assertEquals(100, wrap.material.IFv2_ReturnedQuantity__c);
        wrap.currentQty = 150;
        wrapList =  IFv2_MaterialController.updateMaterialDetails(nonRetreq.Id, new LIST<IFv2_MaterialController.MaterialWrapper>{wrap});
        system.assertEquals(null, wrapList);

        nonRetreq.Workflow__c = Label.CLIFv20200;
        nonRetreq.ChallanTypeofGatePass__c = 'Returnable';
        Database.update(nonRetreq);
        dispWrapper = IFv2_MaterialController.getMaterialDetails(nonRetreq.Id);
        System.assertEquals(1, dispWrapper.materialDetailLIST.size());
        System.assertEquals(false, dispWrapper.isParent);
        Test.stopTest();
        
    }
    
    
    public @IsTest
    static void requestTriggerTest(){
        
        Test.startTest();
        User usr = [SELECT Id FROM User WHERE UserName = 'standarduser@testorg.com.seg'];
        IFv2_RequestExtension1__c ext = new IFv2_RequestExtension1__c();

        
        
        IFv2_Request__c req = new IFv2_Request__c(Workflow__c = Label.CLIFv20199);
        req.ChallanTypeofGatePass__c = 'Non - Returnable';
        req.Approver1__c = usr.Id;
        req.Approver2__c = usr.Id;
        req.Approver3__c = usr.Id;
        req.Approver4__c = usr.Id;
        req.Approver5__c = usr.Id;
        req.Approver6__c = usr.Id;
        req.Approver7__c = usr.Id;
        req.Approver8__c = usr.Id;
        req.Approver9__c = usr.Id;
        req.Approver10__c = usr.Id;
        Database.insert(ext);
        System.assertNotEquals(null, ext.Id);
        req.Status__c = 'Submitted';
        req.RequestExtension1__c = ext.Id;
        Database.insert(req);
        System.assertNotEquals(null, req.Id);
        
        Id acctRecType = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordtypeinfosbydevelopername().get('IFv2_RequestItems').getRecordTypeId();
        Account mat = new Account(RecordTypeId = acctRecType);
        mat.Name = 'Test Material';
        mat.IFv2_Quantity__c = 200;
        mat.IFv2_Amount__c = 15000;
        mat.IFv2_Request__c = req.Id;
        Database.insert(mat);
        System.assertNotEquals(null, mat.Id);
        req.ChallanTypeofGatePass__c = 'Returnable';
        req.Status__c = 'Approved';
        Database.update(req);
        
        Contact record = new Contact();
        record.AccountId = mat.Id;
        record.LastName = 'Test Contact';
        insert record;
        
        LIST<IFv2_Request__c> parentReq = [select Id,parentRequest__c FROM IFv2_Request__c where Id = :req.Id];
        LIST<IFv2_Request__c> childReq = [select Id,parentRequest__c FROM IFv2_Request__c where parentRequest__c = :req.Id];
        System.assertEquals(1,childReq.size());
        System.assertEquals(childReq[0].Id,parentReq[0].parentRequest__c);
        System.assertEquals(parentReq[0].Id,childReq[0].parentRequest__c);
        
        Test.stopTest();
        
    }
}