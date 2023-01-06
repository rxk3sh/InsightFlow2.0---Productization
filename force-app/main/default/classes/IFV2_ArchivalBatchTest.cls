/*******************************************************************************************************
* 
* @ Name    	:   IFV2_ArchivalBatchTest
* @ Purpose 	:   Test class for IFv2_P28Controller
* @ Author  	:   Naga sai/Vivek
* @ Class Name	:	IFv2_ArchivalBatch
*
*   Date        |  Developer Name                   	|  Version      |  Changes
* ======================================================================================================
*   18-03-2019  |  nagasai.chalamalasetti@absyz.com     |  1.0          |  Initial Version
*
*******************************************************************************************************/
@isTest
public class IFV2_ArchivalBatchTest {
    //Test data set up method 
    @testSetup static void createTestData() {
        IFv2_Workflow__c workflowRecord = IFv2_testDataUtility.createWorkflowCustomSetting();
        workflowRecord.ArchivingAfterDays__c = 0;
        Database.SaveResult insertworkflowRecord = Database.insert(workflowRecord);
        LIST<IFv2_Request__c> requestList = IFv2_testDataUtility.createRequest();
        for(IFv2_Request__c request:requestList){
            request.Status__c = 'Approved';
            request.Workflow__c = 'eSignature';
            request.WorkflowId__c = insertworkflowRecord.id;
            request.ArchivalStatus__c = 'Archived';
            request.ContentversionIds__c = '1223;1334;12';
        }
        Database.SaveResult[] saveResultLIST = Database.insert(requestList);
        
    }
    //Archival batch method for Archived status
    public static testmethod void InvokeArchivalBatch() {
        Test.startTest();
        LIST<IFv2_Request__c> requestLIST = [SELECT Id,WorkflowId__c,Workflow__c,lastmodifieddate 
                                             FROM IFv2_Request__c ];
        system.assertEquals(1,requestLIST.size());
        
        SET<Id> workflowId = new SET<Id>();
        IFv2_Workflow__c workflowRecord = IFv2_testDataUtility.createWorkflowCustomSetting();
        workflowRecord.Name = 'Material Gate Pass - Child';
        workflowRecord.Workflow__c = 'Material Gate Pass - Child';
        insert workflowRecord;
        workflowId.add(workflowRecord.Id);
        
        IF(!requestLIST.isEmpty()) {
            database.executeBatch(new IFv2_ArchivalBatch(requestLIST[0].WorkflowId__c,requestLIST[0].Workflow__c,requestLIST[0].lastmodifieddate,workflowId),1);
        }
        Test.stopTest();
    }
    
