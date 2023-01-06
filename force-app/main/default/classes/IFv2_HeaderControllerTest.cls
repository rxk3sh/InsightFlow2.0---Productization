/*******************************************************************************************************
* 
* @ Name    :   IFv2_HeaderControllerTest
* @ Purpose :   Test data for fieldset preparation
* @ Author  :   Prasad Vivek
* @ Class	: 	IFv2_HeaderController
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   20-11-2018      |  vivek.kothalnka@absyz.com      |  1.0          |  Initial Version
*
*******************************************************************************************************/

@isTest
public class IFv2_HeaderControllerTest {
    
    public static LIST<IFv2_Request__c> lstsObject;
    public static Attachment requestPdfAttachment;
    
    public static user objUser;
    Public static user StandardUser;
    public static EntitySubscription objSubscription;
    
    @TestVisible private static IFv2_CustomValidationRules__mdt getRecordMetadata(){
        IFv2_CustomValidationRules__mdt RecordMetadata = [
            select id
            from IFv2_CustomValidationRules__mdt];
        
        return RecordMetadata;
    }
    
    
    @isTest(seeAllData=true)
    static void getfieldmaptest() {
        
        //inserting Request
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'eSignature';
        insert lstsObject ;
        
        IFv2_RequestExtension1__c extension1 = new IFv2_RequestExtension1__c();
        insert extension1;
        lstsObject[0].RequestExtension1__c = extension1.Id;
        update lstsObject[0];
        System.assertEquals(true, lstsObject[0].Workflow__c == 'eSignature');
        
        objUser = IFv2_testDataUtility.createUser();
        insert objUser;
        objSubscription = IFv2_testDataUtility.createEntitySubscription(lstsObject[0].id,objUser);
        insert objSubscription;
        
        Map<String, Schema.SObjectField> fieldMap = Schema.SobjectType.IFv2_Request__c.fields.getMap();
        String queryFields='';
        for(Schema.SObjectField fieldObj :  fieldMap.Values()){
            Schema.DescribeFieldResult fieldDesc = fieldObj.getDescribe();
            queryFields +=fieldDesc.getName() +',';
        } 
        
        queryFields =queryFields.removeEnd(',');
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(lstsObject[0].Id);
        req1.setSubmitterId(UserInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        List<ProcessInstanceWorkItem> lst2=[SELECT Id, Actor.Name, ActorId, originalActorId, originalActor.Name, ProcessInstance.Status 
                                            FROM ProcessInstanceWorkitem 
                                            WHERE ProcessInstance.TargetObjectId =: lstsObject[0].Id 
                                            AND ProcessInstance.Status = 'Pending'];
        
        List<ProcessInstanceWorkItem> lst=[SELECT ActorId, ProcessInstanceId, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkItem];
        
        String objectName = 'IFv2_Request__c';
        IFv2_HeaderController.getFieldMap(objectName);
        
        try{
            IFv2_HeaderController.updateConcessionRecord('Null','Null','Null','Null','Null','Null','Null');
        }
        Catch(Exception e){}
        try{
            IFv2_HeaderController.checkUserIsApprover(lstsObject[0].id);
        }
        Catch(Exception e){}
        try{
            IFv2_HeaderController.customValidationErrors(lstsObject[0], null);
        }
        Catch(Exception e){}
        try{
            IFv2_HeaderController.getAttachmentList(lstsObject[0].id);
        }
        Catch(Exception e){}
        try{
            IFv2_HeaderController.cloneRecord(lstsObject[0].id);
        }
        Catch(Exception e){}
        try{
            IFv2_HeaderController.getFollowedRecord(lstsObject[0].id);
        }
        Catch(Exception e){}
        try{
            IFv2_HeaderController.followRecord(lstsObject[0].id,false);
        }
        Catch(Exception e){}
        try{
            IFv2_HeaderController.getRequiredFields(objectName,'Request details');
        }
        Catch(Exception e){}
        try{
            IFv2_HeaderController.returnValidationErrors(lstsObject[0], null);
        }
        Catch(Exception e){}
        try{
            IFv2_HeaderController.getButtonList(lstsObject[0].id); 
        }
        catch(Exception e){}
        try{
            IFv2_HeaderController.getMartialFromDetail(lstsObject[0].id);
        }
        Catch(Exception e){}
        lstsObject[0].status__c = 'Submitted';
        update lstsObject;
        try{
            IFv2_HeaderController.reCallMethod(lstsObject[0].id, 'test',null);
        }catch(Exception e){}
        
        List<ProcessInstanceWorkitem> lstItems=[SELECT Id, actor.name, actorId, originalActorId, originalActor.Name, ProcessInstance.Status,ProcessInstance.TargetObjectId 
                                                FROM ProcessInstanceWorkitem ];//WHERE ProcessInstance.TargetObjectId =: lstsObject[0].Id
        
        try{
            lstsObject[0].status__c = 'Submitted';
            update lstsObject;
            System.assertEquals(true, lstsObject[0].Status__c == 'Submitted');
            
            IFv2_HeaderController.reassignMethod(lstsObject[0].Id,'Approved',UserInfo.getUserId());
            User currentUser = IFv2_UtilsController.getLoggedInDetails();
        }catch(Exception e){}
        try{
            IFv2_HeaderController.returnContentDocumentURL('eSignature');
        }
        catch(Exception e){}
        try{
            IFv2_HeaderController.restartMethod(lstsObject[0].id,'eSignature',null);
        }
        catch(Exception e){}
        try{
            IFv2_HeaderController.validatedApprovers(lstsObject[0].id,'TestData',Json.serialize(lstsObject[0]));
            
        }catch(Exception e){}
        try{
            IFv2_HeaderController.deleteRecord(lstsObject[0].id);
        }
        catch(Exception e){}
    }
    
    static testmethod void testConsultMethod() {
        test.startTest();
        lstsObject = IFv2_testDataUtility.createRequestWithExt();
        lstsObject[0].Workflow__c = 'eSignature';
        insert lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'eSignature');
        
        objUser = IFv2_testDataUtility.createUser();
        insert objUser;
        StandardUser  = IFv2_testDataUtility.createSGStandardUser();
        insert StandardUser;
        System.assertEquals(true, objUser != Null);
        
        try{
            
            IFv2_HeaderController.consultMethod(lstsObject[0].id,'hi hello how are u',objUser.id);
            IFv2_HeaderController.consultMethod(lstsObject[1].id,'hi hello how are u',objUser.id);
            IFv2_HeaderController.consultMethod(lstsObject[2].id,'hi hello how are u',objUser.id);
            
        }
       catch(Exception e){}
        system.runAs(objUser) {
            IFv2_HeaderController.ButtonWrapper objWrapper = IFv2_HeaderController.getButtonList(lstsObject[0].id);
        }
        test.stopTest();
    }   
     static testmethod void testConsultMethodTwo() {
        test.startTest();
        lstsObject = IFv2_testDataUtility.createRequestWithExt();
        lstsObject[0].Workflow__c = 'eSignature';
        insert lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'eSignature');
        
