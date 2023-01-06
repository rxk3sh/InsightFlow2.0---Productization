/*******************************************************************************************************
* 
* @ Name : IFv2_ArchivalBatch
* @ Purpose : Class that collects Requests which are Approved,Rejected,Cancelled and meet Archival condition(currentdate=lastmodifieddate+workflowarchivaldate)
* @ Author: Naga Sai
* @ Test Class Name : IFV2_ArchivalBatchTest
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   13-03-2019  |  nagasai.chalamalasetti@absyz.com     |  1.0          |  Initial Version

********************************************************************************************************
/** Each reuqest record which satisfies the condition of archival and also records which are archived will be queried **/
global class IFv2_ArchivalBatch implements Database.Batchable<sObject>, Database.Stateful{
    global String WorkflowId;
    global String Workflowname;
    global Datetime approxLastModifiedDate;
    //The logic is to have a set which stores processed workflow ids and use that set as a filter to query
    global  SET<Id> workflowids = new SET<Id>();
    global IFv2_ArchivalBatch(String WorkflowId,String Workflowname, Datetime approxLastModifiedDate,SET<Id> workflowidSet){
        workflowids=workflowidSet;
        this.WorkflowId = WorkflowId;
        this.Workflowname = Workflowname;
        this.approxLastModifiedDate = approxLastModifiedDate;
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        LIST<String> requestStatusValues = label.CLIFv20197.split(','); 
        String requestquery = 'SELECT Id, Name, ArchivalStatus__c, ContentversionIds__c,OldRequest__c, Workflow__c, LastModifiedDate, ParentRequest__c, ChallanTypeofGatePass__c,Scan__r.ArchivingDate__c,Scan__r.ArchivingStatus__c	,Scan__c ' +
            'FROM IFv2_Request__c ' +
            'WHERE ArchivalStatus__c != \'considerforzipping\' ' +
            'AND (WorkflowId__c=:WorkflowId OR(WorkflowId__c=Null AND Workflow__c=:Workflowname)) '+
            'AND (lastmodifieddate<=:approxLastModifiedDate OR ArchivalStatus__c = \'Archived\' OR ArchivalStatus__c = \'fail\' OR OldRequest__c!=Null) '+
            'AND (Status__c in:requestStatusValues) ';
        return Database.getQueryLocator(requestquery);		
    }
    
    //1. Archival date of the respective request is queried using its workflow name
    //2. checks whether the record satisfies the archival conditon based on last modified date
    //3. if the record is already archived, then an archival log is created in admin only object with record type archival logs, and once they are created ,respective request is deleted
    //4. if not archived and if it satisfies archival conditon, then xml and pdf of the request are created using IFv2_ParseRequestToXMLANDPDF class.
    //5. Finally all the contentversions are queried and are filled into a ContentversionIds__c field of request and status is changed to 'considerforzipping'. 
    
    global void execute(Database.BatchableContext BC, LIST<IFv2_Request__c> RequestLIST) {
        try{
            if(RequestLIST.size()==1){
                if(RequestLIST[0].OldRequest__c==Null || RequestLIST[0].ArchivalStatus__c == 'Archived'){
                    if(RequestLIST[0].Scan__c==Null){
                        IFv2_ArchivalHandler.executeArchivalLogic(RequestLIST,Workflowname);
                    }
                }
                else{
                    system.debug('entering');
                    LIST<Account> oldApprovals = [select id,createddate from Account where IFv2_Request__c=:RequestLIST[0].id order by createddate desc limit 1];
                    if(oldApprovals.size()>0 && oldApprovals[0].createddate <=approxLastModifiedDate ){
                        IFv2_ArchivalHandler.executeArchivalLogic(RequestLIST,Workflowname);
                    }
                }
            }
        }
        catch(Exception e){
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }
        
    }
    
    /* Finish method */
    global void finish(Database.BatchableContext BC) {
        //The logic is to have a set which stores processed workflow ids and use that set as a filter to query
        LIST<IFv2_Workflow__c> workflows = [SELECT Id, Workflow__c , ArchivingAfterDays__c FROM IFv2_Workflow__c  where id not in:workflowids  limit 1];
        for(IFv2_Workflow__c workflow:workflows){
            workflowids.add(workflow.id);
            //calculating approximate last modfied date using archival date on workflow and checking that this variable
            //should be equal or greater than lastmodifieddate on request record**/
            Datetime Todaysdate = datetime.now();
            if(workflow.ArchivingAfterDays__c!=Null){
                Datetime ApproxLastModifiedDate = Todaysdate.adddays(-(integer)workflow.ArchivingAfterDays__c);
                IFV2_ArchivalBatch archivalBatch = new IFV2_ArchivalBatch(workflow.id,workflow.Workflow__c ,ApproxLastModifiedDate,workflowids);
                //Batch size should be one  
                database.executebatch(archivalBatch,1);
            }
            
        }
    }
}