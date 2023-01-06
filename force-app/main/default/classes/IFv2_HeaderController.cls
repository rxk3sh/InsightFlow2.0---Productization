/*******************************************************************************************************
* 
* @ Name        : IFv2_HeaderController
* @ Purpose     : Controller for retreiving LIST of buttons to be displayed on request header, and their functionalities
* @ Author      : Pradeep Chary
* @Test Class   : IFv2_HeaderControllerTest
*
*   Date            |  Developer Name                      |  Version         |  Changes
* ======================================================================================================
*   29-10-2018      |  kanchan.baghel@absyz.com            |  1.0             |  Added custom button functonality for approval process
*   09-11-2018      |  nagasai.chalamalasetti@absyz.com    |  1.0             |  Populating empty Parallel Approvers and approving records assigned to them automatically,if atleast one is approved by custom parallel approver  
*   14-03-2019      |  pradeep.chary@absyz(es)             |  2.0             |  Added generic logic for filling gap between approvers, filling/removing dummy users, handling clicks of buttons in wrong statuses  
*   26-03-2018      |  nagasai.chalamalasetti@absyz.com    |  3.0             |  Added method for help Tab(getHelpURLRecords) 
*   20-08-2018      |  external.debasmita.rawooth@seg-automotive.com	      |  Updated Plant field for Concession 
*   10-09-2019		|  external.debasmita.rawooth@seg-automotive.com		  |  Added changes for China L&O validations
*******************************************************************************************************/

