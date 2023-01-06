/*******************************************************************************************************
* 
* @ Name		:  IFv2_MaterialBatch
* @ Purpose		:  Batch class to send emails to applicant and Department Head if due date is crossed and materials are pending to be returned
* @ Author		:  Elsa Shaju
* @ Test Class  :  IFv2_MaterialBatchControllerTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   20-05-2019      |  elsa.shaju@absyz.com         |  1.0          |  Initial Version

*******************************************************************************************************/

public class IFv2_MaterialBatch implements Database.Batchable<Sobject>, Schedulable {
    public IFv2_MaterialBatch() {
        
    }
    /* Start Method for Batch Class*/
    public Database.QueryLocator start(Database.BatchableContext bc){
        String workflow = Label.CLIFv20200;
        String query = 'SELECT Id, Name,ParentRequest__c '+
            ' FROM IFv2_Request__c' + 
            ' WHERE (Workflow__c = \''+workflow +'\''+
            ' AND Status__c = \'Submitted\''+
            ' AND DueDateofReturn__c = Today'+
            ' AND ChallanTypeofGatePass__c = \'Returnable\')';
        return Database.getQueryLocator(query);
    }
    /*Execute method for Batch Class*/
    public void execute(Database.BatchableContext bc, LIST<IFv2_Request__c> requests){
        LIST<Messaging.SingleEmailMessage> allSingleEmailLIST = new LIST<Messaging.SingleEmailMessage>();
        set<String> parentReqSet = new set<String>();
        if(!requests.isEmpty()){
            for(IFv2_Request__c req: requests){
                parentReqSet.add(req.ParentRequest__c);
            }
        }
        String query = 'SELECT Id, Name, CreatedById, Approver1__c, DueDateofReturn__c,DetailLink__c, CreatedBy.Name, Approver1__r.Name, CreatedBy.Email, Approver1__r.Email '+
            ' FROM IFv2_Request__c' + 
            ' WHERE (Workflow__c = \''+Label.CLIFv20199 +'\''+
            ' AND Id IN :parentReqSet)';
        LIST<IFv2_Request__c> parentRequests = new LIST<IFv2_Request__c>();
        if(!parentReqSet.isEmpty()){
            parentRequests = Database.query(query);
        }
        //List to store single email messages
        LIST<Contact> contactLIST = [SELECT Id FROM Contact LIMIT 1];
        if(!parentRequests.isEmpty()) {
            for(IFv2_Request__c request : parentRequests) {
                if(request.CreatedBy.Email != null && request.Approver1__r.Email != null) {
                    String bodyApplicant = '<Html><body> Dear ' + request.CreatedBy.Name + ',<br/><br/>' +
                        'The materials for the below request <br/>' +
                        'Request : ' + '<a href="'+request.DetailLink__c+'">'+request.Name+'</a><br/>'+
                        'has been due for return on ' + request.DueDateofReturn__c +'<br/>' +
                        'Please consider this as a reminder <br/><br/><br/>'+
                        '___________________________________________<br/>'+
                        'Please do not reply to this automated mail.<br/>'+
                        '</body></Html>';
                    Messaging.SingleEmailMessage oneEmail = new Messaging.SingleEmailMessage();
                    //Making email address of dummy contact record inactive 
                    oneEmail.setTreatTargetObjectAsRecipient(false);
                    //Setting the setTargetObjectId to dummy contact id
                    if(!contactLIST.isEmpty()) {
                        oneEmail.setTargetObjectId(contactLIST[0].id);
                    }
                    oneEmail.setSaveAsActivity(false);
                    //Setting the WhatId to customobject Id so that merge fields in template gets rendered
                    oneEmail.setWhatId(request.Id);
                    oneEmail.setSubject('Materials of ' +request.Name+ ' is due for return on ' +request.DueDateofReturn__c);
                    //Set email body
                    oneEmail.setHtmlBody(bodyApplicant);
                    //set user email to send email
                    oneEmail.setToAddresses(new LIST<String>{request.CreatedBy.Email,request.Approver1__r.Email});
                    allSingleEmailLIST.add(oneEmail);
                }
                
            }
            if(!allSingleEmailLIST.isEmpty()) {
                Messaging.sendEmail(allSingleEmailLIST);
            }
        }  
    }
    /*Finish method for Batch Class*/
    public void finish(Database.BatchableContext bc){
        
    }
    /* Execute method for Schedule class */
    public void execute(SchedulableContext sc){
        Database.executeBatch(this);
    }
    /* method to schedule the batch according to the given CRON expression*/
    public void scheduleBatch(String jobName,String cron){
        System.schedule(jobName,cron, this);
    }
}