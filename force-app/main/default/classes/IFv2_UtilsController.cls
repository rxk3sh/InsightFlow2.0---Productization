/*
* @ Name        : IFv2_UtilsController
* @ Purpose     : Base controller for all the SOQL queries
* @ Author      : Pradeep Chary
* @ Test Class  : IFv2_ThankYouForWaitingControllerTest
*
* Date          | Developer Name                | Version   	| Changes
* ======================================================================================================
* 28-10-2018    | pradeep.chary@absyz.com       | 1.0       	| Initial Version
* 30-10-2018    | kanchan.baghel@absyz.com      | 1.1       	| Added query 
* 02-11-2018    | vivek.kothalnka@absyz.com     | 1.1       	| Added logic for Profile Categorization
* 06-12-2019    | pradeep.chary@absyz.com(yv)   | 1.2       	| Updated query for system admin (removed where condition for active)
* 01-03-2019    | pradeep.chary@absyz.com(yv)   | 1.3       	| Updated fieldQuery string to add roles and approvers from 13-25
* 06-05-2019    | elsa.shaju@absyz.com          | 2.0       	| Added query for materials for MGP Workflow
* 21-02-2020    | external.debasmita.rawooth@seg-automotive.com | Added new method to revoke access from old approver after request is submitted
* 18-05-2021    | pradeep.chary@absyz.com		| 3.0           |  Making it without sharing for B2B Portal
*
*******************************************************************************************************/

