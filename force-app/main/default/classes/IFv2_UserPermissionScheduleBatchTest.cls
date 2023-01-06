/*******************************************************************************************************
* 
* @ Name            : IFv2_UserPermissionScheduleBatchTest
* @ Purpose         : Scheduler class for Archival Batch
* @ Author          : Naga Sai
* @ Test Class Name : IFv2_UserPermsonAsgmntBatchScheduler
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   25-03-2019  |  nagasai.chalamalasetti@absyz.com     |  1.0          |  Initial Version

*******************************************************************************************************/
@isTest
public class IFv2_UserPermissionScheduleBatchTest {
    
    //Method to schedule 
    Public static TestMethod void schedlueMethod() {
        
        test.startTest();
        String cronValue = '0 0 0 28 2 ? *';
        SchedulableContext scheduleContext = null;
        IFv2_UserPermsonAsgmntBatchScheduler dummyBatch = new IFv2_UserPermsonAsgmntBatchScheduler();
        String jobId = System.schedule('ArchivalBatchScheduler12',cronValue,dummyBatch);
        
        CronTrigger cronInstance = [SELECT Id, CronExpression 
                                   FROM CronTrigger 
                                   WHERE Id=:jobId];
        system.assertEquals('0 0 0 28 2 ? *',cronInstance.CronExpression);
        test.stopTest();
    }
}