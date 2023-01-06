/*******************************************************************************************************
* 
* @ Name    :   IFv2_SummaryCmpControllerTest
* @ Purpose :   Test class for IFv2_SummaryCmpController
* @ Author  :   Pradeep Chary
* @ Class	: 	IFv2_SummaryCmpController
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   02-01-2018      |  pradeep.chary@absyz.com      |  1.0          |  Initial Version
*
*******************************************************************************************************/

@isTest
public class IFv2_SummaryCmpControllerTest {
    
    public static LIST<Scan__c> scanRecordList;
    public static LIST<IFv2_Request__c> requestRecordLIST;
    public static User objUser;
    
    public static TestMethod void fetchRelatedRequestsMethod() {
        scanRecordList = IFv2_testDataUtility.createScanRecord(2);
        insert scanRecordList;
        System.assertEquals(true, !scanRecordList.isEmpty());
        
        requestRecordLIST = IFv2_testDataUtility.createRequest();
        requestRecordLIST[0].Workflow__c = 'eSignature';
        requestRecordLIST[0].Parallel__c = true;
        requestRecordLIST[0].Serial__c = false;
        requestRecordLIST[0].Scan__c = scanRecordList[0].Id;
        insert requestRecordLIST;
        System.assertEquals(true, !requestRecordLIST.isEmpty());
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(requestRecordLIST[0].Id);
        req1.setSubmitterId(UserInfo.getUserId());
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        IFv2_SummaryCmpController.fetchRelatedRequests(requestRecordLIST[0].Id, requestRecordLIST[0].Status__c);
        
    }
}