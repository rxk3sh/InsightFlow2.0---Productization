/*******************************************************************************************************
* 
* @ Name 	:	IFv2_HomePageControllerTest
* @ Purpose : 	Test class for the Home page
* @ Author	: 	Madhura Vani
*
*   Date	        |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   09-11-2018      |  madhuravani.b@absyz.com		|  1.0          |  Initial Version
*
*******************************************************************************************************/
@isTest
public class IFv2_HomePageControllerTest {
    
    public static list<IFv2_Request__c> lstsObject ;
    @testSetup static void createTestData() {
        //inserting Request
        lstsObject = IFv2_testDataUtility.createRequest();
        lstsObject[0].Workflow__c = 'eSignature';
        lstsObject[0].Status__c = 'Submitted';
        insert lstsObject ;
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(lstsObject[0].Id);
        req1.setSubmitterId(UserInfo.getUserId());
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
    }
    
    private static testmethod void homePageData(){
        Test.startTest();
        lstsObject = [select id,name,Status__c from IFv2_Request__c];
        System.assertEquals(true, !lstsObject.isEmpty());
        IFv2_HomePageController.getItemsToApproveVersion2('IFv2_Request__c');
        lstsObject[0].Status__c = 'Draft';
        update lstsObject;
        System.assertEquals(lstsObject[0].Status__c, 'Draft');
        IFv2_HomePageController.getRequestDetails('Draft','IFv2_Request__c');
        Test.stopTest();
    }
    /*commented for cleaning up of Insightflow 1.0 components
private static testmethod void homePageData2(){
Test.startTest();
lstsObject = [select id,name,Status__c from IFv2_Request__c];
System.assertEquals(true, !lstsObject.isEmpty());
IFv2_HomePageController.getItemsToApproveVersion2('WF_Request__c');
lstsObject[0].Status__c = 'Draft';
update lstsObject;
System.assertEquals(lstsObject[0].Status__c, 'Draft');
IFv2_HomePageController.getRequestDetails('Draft','IFv2_Request__c');
Test.stopTest();
} */
}