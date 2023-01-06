/*******************************************************************************************************
* 
* @ Name       :   IFv2_BackToOfficeOutOfOfficeBatchTest
* @ Purpose    :   Test class for BackToOffice OutOfOfficeBatch
* @ Author     :   Prasad Vivek
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   22-01-2018      |  vivek.kothalanka@absyz.com   |  1.0          |  Initial Version
*************************************************************************/
@isTest
public class IFv2_BackToOfficeOutOfOfficeBatchTest {
     public static user objUser;
    /* Test method for IFv2_BackToOfficeOutOfOfficeBatch Batch class*/
    static testMethod void testMethodForBatchClass(){
        
        Test.startTest();
        
        User loggedInUser = IFv2_testDataUtility.createSGStandardUser();
        loggedInUser.Username = 'sgtestuserabsyz123@test.com';
        loggedInUser.ConsiderInReassignmentBatch__c = true;
        insert loggedInUser;
        
        system.assertEquals('sgtestuserabsyz123@test.com', loggedInUser.Username);
        IFv2_BackToOfficeOutOfOfficeBatch batchInstance = new IFv2_BackToOfficeOutOfOfficeBatch();
        DataBase.executeBatch(batchInstance);
        Test.stopTest();
    }
      
	 @isTest (SeeAllData=false)  
    static void executeTest(){
        
         //createTestData();
        SchedulableContext sc = null;
        system.debug('user'+[select name from user].size());
        Test.startTest();
        IFv2_BackToOfficeOutOfOfficeScheduler tsc = new IFv2_BackToOfficeOutOfOfficeScheduler();
         String jobId = system.schedule('jobName', '0 0 12 * * ?' , tsc);
        CronTrigger cronInstance = [SELECT Id, CronExpression 
                                    FROM CronTrigger 
                                    WHERE Id=:jobId];
        system.assertEquals('0 0 12 * * ?',cronInstance.CronExpression);
        //tsc.execute(sc);
         Test.stopTest();
         
    }     
    
    
    
}