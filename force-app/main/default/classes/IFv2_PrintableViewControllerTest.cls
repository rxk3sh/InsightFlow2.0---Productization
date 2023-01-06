/*******************************************************************************************************
* 
* @ Name 			: IFv2_PrintableViewControllerTest
* @ Purpose 		: Test class for IFv2_PrintableViewController
* @ Author			: Prasad Vivek
* @ Class Name      : IFv2_PrintableViewController 
*
*   Date            |  Developer Name                 |  Version     |  Changes
* ======================================================================================================
*   02-05-2019      |  vivek.kothalanka@absyz.com	  |  1.1         |  Initial version
*
*******************************************************************************************************/
@isTest
public class IFv2_PrintableViewControllerTest {
    
    public static list<IFv2_Request__c> lstsObject = new list<IFv2_Request__c>();
    public static IFv2_Workflow__c lstWF;
    public static contact objCon;
    public static Account objAcc;
    public static User objUser;
    @testsetup static void createTestData() {
        objAcc = IFv2_testDataUtility.createAccount();
        objAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Internal').getRecordTypeId();
        insert objAcc;
        
        objCon = IFv2_testDataUtility.createContact(objAcc);
        insert objCon;
        
        objUser = IFv2_testDataUtility.createUser();
        objUser.IFv2_ByPassValidation__c = true;
        insert objUser;
        
        system.runAs(objUser)
        {
            lstWF =   IFv2_testDataUtility.createWorkflowCustomSetting();
            IFv2_Request__c req = new IFv2_Request__c();
            req.Workflow__c = 'Esignature';
            req.Status__c ='Draft';
            lstsObject.add(req);
            insert lstsObject ;
        }
        
        objUser.IFv2_ByPassValidation__c = false;
        update objUser; 
    }
    
    @TestVisible private static IFv2_Section__mdt getRecordMetadata(){
        IFv2_Section__mdt RecordMetadata = [
            select id,Name__c,ReadOnly__c, SectionNumber__c, Type__c, Workflows__c, Value__c
            from IFv2_Section__mdt limit 1
        ];
        
        return RecordMetadata;
    }
    
    public static TestMethod void redirectToPrintableViewMethod() {
        IFv2_PrintableViewController controllerInstance = new IFv2_PrintableViewController();
        LIST<FeedComment> FeedCommentLIST = new LIST<FeedComment>();
        
        
        LIST<IFv2_Request__c> requestObjectLIST = [SELECT Id 
                                                   FROM IFv2_Request__c LIMIT 1];
        system.assertEquals(1,requestObjectLIST.size());
        
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
        Attachment file = new Attachment();
        file.Name='test';
        file.body=     Blob.valueOf('Test Content data');
        file.ParentId=requestObjectLIST[0].Id;
        insert file;
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
        Account accountRecord = new Account();
        accountRecord.Name = 'Approval History' ;
        accountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Items').getRecordTypeId();
        accountRecord.IFv2_ContentType__c = 'Approval History';
        // accountRecord.IFv2_Legacysubmitter__c = objUser.id;
        //accountRecord.IFv2_LegacyActualApprover__c = objUser.id;
        //accountRecord.IFv2_LegacyAssignedTo__c = objUser.id;
        accountRecord.IFv2_LegacyStatus__c = 'Recalled';
        
        
        accountRecord.IFv2_LegacyComments__c = 'test';
        accountRecord.IFv2_Request__c =requestObjectLIST[0].id ;
        
        accountRecord.IFv2_StepName__c = 'Approval Request Submitted';
        
        
        insert accountRecord;
        FeedComment feed=new FeedComment();
        feed.CommentBody='<p>we must introspect on the reasons for declined COQs.</p>';
        feed.CommentType='TextComment';
        feed.createddate=system.today();
        feed.CreatedBy=objUser;
       // feed.FeedItemId= feedItemRecord.Id;
        //insert feed;
        FeedCommentLIST.add(feed);
        IFv2_printableviewController.chatterparentId =  requestObjectLIST[0].Id;
        IFv2_printableviewController.getchatterRelatedList();
        controllerInstance.getOldApprovalRelatedList();
        String returnValue = IFv2_printableviewController.getChatterComments(FeedCommentLIST);
        IFv2_printableviewController.getContentVersions();
        
    }
    
    
    public static testmethod void printableviewtest(){
        test.startTest();
        
        Account testAccount = new Account();
        testAccount.name = 'test';
        testAccount.CreatedDate=system.today();
        testAccount.IFv2_FromDate__c=system.today();
        //testAccount.IFv2_ShortDescription__c = 'Test Description';
        insert testAccount;
        IFv2_Request__c r = new IFv2_Request__c();
        r.Status__c = 'Draft';
        r.Workflow__c = 'eSignature';
        r.Account__c = testAccount.Id;
        //r.LastReferencedDate = system.today();
       // r.PlannedDate__c = '2021-03-16';
        r.CreatedDate=system.today();
        insert r;
        Account testAccount1 = new Account();
        testAccount1.name = 'test2';
        testAccount1.IFv2_ContentType__c='Employee';
        testAccount1.recordtypeid=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Items').getRecordTypeId();
        testAccount1.IFv2_Request__c=r.id;
        
        insert testAccount1;
        Approval.ProcessSubmitRequest requestitem = new Approval.ProcessSubmitRequest();
        //set the target objcet as request 
        requestitem.setObjectId(r.id);
        //pass user id which will be coming from approval process
        requestitem.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        //set comments 
        requestitem.setComments('Submitted for approval. Please approve.');
        //submit the approval process
        Approval.ProcessResult result = Approval.process(requestitem);
        system.assertEquals('Pending', (String)result.getInstanceStatus());
        ApexPages.currentPage().getParameters().put('id',r.id);
        IFv2_PrintableViewController objPrintableView = new IFv2_PrintableViewController();
        
        IFv2_Request__c req = IFv2_PrintableViewController.getRecord('IFv2_Request__c',r.id);
        system.assertEquals(req.Id,r.id);
        objPrintableView.getApprovalRelatedList();
        
        IFv2_RequestExtension1__c extension = new IFv2_RequestExtension1__c();
        extension.TotalPlannedDuration__c = 6;
        extension.PlannedEndDateTime__c =  datetime.newInstance(2019, 9, 17, 12, 30, 0);
        extension.PlannedStartDateTime__c =  datetime.newInstance(2019, 9, 16, 12, 30, 0);
        insert extension;
        r.Workflow__c = 'China Training Application';
        r.RequestExtension1__c = extension.Id;
        update r;
        IFv2_Request__c req1 = IFv2_PrintableViewController.getRecord('IFv2_Request__c',r.id);
        system.assertEquals(req1.Id,r.id);
        objPrintableView.getApprovalRelatedList();
        
        test.stopTest();
        
    }
    
