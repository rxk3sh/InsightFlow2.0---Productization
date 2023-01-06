/*******************************************************************************************************
* 
* @ Name    	:   IFv2_GenericRelatedListControllerTest
* @ Purpose 	:   Test class for generic related list
* @ Author  	:   Madhura Vani
* @ Class Name	:	IFv2_GenericRelatedListController
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   02-01-2018      |  madhuravani.b@absyz.com      |  1.0          |  Initial Version
*
*******************************************************************************************************/
@isTest
public class IFv2_GenericRelatedListControllerTest {
    public static contact objCon;
    public static Account objAcc;
    public static User objUser;
    public static list<IFv2_Request__c> lstsObject ;
    @testsetup static void createTestData() {
        objAcc = IFv2_testDataUtility.createAccount();
        objAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Internal').getRecordTypeId();
        insert objAcc;
        
        objCon = IFv2_testDataUtility.createContact(objAcc);
        insert objCon;
        
        objUser = IFv2_testDataUtility.createUser();
        objUser.IFv2_ByPassValidation__c = true;
        insert objUser;
        
        system.runAs(objUser)
        {
            lstsObject = IFv2_testDataUtility.createRequestWithOldRequest('HU Scrapping WorkOn');
            insert lstsObject ;
        }
        
        objUser.IFv2_ByPassValidation__c = false;
        update objUser; 
        System.assertEquals(true, objUser.IFv2_ByPassValidation__c == false);
    }
    
    /*commented for cleaning up of Insightflow 1.0 components
* public static testmethod void relatedListData(){
test.startTest();

RecordType objRecordType = [SELECT id,Name FROM RecordType WHERE SobjectType = 'Account' and Name = 'Request Items' Limit 1]; 
objUser = [select id,name from User limit 1];
System.assertEquals(true, objUser!=Null);

Workflow__c oldWorkflow = IFv2_testDataUtility.createOldWorkflow();
insert oldWorkflow;

Request_EMEA__c oldRequest = IFv2_testDataUtility.createRequestEMEA(oldWorkflow, objUser);
insert oldRequest;

IFv2_Request__c objReq = [select id,name,oldrequest__c,status__c from IFv2_Request__c limit 1];
objReq.OldRequest__c = oldRequest.Id;
update objReq;
System.assertEquals(true, objReq.OldRequest__c == oldRequest.Id);

objAcc = [select id,name,IFv2_ContentType__c,IFv2_ChinaMAE__c,IFv2_PersonnelNo__c,IFv2_LegacyAssignedTo__c,IFv2_LegacyActualApprover__c,IFv2_Legacysubmitter__c from Account limit 1];
System.assertEquals(true, objAcc != Null);

Account accountForContact = new Account();
accountForContact.Name = 'Account for Contact';
accountForContact.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Internal').getRecordTypeId();
insert accountForContact;
System.assertEquals(true, accountForContact.Name == 'Account for Contact');
objCon = IFv2_testDataUtility.createContact(accountForContact);
insert objCon;

objAcc.IFv2_ContentType__c = 'Approval History';
objAcc.RecordtypeId = objRecordType.id;
objAcc.IFv2_Request__c = objReq.id;
objAcc.IFv2_ChinaMAE__c = 'test';
objAcc.IFv2_PersonnelNo__c = objCon.id;
objAcc.IFv2_LegacyStatus__c = 'Approved';
objAcc.IFv2_LegacyAssignedTo__c = string.valueOf(objUser.Id);
objAcc.IFv2_LegacyActualApprover__c = string.valueOf(objUser.Id);
objAcc.IFv2_Legacysubmitter__c = string.valueOf(objUser.Id); 
update objAcc;
System.assertEquals(true, objAcc.IFv2_ChinaMAE__c == 'test');
System.assertEquals(true, objAcc.IFv2_LegacyStatus__c == 'Approved');

string strquery = 'IFv2_PersonnelNo__c,IFv2_ChinaMAE__c,IFv2_LegacyActualApprover__c,IFv2_LegacyAssignedTo__c,IFv2_LegacyComments__c,IFv2_LegacyStatus__c,IFv2_Legacysubmitter__c';
IFv2_GenericRelatedListController.getForm(objReq.id,'Account');
Approval.ProcessSubmitRequest requestitem = new Approval.ProcessSubmitRequest();
//set the target objcet as request 
requestitem.setObjectId(objReq.id);
//pass user id which will be coming from approval process
requestitem.setNextApproverIds(new Id[] {UserInfo.getUserId()});
//set comments 
requestitem.setComments('Submitted for approval. Please approve.');
//submit the approval process
Approval.ProcessResult result = Approval.process(requestitem);


set<string> setConIds = new  set<string>();
setConIds.add(objCon.id);
IFv2_GenericRelatedListController.fetchContactNames(setConIds);

set<string> setUserIds = new  set<string>();
setUserIds.add(objUser.id);
IFv2_GenericRelatedListController.fetchUserNames(setUserIds);
test.stopTest();
} */
    
