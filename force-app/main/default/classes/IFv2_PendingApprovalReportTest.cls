/***************************************************************************************************************
* 
* @ Name 		:	IFv2_PendingApprovalReportTest
* @ Purpose 	: 	For sending report regarding ICO workflows
* @ Author		: 	Prasad Vivek
* @ Test class  :   IFv2_PendingApprovalReport
*
*   Date	        |  Developer Name               |  Version      |  Changes
* ==================================================================================================================
*   05-11-2018      |  vivek.kothalanka@absyz.com	|  1.1          | 	Initial version to send ICO workflows  
*
*******************************************************************************************************************/
@istest
public class IFv2_PendingApprovalReportTest {
    
  @testSetUp Public static  void testDataMethod() {
        
        user userRecord = IFv2_TestDataUtility.createSGStandardUser();
        userRecord.Username = 'testUsericomail@gmail.com';
        userRecord.Country = 'Germany';
        insert userRecord;
    }
    
    public static testmethod void testschedule() {
        
        Test.StartTest();
        
        User  UserRecord = [SELECT Id FROM user LIMIT 1];
        system.assertEquals(true, UserRecord!= NULL);
        list<IFv2_Request__c> requestLIST = new list<IFv2_Request__c>();
        list<IFv2_Request__c> testDataUtility = IFv2_TestDataUtility.createRequest();
        for(IFv2_Request__c request : testDataUtility) {
            request.Status__c = 'Submitted';
            request.CompanyCode__c = '9000';
            request.Approver1__c = userRecord.Id;
            request.Approver2__c = userRecord.Id;
            request.Approver3__c = userRecord.Id;
            request.Approver4__c = userRecord.Id;
            request.Approver5__c = userRecord.Id;
            request.Approver6__c = userRecord.Id;
            request.Workflow__c = 'ICO Workflow - 1';
            requestLIST.add(request);
        }
        insert requestLIST;
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(requestLIST[0].Id);
        req1.setSubmitterId(UserInfo.getUserId());
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        req1.setProcessDefinitionNameOrId('IFv2_ICOWorkflowsCommon');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        All_Pending_Approval__c allPending = new All_Pending_Approval__c();
        allPending.Company_Code__c = '9000';
        allPending.Pex_Email1__c = 'testabsyz@gamil.com';
        allPending.Pex_Email2__c = 'testabsyz@gamil.com';
        allPending.Pex_Email3__c = 'testabsyz@gamil.com';
        allPending.Pex_Email4__c = 'testabsyz@gamil.com';
        allPending.Pex_Email5__c =	'testabsyz@gamil.com';
        allPending.Pex_Email6__c = 'testabsyz@gamil.com';
        allPending.Name ='Test';
        insert allPending;
        
        IFv2_PendingApprovalReport sh1 = new IFv2_PendingApprovalReport();      
        String sch = '0 0 23 * * ?';
        system.schedule('PendingApprovalReportPart2A', sch, sh1);
        IFv2_PendingApprovalReport_batch_mlb obj = new IFv2_PendingApprovalReport_batch_mlb();
        DataBase.executeBatch(obj);
        Test.stopTest();        
    } 
    
