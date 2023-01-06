/*******************************************************************************************************
* 
* @ Name 			:	IFv2_WorkflowListviewController
* @ Purpose 		: 	Controller for Workflow Listview
* @ Methods 		:   1) fetchWorkflows - Displaying workflows according to profile categorisation
*							params - sObjectName
*						2) createRequestRecord - Create Request record
*							params - WorkflowName
* @ Author			: 	Pradeep Chary
* @ Usage			: 	1) For displaying workflow list on the workflow page according to the user
*						2) For creating a request from the workflow page onclick of execute
* @ Test class name :   IFv2_WorkflowListviewControllerTest
*
*   Date	        |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   30-10-2018      |  pradeep.chary@absyz.com (yv)	|  1.0          |  Initial Version
*   05-11-2018      |  vivek.kothalanka@absyz.com	|  1.1          |  Added Profile Categorization Logic.
*	18-05-2021      |  pradeep.chary@absyz.com		|  2.0          |  Making it without sharing for B2B Portal
*
*******************************************************************************************************/
public without sharing class IFv2_WorkflowListviewController {
    
    /* fetch the Workflow records from the custom settings */
    @AuraEnabled(cacheable = true)
    public static WorkflowList fetchWorkflows(String sObjectName) {
        
        LIST<String> columnLabelList = new LIST<String>();  //Contains labels of column headers
        LIST<String> FieldAPINameList = new LIST<String>();  //Contains list of Field API Names to be displayed on the table
        SET<String> userId = new SET<String>();  //Ids of Users to be shown as link on the table
        String apiName = '';
        String fieldType = '';
        /* map of labels and its apinames */
        MAP<String, String> labelToAPIName = new MAP<String, String>();
        
        /* map of labels and its types */
        MAP<String, Schema.DisplayType> labelToType = new MAP<String, Schema.DisplayType>();
        
        /* complete map of IFv2_Workflow custom settings */
        MAP<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.IFv2_Workflow__c.fields.getMap();
        
        for (Schema.SObjectField field : fieldsMap.values()) {
            labelToAPIName.put(field.getDescribe().getLabel(), field.getDescribe().getName());
            labelToType.put(field.getDescribe().getLabel(), field.getDescribe().getType());
        }
        
        /* fetching Workflow custom label */
        String fieldsList = System.Label.CLIFv20036;
        LIST<String> fields = fieldsList.trim().split(',');  //List of fields
        LIST<String> APINAMES = new LIST<String>();
        for (String field : fields) {
            apiname = apiname + ',' + labelToAPIName.get(field);
            fieldType = fieldType + ',' + labelToType.get(field);
        }
        
        /* User profile logic */
        LIST<String> profile_List = new LIST<String>();  //Contains list of profiles that have system admin access
        LIST<String> limitedAccessUser = new LIST<String>();  //Contains list of profiles that have limited access
        
        /* Custom Labels to get profles who have Access*/
        String systemAdminAccess = System.Label.CLIFv20008;
        String profilelimitedAccess = System.Label.CLIFv20009;
        
        if (!String.isBlank(systemAdminAccess)) {
            profile_List.addAll(systemAdminAccess.split(','));
        }
        if (!String.isBlank(profilelimitedAccess)) {
            limitedAccessUser.addAll(profilelimitedAccess.split(','));
        }
        
        User userRecord = IFv2_UtilsController.getLoggedInDetails();
        String profileName = userRecord.Profile.Name;
        String userCountry = userRecord.Country;
        String logggedInUserId = userRecord.Id;
        
        /*checking if profile is not null */
        if (profileName != null) {
            
            /* Logic to check if logged in user is System Admin. */
            if (profile_List.contains(profileName)) {
                SET<String> mergedSet = new SET<String>();  //Contains list of all active workflows to be displayed on the list view
                LIST<IFv2_Workflows__mdt> workflowList = IFv2_UtilsController.getWorkflows();
                
                for (IFv2_Workflows__mdt workflow : workflowList) {
                    mergedSet.add(workflow.Name__c);
                }
                
                WorkflowList workflows = new WorkflowList();
                workflows.settings = IFv2_UtilsController.getWorkflowRecords(
                    apiName, 
                    sObjectName, 
                    mergedSet, 
                    true, 
                    userCountry
                );
                workflows.apiNames = apiName;
                workflows.fieldsType = fieldType;
                workflows.userProfileName = profileName;
                
                /* fetching owner and expert ID from the retrieved workflows */
                if (fields.indexOf('Local Expert') != -1 || fields.indexOf('Process Owner') != -1 ) {
                    for (SObject iterator : workflows.settings) {
                        
                        if (fields.indexOf('Local Expert') != -1 && 
                           iterator.get('LocalExpert__c') != null &&
                           iterator.get('LocalExpert__c') != '') { 
                               userId.add(iterator.get('LocalExpert__c').toString()); 
                           }
                        
                        if (fields.indexOf('Process Owner') != -1 && 
                           iterator.get('ProcessOwner__c') != null && 
                           iterator.get('ProcessOwner__c') != '') {
                               userId.add(iterator.get('ProcessOwner__c').toString());
                           }
                    }
                }
                
                if (!userId.isEmpty()) {
                    list<string> userIds = new list<string>(userId);  //Converting set to list
                    workflows.userName = IFv2_UtilsController.getRecordName(userIds, 'User', null);
                }
                
                return workflows;
            }
            
            /* Logic to execute if logged in user is not Admin and user profile is only SG Standard User. */
            else if (limitedAccessUser.contains(profileName)) {
                
                String loggedInUserDepartment = userRecord.Department;
                SET<String> groupSet = new SET<String>();  // Set for Storing Group names.
                SET<String> WorkflowSet = new SET<String>();  //Contains workflow names available to the user
                SET<String> DivisionSet = new SET<String>();  // Get logged in user division start 
                
                /* To get division of logged in user */
                if (loggedInUserDepartment != null) {
                    LIST<IFv2_Department__mdt> departmentList = IFv2_UtilsController.getdepartments(loggedInUserDepartment);
                    /* New logic */
                    if (!departmentList.isEmpty()) {
                        for (IFv2_Department__mdt department : departmentList) {
                            DivisionSet.add(department.Division__r.DeveloperName);
                        }
                    }
                }
                
                /* Group Logic to check if user is added to any public group for specific workflow */
                LIST<Id> groupId = new LIST<Id>();
                LIST<GroupMember> groupsList = IFv2_UtilsController.getGroups(groupId);
                for (GroupMember currentGroup :  groupsList) {
                    groupSet.add(currentGroup.group.Name);
                }
                
                /* Get AllWorkflows. */
                LIST<IFv2_Workflows__mdt> workflowList = IFv2_UtilsController.getWorkflows();
                for (IFv2_Workflows__mdt workflow : workflowList) {
                    /* To check for general workflow */
                    if (workflow.General__c ) {
                        WorkflowSet.add(workflow.Name__c);
                    } else if (workflow.Country__c == 'Global' || workflow.Country__c == userCountry) {
                        if (workflow.Users__c == null) {
                            if (workflow.Country__c == 'Global') {
                                if (workflow.Division__r.DeveloperName == null) {
                                    WorkflowSet.add(workflow.Name__c);
                                } else if (workflow.Division__r.DeveloperName != null && 
                                          DivisionSet.contains(workflow.Division__r.DeveloperName)) {
                                              WorkflowSet.add(workflow.Name__c);
                                          }
                            } else if (workflow.Country__c == userCountry) {
                                if (workflow.Division__r.DeveloperName == null) {
                                    WorkflowSet.add(workflow.Name__c);
                                } else if (workflow.Division__r.DeveloperName != null && 
                                          DivisionSet.contains(workflow.Division__r.DeveloperName)) {
                                              WorkflowSet.add(workflow.Name__c);
                                          }
                            } else {
                                // Nothing
                            }
                        } else {
                            /* If logged in Id is specifed in Users Field in Metadata*/
                            LIST<String> additonalUsersIdsList = new LIST<String>();
                            if (!workflow.EnteredValueisPublicGroup__c) {
                                if (workflow.Users__c!= NULL )
                                    additonalUsersIdsList.addAll(workflow.Users__c.split(','));
                            }
                            
                            /* Add workflow to users workflow list view if user ids is sepcified in users field in workflow metadata */
                            if (!additonalUsersIdsList.isEmpty()) {
                                if (additonalUsersIdsList.contains(logggedInUserId))
                                    WorkflowSet.add(workflow.Name__c);
                            }
                            /* Giving Access through public groups */
                            if (!groupSet.isEmpty()) {
                                if (groupSet.contains(workflow.Users__c) && workflow.EnteredValueisPublicGroup__c)
                                    WorkflowSet.add(workflow.Name__c);
                            }
                        }
                    }
                }
                
                /* assign data to the wrapper class */
                WorkflowList workflows = new WorkflowList();
                workflows.settings = IFv2_UtilsController.getWorkflowRecords(
                    apiName, 
                    sObjectName, 
                    WorkflowSet, 
                    false, 
                    userCountry
                );
                workflows.apiNames = apiName;
                workflows.fieldsType = fieldType;
                workflows.userProfileName = profileName;
                
                /* fetching the Local Expert Id and Process Owner Id from the queried workflows*/
                for (SObject iterator : workflows.settings) {
                    if (iterator.get('LocalExpert__c') != null && iterator.get('LocalExpert__c') != '') { 
                        userId.add(iterator.get('LocalExpert__c').toString()); 
                    }
                    if (iterator.get('ProcessOwner__c') != null && iterator.get('ProcessOwner__c') != '') {
                        userId.add(iterator.get('ProcessOwner__c').toString());
                    }
                }
                
                if (!userId.isEmpty()) { 
                    list<string> userIds = new list<string>(userId);
                    workflows.userName = IFv2_UtilsController.getRecordName(userIds, 'User', null);
                }
                
                return workflows; 
            } else {
                return new WorkflowList();
            }
        } else {
            return new WorkflowList();
        }
    }
    
    /* wrapper class */
    public class WorkflowList {
        
        /* to store the workflow records */
        @AuraEnabled
        public LIST<Sobject> settings {get; set;}
        
        /* for apiNames of the fields to be displayed */
        @AuraEnabled
        public String apiNames {get; set;}
        
        /* for the type of the fields to be displayed */
        @AuraEnabled
        public String fieldsType {get; set;}
        
        /* for the names of expert and process owners */
        @AuraEnabled
        public LIST<SObject> userName {get; set;}
        
        /* for the profile of the logged In user */
        @AuraEnabled
        public String userProfileName {get; set;}
        
        public WorkflowList() {
            
        }
    }
    
    /* The method for execute button on Workflow Listview */
    @AuraEnabled
    public static sObject createRequestRecord (IFv2_Workflow__c workflow) {
        String requestId = IFv2_DmlController.insertRequestRecord(workflow);
        IFv2_Request__c record = new IFv2_Request__c();
        
        if (!String.isBlank(requestId)) {
            record = [SELECT Id,Name FROM IFv2_Request__c WHERE ID = :requestId];
        }
        
        return record;
    }  
}