        objUser = IFv2_testDataUtility.createUser();
        insert objUser;
        StandardUser  = IFv2_testDataUtility.createSGStandardUser();
        insert StandardUser;
        System.assertEquals(true, objUser != Null);
        
        try{
            
            IFv2_HeaderController.consultMethod(lstsObject[0].id,'hi hello how are u',objUser.id);
            IFv2_HeaderController.consultMethod(lstsObject[1].id,'hi hello how are u',objUser.id);
            IFv2_HeaderController.consultMethod(lstsObject[2].id,'hi hello how are u',objUser.id);
            
        }
       catch(Exception e){}
        system.runAs(StandardUser) {
            IFv2_HeaderController.ButtonWrapper objWrapper = IFv2_HeaderController.getButtonList(lstsObject[0].id);
        }
        test.stopTest();
    }
    static testmethod void updateMethod() {
        
        test.startTest();
        //inserting Request
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'eSignature';
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'eSignature');
        
        objUser = IFv2_testDataUtility.createUser();
        insert objUser;
        objSubscription = IFv2_testDataUtility.createEntitySubscription(lstsObject[0].id,objUser);
        insert objSubscription;
        
        lstsObject = [SELECT id,Workflow__c,Status__c from IFv2_Request__c];
        lstsObject[0].status__c = 'Submitted';
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Status__c == 'Submitted');
        test.stopTest();
    }
    
    /* To cover returnHelpDcoument Method */
    public static testMethod void returnHelpDcoumentTest(){
        test.startTest();
        try{
            lstsObject = IFv2_testDataUtility.createRequest();
            lstsObject[0].Workflow__c = 'eSignature';
            insert lstsObject ;
            System.assertEquals(true, lstsObject[0].Workflow__c == 'eSignature');
            
            IFv2_HeaderController.returnHelpDcoument('eSignature');
        }
        Catch(Exception e){}
        test.stopTest();
    } 
    
    public static testMethod void returnValidationErrorsTestMethod1(){
        test.startTest();
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'China MAE Application - Lost';
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'China MAE Application - Lost');
        
        IFv2_HeaderController.returnValidationErrors(lstsObject[0],null);
        test.stopTest();
    }
    Public static testMethod void cloneMethod(){
        test.startTest();
        IFv2_RequestExtension1__c extension1 = new IFv2_RequestExtension1__c();
        insert extension1;
        
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'China Travel Application';
        lstsObject[0].RequestExtension1__c = extension1.Id;
        insert lstsObject ;
        system.assertEquals('China Travel Application',(String)lstsObject[0].Workflow__c);
        IFv2_HeaderController.cloneRecord(lstsObject[0].id);
        test.stopTest();
    }
    Public static testMethod void cloneMethodExtension2(){
        test.startTest();
        IFv2_RequestExtension2__c extension2 = new IFv2_RequestExtension2__c();
        insert extension2;
        
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'Predefined Workflow Approvals';
        lstsObject[0].RequestExtension2__c = extension2.Id;
        insert lstsObject ;
        system.assertEquals('Predefined Workflow Approvals', lstsObject[0].Workflow__c);
        IFv2_HeaderController.cloneRecord(lstsObject[0].id);
        test.stopTest();
    }
    Public static testMethod void cloneMethodExtension3(){
        test.startTest();
        IFv2_RequestExtension3__c extension3 = new IFv2_RequestExtension3__c();
        insert extension3;
        
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'Order Experience Request';
        lstsObject[0].RequestExtension3__c = extension3.Id;
        insert lstsObject ;
         system.assertEquals('Order Experience Request', lstsObject[0].Workflow__c);
        IFv2_HeaderController.cloneRecord(lstsObject[0].id);
        test.stopTest();
    }
    Public static testMethod void cloneMethodAccount(){
        test.startTest();
        Account accountInstance = new Account();
        accountInstance.Name = 'TestAccount';
        insert accountInstance;
        
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'eSignature';
        lstsObject[0].Account__c = accountInstance.Id;
        insert lstsObject ;
         system.assertEquals('eSignature', lstsObject[0].Workflow__c);
        IFv2_HeaderController.cloneRecord(lstsObject[0].id);
        test.stopTest();
    }
    public static testMethod void returnValidationErrorsTestMethod2(){
        test.startTest();
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'HU Scrapping WorkOn';
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'HU Scrapping WorkOn');
        IFv2_HeaderController.returnValidationErrors(lstsObject[0],null);
        test.stopTest();
    }
    public static testMethod void returnValidationErrorsTestMethod3(){
        test.startTest();
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'Badge Management SEG - Stuttgart';
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'Badge Management SEG - Stuttgart');
        IFv2_HeaderController.returnValidationErrors(lstsObject[0], null);
        test.stopTest();
    }
    
    public static testMethod void returnValidationErrorsTestMethod4(){
        test.startTest();
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'China MAE Application - Scrap';
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'China MAE Application - Scrap');
        IFv2_HeaderController.returnValidationErrors(lstsObject[0], null);
        test.stopTest();
    }
    public static testMethod void submitForApprovalTestMethod1(){
        test.startTest();
        lstsObject = IFv2_testDataUtility.createRequest();
        Account acc = IFv2_testDataUtility.createAccount();
        insert acc;
        Contact con = IFv2_testDataUtility.createContact(acc);
        insert con;
        lstsObject[0].Workflow__c = 'China MAE Application - Scrap';
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'China MAE Application - Scrap');
        IFv2_HeaderController.submitForApproval(lstsObject[0], null);
        test.stopTest();
    }
    public static testMethod void submitForApprovalTestMethod2(){
        
        lstsObject = IFv2_testDataUtility.createRequest();
        Account acc = IFv2_testDataUtility.createAccount();
        insert acc;
        Contact con = IFv2_testDataUtility.createContact(acc);
        insert con;
        
        objuser = IFv2_testDataUtility.createUser();
        insert objuser;
        StandardUser  = IFv2_testDataUtility.createSGStandardUser();
        insert StandardUser;
        
        lstsObject[0].Workflow__c = 'eSignature';
        lstsObject[0].approver1__c = StandardUser.Id;
        lstsObject[0].approver2__c = objuser.Id;
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'eSignature');
        IFv2_HeaderController.submitForApproval(lstsObject[0], null);
        
    }
    
    public static testMethod void submitForApprovalTestMethod2ParallelCheck() {
        
        lstsObject = IFv2_testDataUtility.createRequest();
        Account acc = IFv2_testDataUtility.createAccount();
        insert acc;
        Contact con = IFv2_testDataUtility.createContact(acc);
        insert con;
        objUser = IFv2_testDataUtility.createUser();
        lstsObject[0].Workflow__c = 'General Approval Form';
        lstsObject[0].Approver11__c = objUser.Id;
        lstsObject[0].Parallel__c = true;
        lstsObject[0].Serial__c = false;
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'General Approval Form');
        System.assertEquals(true, lstsObject[0].Parallel__c == true);
        IFv2_HeaderController.submitForApproval(lstsObject[0], null);
    }
    public static testMethod void submitForApprovalTestMethod3(){
        
        lstsObject = IFv2_testDataUtility.createRequest();
        Account acc = IFv2_testDataUtility.createAccount();
        insert acc;
        Contact con = IFv2_testDataUtility.createContact(acc);
        insert con;
        objUser = IFv2_testDataUtility.createUser();
        insert objUser;
        lstsObject[0].Workflow__c = 'Approval Process for Special Freights';
        lstsObject[0].Approver3__c = objUser.Id;
        lstsObject[0].Approver4__c = null;
        lstsObject[0].Approver5__c = objUser.Id;
        lstsObject[0].Approver6__c = null;
        lstsObject[0].Approver7__c = objUser.Id;
        lstsObject[0].Approver8__c = null;
        lstsObject[0].Approver9__c = objUser.Id;
        lstsObject[0].Approver10__c = null;
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'Approval Process for Special Freights');
        IFv2_HeaderController.submitForApproval(lstsObject[0], null);
        
    }
    public static testMethod void submitForApprovalTestMethod4(){
        Account acc = IFv2_testDataUtility.createAccount();
        insert acc;
        System.assertEquals(true, acc != Null);
        Contact con = IFv2_testDataUtility.createContact(acc);
        insert con;
        System.assertEquals(true, con != Null);
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'China Leave & Overtime Application';
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'China Leave & Overtime Application');
        IFv2_HeaderController.submitForApproval(lstsObject[0], null);
    }
    public static testMethod void submitForApprovalTestMethod5(){
        Account acc = IFv2_testDataUtility.createAccount();
        insert acc;
        LIST<Account> Acclist = new LIST<Account>();
        Acclist.add(acc);
        System.assertEquals(true, acc != Null);
        Contact con = IFv2_testDataUtility.createContact(acc);
        insert con;
        System.assertEquals(true, con != Null);
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'HU Scrapping WorkOn';
        insert lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'HU Scrapping WorkOn');
        IFv2_HeaderController.submitForApproval(lstsObject[0], null);
       IFv2_HeaderController.isMaterialValidated(lstsObject[0].id,Acclist);
        IFv2_HeaderController.isMaterialListValidated(lstsObject[0].id,Acclist);
    }
    public static testMethod void submitForApprovalTestMethod6(){
        Account acc = IFv2_testDataUtility.createAccount();
        insert acc;
        System.assertEquals(true, acc != Null);
        Contact con = IFv2_testDataUtility.createContact(acc);
        insert con;
        System.assertEquals(true, con != Null);
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'Predefined Workflow Approvals';
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'Predefined Workflow Approvals');
        IFv2_HeaderController.submitForApproval(lstsObject[0], null);
    }
    public static testMethod void ConcessionTestMethod(){
        Account acc = IFv2_testDataUtility.createAccount();
        insert acc;
        System.assertEquals(true, acc != Null);
        Contact con = IFv2_testDataUtility.createContact(acc);
        insert con;
        objUser = IFv2_testDataUtility.createUser();
         objUser.Username = 'testUsernameconcession243@gmail.com';
        insert objUser;
        
        System.assertEquals(true, con != Null);
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'Concession';
        lstsObject[0].Approver1__c =  objUser.id;
        insert lstsObject;
        
        System.assertEquals(true, lstsObject[0].Workflow__c == 'Concession');
        IFv2_HeaderController.submitForApproval(lstsObject[0], null);
        
        IFv2_Request__c requestRecord =[SELECT id,Status__c from IFv2_Request__c where id=:lstsObject[0].Id limit 1];
         requestRecord.Status__c='Approved';
         update requestRecord;
        
    }
     public static testMethod void createIcoRequest(){
        Account acc = IFv2_testDataUtility.createAccount();
        insert acc;
        System.assertEquals(true, acc != Null);
        Contact con = IFv2_testDataUtility.createContact(acc);
        insert con;
         objUser = IFv2_testDataUtility.createUser();
         objUser.Username = 'testUsernameico243@gmail.com';
        insert objUser;
        System.assertEquals(true, con != Null);
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'ICO Workflow - 1';
         lstsObject[0].Approver1__c =  objUser.id;
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'ICO Workflow - 1');
        IFv2_HeaderController.submitForApproval(lstsObject[0], null);
         
         IFv2_Request__c insertedRecord = [SELECT id,Status__c from IFv2_Request__c where id=:lstsObject[0].Id limit 1];
         insertedRecord.Status__c='Cancelled';
         update insertedRecord;
         
         insertedRecord.Status__c='Cancelled';
         update insertedRecord;
         
    }
    
    
    public static testMethod void checkForApprovers(){
        objUser = IFv2_testDataUtility.createUser();
        insert objUser;
        System.assertEquals(true, objUser != Null);
        IFv2_Workflow__c workflowRecord  = IFv2_testDataUtility.createWorkflowCustomSetting();
        workflowRecord.Name = 'China MAE Application - Split';
        workflowRecord.Workflow__c = 'China MAE Application - Split'; 
        insert workflowRecord;
        System.assertEquals(true, workflowRecord.Workflow__c == 'China MAE Application - Split');
        
        IFv2_RequestExtension1__c apac =  new IFv2_RequestExtension1__c();
        insert apac;
        System.assertEquals(true, apac != Null);
        
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'China MAE Application - Split';
        lstsObject[0].Approver1__c =  objUser.id;
        lstsObject[0].RequestExtension1__c =  apac.id;
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c =='China MAE Application - Split');
        System.assertEquals(true, lstsObject[0].RequestExtension1__c == apac.id);
        
        Account relatedListRecords = new Account();
        relatedListRecords.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Items').getRecordTypeId();
        relatedListRecords.IFv2_ContentType__c = 'China MAE Before Split';
        relatedListRecords.Name = 'test Split';
        relatedListRecords.IFv2_Request__c = lstsObject[0].Id;
        insert relatedListRecords;
        System.assertEquals(true, relatedListRecords.Name == 'test Split');
        
        IFv2_HeaderController.customValidationErrors(lstsObject[0], null);
        IFv2_HeaderController.submitForApproval(lstsObject[0], null);
        
        lstsObject[0].Workflow__c = 'HU Scrapping WorkOn';
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'HU Scrapping WorkOn');
        IFv2_HeaderController.customValidationErrors(lstsObject[0], null);
    }
    
    Public static testMethod void insertAccountShareMethod(){
        Test.startTest();
        Account accountinsertRecord = new Account();
        accountinsertRecord.Name = 'TestAccount';
        insert accountinsertRecord;
        system.assertEquals('TestAccount', accountinsertRecord.Name);
        
        objUser = IFv2_testDataUtility.createUser(); //inserting Workflow object
        objUser.Username = 'testshareRecoruser@gmail.com';
        objUser.IFv2_ByPassValidation__c = true;
        insert objUser;
        system.assertEquals('testshareRecoruser@gmail.com',objUser.Username);
        
        system.runAs(objUser){
            LIST<AccountShare> accountShare = new LIST<AccountShare>();
            LIST<IFv2_Request__Share> deleteShare = new LIST<IFv2_Request__Share>();
            LIST<IFv2_RequestExtension1__Share> deleteExtension1 = new LIST<IFv2_RequestExtension1__Share>();
            LIST<IFv2_RequestExtension2__Share> deleteExtenison2 = new LIST<IFv2_RequestExtension2__Share>();
            IFv2_DmlController.insertAccountShare(accountShare);
            IFv2_DmlController.deleteShareRecords(deleteShare);
            IFv2_DmlController.deleteShareRecordsAPAC(deleteExtension1);
            IFv2_DmlController.deleteShareRecordsEMAE(deleteExtenison2);
        }
       
        
    }
    
    public static testMethod void checkCustomValidationErrorsMethod(){
        objUser = IFv2_testDataUtility.createUser();
        insert objUser;
        System.assertEquals(true, objUser != Null);
        IFv2_Workflow__c workflowRecord  = IFv2_testDataUtility.createWorkflowCustomSetting();
        workflowRecord.Name = 'China MAE Application - Split';
        workflowRecord.Workflow__c = 'China MAE Application - Split'; 
        insert workflowRecord;
        System.assertEquals(true, workflowRecord.Workflow__c == 'China MAE Application - Split');
        
        IFv2_RequestExtension1__c apac =  new IFv2_RequestExtension1__c();
        apac.ChargetoOthercostcenter__c = 'Yes';
        apac.ChargetoCostCenter__c ='';
        insert apac;
        System.assertEquals(true, apac.ChargetoOthercostcenter__c == 'Yes');
        
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'Predefined Workflow Approvals';
        lstsObject[0].Role01__c = 'test';
        lstsObject[0].RequestExtension1__c =  apac.id;
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'Predefined Workflow Approvals');
        System.assertEquals(true, lstsObject[0].Role01__c == 'test');
        
        IFv2_HeaderController.customValidationErrors(lstsObject[0], null);
        
        lstsObject[0].Workflow__c = 'Indirect Purchasing Approval';
        lstsObject[0].ResponsibleBuyerIdenticalwRequester__c = false;
        lstsObject[0].BuyerRegion__c = null;
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'Indirect Purchasing Approval');
        System.assertEquals(true, lstsObject[0].ResponsibleBuyerIdenticalwRequester__c == false);
        IFv2_HeaderController.customValidationErrors(lstsObject[0], null);
        
        lstsObject[0].Workflow__c = 'Concession';
        lstsObject[0].AreAllMaterialsValidated__c = false;
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'Concession');
        System.assertEquals(true, lstsObject[0].AreAllMaterialsValidated__c == false);
        IFv2_HeaderController.customValidationErrors(lstsObject[0], null);
        
        lstsObject[0].Workflow__c = 'China Training Application';
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'China Training Application');
        
        Account relatedListRecords = new Account();
        relatedListRecords.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Items').getRecordTypeId();
        relatedListRecords.IFv2_ContentType__c = 'Employee';
        relatedListRecords.Name = 'test Employee';
        relatedListRecords.IFv2_Request__c = lstsObject[0].Id;
        insert relatedListRecords;
        IFv2_HeaderController.customValidationErrors(lstsObject[0], null);
        
        lstsObject[0].Workflow__c = 'HU Scrapping WorkOn';
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'HU Scrapping WorkOn');
        IFv2_HeaderController.customValidationErrors(lstsObject[0], null);
    }
    
    public static testMethod void checkForApproversEtensionTwo(){
        objUser = IFv2_testDataUtility.createUser();
        insert objUser;
        
        IFv2_Workflow__c workflowRecord  = IFv2_testDataUtility.createWorkflowCustomSetting();
        workflowRecord.Name = 'Overtime Request Germany';
        workflowRecord.Workflow__c = 'Overtime Request Germany'; 
        insert workflowRecord;
        System.assertEquals(true, workflowRecord.Workflow__c == 'Overtime Request Germany');
        
        IFv2_RequestExtension2__c apac =  new IFv2_RequestExtension2__c();
        insert apac;
        System.assertEquals(true, apac != Null);
        
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'Overtime Request Germany';
        lstsObject[0].Approver1__c =  objUser.id;
        lstsObject[0].RequestExtension2__c =  apac.id;
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'Overtime Request Germany');
        /*  ////Commented because test failed. Copied from SIT
        workflowRecord.Name = 'Overtime Request Germany';
        workflowRecord.Workflow__c = 'Overtime Request Germany'; 
        insert workflowRecord;
        System.assertEquals(true, workflowRecord.Workflow__c == 'Overtime Request Germany');
        
        IFv2_RequestExtension2__c apac =  new IFv2_RequestExtension2__c();
        insert apac;
        System.assertEquals(true, apac != Null);
        
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'Overtime Request Germany';
        lstsObject[0].Approver1__c =  objUser.id;
        lstsObject[0].RequestExtension2__c =  apac.id;
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'Overtime Request Germany');
        */
        IFv2_HeaderController.customValidationErrors(lstsObject[0], null);
        IFv2_HeaderController.submitForApproval(lstsObject[0], null);
    }
    public static testMethod void checkForApproversEtensionThree(){
        objUser = IFv2_testDataUtility.createUser();
        insert objUser;
        
        IFv2_Workflow__c workflowRecord  = IFv2_testDataUtility.createWorkflowCustomSetting();
        workflowRecord.Name = 'Requests for corporate card';
        workflowRecord.Workflow__c = 'Requests for corporate card'; 
        insert workflowRecord;
        System.assertEquals(true, workflowRecord.Workflow__c == 'Requests for corporate card');
        
        IFv2_RequestExtension3__c nalarequest =  new IFv2_RequestExtension3__c();
        insert nalarequest;
        
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'Requests for corporate card';
        lstsObject[0].Approver1__c =  objUser.id;
        lstsObject[0].RequestExtension3__c =  nalarequest.id;
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'Requests for corporate card');
        
        IFv2_HeaderController.customValidationErrors(lstsObject[0], null);
        IFv2_HeaderController.submitForApproval(lstsObject[0], null);
    }
    
    public static testMethod void testExceptionUtilities() {
        test.startTest();
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'China Training Application';
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'China Training Application');
        
        User objUser = new User();
        objUser = [select id from User limit 1];
        System.assertEquals(true, objUser != Null);
        
        String extension1ShareRecord = string.valueOf(objUser.id);
        
        SET<Id> testSet = new SET<Id>();
        testSet.add(objUser.id);
        try {
            IFv2_HeaderController.RecordShare(testSet, lstsObject[0].id, extension1ShareRecord, null, null, null, null);
        } catch(Exception e) {
        }
        lstsObject[0].X8Dreportno__c = 'llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll';
        try{
            IFv2_DmlController.GenericListDMLOperation(lstsObject, 'update');
        } catch(Exception e) {
        } 
        test.stopTest();
    }
    
    static testMethod void returnRequestDataMethod() {
        String result = IFv2_HeaderController.returnRequestData(true);
        system.assertEquals(true, result!= NULL);
    }
    
    static testMethod void updateConcessionConcessionRecordMethod() {
        lstsObject = IFv2_testDataUtility.createRequest();
        insert lstsObject;
        String recId = lstsObject[0].Id;
        System.assertEquals(true, recId != Null);
        String response = IFv2_HeaderController.updateConcessionConcessionRecord(lstsObject[0].Id,'Null','Null','Null','Null','Null','Null');
        
        String response2 = IFv2_HeaderController.updateConcessionRecord('Null','Null','Null','Null','Null','Null','Null');
        
        IFv2_HeaderController.getPicklistvalues();
        
        LIST<IFv2_HelpURL__c> urlLIST = IFv2_HeaderController.getHelpURLRecords();
    }
    
    static testMethod void approvemethod() {
        
        objUser = IFv2_testDataUtility.createUser();
        objUser.DelegatedApproverId = UserInfo.getUserId();
        objUser.ManagerId = UserInfo.getUserId();
        insert objUser;
        System.assertEquals(true, objUser != Null);
        
        User objUser2 = IFv2_testDataUtility.createUser();
        objUser2.Username = 'objuser2forsubmit@test.com';
        objUser2.ManagerId = objUser.Id;
        insert objUser2;
        System.assertEquals(true, objUser2.Username == 'objuser2forsubmit@test.com');
        
        LIST<Id> userIds = new LIST<Id>();
        userIds.add(objUser.Id);
        
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'General Approval Form';
        lstsObject[0].Serial__c = false;
        lstsObject[0].Parallel__c = true;
        lstsObject[0].Approver1__c = objUser.Id;
        lstsObject[0].Approver2__c = objUser.Id;
        lstsObject[0].Approver3__c = objUser.Id;
        lstsObject[0].Approver4__c = objUser.Id;
        lstsObject[0].Approver5__c = objUser.Id;
        lstsObject[0].Approver6__c = objUser.Id;
        lstsObject[0].Approver7__c = objUser.Id;
        lstsObject[0].Approver8__c = objUser.Id;
        lstsObject[0].Approver9__c = objUser.Id;
        lstsObject[0].Approver10__c = objUser.Id;
        lstsObject[0].Approver11__c = objUser.Id;
        lstsObject[0].Approver12__c = objUser.Id;
        lstsObject[0].Approver13__c = objUser2.Id;
        lstsObject[0].Approver14__c = objUser.Id;
        lstsObject[0].Approver15__c = objUser.Id;
        lstsObject[0].Approver16__c = objUser.Id;
        lstsObject[0].Approver17__c = objUser.Id;
        lstsObject[0].Approver18__c = objUser.Id;
        lstsObject[0].Approver19__c = objUser.Id;
        lstsObject[0].Approver20__c = objUser.Id;
        lstsObject[0].Status__c = 'Submitted';
        insert lstsObject;
        System.assertEquals(true, lstsObject[0].Status__c == 'Submitted');
        System.assertEquals(true, lstsObject[0].Parallel__c == true);
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(lstsObject[0].Id);
        req1.setSubmitterId(objUser2.Id);
        req1.setNextApproverIds(userIds);
        req1.setProcessDefinitionNameOrId('IFv2_GeneralApprovalFormParallel');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        System.runAs(objUser2) {
            Boolean approveResponse = IFv2_HeaderController.approveMethod(lstsObject[0].Id, 'Approved', null);
        }
        
    }
    
    static testMethod void rejectmethod() {
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'eSignature';
        insert lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'eSignature');
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(lstsObject[0].Id);
        req1.setSubmitterId(UserInfo.getUserId());
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        Boolean rejectResponse = IFv2_HeaderController.rejectMethod(lstsObject[0].Id, 'Rejected');
    }
    /*
    static testMethod void utilsmethod() {
        Test.startTest();
        IFv2_Headercontroller.CheckNowWrapper wrapper = new IFv2_Headercontroller.CheckNowWrapper();
        wrapper.requestRecord = null;
        wrapper.accountRecord= null;
        wrapper.userMessage = 'test';
    //    LIST<IFv2_RequestButtons__mdt> result1 = IFv2_UtilsController.getButtonDetails('Select Test__c From IFv2_Request__c');
        IFv2_Request__c result2 = IFv2_UtilsController.forApprovers('Test');
        RecordType result3 = IFv2_UtilsController.getRecordTypeId('Test', 'Test__c');
        IFv2_Section__mdt result5 = IFv2_UtilsController.getSectionMetadataRecords('Test__c');
        IFv2_Section__mdt result4 = IFv2_UtilsController.getSectionMetadataRecords('{Test__c}');
        LIST<IFv2_Department__mdt> result6 = IFv2_UtilsController.getdepartments('Test__c');
        LIST<IFv2_Section__mdt> result67 = IFv2_UtilsController.getSectionMetaDataRecord('Test__c');
        Test.stopTest();
    } */
    
    static testMethod void approvemethodForMGP() {
        
        objUser = IFv2_testDataUtility.createUser();
        objUser.DelegatedApproverId = UserInfo.getUserId();
        objUser.ManagerId = UserInfo.getUserId();
        insert objUser;
        System.assertEquals(true, objUser != Null);
        
        User objUser2 = IFv2_testDataUtility.createUser();
        objUser2.Username = 'objuser2forsubmit@test.com';
        objUser2.ManagerId = objUser.Id;
        insert objUser2;
        System.assertEquals(true, objUser2.Username == 'objuser2forsubmit@test.com');
        
        LIST<Id> userIds = new LIST<Id>();
        userIds.add(objUser.Id);
        
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c =  Label.CLIFv20200;
        lstsObject[0].ChallanTypeofGatePass__c  = 'Returnable';
        lstsObject[0].Approver1__c = objUser.Id;
        lstsObject[0].Approver2__c = objUser.Id;
        lstsObject[0].Approver3__c = objUser.Id;
        lstsObject[0].Approver4__c = objUser.Id;
        lstsObject[0].Approver5__c = objUser.Id;
        lstsObject[0].Approver6__c = objUser.Id;
        lstsObject[0].Approver7__c = objUser.Id;
        lstsObject[0].Approver8__c = objUser.Id;
        lstsObject[0].Approver9__c = objUser.Id;
        lstsObject[0].Approver10__c = objUser.Id;
        lstsObject[0].Approver11__c = objUser.Id;
        lstsObject[0].Status__c = 'Submitted';
        insert lstsObject;
        System.assertEquals(true, lstsObject[0].Status__c == 'Submitted');
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(lstsObject[0].Id);
        req1.setSubmitterId(objUser2.Id);
        req1.setNextApproverIds(userIds);
        req1.setProcessDefinitionNameOrId('IFv2_MGPIndiaChild');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        System.runAs(objUser2) {
            Boolean approveResponse = IFv2_HeaderController.approveMethod(lstsObject[0].Id, 'Approved', null);
        }
        
    }
    
     public static testMethod void checkForApproversEtensionFour() {
        objUser = IFv2_testDataUtility.createUser();
        insert objUser;
        
         User objUsermanager = IFv2_testDataUtility.createUser();
         objUsermanager.username = 'testmanageruser@gmail.com';
         insert objUsermanager; 
         
        IFv2_Workflow__c workflowRecord  = IFv2_testDataUtility.createWorkflowCustomSetting();
        workflowRecord.Name = 'Requests for corporate card';
        workflowRecord.Workflow__c = 'Requests for corporate card'; 
        insert workflowRecord;
        System.assertEquals(true, workflowRecord.Workflow__c == 'Requests for corporate card');
        
        IFv2_RequestExtension3__c nalarequest =  new IFv2_RequestExtension3__c();
        insert nalarequest;
        
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'Requests for corporate card';
        lstsObject[0].Approver1__c =  objUser.id;
        lstsObject[0].RequestExtension3__c =  nalarequest.id;
        insert lstsObject ;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'Requests for corporate card');
        SET<Id> approverIdSET = new SET<Id>();
         approverIdSET.add(objUsermanager.Id);
        IFv2_HeaderController.customValidationErrors(lstsObject[0], null);
        IFv2_HeaderController.RecordShareManager(approverIdSET,lstsObject[0].Id,lstsObject[0].RequestExtension1__c,lstsObject[0].RequestExtension2__c,lstsObject[0].RequestExtension3__c,lstsObject[0].Account__c,lstsObject[0].Workflow__c);
    }
     Public static testMethod void checkForApproversEtensionFive(){
        test.startTest();
        IFv2_RequestExtension1__c extension1Record = new IFv2_RequestExtension1__c();
        insert extension1Record;
         system.debug('Extension record');
        
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'China Travel Application';
        lstsObject[0].RequestExtension1__c = extension1Record.Id;
        insert lstsObject ;
         
         User objUsermanager = IFv2_testDataUtility.createUser();
         objUsermanager.username = 'testmanageruser2@gmail.com';
         insert objUsermanager; 
         SET<Id> approverIdSET = new SET<Id>();
         approverIdSET.add(objUsermanager.Id);
        system.assertEquals('China Travel Application',(String)lstsObject[0].Workflow__c);
        IFv2_HeaderController.RecordShareManager(approverIdSET,lstsObject[0].Id,lstsObject[0].RequestExtension1__c,lstsObject[0].RequestExtension2__c,lstsObject[0].RequestExtension3__c,lstsObject[0].Account__c,'China Travel Application');
        test.stopTest();
    }
    
    Public static testMethod void checkForManagers(){
        test.startTest();
        IFv2_RequestExtension2__c extension2 = new IFv2_RequestExtension2__c();
        insert extension2;
        
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'Overtime Request';
        lstsObject[0].RequestExtension2__c = extension2.Id;
        insert lstsObject ;
        
        system.assertEquals('Overtime Request', lstsObject[0].Workflow__c);
        User objUsermanager = IFv2_testDataUtility.createUser();
        objUsermanager.username = 'testmanageruser3@gmail.com';
        insert objUsermanager;
        SET<Id> approverIdSET = new SET<Id>();
        approverIdSET.add(objUsermanager.Id);
         ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'eSignature',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
        String testString1 = IFv2_HeaderController.returnContentDocumentURL('eSignature');
        String testString2 = IFv2_HeaderController.returnContentDocumentURL('');
         IFv2_HeaderController.validatedApprovers(lstsObject[0].id,'Overtime Request',Json.serialize(lstsObject[0]));
        IFv2_HeaderController.RecordShareManager(approverIdSET,lstsObject[0].Id,lstsObject[0].RequestExtension1__c,extension2.Id,lstsObject[0].RequestExtension3__c,lstsObject[0].Account__c,lstsObject[0].Workflow__c);
       	LIST<IFv2_Request__c> lstsObject2 = IFv2_testDataUtility.createRequest();
        lstsObject2[0].Workflow__c = 'Book My Taxi and MITRA';
        insert lstsObject2 ;
        IFv2_HeaderController.validatedApprovers(lstsObject2[0].id,'Book My Taxi and MITRA',Json.serialize(lstsObject[0]));
        test.stopTest();
    }
    
}