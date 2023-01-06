/*******************************************************************************************************
* 
* @ Name    : IFv2_HistoricScanRecordsBatchTest
* @ Purpose : Test class for IFv2_HistoricScanRecordsBatch
* @ Author  : Pradeep Chary
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   14-11-2018  |  pradeep.chary@absyz.com				|  1.0          |  Initial Version

*******************************************************************************************************/
@isTest
public class IFv2_HistoricScanRecordsBatchTest {
    
    public static LIST<Scan__c> scanRecordsLIST;
    public static LIST<Scan__c> updatescanLIST;
    public static Attachment xmlAttachment;
    public static Attachment pdfAttachment;
    public static user objUser;
    public static GroupMember grpMem1;
    @testSetup static void createTestData() {
        
        objUser = IFv2_testDataUtility.createUser();
        objUser.Username = 'testUserforScan@scan.com';
        objUser.IFv2_ByPassValidation__c = true;
        objUser.TimeZoneSidKey = 'America/Sao_Paulo';
        insert objUser;
        System.assertEquals(true, objUser.IFv2_ByPassValidation__c = true);
        
        Group grp = [select id,name from Group where name = 'IFv2_Admins' limit 1];
        grpMem1 = new GroupMember();
        grpMem1.UserOrGroupId = userinfo.getUserId();
        grpMem1.GroupId = grp.Id;
        Insert grpMem1;
        
        objUser.IFv2_ByPassValidation__c = false;
        update objUser;
        System.assertEquals(true, objUser.IFv2_ByPassValidation__c == false);
        
        system.runAs(objUser) {
            scanRecordsLIST = IFv2_testDataUtility.createScanRecord(2);
            insert scanRecordsLIST;
            
            xmlAttachment = IFv2_testDataUtility.insertXmlAttachment(scanRecordsLIST[0].Id);
            insert xmlAttachment;
            system.assertEquals(true, xmlAttachment.ParentId == scanRecordsLIST[0].Id);
             
        }
    }
    
    public static testmethod void testScanUpdation() {
        
        Test.startTest();
        
        Group grp = [select id,name from Group where name = 'IFv2_Admins' limit 1];
        System.assertEquals(true, grp != Null);
        
        grpMem1 = [select id from GroupMember limit 1];
        System.assertEquals(true, grpMem1 != Null);
        
        objUser = [SELECT Id, Name FROM User WHERE UserName = 'testUserforScan@scan.com' LIMIT 1];
		system.assertEquals(true, objUser != Null);
        
        system.runAs(objUser) {
            updatescanLIST = [SELECT Id, Name, Company_Code__c, Barcode__c, IFv2_SAPStatus__c, IFv2_DateTime__c, CreatedDate 
                               FROM Scan__c];
            system.assert(!updatescanLIST.isEmpty());
            updatescanLIST[0].Company_Code__c = Null;
            update updatescanLIST;
            
            IFv2_HistoricScanRecordsBatch objBatch = new IFv2_HistoricScanRecordsBatch();
            database.executeBatch(objBatch,1); 
        }        
        
        Test.stopTest();
    }
}