/*******************************************************************************************************
* 
* @ Name :IFv2_ScanArchivalBatchScheduler
* @ Purpose : Scheduler class for Scan Archival Batch
* @ Author: Naga Sai
* @ Test Class Name : IFv2_ScanArchivalBatchSchedulerTest
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   15-04-2019  |  nagasai.chalamalasetti@absyz.com     |  1.0          |  Initial Version

*******************************************************************************************************/

global class IFv2_ScanArchivalBatchScheduler implements Schedulable
{
    global void execute(SchedulableContext sc) {
        IFv2_ScanArchivalBatch scanArchivalBatch = new IFv2_ScanArchivalBatch(); 
        //Batch size should be one  
        database.executebatch(scanArchivalBatch,1);
    }
}