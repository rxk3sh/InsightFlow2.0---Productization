/*******************************************************************************************************
* 
* @ Name    	:   IFv2_DummyApproveBatchTest
* @ Purpose 	:   Test data for IFv2_ConcessionWorkflowHandler
* @ Author  	:   Kanchan
* @ Class Name 	:	IFv2_DummyApproveBatch/IFv2_DummyApproveBatchHandler
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   07-05-2019      |  Kanchan.b@absyz.com      	|  1.0          |  Initial Version
*
*******************************************************************************************************/
@isTest
public class IFv2_DummyApproveBatchTest {
    
    public static list<IFv2_Request__c> lstsObject ;
    
    
    @isTest
    public static void checkForApproversEtensionThree(){
        
        String DummyUserId = Label.CLIFv20022;
        
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'eSignature';
        lstsObject[0].Approver1__c=DummyUserId;
        insert lstsObject ;
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(lstsObject[0].Id);
        req1.setSubmitterId(UserInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        
        List<ProcessInstanceWorkItem> lst=[SELECT ActorId, ProcessInstanceId, ProcessInstance.TargetObjectId 
                                           FROM ProcessInstanceWorkItem 
                                           WHERE ActorId=:DummyUserId];
        
        system.assertEquals(1,lst.size());
        system.assertEquals(DummyUserId,lst[0].ActorId);
        IFv2_DummyApproveBatchHandler.dummyApprove(lst,'IFv2_Request__c');
        IFv2_DummyApproveBatch objSendRem = new IFv2_DummyApproveBatch();
        database.executeBatch(objSendRem);
    }
    
    @isTest static void executeTest(){
        Test.startTest();
        IFv2_DummyApproveBatch dummyBatch = new IFv2_DummyApproveBatch();
        String jobId = System.schedule('TestDummyApprovalBatchSchedule','0 0 0 * * ?',dummyBatch);
        Test.stopTest();
        List<CronTrigger> ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                                FROM CronTrigger WHERE id = :jobId];
        system.assertEquals('0 0 0 * * ?', ct[0].CronExpression);
        Date nextDate = system.today().addDays(1);
        DateTime nextRunDateTime = DateTime.newInstance(nextDate.year(),nextDate.month(),nextDate.day());
        System.assertEquals(1, ct.size());
        System.assertEquals(String.valueOf(nextRunDateTime),String.valueOf(ct[0].NextFireTime));
        
        
    } 
    
    //Method to schedule 
    Public static testMethod void scheduleMethod(){
        
        test.startTest();
        //Creating cron Logic
        String cronValue = '0 0 0 28 2 ? *';
        IFv2_DummyApproveBatch dummyApproverBatchInstance = new IFv2_DummyApproveBatch();
        dummyApproverBatchInstance.scheduleBatch('Test Job',cronValue);
        integer numberofscheduleJobs = [select count() from cronTrigger ];
        Date nextDate = system.today().addDays(1);      
        system.assertEquals(true,numberofscheduleJobs!= NULL);
        
        test.stopTest();
    }
    
}