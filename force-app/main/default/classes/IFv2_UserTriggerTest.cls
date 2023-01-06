/*******************************************************************************************************
* 
* @ Name    :   IFv2_UserTriggerTest
* @ Purpose :   Test data for Trigger handler User trigger methods
* @ Author  :   Elsa Shaju
* @ Class	: 	IFv2_TriggerHandler
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   29-10-2019      |  elsa.shaju@absyz.com         |  1.0          |  Initial Version
*
*******************************************************************************************************/
@isTest
public class IFv2_UserTriggerTest {

    	public static list<IFv2_Request__c> lstRequest ;
    	public static Account objAcc;
    	public static User objUser; 
        public static User objUserDelegate;
    
    public static testmethod void testMethod1() {
	
        test.startTest();
        objUser = IFv2_testDataUtility.createUser();
        objUser.Username = 'abc@deltest.com';
        insert objUser;
        objUserDelegate = IFv2_testDataUtility.createUser();
        objUserDelegate.Username = 'abcd@deltest.com';
        insert objUserDelegate;
        
        objAcc = IFv2_testDataUtility.createAccount();
        objAcc.Name = 'Travelling';
        insert objAcc;
        
        lstRequest = IFv2_testDataUtility.createRequest();
        lstRequest[0].Workflow__c = 'eSignature';
        lstRequest[0].Status__c = 'Draft';
        lstRequest[0].Approver1__c = objUser.id; 
        insert lstRequest ;
        
        IFv2_RequestExtension1__c extension1 = new IFv2_RequestExtension1__c();
        insert extension1;
        IFv2_RequestExtension2__c extension2 = new IFv2_RequestExtension2__c();
        insert extension2;
        IFv2_RequestExtension3__c extension3 = new IFv2_RequestExtension3__c();
        insert extension3;
        
        lstRequest[0].Account__c = objAcc.Id;
        lstRequest[0].RequestExtension1__c = extension1.Id;
        lstRequest[0].RequestExtension2__c = extension2.Id;
        lstRequest[0].RequestExtension3__c = extension3.Id;
        update lstRequest[0];
        
        System.assertEquals(true, lstRequest[0].Workflow__c == 'eSignature');
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(lstRequest[0].Id);
        req1.setSubmitterId(UserInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        objUser.DelegatedApproverId = objUserDelegate.Id;
        update objUser;
		
        test.stopTest();
    }
}