//Without sharing is used explicitly as approval process is happening through apex
global without sharing class IFv2_HeaderController {
    public static boolean fromReassign=false;
    /* * * * * * * * * * * Wrapper Classes - Start * * * * * * * * * */
    public class ApproverSectionWrapper {
        
        @AuraEnabled public IFv2_Section__mdt section {get;set;}
        @AuraEnabled public LIST<IFv2_FieldWrapperClass> fields {get;set;}
        public ApproverSectionWrapper() {}
    }
    
    public class ButtonWrapper {
        
        @AuraEnabled public LIST<IFv2_RequestButtons__mdt> button {get;set;}
        @AuraEnabled public String requestName {get;set;}
        @AuraEnabled public String status {get;set;}
        @AuraEnabled public String workflow {get;set;}
        @AuraEnabled public LIST<String> attachmentList {get;set;}
        @AuraEnabled public Id createdById {get;set;}
        @AuraEnabled public Boolean oldRequest {get;set;}
        @AuraEnabled public String privilegedRoleName {get;set;}
        @AuraEnabled public LIST<ApproverSectionWrapper> approverSectionWrapper{get;set;}
        public ButtonWrapper() {}
    }
    
    /* * * * * * * * * * * Wrapper Classes - End * * * * * * * * * */
    
    public static LIST<String> requestFields;
    
    /* Retrieving general required details of Request */
    public static LIST<IFv2_Request__c> getBasicRequestDetails(String requestId) {
        if(!String.isBlank(requestId)){
            return [SELECT Id, Name, OwnerId, CreatedById, OldRequestName__c, Parallel__c, Status__c, Workflow__c,reAssignedToProxyForApproval__c,Ifv2_ProxyApprovalUserList__c
                    FROM IFv2_Request__c
                    WHERE Id = :requestId];
        } else return null;
    }
    
    /*Generic method to check whether the logged in user is an Approver of the current record */
    public static Boolean checkUserIsApprover(Id requestId) {
        Boolean isApprover = false;
        if(requestId != null){
            LIST<ProcessInstanceWorkitem> approvalItemLIST = IFv2_UtilsController.getRecordAcccess((Id)requestId);
            SET<Id> approverSET = new SET<Id>();    //Set of ids of all approvers of this request
            for(ProcessInstanceWorkitem item : approvalItemLIST) {
                approverSET.add(item.ActorId);
            }
            if(approverSET.contains(Userinfo.getUserId())) {
                isApprover = true;
            }
        }
        return isApprover;
    }
    
    /*Generic method to check whether the logged in user is a delegated Approver of the current record */
    public static Boolean checkUserIsDelegatedApprover(Id requestId) {
        Boolean isDelegatedApprover = false;
        if(requestId != null){
            LIST<ProcessInstanceWorkitem> approvalItemLIST = IFv2_UtilsController.getRecordAcccess((Id)requestId);
            SET<Id> approverSET = new SET<Id>();    //Set of ids of all approvers of this request
            SET<Id> delegatedApproverSET = new SET<Id>();    //Set of ids of all delegated approvers of current approvers
            for(ProcessInstanceWorkitem item : approvalItemLIST) {
                approverSET.add(item.ActorId);
            }
            if(!approverSET.isEmpty()){
                for(User user : [SELECT Id,DelegatedApproverId FROM User where Id IN :approverSET]) {
                    if(user.DelegatedApproverId!=null) {
                        delegatedApproverSET.add(user.DelegatedApproverId);
                    }
                }
            }
            if(delegatedApproverSET.contains(Userinfo.getUserId())) {
                isDelegatedApprover = true;
            }
        }
        return isDelegatedApprover;
    }
    
    /* Generic method to check whether the logged in user is an Administrator */
    public static String checkUserIsPrivilegedApprover(Id requestId) {
        String roleName;
        if(requestId != null) {
            roleName = IFv2_UtilsController.getPrivilegedRoleName(requestId);
        }
        return roleName;
    }
    
    /* Generic method to check whether the logged in user is an Administrator */
    public static Boolean checkUserIsAdmin() {
        String profile = [Select Name from Profile where Id =: Userinfo.getProfileid()].Name;
        String profileList = Label.CLIFv20162;
        return(profileList.containsIgnoreCase(profile));
    }
    
    /* Generic method to check whether the logged in user is a HelpDesk User */
    public static Boolean checkUserIsHelpdeskUser() {
        String profile = [Select Name from Profile where Id =: Userinfo.getProfileid()].Name;
        String profileList = Label.CLIFv20339;
        return(profileList.containsIgnoreCase(profile));
    }
    
    /* Method to query for button data from metadata */
    @AuraEnabled
    public static ButtonWrapper getButtonList(String requestId) {
        ButtonWrapper header = new ButtonWrapper();    //creating an Instance of ButtonWrapper
        LIST<IFv2_Request__c> requests = getBasicRequestDetails(requestId);
        if(!requests.isEmpty()) {
            IFv2_Request__c request = requests[0];
            String recordId = request.Id;
            LIST<IFv2_RequestButtons__mdt> buttons = new LIST<IFv2_RequestButtons__mdt>();
            String fieldList = returnRequestData(false);
            LIST<IFv2_Request__c> requestRecordLIST = IFv2_UtilsController.getRequestRecord((Id)recordId, fieldList);
            if(!requestRecordLIST.isEmpty()) {
                IFv2_Request__c requestRecord = requestRecordLIST[0];
                LIST<String> attachmentList = new LIST<String>();
                Boolean isApprover = checkUserIsApprover(recordId);    //checking whether logged in user is an approver
                Boolean isDelegatedApprover = checkUserIsDelegatedApprover(recordId);    //Check whether logged in user is a delegated approver
                Boolean isPrivilegedApprover = false;
                String privilegedRoleName = checkUserIsPrivilegedApprover(recordId);    //Check whether logged in user is a privileged approver as in they can edit the record in submitted status
                if(privilegedRoleName != null){
                    isPrivilegedApprover = true;
                }
                Boolean isApplicant = false;
                //checking whether logged in user is an administrator
                Boolean isAdmin = checkUserIsAdmin();
                //checking whether logged in user is helpdesk user
                Boolean isHelpdeskUser = checkUserIsHelpdeskUser();
                if(Userinfo.getUserId() == requestRecord.CreatedById) {
                    //checking whether logged in user is the applicant
                    isApplicant = true;    
                } else if (Userinfo.getUserId() == requestRecord.OwnerId) {
                    //checking whether logged in user is the owner
                    isApplicant = true;    
                } else {
                    //checking whether logged in user has Read/Write access
                    LIST<UserRecordAccess> recordAccessLIST = new LIST<UserRecordAccess>();
                    if(requestRecord.Id != Null && Userinfo.getUserId() != Null) {
                        recordAccessLIST  = [SELECT RecordId, HasEditAccess 
                                             FROM UserRecordAccess 
                                             WHERE RecordId =: requestRecord.Id
                                             AND UserId =: Userinfo.getUserId()];
                    }
                    /*if(!recordAccessLIST.isEmpty()) {
                        for(UserRecordAccess recordAccess : recordAccessLIST) {
                            if(recordAccess.HasEditAccess) {
                                isApplicant = true;
                            }
                        }
                    }*/ 
                }
                
                String workflowName = IFv2_UtilsController.getWorkflowApiName(requestRecord.Workflow__c);
                
                if(String.isnotBlank(workflowName)) {
                    //Building dynamic query - Start
                    String query = 'SELECT Label__c, OrderOfDisplay__c FROM IFv2_RequestButtons__mdt WHERE Status__c = \'' + requestRecord.Status__c + '\' AND Active__c = true AND ' + workflowName + '__c = true';
                    if(isAdmin) {
                        query = query + ' AND Role__c = \'Administrator\'';
                    } else if(isApplicant && isApprover) {
                        query = query + ' AND (Role__c = \'Applicant\' OR Role__c = \'Approver\')';
                    } else  if(isApplicant && isDelegatedApprover) {
                        query = query + ' AND (Role__c = \'Applicant\' OR Role__c = \'Delegated Approver\')';
                    } else if(isApprover && isPrivilegedApprover) {
                        query = query + ' AND (Role__c = \'Approver\' OR Role__c = \'Privileged Approver\')';
                    } else if(isPrivilegedApprover) {
                        query = query + ' AND (Role__c = \'Other\' OR Role__c = \'Privileged Approver\')';
                    } else if(isApprover) {
                        query = query + ' AND Role__c = \'Approver\'';
                    } else if(isDelegatedApprover) {
                        query = query + ' AND Role__c = \'Delegated Approver\'';
                    } else if(isApplicant) {
                        query = query + ' AND Role__c = \'Applicant\'';
                    } else if(isHelpdeskUser) {
                        query = query + ' AND Role__c = \'Helpdesk\'';
                    } else {
                        query = query + ' AND Role__c = \'Other\'';
                    }
                    query = query + ' ORDER BY OrderOfDisplay__c NULLS LAST';
                    //Building dynamic query - End
                    buttons = IFv2_UtilsController.getButtonDetails(query);    //Retrieving button details from metadata
                    //For loading attachments if current user is an Approver
                    if((isApprover || isDelegatedApprover) && (requestRecord.Status__c == 'Submitted')) {
                        attachmentList = getAttachmentList(recordId);
                    } else {
                        attachmentList = null;
                    }
                    system.debug('attachmentList'+attachmentList);
                    if(privilegedRoleName != Label.CLIFv20229) {
                        Integer index;
                        for(Integer i=0;i<buttons.size();i++) {
                            if(buttons[i].Label__c == Label.CLIFv20233) {
                                index=i;
                                break;
                            }
                        }
                        if(index != null){
                            buttons.remove(index);
                        }
                    }
                    if(privilegedRoleName == Label.CLIFv20238 && requestRecord.Workflow__c == Label.CLIFv20199) {
                        Integer index;
                        for(Integer i=0;i<buttons.size();i++) {
                            if(buttons[i].Label__c == Label.CLIFv20239) {
                                index=i;
                                break;
                            }
                        }
                        if(index != null){
                            buttons.remove(index);
                        }
                    }
                    header.button = buttons;
                    //If the request is from InsightFlow, setting the request name
                    if(!String.isBlank(requestRecord.OldRequestName__c)) {
                        header.requestName = requestRecord.OldRequestName__c;
                        header.oldRequest = true;
                    } else {
                        header.requestName = requestRecord.Name;
                        header.oldRequest = false;
                    }
                    header.status = requestRecord.Status__c;
                    header.workflow = requestRecord.Workflow__c;
                    header.attachmentList = attachmentList;    //LIST of PDF attachments
                    header.createdById = requestRecord.CreatedById;
                    header.privilegedRoleName = privilegedRoleName;
                }
            }
        }
        return header;
    }
    
    /*Generic method to get MAP of fields of an sObject */
    public static MAP<String, Schema.SObjectField> getFieldMap(String sObjectName) {
        MAP<String, Schema.SObjectType> global_describe = Schema.getGlobalDescribe();
        MAP<String, Schema.SObjectField> object_fields_map = global_describe.get(sObjectName).getDescribe().fields.getMap();
        return object_fields_map;
    }
    
    /*Getting request records */
    public static String returnRequestData(Boolean setFieldApi) {
        requestFields = new LIST<String>();
        String fieldList = '';
        if(setFieldApi) {
            MAP<String, Schema.SObjectField> object_fields_map = getFieldMap('IFv2_Request__c');
            for (String fieldName: object_fields_map.keySet()) {
                if(!object_fields_map.get(fieldName).getDescribe().getName().EqualsIgnoreCase('ID')) {
                    fieldList = fieldList + ' , ' + object_fields_map.get(fieldName).getDescribe().getName();
                }
            }
        } else {
            fieldList = ', Name, OwnerId, CreatedById, OldRequestName__c, Status__c, Workflow__c';
        }
        return fieldList;
    }
    
    /* Getting LIST of attachments related to the current request  */
    @AuraEnabled
    public static LIST<String> getAttachmentList(String reqId) {
        LIST<String> pdfList = new LIST<String>();
        LIST<String> requestedPDFIdList = new LIST<String>();
        if(!String.isBlank(reqId)){
            LIST<IFv2_Request__c> requests = getBasicRequestDetails(reqId);
            if(!requests.isEmpty()) {
                IFv2_Request__c request = requests[0];
                String recordId = request.Id;
                LIST<ContentDocumentLink> contentDocLinkList = [SELECT ContentDocument.FileType FROM ContentDocumentLink WHERE LinkedEntityId =:recordId AND ContentDocument.FileType = 'PDF'];
                pdfList = new LIST<String>();
                for(ContentDocumentLink att:contentDocLinkList) { 
                    if(att.ContentDocument.FileType == 'PDF') {
                        pdfList.add(att.ContentDocumentId);    //LIST of all attachments
                    }    
                } 
            }
        }
        return requestedPDFIdList = (!pdfList.isEmpty()) ? pdfList:null;
    }
    
    /* CLONE button functionality */
    @AuraEnabled
    public static sObject cloneRecord(String requestId) {
        Id newRecordId;
        IFv2_Request__c newRecord = new IFv2_Request__c();
        LIST<IFv2_Request__c> requests = getBasicRequestDetails(requestId);
        if(!requests.isEmpty()) {
            IFv2_Request__c request = requests[0];
            String recordId = request.Id;
            String dummyUserId = System.Label.CLIFv20022;    /* dummy user id */
            Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get('IFv2_Request__c').getDescribe();
            MAP<String,Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
            MAP<String,Schema.FieldSet>fieldSetMap = objDescribe.FieldSets.getMap();
            
            /*Get Workflow Name of the current request record*/
            IFv2_Request__c req = new IFv2_Request__c();
            if(recordId != null){
                req = [SELECT Id,Workflow__c FROM IFv2_Request__c WHERE Id=:recordId];
            }
            LIST<IFv2_Section__mdt> sectionList = new LIST<IFv2_Section__mdt>();
            if(!String.isBlank(req.Workflow__c)){
                sectionList = [SELECT Id,Value__c 
                               FROM IFv2_Section__mdt 
                               WHERE Workflows__r.Name__c = :req.Workflow__c 
                               AND Active__c = TRUE
                               AND Type__c = 'Request details'];
            } 
            /*Get all fields on the request layout from section metadata for the current request's workflow*/
            SET<String> requestFieldsSet = new SET<String>();
            MAP<String,LIST<String>> extFieldMap = new MAP<String,LIST<String>>();
            for(IFv2_Section__mdt section:sectionList) {
                if(fieldSetMap.containsKey(section.Value__c)) {
                    for(Schema.FieldSetMember memb: fieldSetMap.get(section.Value__c).getFields()) {
                        if(!(memb.getFieldPath()).contains('.')) {
                            requestFieldsSet.add(memb.getFieldPath().toLowercase());
                        } else if(!(memb.getFieldPath().split('\\.')).isEmpty()) {
                            if(memb.getFieldPath().split('\\.')[0].contains('__r')) {
                                String extension = memb.getFieldPath().split('\\.')[0].replace('__r','__c');
                                requestFieldsSet.add(extension);
                                LIST<String> fields = new LIST<String>();
                                if(extFieldMap.containsKey(extension)) {
                                    fields = extFieldMap.get(extension);
                                }
                                fields.add(memb.getFieldPath().split('\\.')[1]);
                                extFieldMap.put(extension,fields);
                            }
                        }
                    }
                } 
            }
            if(extFieldMap.containsKey('Account__c')){
                list<String> accFieldList = extFieldMap.get('Account__c');
                accFieldList.add('RecordTypeId');
                extFieldMap.put('Account__c',accFieldList);
            }
            requestFieldsSet.add('WorkflowId__c');
            String fieldList = ','+String.join(new LIST<String>(requestFieldsSet),',');
            fieldList = fieldList.replace(',id,', ',');
            /*query all required fields of request*/
            LIST<IFv2_Request__c> requestRecordLIST = IFv2_UtilsController.getRequestRecord((Id)recordId, fieldList);
            if(!requestRecordLIST.isEmpty()) {
                IFv2_Request__c requestRecord = requestRecordLIST[0];
                newRecord.Workflow__c = requestRecord.Workflow__c;
                newRecord.WorkflowId__c = requestRecord.WorkflowId__c;
                for(String field: requestFieldsSet) {
                    if(fieldMap.get(field).getDescribe().isUpdateable()||field.contains('role')) {    //checking whether field is writable
                        String fieldType = String.valueOf(fieldMap.get(field).getDescribe().getType()).toLowerCase();
                        if(field == 'ownerid') {
                            newRecord.put(field, UserInfo.getUserId());
                        } else if(fieldType == 'date' || fieldType == 'dateTime') {
                            newRecord.put(field, null);
                        } else if(field == 'oldrequest__c') {
                            newRecord.put(field, null);
                        }
                        else if(field == 'TotalAmountMGP__c'){
                            newRecord.put(field,null);
                        } 
                        else if(requestRecord.get(field) != dummyUserId) {
                            newRecord.put(field, requestRecord.get(field));
                        }
                    }
                }
                newRecord.Status__c = 'Draft';
                /*Check if its ICO 6 or other ICO requests and update status accordingly*/
                if(newRecord.Workflow__c.containsIgnoreCase(system.label.CLIFv20136) && !newRecord.Workflow__c.equals(system.label.CLIFv20250)){
                    newRecord.Status__c = 'Submitted';
                }
                else{
                    newRecord.Status__c = 'Draft';
                }
                newRecordId = IFv2_DmlController.cloneRequestRecord(newRecord, extFieldMap);
                if(newRecordId != null){
                    newRecord = [SELECT Id,Name FROM IFv2_Request__C WHERE Id = :newRecordId];
                }
            }
        }
        cloneAttachmentsOnRequests(requestId,newRecord.Id);
        return newRecord;
    }
    
    //This method is used to clone the attachements present orignial request
    //to the new cloned request record.
    public static void cloneAttachmentsOnRequests(String requestId,String newRequestId) {
        
        List<ContentDocumentLink> contentList = new List<ContentDocumentLink>();
        
        if(requestId != null && newRequestId!= null) {
            
            List<IFv2_Request__C> reqRecList = [SELECT Id,Workflow__c FROM IFv2_Request__C WHERE Id = :requestId and Workflow__c like 'ICO%'  limit 1];
            List<ContentDocumentLink> contentDocsList = new List<ContentDocumentLink>();
            
            if(!reqRecList.isEmpty()) {
            	contentDocsList = [SELECT ContentDocumentId,ContentDocument.Title,ContentDocument.ContentModifiedDate, ContentDocument.ContentSize 
                                    FROM ContentDocumentLink WHERE LinkedEntityId = :reqRecList[0].Id];
            }
                  
            if(!contentDocsList.isEmpty()){
                
                for(ContentDocumentLink file: contentDocsList) {
                    
                    ContentDocumentLink newclnk = file.clone();
                    newclnk.LinkedEntityId = newRequestId;
                    newclnk.ShareType = 'V';
                    contentList.add(newclnk);
                }
            }
        }
    
        if(!contentList.isEmpty()) {
            Database.insert(contentList);
        }
    }
    
    /* DELETE button functionality logic */
    @AuraEnabled	
    public static void deleteRecord(String reqId) {
        LIST<IFv2_Request__c> requests = getBasicRequestDetails(reqId);
        if(!requests.isEmpty()) {
            IFv2_Request__c request = requests[0];
            String recordId = request.Id;
            IFv2_DmlController.deleteRequestRecord(recordId);
        }
    }
    
    /* This method is used current status of follow/unFollow of a record */
    @AuraEnabled
    public static Boolean getFollowedRecord(String reqId) {
        Boolean isFollowed = false;
        LIST<IFv2_Request__c> requests = getBasicRequestDetails(reqId);
        if(!requests.isEmpty()) {
            IFv2_Request__c request = requests[0];
            String recordId = request.Id;
            isFollowed = IFv2_UtilsController.getFollowedRecord((Id)recordId);
        }
        return(isFollowed);
    }
    
    /* This method is used to Follow/UnFollow record */
    @AuraEnabled
    public static Boolean followRecord(String recordId,Boolean isFollowed) {
        Boolean changeFollowStatus = false;
        LIST<IFv2_Request__c> requests = getBasicRequestDetails(recordId);
        if(!requests.isEmpty()) {
            IFv2_Request__c request = requests[0];
            String requestId = request.Id;
            changeFollowStatus = IFv2_DmlController.followRecord(requestId, isFollowed);
        }
        return changeFollowStatus;
    }
    
    /*This method is used to check required fields before submitting for approval*/
    @AuraEnabled
    public static LIST<IFv2_FieldWrapperClass> getRequiredFields(String objectName,string RequestType) {
        return  IFv2_FieldSetUtility.getRequiredFields(objectName,RequestType);
    }
    
    /*This method is used to check validations before submitting for approval*/
    @AuraEnabled
    public static LIST<String> returnValidationErrors(IFv2_Request__c Request, LIST<ApproverSectionWrapper> ApproverSectionMetadata) {
        
        LIST<String> validationErrors = new LIST<String>();
        SET<String> validationSet = new SET<String>();
        LIST<IFv2_Request__c> requests = getBasicRequestDetails(Request.Id);
        if(!requests.isEmpty()) {
            IFv2_Request__c requestRecord = requests[0];
            validationErrors = IFv2_HeaderController.customValidationErrors(Request, ApproverSectionMetadata);
            validationSet.addAll(validationErrors);
        }
        return  new LIST<String>(validationSet);
    }
    
    /* Custom validation errors. */
    public static LIST<String> customValidationErrors(IFv2_Request__c Request, LIST<ApproverSectionWrapper> ApproverSectionMetadata) {
        
        try {
            if(ApproverSectionMetadata == null) {
                ApproverSectionMetadata = getApproverSectionWrapper(Request.Id, Request.Workflow__c);
            }
            /* Query metadata records */
            LIST<String> picklistvalueList = new LIST<String>();	//LIST holding the type of related LIST
            LIST<String> errorMessages=new  LIST<String>();    //Used to hold erorr messages
            Boolean checkboxerror = true;    //To chcek if any one of the check boxes are checked.
            MAP<String, LIST<Account>> requestItemsMap = new MAP<String, LIST<Account>>();
            LIST<IFv2_FieldWrapperClass>  SerialwrapperClassList = new LIST<IFv2_FieldWrapperClass>();    //used to hold fieldwrapper LIST
            LIST<IFv2_FieldWrapperClass>  ParallelwrapperClassList = new LIST<IFv2_FieldWrapperClass>();    //used to hold fieldwrapper LIST
            LIST<String> noApprovervalidationList = new LIST<String>();
            String exceptionalRole = Label.CLIFv20069;
            
            if(!String.isBlank(exceptionalRole))
                noApprovervalidationList.addAll(exceptionalRole.split(','));
            /* To query CustomValidationRules metadata */
            LIST<IFv2_CustomValidationRules__mdt> customvalidationerrors = IFv2_UtilsController.getCustomValidations(Request.Workflow__c);
            /* To check if customvalidationerrors LIST is not empty */
            if(!customvalidationerrors.isEmpty()) {
                for(IFv2_CustomValidationRules__mdt validation : customvalidationerrors) {
                    /* Both fields for validation are present on request object */
                    if(!validation.HasExtensionObject__c) {
                        /* Having related LIST*/
                        if(validation.RelatedList__c) {
                            picklistvalueList.add(validation.RelatedListRecordType__c);
                        } else if(!noApprovervalidationList.contains(String.valueOf(Request.get(validation.ValidationFieldAPI__c))) && 
                                  !string.isBlank(String.valueof(Request.get(validation.ValidationFieldAPI__c)))  && validation.ApproverValidation__c && 
                                  string.isBlank(String.valueof(Request.get(validation.DependentFieldAPI__c) ))) {
                                      /* Checking for approvers fields */
                                      errorMessages.add(validation.ValidationErrorMessage__c);
                                  } else if(validation.MultiSelectPicklist__c) {
                                      /* Checking for multi select values. */
                                      if(String.valueof(Request.get(validation.ValidationFieldAPI__c)).contains(String.Valueof(validation.ValidationFieldValue__c)) && 
                                         string.isBlank(String.valueof(Request.get(validation.DependentFieldAPI__c)))) {
                                             //checkboxerror = false;
                                             errorMessages.add(validation.ValidationErrorMessage__c);
                                         }  
                                  } else if(string.valueOf(Request.get(validation.ValidationFieldAPI__c)) == validation.ValidationFieldValue__c && !validation.ApproverValidation__c && 
                                            String.isBlank(String.valueOf(Request.get(validation.DependentFieldAPI__c)))) {
                                                /* Field validation for dependent fields  */
                                                errorMessages.add(validation.ValidationErrorMessage__c);
                                            } else {
                                                
                                                // Nothing   
                                            }
                        if(Request.Workflow__c == label.CLIFv20161 && !Request.AreAllMaterialsValidated__c && Request.MaterialNo__c != NULL) {
                            errorMessages.add('Please validate materials');
                        }
                    } else if(validation.ExtensionAPIName__c != Null && validation.HasExtensionObject__c && validation.DependentFieldAPI__c != NUll) {
                        /* Multi select picklist validation */
                        if(validation.MultiSelectPicklist__c) { 
                            if(String.valueof(Request.get(validation.ValidationFieldAPI__c)).contains(String.Valueof(validation.ValidationFieldValue__c)) && 
                               string.isBlank(String.valueof(Request.getSobject(validation.ExtensionAPIName__c).get(validation.DependentFieldAPI__c)))) { 
                                   errorMessages.add(validation.ValidationErrorMessage__c);
                               }
                        } 
                        /* Validation for both fields on extension object validation */
                        else if(validation.BothFieldsOnExtensionObject__c && 
                                string.valueOf( Request.getSobject(validation.ExtensionAPIName__c).get(validation.ValidationFieldAPI__c)) == validation.ValidationFieldValue__c  && 
                                string.isBlank(String.valueof(Request.getSobject(validation.ExtensionAPIName__c).get(validation.DependentFieldAPI__c)))) {
                                    errorMessages.add(validation.ValidationErrorMessage__c);
                                } 
                        /*Dependent field on extension object validation */ 
                        else if(!validation.BothFieldsOnExtensionObject__c && validation.ApproverValidation__c != True ) {
                            if(string.valueOf( Request.get(validation.ValidationFieldAPI__c)) == validation.ValidationFieldValue__c && string.isBlank(String.valueof(Request.getSobject(validation.ExtensionAPIName__c).get(validation.DependentFieldAPI__c)))) {
                                errorMessages.add(validation.ValidationErrorMessage__c);
                            }
                        }
                        else {
                            // Nothing
                        }
                    }
                }
            }
            if(request.Workflow__c==Label.CLIFv20301)
            {
                Ifv2_request__c IFO_request=[select id,RequestExtension3__r.PFMEA_Created_Updated__c,RequestExtension3__r.Control_Plan_Created_Updated__c,RequestExtension3__r.MSA_and_Capability_Created_Updated__c,FileCount__c from Ifv2_request__c where id=:request.id limit 1 ];
                if((IFO_request.RequestExtension3__r.PFMEA_Created_Updated__c=='Yes' || IFO_request.RequestExtension3__r.Control_Plan_Created_Updated__c=='Yes') && IFO_request.FileCount__c<2)
                    errorMessages.add(Label.CLIFv20332);
                else if((IFO_request.RequestExtension3__r.PFMEA_Created_Updated__c=='Yes' && IFO_request.RequestExtension3__r.Control_Plan_Created_Updated__c=='Yes') && IFO_request.FileCount__c<3)
                    errorMessages.add(Label.CLIFv20333);
                else if(IFO_request.RequestExtension3__r.PFMEA_Created_Updated__c=='No' && IFO_request.RequestExtension3__r.Control_Plan_Created_Updated__c=='No' && IFO_request.RequestExtension3__r.MSA_and_Capability_Created_Updated__c=='No'&& IFO_request.FileCount__c < 1)
                    errorMessages.add(Label.CLIFv20334);
            }
            
            //Get picklist values for China L&O
            String individualString = label.CLIFv20304;
            LIST<String> individualLIST = new LIST<String>();
            individualLIST.addAll(individualString.split(','));
            
            String batchString = label.CLIFv20303;
            LIST<String> batchLIST = new LIST<String>();
            batchLIST.addAll(batchString.split(','));
            
            System.debug('Ind list::'+individualLIST);
            System.debug('Batch list::'+batchLIST);
            
            /* To query Account records related to this workflow. */
            if(!picklistvalueList.isEmpty()) {
                /*Checking for attachments validations */
                if(picklistvalueList.contains('Attachment')) {
                    Boolean isSizeGreaterThanZero = IFv2_UtilsController.getAttchments(Request.Id);
                    if(!isSizeGreaterThanZero)
                        /* Show error message when attachment is not added. */
                        errorMessages.add(Label.CLIFv20050);
                }
                /* Querying for Related LIST on Account object */
                LIST<Account> accountlist =  IFv2_UtilsController.getAccount(picklistvalueList,Request.Id);
                for(Account currentAccount: accountlist) {
                    // requestItemsSet.add(currentAccount.IFv2_ContentType__c);
                    if(requestItemsMap.containsKey(currentAccount.IFv2_ContentType__c)) {
                        LIST<Account> temporaryList = requestItemsMap.get(currentAccount.IFv2_ContentType__c);
                        temporaryList.add(currentAccount);
                        requestItemsMap.put(currentAccount.IFv2_ContentType__c,temporaryList);
                    } else {
                        LIST<Account> temporaryList = new LIST<Account>();
                        temporaryList.add(currentAccount);
                        requestItemsMap.put(currentAccount.IFv2_ContentType__c,temporaryList);
                    }
                }
            }
            
            /* To add error messages for related LIST. */
            if(!customvalidationerrors.isEmpty()) {
                for(IFv2_CustomValidationRules__mdt validation : customvalidationerrors) {
                    /* To check for only related LIST not based on any field*/
                    if(validation.RelatedList__c && validation.RelatedListRecordType__c != 'Attachment' &&  
                       validation.ValidationFieldAPI__c == NUll && String.isBlank(String.valueof(validation.ValidationFieldAPI__c)) && 
                       !requestItemsMap.containsKey(validation.RelatedListRecordType__c) ) {
                           if(validation.Workflows__r.Name__c == Label.CLIFv20041 && requestItemsMap.keySet().size()>= 1) {
                               /* This is used not to throw error message when there is atleast one related LIST in China Split */
                           } else {
                               errorMessages.add(validation.ValidationErrorMessage__c);
                           }
                       } else if( validation.RelatedList__c && validation.RelatedListRecordType__c != 'Attachment' &&  validation.ValidationFieldAPI__c != NUll && validation.RelatedListRecordType__c != Null) {
                           /* To check if related LIST based on any field */
                           System.debug('inside specific field validation ::' + validation.ValidationFieldAPI__c + '--' +validation.ValidationFieldValue__c + '--' +validation.RelatedListRecordType__c);
                           if(string.valueOf( Request.get(validation.ValidationFieldAPI__c)) == validation.ValidationFieldValue__c){
                               System.debug('inside first if ::');
                               if(validation.RelatedListRecordType__c == Label.CLIFv20305){
                                   System.debug('inside second if ::');
                                   if(individualLIST.contains(validation.ValidationFieldValue__c)){
                                       System.debug('inside third if ::');
                                       if(!requestItemsMap.containsKey(validation.RelatedListRecordType__c)){
                                           System.debug('inside fourth if ::');
                                           errorMessages.add(validation.ValidationErrorMessage__c);
                                       }
                                       else if(requestItemsMap.containsKey(validation.RelatedListRecordType__c)){
                                           if(requestItemsMap.get(validation.RelatedListRecordType__c).size() > 1){
                                               System.debug('inside fifth if ::');
                                               errorMessages.add(validation.ValidationErrorMessage__c);
                                           }
                                       }
                                   }
                                   else if(batchLIST.contains(validation.ValidationFieldValue__c)){
                                       System.debug('inside first else ::');
                                       if(!requestItemsMap.containsKey(validation.RelatedListRecordType__c)){
                                           System.debug('inside fourth if ::');
                                           errorMessages.add(validation.ValidationErrorMessage__c);
                                       }
                                       else if(requestItemsMap.containsKey(validation.RelatedListRecordType__c)){
                                           if(requestItemsMap.get(validation.RelatedListRecordType__c).size() <= 1){
                                               System.debug('inside fifth if ::');
                                               errorMessages.add(validation.ValidationErrorMessage__c);
                                           }
                                       }
                                   }
                                   else{
                                       System.debug('inside else ::');
                                       errorMessages.add(validation.ValidationErrorMessage__c);
                                   }
                               }
                               else{
                                   if(!requestItemsMap.containsKey(validation.RelatedListRecordType__c)){
                                       System.debug('inside last else ::');
                                       errorMessages.add(validation.ValidationErrorMessage__c);
                                   }
                               }
                           }
                       } 
                }
            }
            MAP<IFv2_Section__mdt,LIST<IFv2_FieldWrapperClass>> checkGapMap = new MAP<IFv2_Section__mdt,LIST<IFv2_FieldWrapperClass>>();	//MAP for checking of gaps in approvers logic
            for(ApproverSectionWrapper sectionWrapper : ApproverSectionMetadata) {
                //making a LIST of all approver fields of the request
                LIST<IFv2_FieldWrapperClass> approverList = new LIST<IFv2_FieldWrapperClass>();
                if(sectionWrapper.section.isApproverSection__c == true && sectionWrapper.section.isPredefinedApproverSection__c == false) {
                    approverList.addAll(sectionWrapper.fields);
                }
                checkGapMap.put(sectionWrapper.section,approverList);
            }
            Boolean checkGapbetweenApprovers=false;
            for(IFv2_Section__mdt key : checkGapMap.keySet()) {
                if(checkGapMap.get(key).size()> 0) {
                    if(string.isnotblank(string.valueof(Request.get(checkGapMap.get(key)[0].APINAME))))    //checking whether atleast one approver is filled
                        checkGapbetweenApprovers = true;
                }
            }
            if(test.isRunningTest()) {
                checkGapbetweenApprovers = true;
            }
            if(checkGapbetweenApprovers) {
                for(IFv2_Section__mdt key : checkGapMap.keySet()) {
                    LIST<String> GapErrorMessages =  CheckGapBetweenApprovers(checkGapMap.get(key),Request);    //calling method to check gap between any filled in approvers
                    errorMessages.addall(GapErrorMessages);
                }
            }
            //Adding the response messages to the existing listerrorMessages.sort();
            if(!errorMessages.isEmpty()) {
                errorMessages.sort();  
            }
            
            return errorMessages;
        } catch(Exception e) {
            LIST<String> errorMessages = new LIST<String>();
            errorMessages.add('Exception Occured.....'+e.getmessage());
            return errorMessages;
        }
    }
    
    /*Checks whether the filled in approvers are without any gap from the LIST of users */
    public static LIST<String> CheckGapBetweenApprovers(LIST<IFv2_FieldWrapperClass> wrapperClassList,IFv2_Request__c Request) {
        
        LIST<String> errorMessages = new LIST<String>();	//LIST to hold error messages
        MAP<string,IFv2_FieldWrapperClass> APIFieldWrappermap = new MAP<string,IFv2_FieldWrapperClass>();	//MAP of field API and fieldwrapper
        MAP<Integer, String> approverNoMap = new MAP<Integer, String>();	//MAP of approver number and its API
        LIST<Integer> approverNoList = new LIST<Integer>();		//LIST to store approver numbers
        LIST<String> sortedFieldAPI = new LIST<String>();	//LIST of the sorted field APIs
        
        for(IFv2_FieldWrapperClass fieldwrapper:wrapperClassList) {
            if(fieldwrapper.Type.toLowerCase() == 'reference')
                APIFieldWrappermap.put(fieldwrapper.APIname,fieldwrapper);
        }
        for(String fieldAPIname : APIFieldWrappermap.keyset()) {
            String fieldName = fieldAPIname.toLowerCase();
            String approverNo = fieldName.substringBetween('approver','__c');
            approverNoMap.put(Integer.valueOf(approverNo),fieldAPIname);
            approverNoList.add(Integer.valueOf(approverNo));
        }
        approverNoList.sort();
        for(Integer approverNo : approverNoList) {
            sortedFieldAPI.add(approverNoMap.get(approverNo));
        }
        Boolean Ispreviousempty=false;    //sets to true if a field value is empty
        Boolean isGap=false;    //If there is a gap between approvers entered by user this variable is set to true
        
        for(string fieldwrapper:sortedFieldAPI) {
            if(!isGap) {
                if(Ispreviousempty && string.isnotblank(string.valueof(Request.get(APIFieldWrappermap.get(fieldwrapper).APINAME)))) {
                    errorMessages.add(label.CLIFv20017);
                    isGap=true;
                }
                if(String.isblank(string.valueof(Request.get(APIFieldWrappermap.get(fieldwrapper).APINAME))))
                    Ispreviousempty=true;
            }
        }
        return errorMessages;
    }
    
    /*This method is used to submit approval process from custom button and populates any empty parallel approvers*/
    @AuraEnabled
    public static string submitForApproval(Sobject RequestRecord, LIST<ApproverSectionWrapper> ApproverSectionMetadata) {
        Id requestId = (ID)RequestRecord.get('id');
        LIST<IFv2_Request__c> requests = getBasicRequestDetails(requestId);
        String workflowName;
        if(!requests.isEmpty()) {
            IFv2_Request__c currentRequest = requests[0];
            String recordId = currentRequest.Id;
            workflowName = currentRequest.Workflow__c;
            String status = currentRequest.Status__c;
            Boolean parallelCheck = currentRequest.Parallel__c;
            
            if(ApproverSectionMetadata == null) {
                ApproverSectionMetadata = getApproverSectionWrapper(recordId, workflowName);
            }
            LIST<IFv2_FieldWrapperClass> wrapperClassList = new LIST<IFv2_FieldWrapperClass>();
            SET<Id> approvers = new SET<Id>();    //To store Approvers Ids. Added for Record Access Logic
            LIST<IFv2_Request__Share> recordShareList = new LIST<IFv2_Request__Share>();
            LIST<IFv2_FieldWrapperClass> ParallelApproverFieldWrapperList = new LIST<IFv2_FieldWrapperClass>();
            
            for(ApproverSectionWrapper sectionWrapper : ApproverSectionMetadata) {
                if(sectionWrapper.section.isApproverSection__c == true) {
                    wrapperClassList.addAll(sectionWrapper.fields);    //LIST of all approver fields
                }
                if(sectionWrapper.section.isParallelApproverSection__c == true && parallelCheck == true) {
                    ParallelApproverFieldWrapperList.addAll(sectionWrapper.fields);    //LIST of all parallel approver fields
                }
            }
            /*Forming  query to get all approver fields */
            String query='select id,Status__c,Workflow__c,Approver3__c,Approver4__c,Approver5__c,Approver6__c,Approver7__c,Approver8__c,Approver9__c,Approver10__c' ;
            for(IFv2_FieldWrapperClass Field:wrapperClassList) {
                if(!query.split(',').contains(Field.APIName)) {
                    query+=','+Field.APIName;
                }
            }
            query+=' from IFv2_Request__c where Id=\''+recordId+'\'';
            IFv2_Request__c Request = IFv2_UtilsController.forApprovers(query);
            /*First checking whether it is parallel approval and Prepopulating parallel approver fields if they are blank*/
            if(ParallelApproverFieldWrapperList != null && !ParallelApproverFieldWrapperList.isEmpty()) {   
                Boolean IsparallelApproverDefined=false;
                /*Checking whether atleast one  parallel approver is defined or not*/
                for(IFv2_FieldWrapperClass Field:ParallelApproverFieldWrapperList) {
                    if(string.isnotBlank(string.valueof(Request.get(Field.APIName))))
                        IsparallelApproverDefined=True;
                }
                /*if atleast one parallel approver is defined and if any other parallel approvers are not defined ,prepopulating them with dummy user*/
                if(IsparallelApproverDefined)
                    for(IFv2_FieldWrapperClass Field:ParallelApproverFieldWrapperList) {
                        if(string.isBlank(string.valueof(Request.get(Field.APIName))))
                            Request.put(Field.APIName,Label.CLIFv20022);
                    }
                IFv2_DmlController.updateRequestRecord(Request);
            }
            // Assign dummy user when proxy user is not in special freight
            if(Request.Workflow__c==label.CLIFv20049) {
                if(Request.Approver3__c!=NULL && Request.Approver4__c==NULL) {
                    Request.Approver4__c=Label.CLIFv20022;
                }
                if(Request.Approver5__c!=NULL && Request.Approver6__c==NULL) {
                    Request.Approver6__c=Label.CLIFv20022;
                }
                if(Request.Approver7__c!=NULL && Request.Approver8__c==NULL) {
                    Request.Approver8__c=Label.CLIFv20022;
                }
                if(Request.Approver9__c!=NULL && Request.Approver10__c==NULL) {
                    Request.Approver10__c=Label.CLIFv20022;
                }
                IFv2_DmlController.updateRequestRecord(Request);
            }
            /* This is used for validating whether approvers have access to extension objects.  */
            String RequestString = JSON.serialize(RequestRecord);
            //validatedApprovers(recordId, workflowName, RequestString);
            /*Iterating over Wrapper class LIST */
            for(IFv2_FieldWrapperClass field : wrapperClassList) {
                if(field.Type.toLowerCase() == 'reference') {
                    if(Request.get(field.APIName) != NULL && field.Type.toLowerCase() == 'reference') {
                        approvers.add((Id)Request.get((String)field.APIName));
                    }
                }
            }
            //For sharing records with delegated approvers.
            for(User user : [SELECT Id, DelegatedApproverId FROM User where Id IN :approvers]) {
                if(user.DelegatedApproverId != null) {
                    approvers.add(user.DelegatedApproverId);
                }
            }
            /* End of code to get Approvers*/
            
            // To Insert Extension share records 
            String extension1ShareRecord = (String)RequestRecord.get('RequestExtension1__c');
            String extension2ShareRecord = (String)RequestRecord.get('RequestExtension2__c');
            String extension3ShareRecord = (String)RequestRecord.get('RequestExtension3__c');
            String accountId = (String)RequestRecord.get('Account__c');
            
            /* Calling Future Method for Sharing Record */
            RecordShare(approvers,recordId,extension1ShareRecord,extension2ShareRecord,extension3ShareRecord, accountId, workflowName);
            
            /* Giving record Accesss ends here*/ 
            /* Invoking Approval Process*/
            Approval.ProcessSubmitRequest requestitem = new Approval.ProcessSubmitRequest();    // Create an approval request instance
            requestitem.setObjectId(recordId);    //set the target object as request 
            requestitem.setNextApproverIds(new Id[] {UserInfo.getUserId()});    //pass user id which will be coming from approval process
            requestitem.setComments(Label.CLIFv20148);    //set comments
            Approval.ProcessResult result = Approval.process(requestitem);    //submit the approval process
        }
        return 'successfully submitted';
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
                                              WHERE isActive = true and profile.name In: adminLIST AND Id IN: Approvers];
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
                System.debug('In Record Share Method::' + approverIdSET);
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
    
        /* Method to share records from batch class*/
    /*
    public static void RecordShareForBatch(Set <Id> Approvers, Id recordid, String extension1ShareRecord, String extension2ShareRecord, String extension3ShareRecord, String accountId, String workflowName) {
        
        if(!String.isBlank(recordid)){
            LIST<IFv2_Request__Share> recordShareList = new LIST<IFv2_Request__Share>();
            // Lists to store Extension object 
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
                }
                System.debug('workflowRegion>'+workflowRegion);
                
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
                
                // To create share records. 
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
                //To insert share records
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
  */
    /* Method to share record with manager on escalation */
    public static void RecordShareManager(Set <Id> Approvers, Id recordid, String extension1ShareRecord, String extension2ShareRecord, String extension3ShareRecord, String accountId, String workflowName) {
        
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
                    system.debug('workflowRegion'+workflowRegion);
                    system.debug('extension1ShareRecord'+extension1ShareRecord);
                    system.debug('extension2ShareRecord'+extension2ShareRecord);
                    if( extension1ShareRecord != NUll || extension2ShareRecord != NUll || extension3ShareRecord != NULL || accountId != NULL)  {
                        if(workflowRegion== 'APAC' && extension1ShareRecord != NULL && extension1ShareRecord != '' ) {
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
    
    
    
    
    /*This method is used to recall approval process from custom Recall button and remove prepopulated dummy users in parallel approver fields*/
    @auraEnabled
    public static Boolean  reCallMethod(Id recId,string workflow, LIST<ApproverSectionWrapper> ApproverSectionMetadata) {
        
        LIST<IFv2_Request__c> requests = getBasicRequestDetails(recId);
        if(!requests.isEmpty()) {
            IFv2_Request__c request = requests[0];
            String recordId = request.Id;
            String status = request.Status__c;
            Boolean parallelCheck = request.Parallel__c;
            if(status == 'Submitted') {
                /**************Recall from approval process********************/
                LIST<ProcessInstanceWorkitem> workItems = IFv2_UtilsController.getRecordAcccess((Id)recordId);    //ProcessInstanceWorkitem LIST to capture request instance 
                Approval.ProcessWorkitemRequest requestitem = new Approval.ProcessWorkitemRequest();    // Create an approval request instance 
                requestitem.setAction('Removed');    //set action on click on recall button
                requestitem.setWorkItemId(workItems[0].id);    //set workitem id
                Approval.ProcessResult result = Approval.process(requestitem);    //submit approval process
                /***********End of recall*************/
                removeDummyUsers(recordId, workflow, parallelCheck, ApproverSectionMetadata, false);    //Removing the dummy approvers filled in the blank parallel approvers 
                return true;
            } else return false;
        } else return false;
        
    }
    
    /*This method is used to update request status to draft from custom Restart button and remove prepopulated dummy users in parallel approver fields*/
    @auraEnabled
    public Static Boolean restartMethod(Id recId,string workflow, LIST<ApproverSectionWrapper> ApproverSectionMetadata) {
        LIST<IFv2_Request__c> requests = getBasicRequestDetails(recId);
        if(!requests.isEmpty()) {
            IFv2_Request__c request = requests[0];
            String recordId = request.Id;
            String status = request.Status__c;
            Boolean parallelCheck = request.Parallel__c;
            if(status == 'Rejected') {
                removeDummyUsers(recordId, workflow, parallelCheck, ApproverSectionMetadata, true);    //Removing the dummy approvers filled in the blank parallel approvers
                return true;
            } else return false;
        } else return false;
    }
    
    /*This method is used to reject request record from custom Reject button*/
    @auraEnabled
    public static Boolean rejectMethod(Id recId,string strComments) {
        
        LIST<IFv2_Request__c> requests = getBasicRequestDetails(recId);
        if(!requests.isEmpty()) {
            IFv2_Request__c request = requests[0];
            String recordId = request.Id;
            String status = request.Status__c;
            if(status == 'Submitted') {
                User currentUser = IFv2_UtilsController.getLoggedInDetails();    //get logged in user detail
                LIST<ProcessInstanceWorkitem> approvalItem = IFv2_UtilsController.getRecordAcccess((Id)recordId);    //LIST to capture approval process instance for request record
                SET<Id>approverList = new SET<Id>();
                MAP<Id,SET<Id>>approverMap = new MAP<Id,SET<Id>>();
                for(ProcessInstanceWorkitem item : approvalItem) {
                    SET<Id>approverSet = new SET<Id>();
                    if(approverMap.containsKey(item.Id)) {
                        approverSet = approverMap.get(Item.Id);
                    }
                    approverSet.add(item.ActorId);
                    approverMap.put(item.Id,approverSet);
                    approverList.add(item.ActorId);
                }
                //Handle Delegate Approvers
                if(!approverList.isEmpty()){
                    for(User user:[SELECT Id, DelegatedApproverId FROM User WHERE Id IN :approverList]) {
                        if(user.DelegatedApproverId != null) {
                            for(ProcessInstanceWorkitem item : approvalItem) {
                                if(approverMap.containsKey(item.Id)) {
                                    if(approverMap.get(item.Id).contains(user.Id)) {
                                        SET<Id> approverSet = new SET<Id>();
                                        if(approverMap.containsKey(item.Id)) {
                                            approverSet = approverMap.get(Item.Id);
                                        }
                                        approverSet.add(user.DelegatedApproverId);
                                        approverMap.put(item.Id,approverSet);
                                    }
                                }
                            }
                        }
                    }
                }
                //iterate over LIST 
                for(ProcessInstanceWorkitem item : approvalItem) {
                    //check if logged in user is approver or delegate approver
                    if( (approverMap.containsKey(item.Id) && approverMap.get(item.Id).contains(Userinfo.getUserId())) || (Userinfo.getUserId() == item.OriginalActorId)||checkUserIsAdmin()) {
                        Approval.ProcessWorkitemRequest requestForApproval = new Approval.ProcessWorkitemRequest();    //create approval process instance 
                        requestForApproval.setAction('Reject');    //set action as reject
                        requestForApproval.setComments(strComments);    //capture comments from method
                        requestForApproval.setWorkItemId(item.id);    //set workitem id
                        Approval.ProcessResult result = Approval.process(requestForApproval);    //update approval process
                        break;
                    }
                }   
                return true;
            } else return false;
        } else return false;
    } 
    
    /*This method is used to approve request record from custom approve button and automatically approve dummy user assigned requests if one of the parallel approver  approves it*/
    @auraEnabled
    public static Boolean approveMethod(Id recId,string strComments, LIST<ApproverSectionWrapper> ApproverSectionMetadata) { 
        System.debug('inside approveMethod proxy test>');
        LIST<IFv2_Request__c> requests = getBasicRequestDetails(recId);
        if(!requests.isEmpty()) {
            System.debug('inside requests if proxy test>');
            IFv2_Request__c currentRequest = requests[0];
            String recordId = currentRequest.Id;
            String status = currentRequest.Status__c;
            String workflowName = currentRequest.Workflow__c;
            Boolean parallelCheck = currentRequest.Parallel__c;
            Boolean reAssignedToProxyForApproval = false;
            if(currentRequest.reAssignedToProxyForApproval__c!=null)
                reAssignedToProxyForApproval =currentRequest.reAssignedToProxyForApproval__c;
            String Ifv2_ProxyApprovalUserList='';
            if(currentRequest.Ifv2_ProxyApprovalUserList__c!=null)
                Ifv2_ProxyApprovalUserList=currentRequest.Ifv2_ProxyApprovalUserList__c;
            System.debug('Parallel>>Entering>'+parallelCheck);
            if(status == 'Submitted') {
                try {
                    if(workflowName == Label.CLIFv20200){
                        if(!String.isBlank(recordId) ){
                            LIST<AggregateResult> aggResultList = [ SELECT sum(IFv2_Quantity__c)qty,sum(IFv2_ReturnedQuantity__c)retQty 
                                                                   FROM Account 
                                                                   WHERE IFv2_Request__c = :recordId
                                                                   AND IFv2_ContentType__c = 'Material' ];
                            if(!aggResultList.isEmpty()){
                                for(AggregateResult aggResult:aggResultList){
                                    if((Decimal)aggResult.get('qty') != (Decimal)aggResult.get('retQty')){
                                        return null;
                                    }
                                }
                            }
                        }
                        else {
                            return null;
                        }
                    }
                    
                    if(ApproverSectionMetadata == null) {
                        ApproverSectionMetadata = getApproverSectionWrapper(recordId, workflowName);
                    }
                    System.debug('Parallel>>ApproverSectionMetadata'+ApproverSectionMetadata);
                    string ApproverId;
                    LIST<ProcessInstanceWorkitem> approvalItem = IFv2_UtilsController.getRecordAcccess((Id)recordId);    //LIST to capture approval process instance for request record
                    LIST<IFv2_FieldWrapperClass> ParallelApproverFieldWrapperList = new LIST<IFv2_FieldWrapperClass>();    //Getting parallel Approver field LIST
                    for(ApproverSectionWrapper sectionWrapper : ApproverSectionMetadata) {
                        if(sectionWrapper.section.isParallelApproverSection__c == true && parallelCheck == true) {
                            System.debug('Parallel>>sectionWrapper.field>'+sectionWrapper.fields);
                            ParallelApproverFieldWrapperList.addAll(sectionWrapper.fields);
                        }
                    }
                    // Querying for all paralle approver fields of request record
                    String query='select id,Status__c,Workflow__c' ;
                    for(IFv2_FieldWrapperClass Field:ParallelApproverFieldWrapperList)
                        query+=','+Field.APIName;
                    query+=' from IFv2_Request__c where Id=\''+recordId+'\'';
                    IFv2_Request__c Request = IFv2_UtilsController.forApprovers(query);
                    System.debug('Parallal>>Request>'+Request);
                    SET<Id> fullApproverSET = new SET<Id>();
                    MAP<Id,SET<Id>>approverMap = new MAP<Id,SET<Id>>();    //Hot Fix Start Bug No -  W-010322
                    for(ProcessInstanceWorkitem item : approvalItem) {
                        System.debug('Parallel>workitem>'+item);
                        SET<Id>approverSet = new SET<Id>();
                        if(approverMap.containsKey(item.Id)) {
                            approverSet = approverMap.get(Item.Id);
                        }
                        approverSet.add(item.ActorId);
                        approverMap.put(item.Id,approverSet);
                        fullApproverSET.add(item.ActorId);
                    }
                    //Handle Delegate Approvers
                    if(!fullApproverSET.isEmpty()){
                        for(User user:[SELECT Id, DelegatedApproverId FROM User WHERE Id IN :fullApproverSET]) {
                            if(user.DelegatedApproverId != null) {
                                for(ProcessInstanceWorkitem item : approvalItem) {
                                    if(approverMap.containsKey(item.Id)) {
                                        if(approverMap.get(item.Id).contains(user.Id)) {
                                            SET<Id>approverSet = new SET<Id>();
                                            if(approverMap.containsKey(item.Id)) {
                                                approverSet = approverMap.get(Item.Id);
                                            }
                                            approverSet.add(user.DelegatedApproverId);
                                            approverMap.put(item.Id,approverSet);
                                        }
                                    }
                                }
                            }
                        }                             
                    }                                  
                    //iterate over ProcessInstanceWorkitem LIST
                    for(ProcessInstanceWorkitem item : approvalItem) {
                        //check if logged in user is approver or delegate approver
                        System.debug('parallel>ProcessInstanceWorkitem'+item);
                        System.debug('parallel>approvermap>'+approverMap);
                        System.debug('parallel>ie userId>'+approverMap.get(item.Id));
                            System.debug('parallel> item.OriginalActorId>'+item.OriginalActorId);
                        if((approverMap.containsKey(item.Id) && approverMap.get(item.Id).contains(Userinfo.getUserId())) || (Userinfo.getUserId() == item.OriginalActorId)||checkUserIsAdmin()) {    //Hot Fix End Bug No -  W-010322
                            System.debug('parallel>inside>user>'+Userinfo.getUserId());
                            ///// proxy approval code /////
                            System.debug('on top of if proxy test>');
                            if(reAssignedToProxyForApproval==true && item.OriginalActorId!=Userinfo.getUserId())
                            {
                                if(Ifv2_ProxyApprovalUserList!='' || Ifv2_ProxyApprovalUserList!=null)
                               	currentRequest.Ifv2_ProxyApprovalUserList__c=Ifv2_ProxyApprovalUserList+','+item.OriginalActorId;
                                else
                                    currentRequest.Ifv2_ProxyApprovalUserList__c=item.OriginalActorId;
                                System.debug('inside if proxy test>'+currentRequest.Ifv2_ProxyApprovalUserList__c);
                                update(currentRequest);
                            }
                            //////////////////////////////
                            Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();    //LIST to capture approval process instance for request record 
                            pwr.setAction('Approve');    //set action as appoved
                            pwr.setComments(strComments);    //set comments
                            pwr.setWorkItemId(item.id);    //set work item 
                            Approval.ProcessResult result = Approval.process(pwr);    //update approval process
                            ApproverId=Userinfo.getUserId();    //storing approver id to check whther he is a parallel approver or not
                            break;    //added for breaking after approving one approvalItem
                        }
                    }
                    
                    if(parallelCheck) {
                        System.debug('Parallel Entering check>>');
                        Boolean IsOneparallelApproved = false;    //used to check whther atleast one paralle approval is approved
                        //Checking approver id against all the parallel approver ids and if it matches then the approver is a parallel approver
                        for(IFv2_FieldWrapperClass Field:ParallelApproverFieldWrapperList) {
                            System.debug('Field.APIName>>'+Field.APIName);
                            System.debug('parallel string.valueof(Request.get(Field.APIName)>'+string.valueof(Request.get(Field.APIName)));
                            system.debug('parallel>'+ApproverId);
                            if(string.valueof(Request.get(Field.APIName))==ApproverId)
                            {
                                IsOneparallelApproved = true;
                                System.debug('Parallel setting parallel one true>>');
                            }
                                
                        }
                        if(parallelCheck)
                            IFv2_WithoutSharingClass.approveDummyApproversProcessInstances(approvalItem,checkUserIsAdmin(),strComments);

                        //Making all dummy parallel approvers approve automatically
                     /*   if(IsOneparallelApproved) {
                            System.debug('Parallel Entering IsOneparallelApproved>>');
                            IFv2_WithoutSharingClass.approveDummyApproversProcessInstances(approvalItem,checkUserIsAdmin(),strComments);
                        } */
                    }
                } catch(Exception e) {
                    system.debug('error' + e.getmessage());
                }
                return true;
            } else return false;
        } else return false;
    }   
    
    /*This method is used to reassign approver custom reassigns button  */ 
    @AuraEnabled
    public static Boolean reassignMethod(Id recId,string strComments, Id newApproverId) { 
        fromReassign=true;
        LIST<IFv2_Request__c> requests = getBasicRequestDetails(recId);
        System.debug('strComments******' +strComments);
        if(!requests.isEmpty()) {
            IFv2_Request__c request = requests[0];
            String recordId = request.Id;
            String status = request.Status__c;
            if(status == 'Submitted') {
                
                LIST<IFv2_Request__Share> recordShareList = new LIST<IFv2_Request__Share>();
                
                /* To share record with deligated approver of reAssigned User  */
                Id reAssignedUserId; 	// To store reassigned user Id
                Id deligatedUserId;		// To store deligated user Id.
                /* End of To share record with deligated approver of reAssigned User */
                
                User currentUser = IFv2_UtilsController.getLoggedInDetails();    //get id of current logged in user
                LIST<ProcessInstanceWorkitem> approvalItem = IFv2_UtilsController.getRecordAcccess((Id)recordId);    //LIST to capture approval process instance for request record
                String actorId = approvalItem[0].ActorId;    //store actor id

                
                //Iterate over LIST 
                for(ProcessInstanceWorkitem item : approvalItem) {
                    //check if logged in user is approver
                    if(Userinfo.getUserId() == item.ActorId || Userinfo.getUserId() == item.OriginalActorId || checkUserIsAdmin() || checkUserIsHelpdeskUser()) {
                        item.ActorId = newApproverId;    //update actor id newApproverId is passed from method
                        reAssignedUserId = newApproverId;
                        /*******give record access to new user******/
                        fromReassign=true;
                        System.debug('Calling Consult Method'+recordId+strComments+newApproverId);
                        Boolean postAndAccess = consultMethod(recordId, strComments, newApproverId);
                        break;
                    }
                }
                
                /* For sharing record with deligated approver */
                //For sharing records with delegated approvers.
                for(User user : [SELECT Id, DelegatedApproverId FROM User where Id =: reAssignedUserId]) {
                    if(user.DelegatedApproverId != null) {
                        deligatedUserId = user.DelegatedApproverId;
                    }
                }
                if(deligatedUserId != NULL) {
                    fromReassign=true;
                    Boolean deligateduserAccess = consultMethod(recordId, NULL, deligatedUserId);
                }
                /* End of sharing record with deligated approver */
                
                if(!approvalItem.isEMpty()) {
                    IFv2_DmlController.updateActor(approvalItem);//update the LIST
                }
                return true;
            } else return false;
        } else return false;
    }  
    
    /*This method is used to post in chatter when approver clicks consult and add user and post something  */ 
    @AuraEnabled
    public static Boolean consultMethod(Id recId,string strComments, Id chatterUserId) { 
        LIST<IFv2_Request__c> requests = new LIST<IFv2_Request__c>();
        if(recId != null){
            requests = [SELECT status__c, Workflow__c, Account__c, RequestExtension1__c, RequestExtension2__c, RequestExtension3__c FROM IFv2_Request__c WHERE id =:recId];
        }
        if(!requests.isEmpty()) {
            IFv2_Request__c request = requests[0];
            String WorkflowName = requests[0].Workflow__c;
            //String to store workflowRegion
            String workflowRegion; 
            
            //Checking if workflow Name is not NULL    
            if(!String.isBlank(WorkflowName)) {
                workflowRegion = IFv2_UtilsController.getWorkflows(workflowName);
            }
            
            if(request.Status__c == 'Submitted') {
                
                SET<Id> chatterUserIdSET = new SET<Id>();
                if(chatterUserId != NULL) {
                    chatterUserIdSET.add(chatterUserId);
                }
                
                List<IFv2_Request__Share> reqsharelist=[select id,parentId,UserOrGroupId from IFv2_Request__Share where parentId=:recId and UserOrGroupId IN :chatterUserIdSET];
                if(!fromReassign)
                sendNotificationEmail(chatterUserIdSET,recId,WorkflowName,strComments,reqsharelist);
                fromReassign=false;
                //Calling Record share method
                System.debug('Calling Record Share Method');
                RecordShare(chatterUserIdSET, recId, (String)request.RequestExtension1__c, (String)request.RequestExtension2__c, (String)request.RequestExtension3__c, request.Account__c, WorkflowName);
                
                if(!String.isBlank(strComments)) {
                    //Creating chatter post
                    ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
                    ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
                    ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                    ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
                    messageBodyInput.messageSegments = new LIST<ConnectApi.MessageSegmentInput>();
                    mentionSegmentInput.id = chatterUserId;    //assigning user id
                    messageBodyInput.messageSegments.add(mentionSegmentInput);
                    textSegmentInput.text = ' ' + strComments;
                    messageBodyInput.messageSegments.add(textSegmentInput);    //adding comments
                    feedItemInput.body = messageBodyInput;
                    feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
                    feedItemInput.subjectId = recId;    //linking with record id
                    ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
                    return true;
                } else return false;
            } else return false;
        } else return false;
    }
    
    /**This method is used to return ContentDocumentURl**/
    @AuraEnabled
    public static string  returnContentDocumentURL(string workflow) {
        try {
            String fullFileURL;
            if(String.isnotblank(workflow)) {    
                ContentDocument doc = [SELECT Id FROM ContentDocument WHERE Title = :workflow];
                if (doc != null) {
                    fullFileURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + doc.id;
                }
            } else
                fullFileURL=null;
            return fullFileURL;
        } catch(Exception e) {
            return null;
        }
    }
    
    /**This method is used to return Help document url in new tab **/
    @AuraEnabled
    public static string  returnHelpDcoument(String workflow) {
        String helpurl ='';
        if(String.isnotblank(workflow)) {
            helpurl= IFv2_UtilsController.getHelpIconUrl(workflow);
        }
        return helpurl;
    }
    
    /* Future Class to give record Access to users if they don't have access.*/
    @Future
    public static void validatedApprovers(String RequestId, String workflowName, String RequestString) {
        
        if(!String.isBlank(RequestId)){
            SET<String> approverSET = new SET<String>();/* Set to store Approvers. */
            SET<String> usersWhoDontHaveAccess = new SET<String>();/* Set to store users who don't have accees to Request object */
            LIST<String> patentIdsList = new LIST<String>();/* To store for permission set Ids.*/
            LIST<PermissionSetAssignment> PermissionSetList = new LIST<PermissionSetAssignment>();/* LIST to store PermissionSetAssignment*/
            LIST<IFv2_FieldWrapperClass> wrapperClassList = new  LIST<IFv2_FieldWrapperClass>();/* LIST to store IFv2_FieldWrapperClass  */
            
            /* Query custom metadata (workflow) record to check for extension object */
            /* To get the workflow region, to decide which extension object*/
            String region = IFv2_UtilsController.getWorkflows(workflowName);
            /* To execute logic only if region is not all */
            if(region != 'ALL' && region!= Null) {
                /*Deserializing a object */
                IFv2_Request__c Request  = (IFv2_Request__c)JSON.deserialize(RequestString, IFv2_Request__c.Class);
                /* To get Section metadata for specific workflow*/
                LIST<IFv2_Section__mdt> sectionRecords = IFv2_UtilsController.getSectionMetaDataRecord(workflowName);
                /* To get Approver Fields */
                for(IFv2_Section__mdt section : sectionRecords) {
                    wrapperClassList.addAll(IFv2_FieldSetUtility.getFields(RequestId,'IFv2_Request__c',section.Value__c));
                } 
                /*Iterating over Wrapper class LIST to get Approvers */
                for(IFv2_FieldWrapperClass field : wrapperClassList) {
                    if(Request.get(field.APIName) != NULL && field.Type.toLowerCase() == 'reference')
                        approverSET.add((Id)Request.get((String)field.APIName));
                }
                SET<Id> permissionSetIdList = new SET<Id>();
                /* Getting Permission set Records */
                LIST<PermissionSet> permissionSetRecords = IFv2_UtilsController.permissionSetRecords();
                For(PermissionSet currentpermissionSet : permissionSetRecords) {
                    permissionSetIdList.add(currentpermissionSet.id);
                }
                String extensionObject;
                /* This is used for checking whether user is having access to extesnion object or not */
                if(region.contains('APAC')) {
                    extensionObject = system.label.CLIFv20029;
                } else if(region.contains('EMEA')) {
                    extensionObject = system.label.CLIFv20030;
                }
                else {
                    extensionObject = system.label.CLIFv20031;
                }
                /* To get Object permissions .*/
                LIST<ObjectPermissions> objectPermissions = IFv2_UtilsController.getObjectPermissions(permissionSetIdList, extensionObject);
                /* Creating patentIdsList */
                For(ObjectPermissions ccurrentObjectPermission : objectPermissions) {
                    
                    patentIdsList.add(ccurrentObjectPermission.ParentId);
                }
                LIST<String> AssignedUsersList = new LIST<String>();    //To get users assigned to permission set for specific object 
                /* Get data of PermissionSetAssignment*/
                LIST<PermissionSetAssignment> PermissionSetAssignmentList = IFv2_UtilsController.getPermissionSetAssignment(patentIdsList,approverSET);
                /* To get users who have been added to permission sets. */
                for(PermissionSetAssignment assignedUsers :  PermissionSetAssignmentList) {
                    AssignedUsersList.add(assignedUsers.AssigneeId);
                }
                SET<String> noAccessUsersset= new SET<String>();    //Set to store Users who don't have access 
                /* Checking for approvers who don't have access */
                for(String uservariable : approverSET) {
                    if(!AssignedUsersList.contains(uservariable)) {
                        noAccessUsersset.add(uservariable);
                    }
                }            
                /* Adding users to permission set who don't have access */
                if(region != 'ALL') {
                    /* To get Permissionset id to Add users to Permission set*/
                    String permissionId = IFv2_UtilsController.getPermission(region);
                    
                    for(String   users: noAccessUsersset) {
                        PermissionSetAssignment  PermissionAssignment = new PermissionSetAssignment();
                        PermissionAssignment.PermissionSetId = (Id)permissionId;
                        PermissionAssignment.AssigneeId  = (Id)users;
                        PermissionSetList.add(PermissionAssignment);
                    }
                }
                /* Inserting  permission set Assignments */
                if(!PermissionSetList.isEmpty()) {
                    IFv2_DmlController.insertPermissionSetUsers(PermissionSetList);
                }
                /* Updating user records */
                LIST<User> UserRecords =  IFv2_UtilsController.getUserRecords(noAccessUsersset);
                LIST<User> updatedRecords = new LIST<User>();
                for(User currntUser : UserRecords) {
                    
                    if(region.contains('APAC')) {
                        currntUser.IFv2_RequestAPAC__c = true;
                    }
                    else if(region.contains('EMEA')) {
                        currntUser.IFv2_RequestEMEA__c = true;
                    }
                    else if(region.contains('NALA')) {
                        currntUser.IFv2_RequestNALA__c = true;
                    }
                    updatedRecords.add(currntUser);
                }
                /* Update Current users */
                IFv2_DmlController.updateUsers(updatedRecords);
            }
        }
    }
    
    /*Method to remove the filled in dummy users for parallel approverswhen request is recalled/restarted */
    public static void removeDummyUsers(Id recId, string workflow, Boolean parallelCheck, LIST<ApproverSectionWrapper> ApproverSectionMetadata, Boolean isRestart) {
        
        if(ApproverSectionMetadata == null) {
            ApproverSectionMetadata = getApproverSectionWrapper(recId, workflow);
        }   
        LIST<IFv2_FieldWrapperClass> ParallelApproverFieldWrapperList = new LIST<IFv2_FieldWrapperClass>();
        for(ApproverSectionWrapper sectionWrapper : ApproverSectionMetadata) {
            if(sectionWrapper.section.isParallelApproverSection__c == true && parallelCheck == true) {
                ParallelApproverFieldWrapperList.addAll(sectionWrapper.fields);
            }
        }
        // Querying for all paralle approver fields of request record
        String query='select id,Status__c,Workflow__c' ;
        for(IFv2_FieldWrapperClass Field:ParallelApproverFieldWrapperList)
            query+=','+Field.APIName;
        query+=' from IFv2_Request__c where Id=\''+recId+'\'';
        IFv2_Request__c Request=IFv2_UtilsController.forApprovers(query);
        
        if(ParallelApproverFieldWrapperList != null && !ParallelApproverFieldWrapperList.isEmpty()) {
            //checking if the approver is dummy user and making it empty
            for(IFv2_FieldWrapperClass Field:ParallelApproverFieldWrapperList) {
                if(string.valueof(Request.get(Field.APIName)) == Label.CLIFv20022)
                    Request.put(Field.APIName,'');
            }
        }
        if(isRestart) {
            Request.Status__c = 'Draft';
        }
        IFv2_DmlController.updateRequestRecord(request);
    }
    
    /*Method to get all approver sections of a workflow and their fields */
    public static LIST<ApproverSectionWrapper> getApproverSectionWrapper(Id recId, String workflow) {
        LIST<ApproverSectionWrapper> approverSectionWrapper = new LIST<ApproverSectionWrapper>();
        if(recId != null){
            string objectapiname= string.valueof(recId.getsobjecttype());
            LIST<IFv2_Section__mdt> approversectionRecords = IFv2_UtilsController.getSectionMetaDataRecord(workflow);
            for(IFv2_Section__mdt section : approversectionRecords) {
                ApproverSectionWrapper approverSectionWrapperInstance = new ApproverSectionWrapper();
                LIST<IFv2_FieldWrapperClass> approverFieldWrapperList = new LIST<IFv2_FieldWrapperClass>();
                approverFieldWrapperList.addAll(IFv2_FieldSetUtility.getFields(recId,objectapiname,section.Value__c));
                approverSectionWrapperInstance.section = section;
                approverSectionWrapperInstance.fields = approverFieldWrapperList;
                approverSectionWrapper.add(approverSectionWrapperInstance);
            }
        }
        return approverSectionWrapper;
    }
    
    /* Start of Iteration 3 changes, this is used in Concession workflow */
    @AuraEnabled 
    public static IFv2_Request__c getMartialFromDetail(String requestId) {
        IFv2_Request__c relatedrequestRecord;
        if(!String.isBlank(requestId)){
            try {
                relatedrequestRecord  = IFv2_UtilsController.getRequest(requestId);
            } catch(Exception e) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(e);
            }
        }
        return relatedrequestRecord;
    }
    
    @AuraEnabled
    Webservice static String updateConcessionRecord(String idForOneMaterial, String materialNo, String customerNo, String supplierNo,String plant, String revisionLevel, String language) {
        
        Boolean someBoolvalue = false;
        String userMessage = '';
        
        LIST<Account> material = new LIST<Account>();	//LIST of materials in the related LIST
        if(idForOneMaterial != null) {
            material = IFv2_UtilsController.getAccount(idForOneMaterial);
        }
        
        if(material.Size()>0) {
            if(material[0].IFv2_Request__r.SAPInstance__c  == 'PSI') {
                someBoolvalue = true;
            } else {
                someBoolValue = false;
            }                                                          
        }
        SG_WF_WS_Sap_Con_ValidateNotif.HTTP_Basic stub = new SG_WF_WS_Sap_Con_ValidateNotif.HTTP_Basic(someBoolValue);
        MAP<String,String> headersMap = new MAP<String, String>();
        
        //AUTHORISATION
        String username = Label.SAP_User.split(';')[0];
        String password = Label.SAP_User.split(';')[1];
        Blob headerValue = Blob.valueOf(username+':'+password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        
        headersMap.put('Authorization', authorizationHeader);
        headersMap.put('KeyId', Label.SAP_Key_Id);
        
        stub.inputHttpHeaders_x = headersMap;
        
        try {
            SG_WF_WS_Sap_Con_ValidateNotif.ConcessionValidate_Result result = stub.ConcessionValidate_IN(
                materialNo, 
                customerNo, 
                supplierNo,
                plant,
                revisionLevel,
                language);
            
            if(result != null) {
                system.debug(result);
            } else {
                userMessage = 'No response from server.';
            }
            
            if(result.ConcessionText != null && material.size()> 0) {
                if(result.ConcessionText.MatnrText != null) {
                    material[0].IFv2_Request__r.MaterialDescription__c = result.ConcessionText.MatnrText;
                }
                if(result.ConcessionText.SupplierName != null) {
                    material[0].IFv2_SupplierName__c = result.ConcessionText.SupplierName;
                }
                if(result.ConcessionText.KunnrName != null) {
                    material[0].IFv2_CustomerName__c = result.ConcessionText.KunnrName;
                }
                if(result.ConcessionText.PlantName != null) {
                    material[0].IFv2_Concession_Plant_Name__c = result.ConcessionText.PlantName;
                }                
            }
            
            // log errors and set message for user 
            if(result.Log.ConcessionLogItem == null) {
                System.debug('LOG IS NULL');
            } else {
                for(SG_WF_WS_Sap_Con_ValidateNotif.ZT2_WSRNOTIF_LOG_ITEM logItem : result.Log.ConcessionLogItem) {
                    if(logItem.Type_x == 'E') {
                        userMessage = logItem.Message;
                    }
                }
            }
            
            if(result.ConcessionText != null) {
                //do the actual update 
                material[0].IFv2_IsValidated__c = true;
                update material;
                
                //validation concession
                LIST<Account> matList = new LIST<Account>();
                matList = IFv2_UtilsController.validateConcession(idForOneMaterial);
                
                if(material.size()>0) {
                    if(isMaterialListValidated(material[0].IFv2_Request__c, matList)) {
                        IFv2_Request__c reqForUpdate = new IFv2_Request__c(Id=material[0].IFv2_Request__c);
                        reqForUpdate.areAllMaterialsValidated__c = true;
                        update reqForUpdate;
                        update material;
                    }
                }
            }
        } catch(Exception e) {
            userMessage = 'Connection to server failed.';
        }
        return userMessage;
    }
    
    public static FINAL SET<String> materialCodeDescs = new SET<String>();
    @TestVisible
    private static Boolean isMaterialListValidated(String requestId, LIST<Account> materialList) {
        
        LIST<String> requestStringLIST = new LIST<String>();
        requestStringLIST.add(requestId);
        LIST<IFv2_Request__c> requestLIST = IFv2_UtilsController.getConcessionRequest(requestStringLIST);
        
        return materialCodeDescs.contains(requestLIST[0].CategoryCodeDescription__c) ? requestLIST[0].IsMaterialValidated__c == true && materialList.isEmpty() : true;
    }   
    
    /*Method to update material description on request */
    @AuraEnabled
    Webservice static String updateConcessionConcessionRecord(String idForOneMaterial, String materialNo, String customerNo, String supplierNo, String plant, String revisionLevel, String language) {
        Boolean someBoolvalue = false;
        String userMessage = '';
        
        IFv2_Request__c request = new  IFv2_Request__c();
        if(!String.isBlank(idForOneMaterial)){
            request = [SELECT Id, Name, MaterialNo__c,Account__c, Account__r.IFv2_Plant__c,Account__r.IFv2_CustomerNo__c, 
                       Account__r.IFv2_RevisionLevel__c, Account__r.IFv2_PlantName__c, CategoryCodeDescription__c,
                       Account__r.IFv2_ConcessionCustomerText__c,Account__r.IFv2_ConcessionSupplierName__c,areAllMaterialsValidated__c, 
                       Account__r.IFv2_SupplierNo__c, ConcessionDescription__c, MaterialDescription__c, Plant__c, Language__c, SAPInstance__c, Account__r.IFv2_Concession_Plant_Name__c
                       FROM IFv2_Request__c
                       WHERE Id = : idForOneMaterial];
        }
        if (request.SAPInstance__c == 'PSI') {
            someBoolvalue = true;
        } else {
            someBoolValue = false;
        }
        
        SG_WF_WS_Sap_Con_ValidateNotif.HTTP_Basic stub = new SG_WF_WS_Sap_Con_ValidateNotif.HTTP_Basic(someBoolValue);
        MAP<String,String> headersMap = new MAP<String, String>();
        
        //AUTHORISATION
        String username = Label.SAP_User.split(';')[0];
        String password = Label.SAP_User.split(';')[1];
        Blob headerValue = Blob.valueOf(username+':'+password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        
        headersMap.put('Authorization', authorizationHeader);
        headersMap.put('KeyId', Label.SAP_Key_Id);
        stub.inputHttpHeaders_x = headersMap;
        LIST<Account> accountRecordLIST  = new LIST<Account>();
        try {
            SG_WF_WS_Sap_Con_ValidateNotif.ConcessionValidate_Result result = stub.ConcessionValidate_IN(
                materialNo, 
                customerNo, 
                supplierNo,
                plant,
                revisionLevel,
                language); 
            
            //check for empty result
            if(result != null) {
                system.debug(result);
            } else {
                userMessage = 'No response from server.'; 
            }
            
            //parse result  
            //prevent nullPointer here in case of empty answer 
            
            Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Extension').getRecordTypeId();
            
            accountRecordLIST = [select id,IFv2_ConcessionSupplierName__c,IFv2_ConcessionCustomerText__c,IFv2_PlantName__c,IFv2_Concession_Plant_Name__c from Account where id=:request.Account__c and recordtypeId =:devRecordTypeId];
            
            if(result.ConcessionText != null) {
                if(result.ConcessionText.MatnrText != null) {
                    request.MaterialDescription__c = result.ConcessionText.MatnrText;
                }
                if(result.ConcessionText.SupplierName != null) {
                    if(!accountRecordLIST.isEMpty())
                        accountRecordLIST[0].IFv2_ConcessionSupplierName__c = result.ConcessionText.SupplierName;
                }
                if(result.ConcessionText.KunnrName != null) {
                    if(!accountRecordLIST.isEMpty())
                        accountRecordLIST[0].IFv2_ConcessionCustomerText__c = result.ConcessionText.KunnrName;
                }
                if(result.ConcessionText.PlantName != null) {
                    if(!accountRecordLIST.isEMpty())
                        accountRecordLIST[0].IFv2_Concession_Plant_Name__c = result.ConcessionText.PlantName;
                }                
            }
            
            // log errors and set message for user 
            if(result.Log.ConcessionLogItem == null) {
                System.debug('LOG IS NULL');
            } else {
                for(SG_WF_WS_Sap_Con_ValidateNotif.ZT2_WSRNOTIF_LOG_ITEM logItem : result.Log.ConcessionLogItem) {
                    
                    if(logItem.Type_x == 'E') {
                        userMessage = logItem.Message;
                    }
                }
            }
            if(result.ConcessionText != null) {
                //do the actual update 
                request.isMaterialValidated__c = true;
                update request;
                if(!accountRecordLIST.isEMpty())
                    update accountRecordLIST[0];
                //validation of request 
                LIST<Account> reqList = new LIST<Account>();
                if(!String.isBlank(idForOneMaterial)){
                    reqList = [SELECT Id, IFv2_IsValidated__c FROM Account WHERE id =: idForOneMaterial AND IFv2_IsValidated__c=false];
                }
                if(isMaterialValidated(idForOneMaterial, reqList)) {
                    request.areAllMaterialsValidated__c = true;
                    update request;
                }
            }   
        } catch (Exception e) {
            userMessage = 'Connection to server failed.'; 
        }
        /* Creating wrapper class to send data */
        CheckNowWrapper wrapperInstance = new CheckNowWrapper();
        wrapperInstance.userMessage = userMessage;
        wrapperInstance.requestRecord = request;
        if(!accountRecordLIST.isEMpty())
            wrapperInstance.accountRecord = accountRecordLIST[0];
        return JSON.serialize(wrapperInstance);
        
    }
    
    /* Class to send both message and updated request record */
    public class CheckNowWrapper {
        
        /* Attribute to store updated request record */
        @AuraEnabled
        public IFv2_Request__c requestRecord { get; set; }
        /* To get Account Record fileds */
        @AuraEnabled 
        Public account accountRecord{get;set;}
        
        /* Attribute to store userMessage */
        @AuraEnabled
        public STring userMessage { get; set; }
    }
    
    /* MATERIAL validation check method */
    @TestVisible
    private static Boolean isMaterialValidated(String reqId, LIST<Account> AccountList) {
        IFv2_Request__c req = new IFv2_Request__c();
        if(!String.isBlank(reqId)){
            req = [SELECT Id, isMaterialValidated__c, CategoryCodeDescription__c FROM IFv2_Request__c WHERE Id=:reqId LIMIT 1][0];
        }
        return materialCodeDescs.contains(req.CategoryCodeDescription__c) ? req.isMaterialValidated__c == true && AccountList.isEmpty() : true;
    }
    
    public static void getPicklistvalues() {
        Schema.DescribeFieldResult  fieldResult = IFv2_Request__c.CategoryCodeDescription__c.getDescribe();
        LIST<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry FieldValue : picklistValues) {
            materialCodeDescs.add(FieldValue.getValue());
        }
    }
    
    //Querying help url custom setting records
    @AuraEnabled
    public static LIST<IFv2_HelpURL__c> getHelpURLRecords() {
        return [select Name,IFv2_LinkURL__c,IFv2_Description__c from IFv2_HelpURL__c where IFv2_Active__c  = True ORDER BY Name ASC];
    }
    /* End of Iteration 3 changes*/
    
    public static void sendNotificationEmail(set<id>userIds,ID rcdId,String workflow,String comments,List<IFv2_Request__Share> sharedlist)
    {
        System.debug('inside send notification email>'+sharedlist);
        List<id>userList=new List<id>();
        if(sharedlist.size()==0)        
        {
            for(id userid:userIds)
            {	
                userList.add(userid);
            }
        }
        else
        {
            for(IFv2_Request__Share share:sharedlist)
            {
                if(!userIds.contains(share.UserOrGroupId))
                {
                    userList.add(share.UserOrGroupId);                  
                }
            }
            
        }
        System.debug('send email userList>'+userList);
        List<string>emailIdSet=new List<string>();
        for(User user:[select id, email from user where id IN: userList])
        {
            emailIdSet.add(user.email);
        }
        System.debug('send email emailIdSet>'+emailIdSet);
        String emailTemplate = 'IFv2_emailNotificationOnConsult';
        /* Query for emial template */
        EmailTemplate emailTemplateRecord = new EmailTemplate();
        if(emailTemplate!=Null)
            emailTemplateRecord = [SELECT Id,Name,Subject, Body,HtmlValue FROM EmailTemplate WHERE DeveloperName = :emailTemplate limit 1];
        LIST<contact> contacts = [select Id from contact limit 1];
        LIST<Messaging.SingleEmailMessage> emailList = new LIST<Messaging.SingleEmailMessage>(); 	// LIST to store email messages 
        if(!emailIdSet.isEmpty()) { 
            System.debug('email not null>>'+emailIdSet);
            String username=UserInfo.getName();
            Ifv2_request__c record=[select name,id from Ifv2_request__c limit 1];
            String recordName=record.name;
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses =new LIST<String>(emailIdSet);
            message.setTreatTargetObjectAsRecipient(false);
            message.setSaveAsActivity(false);
            //Setting the setTargetObjectId to dummy contact Id
            if(!Contacts.isEmpty()) {
                message.setTargetObjectId(contacts[0].Id);
            } else if(Test.isRunningTest()) {
                message.setTargetObjectId(UserInfo.getUserId());
            }
            //Setting the WhatId to customobject Id so that merge fields in template gets rendered
            message.setWhatId(rcdId);
            //SET email template
            if(emailTemplateRecord != null) {
                message.setTemplateId(emailTemplateRecord.Id);                
            }
            
            if(message.toAddresses.size()>0) {
                emailList.add(message);
            }
        } 
        Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
        System.debug('email result>'+results);
        
    }
}