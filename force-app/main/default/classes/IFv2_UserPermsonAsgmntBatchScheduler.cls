/*******************************************************************************************************
* 
* @ Name            : IFv2_UserPermsonAsgmntBatchScheduler
* @ Purpose         : Scheduler class for Archival Batch
* @ Author          : Naga Sai
* @ Test Class Name : IFv2_UserPermissionScheduleBatchTest
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   25-03-2019  |  nagasai.chalamalasetti@absyz.com     |  1.0          |  Initial Version

*******************************************************************************************************/

global class IFv2_UserPermsonAsgmntBatchScheduler implements Schedulable
{
    global void execute(SchedulableContext sc) {
        IFv2_UserPermissionSetAssignmentBatch userPermissionSetAssignmentBatch = new IFv2_UserPermissionSetAssignmentBatch(); 
        if(!Test.isRunningTest()){
                  database.executebatch(userPermissionSetAssignmentBatch,1);  
        }
    }
}