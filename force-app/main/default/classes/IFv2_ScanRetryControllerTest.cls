/*******************************************************************************************************
* 
* @ Name 		:	IFv2_ScanRetryControllerTest
* @ Purpose 	: 	Test class for the Home page
* @ Author		: 	Prasad Vivek
* @ Class Name 	:	IFv2_ScanRetryController
*
*   Date        |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   09-11-2018  |  vivek.kothalnka@absyz.com	|  1.0          |  Initial Version
*
*******************************************************************************************************/
@isTest
public class IFv2_ScanRetryControllerTest {
    public static LIST<Scan__c> scanRecordLIST;
    public static Scan__c scanRecord;
    
    @testsetup static void createTestData() {
        scanRecordLIST = IFv2_testDataUtility.createScanRecord(3);
        insert scanRecordLIST;
    }
    
    public static TestMethod void successMethod() {
        scanRecordLIST = [SELECT Id, Name, SAP_Response__c, IFv2_SAPStatus__c
                          FROM Scan__c];
        System.assertEquals(true, scanRecordLIST.size()>0);
        Id scanId = scanRecordLIST[0].Id;
        String response = IFv2_ScanRetryController.updateScanRecord(scanId);
        
    }
    
     public static TestMethod void successMethod1() {
        scanRecordLIST = [SELECT Id, Name, SAP_Response__c, IFv2_SAPStatus__c
                          FROM Scan__c];
        System.assertEquals(true, scanRecordLIST.size()>0);
        Id scanId = scanRecordLIST[0].Id;
        integer count = IFv2_ScanRetryController.getFailedRecord(system.today(),system.today().addDays(2));
        String response = IFv2_ScanRetryController.reprocessFailedRecord(system.today(),system.today().addDays(2));
        
    }
    
    public static TestMethod void failureMethod() {
        scanRecordLIST = [SELECT Id, Name, SAP_Response__c, IFv2_SAPStatus__c
                          FROM Scan__c];
        System.assertEquals(true, scanRecordLIST.size()>0);
        scanRecordLIST[0].IFv2_SAPStatus__c = 'Success';
        update scanRecordLIST;
        System.assertEquals(true, scanRecordLIST[0].IFv2_SAPStatus__c == 'Success');
        
        scanRecord = [SELECT Id, Name, SAP_Response__c, IFv2_SAPStatus__c
                      FROM Scan__c 
                      WHERE IFv2_SAPStatus__c = 'Success'];
        System.assertEquals(true, scanRecord.IFv2_SAPStatus__c == 'Success');
        Id scanId = scanRecord.Id;
        String response = IFv2_ScanRetryController.updateScanRecord(scanId);
        Integer count = IFv2_ScanRetryController.getFailedRecord(system.today(),system.today());
        String response1 = IFv2_ScanRetryController.reprocessFailedRecord(system.today(),system.today());

    }
}