/*******************************************************************************************************
* 
* @ Name :IFv2_BackToOfficeOutOfOfficeBatchV2
* @ Purpose : Class that collectss  users who are out of office assigns their requests to delegated approvers
* @ Author: Naga Sai
* @ Test Class Name : IFv2_BackToOfficeOutOfOfficeBatchV2test
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   08-03-2018  |  nagasai.chalamalasetti@absyz.com     |  1.0          |  Initial Version

*******************************************************************************************************/

global class IFv2_BackToOfficeOutOfOfficeBatchV2 implements Database.Batchable<sObject> {
    
    //Global Variables
    SET<Id> outOfOfficeUserIds = new SET<Id>(); 
    LIST<Id> backToOfficeuserIds = new LIST<Id>();
    
    //Querying users who should be considered in reassignment and delegate assignment of approval requests
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String outofofficelogsrecordtypeid = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('OutOfOfficeLogs').getRecordTypeId();
        String   query ='SELECT WorkflowName__c,User__c,createdbyid,Active__c'+
            ' FROM IFv2_AdminOnly__c a WHERE  recordtypeid=:outofofficelogsrecordtypeid  '+ 
            'AND createdbyid not in :outOfOfficeUserIds AND createdbyid not in :backToOfficeuserIds '+
            'AND WorkflowName__c!=Null AND User__c!=Null and ((a.LastModifiedDate = TODAY AND HOUR_IN_DAY(a.LastModifiedDate) > 1) OR Active__c=true)';
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, LIST<IFv2_AdminOnly__c> adminonlyRecords) {
        if(!adminonlyRecords.isEmpty()) {
            String workflow;
            MAP<String,String> delegatedIdworkflownameMap = new MAP<String,String>();
            
            //Iterating and collecting the created by id and delegated id and allso workflow
            for(IFv2_AdminOnly__c admin : adminonlyRecords) {
                //Collecting out of office userids
                if(admin.Active__c) {
                    outOfOfficeUserIds.add(admin.CreatedById);
                    delegatedIdworkflownameMap.put(admin.WorkflowName__c, admin.User__c);
                } else {
                    //collecting back to office user ids
                    backToOfficeuserIds.add(admin.CreatedById);
                    workflow = admin.WorkflowName__c ;
                }
            }
            //Invoking Out of office
            if(!outOfOfficeUserIds.isEmpty()) {
                IFv2_TriggerHandler.TransferApproverToDelegatedUserv1(outOfOfficeUserIds, delegatedIdworkflownameMap);
            }
            //Invoking Back To office
            if(!backToOfficeuserIds.isEmpty()) {
                IFv2_TriggerHandler.AssignRequestsBack(backToOfficeuserIds, workflow);
            }
        }
    }
    
    //Finish method
    global void finish(Database.BatchableContext BC) {
        //do nothing
    }
}