/*******************************************************************************************************
* 
* @ Name		: IFv2_BackfficeOutOfficeBatchV2Schdulr
* @ Purpose		: Class that collectss  users who are out of office assigns their requests to delegated approvers
* @ Author		: Naga Sai
* @ Test Class  : IFv2_BackToOfficeOutOfOfficeBatchV2test
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   09-04-2018  |  nagasai.chalamalasetti@absyz.com     |  1.0          |  Initial Version

*******************************************************************************************************/

global class IFv2_BackfficeOutOfficeBatchV2Schdulr implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        IFv2_BackToOfficeOutOfOfficeBatchV2 backtooffice = new IFv2_BackToOfficeOutOfOfficeBatchV2(); 
        Database.executebatch(backtooffice, 1);
    }
}