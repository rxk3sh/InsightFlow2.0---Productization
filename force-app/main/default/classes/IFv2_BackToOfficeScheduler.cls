/*******************************************************************************************************
* 
* @ Name		: IFv2_BackToOfficeScheduler
* @ Purpose		: Class that collectss  users who are Back to office and assigns their requests back.
* @ Author		: Hanu Sanampudi
* @ Test Class  : IFv2_BackToOfficeOutOfOfficeBatchV2test
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   11-10-2019  |  hanumantharao.sanampudi@seg-automotive.com     |  1.0          |  Initial Version

*******************************************************************************************************/

global class IFv2_BackToOfficeScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        IFv2_BackToOfficeBatch backToOfficeJob = new IFv2_BackToOfficeBatch(); 
        Database.executebatch(backToOfficeJob, 1);
    }
}