    // Archival batch method for fail status
    Public static testMethod void  archivalStatusFail(){
        Test.startTest();
        IFv2_Workflow__c workflowRecord = IFv2_testDataUtility.createWorkflowCustomSetting();
        workflowRecord.ArchivingAfterDays__c = 0;
        Database.SaveResult insertworkflowRecord = Database.insert(workflowRecord); 
        
        IFv2_request__c request = new IFv2_Request__c();
        request.Status__c = 'Approved';
        request.Workflow__c = 'eSignature';
        request.WorkflowId__c = insertworkflowRecord.id;
        request.ArchivalStatus__c = 'Fail';
        request.ContentversionIds__c = '1223;1334;12';
        insert request;
        
        SET<Id> workflowId = new SET<Id>();
        IFv2_Workflow__c workflowRecord2 = IFv2_testDataUtility.createWorkflowCustomSetting();
        workflowRecord2.Name = 'China Training Application';
        workflowRecord2.Workflow__c = 'China Training Application';
        insert workflowRecord2;
        workflowId.add(workflowRecord2.Id);
        
        database.executeBatch(new IFv2_ArchivalBatch(request.WorkflowId__c, request.Workflow__c,request.lastmodifieddate,workflowId),1);
        
        LIST<IFv2_request__c> requestLIST = [SELECT Id,ArchivalStatus__c 
                                             FROM IFv2_request__c order by ArchivalStatus__c];
        system.assertEquals('Archived',requestLIST[0].ArchivalStatus__c);
        system.assertEquals('Fail',requestLIST[1].ArchivalStatus__c);
        test.stopTest();
    }
    //Method for Printable view
    public static TestMethod void redirectToPrintableViewMethod() {
        IFv2_PrintableViewController controllerInstance = new IFv2_PrintableViewController();
        LIST<FeedComment> FeedCommentLIST = new LIST<FeedComment>();
        
        LIST<IFv2_Request__c> requestObjectLIST = [SELECT Id,Name 
                                                   FROM IFv2_Request__c LIMIT 1];
        
        FeedItem feedItemRecord = new FeedItem();
        feedItemRecord.ParentId = userInfo.getUserId();
        feedItemRecord.Body = 'Test';
        feedItemRecord.Type = 'ContentPost';
        if(!requestObjectLIST.isEmpty()){
            feedItemRecord.ParentId =  requestObjectLIST[0].Id; 
        }
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test data';
        contentVersion.PathOnClient = 'test.jpg';
        contentVersion.VersionData = Blob.valueOf('Test Content data');
        contentVersion.IsMajorVersion = true;
        insert contentVersion;
        
        LIST<ContentDocument> ContentDocumentLIST = [SELECT Id, Title, LatestPublishedVersionId 
                                                     FROM ContentDocument];
        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = New ContentDocumentLink();
        if(requestObjectLIST[0] != NULL)
            cdl.LinkedEntityId = requestObjectLIST[0].Id;
        if(ContentDocumentLIST[0] != NULL)
            cdl.ContentDocumentId = ContentDocumentLIST[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        LIST<sobject> OldApprovalList = new LIST<sObject>();
        Account Acc = new Account();
        Acc.IFv2_ContentType__c = 'Approval History';
        Acc.Name = 'OldApproval';
        Acc.IFv2_LegacyComments__c = 'testing';
        Acc.IFv2_LegacyStatus__c = 'Approved';
        
        insert Acc;
        OldApprovalList.add([select id,createddate,IFv2_LegacyStatus__c,IFv2_LegacyComments__c,IFv2_LegacyAssignedTo__c,IFv2_LegacyActualApprover__c,IFv2_StepName__c,IFv2_Legacysubmitter__c,LastModifiedById,LastModifiedDate from Account limit 1]);
        IFv2_printableviewController.OldApprovalRecords = OldApprovalList;
        controllerInstance.getOldApprovalRelatedList();
        IFv2_ParseRequestToXMLANDPDF.generateXMLANDPDF(requestObjectLIST[0]);
        system.assertEquals(IFv2_printableviewController.OldApprovalRecords[0].Id,OldApprovalList[0].Id);
    }
      // Archival batch method for null status
    Public static testMethod void  archivalStatusNone(){
        Test.startTest();
        IFv2_Workflow__c workflowRecord = IFv2_testDataUtility.createWorkflowCustomSetting();
        workflowRecord.ArchivingAfterDays__c = 0;
        Database.SaveResult insertworkflowRecord = Database.insert(workflowRecord); 
        
        IFv2_request__c request = new IFv2_Request__c();
        request.Status__c = 'Approved';
        request.Workflow__c = 'eSignature';
        request.WorkflowId__c = insertworkflowRecord.id;
      //  request.ArchivalStatus__c = 'Fail';
       // request.ContentversionIds__c = '1223;1334;12';
        insert request;
        
        SET<Id> workflowId = new SET<Id>();
       /* IFv2_Workflow__c workflowRecord2 = IFv2_testDataUtility.createWorkflowCustomSetting();
        workflowRecord2.Name = 'China Training Application';
        workflowRecord2.Workflow__c = 'China Training Application';
        workflowRecord2.ArchivingAfterDays__c =0;
        insert workflowRecord2;*/
        workflowId.add(insertworkflowRecord.Id);
         LIST<IFv2_Workflow__c> workflows = [SELECT id, ArchivingAfterDays__c,Workflow__c FROM IFv2_Workflow__c where  Active__c =True limit 1];
        SET<Id> workflowids = new SET<Id>();
        //The logic is to have a set which stores processed workflow ids and use that set as a filter to query
        for(IFv2_Workflow__c workflow:workflows){
            workflowids.add(workflow.id);
            //calculating approximate last modfied date using archival date on workflow and checking that this variable
            //should be equal or greater than lastmodifieddate on request record**/
            Datetime Todaysdate = datetime.now();
            //checking for null
            if(workflow.ArchivingAfterDays__c!=Null){
                Datetime ApproxLastModifiedDate = Todaysdate.adddays(-(integer)workflow.ArchivingAfterDays__c);
                IFV2_ArchivalBatch archivalBatch = new IFV2_ArchivalBatch(workflow.id,workflow.Workflow__c,ApproxLastModifiedDate,workflowids);
                //Batch size should be one  
                database.executebatch(archivalBatch,1);
            }
        }
        //database.executeBatch(new IFv2_ArchivalBatch(request.WorkflowId__c,request.lastmodifieddate,workflowId),1);
        
        LIST<IFv2_request__c> requestLIST = [SELECT Id,ArchivalStatus__c 
                                             FROM IFv2_request__c order by ArchivalStatus__c];
         system.assertEquals('Archived',requestLIST[1].ArchivalStatus__c);
        test.stopTest();
    }
 
}