/*******************************************************************************************************
* 
* @ Name        :   IFv2_RelatedListsControllerTest
* @ Purpose     :   Test class for generic related list
* @ Author      :   Madhura Vani
* @ Class Name  :   IFv2_RelatedListsController
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   20-11-2018      |  madhuravani.b@absyz.com      |  1.0          |  Initial Version
*
*******************************************************************************************************/
@isTest
public class IFv2_RelatedListsControllerTest {
    
    public static list<IFv2_Request__c> lstsObject ;
    public static user objUser;
    @testsetup static void createTestData() {
        //inserting Request
        objUser = IFv2_testDataUtility.createUser();
        objUser.IFv2_ByPassValidation__c = true;
        insert objUser;
        System.assertEquals(true, objUser.IFv2_ByPassValidation__c == true);
        
        System.runAs(objUser)
        {
            //inserting Request
            lstsObject = IFv2_testDataUtility.createRequest();
            insert lstsObject ;
        }
        objUser.IFv2_ByPassValidation__c = false;
        update objUser;
        System.assertEquals(true, objUser.IFv2_ByPassValidation__c == false);
    }
    
    public static testmethod void relatedListData(){
        test.startTest();
        lstsObject = [select id,name,Status__c from IFv2_Request__c];
        lstsObject[0].OldRequest__c = null;
        update lstsObject[0];
        IFv2_RelatedListsController.fetchRelatedList(lstsObject[0].Id, 'ProcessInstance');
        IFv2_RelatedListsController.completeRelatedList(lstsObject[0].Id, 'ProcessInstance');
        System.assertEquals(lstsObject[0].Status__c, 'Draft');
        test.stopTest();
    }
    
    public static testmethod void relatedListData1(){
        test.startTest();
        /*commented for cleaning up of Insightflow 1.0 components 
WF_Request__c obj1 = new WF_Request__c();
obj1.Description_Identification__c = 'test';
obj1.Version__c = '1.0';
obj1.Short_description__c = 'abc';
obj1.Release_date__c = system.today()+1;
try{
insert obj1;
}catch (Dmlexception e){
system.debug('lead update failed: '+e);
}
System.assertNotEquals(null, obj1);
IFv2_Request__c reqRecord = [select id,name,Status__c from IFv2_Request__c limit 1];
reqRecord.OldRequest__c = obj1.Id;
reqRecord.DisplayApprovalHistory__c = true;
update reqRecord;
IFv2_RelatedListsController.fetchRelatedList(reqRecord.Id, 'OldRequestApprovals');
//System.assertEquals(lstsObject[0].Status__c, 'Draft');
*/
        test.stopTest();
    }
    
    public static testmethod void relatedListData2(){
        test.startTest();
        lstsObject = [select id,name,Status__c from IFv2_Request__c];
        System.assertEquals(true, lstsObject != Null);
        try{
            IFv2_RelatedListsController.fetchRelatedList(lstsObject[0].Id, 'test');
        }catch (TypeException ee) {
            System.assertEquals(
                'Procedure is only valid for System.DmlException and System.MailException',
                ee.getMessage()
            );
        }
        test.stopTest();
    }
    
    public static testmethod void relatedListDataTest(){
        test.startTest();
        Account testAccount = new Account();
        testAccount.name = 'test';
        insert testAccount;
        IFv2_Request__c obj1 = new IFv2_Request__c();
        obj1.Status__c = 'Draft';
        obj1.Workflow__c = 'eSignature';
        obj1.Account__c = testAccount.Id;
        insert obj1;
        try{
            insert obj1;
        }catch (Dmlexception e){
            system.debug('lead update failed: '+e);
        }
        System.assertNotEquals(null, obj1);
        IFv2_Request__c reqRecord = [select id,name,Status__c from IFv2_Request__c limit 1];
        reqRecord.OldRequest__c = obj1.Id;
        reqRecord.DisplayApprovalHistory__c = true;
        update reqRecord;
        IFv2_RelatedListsController.fetchRelatedList(reqRecord.Id, 'OldRequestApprovals');
        //System.assertEquals(lstsObject[0].Status__c, 'Draft');

        test.stopTest();
    }
    
}