public without sharing class IFv2_UtilsController {
    
    /*Wrapper class for returning name for lookup fields*/
    public class CreatedByWrapper {
        @AuraEnabled public String Name{get;set;}
        @AuraEnabled public DateTime dateVal{get;set;}
        
        public CreatedByWrapper() {}
    }
    
    /* get logged in user information */
    @AuraEnabled
    public static User getLoggedInDetails() {
        User record = new User();
        LIST<User> recordList = new LIST<User>();
        try {
            recordList = [SELECT Id, Name, Phone, Currency__c, Profile.Name, Department, Location__c, Cost_Center__c, Country, Out_Of_Office__c 
                          FROM User 
                          WHERE Id = :UserInfo.getUserId()];
            if(!recordList.isEmpty()) {
                record = recordList[0];
            }
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return record;
    }
    
    /* Method to retreive the button details from custom metadata */
    public static String getWorkflowApiName(String workflow) {
        String WFName = '';
        if(!String.isBlank(workflow)) {
            try {
                LIST<IFv2_Workflows__mdt> workflowsLIST = [SELECT DeveloperName FROM IFv2_Workflows__mdt WHERE Name__c =: workflow];
                if(!workflowsLIST.isEmpty()) {
                    WFName = workflowsLIST[0].DeveloperName;
                }
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
        }
        return WFName;
    }
    
    /* Method to retreive the button details from custom metadata */
    public static LIST<IFv2_RequestButtons__mdt> getButtonDetails(String query) {
        LIST<IFv2_RequestButtons__mdt> recordLIST = new LIST<IFv2_RequestButtons__mdt>();
        if(!String.isBlank(query)) {
            try {
                recordLIST = Database.query(query);
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
        }
        return recordLIST;
    }
    
    /* Method to retreive the records from request object */
    public static LIST<IFv2_Request__c> getRequestRecord(Id requestId, String fields) {
        LIST<IFv2_Request__c> record = new LIST<IFv2_Request__c>();
        if(requestId != null && !String.isBlank(fields)) {
            String query = 'SELECT Id' + fields + ' FROM IFv2_Request__c WHERE Id = :requestId';
            try {
                record = Database.query(query);
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
        }
        return record;
    }
    
    /* Method to retreive the records from request object */
    public static String getPrivilegedRoleName(Id requestId) {
        String roles = Label.CLIFv20235;
        if(requestId != null && !String.isBlank(roles)) {
            try {
                system.debug('userId:'+UserInfo.getUserId());
                for(ProcessInstance instance :[SELECT Id, (SELECT Id, ProcessNode.Name 
                                                           FROM StepsAndWorkitems 
                                                           WHERE (StepStatus = 'Pending' 
                                                                  OR (StepStatus = 'Approved' 
                                                                      AND ProcessNode.Name = :Label.CLIFv20229))
                                                           AND (ActorId = :UserInfo.getUserId() OR OriginalActorId = :UserInfo.getUserId())) 
                                               FROM ProcessInstance 
                                               WHERE TargetObjectId =: requestId ORDER BY CreatedDate]) {
                                                   for(ProcessInstanceHistory workItem :instance.StepsAndWorkitems) {
                                                       if(roles.containsIgnoreCase(workItem.ProcessNode.Name))
                                                           return workItem.ProcessNode.Name;
                                                   }   
                                               }
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
        }
        return null;
    }
    
    /*Method to find the users with request record access*/
    public static LIST<ProcessInstanceWorkitem> getRecordAcccess(Id requestId) {
        LIST<ProcessInstanceWorkitem> record = new LIST<ProcessInstanceWorkitem>();
        if(requestId != null) {
            try {
                record = [SELECT Id, Actor.Name, ActorId, originalActorId, originalActor.Name, ProcessInstance.Status 
                          FROM ProcessInstanceWorkitem 
                          WHERE ProcessInstance.TargetObjectId =: requestId 
                          AND ProcessInstance.Status = 'Pending'];
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
        }
        return record;
    }
    
    /* This method is used current status of follow/unFollow of a record */
    public static Boolean getFollowedRecord(Id requestId) {
        LIST<EntitySubscription> entity = new LIST<EntitySubscription>();
        if(requestId != null) {
            try { 
                entity = [SELECT ParentId FROM EntitySubscription 
                          WHERE SubscriberId =: UserInfo.getUserId() 
                          AND Parent.Type = 'IFv2_Request__c' 
                          AND ParentId = :requestId LIMIT 1000];
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
        }
        return (!entity.isEmpty());
    }
    
    /* Method to execute a string query and return a request record*/
    public static IFv2_Request__c forApprovers(String query) {
        IFv2_Request__c record = new IFv2_Request__c();
        LIST<IFv2_Request__c> recordList = new LIST<IFv2_Request__c>();
        if(!String.isBlank(query)) {
            try {
                recordList = Database.query(query);
                if(!recordList.isEmpty()) {
                    record = recordList[0];
                }
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
        }
        return record;
    }
    
    //Method to get Selected Workflow Record.
    public static LIST<IFv2_Workflow__c> getWorkflowRecords(String fieldQuery, String objectApiName, SET<String> mergedSET, Boolean isSystemAdmin, String userCountry) {
        String recordSOQL;
        String recordSOQLforDefault;
        String countryGlobal = 'Global';
        LIST<IFv2_Workflow__c> workflowList = new LIST<IFv2_Workflow__c>();
        LIST<IFv2_Workflow__c> workflowListForDefault = new LIST<IFv2_Workflow__c>();
        LIST<IFv2_Workflow__c> finalWorkflowList = new LIST<IFv2_Workflow__c>();
        
        MAP<String,IFv2_Workflow__c> workflowMap = new MAP<String,IFv2_Workflow__c>();
        if(String.isBlank(objectApiName)){
            objectApiName = 'IFv2_Workflow__c';
        }
        /* Iteration 3 query update 01-03-2019 START */
        if(fieldQuery != null) {
            fieldQuery = fieldQuery + ',Name,Default__c,Approver01Role__c,Approver02Role__c,Approver03Role__c,Approver04Role__c,'
                + 'Approver05Role__c,Approver06Role__c,Approver07Role__c,Approver08Role__c,Approver09Role__c,'
                + 'Approver10Role__c,Approver11Role__c,Approver12Role__c,Approver1__c,Approver2__c,Approver3__c,Approver4__c,'
                + 'Approver5__c,Approver6__c,Approver7__c,Approver8__c,Approver9__c,Approver10__c,Approver11__c,Approver12__c,'
                + 'Approver13Role__c,Approver14Role__c,Approver15Role__c,Approver16Role__c,Approver17Role__c,Approver18Role__c,'
                + 'Approver19Role__c,Approver20Role__c,Approver21Role__c,Approver22Role__c,Approver23Role__c,Approver24Role__c,'
                + 'Approver25Role__c,Approver13__c,Approver14__c,Approver15__c,Approver16__c,Approver17__c,Approver18__c,'
                + 'Approver19__c,Approver20__c,Approver21__c,Approver22__c,Approver23__c,Approver24__c,Approver25__c';
        } else {
            fieldQuery = ',Name,Default__c,Approver01Role__c,Approver02Role__c,Approver03Role__c,Approver04Role__c,'
                + 'Approver05Role__c,Approver06Role__c,Approver07Role__c,Approver08Role__c,Approver09Role__c,'
                + 'Approver10Role__c,Approver11Role__c,Approver12Role__c,Approver1__c,Approver2__c,Approver3__c,Approver4__c,'
                + 'Approver5__c,Approver6__c,Approver7__c,Approver8__c,Approver9__c,Approver10__c,Approver11__c,Approver12__c,'
                + 'Approver13Role__c,Approver14Role__c,Approver15Role__c,Approver16Role__c,Approver17Role__c,Approver18Role__c,'
                + 'Approver19Role__c,Approver20Role__c,Approver21Role__c,Approver22Role__c,Approver23Role__c,Approver24Role__c,'
                + 'Approver25Role__c,Approver13__c,Approver14__c,Approver15__c,Approver16__c,Approver17__c,Approver18__c,'
                + 'Approver19__c,Approver20__c,Approver21__c,Approver22__c,Approver23__c,Approver24__c,Approver25__c';
        }
        /* Iteration 3 query update END */
        
        //checking for conditions
        if(!mergedSET.isEmpty() && isSystemAdmin) {
            recordSOQL = 'SELECT Id' + fieldQuery + 
                ' FROM ' + objectApiName +
                ' WHERE Workflow__c IN : mergedSET';
        } else if(isSystemAdmin) {
            recordSOQL = 'SELECT Id' + fieldQuery + 
                ' FROM ' + objectApiName;
        } else {
            recordSOQL = 'SELECT Id' + fieldQuery +
                ' FROM ' + objectApiName + 
                ' WHERE Active__c = true' + 
                ' AND (Workflow__c IN : mergedSET)' + 
                ' AND (Country__c =: userCountry OR Country__c =: countryGlobal)';
            
            recordSOQLforDefault = 'SELECT Id' + fieldQuery +
                ' FROM ' + objectApiName + 
                ' WHERE Active__c = true'+ 
                ' AND (Workflow__c IN : mergedSET)' + 
                ' AND (Default__c = true)';
        }
        
        try {
            workflowList = Database.query(recordSOQL);
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        if(!isSystemAdmin) {
            try {
                workflowListForDefault = Database.query(recordSOQLforDefault);
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
            for(IFv2_Workflow__c workflow : workflowList) {
                if(!workflowMap.containsKey(workflow.Workflow__c)) {
                    workflowMap.put(workflow.Workflow__c, workflow);
                }
            }
            
            for(IFv2_Workflow__c workflow : workflowListForDefault) {
                if(!workflowMap.containsKey(workflow.Workflow__c)) {
                    workflowMap.put(workflow.Workflow__c, workflow);
                }
            }
            
            if(workflowMap.values().size() > 0)
                finalWorkflowList = workflowMap.values();
            
        } else {
            finalWorkflowList = workflowList;
        }
        return finalWorkflowList;
    }
    
    /* Method to Fetch Custom metadata records*/
    public static LIST<IFv2_Section__mdt> getCustomMetaDataList(String SeletedRecordName) {
        LIST<IFv2_Section__mdt> recordLIST = new LIST<IFv2_Section__mdt>();
        if(!String.isBlank(SeletedRecordName)) {
            try {
                recordLIST = [SELECT id,value__c,Workflows__c,SectionNumber__c 
                              FROM IFv2_Section__mdt 
                              WHERE Workflows__r.Name__c =: SeletedRecordName];
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
        }
        return recordLIST;
    }
    
    //Method to get Selected Workflow Record.
    public static Sobject getSeletedWorkflowRecord(Id SingleWorkflowrecordId) {
        LIST<Sobject> recordsLIST = new LIST<Sobject>();
        if(SingleWorkflowrecordId != null) {
            try {
                DescribeSObjectResult DescribeResult = SingleWorkflowrecordId.getSObjectType().getDescribe();
                if(DescribeResult != null) {
                    LIST<String> fieldNamesLIST = new LIST<String>(DescribeResult.fields.getMap().keySet());
                    
                    if(!fieldNamesLIST.isEmpty()) {
                        String query = ' SELECT ' + String.join(fieldNamesLIST, ',') +
                            ' FROM ' + DescribeResult.getName() +
                            ' WHERE ' + ' Id = :SingleWorkflowrecordId ' + ' LIMIT 1 ';
                        
                        recordsLIST = Database.query(query);
                    }
                }
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
        }
        
        if(!recordsLIST.isEmpty()) {
            Sobject record = recordsLIST[0];
            return record;
        }
        return null;
    } 
    
    //Method to get custom meta data records.
    public static LIST<IFv2_Workflows__mdt> getMetadataRecords() {
        LIST<IFv2_Workflows__mdt> metadataLIST = new LIST<IFv2_Workflows__mdt>();
        try {
            metadataLIST = [SELECT id,Name__c,Users__c,General__c  
                            FROM IFv2_Workflows__mdt
                            WHERE General__c = TRUE
                            AND Status__c = 'Active'];
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return metadataLIST;
    }
    
    /* To retrieve the user name from id*/
    public static LIST<SObject> getUserName(SET<String> userId) {
        LIST<SObject> record = new LIST<SObject>();
        try {
            if(!userId.isEmpty())
                record = [SELECT Id, Name,Email,FirstName,LastName,DelegatedApproverId, ProfileId
                          FROM User 
                          WHERE Id IN :userId];
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return record;
    }
    
    /* Generic query to retrieve Name from Id*/
    @AuraEnabled
    public static LIST<SObject> getRecordName(LIST<String> recordIds, String objectName, String searchField) {
        LIST<SObject> recordsLIST = new LIST<SObject>();
        if(!String.isBlank(objectName)) {
            try {
                String query = 'SELECT Id, ';
                if(!String.isBlank(searchField)) {
                    query += searchField;
                } else {
                    query += 'Name';
                }
                query += ' FROM ' + objectName + 
                    ' WHERE Id IN :recordIds';
                
                recordsLIST = Database.query(query);
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
        }
        return recordsLIST;
    }
    
    /* Get record Name with createdby and Last modified dates*/
    @AuraEnabled
    public static CreatedByWrapper getRecordNameWithDates(LIST<String> recordIds, String objectName, String parentId, String fieldName) {
        CreatedByWrapper wrapper= new CreatedByWrapper();
        try {
            if(!String.isBlank(objectName)) {
                String query = 'SELECT Id, Name FROM ' + objectName + ' WHERE Id IN :recordIds';
                LIST<SObject> recordsLIST = Database.query(query);
                if(!recordsLIST.isEmpty()) {
                    wrapper.Name = String.valueOf(recordsLIST[0].get('Name'));
                }
            }
            
            if(!String.isBlank(fieldName) && !String.isBlank(parentId)) {
                if(fieldName.toLowerCase() == 'created by' || fieldName.toLowerCase() == 'last modified by') {
                    String parentObjectName = (Id.valueOf(parentId)).getSobjectType().getDescribe().getName();
                    String query = 'SELECT Id, CreatedDate, LastModifiedDate FROM ' + parentObjectName + ' WHERE Id = :parentId';
                    LIST<IFv2_Request__c> reqRecordsLIST = Database.query(query);
                    if(!reqRecordsLIST.isEmpty()) {
                        if(fieldName.toLowerCase() == 'created by') {
                            wrapper.dateVal = DateTime.valueOf(reqRecordsLIST[0].get('CreatedDate'));
                        } else if(fieldName.toLowerCase() == 'last modified by') {
                            wrapper.dateVal = DateTime.valueOf(reqRecordsLIST[0].get('LastModifiedDate'));
                        }
                    }
                }
            }
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return wrapper;
    }
    
    /* retrieve names of the contacts */
    public static LIST<SObject> getContactName(SET<String> userId) {
        LIST<SObject> recordLIST = new LIST<SObject>();
        try {
            if(!userId.isEmpty())
                recordLIST = [SELECT Id, Name
                              FROM Contact 
                              WHERE Id IN :userId];
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return recordLIST;
    }
    
    
    public static sObject getRequestObject(Id recordId, SET<Id> targetObjectId) {
        //Dynamic quest string variable
        String requestQuery;
        try {
            if(targetObjectId.isEmpty() && recordId != null) {
                requestQuery = ' SELECT Id, OwnerId, Status__c' + 
                    ' FROM IFv2_Request__c '+ 
                    ' WHERE Id = \'' + recordId + '\' Limit 1';
            } else {
                requestQuery = ' SELECT Id, OwnerId, Status__c' + 
                    ' FROM IFv2_Request__c '+ 
                    ' WHERE Status__c NOT IN (\'Draft\',\'Approved\',\'Rejected\') AND Id IN: targetObjectId';
            }
            LIST<SObject> objectLIST = Database.query(requestQuery);
            if(!objectLIST.isEmpty()) {
                SObject requestObject = objectLIST[0];
                return requestObject;
            }
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return null;
    }
    
    //To get ProcessinstanceWorkItem based on the request record (IFv2_ThankYouForWaitingController) - Madhura Vani
    public static ProcessInstanceWorkItem getProcessInstance(String recordId) {
        if(!String.isBlank(recordId)) {
            try {
                LIST<ProcessInstanceWorkItem> processItemLIST = [SELECT ActorId, ProcessInstanceId, ProcessInstance.TargetObjectId 
                                                                 FROM ProcessInstanceWorkItem p 
                                                                 WHERE p.ProcessInstance.TargetObjectId = : recordId];
                if(!processItemLIST.isEmpty()) {
                    ProcessInstanceWorkItem processItem = processItemLIST[0];
                    return processItem;
                }
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
        }
        return null;
    }
    
    public static LIST<GroupMember> getGroups(LIST<Id> groupIds) {
        LIST<GroupMember> GroupMembersLIST = new LIST<GroupMember>();
        String query;
        try {
            String userid = UserInfo.getUserId();
            if(groupIds.isEmpty()) {
                query = 'SELECT Id, group.Id, group.Name, UserOrGroupId FROM GroupMember WHERE UserOrGroupId =: userid';
            } else {
                query = 'SELECT UserOrGroupId, GroupId, Group.type FROM GroupMember WHERE GroupId IN: groupIds AND Group.type = \'Queue\'';
            }
            GroupMembersLIST = Database.query(query);
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return GroupMembersLIST;
    }
    
    /* method to retrieve the record type ID */
    public Static RecordType getRecordTypeId(String recordTypeName, String ObjectName) {
        RecordType recordType = new RecordType();
        if(!String.isBlank(recordTypeName) && !String.isBlank(ObjectName)) {
            try {
                LIST<RecordType> recordTypeLIST = [SELECT Id, Name FROM RecordType WHERE Name =: recordTypeName AND SObjectType =: ObjectName];
                if(!recordTypeLIST.isEmpty()) {
                    recordType = recordTypeLIST[0];
                }
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
        }
        return recordType;
    }
    
    /* method to fetch the request record */
    public static IFv2_Request__c getInsertedRequest(ID requestID) {
        IFv2_Request__C record = new IFv2_Request__c();
        if(requestID != null) {
            try {
                LIST<IFv2_Request__C> recordLIST = [SELECT Id, Name, Workflow__c, Status__c, Subworkflow__c, OldRequest__c, DisplayApprovalHistory__c
                                                    FROM IFv2_Request__c 
                                                    WHERE Id =: requestID];
                if(!recordLIST.isEmpty()) {
                    record = recordLIST[0];
                }
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
        }
        return record;
    }
    
    /* retrieve custom metadata records for Approver History fields */
    public static IFv2_Section__mdt getSectionMetadataRecords(String listType) {
        IFv2_Section__mdt record = new IFv2_Section__mdt();
        if(!String.isBlank(listType)) {
            try {
                LIST<IFv2_Section__mdt> recordLIST = [SELECT ExtendedValue__c,Value__c 
                                                      FROM IFv2_Section__mdt
                                                      WHERE Label =: listType];
                if(!recordLIST.isEmpty()) {
                    record = recordLIST[0];
                }
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
        }
        return record;
    }
    
    /* method to fetch limited approval history list records */
    public static LIST<SObject> getApprovalHistoryRecords(String apiNames, String parentObjectName, String objectId, String dummyUserId) {
        LIST<ProcessInstance> processInstancerecord = new LIST<ProcessInstance>();
        LIST<SObject> record = new LIST<SObject>();
        if(!String.isBlank(apiNames) && !String.isBlank(parentObjectName) && !String.isBlank(objectId)){
            String query = 'SELECT Id, (SELECT '+apiNames+
                ' FROM StepsAndWorkitems'+ 
                ' WHERE OriginalActorId !=: dummyUserId ORDER BY Id DESC LIMIT 5)'+
                ' FROM ' + parentObjectName+
                ' WHERE TargetObjectId =:objectId ORDER BY Id DESC';
            try {
                processInstancerecord = Database.query(query);
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            } 
        }
        return processInstancerecord;
    }
    
    /* method to fetch all the Approval history list records */
    public static LIST<SObject> getExtendedApprovalHistoryRecords(String apiNames, String parentObjectName, String objectId, String dummyUserId) {
        LIST<ProcessInstance> processInstancerecord = new LIST<ProcessInstance>();
        LIST<SObject> record = new LIST<SObject>();
        if(objectId!=Null && !String.isBlank(apiNames) && !String.isBlank(parentObjectName)) {
            String query = 'SELECT Id, (SELECT '+apiNames+
                ' FROM StepsAndWorkitems'+ 
                ' WHERE OriginalActorId !=: dummyUserId ORDER BY Id DESC)'+
                ' FROM '+parentObjectName+
                ' WHERE TargetObjectId =:objectId'+
                ' ORDER BY Id DESC';
            try {
                processInstancerecord = Database.query(query);
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
        }
        return processInstancerecord;
    }
    
    /* Permission set*/
    public static LIST<PermissionSet> permissionSetRecords() {
        LIST<PermissionSet> record = new LIST<PermissionSet>();
        try {
            record = [SELECT Id, ProfileId, Label,Name 
                      FROM PermissionSet 
                      WHERE Name LIKE : '%Extension%'];
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return record;
    }
    
    /* get ObjectPermissions*/
    public static LIST<ObjectPermissions> getObjectPermissions(SET<Id> permissionSetIds, String extensionObjectName ) {
        LIST<ObjectPermissions> record = new LIST<ObjectPermissions>();
        try {
            if(!permissionSetIds.isEmpty() || String.isNotBlank(extensionObjectName))
                record = [SELECT id, ParentId,Parent.ProfileId, PermissionsCreate, PermissionsRead, PermissionsEdit,
                          PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords, SobjectType 
                          FROM ObjectPermissions 
                          WHERE ParentId IN: permissionSetIds AND SobjectType =: extensionObjectName AND PermissionsRead = TRUE];
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        } 
        return record;
    }
    
    /* Get PermissionSetAssignment*/
    public static LIST<PermissionSetAssignment> getPermissionSetAssignment(LIST<String> patentIdsList, SET<String> approvers) {
        LIST<PermissionSetAssignment> records = new LIST<PermissionSetAssignment>();
        try {
            if(!patentIdsList.isEmpty() || !approvers.isEmpty())
                records = [SELECT AssigneeId, PermissionSetId 
                           FROM PermissionSetAssignment 
                           WHERE PermissionSetId IN : patentIdsList AND AssigneeId IN : approvers];
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        } 
        return records;
    }
    
    /* To get Logged in user division*/
    public static LIST<IFv2_Department__mdt> getdepartments(String department) {
        LIST<IFv2_Department__mdt> departmentList = new LIST<IFv2_Department__mdt>();
        try {
            if(String.isNotBlank(department)) {
                for(IFv2_Department__mdt dept:[SELECT Id, Division__r.DeveloperName, DeveloperName, Label, Division__r.Status__C
                                               FROM IFv2_Department__mdt
                                               WHERE label =: department
                                               AND Status__c = 'Active']) {
                                                   if(dept.Division__r.Status__C == 'Active') {
                                                       departmentList.add(dept); 
                                                   }
                                               }
            }
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return departmentList;
    }
    
    /* To get All workflows .*/
    public static LIST<IFv2_Workflows__mdt> getWorkflows() {
        LIST<IFv2_Workflows__mdt> WorkflowsList = new LIST<IFv2_Workflows__mdt>();
        string query;
        try {
            query = 'SELECT Id, Country__c, Division__c, EnteredValueisPublicGroup__c, Division__r.DeveloperName, General__c, Name__c, Region__c, Users__c FROM IFv2_Workflows__mdt WHERE Status__c = \'Active\'';
            WorkflowsList = Database.query(query);
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return WorkflowsList;
    }
    
    /* To get IFv2_Section__mdt metadata records*/
    public static LIST<IFv2_Section__mdt> getSectionMetaDataRecord(String workflowName) {
        LIST<IFv2_Section__mdt> sectionRecords = new LIST<IFv2_Section__mdt>();
        try {
            if(String.isNotBlank(workflowName))
                sectionRecords = [SELECT id,value__c,Workflows__c,Workflows__r.Name__c,Name__c,isApproverSection__c, isParallelApproverSection__c, isPredefinedApproverSection__c 
                                  FROM IFv2_Section__mdt 
                                  WHERE Workflows__r.Name__c=:workflowName AND isApproverSection__c = true];
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return sectionRecords;
    }
    
    /* To get All workflows .*/
    public static String getWorkflows(String workflowName) {
        string query;
        LIST<IFv2_Workflows__mdt> workflowlist= new LIST<IFv2_Workflows__mdt>();
        try {
            if(String.isNotBlank(workflowName))
                workflowlist = [SELECT id, Name__c, Region__c
                                FROM IFv2_Workflows__mdt
                                WHERE Name__c = :workflowName
                                AND Status__c = 'Active'];
            if(!workflowlist.isEmpty()) {
                query = workflowlist[0].Region__c;
            }
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return query;
    }
    
    /* Query Permission sets*/
    public static String getPermission(String Region) {
        String PermissionSetId;
        if(String.isNotBlank(Region)) {
            String regioncheck;
            if(Region == 'APAC') {
                regioncheck = '%'+'- 1' +'%';
            } else if(Region == 'EMEA') {
                regioncheck = '%'+'- 2' +'%';
            } else if(Region == 'NALA') {
                regioncheck = '%'+'- 3' +'%';
            }
            
            try {
                if(!String.isBlank(regioncheck)){
                    PermissionSetId = [SELECT Id, Label 
                                       FROM PermissionSet
                                       WHERE label LIKE :regioncheck LIMIT 1].Id;
                }
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
        }
        return PermissionSetId;
    }
    
    /* To get users who are given access through permission sets. */
    public static LIST<User> getUserRecords(SET<String> noAccessUsersset) {
        LIST<User> userRecordsList = new LIST<User>();
        try {
            if(!noAccessUsersset.isEmpty())
                userRecordsList = [SELECT ID, IFv2_RequestAPAC__c, IFv2_RequestEMEA__c, IFv2_RequestNALA__c 
                                   FROM User 
                                   WHERE Id IN : noAccessUsersset];
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return userRecordsList;
    }
    
    /* Get Region metadata records. */
    public static LIST<IFv2_Country__mdt> getRegionMetadata(SET<String> countriesSet) {
        LIST<IFv2_Country__mdt> metdatalist = new LIST<IFv2_Country__mdt>();
        try {
            if(!countriesSet.isEmpty())
                metdatalist = [SELECT Id, DeveloperName,label, PermissionSetName__c, Region__c 
                               FROM IFv2_Country__mdt 
                               WHERE label IN : countriesSet
                               AND Status__c = 'Active'];
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return metdatalist;
    }
    
    /*holds permission set to be deleted */
    public static LIST<PermissionSetAssignment> deletePermissionSetAssignment(SET<Id> permissionstIds, LIST<SET<String>> userIds ) {
        LIST<PermissionSetAssignment> PermissionSetAssignmentList = new LIST<PermissionSetAssignment>();
        LIST<String> userlist=new LIST<String>();
        for(SET<String> s:userIds)
            userlist.addall(s);
        try {
            if(!userlist.isEmpty() || !permissionstIds.isEmpty() )
                PermissionSetAssignmentList = [SELECT Id, AssigneeId, PermissionSetId 
                                               FROM PermissionSetAssignment 
                                               WHERE AssigneeId IN : userlist 
                                               AND PermissionSetId IN : permissionstIds];
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return PermissionSetAssignmentList;
    }
    
    /** Returns the ProcessInstanceWorkItem based on conditions **/
    public static LIST<ProcessInstanceWorkitem> createProcessInstanceWI() { 
        LIST<ProcessInstanceWorkitem> lstItems = new LIST<ProcessInstanceWorkitem>();
        try {
            lstItems = [SELECT Id, Actor.Name, ProcessInstance.TargetObject.Name, CreatedDate, OriginalActor.Name, ProcessInstance.Status, ActorId, OriginalActorId
                        FROM ProcessInstanceWorkitem 
                        WHERE ActorId =: userInfo.getUserId()
                        AND ProcessInstance.Status = 'Pending'];
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        } 
        return lstItems;
    }
    
    /** Holds the request records based on the status **/
    public static LIST<IFv2_Request__c> createRequest(string strStatus) {
        LIST<IFv2_Request__c> lstRequest = new LIST<IFv2_Request__c>();
        try {
            if(String.isNotBlank(strStatus))
                lstRequest = [SELECT Id, OwnerId, Name , CreatedDate,Workflow__c,Status__c,CreatedBy.Name
                              FROM IFv2_Request__c 
                              WHERE Status__c = :strStatus
                              AND OwnerId = :userInfo.getUserId()
                              Order BY CreatedDate ASC];
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return lstRequest;
    }
    
    /* Method to get Checkbox to Activate or deactivate Trigger */
    public Static Boolean getTriggerLogic(String TriggerName,String methodName) {
        Boolean dontExecuteTrigger = false;
        try {
            if(String.isNotBlank(TriggerName) || String.isNotBlank(methodName)) {
                LIST<IFv2_TriggerLogicConfiguration__mdt> configList = [SELECT ID, Deactivate__c ,TriggerName__c,MethodName__c
                                                                        FROM IFv2_TriggerLogicConfiguration__mdt
                                                                        WHERE TriggerName__c =: TriggerName AND MethodName__c = :methodName];
                if(!configList.isEmpty()) {
                    dontExecuteTrigger = configList[0].Deactivate__c;
                }
            }
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        } 
        return dontExecuteTrigger;
    }
    
    /* To get Logged in user division*/
    public static LIST<IFv2_PredefinedWorkflowFields__mdt> getPredefinedFields(String workflowName) {
        LIST<IFv2_PredefinedWorkflowFields__mdt> predefinedFields = new LIST<IFv2_PredefinedWorkflowFields__mdt>();
        try {
            if(String.isNotBlank(workflowName))
                predefinedFields = [SELECT RequestFieldApi__c, WorkflowField__c, WorkflowName__c 
                                    FROM IFv2_PredefinedWorkflowFields__mdt
                                    WHERE Workflow__r.Name__c= :workflowName 
                                    AND IsConditional__c = false];
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return predefinedFields;
    }
    
    /* Getting list of attachments related to the current request */
    @AuraEnabled
    public static LIST<ContentDocumentLink> getAllAttachmentList(id recordId) {
        LIST<ContentDocumentLink> contentDocLinkList = new LIST<ContentDocumentLink>();
        try {
            if(recordId!=Null)
                contentDocLinkList = [SELECT ContentDocumentId, ContentDocument.ContentSize, 
                                      ContentDocument.Title, ContentDocument.ContentModifiedDate, 
                                      ContentDocument.CreatedDate, ContentDocument.FileExtension
                                      FROM ContentDocumentLink 
                                      WHERE LinkedEntityId =:recordId ORDER BY ContentDocument.CreatedDate DESC];
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return contentDocLinkList;
    }
    /* To query CustomValidationRules metadata records.*/
    public static LIST<IFv2_CustomValidationRules__mdt> getCustomValidations(String workflowName) {
        LIST<IFv2_CustomValidationRules__mdt> customvalidationlist;
        try {
            if(String.isNotBlank(workflowName))
                customvalidationlist = [SELECT DependentFieldAPI__c,RelatedList__c,RelatedListRecordType__c,MultiSelectPicklist__c,
                                        BothFieldsOnExtensionObject__c,HasExtensionObject__c,ValidationErrorMessage__c,
                                        ValidationFieldAPI__c,Workflows__c,ValidationFieldValue__c,ApproverValidation__c,
                                        ExtensionAPIName__c,Workflows__r.Name__c
                                        FROM IFv2_CustomValidationRules__mdt
                                        WHERE Workflows__r.name__c =: workflowName
                                        AND Status__c = 'Active'];
            
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return customvalidationlist;
    }
    /* To query Account Records */
    public static LIST<Account> getAccount(LIST<String> picklistvalue , string requestId) {
        LIST<Account> AccountList = new LIST<Account>();
        try {
            if(String.isNotBlank(requestId))
                AccountList = [SELECT id,IFv2_ContentType__c,RecordType.name,IFv2_Request__c
                               FROM Account 
                               WHERE IFv2_ContentType__c IN: picklistvalue 
                               AND RecordType.name = 'Request Items' 
                               AND IFv2_Request__c =: requestId];
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return AccountList;
    }
    /*To hold related list meta data*/
    public static LIST<IFv2_Section__mdt> getRelatedListMetadata(String workflowName, String oldRequestId) {
        LIST<IFv2_Section__mdt> sectionMetadata = new LIST<IFv2_Section__mdt>();
        LIST<IFv2_Section__mdt> tempSectionMetadata = new LIST<IFv2_Section__mdt>();
        try {
            if(String.isNotBlank(workflowName))
                sectionMetadata = [SELECT id, Value__c, Name__c, RelatedListType__c, Workflows__c, ExtendedValue__c, SectionNumber__c,Active__c
                                   FROM IFv2_Section__mdt
                                   WHERE Type__c = 'Related List' AND Workflows__r.Name__c=: workflowName AND Active__c = True 
                                   Order BY SectionNumber__c ASC];
            if(oldRequestId != null) {
                tempSectionMetadata = [SELECT id, Value__c, Name__c, RelatedListType__c, Workflows__c, ExtendedValue__c, SectionNumber__c,Active__c 
                                       FROM IFv2_Section__mdt
                                       WHERE Type__c = 'Related List' AND RelatedListType__c = 'Approval History' AND Active__c = True
                                       Order BY SectionNumber__c ASC];
                sectionMetadata.addAll(tempSectionMetadata);
            } 
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return sectionMetadata;
    }
    
    /*holds relate dlist data*/
    public static LIST<SObject> getRelatedRecords(String fields, String objectName, String recordId, String recordType) {
        LIST<SObject> record = new LIST<SObject>();
        if(fields == null) {
            fields = '';
        }
        if(!String.isBlank(objectName) && !String.isBlank(recordType) && !String.isBlank(recordId)){
            String recordSOQL = 'SELECT ';
            recordSOQL += fields+'IFv2_ContentType__c FROM '+objectName+' WHERE RecordType.name =:recordType AND IFv2_Request__c=:recordId ORDER BY CreatedDate DESC';
            try {
                record = Database.query(recordSOQL);
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            } 
        }
        return record;
    }
    
    @AuraEnabled
    public static User getUserName(String recordId) {
        LIST<User> records = new LIST<User>();
        User record = new User();
        try {
            if(String.isNotBlank(recordId)) {
                records = [SELECT Id, Name 
                           FROM User 
                           WHERE Id = :recordId LIMIT 1];
                
                if(!records.isEmpty()) {
                    record = records[0];
                }
            }
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        } 
        return record;
    }
    
    public static User getUserManager(String userId) {		
        LIST<User> records = new LIST<User>();		
        User userManager = new User();		
        try {		
            if(String.isNotBlank(userId)) {		
                records = [SELECT Id, Name, ManagerId 		
                           FROM User 		
                           WHERE Id = :userId LIMIT 1];		
                
                if(!records.isEmpty() && records[0].ManagerId != null) {		
                    userManager = [SELECT Id, Name 		
                                   FROM User 		
                                   WHERE Id = :records[0].ManagerId LIMIT 1];		
                }		
            }		
        } catch(QueryException qe) {		
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);		
        } 		
        return userManager;		
    }	
    
    public static LIST<PermissionSetAssignment> getExistingPermissionSets(SET<String> userIdsList) {
        LIST<PermissionSetAssignment> permissionsetlist = new LIST<PermissionSetAssignment>();
        try {
            if(!userIdsList.isEmpty())
                permissionsetlist = [SELECT Id,AssigneeId,PermissionSetId,PermissionSet.Label,PermissionSet.Name
                                     FROM PermissionSetAssignment
                                     WHERE AssigneeId IN : userIdsList];
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return permissionsetlist;
    }
    
    /*To get attachments*/
    public static Boolean getAttchments(String requestId) {
        LIST<ContentDocumentLink> attachmentlist = new LIST<ContentDocumentLink>();
        try {
            if(String.isNotBlank(requestId)) {
                attachmentlist = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink 
                                  WHERE LinkedEntityId in (SELECT Id FROM IFv2_Request__c where Id = :requestId) and LinkedEntity.Type='IFv2_Request__c'];
                if(test.isRunningTest()) {
                    Contact c=new contact();
                    c.LastName = 'test';
                    insert c;
                }
            }
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        } 
        if(!attachmentlist.isEmpty()) {
            return true;
        } else {
            return false;
        }
    }
    
    /* To get Pre defined workflow Metadata for mapping */
    public static LIST<Sobject> getPredefinedMapping(String workflowName) {
        LIST<sObject> sObjectList = new LIST<SObject>();
        User loggedinUser = IFv2_UtilsController.getLoggedInDetails();
        String userCurrency = loggedinUser.currency__c;
        
        MAP<string,Schema.SObjectField> mappingFieldMap = Schema.getGlobalDescribe().get('IFv2_RoleApproverMapping__mdt').getDescribe().fields.getMap();
        try {
            if(String.isNotBlank(workflowName)) {
                String query = 'SELECT '+ String.join(new LIST<String>(mappingFieldMap.keySet()),',') +' FROM IFv2_RoleApproverMapping__mdt '+' WHERE Workflows__r.Name__c =\''+ workflowName +'\'';
                if(workflowName == Label.CLIFv20049) {
                    if(userCurrency == 'EUR') {
                        query = query + ' order by ValueEur__c ASC';
                    } else if(userCurrency == 'INR') {
                        query = query + ' order by ValueINR__c ASC';
                    } else if(userCurrency == 'CNY') {
                        query = query + ' order by ValueCNY__c ASC';
                    } else if(userCurrency == 'USD') {
                        query = query + ' order by ValueUSD__c ASC';
                    } else if(userCurrency == 'BRL') {
                        query = query + ' order by ValueBRL__c ASC';
                    }
                }
                if(workflowName == Label.CLIFv20056) {
                    query = query +' order by LowerLimit__c ASC';
                }
                sObjectList = Database.query(query);
            }
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return sObjectList;
    }
    
    /*To hold extension records*/
    public static LIST<Sobject> getExtensionRecord(String recordId) {
        LIST<SObject> sobjectlist = new LIST<SObject>();
        try {
            if(String.isNotBlank(recordId)) {
                sobjectlist = [SELECT RequestExtension1__r.TotalPlannedDuration__c FROM IFv2_Request__c WHERE id =: recordId LIMIT 1];
            }
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return sobjectlist;
    }
    
    /* Method to query help icon url for request detail page help icon */
    public static String getHelpIconUrl(String workflow) {
        String fullFileURL;
        try {
            if(string.isnotblank(workflow)) { 
                LIST<IFv2_Workflow__c> WorkflowrecordLIST = [SELECT id,HelpUrl__c,Workflow__c 
                                                             FROM IFv2_Workflow__c 
                                                             WHERE Workflow__c = :workflow 
                                                             AND HelpUrl__c != null LIMIT 1];
                if(!WorkflowrecordLIST.isEmpty()) {
                    fullFileURL = WorkflowrecordLIST[0].HelpUrl__c;
                }
            } else {
                fullFileURL = null;
            }
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return fullFileURL;
    }
    
    /* Start of Iteration 3 */
    public static IFv2_Request__c getRequest(String requestId) {
        IFv2_Request__c relatedrequestRecord = new IFv2_Request__c();
        LIST<IFv2_Request__c> recordList = new LIST<IFv2_Request__c>();
        try {
            if(String.isNotBlank(requestId))
                recordList = [SELECT Id, MaterialNo__c, Account__r.IFv2_Plant__c,Account__r.IFv2_CustomerNo__c,
                              Account__r.IFv2_RevisionLevel__c,Account__r.IFv2_ConcessionCustomerText__c,Language__c,
                              SAPInstance__c,Full8Dreportnecessary__c,Account__r.IFv2_Escalatetomanagementlevel__c,
                              Account__r.IFv2_ConcessionSupplierName__c,Account__r.IFv2_SupplierNo__c,ConcessionDescription__c,
                              MaterialDescription__c,Account__r.IFv2_PlantName__c,Account__r.IFv2_Concession_Plant_Name__c
                              FROM IFv2_Request__C 
                              WHERE ID =: requestId];
            if(!recordList.isEmpty()) {
                relatedrequestRecord = recordList[0];
            }
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }
        return relatedrequestRecord;
    }
    
    /* Get related account records */
    public static  LIST<Account> getAccount(String idForOneMaterial) {
        LIST<Account> material = new LIST<Account>();
        try {
            Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Items').getRecordTypeId();
            if(recordTypeId!=Null || String.isNotBlank(idForOneMaterial))
                material = [SELECT Id, IFv2_Request__c,IFv2_Request__r.MaterialDescription__c, IFv2_Request__r.Language__c, 
                            IFv2_Request__r.MaterialNo__c,IFv2_Plant__c,IFv2_IsValidated__c,IFv2_ContentType__c,
                            IFv2_ConcessionCustomerText__c,IFv2_CustomerNo__c,IFv2_GoodsReceiptDocument__c,IFv2_RevisionLevel__c,
                            IFv2_ConcessionSupplierName__c,IFv2_SupplierNo__c,IFv2_Request__r.SAPInstance__c
                            FROM ACCOUNT 
                            WHERE IFv2_Request__c =: idForOneMaterial 
                            AND IFv2_ContentType__c = 'Material' 
                            AND recordtypeId =: recordTypeId limit 1
                           ];
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }
        return material;
    }
    
    /*Query to get concession fields*/
    public static LIST<IFv2_Request__c> getConcessionRequest(LIST<String> requestIds) {
        LIST<IFv2_Request__c> requestList = new LIST<IFv2_Request__c>();
        try {
            if(!requestIds.isEmpty())
                requestList = [
                    SELECT Id, Name, CreatedDate, SAPInstance__c, CategoryCodeDescription__c, MaterialNo__c, Account__r.IFv2_Plant__c, 
                    Account__r.IFv2_RevisionLevel__c, Account__r.IFv2_CustomerNo__c, Account__r.IFv2_ConcessionSupplierName__c, Account__r.IFv2_SupplierNo__c, 
                    SpecificRequirement__c, Account__r.IFv2_Description__c, Account__r.IFv2_Actualvaluenonconformity__c, Account__r.IFv2_Escalatetomanagementlevel__c, 
                    Account__r.IFv2_Furtherprocessing__c, Account__r.IFv2_Reliability__c, Account__r.IFv2_Function__c, 
                    Riskassessment__c, ReleaseDate__c, Buyer__c, Buyer__r.Department,Buyer__r.NT_User__c, Account__r.IFv2_CustomerApprovalInformation__c, 
                    Account__r.IFv2_Noreasonwhynot__c, Account__r.IFv2_Full8Dreportnecessarydescription__c, Account__r.IFv2_Containmentactionlongtext__c,
                    Account__r.IFv2_Full8Dreport__c, Account__r.IFv2_Containmentaction__c, Account__r.IFv2_Responsible__c, Account__r.IFv2_Responsible2__c,
                    Account__r.IFv2_Responsible3__c,Account__r.IFv2_Responsible4__c,Account__r.IFv2_Responsible5__c,
                    Account__r.IFv2_Effectivefrom__c, Account__r.IFv2_EffectiveFrom2__c, Account__r.IFv2_EffectiveFrom3__c,Account__r.IFv2_EffectiveFrom4__c,
                    Account__r.IFv2_EffectiveFrom5__c,Account__r.IFv2_Introducedon2__c,Account__r.IFv2_Introducedon3__c,Account__r.IFv2_Introducedon4__c,
                    Account__r.IFv2_Introducedon5__c,Account__r.IFv2_ContainmentActionLongText2__c,Account__r.IFv2_ContainmentActionLongText3__c,
                    Account__r.IFv2_ContainmentActionLongText4__c,Account__r.IFv2_ContainmentActionLongText5__c,
                    Account__r.IFv2_Introducedon__c, Account__r.IFv2_Responsiblefortrackingthequantities__c, X8Dreportno__c,
                    Account__r.IFv2_QuantitiesDeadlinedescription__c,ConcessionDescription__c, ApplicantNTUser__c, Account__r.IFv2_ContainmentAction2__c,
                    Account__r.IFv2_ContainmentAction3__c,Account__r.IFv2_ContainmentAction4__c,Account__r.IFv2_ContainmentAction5__c,
                    Remarks__c, Account__r.Valid_from__c, Account__r.Valid_to__c, Account__r.IFv2_Limitedtothefollowingquantity__c, 
                    Approver1__c, Approver1__r.NT_User__c, Approver2__c, Approver2__r.NT_User__c, Account__r.IFv2_CustomerName__c,Approver23__r.NT_User__c,
                    Approver3__c, Approver3__r.NT_User__c, ConcessionComment__c, Account__r.IFv2_Yescustomerreferenceno__c,Full8Dreportnecessary__c,
                    Account__r.IFv2_GoodsReceiptDocument__c, Account__r.IFv2_UsageProcess__c, Account__r.IFv2_Process__c, Account__r.IFv2_MaterialUsage__c
                    FROM IFv2_Request__c
                    WHERE Id IN: requestIds];
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }    
        return requestList;
    }
    
    /* To query process instance step */
    public static LIST<ProcessInstanceStep> getProcessInstanceStep(SET<Id> processInstancesMap) {
        LIST<ProcessInstanceStep> processInstaceStepList = new LIST<ProcessInstanceStep>();
        try {
            if(!processInstancesMap.isEmpty())
                processInstaceStepList = [SELECT Id, ProcessInstanceId, ActorId, Actor.Name, OriginalActorId, OriginalActor.Name, StepStatus, Comments, CreatedDate
                                          FROM ProcessInstanceStep
                                          WHERE ProcessInstanceId IN:processInstancesMap
                                          ORDER BY CreatedDate DESC];
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }
        return processInstaceStepList;
    }
    
    /* Query for Account records of type material */
    public static LIST<Account> getAccountMaterial(LIST<String> requestIds) {
        LIST<Account> additionalMaterials = new LIST<Account>();
        try {
            if(!requestIds.isEmpty())
                additionalMaterials = [SELECT Id, IFv2_RevisionLevel__c, IFv2_Request__c,
                                       IFv2_MaterialDescription__c,IFv2_MaterialNumber__c 
                                       FROM Account 
                                       WHERE IFv2_Request__c IN: requestIds 
                                       AND IFv2_ContentType__c = 'Material'];
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }
        return additionalMaterials;
    }
    
    /* To get users from Aprrover or proxy approver name from SAP */
    public static LIST<User> getUsersOfICO(String ApproverName, String ApproverProxyName) {
        LIST<User> userList = new LIST<User>();
        try {
            if(String.isNotBlank(ApproverName) || String.isNotBlank(ApproverProxyName))
                userList =[SELECT Id, NT_User__c 
                           FROM User 
                           WHERE isActive= true 
                           AND (NT_User__c =: ApproverName OR NT_User__c =: ApproverProxyName)];
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }
        return userList;
    }
    
    /* To get metadata records of ICO Workflow */
    public static LIST<IFv2_Workflows__mdt> getICOWorkflowMetadata(String worklflowNumber) {
        LIST<IFv2_Workflows__mdt> ICOWorkflowMdt = new LIST<IFv2_Workflows__mdt>();
        try {
            if(String.isNotBlank(worklflowNumber))
                ICOWorkflowMdt = [SELECT Id, Name__c, Status__c,ThirdPartyFormat__c,RequestStatus__c
                                  FROM IFv2_Workflows__mdt 
                                  WHERE ThirdPartyFormat__c = :worklflowNumber 
                                  AND Status__c = 'Active'];
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }
        return ICOWorkflowMdt;
    }
    
    /* For fetching SCAN record during insertion of ICO request record */
    public static LIST<Scan__c> getScanRecord(String SalesforceId) {
        LIST<Scan__c> scanRecordList = new LIST<Scan__c>();
        try {
            if(String.isNotBlank(SalesforceId)) {
                scanRecordList = [SELECT Id, Name
                                  FROM Scan__c 
                                  WHERE Name = :SalesforceId];
            }
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }
        return scanRecordList;
    }
    
    /* Get request record */
    public static IFv2_Request__c getICORequestRecord(String RequestId) {
        IFv2_Request__c requestRecord = new IFv2_Request__c();
        LIST<IFv2_Request__c> requestList = new LIST<IFv2_Request__c>();
        try {
            if(String.isNotBlank(RequestId)) {
                requestList = [SELECT ID,Name,Status__c,Workflow__c,RequestExtension1__c,RequestExtension2__c,RequestExtension3__c, 
                               InvoiceItemCurrency__c,CompanyCode__c,Ordernetprice__c,Approver1__c,Approver2__c,Approver3__c,
                               Approver4__c,Approver5__c,Approver6__c,Role01__c,Role02__c,Role03__c,Role04__c,Role05__c,Role06__c,CreatedDate
                               FROM IFv2_Request__c 
                               WHERE id=:RequestId LIMIT 1];
                
                if(!requestList.isEmpty()) {
                    requestRecord = requestList[0];
                }
            }
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }
        return requestRecord;
    }
    
    public static LIST<PermissionSetAssignment> deletePermissionSetAssignmentCheckbox(LIST<LIST<String>> permissionstIds, SET<Id> userIds) {
        LIST<PermissionSetAssignment> PermissionSetAssignmentList = new LIST<PermissionSetAssignment>();
        LIST<String> userlist=new LIST<String>();
        for(LIST<String> s:permissionstIds)
            userlist.addall(s);
        try {
            if(!userlist.isEmpty() && userIds != null && !userIds.isEmpty()){
                PermissionSetAssignmentList =  [SELECT Id,AssigneeId,PermissionSetId 
                                                FROM PermissionSetAssignment 
                                                WHERE AssigneeId IN : userIds 
                                                AND PermissionSetId IN : userlist];
            }
        } catch(Exception qe) { 
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return PermissionSetAssignmentList;
    }
    
    /* Method to query for custom error messages */
    public static LIST<IFv2_CustomErrorMessages__c> getCustomErrorMessages(String errorMessage) {
        LIST<IFv2_CustomErrorMessages__c> customErrorMessages = new LIST<IFv2_CustomErrorMessages__c>();
        if(errorMessage != null){
            String standardError = '%'+errorMessage+'%';
            try {
                customErrorMessages = [SELECT Id,CustomErrorMessage__c,StandardErrorMessage__c,IsActive__c
                                       FROM IFv2_CustomErrorMessages__c 
                                       WHERE IsActive__c = TRUE 
                                       AND StandardErrorMessage__c LIKE :standardError];
            } catch(Exception e) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(e);
            }
        }
        return customErrorMessages;
    }
    
    /* Method to query role Approver mapping */
    public static LIST<IFv2_RoleApproverMapping__mdt> getRoleApproverMapping(String workflowname) {
        LIST<IFv2_RoleApproverMapping__mdt> roleApproverMapping = new LIST<IFv2_RoleApproverMapping__mdt>();
        try {
            if(String.isNotBlank(workflowname)) {
                roleApproverMapping =     [SELECT id,Workflows__r.Name__c 
                                           FROM  IFv2_RoleApproverMapping__mdt
                                           WHERE Workflows__r.name__c =: workflowname];
            } 
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }
        return roleApproverMapping;
    }
    
    /* Query request */
    public static IFv2_Request__c getConcessionRequest(String requestId) {
        IFv2_Request__c requestrecord = new IFv2_Request__c();
        LIST<IFv2_Request__c> recordList = new LIST<IFv2_Request__c>();
        try {
            if(String.isNotBlank(requestId)) {
                recordList = [SELECT Id, IsMaterialValidated__c, CategoryCodeDescription__c,ApplicantNTUser__c 
                              FROM IFv2_Request__c 
                              WHERE Id=:requestId LIMIT 1];
                if(!recordList.isEmpty()) {
                    requestrecord = recordList[0];
                }
            } 
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }
        return requestrecord;
    }
    
    /* Get Account details */
    public static LIST<Account> validateConcession(String idForOneMaterial) {
        LIST<Account> accountList = new LIST<Account>();
        try {
            Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Items').getRecordTypeId();
            if(String.isNotBlank(idForOneMaterial) && recordTypeId!=Null) {
                accountList = [SELECT Id, IFv2_IsValidated__c,IFv2_Request__c 
                               FROM Account 
                               WHERE IFv2_Request__c =: idForOneMaterial AND IFv2_IsValidated__c=false AND recordTypeId =: RecordTypeId];
                
            }
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }
        return accountList;
    }
    
    /* Method to retreive the records from request object */
    public static LIST<sObject> getRequestRecord(SET<Id> requestIdSET, String fields) {
        LIST<sObject> record = new LIST<sObject>();
        
        if(!requestIdSET.isEmpty() && !String.isBlank(fields)) {
            String query = 'SELECT Id,ownerId,createdById,' + fields + ' FROM IFv2_Request__c WHERE Id IN :requestIdSET';
            try {
                record = Database.query(query);
            } catch(QueryException qe) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
            }
        }
        return record;
    }
    
    public static LIST<Account> getAccountRecords(SET<Id> accountIdSET, Id recordTypeId) {
        LIST<Account> insertedAccountRecordLIST = new LIST<Account>();
        try {
            if(accountIdSET != null && !accountIdSET.isEmpty() && recordTypeId != null){
                insertedAccountRecordLIST = [SELECT Id, IFv2_Request__c 
                                             FROM ACCOUNT 
                                             WHERE Id IN : accountIdSET  AND RecordTypeId =: recordTypeId];
            }
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return insertedAccountRecordLIST;
    }
    
    // Method to get request related account records
    public static LIST<Account> getRequestRelatedAccountRecords(SET<Id> accountIdSET, Id recordTypeId) {
        LIST<Account> insertedAccountRecordLIST =  new LIST<Account>();
        try {
            if(accountIdSET != null && !accountIdSET.isEmpty() && recordTypeId != null){
                insertedAccountRecordLIST = [SELECT Id, IFv2_Request__c 
                                             FROM ACCOUNT 
                                             WHERE IFv2_Request__c IN : accountIdSET  AND RecordTypeId =: recordTypeId];
            }
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return insertedAccountRecordLIST;
    }
    
    public static LIST<User> getActiveUsers(SET<Id> userIdSET) {
        LIST<User> userRecordsLIST = new LIST<User>();
        try {
            if(userIdSET != null && !userIdSET.isEmpty()){
                userRecordsLIST = [SELECT id 
                                   FROM User 
                                   WHERE Id IN : userIdSET AND IsActive = True];
            }
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }
        return userRecordsLIST;
    }
    
    /* Method to update all records of out of office and back to office */
    public static LIST<IFv2_AdminOnly__c> getAdminOnlyRecords(Id userId) {
        LIST<IFv2_AdminOnly__c> adminOnlyrecordsLIST = new LIST<IFv2_AdminOnly__c>();
        try {
            adminOnlyrecordsLIST = [SELECT Id,User__c 
                                    FROM IFv2_AdminOnly__c 
                                    WHERE CreatedById =: userId AND  recordtype.name = 'OutOfOfficeLogs'];
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }
        return adminOnlyrecordsLIST;
    }
    /* End of Iteration 3 */
    public static LIST<Account> getMaterialsDetailList(Id requestId, String fieldList) {
        LIST<Account> materialLIST = new LIST<Account>();
        if(requestId != null) {
            try {
                if(!String.isBlank(fieldList)) {
                    String query = 'SELECT ' + fieldList + ' FROM Account WHERE IFv2_Request__c =:requestId';
                    materialLIST = Database.query(query);
                }
            } catch(Exception e) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(e);
            }
        }
        return materialLIST;
    }
    
    /* Method to query request details for submitting for approval */
    public static LIST<IFv2_Request__c> fetchInsertedRequests(SET<Id> requestIds) {
        LIST<IFv2_Request__c> requestLIST = new LIST<IFv2_Request__c>();
        if(requestIds.size()>0) {
            try {
                String query = 'SELECT Id, Workflow__c, Status__c, Parallel__c, OldRequest__c, OldRequestName__c, RequestExtension1__c, RequestExtension2__c, RequestExtension3__c, Account__c FROM IFv2_Request__c WHERE Id in:requestIds';
                requestLIST = Database.query(query);
            } catch(Exception e) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(e);
            }
        }
        return requestLIST;
    }
    /* Method to share records */
    @Future
    public static void RecordShare(Set <Id> Approvers, Id recordid, String extension1ShareRecord, String extension2ShareRecord, String extension3ShareRecord, String accountId, String workflowName) {
        
        if(!String.isBlank(recordid)){
            LIST<IFv2_Request__Share> recordShareList = new LIST<IFv2_Request__Share>();
            /* Lists to store Extension object */
            LIST<IFv2_RequestExtension1__Share> Extension1RecordsList = new LIST<IFv2_RequestExtension1__Share>();
            LIST<IFv2_RequestExtension2__Share> Extension2RecordsList = new LIST<IFv2_RequestExtension2__Share>();
            LIST<IFv2_RequestExtension3__Share> Extension3RecordsList = new LIST<IFv2_RequestExtension3__Share>();
            SET<AccountShare> AccountShareSET = new SET<AccountShare>();
            MAP<Id,Boolean> userStatusMap = new MAP<Id,Boolean>();
            SET<Id> approverIdSET = new SET<Id>(); // user id set where user is active 
            
            String adminString = label.CLIFv20162;
            LIST<String> adminLIST = new LIST<String>();
            adminLIST.addAll(adminString.split(','));
            
            LIST<User> adminUserRecordLIST = [SELECT Id,name 
                                              FROM User 
                                              WHERE profile.name In: adminLIST AND Id IN: Approvers];
            SET<Id> adminUserIdSET = new SET<Id>();
            
            for(User userId : adminUserRecordLIST){
                adminUserIdSET.add(userId.Id);
            }
            
            if(Approvers != null && !Approvers.isEmpty()){
                // Query for User Id records where users are active 
                LIST<User> userRecordLIST = [SELECT Id 
                                             FROM User 
                                             WHERE Id IN : Approvers and IsActive = True];
                
                // Getting logged in user logged in user details
                User loggedInUserRecord = IFv2_UtilsController.getLoggedInDetails();
                // Id to assign logged in user Id
                Id loggedInUserId;
                // Checking if loggedInUserRecord is not NULL
                if(loggedInUserRecord != NULL) {
                    loggedInUserId = loggedInUserRecord.Id; 
                }
                
                
                for(User userRecord : userRecordLIST) {
                    // to check if logged in user id is not in approvers
                    if(userRecord.Id != loggedInUserId )
                        approverIdSET.add(userRecord.Id);
                }
                
                
                // String to store workflowRegion
                String workflowRegion; 
                //Checking if workflowName is not Null
                if(!String.isBlank(workflowName)){
                    workflowRegion = IFv2_UtilsController.getWorkflows(workflowName);
                    System.debug('workflowRegion>'+workflowRegion);
                }
                
                // Query for Account related records 
                LIST<Account> accountLIST = new LIST<Account>();
                //Checking if Account is Private
                if(system.Label.CLIFv20189 == 'True' && recordid != NULL || Test.isRunningTest()) {
                    
                    Id requestItemsRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Items').getRecordTypeId();
                    if(requestItemsRecordTypeId != NULL) {
                        accountLIST = [SELECT Id 
                                       FROM Account 
                                       WHERE IFv2_Request__c = : recordid AND RecordTypeId =: requestItemsRecordTypeId ];
                    }
                }
                
                /* To create share records. */
                for(Id approver : approverIdSET) {
                    IFv2_Request__Share shareRecord = new IFv2_Request__Share();
                    shareRecord.ParentId = recordid ;
                    shareRecord.UserOrGroupId = approver;
                    shareRecord.AccessLevel = 'read';
                    shareRecord.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                    recordShareList.add(shareRecord);
                    if( extension1ShareRecord != NUll || extension2ShareRecord != NUll || extension3ShareRecord != NULL || accountId != NULL)  {
                        if(workflowRegion== 'APAC' && extension1ShareRecord != NULL && extension1ShareRecord != '') {
                            IFv2_RequestExtension1__Share shareRecord1 = new IFv2_RequestExtension1__Share();
                            shareRecord1.ParentId = extension1ShareRecord ;
                            shareRecord1.UserOrGroupId = approver;
                            shareRecord1.AccessLevel = 'read';
                            shareRecord1.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                            Extension1RecordsList.add(shareRecord1);
                        } 
                        else if(workflowRegion == 'EMEA' && extension2ShareRecord != NULL && extension2ShareRecord != '') {
                            IFv2_RequestExtension2__Share shareRecord2 = new IFv2_RequestExtension2__Share();
                            shareRecord2.ParentId = extension2ShareRecord ;
                            shareRecord2.UserOrGroupId = approver;
                            shareRecord2.AccessLevel = 'read';
                            shareRecord2.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                            Extension2RecordsList.add(shareRecord2);
                        }
                        else if(workflowRegion == 'NALA' &&  extension3ShareRecord != NULL && extension3ShareRecord != '') {
                            IFv2_RequestExtension3__Share shareRecord3 = new IFv2_RequestExtension3__Share();
                            shareRecord3.ParentId = extension3ShareRecord ;
                            shareRecord3.UserOrGroupId = approver;
                            shareRecord3.AccessLevel = 'read';
                            shareRecord3.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                            Extension3RecordsList.add(shareRecord3);
                        }
                        //Checking if Account is Private
                        if(System.Label.CLIFv20189 == 'True'  || Test.isRunningTest()) {
                            if(workflowRegion == 'ALL' && accountId != NULL && !adminUserIdSET.contains(approver)) {
                                AccountShare accountShareRecord = new AccountShare();
                                accountShareRecord.AccountId = accountId ;
                                accountShareRecord.UserOrGroupId = approver;
                                accountShareRecord.AccountAccessLevel = 'read';
                                accountShareRecord.RowCause = Schema.AccountShare.RowCause.Manual;
                                accountShareRecord.OpportunityAccessLevel = 'none';
                                AccountShareSET.add(accountShareRecord);
                            }
                            // Sharing related lists 
                            if(!accountLIST.isEmpty()) {
                                for(Account accountRecord : accountLIST ) {
                                    if(!adminUserIdSET.contains(approver) || Test.isRunningTest()) {
                                        AccountShare accountShareRecord = new AccountShare();
                                        accountShareRecord.AccountId = accountRecord.Id ;
                                        accountShareRecord.UserOrGroupId = approver;
                                        accountShareRecord.AccountAccessLevel = 'read';
                                        accountShareRecord.RowCause = Schema.AccountShare.RowCause.Manual;
                                        accountShareRecord.OpportunityAccessLevel = 'none';
                                        AccountShareSET.add(accountShareRecord);
                                    }
                                }
                            }
                        }
                    }
                }
                /*To insert share records*/
                IFv2_DmlController.insertShareRecords(recordShareList);
                if(!Extension1RecordsList.isEmpty())
                    IFv2_DmlController.insertShareRecordsAPAC(Extension1RecordsList);
                else if(!Extension2RecordsList.isEmpty())
                    IFv2_DmlController.insertShareRecordsEMAE(Extension2RecordsList);
                else if(!Extension3RecordsList.isEmpty())
                    IFv2_DmlController.insertShareRecordsNALA(Extension3RecordsList);
                if(!AccountShareSET.isEmpty()){
                    LIST<AccountShare> accountShareLIST = new LIST<AccountShare>();
                    accountShareLIST.addAll(AccountShareSET);
                    IFv2_DmlController.insertAccountShare(accountShareLIST);
                }  
            }
        }     
    }
    
    /* Method to revoke record access */
    @Future
    public static void RevokeRecordAccess(Set <Id> Approvers, Id recordid, String extension1ShareRecord, String extension2ShareRecord, String extension3ShareRecord, String accountId, String workflowName) {       
        if(!String.isBlank(recordid)){
            // LIST<IFv2_Request__Share> recordShareList = new LIST<IFv2_Request__Share>();
            /* Lists to store Extension object */
            System.debug('Extensions>'+extension1ShareRecord+'>'+extension2ShareRecord+'>'+extension3ShareRecord);
            LIST<IFv2_RequestExtension1__Share> Extension1RecordsList = new LIST<IFv2_RequestExtension1__Share>();
            LIST<IFv2_RequestExtension2__Share> Extension2RecordsList = new LIST<IFv2_RequestExtension2__Share>();
            LIST<IFv2_RequestExtension3__Share> Extension3RecordsList = new LIST<IFv2_RequestExtension3__Share>();
            LIST<AccountShare> AccountRevokeList = new LIST<AccountShare>();
            MAP<Id,Boolean> userStatusMap = new MAP<Id,Boolean>();
            SET<Id> approverIdSET = new SET<Id>(); // user id set where user is active 
            
            String adminString = label.CLIFv20162;
            LIST<String> adminLIST = new LIST<String>();
            adminLIST.addAll(adminString.split(','));
            
            LIST<User> adminUserRecordLIST = [SELECT Id,name 
                                              FROM User 
                                              WHERE profile.name In: adminLIST AND Id IN: Approvers];
            SET<Id> adminUserIdSET = new SET<Id>();
            
            for(User userId : adminUserRecordLIST){
                adminUserIdSET.add(userId.Id);
            }
            
            if(Approvers != null && !Approvers.isEmpty()){
                // Query for User Id records where users are approver but not admin 
                LIST<User> userRecordLIST = [SELECT Id 
                                             FROM User 
                                             WHERE Id IN : Approvers and Id NOT IN :adminUserIdSET];
                System.debug('revoke userlist>'+userRecordLIST);
                // Getting logged in user logged in user details
                User loggedInUserRecord = IFv2_UtilsController.getLoggedInDetails();
                // Id to assign logged in user Id
                Id loggedInUserId;
                // Checking if loggedInUserRecord is not NULL
                if(loggedInUserRecord != NULL) {
                    loggedInUserId = loggedInUserRecord.Id; 
                }
                For(User user:userRecordLIST) {
                    approverIdSET.add(user.id);
                }
                if(approverIdSET.contains(loggedInUserId)) {
                    approverIdSET.remove(loggedInUserId);  
                }
                
                
                // String to store workflowRegion
                String workflowRegion; 
                //Checking if workflowName is not Null
                if(!String.isBlank(workflowName)){
                    workflowRegion = IFv2_UtilsController.getWorkflows(workflowName);
                }
                
                // Query for Account related records 
                LIST<Account> accountLIST = new LIST<Account>();
                //Checking if Account is Private
                if(recordid != NULL || Test.isRunningTest()) {
                    Id requestItemsRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Items').getRecordTypeId();
                    if(requestItemsRecordTypeId != NULL) {
                        accountLIST = [SELECT Id 
                                       FROM Account 
                                       WHERE IFv2_Request__c = : recordid AND RecordTypeId =: requestItemsRecordTypeId ];
                    }
                }
                
                List<IFv2_Request__Share> revokeRecordList=[select id from IFv2_Request__Share WHERE ParentId=:recordid AND UserOrGroupId IN : approverIdSET];
                System.debug('revoke recd>'+revokeRecordList);
                if( extension1ShareRecord != NUll || extension2ShareRecord != NUll || extension3ShareRecord != NULL || accountId != NULL)  {
                    if(workflowRegion== 'APAC' && extension1ShareRecord != NULL && extension1ShareRecord != '') 
                    {
                        Extension1RecordsList = [select id from IFv2_RequestExtension1__Share WHERE ParentId=:extension1ShareRecord AND UserOrGroupId IN : approverIdSET];   
                        
                    }
                    else if(workflowRegion == 'EMEA' && extension2ShareRecord != NULL && extension2ShareRecord != '')
                    {
                        Extension2RecordsList = [select id from IFv2_RequestExtension2__Share WHERE ParentId=:extension2ShareRecord AND UserOrGroupId IN : approverIdSET];       
                        
                    }
                    else if(workflowRegion == 'NALA' &&  extension3ShareRecord != NULL && extension3ShareRecord != '') 
                    {
                        Extension3RecordsList = [select id from IFv2_RequestExtension3__Share WHERE ParentId=:extension3ShareRecord AND UserOrGroupId IN : approverIdSET];
                        
                    }
                    if(workflowRegion == 'ALL' && accountId != NULL) 
                    {
                        AccountRevokeList = [select id from AccountShare WHERE AccountId=:accountId AND UserOrGroupId IN : approverIdSET];           
                        
                    }
                }
                
                /*To revoke record access*/
                IFv2_DmlController.deleteShareRecords(revokeRecordList);
                if(!Extension1RecordsList.isEmpty())
                    IFv2_DmlController.deleteShareRecordsAPAC(Extension1RecordsList);
                else if(!Extension2RecordsList.isEmpty())
                    IFv2_DmlController.deleteShareRecordsEMAE(Extension2RecordsList);
                else if(!Extension3RecordsList.isEmpty())
                    IFv2_DmlController.deleteShareRecordsNALA(Extension3RecordsList);
                if(!AccountRevokeList.isEmpty()){
                    IFv2_DmlController.deleteShareRecordsAccount(AccountRevokeList);
                }  
            }
        }     
    }
    
}