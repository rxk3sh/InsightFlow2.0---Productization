/*******************************************************************************************************
* 
* @ Name 		: 	IFv2_ScanPrintableViewControllerTest
* @ Purpose 	: 	Test class to Scheduler class IFv2_BackfficeOutOfficeBatchV2Schdulr
* @ Author		: 	Prasad Vivek
* @ Class Name 	:	IFv2_ScanPrintableViewControlle
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   28-10-2018      |  vivek.kothalanka@absyz.com   |  1.0          |  Initial Version
*******************************************************************************************************/
@isTest
public class IFv2_ScanPrintableViewControllerTest {
    
    
    @TestSetUp
    Public static void testSetUpMethod() {
        
        User objUser = IFv2_testDataUtility.createUser();
        Database.SaveResult insertUser = Database.insert(objUser);
        system.runAs(objUser){
            LIST<Scan__c> scanLIST = Ifv2_testDataUtility.createScanRecord(1);
            Database.SaveResult[] saveResult = Database.insert(scanLIST);
            
            IFv2_testDataUtility.createRequestForScan(saveResult[0].Id);
        }
    }
    /*Method to generate PDF */
    Public static testMethod void generatePDFMethod() {
        Test.startTest();
        LIST<Scan__c> scanLIST = new LIST<Scan__c>();
        scanLIST = [SELECT Id,Name 
                    FROM Scan__c ];
        
        system.assertEquals(1,scanLIST.size());
        
        ApexPages.currentPage().getParameters().put('id', scanLIST[0].Id);
        
        IFv2_ScanPrintableViewController scanInstance = new IFv2_ScanPrintableViewController(scanLIST[0].Id);
        system.assertEquals(scanInstance.ScanId,scanLIST[0].Id);
        scanInstance.getgeneratePDF();
        Test.stopTest();
        
    }
}