/*******************************************************************************************************
* 
* @ Name   	 		: IFv2_DmlController
* @ Purpose 		: Base controller for all the DML queries
* @ Author  		: Pradeep Chary
* Test class name	: IFv2_FieldSetFormControllerTest 
*
*   Date        |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   31-10-2018  |  pradeep.chary@absyz.com      |  1.0          |  Initial Version
*   08-09-2018  |  madhuravani.b@absyz.com      |  1.1          |  Generic DML operations
*   22/04-2019	|  vivek.kothalanka@absyz.com	|  1.2			|  Added logic to insert Account Share Records
*
*******************************************************************************************************/

public without sharing class IFv2_DmlController {
    
    /* To insert a Request record and an Account record */
    public static Id insertRequestRecord(IFv2_Workflow__c workflow) {
        IFv2_Request__c insertedRequest = new IFv2_Request__c();
        try {
            /* Request record insertion - Start */
            IFv2_Request__c request = new IFv2_Request__c();
            request.Workflow__c = workflow.Workflow__c;
            request.put('WorkflowId__c',workflow.Id);
			request.put('Local_Expert_Id__c',workflow.LocalExpert__c);
            /* list for mapping of roles from workflow detail page to request detail page*/
            LIST<IFv2_PredefinedWorkflowFields__mdt> predefinedFieldLIST = IFv2_UtilsController.getPredefinedFields(workflow.Workflow__c);
            if(!predefinedFieldLIST.isEmpty()) {
                for(IFv2_PredefinedWorkflowFields__mdt iterator : predefinedFieldLIST) {
                    request.put(iterator.RequestFieldApi__c, workflow.get(iterator.WorkflowField__c));
                }
            }
            
            GenericDMLOperation(request, 'insert');		//Request insert
            /* Request record insertion - End */
            
            String Region = IFv2_UtilsController.getWorkflows(workflow.Workflow__c); //Gets the region of the executed Workflow
            if(request.Id != null){
                insertedRequest = IFv2_UtilsController.getInsertedRequest(request.Id);
            }
            if(insertedRequest != null){
                if(Region == 'All') {
                    
                    /* Extension record Account insertion - Start */
                    Account accountRecord = new Account();
                    accountRecord.put('recordtypeid', Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Extension').getRecordTypeId());
                    
                    accountRecord.Name = insertedRequest.Name.replace('INF','ACC');
                    accountRecord.IFv2_Request__c = insertedRequest.Id;
                    accountRecord.IFv2_Workflow__c = insertedRequest.Workflow__c;
                    accountRecord.Plant__c = 'SGNA';
                    GenericDMLOperation(accountRecord, 'insert');	//Insert Account as an Extension 
                    insertedRequest.Account__c = accountRecord.Id;
                    /* Extension record Account insertion - End */
                    
                } else if(Region == 'APAC') {
                    
                    /* Extension record APAC insertion - Start */
                    IFv2_RequestExtension1__c Extension1 = new IFv2_RequestExtension1__c();
                    Extension1.Name = insertedRequest.Name;
                    Extension1.WorkflowName__c = insertedRequest.Workflow__c;
                    GenericDMLOperation(Extension1, 'insert');	//Insert IFv2_RequestExtension1__c as an Extension
                    insertedRequest.RequestExtension1__c = Extension1.Id;
                    /* Extension record APAC insertion - End */
                    
                } else if(Region == 'EMEA') {
                    
                    /* Extension record EMEA insertion - Start */
                    IFv2_RequestExtension2__c Extension2 = new IFv2_RequestExtension2__c();
                    Extension2.Name = insertedRequest.Name;
                    Extension2.WorkflowName__c = insertedRequest.Workflow__c;
                    GenericDMLOperation(Extension2, 'insert');		//Insert IFv2_RequestExtension2__c as an Extension
                    insertedRequest.RequestExtension2__c = Extension2.Id;
                    /* Extension record EMEA insertion - End */
                    
                } else if(Region == 'NALA') {
                    
                    /* Extension record NALA insertion - Start */
                    IFv2_RequestExtension3__c Extension3 = new IFv2_RequestExtension3__c();
                    Extension3.Name = insertedRequest.Name;
                    Extension3.WorkflowName__c = insertedRequest.Workflow__c;
                    GenericDMLOperation(Extension3, 'insert');		//Insert IFv2_RequestExtension3__c as an Extension
                    insertedRequest.RequestExtension3__c = Extension3.Id;
                    /* Extension record NALA insertion - End */
                }
                
                GenericDMLOperation(insertedRequest, 'update');		//Update Inserted request with the extension Id
            }
        } catch(DMLException de) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(de);
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }
        
        if(insertedRequest != null) {
            return insertedRequest.Id;
        } else {
            return null;
        }
    }
    
    /* To clone a Request record */
    public static Id cloneRequestRecord(IFv2_Request__c requestRecord,MAP<String,LIST<String>> extFieldMap) {
        String extObjectName;
        String extRecordId;
        String extRelName;
        LIST<String> fieldList = new LIST<String>{'Id'};
            if(requestRecord != null){
                if(requestRecord.get('RequestExtension1__c')!=null) {    //APAC
                    extRelName = 'RequestExtension1__c';
                    extObjectName = 'IFv2_RequestExtension1__c';
                    extRecordId = String.valueOf(requestRecord.get('RequestExtension1__c'));
                    if(extFieldMap.containsKey('RequestExtension1__c')) {
                        fieldList = extFieldMap.get('RequestExtension1__c');    //Adding fields on Extension 1 to clone
                    }
                } else if(requestRecord.get('RequestExtension2__c')!=null) {    //EMEA
                    extRelName = 'RequestExtension2__c';
                    extObjectName = 'IFv2_RequestExtension2__c';
                    extRecordId = String.valueOf(requestRecord.get('RequestExtension2__c'));
                    if(extFieldMap.containsKey('RequestExtension2__c')) {
                        fieldList = extFieldMap.get('RequestExtension2__c');    //Adding fields on Extension 2 to clone
                    }
                } else if(requestRecord.get('RequestExtension3__c')!=null) {    //NALA
                    extRelName = 'RequestExtension3__c';
                    extObjectName = 'IFv2_RequestExtension3__c';
                    extRecordId = String.valueOf(requestRecord.get('RequestExtension3__c'));
                    if(extFieldMap.containsKey('RequestExtension3__c')) {
                        fieldList = extFieldMap.get('RequestExtension3__c');    //Adding fields on Extension 3 to clone
                    }
                } else if(requestRecord.get('Account__c')!=null) {
                    extRelName = 'Account__c';
                    extObjectName = 'Account';
                    extRecordId = String.valueOf(requestRecord.get('Account__c'));
                    if(extFieldMap.containsKey('Account__c')) {
                        fieldList = extFieldMap.get('Account__c');    //Adding fields on Account to clone
                    }
                }
                for(String field:fieldList){
                    system.debug(field);
                }
                GenericDMLOperation(requestRecord, 'insert');    //inserting the new cloned request after mapping fields from the parent request
                if(requestRecord.Id != null){
                    if(extRecordId != null) {
                        SObject insertedRecord = IFv2_UtilsController.getInsertedRequest(requestRecord.Id);    //getting the cloned record
                        MAP<String,Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(extObjectName).getDescribe().fields.getMap();
                        String query = 'SELECT ' + String.join(fieldList,',') + 
                            ' FROM ' + extObjectName + ' WHERE Id=\'' + extRecordId + '\'';
                        LIST<SObject> recList = Database.query(query);    //querying for extension fields to insert values
                        if(!recList.isEmpty()) {
                            SObject extRecord = recList[0];
                            extRecord.put('Id', null);
                            extRecord.put('OwnerId',UserInfo.getUserId());
                            extRecord.put('Name',insertedRecord.get('Name'));
                            
                            // To Nullify values on clone 
                            if(extObjectName == 'IFv2_RequestExtension1__c') {
                                extRecord.put('TotalOriginalValue__c', null);
                                extRecord.put('TotalNetBookValue__c', null);
                                if(requestRecord.Workflow__c == Label.CLIFv20199 || requestRecord.Workflow__c == Label.CLIFv20200){
                                    extRecord.put('DueDateofReturn__c',null);
                                }
                            } else if(extObjectName == 'Account') {
                                extRecord.put('IFv2_NotificationNo__c', null);
                            }
                            GenericDMLOperation(extRecord, 'insert');    //inserting extension object fields
                            requestRecord.put(extRelName,extRecord.get('Id'));    //setting extension id to the new request record
                        }
                        GenericDMLOperation(requestRecord, 'update');    //updating the new request after setting the extension id
                    }
                }
                /*Check for ICO requests other than ICO 6 and submit for approval immediately after cloning*/
                if(requestRecord.Id != null){
                    if(requestRecord.Workflow__c.containsIgnoreCase(system.label.CLIFv20136) && !requestRecord.Workflow__c.equals(system.label.CLIFv20250)){
                    	Sobject SobjectTypeRecord = (Sobject)requestRecord;
                		LIST<IFv2_HeaderController.ApproverSectionWrapper> approverSectionList = IFv2_HeaderController.getApproverSectionWrapper(requestRecord.Id, requestRecord.Workflow__c);
                		System.debug('Approver Section::'+approverSectionList);
                		String statusOfSubmition = IFv2_HeaderController.submitForApproval(SobjectTypeRecord,approverSectionList);
                    }
                }
                return requestRecord.Id;
            }
        else return null;
    }
    
    /* To Delete a Request record */
    public static void deleteRequestRecord (id requestId) {
        IFv2_Request__c requestRecord = new IFv2_Request__c();
        if(requestId != null) {
            requestRecord.Id = requestId;
            GenericDMLOperation(requestRecord, 'delete');    //deleting the request record
        }
    }
    
    /* To Update a Request record */
    public static void updateRequestRecord (IFv2_Request__c requestRecord) {
        if(requestRecord != null){
            GenericDMLOperation(requestRecord, 'update');
        }
    }
    
    /* To change status followed/unfollow */
    public static Boolean followRecord(String recordId,Boolean isFollowed) {
        if(!String.isBlank(recordId)){
            LIST<EntitySubscription> EntityLIST = new LIST<EntitySubscription>(); 
            if(!isFollowed) {
                EntitySubscription entitysubscription = new EntitySubscription(parentId = recordId, SubscriberId = UserInfo.getUserId());
                GenericDMLOperation(entitysubscription, 'insert');
            } else if(isFollowed) {
                EntityLIST = [SELECT id FROM EntitySubscription 
                              WHERE parentId =: recordId AND subscriberId =: UserInfo.getUserId() LIMIT 1000];
                if(!EntityLIST.isEmpty()){
                    GenericListDMLOperation(EntityLIST, 'delete');
                }
            }
            return !isFollowed;
        }
        else return false;
    }
    
    /* To insert Request Share records Used to insert share records */
    public static void insertShareRecords(LIST<IFv2_Request__Share> shareRecordsList) {
        if(!shareRecordsList.isEmpty()){
            GenericListDMLOperation(shareRecordsList, 'insert');
        }
    }
    
    /* To insert Request Share records Used to insert share records */
    public static void insertShareRecordsAPAC(LIST<IFv2_RequestExtension1__Share> shareRecordsList) {
        if(!shareRecordsList.isEmpty()){
            GenericListDMLOperation(shareRecordsList, 'insert');
        }
    }
    
    /* To insert Request Share records Used to insert share records */
    public static void insertShareRecordsEMAE(LIST<IFv2_RequestExtension2__Share> shareRecordsList) {
        if(!shareRecordsList.isEmpty()){
            GenericListDMLOperation(shareRecordsList, 'insert');
        }
    }
    
    /* To insert Request Share records Used to insert share records */
    public static void insertShareRecordsNALA(LIST<IFv2_RequestExtension3__Share> shareRecordsList) {
        if(!shareRecordsList.isEmpty()){
            GenericListDMLOperation(shareRecordsList, 'insert');
        }
    }
    
    public static void insertAccountShare(LIST<AccountShare> shareRecordsLIST) {
        
        if(!shareRecordsLIST.isEmpty()){
            GenericListDMLOperation(shareRecordsLIST, 'insert');
        }
    }
    
    /* To delete Request Share records */
    public static void deleteShareRecords(LIST<IFv2_Request__Share> shareRecordsList) {
        if(!shareRecordsList.isEmpty()){
            GenericListDMLOperation(shareRecordsList, 'delete');
        }
    }
    
    /* To delete Requestextension Share records Used to delete share records */
    public static void deleteShareRecordsAPAC(LIST<IFv2_RequestExtension1__Share> shareRecordsList) {
        if(!shareRecordsList.isEmpty()){
            GenericListDMLOperation(shareRecordsList, 'delete');
        }
    }
    
    /* To delete Requestextension Share records Used to delete share records */
    public static void deleteShareRecordsEMAE(LIST<IFv2_RequestExtension2__Share> shareRecordsList) {
        if(!shareRecordsList.isEmpty()){
            GenericListDMLOperation(shareRecordsList, 'delete');
        }
    }
    /* To delete Requestextension Share records Used to delete share records */
    public static void deleteShareRecordsNALA(LIST<IFv2_RequestExtension3__Share> shareRecordsList) {
        if(!shareRecordsList.isEmpty()){
            GenericListDMLOperation(shareRecordsList, 'delete');
        }
    }
    /* To delete Account Share records */
    public static void deleteShareRecordsAccount(LIST<AccountShare> shareRecordsList) {
        if(!shareRecordsList.isEmpty()){
            GenericListDMLOperation(shareRecordsList, 'delete');
        }
    }
    
    
    /* To delete Accountecords */
    public static void deleteAccountRecords(LIST<Account> AccountList) {
        if(!AccountList.isEmpty()){
            GenericListDMLOperation(AccountList, 'delete');
        }
    }
    
    /* To insert Accountecords */
    public static void insertAccountRecords(LIST<Account> AccountList) {
        if(!AccountList.isEmpty()){
            GenericListDMLOperation(AccountList, 'insert');
        }
    }
    
    /* Start of Iteration 3 changes */
    /* To update Account records */
    public static void updateAccountRecords(LIST<Account> AccountList) {
        if(!AccountList.isEmpty()){
            GenericListDMLOperation(AccountList, 'update');
        }
    }
    
    /* Method to update extension records */
    public static void UpdateExtensionOnerecords(LIST<IFv2_RequestExtension1__c> ExtensionList) {
        if(!ExtensionList.isEmpty()){
            GenericListDMLOperation(ExtensionList, 'update');
        }
    }
    
    /* End of iteration 3 changes */
    
    /* Update the ProcessInstance after Reassigning */
    public static void updateActor(LIST<ProcessInstanceWorkitem> approvalItem) {
        //Database.saveResult[] srList = Database.update(approvalItem, false);
        if(!approvalItem.isEmpty()){
            GenericListDMLOperation(approvalItem, 'update');
        }
    }
    
    /*Method to Insert users to permissionsets. */
    public static void insertPermissionSetUsers(LIST<PermissionSetAssignment> PermissionSetList) {
        if(!PermissionSetList.isEmpty())
            GenericListDMLOperation(PermissionSetList, 'insert');
    }
    
    /* Method to update user records */
    public static void updateUsers(LIST<User> UserRecords) {
        if(!UserRecords.isEmpty()){
            GenericListDMLOperation(UserRecords, 'update');
        }
    }
    
    /* Delete Permission set Assignment if user record is updated. */
    public static void deleteAssignment(LIST<PermissionSetAssignment> assignmentlist) {
        if(!assignmentlist.isEmpty()){
            GenericListDMLOperation(assignmentlist, 'delete');
        }
    }
    
    /* Start of Iteration 3 changes */
    /* Added to update Scan records */
    public static void UpdateScanRecord(LIST<Scan__c> ScanRecords) {
        if(!ScanRecords.isEmpty()){
            GenericListDMLOperation(ScanRecords, 'update');
        }
    }
    /* End of Iteration 3 changes */
    
    /* Generic DML method which inserts,update,delete and upserts the records */
    public static void GenericListDMLOperation(LIST<SObject> recordLIST, String operation) {
        String UNABLE_TO_LOCK_ROW = System.Label.CLIFv20155;
        Integer MAX_TRIES = Integer.valueOf(System.Label.CLIFv20188);
        if(!recordLIST.isEmpty()){
            if(operation == 'insert') {
                try {
                    Database.SaveResult[] result = Database.insert(recordLIST);
					system.debug('result--insert' + result);                    
                } catch(DMLException de) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(de);
                }
            } else if(operation == 'update') {
                Integer count = 0;
                while(count < MAX_TRIES) {
                    try {
                        Database.SaveResult[] result = Database.update(recordLIST);
                        break;
                    } catch(DMLException de) {
                        if(de.getMessage().contains(UNABLE_TO_LOCK_ROW)) {
                            count++;
                        } else {
                            count = MAX_TRIES;
                            IFv2_ExceptionUtilitiesController.exceptionHandler(de);
                        } 
                    }
                }
            } else if(operation == 'delete') {
                try {
                    Database.DeleteResult[] result = Database.delete(recordLIST);
                } catch(DMLException de) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(de);
                }
            } else if(operation == 'upsert') {
                Integer count = 0;
                while(count < MAX_TRIES) {
                    try {
                        Database.UpsertResult[] result = Database.upsert(recordLIST);
                        break;
                    } catch(DMLException de) {
                        if(de.getMessage().contains(UNABLE_TO_LOCK_ROW)) {
                            count++;
                        } else {
                            count = MAX_TRIES;
                            IFv2_ExceptionUtilitiesController.exceptionHandler(de);
                        }
                    }
                }
            }
        }
    }
    
    /* Generic DML method which inserts,update,delete and upserts the records */
    public static void GenericDMLOperation(SObject record, String operation) {
        String UNABLE_TO_LOCK_ROW = System.Label.CLIFv20155;
        Integer MAX_TRIES = Integer.valueOf(System.Label.CLIFv20188);
        if(record != null){
            if(operation == 'insert') {
                try {
                    Database.SaveResult result = Database.insert(record);
                } catch(DMLException de) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(de);
                }
            } else if(operation == 'update') {
                Integer count = 0;
                while(count < MAX_TRIES) {
                    try {
                        Database.SaveResult result = Database.update(record);
                        break;
                    } catch(DMLException de) {
                        if(de.getMessage().contains(UNABLE_TO_LOCK_ROW)) {
                            count++;
                        } else {
                            count = MAX_TRIES;
                            IFv2_ExceptionUtilitiesController.exceptionHandler(de);
                        } 
                    }
                }
            } else if(operation == 'delete') {
                try {
                    Database.DeleteResult result = Database.delete(record);
                } catch(DMLException de) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(de);
                }
            } else if(operation == 'upsert') {
                Integer count = 0;
                while(count < MAX_TRIES) {
                    try {
                        Database.UpsertResult result = Database.upsert(record);
                        break;
                    } catch(DMLException de) {
                        if(de.getMessage().contains(UNABLE_TO_LOCK_ROW)) {
                            count++;
                        } else {
                            count = MAX_TRIES;
                            IFv2_ExceptionUtilitiesController.exceptionHandler(de);
                        }
                    }
                }
            }
        }
    }
    
    
    /* Generic DML method which inserts,update,delete and upserts the records */
    public static LIST<Account> GenericListDMLOperationAccountRecords(LIST<SObject> recordLIST, String operation) {
        Database.SaveResult[] result;
        if(!recordLIST.isEmpty()) {
            if(operation == 'insert') {
                try {
                    result = Database.insert(recordLIST);
                } catch(DMLException de) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(de);
                }
            }  
        }
        return recordLIST;
    }
    
     /* Generic DML method which inserts,update,delete and upserts the records */
    public static LIST<Database.SaveResult> GenericListDMLOperationWithReturn(LIST<SObject> recordLIST, String operation) {
        Database.SaveResult[] result;
        if(!recordLIST.isEmpty()) {
            if(operation == 'insert') {
                try {
                    result = Database.insert(recordLIST);
                } catch(DMLException de) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(de);
                }
            }  
        }
        
        return result;
    }
}