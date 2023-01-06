/*******************************************************************************************************
* 
* @ Name    :   IFv2_HomePageRequestsOverviewTest
* @ Purpose :   Test class for HomeScreen
* @ Author  :   Madhura Vani
* @ Class   :   IFv2_HomePageRequestsOverview
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   31-03-2019      |  madhuravani.b@absyz.com      |  1.0          |  Initial Version
*
*******************************************************************************************************/
@isTest
public class IFv2_HomePageRequestsOverviewTest {
    public static IFv2_AdminOnly__c objAdmin; //holds Insightflow Records
    public static User objUser; //holds Users
    public static LIST<IFv2_Request__c> lstRequests; //Holds Requests
    public static IFv2_Workflow__c objWorkflow; //holds workflows
    
    /** Inserting the testdata **/
    @testsetup static void createTestData() {
        objUser = IFv2_testDataUtility.createUser();
        insert objUser;
        
        lstRequests = IFv2_testDataUtility.createRequest();
        lstRequests[0].Workflow__c = 'eSignature';
        lstRequests[0].Status__c = 'Submitted';
        insert lstRequests[0];
        
        objWorkflow = IFv2_testDataUtility.createWorkflowCustomSetting();    
        insert objWorkflow;
        
        objAdmin = new IFv2_AdminOnly__c();
        objAdmin.Active__c = true;
        objAdmin.WorkflowName__c = 'eSignature';
        objAdmin.User__c = objUser.Id;
        objAdmin.ProcessInstanceWorkItemId__c = lstRequests[0].id;
        insert objAdmin;
    }
    
    /**Calling the methods by satisfying Conditions **/
    static testmethod void homeMethods() {
        objAdmin = [SELECT id,name,WorkflowName__c,Active__c,User__c,User__r.Id,User__r.Username
                    FROM IFv2_AdminOnly__c 
                    LIMIT 1];
        System.assertEquals(true, objAdmin != Null);
        
        lstRequests= [SELECT id,name from IFv2_Request__c limit 1];
        System.assertEquals(true, !lstRequests.isEmpty()); 
        
        objWorkflow = [SELECT id from IFv2_Workflow__c limit 1];
        System.assertEquals(true, objWorkflow != Null); 
        
        //Calling Approval Process
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(lstRequests[0].Id);
        req1.setSubmitterId(UserInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        IFv2_HomePageRequestsOverviewController.getSectionMetadata();
        IFv2_HomePageRequestsOverviewController.getRequests();
        IFv2_HomePageRequestsOverviewController.getOutOfOfficeData();
        //BacktoOffice JSON
        string strBackToOffice = '{"Name":\"'+objAdmin.WorkflowName__c+'\","Id":\"'+objAdmin.Id+'\","userId":\"'+objAdmin.User__r.Id+'\","UserName":\"'+objAdmin.User__r.Username+'\"}';
        IFv2_HomePageRequestsOverviewController.DisableOutOfOfficeSettings(strBackToOffice);
        IFv2_HomePageRequestsOverviewController.saveOutOfOfficeSettings(objAdmin.id,objAdmin.Active__c,objAdmin.WorkflowName__c,objAdmin.User__r.Id);
        IFv2_HomePageRequestsOverviewController.UpdateOutOfOfficeBackToOffice(false);
        Test.startTest();
        IFv2_HomePageRequestsOverviewController.saveOutOfOfficeSettings('',objAdmin.Active__c,'All',objAdmin.User__r.Id);
        Test.stopTest();
    }
    
    /** Null Conditions **/
    static testmethod void adminRecordNew() {
        objAdmin = [SELECT id,name,WorkflowName__c,Active__c,User__c,User__r.Id,User__r.Username
                    FROM IFv2_AdminOnly__c 
                    LIMIT 1];
        System.assertEquals(true, objAdmin != Null);
        
        IFv2_AdminOnly__c objEmptyAdmin = new IFv2_AdminOnly__c();
        string strBackToOffice = '{"Name":\"'+objEmptyAdmin.WorkflowName__c+'\","Id":\"'+objEmptyAdmin.Id+'\","userId":\"'+objAdmin.User__r.Id+'\","UserName":\"'+objAdmin.User__r.Username+'\"}';
        IFv2_HomePageRequestsOverviewController.DisableOutOfOfficeSettings(strBackToOffice);
        IFv2_HomePageRequestsOverviewController.saveOutOfOfficeSettings('',objAdmin.Active__c,objEmptyAdmin.WorkflowName__c,objAdmin.User__r.Id);
        IFv2_HomePageRequestsOverviewController.UpdateOutOfOfficeBackToOffice(false);
    }
    
    /* Creating test records for migrated old records */
    public static void migrationRecords(){
        
        lstRequests = IFv2_testDataUtility.createRequest();
        lstRequests[0].Workflow__c = 'eSignature';
        lstRequests[0].Status__c = 'Submitted';
        insert lstRequests[0];
        system.assertEquals('Submitted', lstRequests[0].Status__c);
        
        id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Items').getRecordTypeId();
        
        Account testAccount = new Account();
        testAccount.Name = 'Approval History test records';
        testAccount.IFv2_ContentType__c = 'Approval History';
        testAccount.IFv2_Request__c = lstRequests[0].Id;
        testAccount.IFv2_LegacyActualApprover__c = userInfo.getUserId();
        testAccount.RecordTypeId = accountRecordTypeId;
        insert testAccount;
        system.debug(testAccount);
        IFv2_HomePageRequestsOverviewController.getRequestApprovedByMe();
        
    }
}