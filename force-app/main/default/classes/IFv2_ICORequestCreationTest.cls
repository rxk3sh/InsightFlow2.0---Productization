/*******************************************************************************************************
* 
* @ Name 			: IFv2_ICORequestCreationTest
* @ Purpose 		: Test class for IFv2_ICORequestCreation
* @ Author			: Prasad Vivek
* @ Test Class Name : IFv2_ICORequestCreationTest 
*
*   Date            |  Developer Name                 |  Version     |  Changes
* ======================================================================================================
*   19-03-2019      |  vivek.kothalanka@absyz.com	  |  1.1         |  Initial version
*
*******************************************************************************************************/

@isTest
public class IFv2_ICORequestCreationTest {
    
    @TestSetup
    static void testSetup(){
        /*commented for cleaning up of Insightflow 1.0 components
* Workflow__c wf = new Workflow__c();
wf.Name = 'ICO Workflow - 1';
wf.Application_Key__c = 'APM1';
insert wf; */
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        
        User u = new User(
            Alias = 'standt', 
            Email='standarduser@seg-automotive.com', 
            EmailEncodingKey='UTF-8', 
            LastName='Testing', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='standarduser@t-systems.com.test',
            NT_User__c = 'SAP123'
        );
        insert u;
        
        User u2 = new User(
            Alias = 'standt2', 
            Email='standarduser@seg-automotive.com', 
            EmailEncodingKey='UTF-8', 
            LastName='Testing2', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='standarduser@t-systems.com.test2',
            NT_User__c = 'SAP321'
        );
        insert u2;
        List<User> uList = [SELECT Id FROM User];
        System.assertEquals(true, uList.size()>0);
    }
    
    static testMethod void mandatoryFieldsTest() {
        
        
        SG_WF_WS_SAP_Cust_RequestCreation.RequestWrapper responseWrapper = new SG_WF_WS_SAP_Cust_RequestCreation.RequestWrapper();
        
        IFv2_ICORequestCreation.RequestWrapper rw = new IFv2_ICORequestCreation.RequestWrapper(responseWrapper);
        
        rw.Approver_name = 'SAP123';
        rw.Workflow_number = '06';
        Test.startTest();
        try{
            IFv2_ICORequestCreation.createApmRequest(rw);
        } catch (Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('Salesforce ID, Approver Name and Workflow number are required, please check if are filled properly') ? true : false;
            System.AssertEquals(expectedExceptionThrown, false);
        }
        Test.stopTest();
        
    }
    
    static testMethod void requstCreationTestMethodOne(){
        
        Scan__c scanRecord = new Scan__c();
        insert scanRecord;
        
        Attachment attachmentRecord = IFv2_testDataUtility.insertXmlAttachment(scanRecord.Id);
        insert attachmentRecord;
        
        SG_WF_WS_SAP_Cust_RequestCreation.RequestWrapper responseWrapper = new SG_WF_WS_SAP_Cust_RequestCreation.RequestWrapper();
        
        IFv2_ICORequestCreation.RequestWrapper rw = new IFv2_ICORequestCreation.RequestWrapper(responseWrapper);
        rw.Approver_name = 'TESTSAP123';
        rw.Salesforce_ID = scanRecord.Id;
        rw.Workflow_number = '01';
        rw.Approver_Proxy_name = 'TESTSAP321';
        
        IFv2_ICORequestCreation.ResponseObject response = IFv2_ICORequestCreation.createApmRequest(rw);
        System.assertEquals('ERROR', response.result);
        System.assert(String.isBlank(response.objectId));
        
    }
    static testMethod void requstCreationTestMethodTwo(){
        
        IFv2_Request__c requestRecord = new IFv2_Request__c();
        insert requestRecord;
        
        SG_WF_WS_SAP_Cust_RequestCreation.RequestWrapper responseWrapper = new SG_WF_WS_SAP_Cust_RequestCreation.RequestWrapper();
        
        
        IFv2_ICORequestCreation.RequestWrapper rw = new IFv2_ICORequestCreation.RequestWrapper(responseWrapper);
        rw.Approver_name = 'SAP123';
        rw.Salesforce_ID = requestRecord.Id;
        rw.Workflow_number = '01';
        
        try{
            IFv2_ICORequestCreation.createApmRequest(rw);
        } catch (Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('Salesforce ID, Approver Name and Workflow number are required, please check if are filled properly') ? true : false;
            System.AssertEquals(expectedExceptionThrown, false);
        }
        
    }
    
    static testMethod void requstCreationTestMethodThree(){
        
        Scan__c scanRecord = new Scan__c();
        insert scanRecord;
        
        Attachment attachmentRecord = IFv2_testDataUtility.insertXmlAttachment(scanRecord.Id);
        insert attachmentRecord;
        
        SG_WF_WS_SAP_Cust_RequestCreation.RequestWrapper responseWrapper = new SG_WF_WS_SAP_Cust_RequestCreation.RequestWrapper();
        
        IFv2_ICORequestCreation.RequestWrapper rw = new IFv2_ICORequestCreation.RequestWrapper(responseWrapper);
        rw.Approver_name = 'SAP123';
        
        LIST<Scan__C> scanLIST = [SELECT Id,Name FROM Scan__c WHERE Id =: scanRecord.Id];
        if(scanLIST != NULL) {
            rw.Salesforce_ID = scanLIST[0].Name;
        }
        rw.Workflow_number = '06';
        rw.Approver_Proxy_name = 'SAP321';
        
        IFv2_ICORequestCreation.ResponseObject response = IFv2_ICORequestCreation.createApmRequest(rw);
        System.assertEquals('SUCCESS', response.result);
        
    }
    
    static testMethod void requstCreationTestMethodFour(){
        
        Scan__c scanRecord = new Scan__c();
        insert scanRecord;
        
        Attachment attachmentRecord = IFv2_testDataUtility.insertXmlAttachment(scanRecord.Id);
        insert attachmentRecord;
        
        SG_WF_WS_SAP_Cust_RequestCreation.RequestWrapper responseWrapper = new SG_WF_WS_SAP_Cust_RequestCreation.RequestWrapper();
        
        IFv2_ICORequestCreation.RequestWrapper rw = new IFv2_ICORequestCreation.RequestWrapper(responseWrapper);
        rw.Approver_name = 'SAP123';
        LIST<Scan__C> scanLIST = [SELECT Id,Name FROM Scan__c WHERE Id =: scanRecord.Id];
        if(scanLIST != NULL) {
            rw.Salesforce_ID = scanLIST[0].Name;
        }
        rw.Workflow_number = '01';
        rw.Approver_Proxy_name = 'SAP321';
        
        IFv2_ICORequestCreation.ResponseObject response = IFv2_ICORequestCreation.createApmRequest(rw);
        System.assertEquals('SUCCESS', response.result);
        
    }
    
    
    
}