/***************************************************************************************************************
* 
* @ Name    :   IFv2_SendReminderMailTest
* @ Purpose :   Test data for Send Reminder mail preparation
* @ Author  :   Madhura Vani
* @ Class	: 	IFv2_SendReminderMail
*
*   Date            |  Developer Name               |  Version      |  Changes
* ===============================================================================================================
*   05-01-2019      |  madhuravani.b@absyz.com      |  1.0          |  Initial Version
*   07-05-2019      |  vivek.kothalanka@absyz.com   |  1.1          |  Updated code for changes in Iteartion 3
*
******************************************************************************************************************/
@isTest
public class IFv2_SendReminderMailTest {
    public static Account objAcc ;
    public static Contact objCon ;
    public static list<IFv2_Request__c> lstRequest;
    public static user objUser;
    
    //Test set up method for creating test data
    @testSetup static void createTestData() {
        
        objAcc = IFv2_testDataUtility.createAccount();
        insert objAcc;
        
        objCon = IFv2_testDataUtility.createContact(objAcc);
        insert objCon;
        
        objUser = IFv2_testDataUtility.createUser();
        objUser.IFv2_ByPassValidation__c = true;
        insert objUser;
        
        system.runAs(objUser)
        {
            lstRequest = IFv2_testDataUtility.createRequest();
            insert lstRequest;
        }
        
        objUser.IFv2_ByPassValidation__c = false;
        update objUser;  
    }
    
    public static testmethod void notesData(){ 
        objCon = [select id,lastname from contact limit 1];
        lstRequest = [select id from IFv2_Request__c limit 1];
        objUser = [select id,name from user limit 1];
        lstRequest[0].status__c = 'Submitted';
        lstRequest[0].Workflow__c = 'eSignature';
        update lstRequest[0];
        
        IFv2_Workflow__c objWF = new IFv2_Workflow__c();
        objWF.Name = 'eSignature';
        objWF.Workflow__c = 'eSignature';
        objWF.ReminderAfterDays__c = 7;
        objWF.SubsequentReminderAfter__c = 8;
        list<IFv2_Workflow__c> lstWF = new list<IFv2_Workflow__c>();
        lstWF.add(objWF);
        insert lstWF;
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(lstRequest[0].Id); 
        req1.setSubmitterId(UserInfo.getUserId()); 
        
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        system.assertEquals(true,result.isSuccess());
        IFv2_SendReminderMail objSendRem = new IFv2_SendReminderMail();
        database.executeBatch(objSendRem);
    }
    
    public static testMethod void executeTestMethod(){
        
        User userRecord;
        System.runAs(new User(Id=UserInfo.getUserId())) {
            userRecord = IFv2_testDataUtility.createSGStandardUser();
            insert userRecord;
        }
        
        
        IFv2_Request__c requestRecord = new IFv2_Request__c();
        requestRecord.Workflow__c = 'eSignature';
        requestRecord.Status__c= 'submitted';
        requestRecord.Approver1__c = userRecord.Id;
        insert requestRecord;
        
        IFv2_Workflow__c objWF = new IFv2_Workflow__c();
        objWF.Name = 'eSignature';
        objWF.Workflow__c = 'eSignature';
        objWF.ReminderAfterDays__c = 1;
        objWF.SubsequentReminderAfter__c = 1;
        list<IFv2_Workflow__c> lstWF = new list<IFv2_Workflow__c>();
        lstWF.add(objWF);
        insert lstWF;
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(requestRecord.Id); 
        req1.setSubmitterId(UserInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        system.assertEquals('Pending',result.getInstanceStatus());
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'test1', Email='test@gamil.com',FirstName = 'Testm', 
                          EmailEncodingKey='UTF-8', LastName='Testlastm', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='test111@gmailtest.com');
        insert u;
        ID candidate;
        ID recipient;
        
        Contact con=new Contact();
        con.lastname='Testing';
        insert con;
        mail.setTargetObjectId(recipient);
        mail.setPlainTextBody('');
        mail.setWhatId(candidate);   
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setReplyTo('tintu@qburst.com');
        mail.toaddresses=new String[] {'test@gmail.com'};
            mail.setSenderDisplayName('HR Recruiting');
        mail.setSaveAsActivity(false); 
        Test.startTest();
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        Test.stopTest();
        System.assert (result.success, 'InboundEmailResult returned a failure message');
        
        IFv2_SendReminderMail objSendRem = new IFv2_SendReminderMail();
        database.executeBatch(objSendRem);
    }
    
