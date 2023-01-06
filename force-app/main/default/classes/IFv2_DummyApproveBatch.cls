/*******************************************************************************************************
* 
* @ Name		:  IFv2_DummyApproveBatch
* @ Purpose		:  Batch class to approve requests submitted to Dummy User
* @ Author		:  Anoop Ravindran
* @ Test Class  :  IFv2_DummyApproveBatchTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   23-04-2019      |  anoop.ravindran@absyz.com    |  1.0          |  Initial Version

*******************************************************************************************************/

public class IFv2_DummyApproveBatch implements Database.Batchable<Sobject>, Schedulable {
    public IFv2_DummyApproveBatch() {
        
    }
    /* Start Method for Batch Class*/
    public Database.QueryLocator start(Database.BatchableContext bc){
        String DummyUserId = Label.CLIFv20022;
        String query = 'SELECT Id,ActorId,OriginalActorId,ProcessInstance.TargetObjectId '+
            ' FROM ProcessInstanceWorkitem' + 
            ' WHERE (ActorId = \''+DummyUserId +'\''+
            ' OR OriginalActorId = \''+DummyUserId +'\')';
        return Database.getQueryLocator(query);
    }
    /*Execute method for Batch Class*/
    public void execute(Database.BatchableContext bc, LIST<ProcessInstanceWorkitem> items){
        IFv2_DummyApproveBatchHandler.dummyApprove(items,'IFv2_Request__c');
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