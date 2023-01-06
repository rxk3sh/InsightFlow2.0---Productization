/*******************************************************************************************************
* 
* @ Name    		:   IFv2_GenericRelatedListController
* @ Purpose 		:   displaying the generic related lists
* @ Author  		:   Pradeep Chary
* @ Usage   		:   Method to fetch the related list records
* @ Test class name :   IFv2_GenericRelatedListControllerTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   12-11-2018      |  pradeep.chary@absyz.com (yv) |  1.0          |  Initial Version
*	12-11-2018      |  pradeep.chary@absyz.com 		|  2.0          |  Interation 2 - Code update for fetching fields
*********************************************************************************************************************/

public without sharing class IFv2_GenericRelatedListController {
    
    /* Method called on init to get fields for a related list */  
    @AuraEnabled
    public static LIST<FieldSetForm> getForm(String recordId, String objectName) {
        // Dynamic query fields
        String queryFields;
        //set of users
        SET<String> userIdSET = new SET<String>();
        //set of contacts
        SET<String> contactIdSET = new SET<String>();
        //list of FieldSetForm wrapper to return
        LIST<FieldSetForm> formLIST = new LIST<FieldSetForm>();
        //list of fieldsets retrieved from section metadata
        LIST<String> fieldSetNames = new LIST<String>();
        //map of fieldset and section metadata record 
        MAP<String, IFv2_Section__mdt> sectionMap = new MAP<String, IFv2_Section__mdt>();
        
        if(!String.isBlank(recordId) && !String.isBlank(objectName)) {
            //SObject Global describe
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
            //list to store all the field APIs from all fieldsets
            LIST<String> fieldAPIs = new LIST<String>();
            //string for dynamic query
            String allQueryFields = '';
            
            //querying the current request record details
            IFv2_Request__c requestRecord = IFv2_UtilsController.getInsertedRequest(recordId);
            
            if(requestRecord != null) {
                /* fetching related list metadata for the current request workflow */
                LIST<IFv2_Section__mdt> sectionMetadata = IFv2_UtilsController.getRelatedListMetadata(requestRecord.Workflow__c, requestRecord.OldRequest__c);
                
                /* fetching the fields of the fieldset */
                if(!sectionMetadata.isEmpty()) {
                    for(IFv2_Section__mdt iterator : sectionMetadata) {
                        fieldSetNames.add(iterator.Value__c);
                        sectionMap.put(iterator.Value__c, iterator);
                    }
                }
                /* Collections for field schema */
                Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
                MAP<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap();
                MAP<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
                
                /*create field wrapper from fieldset*/
                for(String fieldSetName : fieldSetNames) {
                    FieldSetForm form = new FieldSetForm();
                    form.requestRecord = requestRecord;
                    Schema.FieldSet fieldSet = fieldSetMap.get(fieldSetName);
                    LIST<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
                    LIST<IFv2_FieldWrapperClass> fields = new LIST<IFv2_FieldWrapperClass>();
                    for(Schema.FieldSetMember fsm : fieldSetMembers) {
                        IFv2_FieldWrapperClass field = new IFv2_FieldWrapperClass(fsm, objectName, null, fieldMap);
                        fieldAPIs.add(field.APIName);
                        fields.add(field);
                    }
                    
                    if(sectionMap.containsKey(fieldSetName)) {
                        form.section = sectionMap.get(fieldSetName);
                        form.fields = fields;
                        formLIST.add(form);
                    }
                }
                if(!fieldAPIs.isEmpty()) {
                    for(String fieldApi : fieldAPIs) {
                        if(fieldApi.toLowerCase() != 'id' && !allQueryFields.contains(fieldApi)) {
                            allQueryFields += fieldApi + ', ';
                        }
                    }
                }
                
                /* querying all the records from all the related lists */
                LIST<SObject> AllRecords = fetchRecords(allQueryFields, objectName, recordId);
                if(!formLIST.isEmpty()) {
                    for(SObject iterator : AllRecords) {
                        for(FieldSetForm form : formLIST) {
                            if(iterator != null && iterator.get('IFv2_ContentType__c') == form.section.RelatedListType__c) {
                                form.Record.add(iterator);
                            } 
                            
                            if(allQueryFields.indexOf('IFv2_PersonnelNo__c') != -1) {
                                if(iterator.get('IFv2_PersonnelNo__c') != null)
                                    contactIdSET.add(iterator.get('IFv2_PersonnelNo__c').toString());
                            }
                            if(iterator.get('IFv2_ContentType__c') == 'Approval History') {
                                if( fieldAPIs.contains('IFv2_LegacyActualApprover__c') && iterator.get('IFv2_LegacyActualApprover__c') != null)
                                    userIdSET.add(iterator.get('IFv2_LegacyActualApprover__c').toString());
                                
                                if( fieldAPIs.contains('IFv2_LegacyAssignedTo__c') && iterator.get('IFv2_LegacyAssignedTo__c') != null)
                                    userIdSET.add(iterator.get('IFv2_LegacyAssignedTo__c').toString());
                                
                                if(fieldAPIs.contains('IFv2_Legacysubmitter__c') && iterator.get('IFv2_Legacysubmitter__c') != null)
                                    userIdSET.add(iterator.get('IFv2_Legacysubmitter__c').toString());
                            }
                            if(allQueryFields.indexOf('CreatedById') != -1) {
                                userIdSET.add(iterator.get('CreatedById').toString());
                            }
                            if(allQueryFields.indexOf('LastModifiedById') != -1){
                                userIdSET.add(iterator.get('LastModifiedById').toString());
                            }
                            if(allQueryFields.indexOf('IFv2_EmployeeUser__c') != -1) {
                                if(iterator.get('IFv2_EmployeeUser__c') != null)
                                    userIdSET.add(iterator.get('IFv2_EmployeeUser__c').toString());
                            }
                        }
                    }
                }
                
                //list to store names of users retrieved
                LIST<SObject> userNamesLIST = new LIST<SObject>();
                //list to store names of contacts retrieved
                LIST<SObject> contactNamesLIST = new LIST<SObject>();
                
                if(!userIdSET.isEmpty()) {
                    userNamesLIST = fetchUserNames(userIdSET);
                }
                
                if(!contactIdSET.isEmpty()) {
                    contactNamesLIST = fetchContactNames(contactIdSET);
                }
                
                for(FieldSetForm form : formLIST) {
                    form.userName.addAll(userNamesLIST);
                    form.userName.addAll(contactNamesLIST);
                }
            }
        }
        return formLIST;
    }
    
    /* method to create record */
    @AuraEnabled
    public static FieldSetForm createRecord(String recordId, String recordType, Account record, IFv2_Request__c requestRecord, String queryFields) {
        //Return variable
        FieldSetForm form = new FieldSetForm();
        //set of contact ids
        SET<String> contactIdSET = new SET<String>();
        SET<String> userIdSET = new SET<String>();
        //list of related records
        LIST<SObject> relatedRecordsLIST = new LIST<SObject>();
        
        if(requestRecord != null && record != null && !String.isBlank(recordId) && !String.isBlank(queryFields)) {
            String reqName = '';
            if(!String.isBlank(requestRecord.Name)){
                reqName = requestRecord.Name.replace('INF','ACC');
            }
            //forming the account name for related list record
            String accountName = recordType + ' ' + reqName + ' ' + DateTime.now();
            record.put('IFv2_ContentType__c', recordType);
            record.put('recordtypeid', Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Items').getRecordTypeId());
            record.put('IFv2_Request__c', recordId);
            record.put('Name', accountName);
            
            //Upserting the related list record
            IFv2_DmlController.GenericDMLOperation(record, 'upsert');
            queryFields += ',';
            relatedRecordsLIST = fetchRecords(queryFields, 'Account', recordId);
            
            
            for(SObject iterator : relatedRecordsLIST) {
                if(queryFields.indexOf('IFv2_PersonnelNo__c') != -1) {
                    if(iterator.get('IFv2_PersonnelNo__c') != null)
                        contactIdSET.add(iterator.get('IFv2_PersonnelNo__c').toString());
                }
                if(queryFields.indexOf('IFv2_EmployeeUser__c') != -1) {
                    if(iterator.get('IFv2_EmployeeUser__c') != null)
                        userIdSET.add(iterator.get('IFv2_EmployeeUser__c').toString());
                }
                if(iterator != null && iterator.get('IFv2_ContentType__c') == recordType) {
                    form.Record.add(iterator);
                }  
            }
            
            if(!contactIdSET.isEmpty()) {
                form.userName = fetchContactNames(contactIdSET);
            } 
            if(!userIdSET.isEmpty()) {
                form.userName = fetchUserNames(userIdSET);
            } 
        }
        return form;
    }
    
    /* method to delete record */
    @AuraEnabled
    public static FieldSetForm deleteRecord(String accountRecordId, String requestRecordId, String queryFields, String recordType) {
        //instance of FieldSetForm wrapper
        FieldSetForm form = new FieldSetForm();
        LIST<Account> accountsLIST = new LIST<Account>();
        if(!String.isBlank(accountRecordId)){
            accountsLIST = [SELECT Id, Name FROM Account WHERE Id =: accountRecordId];
        }
        if(!accountsLIST.isEmpty()) {
            Account accountRecord = accountsLIST[0];
            
            //set of contact ids
            SET<String> contactIdSET = new SET<String>();
            SET<String> userIdSET = new SET<String>();
            
            //Deleting the selected record
            IFv2_DmlController.GenericDMLOperation(accountRecord, 'delete');
            
            //list of related list records for current request record
            LIST<SObject> relatedRecordsLIST = new LIST<SObject>();
            
            //string of dynamic query
            queryFields += ',';
            relatedRecordsLIST = fetchRecords(queryFields, 'Account', requestRecordId);
            
            for(SObject iterator : relatedRecordsLIST) {
                if(queryFields.indexOf('IFv2_PersonnelNo__c') != -1) {
                    if(iterator.get('IFv2_PersonnelNo__c') != null)
                        contactIdSET.add(iterator.get('IFv2_PersonnelNo__c').toString());
                } 
                if(queryFields.indexOf('IFv2_EmployeeUser__c') != -1) {
                    if(iterator.get('IFv2_EmployeeUser__c') != null)
                        userIdSET.add(iterator.get('IFv2_EmployeeUser__c').toString());
                } 
                if(iterator != null && iterator.get('IFv2_ContentType__c') == recordType) {
                    form.Record.add(iterator);
                }
            }
            
            /* get contact names */
            if(!contactIdSET.isEmpty()) {
                form.userName = fetchContactNames(contactIdSET);
            }
            if(!userIdSET.isEmpty()) {
                form.userName = fetchUserNames(userIdSET);
            }
        }
        return form;
    }
    
    /* method to retrieve all the related list records */
    public static LIST<SObject> fetchRecords(String queryFields, String objectName, String recordId) {
        LIST<SObject> relatedListRecords = new LIST<SObject>();
        if(!String.isBlank(queryFields) && !String.isBlank(objectName) && !String.isBlank(recordId)) {
            relatedListRecords = IFv2_UtilsController.getRelatedRecords(queryFields, objectName, recordId, 'Request Items');
        }
        return relatedListRecords;
    }
    
    /* method to retrieve names of the users or contacts */
    public static LIST<SObject> fetchUserNames(SET<String> userId) {
        //list to hold the names of users fetched
        LIST<SObject> userNamesLIST = new LIST<SObject>();
        //list to hold the user ids
        LIST<String> userIdsLIST = new LIST<String>(userId);
        if(!userIdsLIST.isEmpty()) {
            userNamesLIST = IFv2_UtilsController.getRecordName(userIdsLIST, 'User', null);
        }
        return userNamesLIST;
    }
    
    /* method to retrieve names of the users or contacts */
    public static LIST<SObject> fetchContactNames(SET<String> userId) {
        //list to hold the names of users fetched
        LIST<SObject> userNamesLIST = new LIST<SObject>();
        //list to hold the user ids
        LIST<String> contactIdsLIST = new LIST<String>(userId);
        if(!contactIdsLIST.isEmpty()) {
            userNamesLIST = IFv2_UtilsController.getRecordName(contactIdsLIST, 'Contact', null);
        }
        return userNamesLIST;
    }
    
    /* method to get attachments */
    @AuraEnabled
    public static WrapperClass fetchAttachmentList(Id recordId) {
        WrapperClass wrapperObject = new WrapperClass();
        if(recordId != null) {
            LIST<IFv2_Request__c> recordLIST = IFv2_UtilsController.getRequestRecord(recordId, ',Status__c');
            if(!recordLIST.isEmpty()) {
                wrapperObject.requestRecord = recordLIST[0];
            }
            wrapperObject.allAttachments = IFv2_UtilsController.getAllAttachmentList(recordId);
        }
        return wrapperObject;
    }
    
    /* wrapper for related lists */
    public class FieldSetForm {
        
        /* store section metadata */
        @AuraEnabled public IFv2_Section__mdt section { get; set; }
        
        /* store fields */
        @AuraEnabled public  LIST<IFv2_FieldWrapperClass> fields { get; set; }
        
        /* store related list records */
        @AuraEnabled public LIST<SObject> Record { get; set; }
        
        /* store request record */
        @AuraEnabled public IFv2_Request__c requestRecord { get; set; }
        
        /* for the names of contacts and users */
        @AuraEnabled public LIST<SObject> userName { get; set; }
        
        public FieldSetForm() {
            Fields = new  LIST<IFv2_FieldWrapperClass>();
            Record = new LIST<SObject>();
            userName = new LIST<SObject>();
        }
    }
    
    /* wrapper class for notes and attachments*/
    public class WrapperClass{
        
        /* to store the request record */
        @AuraEnabled public SObject requestRecord { get; set; }
        
        /* for list of files to be displayed */
        @AuraEnabled public LIST<ContentDocumentLink> allAttachments { get; set; }
        
        public WrapperClass() {}
    }
}