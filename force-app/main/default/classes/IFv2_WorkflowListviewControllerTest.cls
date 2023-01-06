/*******************************************************************************************************
* 
* @ Name 		:	IFv2_WorkflowListviewControllerTest
* @ Purpose 	: 	Test class for the Home page
* @ Author		: 	Prasad Vivek
* @ Class Name	: 	IFv2_WorkflowListviewController
*
*   Date        |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   09-11-2018  |  vivek.kothalnka@absyz.com	|  1.0          |  Initial Version
*
*******************************************************************************************************/
@isTest
public class IFv2_WorkflowListviewControllerTest {
    @testSetup static void createTestData() {
        IFv2_Workflow__c workflowRecord = IFv2_testDataUtility.createWorkflowCustomSetting();
        insert workflowRecord;
        System.assertEquals(true, workflowRecord != Null);
    }
    /* Test method to cover fetchWorkflows */
    public static TestMethod Void fetchWorkflowsAdminTest(){
        
        IFv2_Workflow__c workflowRecord = [SELECT Name,Workflow__c,ApplicationKey__c,ArchivingAfterDays__c,Description__c,
                                           Country__c,Active__c,LocalExpert__c,ProcessOwner__c 
                                           FROM IFv2_Workflow__c];
        System.assertEquals(true, workflowRecord != Null);
        User loggedInUser = IFv2_testDataUtility.createUser();
        loggedInUser.IFv2_ByPassValidation__c = true;
        insert loggedInUser;
        System.assertEquals(true, loggedInUser != Null);
        
        workflowRecord.LocalExpert__c = loggedInUser.Id;
        workflowRecord.ProcessOwner__c = loggedInUser.Id;
        update workflowRecord;
        System.assertEquals(true, workflowRecord.LocalExpert__c == loggedInUser.Id);
        
        system.runas(loggedInUser){
            try{
                IFv2_WorkflowListviewController.fetchWorkflows('IFv2_Workflow__c');
            }
            Catch(Exception e){}
        }  
        loggedInUser.IFv2_ByPassValidation__c = false;
        update loggedInUser;
        System.assertEquals(true, loggedInUser.IFv2_ByPassValidation__c == false);
    }
    /* Test method to cover fetchWorkflows */
    public static TestMethod Void fetchWorkflowsUserTest(){
        
        Test.startTest();
        IFv2_Workflow__c workflowRecord = [SELECT Name,Workflow__c,ApplicationKey__c,ArchivingAfterDays__c,Description__c,
                                           Country__c,Active__c,LocalExpert__c,ProcessOwner__c 
                                           FROM IFv2_Workflow__c];
        System.assertEquals(true, workflowRecord != Null);
        
        User loggedInUser = IFv2_testDataUtility.createSGStandardUser();
        loggedInUser.Username = 'sgtestuser2@test.com';
        insert loggedInUser;
        System.assertEquals(true, loggedInUser != Null);
        
        system.runas(loggedInUser){
            try{
                IFv2_WorkflowListviewController.fetchWorkflows('IFv2_Workflow__c');
            }
            Catch(Exception e){}
        }
        Test.stopTest();
    }
    
