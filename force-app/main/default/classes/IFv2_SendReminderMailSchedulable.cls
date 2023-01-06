/*******************************************************************************************************
* 
* @ Name    		: IFv2_SendReminderMailSchedulable
* @ Purpose 		: To schedule the reminder email
* @ Author  		: Naga sai
* @ Test class name : IFv2_SendReminderMailTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   18-02-2019  |  nagasai.chalamalasetti@absyz.com |  1.0          |  Initial Version
*
*******************************************************************************************************/
global class IFv2_SendReminderMailSchedulable implements Schedulable
{
    global void execute(SchedulableContext sc) {
        IFv2_SendReminderMail sendreminder = new  IFv2_SendReminderMail();
        database.executebatch(sendreminder,1);
        
    }
}