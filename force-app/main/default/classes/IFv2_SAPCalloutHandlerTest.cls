/*******************************************************************************************************
* 
* @ Name    	: IFv2_SAPCalloutHandlerTest
* @ Purpose 	: Test class for IFv2_SAPCalloutHandler
* @ Author  	: Pradeep Chary
* @	Class Name	: IFv2_SAPCalloutHandler
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   14-11-2018  |  pradeep.chary@absyz.com(yv)			|  1.0          |  Initial Version

*******************************************************************************************************/

@isTest
public class IFv2_SAPCalloutHandlerTest {
    
    public static LIST<Scan__c> scanRecordList;
    public static LIST<IFv2_Request__c> requestRecordLIST;
    public static Attachment pdfAttachment;
    public static Attachment xmlAttachment;
    public static User objUser;
    
    @testsetup static void createTestData() {
        
        scanRecordList = IFv2_testDataUtility.createScanRecord(2);
        insert scanRecordList;
        System.assertEquals(true, !scanRecordList.isEmpty());
        
        pdfAttachment = IFv2_testDataUtility.insertPdfAttachment(scanRecordList[0].Id);
        insert pdfAttachment;
        pdfAttachment.Name = 'Test pdf';
        update pdfAttachment;
        System.assertEquals(true, pdfAttachment.Name == 'Test pdf');
        
        xmlAttachment = IFv2_testDataUtility.insertXmlAttachment(scanRecordList[0].Id);
        insert xmlAttachment;
        System.assertEquals(true, xmlAttachment!=Null);
        
        requestRecordLIST = IFv2_testDataUtility.createRequestForScan(scanRecordList[0].Id);
        System.assertEquals(true, !requestRecordLIST.isEmpty());
        
        /*commented for cleaning up of Insightflow 1.0 components
* LIST<WF_Request__c> IFv1requestLIST = new LIST<WF_Request__c>();
LIST<WF_Request__c> IFv1requestLIST2 = new LIST<WF_Request__c>(); */
        MAP<Id,String> scanIdNameMap = new MAP<Id,String>();
        
        for(Scan__c scan : [SELECT Id, Name FROM Scan__c WHERE Id =: scanRecordList[0].Id]) {
            scanIdNameMap.put(scan.Id, scan.Name);
        }
    }
    
    public static TestMethod void calloutMethod() {
        Test.startTest();
        LIST<Scan__c> testScanLIST = [SELECT Id,Name,IFv2_SAPStatus__c, SAP_Response__c 
                                      FROM Scan__c];
        System.assertEquals(true, !testScanLIST.isEmpty());
        
        IFv2_SAPCalloutHandler.httpSapCall(testScanLIST[0].Id, testScanLIST[0].Name);
        Test.stopTest();
    }
    
    public static TestMethod void calloutMethodIFv1() {
        Test.startTest();
        LIST<Scan__c> testScanLIST = [SELECT Id,Name,IFv2_SAPStatus__c, SAP_Response__c 
                                      FROM Scan__c];
        System.assertEquals(true, !testScanLIST.isEmpty());
        /*commented for cleaning up of Insightflow 1.0 components
SG_WF_SAP_COM_STRUC_HANDLER.httpSapCall(testScanLIST[0].Id, testScanLIST[0].Name);
*/
        Test.stopTest();
    }
    
    public static TestMethod void scanTriggerMethod() {
        Test.startTest();
        LIST<Scan__c> testScanLIST = [SELECT Id,Name,IFv2_SAPStatus__c, SAP_Response__c 
                                      FROM Scan__c];
        System.assertEquals(true, !testScanLIST.isEmpty());
        
        Scan__c scanToUpdate = testScanLIST[0];
        scanToUpdate.IFv2_SAPStatus__c = 'Draft';
        scanToUpdate.SAP_Response__c = Null;
        scanToUpdate.IsArchived__c = 'N';
        update scanToUpdate;
        System.assertEquals(true, scanToUpdate.IFv2_SAPStatus__c == 'Draft');
        System.assertEquals(true, scanToUpdate.SAP_Response__c == Null);
        Test.stopTest();
    }
    
    public static TestMethod void soapUpdateMethod() {
        Test.startTest();
        requestRecordLIST = [SELECT  Id, Status__c,Scan__c,Workflow__c,Account__r.IFv2_SAPUPDATERESULT__c,Account__r.IFv2_SequenceNumber__c, CompanyCode__c, Account__r.IFv2_InvoiceNumber__c, Account__r.IFv2_FiscalYear__c,
                             Account__r.IFv2_DocumentItem__c, Account__r.IFv2_SalesforceID__c,Account__r.IFv2_WorkflowNumber__c
                             FROM IFv2_Request__c];
        System.assertEquals(true, !requestRecordLIST.isEmpty());
        
        LIST<Id> requestIdList = new LIST<Id>();
        for(IFv2_Request__c req: requestRecordLIST) {
            requestIdList.add(req.Id);
        }
        IFv2_SAPCalloutHandler.soapUpdateSapStatus(requestIdList);
        Test.stopTest();
    }
    
    public static TestMethod void soapUpdateMethodIFv1() {
        
        Test.startTest();
        scanRecordList = IFv2_testDataUtility.createScanRecord(2);
        insert scanRecordList;
        LIST<Scan__c> scanrecord = [SELECT Id, Name FROM Scan__c WHERE Id = :scanRecordList[0].Id];
        /*commented for cleaning up of Insightflow 1.0 components   
* WF_Request__c request = new WF_Request__c();
request.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = '39 AP Monitor workflow-6'].Id;
request.Workflow_Number__c = '06';
request.Status__c = 'Draft';
request.Salesforce_Id__c = scanrecord[0].Name;
insert request; */
        
        IFv2_testDataUtility.insertPdfAttachment(scanrecord[0].id);
        IFv2_testDataUtility.insertXmlAttachment(scanrecord[0].id);
        /*commented for cleaning up of Insightflow 1.0 components
* request.Status__c = 'Submitted';
update request;
LIST<WF_Request__c> IFv1requestLIST = [SELECT  Id, Status__c, Company_Code__c, Invoice_Number__c, Fiscal_Year__c,
Document_Item__c, APM_Workflow_Name__c, Salesforce_Id__c, Sequence_Number__c,Workflow_Number__c
FROM WF_Request__c WHERE Id = :request.Id]; 

System.assertEquals(true, !IFv1requestLIST.isEmpty());

LIST<Id> requestIdList = new LIST<Id>();
for(WF_Request__c req : IFv1requestLIST) {
requestIdList.add(req.Id);
}
SG_WF_SAP_COM_STRUC_HANDLER.soapUpdateSapStatus(requestIdList); */
        Test.stopTest();
    }
}