    public static testmethod void createRecordMethod(){ 
        test.startTest();
        
        RecordType objRecordType = [SELECT id,Name FROM RecordType WHERE SobjectType = 'Account' and Name = 'Request Items' Limit 1]; 
        IFv2_Request__c objReq = new IFv2_Request__c();
        objReq.Status__c = 'Draft';
        objReq.Workflow__c = 'China MAE Application - Combine';
        objReq.OldRequest__c = null;
        insert objReq;
        system.assertEquals(true, objReq.Workflow__c == 'China MAE Application - Combine');
        
        Account accountForContact = new Account();
        accountForContact.Name = 'Account for Contact';
        accountForContact.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Internal').getRecordTypeId();
        insert accountForContact;
        system.assertEquals(true, accountForContact.Name == 'Account for Contact');
        
        objCon = IFv2_testDataUtility.createContact(accountForContact);
        insert objCon;
        system.assertEquals(true, objCon != Null);
        
        objUser = [select Id,Name from User limit 1];
        system.assertEquals(true, objUser != Null);
        
        objAcc = [select id,name,IFv2_LegacyActualApprover__c,IFv2_PersonnelNo__c,IFv2_LegacyAssignedTo__c,IFv2_Legacysubmitter__c from Account limit 1];
        objAcc.IFv2_ContentType__c = 'China MAE Combine';
        objAcc.IFv2_ChinaMAE__c = 'Test MAE';
        objAcc.RecordtypeId = objRecordType.id;
        objAcc.Ifv2_Request__c = objReq.id;
        objAcc.IFv2_PersonnelNo__c = objCon.id;
        objAcc.IFv2_LegacyAssignedTo__c = string.valueOf(objUser.Id);
        objAcc.IFv2_LegacyActualApprover__c = string.valueOf(objUser.Id);
        objAcc.IFv2_Legacysubmitter__c = string.valueOf(objUser.Id);
        update objAcc; 
        system.assertEquals(true, objAcc.IFv2_ChinaMAE__c == 'Test MAE');
        system.assertEquals(true, objAcc.IFv2_ContentType__c == 'China MAE Combine');
        
        string strquery = 'IFv2_LegacyActualApprover__c,IFv2_ChinaMAE__c,IFv2_PersonnelNo__c,IFv2_LegacyAssignedTo__c,IFv2_LegacySubmitter__c';
        try{
            IFv2_GenericRelatedListController.createRecord(string.valueOf(objReq.id),'China MAE Combine',objAcc,objReq,strquery);
        } catch (TypeException ee) {
            System.assertEquals(
                'Procedure is only valid for System.DmlException and System.MailException',
                ee.getMessage()
            );
        }
    }
    
    public static testmethod void deleteRecordMethod(){ 
        test.startTest();
        IFv2_Request__c objReq = [select id,name,oldrequest__c,status__c from IFv2_Request__c limit 1];
        objAcc = [select id,name,IFv2_ContentType__c,IFv2_ChinaMAE__c,IFv2_PersonnelNo__c,IFv2_LegacyAssignedTo__c,IFv2_LegacyActualApprover__c,IFv2_Legacysubmitter__c from Account limit 1];
        System.assertEquals(true, objAcc != Null);
        
        Account accountForContact = new Account();
        accountForContact.Name = 'Account for Contact';
        accountForContact.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Internal').getRecordTypeId();
        insert accountForContact;
        objCon = IFv2_testDataUtility.createContact(accountForContact);
        insert objCon;
        
        objUser = [select id,name from User limit 1];
        system.assertEquals(true, objUser != Null);
        
        objAcc.IFv2_ContentType__c = 'China MAE Lost';
        objAcc.RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Items').getRecordTypeId();
        objAcc.IFv2_Request__c = objReq.id;
        objAcc.IFv2_ChinaMAE__c = 'test';
        objAcc.IFv2_PersonnelNo__c = objCon.id;
        
        objAcc.IFv2_LegacyAssignedTo__c = string.valueOf(objUser.Id);
        objAcc.IFv2_LegacyActualApprover__c = string.valueOf(objUser.Id);
        objAcc.IFv2_Legacysubmitter__c = string.valueOf(objUser.Id); 
        
        update objAcc;
        system.assertEquals(true, objAcc.IFv2_ChinaMAE__c == 'test');
        system.assertEquals(true, objAcc.IFv2_ContentType__c == 'China MAE Lost');
        
        string strquery = 'IFv2_PersonnelNo__c,IFv2_ChinaMAE__c,IFv2_LegacyActualApprover__c,IFv2_LegacyAssignedTo__c,IFv2_LegacyComments__c,IFv2_LegacyStatus__c,IFv2_Legacysubmitter__c';
        
        IFv2_GenericRelatedListController.deleteRecord(objAcc.id,objReq.id,strquery,'China MAE Lost');
        
        
        set<string> setConIds = new  set<string>();
        setConIds.add(objCon.id);
        IFv2_GenericRelatedListController.fetchContactNames(setConIds);
        
        objUser = [select id,name from User limit 1];
        System.assertEquals(true, objUser != Null);
        set<string> setUserIds = new  set<string>();
        setUserIds.add(objUser.id);
        IFv2_GenericRelatedListController.fetchUserNames(setUserIds);
        test.stopTest();
    }
    
    private static testmethod void notesData(){
        Test.startTest();
        lstsObject = [select id,name,Status__c from IFv2_Request__c];
        
        //inserting Document
        Document doc = new Document(FolderId = UserInfo.getUserId() ,Name='mySampleFile', Body = Blob.ValueOf('Hello World'));
        insert doc;
        System.assertEquals(true, doc.Name == 'mySampleFile');
        
        IFv2_GenericRelatedListController.fetchAttachmentList(lstsObject[0].id);
        Test.stopTest();
        
    }
}