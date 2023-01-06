/*******************************************************************************************************
* 
* @ Name :IFv2_BackToOfficeOutOfOfficeBatch
* @ Purpose : Class that collects users who are back to office and assigns their approval requests back, 
and also users who are out of office assigns their requests to delegated approvers
* @ Author: Naga Sai
* @ Test Class Name : IFv2_BackToOfficeOutOfOfficeBatchTest
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   02-11-2018  |  nagasai.chalamalasetti@absyz.com     |  1.0          |  Initial Version
*   10-04-2019  |  nagasai.chalamalasetti@absyz.com     |  1.1          |  Added Commenst for collections and used generic
DML operation

*******************************************************************************************************/

global class IFv2_BackToOfficeOutOfOfficeBatch implements Database.Batchable<sObject>{
    
    /*
* Querying users who should be considered in reassignment and delegate assignment of approval requests

*/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        /*** getting all user fields and filtering them by delegate word***/
        //holds Field API names of user object
        LIST<String> userFieldAPINames=new LIST<String>();
        //holds Object metadata details against its API name
        MAP<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        //holds Fields metadata against its field API name 
        MAP<String, Schema.SObjectField> fieldMap = schemaMap.get('user').getDescribe().fields.getMap();
        //Iterating over each field and checking for delegate fields
        for(Schema.SObjectField sfield : fieldMap.Values())
        {
            schema.describefieldresult dfield = sfield.getDescribe();
            if(dfield.getName().containsIgnoreCase('delegate'))
                userFieldAPINames.add(dfield.getName());
        }
        //Forming a dynamic query with necessary fields
        String query='select id,email,ConsiderInReassignmentBatch__c,Out_Of_Office__c,'+String.join( userFieldAPINames, ',' )+ ' from user where   IsActive = true and (ConsiderInReassignmentBatch__c = true or Out_Of_Office__c = true)';
        if(test.isRunningTest())
            query='select id,email,ConsiderInReassignmentBatch__c,Out_Of_Office__c,'+String.join( userFieldAPINames, ',' )+ ' from user where   IsActive = true and (ConsiderInReassignmentBatch__c = true or Out_Of_Office__c = true) limit 1';
        
        return Database.getQueryLocator(query);		
    }
    
    
    global void execute(Database.BatchableContext BC, LIST<sObject> scope) {
        if(!scope.isEmpty()){
            //holds userids who are back to office
            LIST<Id> backToOfficeuserIdList = new LIST<Id>();
            //holds user records who are out of office
            LIST<user> outOfOfficeuserList = new LIST<user>();
            //holds user records who are back to office
            LIST<user> backToOfficeUserList = new LIST<user>();
            // 1. Collecting  back to office user list by ConsiderInReassignmentBatch__c checkbox
            // 2.  collecting out of office user list by Out_Of_Office__c checkbox and Invoking handler
            for(sObject sobj : scope){
                User curUser = (User)sobj;
                if(curUser.ConsiderInReassignmentBatch__c){
                    backToOfficeuserIdList.add(curUser.Id);
                    curUser.ConsiderInReassignmentBatch__c = false;
                    backToOfficeUserList.add(curUser);
                }
                else if(curUser.Out_Of_Office__c){
                    outOfOfficeuserList.add(curUser);
                }
            }
            // Invoking handler if list size is greater than o
            if(backToOfficeUserList.size() > 0 ) {
                IFv2_TriggerHandler.assignRequestsBack(backToOfficeuserIdList,Null);	
            }
            //updating this ConsiderInReassignmentBatch__c to false
            IFv2_DmlController.GenericListDMLOperation(backToOfficeUserList,'update');
            /** Invoking Out of office**/
            
            if(!outOfOfficeuserList.isEmpty()) {
                //IFv2_TriggerHandler.TransferApproverToDelegatedUser(outOfOfficeuserList);
            }
            
        }
    }
    
    /*
* Finish method 
*/
    global void finish(Database.BatchableContext BC) {
        
        
    }
}