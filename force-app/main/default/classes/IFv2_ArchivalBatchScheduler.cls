/*******************************************************************************************************
* 
* @ Name :IFv2_ArchivalBatchScheduler
* @ Purpose : Scheduler class for Archival Batch
* @ Author: Naga Sai
* @ Test Class Name : IFV2_ArchivalBatchTest
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   25-03-2019  |  nagasai.chalamalasetti@absyz.com     |  1.0          |  Initial Version

*******************************************************************************************************/

global class IFv2_ArchivalBatchScheduler implements Schedulable
{
     
    global void execute(SchedulableContext sc) {
       //querying for workflows with limit 1
        LIST<IFv2_Workflow__c> workflows = [SELECT id, Workflow__c , ArchivingAfterDays__c FROM IFv2_Workflow__c  limit 1];
      SET<Id> workflowids = new SET<Id>();
      //The logic is to have a set which stores processed workflow ids and use that set as a filter to query
        for(IFv2_Workflow__c workflow:workflows){
           workflowids.add(workflow.id);
            //calculating approximate last modfied date using archival date on workflow and checking that this variable
            //should be equal or greater than lastmodifieddate on request record**/
            Datetime Todaysdate = datetime.now();
            //checking for null
            if(workflow.ArchivingAfterDays__c!=Null){
                Datetime ApproxLastModifiedDate = Todaysdate.adddays(-(integer)workflow.ArchivingAfterDays__c);
                IFV2_ArchivalBatch archivalBatch = new IFV2_ArchivalBatch(workflow.id,workflow.Workflow__c ,ApproxLastModifiedDate,workflowids);
                //Batch size should be one  
                database.executebatch(archivalBatch,1);
            }
        }
    }
}