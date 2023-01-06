/*******************************************************************************************************
* 
* @ Name		: IFv2_OutOfOfficeScheduler
* @ Purpose		: Class that collectss  users who are out of office assigns their requests to delegated approvers
* @ Author		: Hanu Sanampudi
* @ Test Class  : IFv2_BackToOfficeOutOfOfficeBatchV2test
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   11-10-2019  |  hanumantharao.sanampudi@seg-automotive.com     |  1.0          |  Initial Version

*******************************************************************************************************/

global class IFv2_OutOfOfficeScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        IFv2_OutOfOfficeBatch outOfOfficeJob = new IFv2_OutOfOfficeBatch(); 
        Database.executebatch(outOfOfficeJob, 1);
    }
}