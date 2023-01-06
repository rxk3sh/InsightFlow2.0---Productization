/*******************************************************************************************************
* 
* @ Name 		: 	IFv2_ScanArchivalBatchSchedulerTest
* @ Purpose 	: 	Test class to Scheduler class for Scan Archival Batch
* @ Author		: 	Prasad Vivek
* @ Class Name 	: 	IFv2_ScanArchivalBatchScheduler
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   28-10-2018      |  vivek.kothalanka@absyz.com   |  1.0          |  Initial Version
*******************************************************************************************************/

@isTest
public class IFv2_ScanArchivalBatchSchedulerTest {
    
    //Method to call schedule class
    Public static TestMethod void schedlueMethod() {
        
        //Creating cron Logic
        String cronValue = '0 0 0 28 2 ? *';
        
        test.startTest();     
        IFv2_ScanArchivalBatchScheduler userPermissionSetAssignmentBatch = new IFv2_ScanArchivalBatchScheduler(); 
        String jobId = System.schedule('ArchivalBatchScheduler',cronValue,userPermissionSetAssignmentBatch);
        CronTrigger crontrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                                   FROM CronTrigger 
                                   WHERE id = :jobId];
        system.assertEquals(0, crontrigger.TimesTriggered);
        test.stopTest();
    }
    
}