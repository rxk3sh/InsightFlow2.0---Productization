/*******************************************************************************************************
* 
* @ Name :IFv2_BackToOfficeBatch
* @ Purpose : Class that collectss  users who are Back to Office and assigns their requests back.
* @ Author: Hanu Sanampudi
* @ Test Class Name : IFv2_BackToOfficeOutOfOfficeBatchV2test
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   10-09-2019  |  hanumantharao.sanampudi@seg-automotive.com     |  1.0          |  Initial Version

*******************************************************************************************************/

global class IFv2_BackToOfficeBatch implements Database.Batchable<sObject> {
    
    String reassignmentLogId = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('Reassignment Logs').getRecordTypeId();
    LIST<Id> backToOfficeuserIds = new LIST<Id>();	
    
    //Querying users who should be considered in reassignment and delegate assignment of approval requests
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String strQuery = '';
        if(Test.isRunningTest()){
            strQuery ='SELECT Id,Name,ConsiderInReassignmentBatch__c From User Where ConsiderInReassignmentBatch__c=true AND isActive=true AND Out_Of_Office__c =false limit 1';
        } else {
            strQuery ='SELECT Id,Name,ConsiderInReassignmentBatch__c From User Where ConsiderInReassignmentBatch__c=true AND isActive=true AND Out_Of_Office__c =false and id=\'0059E000008KfQ8QAK\'';
        }
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.BatchableContext BC, LIST<User> usersList) {
        
        List<IFv2_AdminOnly__c> adminonlyRecords = new List<IFv2_AdminOnly__c>();
        
        if(!usersList.isEmpty()) {
            if(Test.isRunningTest()) {
                adminonlyRecords = [SELECT WorkflowName__c,User__c,createdbyid,Active__c,OwnerId From IFv2_AdminOnly__c limit 1];
            } else {
                adminonlyRecords = [SELECT WorkflowName__c,User__c,createdbyid,Active__c,OwnerId From IFv2_AdminOnly__c 
                                    Where recordtypeId=:reassignmentLogId AND WorkflowName__c!=Null                                                 
                                    AND User__c!=Null AND OwnerId IN : usersList];
            }
        }
        System.debug('Debug:: check for admin logs ***** Finished'+adminonlyRecords);
        if(!adminonlyRecords.isEmpty()) {
            System.debug('Debug:: adminonlyRecords*****' + adminonlyRecords);
            //Iterating and collecting the created by id and delegated id and allso workflow
            for(IFv2_AdminOnly__c admin : adminonlyRecords) {
                backToOfficeuserIds.add(admin.OwnerId);	
            } 
        }
        
        //Invoking Back To office
        if(!backToOfficeuserIds.isEmpty()) {
            OutOfOfficeAndBackToOfficeHelper.assignRequestsBack(backToOfficeuserIds, null);
        }
    }
    
    //Finish method
    global void finish(Database.BatchableContext BC) {
        //do nothing
    }
}