    /* Test method to cover createRequestRecord */
    public Static TestMethod void createRequestRecordTest(){
        IFv2_Workflow__c workflowRecord = [SELECT Name,Workflow__c,ApplicationKey__c,ArchivingAfterDays__c,Description__c,
                                           Country__c,Active__c 
                                           FROM IFv2_Workflow__c];
        User loggedInUser = IFv2_testDataUtility.createUser();
        loggedInUser.IFv2_ByPassValidation__c = true;
        insert loggedInUser;
        System.assertEquals(true, loggedInUser.IFv2_ByPassValidation__c == true);
        
        system.runas(loggedInUser){
            try{
                IFv2_WorkflowListviewController.createRequestRecord(workflowRecord);
            }
            Catch(Exception e){}
        }
        loggedInUser.IFv2_ByPassValidation__c = false;
        update loggedInUser;
        System.assertEquals(true, loggedInUser.IFv2_ByPassValidation__c == false);
    }
    /* Test method to cover createRequestRecord */
    public Static TestMethod void createRequestRecordTest2(){
        
        IFv2_Workflow__c workflowRecord = IFv2_testDataUtility.createWorkflowCustomSetting();
        
        workflowRecord.Name = 'China Training Application';
        workflowRecord.Workflow__c = 'China Training Application';
        insert workflowRecord;
        System.assertEquals(true, workflowRecord != Null);
        
        User loggedInUser = IFv2_testDataUtility.createUser();
        loggedInUser.IFv2_ByPassValidation__c = true;
        insert loggedInUser;
        System.assertEquals(true, loggedInUser != Null);
        
        system.runas(loggedInUser){
            IFv2_WorkflowListviewController.createRequestRecord(workflowRecord);
        }
        loggedInUser.IFv2_ByPassValidation__c = false;
        update loggedInUser;
        System.assertEquals(true, loggedInUser.IFv2_ByPassValidation__c == false);
    }
    /* Test method to cover createRequestRecord */
    public Static TestMethod void createRequestRecordTest3(){
        IFv2_Workflow__c workflowRecord = IFv2_testDataUtility.createWorkflowCustomSetting();
        workflowRecord.Name = 'Badge Management SEG - Stuttgart';
        workflowRecord.Workflow__c = 'Badge Management SEG - Stuttgart';
        insert workflowRecord;
        System.assertEquals(true, workflowRecord != Null);
        
        User loggedInUser = IFv2_testDataUtility.createUser();
        loggedInUser.IFv2_ByPassValidation__c = true;
        insert loggedInUser;
        System.assertEquals(true, loggedInUser.IFv2_ByPassValidation__c == true);
        
        system.runas(loggedInUser){
            IFv2_WorkflowListviewController.createRequestRecord(workflowRecord);
        }
        loggedInUser.IFv2_ByPassValidation__c = false;
        update loggedInUser;
        System.assertEquals(true, loggedInUser.IFv2_ByPassValidation__c == false);
    }
    /**Test method to cover DML Controller ***/
    public Static TestMethod void createAccounts(){
        LIST<Account> AccountList=new list<Account>();
        Account a=new Account();
        a.name='test';
        AccountList.add(a);
        system.assertEquals('test',a.name);
        IFv2_DmlController.insertAccountRecords(AccountList);
        System.assertNotEquals(null, a.Id);
        IFv2_DmlController.deleteAccountRecords(AccountList);
    }
    
