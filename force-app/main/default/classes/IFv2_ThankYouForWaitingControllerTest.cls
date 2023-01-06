/*******************************************************************************************************
* 
* @ Name    :   IFv2_ThankYouForWaitingControllerTest
* @ Purpose :   Test class for Thank you page to redirect to the current system
* @ Author  :   Madhura Vani 
* @ Class	:	IFv2_ThankYouForWaitingController
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   26-11-2018      |  madhuravani.b@absyz.com      |  1.0          |  Initial Version   
*******************************************************************************************************/
@isTest
public class IFv2_ThankYouForWaitingControllerTest {
    public static list<IFv2_Request__c> lstRequest ;
    public static User objUser;
    public static testmethod void ThankyouData(){
        
        objUser = IFv2_testDataUtility.createUser();
        objUser.IFv2_ByPassValidation__c = true;
        insert objUser;
        IFv2_Request__c objReq = new IFv2_Request__c(); 
        system.runAs(objUser)
        {
            objReq.Status__c = 'Draft' ;
            objReq.OldRequest__c = '123';
            insert objReq;
        }
        
        objUser.IFv2_ByPassValidation__c = false;
        update objUser; 
        
        Pagereference page = Page.IFv2_ThankYouForWaiting;
        
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('Id','123');
        
        IFv2_Request__Share chatterShare = new IFv2_Request__Share();
        chatterShare.ParentId = objReq.Id;
        chatterShare.UserOrGroupId = userinfo.getUserId();
        chatterShare.AccessLevel = 'read';
        chatterShare.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
        insert chatterShare;
        
        IFv2_ThankYouForWaitingController obj = new IFv2_ThankYouForWaitingController();
        try{
            IFv2_ThankYouForWaitingController.redirectToActualRecord();
            obj.clickHme();
        } catch (TypeException ee) {
            System.assertEquals(
                'Procedure is only valid for System.DmlException and System.MailException',
                ee.getMessage()
            );
        }
    }
    
    public static testmethod void ThankyouData2(){
        
        IFv2_Request__c objReq = new IFv2_Request__c(); 
        objReq.Status__c = 'Draft' ;
        objReq.Workflow__c='eSignature';
        objReq.Version__c='test1';
        ObjReq.ReleaseDate__c=Date.newInstance(2019, 12, 20);
        insert objReq;
        
        
        lstRequest = [select id from IFv2_Request__c limit 1];
        system.assertEquals(1,lstRequest.size());
        System.debug('check id>>'+objReq.id);
        //  ApexPages.currentPage().getParameters().put('id',objReq.id);
        /* Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
app.setObjectId(objReq.id);
Approval.ProcessResult result = Approval.process(app);
*/
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(objReq.id);
        req1.setSubmitterId(UserInfo.getUserId());
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        
        Test.setCurrentPageReference(new PageReference('Page.IFv2_ThankYouForWaiting')); 
        System.currentPageReference().getParameters().put('id', objReq.id);
        
        IFv2_ThankYouForWaitingController obj = new IFv2_ThankYouForWaitingController();
        IFv2_ThankYouForWaitingController.recordId = objReq.id;
        IFv2_ThankYouForWaitingController.redirectToActualRecord();
    }
    /*commented for cleaning up of Insightflow 1.0 components
public static testmethod void ThankyouData3(){
WF_Request__c objReq = new WF_Request__c();
objReq.Status__c = 'Draft';
insert objReq;
system.assertEquals('Draft',objReq.Status__c);
ApexPages.currentPage().getParameters().put('id',objReq.id);
IFv2_ThankYouForWaitingController obj = new IFv2_ThankYouForWaitingController();
IFv2_ThankYouForWaitingController.redirectToActualRecord(); 
}

public static testmethod void ThankyouDataDelete(){
WF_Request__c objReq = new WF_Request__c();
objReq.Status__c = 'Draft';
insert objReq;
system.assertEquals('Draft',objReq.Status__c);
IFv2_ThankYouForWaitingController.redirectToActualRecord();
} */
}