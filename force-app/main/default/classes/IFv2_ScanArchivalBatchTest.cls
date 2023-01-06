/*******************************************************************************************************
* 
* @ Name    	:   IFv2_ScanArchivalBatchTest
* @ Purpose 	:   Test class for IFv2_P28Controller
* @ Author  	:   Vivek
* @ Class Name 	: 	IFv2_ScanArchivalBatch
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   02-05-2019		|  vivek.kothalanka@absyz.com	|  1.1			|  Initial Version
*
*******************************************************************************************************/
@isTest
public class IFv2_ScanArchivalBatchTest {
    
    //Test set up method
    @TestSetup
    public static void testSetUp(){
        
        User objUser = IFv2_testDataUtility.createUser();
        Database.SaveResult insertUser = Database.insert(objUser);
        system.runAs(objUser){
            ScanArchiving__c scanArchival  = new ScanArchiving__c();
            scanArchival.ArchAfterDays__c = '0';
            scanArchival.Name = 'testdata';
            Database.SaveResult saveResult= Database.insert(scanArchival);
            
            LIST<Scan__c> scanLIST = Ifv2_testDataUtility.createScanRecord(1);
            Database.SaveResult[] saveResultScan = Database.insert(scanLIST);
        }
    }
    //Method for Archival batch with status Archived
    public static TestMethod void scanArchivalBatch(){
        Test.startTest();
        LIST<Scan__c> scanRecordsLIST = new LIST<Scan__c>();
        scanRecordsLIST.addAll(IFv2_testDataUtility.createScanRecord(1));
        
        LIST<Scan__c> scanInsertRecordLIST = new LIST<Scan__c>();
        
        if(!scanRecordsLIST.isEmpty()){
            for(Scan__c scanRecord : scanRecordsLIST) {
                scanRecord.ArchivingStatus__c = 'Archived';
                scanRecord.IFv2_ContentversionIds__c= 'test;test123;test';
                scanRecord.IFv2_SAPStatus__c = 'Success';
                scanInsertRecordLIST.add(scanRecord);
            }
        }
        if(!scanInsertRecordLIST.isEmpty()) {
            Database.SaveResult[] result = Database.insert(scanInsertRecordLIST);
        }
       
        IFv2_ScanArchivalBatch batchInstance = new IFv2_ScanArchivalBatch();
        Database.executeBatch(batchInstance,1);
        
        LIST<Scan__c> scanRecordLIST = new LIST<Scan__c>();
        scanRecordLIST = [SELECT Id,IFv2_SAPStatus__c,ArchivingStatus__c FROM SCAN__C];
        system.assertEquals(2,scanRecordLIST.size());
        Test.stopTest();
    }
      //Method for Archival batch with ICO
    public static TestMethod void scanArchivalBatchforICO(){
        Test.startTest();
        LIST<Scan__c> scanRecordsLIST = new LIST<Scan__c>();
        scanRecordsLIST.addAll(IFv2_testDataUtility.createScanRecord(1));
        
        LIST<Scan__c> scanInsertRecordLIST = new LIST<Scan__c>();
        
        if(!scanRecordsLIST.isEmpty()){
            for(Scan__c scanRecord : scanRecordsLIST) {
                scanRecord.ArchivingStatus__c = 'Archived';
                scanRecord.IFv2_ContentversionIds__c= 'test;test123;test';
                scanRecord.IFv2_SAPStatus__c = 'Success';
                scanInsertRecordLIST.add(scanRecord);
            }
        }
        if(!scanInsertRecordLIST.isEmpty()) {
            Database.SaveResult[] result = Database.insert(scanInsertRecordLIST);
        }
        IFv2_Request__c req = new IFv2_Request__c();
        req.scan__c = scanInsertRecordLIST[0].id;
        insert req;
        IFv2_ScanArchivalBatch batchInstance = new IFv2_ScanArchivalBatch();
        Database.executeBatch(batchInstance,1);
        
        LIST<Scan__c> scanRecordLIST = new LIST<Scan__c>();
        scanRecordLIST = [SELECT Id,IFv2_SAPStatus__c,ArchivingStatus__c FROM SCAN__C];
        system.assertEquals(2,scanRecordLIST.size());
        Test.stopTest();
    }
  
