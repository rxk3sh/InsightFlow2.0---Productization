/*******************************************************************************************************
* 
* @ Name 				:	IFv2_RelatedListsController
* @ Purpose 			: 	displaying the Approval history related lists
* @ Author				: 	Pradeep Chary
* @ Usage			   	: 	Method to fetch the Approval history related list records
* @ Test class name    	:   IFv2_RelatedListsControllerTest
*
*   Date	        |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   12-11-2018      |  pradeep.chary@absyz.com (yv) |  1.0          |  Initial Version
*******************************************************************************************************/

public with sharing class IFv2_RelatedListsController {
    @AuraEnabled
    public Static RelatedList fetchRelatedList(String objectId, String listType){
        
        SObject requestRecord = IFv2_UtilsController.getInsertedRequest(objectId);
        RelatedList relatedListWrapper = new RelatedList();
        if(requestRecord.get('OldRequest__c') != null && requestRecord.get('DisplayApprovalHistory__c') == true) {
            relatedListWrapper.oldRequest = requestRecord.get('OldRequest__c');
			relatedListWrapper.displayApprovalHistory = (Boolean)requestRecord.get('DisplayApprovalHistory__c'); 
            String dummyUserId = System.Label.CLIFv20022;
            String columnLabels = System.Label.CLIFv20034;
            String fieldType = '';
            /* Logged-in user details */
            User userRecord = IFv2_UtilsController.getLoggedInDetails();
            String profileName = '';
            if(userRecord != null) {
                profileName = userRecord.Profile.name;
            }
            
            /* map of labels and its types */
            MAP<String, Schema.DisplayType> labelToTypeMAP = new MAP<String, Schema.DisplayType> ();
            
            /* complete map of Account Object */
            MAP<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.Account.fields.getMap();
            
            /* fetch metadata records for the apiNames and labels of the related list */
            IFv2_Section__mdt relatedListSection = new IFv2_Section__mdt();
            if(listType != null && listType != '') {
                relatedListSection = IFv2_UtilsController.getSectionMetadataRecords(listType);
            }
            String apiMetadataList='';
            String labelsMetadataList='';
            String extendedApiMetadataList='';
            String extendedLabelsMetadataList='';
            
            if(relatedListSection != null && relatedListSection.Value__c != null) {
                apiMetadataList = relatedListSection.Value__c;            
            }
            
            /* storing field types of the columns to be displayed in the data table */
            LIST<String> fields = columnLabels.trim().split(',');    //List of field Names
            for(String field : fields) {
                fieldType = fieldType + ',' + labelToTypeMAP.get(field);
            }
            
            /* Creating object of wrapper and inserting values */
            
            relatedListWrapper.apiNames = apiMetadataList;
            relatedListWrapper.columnLabels = columnLabels;
            relatedListWrapper.fieldType = fieldType;
            relatedListWrapper.userProfile = profileName;
            
            /* fetch records for the related list */
            /* for Approval History Related List */
            if(listType != null && listType == 'ProcessInstance') {
                relatedListWrapper.records = IFv2_UtilsController.getApprovalHistoryRecords(
                    apiMetadataList, listType, objectId, dummyUserId);
            }
        } else if(requestRecord.get('OldRequest__c') != null) {
            relatedListWrapper.oldRequest = requestRecord.get('OldRequest__c');
        } else {
            String dummyUserId = System.Label.CLIFv20022;
            String columnLabels = System.Label.CLIFv20034;
            String fieldType = '';
            /* Logged-in user details */
            User userRecord = IFv2_UtilsController.getLoggedInDetails();
            String profileName = '';
            if(userRecord != null) {
                profileName = userRecord.Profile.name;
            }
            
            /* map of labels and its types */
            MAP<String, Schema.DisplayType> labelToTypeMAP = new MAP<String, Schema.DisplayType> ();
            
            /* complete map of Account Object */
            MAP<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.Account.fields.getMap();
            
            /* fetch metadata records for the apiNames and labels of the related list */
            IFv2_Section__mdt relatedListSection = new IFv2_Section__mdt();
            if(listType != null && listType != '') {
                relatedListSection = IFv2_UtilsController.getSectionMetadataRecords(listType);
            }
            String apiMetadataList='';
            String labelsMetadataList='';
            String extendedApiMetadataList='';
            String extendedLabelsMetadataList='';
            
            if(relatedListSection != null && relatedListSection.Value__c != null) {
                apiMetadataList = relatedListSection.Value__c;            
            }
            
            /* storing field types of the columns to be displayed in the data table */
            LIST<String> fields = columnLabels.trim().split(',');    //List of field Names
            for(String field : fields) {
                fieldType = fieldType + ',' + labelToTypeMAP.get(field);
            }
            
            /* Creating object of wrapper and inserting values */
            
            relatedListWrapper.apiNames = apiMetadataList;
            relatedListWrapper.columnLabels = columnLabels;
            relatedListWrapper.fieldType = fieldType;
            relatedListWrapper.userProfile = profileName;
            
            /* fetch records for the related list */
            /* for Approval History Related List */
            if(listType != null && listType == 'ProcessInstance') {
                relatedListWrapper.records = IFv2_UtilsController.getApprovalHistoryRecords(
                    apiMetadataList, listType, objectId, dummyUserId);
            }  
        }
        return relatedListWrapper;
    }
    
    @AuraEnabled
    public Static RelatedList completeRelatedList(String objectId, String listType) {
        
        String dummyUserId = System.Label.CLIFv20022;
        String extendedListColumnLabels = System.Label.CLIFv20035;
        String fieldType = '';
        
        /* fetch metadata records for the apiNames and labels of the related list */
        IFv2_Section__mdt relatedListSection = new IFv2_Section__mdt();
        if(listType != null && listType != '') {
            relatedListSection = IFv2_UtilsController.getSectionMetadataRecords(listType);
        }
        /* string of Api Names of Approval history fields */
        String apiMetadataList='';
        if(relatedListSection != null && relatedListSection.ExtendedValue__c != null) {
            apiMetadataList = relatedListSection.ExtendedValue__c;   
        }
        
        /* Creating object of wrapper and inserting values */
        RelatedList relatedListWrapper = new RelatedList();
        relatedListWrapper.apiNames = apiMetadataList;
        relatedListWrapper.columnLabels = extendedListColumnLabels;
        
        /* map of labels and its types */
        Map <String, Schema.DisplayType> labelToTypeMAP = new Map <String, Schema.DisplayType> ();
        
        /* storing field types of the columns to be displayed in the data table */
        LIST<String> fieldLIST = extendedListColumnLabels.trim().split(',');
        for(String field : fieldLIST) {
            fieldType = fieldType + ',' + labelToTypeMAP.get(field);
        }
        relatedListWrapper.fieldType = fieldType;
        
        /* fetch records for Approval History Related List */
        if(listType != null && listType == 'ProcessInstance') {
            relatedListWrapper.records = IFv2_UtilsController.getExtendedApprovalHistoryRecords(apiMetadataList, listType, objectId, dummyUserId);
        } 
        return relatedListWrapper;
    }
    
    /* wrapper */
    public class RelatedList {
        @AuraEnabled
        public LIST<SObject> records {
            get;
            set;
        }
        
        /* for apiNames of the fields */
        @AuraEnabled
        public String apiNames {
            get;
            set;
        }
        
        /* for labels of the fields */
        @AuraEnabled
        public String columnLabels {
            get;
            set;
        }
        
        /* for field types */
        @AuraEnabled
        public String fieldType {
            get;
            set;
        }
        
        /* for user profile */
        @AuraEnabled
        public String userProfile {
            get;
            set;
        }
        
        /* for user profile */
        @AuraEnabled
        public Object oldRequest {
            get;
            set;
        }
        
        /* for user profile */
        @AuraEnabled
        public Boolean displayApprovalHistory {
            get;
            set;
        }
    }
}