/*******************************************************************************************************
* 
* @ Name        :   IFv2_BackToOfficeOutOfOfficeBatchV2test
* @ Purpose     :   Test class to Scheduler class IFv2_BackfficeOutOfficeBatchV2Schdulr
* @ Author      :   Prasad Vivek
* @ Class Name  :   IFv2_BackToOfficeOutOfOfficeBatchV2
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   28-10-2018      |  vivek.kothalanka@absyz.com   |  1.0          |  Initial Version
*******************************************************************************************************/
@isTest(SeeAllData=false)
public class IFv2_BackToOfficeOutOfOfficeBatchV2test {
    
    //Method to call schedule class
    Public static TestMethod void schedlueMethod() {
        
        //Creating cron Logic
        String cronValue = '0 0 0 28 2 ? *';
        test.startTest();     
        IFv2_OutOfOfficeScheduler userPermissionSetAssignmentBatch = new IFv2_OutOfOfficeScheduler(); 
        String jobId = System.schedule('OutOfOfficeScheduler',cronValue,userPermissionSetAssignmentBatch);
        CronTrigger crontrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                                   FROM CronTrigger 
                                   WHERE id = :jobId];
        system.assertEquals(0, crontrigger.TimesTriggered);
        
        test.stopTest();
        
    }
    
        //Method to call schedule class
    Public static TestMethod void schedlueMethod1() {
        
        //Creating cron Logic
        String cronValue = '0 0 0 28 2 ? *';
        test.startTest();     
        IFv2_BackToOfficeScheduler userPermissionSetAssignmentBatch = new IFv2_BackToOfficeScheduler(); 
        String jobId = System.schedule('BackToOfficeScheduler',cronValue,userPermissionSetAssignmentBatch);
        CronTrigger crontrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                                   FROM CronTrigger 
                                   WHERE id = :jobId];
        system.assertEquals(0, crontrigger.TimesTriggered);
        
        test.stopTest();
        
    }
    //Execute method for outOfOffice Batch method 
    Public static TestMethod void executeBatchMethod() {
        
        Account objAcc = IFv2_testDataUtility.createAccount();
        insert objAcc;
        
        Contact objCon = IFv2_testDataUtility.createContact(objAcc);
        insert objCon;
        
        User objUser = IFv2_testDataUtility.createUser();
        objUser.IFv2_ByPassValidation__c = true;
        objUser.Out_Of_Office__c = true;
        objUser.ConsiderInReassignmentBatch__c = false;
        objUser.DelegatedApproverId = UserInfo.getUserId();
        insert objUser;
        system.assertEquals(true, objUser.IFv2_ByPassValidation__c );
        
        String recTypeId = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('OutOfOfficeLogs').getRecordTypeId();

        IFv2_AdminOnly__c adminRecord = new IFv2_AdminOnly__c(recordtypeId=recTypeId, WorkflowName__c='eSignature',User__c= UserInfo.getUserId(),active__c=true,OwnerId=objUser.Id);
        insert adminRecord;

        
        LIST<IFv2_Request__c> lstRequest = IFv2_testDataUtility.createRequest();
        insert lstRequest;
        lstRequest[0].status__c = 'Submitted';
        lstRequest[0].Workflow__c = 'eSignature';
        update lstRequest;
        
        objAcc.IFv2_Request__c = lstRequest[0].Id;
        update objAcc;
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(lstRequest[0].Id); 
        req1.setSubmitterId(UserInfo.getUserId()); 
        
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        
        IFv2_OutOfOfficeBatch batchInstance = new IFv2_OutOfOfficeBatch();
        Database.executeBatch(batchInstance,1);
        
        ProcessInstanceWorkitem pworkItemLIST = new  ProcessInstanceWorkitem();
        pworkItemLIST = [SELECT OriginalActorId, ActorId, ElapsedTimeInDays,Actor.Name,
                         ProcessInstance.TargetObjectId, createdDate
                         FROM ProcessInstanceWorkitem
                         WHERE ProcessInstance.TargetObjectId =:lstRequest[0].Id  limit 1];
        OutOfOfficeAndBackToOfficeHelper.createReassignmentLog(pworkItemLIST,UserInfo.getUserId(),'eSignature',objUser.Id);
        Set<Id> userSet = new Set<Id>();
        userSet.add(UserInfo.getUserId());
        Set<Id> ProxyUserSet = new Set<Id>();
        ProxyUserSet.add(objUser.Id);
        OutOfOfficeAndBackToOfficeHelper.createUnAssignedLogs(userSet,ProxyUserSet);
        IFv2_TriggerHandler.createUnAssignedLogs(userSet,ProxyUserSet);
        list<id> lstIds = new list<id>();
        lstIds.add(objUser.id);
        OutOfOfficeAndBackToOfficeHelper.assignRequestsBack(lstIds,'eSignature');
        
        
    }
    
    //Execute method for backtoOfficeOutofOffice
    Public static TestMethod void executeBatchMethod2() {
        
        Account objAcc = IFv2_testDataUtility.createAccount();
        insert objAcc;
        
        Contact objCon = IFv2_testDataUtility.createContact(objAcc);
        insert objCon;
        
        User objUser = IFv2_testDataUtility.createUser();
        objUser.IFv2_ByPassValidation__c = true;
        objUser.Out_Of_Office__c = false;
        objUser.ConsiderInReassignmentBatch__c = true;
        insert objUser;
        system.assertEquals(true, objUser.IFv2_ByPassValidation__c );
        
        String recTypeId = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('Reassignment Logs').getRecordTypeId();

        IFv2_AdminOnly__c adminRecord1 = new IFv2_AdminOnly__c(recordtypeId=recTypeId, WorkflowName__c='eSignature',User__c= UserInfo.getUserId(),active__c=true);
        insert adminRecord1;
        system.assertNotEquals(adminRecord1,null );

        
        LIST<IFv2_Request__c> lstRequest = IFv2_testDataUtility.createRequest();
        insert lstRequest;
        lstRequest[0].status__c = 'Submitted';
        lstRequest[0].Workflow__c = 'eSignature';
        update lstRequest;
        objAcc.IFv2_Request__c = lstRequest[0].Id;
        update objAcc;
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(lstRequest[0].Id); 
        req1.setSubmitterId(UserInfo.getUserId()); 
        
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        
        IFv2_BackToOfficeBatch batchInstance = new IFv2_BackToOfficeBatch();
        Database.executeBatch(batchInstance,1);
        
        ProcessInstanceWorkitem pworkItemLIST = new  ProcessInstanceWorkitem();
        pworkItemLIST = [SELECT OriginalActorId, ActorId, ElapsedTimeInDays,Actor.Name,
                         ProcessInstance.TargetObjectId, createdDate
                         FROM ProcessInstanceWorkitem
                         WHERE ProcessInstance.TargetObjectId =:lstRequest[0].Id  limit 1];
        OutOfOfficeAndBackToOfficeHelper.createReassignmentLog(pworkItemLIST,(Id)UserInfo.getUserId(),'eSignature',objUser.Id);
        list<id> lstIds = new list<id>();
        lstIds.add(objUser.id);
        OutOfOfficeAndBackToOfficeHelper.assignRequestsBack(lstIds,'');
        
    }
}