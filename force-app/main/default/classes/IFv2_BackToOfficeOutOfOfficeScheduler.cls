/*
 * Block comments with details of changes
 */
global class IFv2_BackToOfficeOutOfOfficeScheduler implements Schedulable
{
      global void execute(SchedulableContext sc) {
        IFv2_BackToOfficeOutOfOfficeBatch backtooffice = new IFv2_BackToOfficeOutOfOfficeBatch(); 
       database.executebatch(backtooffice,1);
      }
}