    public static testmethod void printableviewtestM1(){
        test.startTest();
        
        Account testAccount = new Account();
        testAccount.name = 'test';
        testAccount.CreatedDate=system.today();
        testAccount.IFv2_FromDate__c=system.today();
        //testAccount.IFv2_ShortDescription__c = 'Test Description';
        insert testAccount;
        IFv2_RequestExtension1__c extension = new IFv2_RequestExtension1__c();
        extension.TotalPlannedDuration__c = 6;
        extension.PlannedEndDateTime__c =  datetime.newInstance(2019, 9, 17, 12, 30, 0);
        extension.PlannedStartDateTime__c =  datetime.newInstance(2019, 9, 16, 12, 30, 0);
        insert extension;
        IFv2_Request__c r = new IFv2_Request__c();
        r.Status__c = 'Draft';
        r.Workflow__c = 'China Training Application';
        r.RequestExtension1__c = extension.Id;
        r.Account__c = testAccount.Id;
        //r.LastReferencedDate = system.today();
       // r.PlannedDate__c = '2021-03-16';
        r.CreatedDate=system.today();
        insert r;
        Account testAccount1 = new Account();
        testAccount1.name = 'test2';
        testAccount1.IFv2_ContentType__c='Employee';
        testAccount1.recordtypeid=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Items').getRecordTypeId();
        testAccount1.IFv2_Request__c=r.id;
        
        insert testAccount1;
        Approval.ProcessSubmitRequest requestitem = new Approval.ProcessSubmitRequest();
        //set the target objcet as request 
        requestitem.setObjectId(r.id);
        //pass user id which will be coming from approval process
        requestitem.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        //set comments 
        requestitem.setComments('Submitted for approval. Please approve.');
        //submit the approval process
        Approval.ProcessResult result = Approval.process(requestitem);
       // system.assertEquals('Pending', (String)result.getInstanceStatus());
        ApexPages.currentPage().getParameters().put('id',r.id);
        IFv2_PrintableViewController objPrintableView = new IFv2_PrintableViewController();
        
        IFv2_Request__c req = IFv2_PrintableViewController.getRecord('IFv2_Request__c',r.id);
        system.assertEquals(req.Id,r.id);
        objPrintableView.getApprovalRelatedList();
        
        
       // r.Workflow__c = 'China Training Application';
        //r.RequestExtension1__c = extension.Id;
        //update r;
       // IFv2_Request__c req1 = IFv2_PrintableViewController.getRecord('IFv2_Request__c',r.id);
       // system.assertEquals(req1.Id,r.id);
       // objPrintableView.getApprovalRelatedList();
        
        test.stopTest();
        
    }
    
    
    public static testmethod void printableviewtestMethod2(){
        
        test.startTest();
        Account testAccount = new Account();
        testAccount.name = 'test';
        insert testAccount;
        
        RecordType objRecordType = [SELECT id,Name FROM RecordType WHERE SobjectType = 'Account' and Name = 'Request Items' Limit 1]; 
        objUser = [select id,name from User limit 1];
        /*commented for cleaning up of Insightflow 1.0 components
Workflow__c oldWorkflow = IFv2_testDataUtility.createOldWorkflow();
insert oldWorkflow;
Request_EMEA__c oldRequest = IFv2_testDataUtility.createRequestEMEA(oldWorkflow, objUser);
insert oldRequest; */
        IFv2_Request__c objReq = [select id,name,oldrequest__c,status__c from IFv2_Request__c limit 1];
        // objReq.OldRequest__c = oldRequest.Id;
        objReq.Account__c = testAccount.Id;
        update objReq;
        objAcc = [select id,name,IFv2_ContentType__c,IFv2_ChinaMAE__c,IFv2_PersonnelNo__c,IFv2_LegacyAssignedTo__c,IFv2_LegacyActualApprover__c,IFv2_Legacysubmitter__c from Account limit 1];
        
        Account accountForContact = new Account();
        accountForContact.Name = 'Account for Contact';
        accountForContact.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Internal').getRecordTypeId();
        insert accountForContact;
        objCon = IFv2_testDataUtility.createContact(accountForContact);
        insert objCon;
        
        objAcc.IFv2_ContentType__c = 'Approval History';
        objAcc.RecordtypeId = objRecordType.id;
        objAcc.IFv2_Request__c = objReq.id;
        objAcc.IFv2_ChinaMAE__c = 'test';
        objAcc.IFv2_PersonnelNo__c = objCon.id;
        
        objAcc.IFv2_LegacyAssignedTo__c = string.valueOf(objUser.Id);
        objAcc.IFv2_LegacyActualApprover__c = string.valueOf(objUser.Id);
        objAcc.IFv2_Legacysubmitter__c = string.valueOf(objUser.Id); 
        
        update objAcc;
        
        system.assertEquals(objAcc.IFv2_LegacyAssignedTo__c,string.valueOf(objUser.Id));
        
        Approval.ProcessSubmitRequest requestitem = new Approval.ProcessSubmitRequest();
        //set the target objcet as request 
        requestitem.setObjectId(objReq.id);
        //pass user id which will be coming from approval process
        requestitem.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        //set comments 
        requestitem.setComments('Submitted for approval. Please approve.');
        //submit the approval process
        Approval.ProcessResult result = Approval.process(requestitem);
        system.assertEquals('Pending', result.getInstanceStatus());
        apexpages.StandardController sc = new ApexPages.StandardController(objReq);
        
        IFv2_PrintableViewController v=new IFv2_PrintableViewController(sc);
        v.getOldApprovalRelatedList();
        test.stopTest();
    }
    