    public static testmethod void testscheduleMethod2() {
        
        Test.StartTest();
        
        User  UserRecord = [SELECT Id FROM user LIMIT 1];
        system.assertEquals(true, UserRecord!= NULL);
        list<IFv2_Request__c> requestLIST = new list<IFv2_Request__c>();
        list<IFv2_Request__c> testDataUtility = IFv2_TestDataUtility.createRequest();
        for(IFv2_Request__c request : testDataUtility) {
            request.Status__c = 'Submitted';
            request.CompanyCode__c = '71F0';
            request.Approver1__c = userRecord.Id;
            request.Approver2__c = userRecord.Id;
            request.Approver3__c = userRecord.Id;
            request.Approver4__c = userRecord.Id;
            request.Approver5__c = userRecord.Id;
            request.Approver6__c = userRecord.Id;
            request.Workflow__c = 'ICO Workflow - 1';
            requestLIST.add(request);
        }
        insert requestLIST;
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(requestLIST[0].Id);
        req1.setSubmitterId(UserInfo.getUserId());
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        req1.setProcessDefinitionNameOrId('IFv2_ICOWorkflowsCommon');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        All_Pending_Approval__c allPending = new All_Pending_Approval__c();
        allPending.Company_Code__c = '71F0';
        allPending.Pex_Email1__c = 'testabsyz@gamil.com';
        allPending.Pex_Email2__c = 'testabsyz@gamil.com';
        allPending.Pex_Email3__c = 'testabsyz@gamil.com';
        allPending.Pex_Email4__c = 'testabsyz@gamil.com';
        allPending.Pex_Email5__c =	'testabsyz@gamil.com';
        allPending.Pex_Email6__c = 'testabsyz@gamil.com';
        allPending.Name ='Test';
        insert allPending;
        
        
        IFv2_PendingApprovalReport sh1 = new IFv2_PendingApprovalReport();      
        String sch = '0 0 23 * * ?';
        system.schedule('PendingApprovalReportPart2A', sch, sh1);
        IFv2_PendingApprovalReport_batch_mlb obj = new IFv2_PendingApprovalReport_batch_mlb();
        DataBase.executeBatch(obj);
        Test.stopTest();        
    }
    public static testmethod void testscheduleMethod3() {
        
        Test.StartTest();
        
        User  UserRecord = [SELECT Id FROM user LIMIT 1];
        system.assertEquals(true, UserRecord!= NULL);
        list<IFv2_Request__c> requestLIST = new list<IFv2_Request__c>();
        list<IFv2_Request__c> testDataUtility = IFv2_TestDataUtility.createRequest();
        for(IFv2_Request__c request : testDataUtility) {
            request.Status__c = 'Submitted';
            request.CompanyCode__c = '70A0';
            request.Approver1__c = userRecord.Id;
            request.Approver2__c = userRecord.Id;
            request.Approver3__c = userRecord.Id;
            request.Approver4__c = userRecord.Id;
            request.Approver5__c = userRecord.Id;
            request.Approver6__c = userRecord.Id;
            request.Workflow__c = 'ICO Workflow - 1';
            requestLIST.add(request);
        }
        insert requestLIST;
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(requestLIST[0].Id);
        req1.setSubmitterId(UserInfo.getUserId());
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        req1.setProcessDefinitionNameOrId('IFv2_ICOWorkflowsCommon');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        All_Pending_Approval__c allPending = new All_Pending_Approval__c();
        allPending.Company_Code__c = '70A0';
        allPending.Pex_Email1__c = 'testabsyz@gamil.com';
        allPending.Pex_Email2__c = 'testabsyz@gamil.com';
        allPending.Pex_Email3__c = 'testabsyz@gamil.com';
        allPending.Pex_Email4__c = 'testabsyz@gamil.com';
        allPending.Pex_Email5__c =	'testabsyz@gamil.com';
        allPending.Pex_Email6__c = 'testabsyz@gamil.com';
        allPending.Name ='Test';
        insert allPending;
        
        
        IFv2_PendingApprovalReport sh1 = new IFv2_PendingApprovalReport();      
        String sch = '0 0 23 * * ?';
        system.schedule('PendingApprovalReportPart2A', sch, sh1);
        IFv2_PendingApprovalReport_batch_mlb obj = new IFv2_PendingApprovalReport_batch_mlb();
        DataBase.executeBatch(obj);
        Test.stopTest();        
    }
    public static testmethod void testscheduleMethod4() {
        
        Test.StartTest();
        
        User  UserRecord = [SELECT Id FROM user LIMIT 1];
        system.assertEquals(true, UserRecord!= NULL);
        list<IFv2_Request__c> requestLIST = new list<IFv2_Request__c>();
        list<IFv2_Request__c> testDataUtility = IFv2_TestDataUtility.createRequest();
        for(IFv2_Request__c request : testDataUtility) {
            request.Status__c = 'Submitted';
            request.CompanyCode__c = '70B0';
            request.Approver1__c = userRecord.Id;
            request.Approver2__c = userRecord.Id;
            request.Approver3__c = userRecord.Id;
            request.Approver4__c = userRecord.Id;
            request.Approver5__c = userRecord.Id;
            request.Approver6__c = userRecord.Id;
            request.Workflow__c = 'ICO Workflow - 1';
            requestLIST.add(request);
        }
        insert requestLIST;
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(requestLIST[0].Id);
        req1.setSubmitterId(UserInfo.getUserId());
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        req1.setProcessDefinitionNameOrId('IFv2_ICOWorkflowsCommon');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        All_Pending_Approval__c allPending = new All_Pending_Approval__c();
        allPending.Company_Code__c = '70B0';
        allPending.Pex_Email1__c = 'testabsyz@gamil.com';
        allPending.Pex_Email2__c = 'testabsyz@gamil.com';
        allPending.Pex_Email3__c = 'testabsyz@gamil.com';
        allPending.Pex_Email4__c = 'testabsyz@gamil.com';
        allPending.Pex_Email5__c =	'testabsyz@gamil.com';
        allPending.Pex_Email6__c = 'testabsyz@gamil.com';
        allPending.Name ='Test';
        insert allPending;
        
        
        
        IFv2_PendingApprovalReport sh1 = new IFv2_PendingApprovalReport();      
        String sch = '0 0 23 * * ?';
        system.schedule('PendingApprovalReportPart2A', sch, sh1);
        IFv2_PendingApprovalReport_batch_mlb obj = new IFv2_PendingApprovalReport_batch_mlb();
        DataBase.executeBatch(obj);
        Test.stopTest();        
    }
    public static testmethod void testscheduleMethod5() {
        
        Test.StartTest();
        
        User  UserRecord = [SELECT Id FROM user LIMIT 1];
        system.assertEquals(true, UserRecord!= NULL);
        list<IFv2_Request__c> requestLIST = new list<IFv2_Request__c>();
        list<IFv2_Request__c> testDataUtility = IFv2_TestDataUtility.createRequest();
        for(IFv2_Request__c request : testDataUtility) {
            request.Status__c = 'Submitted';
            request.CompanyCode__c = '68C0';
            request.Approver1__c = userRecord.Id;
            request.Approver2__c = userRecord.Id;
            request.Approver3__c = userRecord.Id;
            request.Approver4__c = userRecord.Id;
            request.Approver5__c = userRecord.Id;
            request.Approver6__c = userRecord.Id;
            request.Workflow__c = 'ICO Workflow - 1';
            requestLIST.add(request);
        }
        insert requestLIST;
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(requestLIST[0].Id);
        req1.setSubmitterId(UserInfo.getUserId());
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        req1.setProcessDefinitionNameOrId('IFv2_ICOWorkflowsCommon');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        All_Pending_Approval__c allPending = new All_Pending_Approval__c();
        allPending.Company_Code__c = '68C0';
        allPending.Pex_Email1__c = 'testabsyz@gamil.com';
        allPending.Pex_Email2__c = 'testabsyz@gamil.com';
        allPending.Pex_Email3__c = 'testabsyz@gamil.com';
        allPending.Pex_Email4__c = 'testabsyz@gamil.com';
        allPending.Pex_Email5__c =	'testabsyz@gamil.com';
        allPending.Pex_Email6__c = 'testabsyz@gamil.com';
        allPending.Name ='Test';
        insert allPending;
        
        
        IFv2_PendingApprovalReport sh1 = new IFv2_PendingApprovalReport();      
        String sch = '0 0 23 * * ?';
        system.schedule('PendingApprovalReportPart2A', sch, sh1);
        IFv2_PendingApprovalReport_batch_mlb obj = new IFv2_PendingApprovalReport_batch_mlb();
        DataBase.executeBatch(obj);
        Test.stopTest();        
    }
    