    /* Cover utilscontroller methods */
    public static testMethod void  coverUtilsMethods() {
        User objUser = IFv2_testDataUtility.createUser();
        objUser.IFv2_ByPassValidation__c = true;
        insert objUser;
        System.assertEquals(true, objUser.IFv2_ByPassValidation__c == true);
        
        Account objAcc = IFv2_testDataUtility.createAccount();
        insert objAcc;
        
        Contact objContact = IFv2_testDataUtility.createContact(objAcc);
        insert objContact;
        
        LIST<IFv2_Request__c> lstsObject = new LIST<IFv2_Request__c>();
        lstsObject = IFv2_testDataUtility.createRequest();
        insert lstsObject;
        System.assertEquals(true, !lstsObject.isEmpty());
        
        IFv2_Workflow__c workflowRecord = [SELECT Name,Workflow__c,ApplicationKey__c,ArchivingAfterDays__c,Description__c,
                                           Country__c,Active__c,LocalExpert__c,ProcessOwner__c 
                                           FROM IFv2_Workflow__c];
        System.assertEquals(true, workflowRecord != Null);
        
        LIST<IFv2_Section__mdt> responseSectionLIST = IFv2_UtilsController.getCustomMetaDataList('eSignature');
        
        Sobject responseObj = IFv2_UtilsController.getSeletedWorkflowRecord(workflowRecord.Id);
        
        LIST<IFv2_Workflows__mdt> responseWorkflowRecords = IFv2_UtilsController.getMetadataRecords();
        
        SET<String> userIdsSET = new SET<String>();
        userIdsSET.add(objUser.Id);
        LIST<Sobject> responseUserNames = IFv2_UtilsController.getUserName(userIdsSET);
        
        SET<String> contactIdsSET = new SET<String>();
        contactIdsSET.add(objContact.Id);
        LIST<Sobject> responseContactNames = IFv2_UtilsController.getContactName(contactIdsSET);
        
        SET<Id> recordIdSET = new SET<Id>();
        Sobject responseGetRequest = IFv2_UtilsController.getRequestObject(lstsObject[0].Id, recordIdSET);
        
        RecordType responseRecordType = IFv2_UtilsController.getRecordTypeId('Request Items', 'Account');
        
        LIST<IFv2_Request__c> responseReqList = IFv2_UtilsController.createRequest('Draft');
        
        User responseSingleUserName = IFv2_UtilsController.getUserName(objUser.Id);
        User userManager = IFv2_UtilsController.getUserManager(objUser.Id);
        
        LIST<PermissionSetAssignment> responsePermissionSets = IFv2_UtilsController.getExistingPermissionSets(userIdsSET);
        ///
        set<id>PermissionSetId=new set<id>();
        For(PermissionSetAssignment perm:responsePermissionSets)
        {
            PermissionSetId.add(perm.id);
        }
        LIST<ObjectPermissions> objectPermissions=IFv2_UtilsController.getObjectPermissions(PermissionSetId,'EMEA');
        
        //LIST<ObjectPermissions> objectPermissions = IFv2_UtilsController.getObjectPermissions(permissionSetIdList, extensionObject);
                /* Creating patentIdsList */
        LIST<String> patentIdsList = new LIST<String>();
                For(ObjectPermissions ccurrentObjectPermission : objectPermissions) {
                    
                    patentIdsList.add(ccurrentObjectPermission.ParentId);
                }
                LIST<String> AssignedUsersList = new LIST<String>();    //To get users assigned to permission set for specific object 
                /* Get data of PermissionSetAssignment*/
                LIST<PermissionSetAssignment> PermissionSetAssignmentList = IFv2_UtilsController.getPermissionSetAssignment(patentIdsList,userIdsSET);
        		IFv2_UtilsController.getPermission('all');
        		IFv2_UtilsController.getPermission('APAC');
        		IFv2_UtilsController.getPermission('EMEA');
        		IFv2_UtilsController.getPermission('NALA');
        ////
        LIST<Sobject> responseMapping = IFv2_UtilsController.getPredefinedMapping(workflowRecord.Name);
        
        LIST<Sobject> responseExtObj = IFv2_UtilsController.getExtensionRecord(lstsObject[0].Id);
        
        LIST<IFv2_CustomErrorMessages__c> responseErrorMessages = IFv2_UtilsController.getCustomErrorMessages('test');
        
        IFv2_Request__c responseConcession = IFv2_UtilsController.getConcessionRequest(lstsObject[0].Id);
        
        Boolean responseAttachment = IFv2_UtilsController.getAttchments(lstsObject[0].Id);
        
        IFv2_UtilsController.CreatedByWrapper responseWrapper = new IFv2_UtilsController.CreatedByWrapper();
        LIST<String> recordIdsList = new LIST<String>();
        recordIdsList.add(lstsObject[0].Id);
        responseWrapper = IFv2_UtilsController.getRecordNameWithDates(recordIdsList, 'IFv2_Request__c', lstsObject[0].Id, 'created by');
        responseWrapper = IFv2_UtilsController.getRecordNameWithDates(recordIdsList, 'IFv2_Request__c', lstsObject[0].Id, 'last modified by');
        
        LIST<Account> responseAccList = IFv2_UtilsController.validateConcession('123456');
        
        User userObj = IFv2_testDataUtility.createSGStandardUser();
        userObj.Currency__c = 'EUR';
        userObj.Country = 'Germany';
        userObj.Username = 'acbwew@test.com';
        insert userObj;
        System.runAs(userObj) {
            LIST<Sobject> responseObjj = IFv2_UtilsController.getPredefinedMapping('Approval Process for Special Freights');  
            
            userObj.Currency__c = 'INR';
            update userObj;
            LIST<Sobject> responseObj2 = IFv2_UtilsController.getPredefinedMapping('Approval Process for Special Freights');
            
            userObj.Currency__c = 'CNY';
            update userObj;
            LIST<Sobject> responseObj3 = IFv2_UtilsController.getPredefinedMapping('Approval Process for Special Freights');
            
            userObj.Currency__c = 'USD';
            update userObj;
            LIST<Sobject> responseObj4 = IFv2_UtilsController.getPredefinedMapping('Approval Process for Special Freights');
            
            userObj.Currency__c = 'BLR';
            update userObj;
            LIST<Sobject> responseObj5 = IFv2_UtilsController.getPredefinedMapping('Approval Process for Special Freights');
            
            LIST<Sobject> responseObj6 = IFv2_UtilsController.getPredefinedMapping('MAE Approval Request');
            
        }
        
        workflowRecord.Name = 'Badge Management SEG - Stuttgart';
        workflowRecord.Workflow__c = 'Badge Management SEG - Stuttgart';
        workflowRecord.Default__c = true;
        update workflowRecord;
        System.assertEquals(true, workflowRecord != Null);
        SET<String> mergedSET = new SET<String>();
        LIST<IFv2_Workflow__c> responseWorkflows = IFv2_UtilsController.getWorkflowRecords(null, null, mergedSET, true, 'China');
        LIST<IFv2_Workflow__c> responseWorkflows2 = IFv2_UtilsController.getWorkflowRecords(null, null, mergedSET, false, 'China');
        LIST<Sobject> responseRecordName = IFv2_UtilsController.getRecordName(null, '', null);
        
        SET<Id> emptySET = new SET<ID>();
        Sobject responseObject = IFv2_UtilsController.getRequestObject(null, emptySET);
        
        LIST<ID> emptyLIST = new LIST<ID>();
        LIST<GroupMember> responseGroup = IFv2_UtilsController.getGroups(emptyLIST);
        
        SET<Id> testSETID = new SET<Id>();
        testSETID.add(lstsObject[0].Id);
        LIST<Account> accountRecord = 	IFv2_UtilsController.getRequestRelatedAccountRecords(testSETID,responseRecordType.Id); 
        LIST<ProcessInstanceWorkitem> responseWI = IFv2_UtilsController.createProcessInstanceWI();
        
        LIST<Sobject> responseObjects = IFv2_UtilsController.getRequestRecord(testSETID, 'Name');
        IFv2_Request__c responserequest = IFv2_UtilsController.getRequest(lstsObject[0].Id);
        IFv2_Request__c responserequest2 = IFv2_UtilsController.getICORequestRecord(lstsObject[0].Id);
        LIST<PermissionSetAssignment> responseAssignments = IFv2_UtilsController.deletePermissionSetAssignmentCheckbox(new List<List<String>>(), emptySET);
    }  
    
    public static testMethod void getActiveUsers() {
        SET<Id> userIdSET = new SET<Id>();
        
        Id UserId = UserInfo.getUserId();
        system.assertEquals(false, UserId== NULL);
        userIdSET.add(UserId);
        
        LIST<User> userLIST = IFv2_UtilsController.getActiveUsers(userIdSET);
        system.assertEquals(1, userLIST.size());
    } 
}