    public static testMethod void executeTestMethod2(){
        
        User userRecord;
        System.runAs(new User(Id=UserInfo.getUserId())) {
            userRecord = IFv2_testDataUtility.createSGStandardUser();
            insert userRecord;
        }
        
        IFv2_Request__c requestRecord = new IFv2_Request__c();
        requestRecord.Workflow__c = 'eSignature';
        requestRecord.Status__c= 'submitted';
        requestRecord.Approver1__c = userRecord.Id;
        insert requestRecord;
        
        IFv2_Workflow__c objWF = new IFv2_Workflow__c();
        objWF.Name = 'eSignature';
        objWF.Workflow__c = 'eSignature';
        objWF.ReminderAfterDays__c = 0;
        objWF.SubsequentReminderAfter__c = 0;
        list<IFv2_Workflow__c> lstWF = new list<IFv2_Workflow__c>();
        lstWF.add(objWF);
        insert lstWF;
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(requestRecord.Id); 
        req1.setSubmitterId(UserInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        system.assertEquals(true,result.isSuccess());
        
        IFv2_SendReminderMail objSendRem = new IFv2_SendReminderMail();
        database.executeBatch(objSendRem);
    }
    
    @isTest static void executeTest(){
        Test.startTest();
        IFv2_SendReminderMailSchedulable tsc = new IFv2_SendReminderMailSchedulable();
        String jobId = System.schedule('TetsReminderMailSchedule', '0 0 0 * * ?', tsc);
        Test.stopTest();
        List<CronTrigger> ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        system.assertEquals('0 0 0 * * ?', ct[0].CronExpression);
        Date nextDate = system.today().addDays(1);
        DateTime nextRunDateTime = DateTime.newInstance(nextDate.year(),nextDate.month(),nextDate.day());
        System.assertEquals(1, ct.size());
        System.assertEquals(String.valueOf(nextRunDateTime),String.valueOf(ct[0].NextFireTime));
        
    } 
    
    public static testmethod void notesData2(){ 
        
        IFv2_Workflow__c objWF = new IFv2_Workflow__c();
        objWF.Name = 'eSignature';
        objWF.Workflow__c = 'eSignature';
        objWF.ReminderAfterDays__c = null;
        list<IFv2_Workflow__c> lstWF = new list<IFv2_Workflow__c>();
        lstWF.add(objWF);
        insert lstWF;
        
        objCon = [select id,lastname from contact limit 1];
        lstRequest = [select id from IFv2_Request__c limit 1];
        objUser = [select id,name from user limit 1];
        lstRequest[0].status__c = 'Submitted';
        lstRequest[0].WorkflowId__c = lstWF[0].Id;
        lstRequest[0].Workflow__c = 'eSignature';
        update lstRequest[0];
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(lstRequest[0].Id); 
        req1.setSubmitterId(UserInfo.getUserId()); 
        
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        system.assertEquals(true,result.isSuccess());
        
        IFv2_SendReminderMail objSendRem = new IFv2_SendReminderMail();
        database.executeBatch(objSendRem);
    }
    
    public static testmethod void notesData3(){ 
        
        IFv2_Workflow__c objWF = new IFv2_Workflow__c();
        objWF.Name = 'eSignature';
        objWF.Workflow__c = 'eSignature';
        objWF.ReminderAfterDays__c = 0;
        objWF.SubsequentReminderAfter__c = 0;
        list<IFv2_Workflow__c> lstWF = new list<IFv2_Workflow__c>();
        lstWF.add(objWF);
        insert lstWF;
        
        objCon = [select id,lastname from contact limit 1];
        lstRequest = [select id from IFv2_Request__c limit 1];
        objUser = [select id,name from user limit 1];
        lstRequest[0].status__c = 'Submitted';
        lstRequest[0].WorkflowId__c = lstWF[0].Id;
        lstRequest[0].Workflow__c = 'eSignature';
        update lstRequest[0];
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(lstRequest[0].Id); 
        req1.setSubmitterId(UserInfo.getUserId()); 
        
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        system.assertEquals(true,result.isSuccess());
        
        IFv2_SendReminderMail objSendRem = new IFv2_SendReminderMail();
        database.executeBatch(objSendRem);
    }
    
    
    public static testmethod void notesData4(){ 
        
        IFv2_Workflow__c objWF = new IFv2_Workflow__c();
        objWF.Name = 'eSignature';
        objWF.Workflow__c = 'eSignature';
        objWF.ReminderAfterDays__c = 0;
        objWF.SubsequentReminderAfter__c = 1;
        list<IFv2_Workflow__c> lstWF = new list<IFv2_Workflow__c>();
        lstWF.add(objWF);
        insert lstWF;
        
        objCon = [select id,lastname from contact limit 1];
        lstRequest = [select id from IFv2_Request__c limit 1];
        objUser = [select id,name from user limit 1];
        lstRequest[0].status__c = 'Submitted';
        lstRequest[0].WorkflowId__c = lstWF[0].Id;
        lstRequest[0].Workflow__c = 'eSignature';
        update lstRequest[0];
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(lstRequest[0].Id); 
        req1.setSubmitterId(UserInfo.getUserId()); 
        
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        system.assertEquals(true,result.isSuccess());
        LIST<ProcessInstanceWorkitem> workitemsLIST = new  LIST<ProcessInstanceWorkitem>();
        workitemsLIST = [SELECT OriginalActorId, ActorId, ElapsedTimeInDays,Actor.Name,
                         ProcessInstance.TargetObjectId, createdDate
                         FROM ProcessInstanceWorkitem
                         WHERE ProcessInstance.TargetObjectId =:lstRequest[0].Id ];
        if(workitemsLIST[0] != NULL)
            Test.setCreatedDate(workitemsLIST[0].Id, Datetime.now().addDays(-1));
        
        IFv2_SendReminderMail objSendRem = new IFv2_SendReminderMail();
        database.executeBatch(objSendRem);
    }
    
    public static testmethod void notesData5(){ 
        
        IFv2_Workflow__c objWF = new IFv2_Workflow__c();
        objWF.Name = 'eSignature';
        objWF.Workflow__c = 'eSignature';
        objWF.ReminderAfterDays__c = 1;
        objWF.SubsequentReminderAfter__c = 1;
        list<IFv2_Workflow__c> lstWF = new list<IFv2_Workflow__c>();
        lstWF.add(objWF);
        insert lstWF;
        
        objCon = [select id,lastname from contact limit 1];
        lstRequest = [select id from IFv2_Request__c limit 1];
        objUser = [select id,name from user limit 1];
        lstRequest[0].status__c = 'Submitted';
        lstRequest[0].WorkflowId__c = lstWF[0].Id;
        lstRequest[0].Workflow__c = 'eSignature';
        update lstRequest[0];
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(lstRequest[0].Id); 
        req1.setSubmitterId(UserInfo.getUserId()); 
        
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        system.assertEquals(true,result.isSuccess());
        LIST<ProcessInstanceWorkitem> workitemsLIST = new  LIST<ProcessInstanceWorkitem>();
        workitemsLIST = [SELECT OriginalActorId, ActorId, ElapsedTimeInDays,Actor.Name,
                         ProcessInstance.TargetObjectId, createdDate
                         FROM ProcessInstanceWorkitem
                         WHERE ProcessInstance.TargetObjectId =:lstRequest[0].Id ];
        if(workitemsLIST[0] != NULL)
            Test.setCreatedDate(workitemsLIST[0].Id, Datetime.now().addDays(-2));
        
        IFv2_SendReminderMail objSendRem = new IFv2_SendReminderMail();
        database.executeBatch(objSendRem);
    }
}