    public static testmethod void testscheduleMethod6() {
        
        Test.StartTest();
        
        User  UserRecord = [SELECT Id FROM user LIMIT 1];
        system.assertEquals(true, UserRecord!= NULL);
        list<IFv2_Request__c> requestLIST = new list<IFv2_Request__c>();
        list<IFv2_Request__c> testDataUtility = IFv2_TestDataUtility.createRequest();
        for(IFv2_Request__c request : testDataUtility) {
            request.Status__c = 'Submitted';
            request.CompanyCode__c = '69F0';
            request.Approver1__c = userRecord.Id;
            request.Approver2__c = userRecord.Id;
            request.Approver3__c = userRecord.Id;
            request.Approver4__c = userRecord.Id;
            request.Approver5__c = userRecord.Id;
            request.Approver6__c = userRecord.Id;
            request.Workflow__c = 'ICO Workflow - 1';
            requestLIST.add(request);
        }
        insert requestLIST;
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(requestLIST[0].Id);
        req1.setSubmitterId(UserInfo.getUserId());
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        req1.setProcessDefinitionNameOrId('IFv2_ICOWorkflowsCommon');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        All_Pending_Approval__c allPending = new All_Pending_Approval__c();
        allPending.Company_Code__c = '69F0';
        allPending.Pex_Email1__c = 'testabsyz@gamil.com';
        allPending.Pex_Email2__c = 'testabsyz@gamil.com';
        allPending.Pex_Email3__c = 'testabsyz@gamil.com';
        allPending.Pex_Email4__c = 'testabsyz@gamil.com';
        allPending.Pex_Email5__c =	'testabsyz@gamil.com';
        allPending.Pex_Email6__c = 'testabsyz@gamil.com';
        allPending.Name ='Test';
        insert allPending;
        
        
        IFv2_PendingApprovalReport sh1 = new IFv2_PendingApprovalReport();      
        String sch = '0 0 23 * * ?';
        system.schedule('PendingApprovalReportPart2A', sch, sh1);
        IFv2_PendingApprovalReport_batch_mlb obj = new IFv2_PendingApprovalReport_batch_mlb();
        DataBase.executeBatch(obj);
        Test.stopTest();        
    }
}