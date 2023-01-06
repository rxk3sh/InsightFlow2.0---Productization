/*******************************************************************************************************
* 
* @ Name 			: IFv2_ExceptionUtilitiesController
* @ Purpose 		: Utilities class
* @ Author			: Pradeep Chary
* @ Test class name : IFv2_HeaderControllerTest
*
*   Date            |  Developer Name                     |  Version         |  Changes
* ======================================================================================================
*   28-10-2018      |  pradeep.chary@absyz.com			  |  1.0             |  Initial Version 
*******************************************************************************************************/

public with sharing class IFv2_ExceptionUtilitiesController {
    
    public static void exceptionHandler(Exception e) {
        
        Id recordTypeId = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('Error Logs').getRecordTypeId();
       
        if(System.isFuture() || System.isBatch() || System.isScheduled() || System.isQueueable()) {
            if(!String.valueOf(e).contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                IFv2_AdminOnly__c record = new IFv2_AdminOnly__c();
                record.RecordTypeId = recordTypeId;
                record.ErrorType__c = e.getTypeName();
                Id recordId;
                if(e.getTypeName().contains('DmlException')) {
                    record.IFv2_ErrorDescription__c = e.getDmlMessage(0);
                    if(e.getDmlId(0) != null) {
                        recordId = e.getDmlId(0);
                    }
                } else {
                    record.IFv2_ErrorDescription__c = e.getMessage();
                }
                
                /* get the record name if id exists */
                if(recordId != null) {
                    String sObjName = recordId.getSObjectType().getDescribe().getName();
                    String queryString = 'SELECT NAME FROM ' + sObjName + ' WHERE ID =: recordId';
                    SObject recordName = Database.query(queryString);
                }
                
                record.StackTrace__c = e.getStackTraceString();
                
                Database.insert(record);
                
            }
        } else {
            
            Boolean throwAuraException = true;
            LIST<String> classesToAvoidAuraExceptionLIST = new LIST<String>();
            classesToAvoidAuraExceptionLIST = System.Label.CLIFv20245.split(',');
            
            /* Insert logs other than standard validation error */
            if(!String.valueOf(e).contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                IFv2_AdminOnly__c record = new IFv2_AdminOnly__c();
                record.RecordTypeId = recordTypeId;
                record.ErrorType__c = e.getTypeName();
                Id recordId;
                
                if(e.getTypeName().contains('DmlException')) {
                    record.IFv2_ErrorDescription__c = e.getDmlMessage(0);
                    if(e.getDmlId(0) != null) {
                        recordId = e.getDmlId(0);
                    }
                } else {
                    record.IFv2_ErrorDescription__c = e.getMessage();
                }
                /* get the record name if id exists */
                if(recordId != null) {
                    String sObjName = recordId.getSObjectType().getDescribe().getName();
                    String queryString = 'SELECT NAME FROM ' + sObjName + ' WHERE ID =: recordId';
                    SObject recordName = Database.query(queryString);
                } 
                
                record.StackTrace__c = e.getStackTraceString();
                String recordString = JSON.serialize(record);
                
                /* calling future method for record insertion */
                insertExceptionLog(recordString);
            }
            
            for(String iterator: classesToAvoidAuraExceptionLIST) {
                if(e.getStackTraceString().containsIgnoreCase(iterator) || Test.isRunningTest()) {
                    throwAuraException = false;
                }    
            }
            
            if(throwAuraException || Test.isRunningTest()) {
                if(e.getTypeName().contains('DmlException')) {
                    AuraHandledException exc = new AuraHandledException(e.getDmlMessage(0));
                    exc.setMessage(e.getMessage());
                    throw exc;
                } else {
                    AuraHandledException exc = new AuraHandledException(e.getMessage());
                    exc.setMessage(e.getMessage());
                    throw exc;
                }
            } 
        }
    }
    
    @future
    public static void insertExceptionLog(String errorLogString) {
        /* deserialize string to type SObject */
        IFv2_AdminOnly__c errorLogRecord = (IFv2_AdminOnly__c)JSON.deserialize(errorLogString, IFv2_AdminOnly__c.Class);
        Database.insert(errorLogRecord);
    }
    
    public static void batchJobError(AsyncApexJob error) {
        /* Insert logs other than standard validation error */
        IFv2_AdminOnly__c errorLogRecord = new IFv2_AdminOnly__c();
        errorLogRecord.RecordTypeId = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('Error Logs').getRecordTypeId();
        errorLogRecord.IFv2_ErrorDescription__c = error.ExtendedStatus;
        Database.insert(errorLogRecord);
    }
}