    //Method for Archival status fail
    public static TestMethod void scanArchivalBatchTwo() {
        Test.startTest();
        LIST<Scan__c> scanRecordsTryingStatusLIST = new LIST<Scan__c>();
        LIST<Scan__c> scanInsertRecordFailedSatusLIST = new LIST<Scan__c>(); 
        scanRecordsTryingStatusLIST.addAll(IFv2_testDataUtility.createScanRecord(1));
        if(!scanRecordsTryingStatusLIST.isEmpty()){
            for(Scan__c scanRecord : scanRecordsTryingStatusLIST) {
                //scanRecord.ArchivingStatus__c = 'Error';
                scanRecord.IFv2_ContentversionIds__c= 'test;test123;test';
                scanRecord.IFv2_SAPStatus__c = 'Success';
                scanInsertRecordFailedSatusLIST.add(scanRecord);
            }
        }
        
        if(!scanInsertRecordFailedSatusLIST.isEmpty()) {
            Database.SaveResult[] resultTwo = Database.insert(scanInsertRecordFailedSatusLIST);
        }
        IFv2_ScanArchivalBatch batchInstance2 = new IFv2_ScanArchivalBatch();
        Database.executeBatch(batchInstance2,1);
        
        LIST<Scan__c> scanRecordLIST = new LIST<Scan__c>();
        scanRecordLIST = [SELECT Id,IFv2_SAPStatus__c,ArchivingStatus__c,IFv2_ContentversionIds__c FROM SCAN__C order by ArchivingStatus__c];
        system.debug('scanRecordLIST'+scanRecordLIST);
        //system.assertEquals('Error',scanRecordLIST[1].ArchivingStatus__c);
        system.assertEquals(2,scanRecordLIST.size());
        
        Test.stopTest();
    }
    
    //Method for Printable view
    public static TestMethod void redirectToPrintableViewMethod() {
        
        IFv2_PrintableViewController controllerInstance = new IFv2_PrintableViewController();
        LIST<FeedComment> FeedCommentLIST = new LIST<FeedComment>();
        
        LIST<Scan__c> scanObjectLIST = [SELECT Id,Name 
                                        FROM Scan__c LIMIT 1];
        
        Attachment attachmentRecord = IFv2_testDataUtility.insertXmlAttachment(scanObjectLIST[0].Id);
        insert attachmentRecord;
        
        
        FeedItem feedItemRecord = new FeedItem();
        feedItemRecord.ParentId = userInfo.getUserId();
        feedItemRecord.Body = 'Test';
        feedItemRecord.Type = 'ContentPost';
        if(!scanObjectLIST.isEmpty()){
            feedItemRecord.ParentId =  scanObjectLIST[0].Id; 
        }
        Database.SaveResult saveResult = Database.insert(feedItemRecord);
        FeedComment feedComments = new FeedComment();
        feedComments.CommentBody = 'Test body';
        feedComments.FeedItemId = saveResult.id;
        FeedCommentLIST.add(feedComments);
        insert FeedCommentLIST;
        
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test data';
        contentVersion.PathOnClient = 'test.jpg';
        contentVersion.VersionData = Blob.valueOf('Test Content data');
        contentVersion.IsMajorVersion = true;
        insert contentVersion;
        
        LIST<ContentDocument> ContentDocumentLIST = [SELECT Id, Title, LatestPublishedVersionId 
                                                     FROM ContentDocument];
        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = New ContentDocumentLink();
        if(scanObjectLIST[0] != NULL)
            cdl.LinkedEntityId = scanObjectLIST[0].Id;
        if(ContentDocumentLIST[0] != NULL)
            cdl.ContentDocumentId = ContentDocumentLIST[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        LIST<sobject> OldApprovalList = new LIST<sObject>();
        Account Acc = new Account();
        Acc.IFv2_ContentType__c = 'Approval History';
        Acc.Name = 'OldApproval';
        Acc.IFv2_LegacyComments__c = 'testing';
        Acc.IFv2_LegacyStatus__c = 'Approved';
        
        insert Acc;
        OldApprovalList.add([select id,createddate,IFv2_LegacyStatus__c,IFv2_LegacyComments__c,IFv2_LegacyAssignedTo__c,IFv2_LegacyActualApprover__c,IFv2_StepName__c,IFv2_Legacysubmitter__c,LastModifiedById,LastModifiedDate from Account limit 1]);
        IFv2_printableviewController.OldApprovalRecords = OldApprovalList;
        IFv2_printableviewController.chatterparentId =  scanObjectLIST[0].Id;
        controllerInstance.getOldApprovalRelatedList();
        IFv2_ParseScanToXMLANDPDF.generateXMLANDPDF(scanObjectLIST[0]);
        //Asert statements
        system.assertEquals(IFv2_printableviewController.chatterparentId,scanObjectLIST[0].Id);
        system.assertEquals(IFv2_printableviewController.OldApprovalRecords[0].Id,OldApprovalList[0].Id);
    }
    
}