    public static testmethod void printableviewtestMethod3(){
        
        test.startTest();
        
        Account testAccount = new Account();
        testAccount.name = 'test';
        insert testAccount;
        IFv2_Request__c r = new IFv2_Request__c();
        r.Status__c = 'Draft';
        r.Workflow__c = 'eSignature';
        r.Account__c = testAccount.Id;
        insert r;
        
        // Create an approval request instance
        Approval.ProcessSubmitRequest requestitem = new Approval.ProcessSubmitRequest();
        //set the target objcet as request 
        requestitem.setObjectId(r.id);
        //pass user id which will be coming from approval process
        requestitem.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        //set comments 
        requestitem.setComments('Submitted for approval. Please approve.');
        //submit the approval process
        Approval.ProcessResult result = Approval.process(requestitem);
        apexpages.StandardController sc = new ApexPages.StandardController(r);
        
        IFv2_PrintableViewController v=new IFv2_PrintableViewController(sc);
        // v.getApprovalRelatedList();
        IFv2_RelatedListsController.RelatedList Approvalhistory = IFv2_RelatedListsController.completeRelatedList(r.id,'ProcessInstance');
        system.assertEquals(label.CLIFv20035,Approvalhistory.columnLabels);
        test.stopTest();
        
    }
    
    public static testmethod void printableviewtest4(){
        test.startTest();
        
        Account testAccount = new Account();
        testAccount.name = 'test';
        insert testAccount;
        IFv2_Request__c r = new IFv2_Request__c();
        r.Status__c = 'Draft';
        r.Workflow__c = 'China Training Application';
        r.Account__c = testAccount.Id;
        insert r;
        Account testAccount1 = new Account();
        testAccount1.name = 'test2';
        testAccount1.IFv2_ContentType__c='Employee';
        testAccount1.recordtypeid=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Items').getRecordTypeId();
        testAccount1.IFv2_Request__c=r.id;
        
        insert testAccount1;
        Approval.ProcessSubmitRequest requestitem = new Approval.ProcessSubmitRequest();
        //set the target objcet as request 
        requestitem.setObjectId(r.id);
        //pass user id which will be coming from approval process
        requestitem.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        //set comments 
        requestitem.setComments('Submitted for approval. Please approve.');
        //submit the approval process
        Approval.ProcessResult result = Approval.process(requestitem);
        system.assertEquals('Rejected', result.getInstanceStatus());
        
        ApexPages.currentPage().getParameters().put('id',r.id);
        IFv2_PrintableViewController objPrintableView = new IFv2_PrintableViewController();
        
        IFv2_Request__c req = IFv2_PrintableViewController.getRecord('IFv2_Request__c',r.id);
        System.assertEquals(req.Id,r.id);
        objPrintableView.getApprovalRelatedList();
        test.stopTest();
    }
}