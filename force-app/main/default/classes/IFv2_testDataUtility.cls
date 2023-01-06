/*******************************************************************************************************
* 
* @ Name    		:   IFv2_testDataUtility
* @ Purpose 		:   Data preparation
* @ Author  		:   Madhura Vani
* @ Test class name : 	IFv2_WorkflowListviewControllerTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   09-11-2018      |  madhuravani.b@absyz.com      |  1.0          |  Initial Version
*
*******************************************************************************************************/
public with sharing class IFv2_testDataUtility {
    
    //Integer Test Data Size
    public static Integer testDataSize = 1; 
    
    /** Inserting IFv2_Request__c object **/
    public static list<IFv2_Request__c> createRequest(){
        
        list<IFv2_Request__c> lstsObj = new list<IFv2_Request__c>(); 
        for (Integer i= 0 ; i < testDataSize ; i++){
            IFv2_Request__c obj = new IFv2_Request__c(); 
            
            obj.Status__c = 'Draft' ;
            
            lstsObj.add(obj);
        }   
        return lstsObj;
    }
    
    public static LIST<IFv2_HomeScreenTab__c> createHomeScreenCustomSettings(){
        
        LIST<IFv2_HomeScreenTab__c> customSettingLIST = new LIST<IFv2_HomeScreenTab__c>();
        IFv2_HomeScreenTab__c homescreenRecord = new IFv2_HomeScreenTab__c();
        homescreenRecord.Name__c = 'Thank you for contacting us. SEG Automotive. This record is for Testing';
        homescreenRecord.IsActive__c = true;
        homescreenRecord.Name ='Test';
        homescreenRecord.Link__c = 'http://test.salesforce.com';
        homescreenRecord.ImageName__c = 'SEGlogo';
        homescreenRecord.Description__c = 'Test';
        homescreenRecord.Sequence__c = 1;
        homescreenRecord.Country__c='Global';
        homescreenRecord.AppOldName__c = 'Test App1';
        customSettingLIST.add(homescreenRecord);
        return customSettingLIST;
    }
    
    /*Inserting requests that have related old request*/
    public static list<IFv2_Request__c> createRequestWithOldRequest(String WFName){
        
        list<IFv2_Request__c> lstsObj = new list<IFv2_Request__c>(); 
        /*commented for cleaning up of Insightflow 1.0 components
//  list<WF_Request__c> lstsOldObj = new list<WF_Request__c>();
/*
for (Integer i= 0 ; i < testDataSize ; i++){
WF_Request__c obj1 = new WF_Request__c();
obj1.Description_Identification__c = 'test';
obj1.Version__c = '1.0';
obj1.Short_description__c = 'abc';
obj1.Release_date__c = system.today()+1;
lstsOldObj.add(obj1);
}
try{
insert lstsOldObj;
}catch (Dmlexception e){
system.debug('lead update failed: '+e);
} */
        //  createMaterialRelatedListRecord(lstsOldObj[0].id);
        for (Integer i= 0 ; i < testDataSize ; i++){
            IFv2_Request__c obj = new IFv2_Request__c(); 
            obj.WorkFlow__c = WFName;
            obj.Status__c = 'Draft' ;
            //     obj.OldRequest__c = lstsOldObj[0].Id;
            lstsObj.add(obj);
        }   
        return lstsObj;
    }
    
    /** Inserting IFv2_Request__c object **/
    public static list<IFv2_Request__c> createRequest(id id1,id id2){
        
        list<IFv2_Request__c> lstsObj = new list<IFv2_Request__c>(); 
        for (Integer i= 0 ; i < testDataSize ; i++){
            IFv2_Request__c obj = new IFv2_Request__c(); 
            obj.Status__c = 'Draft' ;
            obj.Approver1__c = id1;
            obj.Approver2__c = id2;
            lstsObj.add(obj);
        }   
        return lstsObj;
    }
    
    /** Inserting IFv2_Request__c object **/
    public static list<IFv2_Request__c> createRequest(id oldRequestId){
        list<IFv2_Request__c> lstsObj = new list<IFv2_Request__c>(); 
        for (Integer i= 0 ; i < testDataSize ; i++){
            IFv2_Request__c obj = new IFv2_Request__c(); 
            obj.Status__c = 'Draft' ;
            obj.OldRequest__c = oldRequestId;
            lstsObj.add(obj);
        }   
        return lstsObj;
    }
    
    /** Inserting Request_APAC__c object **/
    public static list<IFv2_Request__c> createRequestWithOldAPACRequest(String WFName, User objUser){
        list<IFv2_Request__c> lstsObj = new list<IFv2_Request__c>();
        /*commented for cleaning up of Insightflow 1.0 components
//    list<Request_APAC__c> lstsOldObj = new list<Request_APAC__c>();

/*    for (Integer i= 0 ; i < testDataSize ; i++){
Request_APAC__c obj1 = new Request_APAC__c();
obj1.Status__c = 'Draft';
obj1.Employee_Company__c = 'test';
obj1.Employee_Name__c = objUser.id;
obj1.Reason_for_Exit__c = 'Transfer';
obj1.Approver_01__c = objUser.id;
obj1.Subject__c = 'test';
lstsOldObj.add(obj1);
}
insert lstsOldObj;*/
        
        //  createEmployeeRelatedListRecord(lstsOldObj[0].id);
        //  createChinaRelatedListRecord(lstsOldObj[0].id);
        //  createChinaLeaveOvertimeRelatedListRecord(lstsOldObj[0].id);
        
        for (Integer i= 0 ; i < testDataSize ; i++){
            IFv2_Request__c obj = new IFv2_Request__c(); 
            obj.WorkFlow__c = WFName;
            obj.Status__c = 'Draft' ;
            //    obj.OldRequest__c = lstsOldObj[i].Id;
            lstsObj.add(obj);
        }   
        system.debug('lstsObj---'+lstsObj);
        return lstsObj;
        
    }
    
    /** Inserting Request_EMEA__c object **/
    public static list<IFv2_Request__c> createRequestWithOldEMEARequest(String WFName) {
        list<IFv2_Request__c> lstsObj = new list<IFv2_Request__c>();
        /*commented for cleaning up of Insightflow 1.0 components
// list<Request_EMEA__c> lstsOldObj = new list<Request_EMEA__c>();
/*
for (Integer i= 0 ; i < testDataSize ; i++){
Request_EMEA__c obj1 = new Request_EMEA__c();
lstsOldObj.add(obj1);
}
insert lstsOldObj;
*/
        
        for (Integer i= 0 ; i < testDataSize ; i++){
            IFv2_Request__c obj = new IFv2_Request__c(); 
            obj.WorkFlow__c = WFName;
            obj.Status__c = 'Draft' ;
            //obj.OldRequest__c = lstsOldObj[i].Id;
            lstsObj.add(obj);
        }
        
        return lstsObj;
    }
    
    /** Inserting Request_NALA__c object **/
    public static list<IFv2_Request__c> createOldNALARequest(String WFName) {
        list<IFv2_Request__c> lstsObj = new list<IFv2_Request__c>();
        /*commented for cleaning up of Insightflow 1.0 components
//  list<Request_NALA__c> lstsOldObj = new list<Request_NALA__c>();
/*
for (Integer i= 0 ; i < testDataSize ; i++){
Request_NALA__c obj1 = new Request_NALA__c();
lstsOldObj.add(obj1);
}
insert lstsOldObj;
*/
        
        for (Integer i= 0 ; i < testDataSize ; i++){
            IFv2_Request__c obj = new IFv2_Request__c(); 
            obj.WorkFlow__c = WFName;
            obj.Status__c = 'Draft' ;
            //   obj.OldRequest__c = lstsOldObj[i].Id;
            lstsObj.add(obj);
        }
        return lstsObj;
    }
    /*commented for cleaning up of Insightflow 1.0 components
/** Inserting Employee__c object **//*
public static void createEmployeeRelatedListRecord(id oldRequestId) {
list<Employee__c> lstsObj = new list<Employee__c>();

Account acc= new Account();
acc.Name = 'Test Account';
acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Internal').getRecordTypeId();
insert acc;

Contact con = new Contact();
con.LastName = 'Test Contact';
con.AccountId = acc.Id;
insert con;

for (Integer i= 0 ; i < testDataSize ; i++){
Employee__c emp = new Employee__c();
emp.Personnel_No__c = con.Id;
emp.Remark__c = 'Test Remarks';
emp.Associated_Request__c = oldRequestId;
lstsObj.add(emp);
}
insert lstsObj;

//return lstsObj;
}
*/
    /** Inserting Travel__c object **//*
public static void createChinaRelatedListRecord(id oldRequestId) {
list<China_MAE__c> lstsObj = new list<China_MAE__c>();
for (Integer i= 0 ; i < testDataSize ; i++){
China_MAE__c mae = new China_MAE__c();
mae.Name = 'Test MAE'+i;
mae.Asset_Number__c = 987654;
mae.Sub_Number__c = 654321;
mae.Comment__c = 'Test Comments';
mae.Description__c = 'Test description';
mae.Estimated_Import_Tax_to_Pay__c = 987654;
mae.Import_Tax__c = 65;
mae.Info_from_SAP__c = 'test info from sap';
mae.Inventory_Number__c = 9875;
mae.Net_Book_Value__c = 4563;
mae.Net_Book_Value_at_Lost_Month__c = 654;
mae.Net_Book_Value_at_Planned_Month__c = 321;
mae.New_Asset_Number__c = 4678;
mae.New_Description__c = '32154';
mae.New_Inventory_Number__c = 45678;
mae.New_Location__c = 'China';
mae.New_Net_Book_Value__c = 123548;
mae.New_Sub_Number__c = 8524;
mae.New_Original_Value__c = 7518;
mae.RecordTypeId = Schema.SObjectType.China_MAE__c.getRecordTypeInfosByName().get('China MAE Lost').getRecordTypeId();
mae.Old_Asset_Number__c = '4654';
mae.Old_Inventory_Number__c = '467';
mae.Old_Sub_Number__c = '1325';
mae.Physical_Location__c = 'India';
mae.Request_Number__c=oldRequestId;
lstsObj.add(mae);
} 
insert lstsObj;
}
*/
    
    /** Inserting Travel__c object **/
    /*
public static void createChinaTravelRelatedListRecord(id oldRequestId) {
list<Travel__c> lstsObj = new list<Travel__c>();
for (Integer i= 0 ; i < testDataSize ; i++){
Travel__c travel = new Travel__c();
travel.China_Travel__c = oldRequestId;
travel.From_Place__c = 'Hyderabad';
travel.To_Place__c = 'Pune';
travel.From_Date_Time__c = system.today();
travel.To_Date_Time__c = system.today() + 2;
lstsObj.add(travel);
}
System.debug('Travel'+lstsObj);
insert lstsObj;
}
*/
    /** Inserting Material__c object **/
    /*  public static void createMaterialRelatedListRecord(id oldRequestId) {
list<Material__c> lstsObj = new list<Material__c>();
for (Integer i= 0 ; i < testDataSize ; i++){
Material__c mat = new Material__c();
mat.Name = 'Test Material';
mat.Request__c = oldRequestId;
mat.Language__c = 'E';
mat.Supplier_No__c = '654987';
mat.Customer_No__c = '654321';

lstsObj.add(mat);
}
try{
insert lstsObj;
}catch (Dmlexception e){
system.debug('lead update failed: '+e);
}
} 
*/
    
    /** Inserting Table__c object **/
    /*
public static void createChinaLeaveOvertimeRelatedListRecord(id oldRequestId) {
list<Table__c> lstsObj = new list<Table__c>();
for (Integer i= 0 ; i < testDataSize ; i++){
Table__c table = new Table__c();
table.Act_Clock_In2__c = system.today();
table.Act_Clock_Out2__c = system.today();
table.All_Day__c = 'Yes';
table.RecordTypeId = Schema.SObjectType.Table__c.getRecordTypeInfosByName().get('Leave Details').getRecordTypeId();
table.From_Date__c = system.today();
table.To_Date__c = system.today() + 2;
table.From__c = 'India';
table.To__c = 'Germany';
table.Request_APAC__c = oldRequestId;           
lstsObj.add(table);
}
insert lstsObj;
}
*/
    /* Inserting user record */
    public static user createSGStandardUser(){ 
        
        User userRecord = new User();
        try{
            
            String profileId = [SELECT Id FROM Profile WHERE Name = 'SG Standard User'].Id;
            userRecord.ProfileId = profileId;
            userRecord.LastName = 'SG Test User';
            userRecord.Email = 'sgtestuser@test.com';
            userRecord.Username = 'veernedr123atestuser@test.com';
            userRecord.CompanyName = 'SEG';
            userRecord.Title = 'Sales';
            userRecord.Alias = 'User';
            
            userRecord.TimeZoneSidKey = 'America/Sao_Paulo';
            userRecord.EmailEncodingKey = 'UTF-8';
            userRecord.LanguageLocaleKey = 'en_US';
            userRecord.LocaleSidKey = 'en_US';
            userRecord.Department = 'SG/CFA';
            userRecord.Country = 'China'; 
        } Catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage()); 
        }
        return userRecord;
        
    }
    
    /* Inserting user record */
    public static user createUser(){ 
        
        User userRecord = new User();  
        try{
            
            String profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
            userRecord.ProfileId = profileId;
            userRecord.LastName = 'Test Admin User';
            userRecord.Email = 'testAdmin@seg.com';
            userRecord.Username = 'testAdmin@seg.com';
            userRecord.CompanyName = 'SEG';
            userRecord.Title = 'Admin';
            userRecord.Alias = 'User';
            userRecord.ManagerId=userRecord.Id;
            userRecord.TimeZoneSidKey = 'America/Sao_Paulo';
            userRecord.EmailEncodingKey = 'UTF-8';
            userRecord.LanguageLocaleKey = 'en_US';
            userRecord.LocaleSidKey = 'en_US';
            userRecord.iFreight_Plant__c = 'HiP';
            //userRecord.Country = 'China';
        } Catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage()); 
        }
        return userRecord;
        
    }
    
    
    
    
    /* Inserting custom settings record */
    public static IFv2_Workflow__c createWorkflowCustomSetting(){
        
        IFv2_Workflow__c workflowRecord = new IFv2_Workflow__c();
        try{
            workflowRecord.Name = 'eSignature';
            workflowRecord.Workflow__c = 'eSignature';
            workflowRecord.ApplicationKey__c = 'EUU';
            workflowRecord.ArchivingAfterDays__c = 180;
            workflowRecord.Category__c = 'All';
            workflowRecord.Description__c = 'Workflow for the approval of quality documents such as FMEAs, QA douments etc. 789698767';
            workflowRecord.Country__c = 'Global';
            workflowRecord.ReminderAfterDays__c = 7;
            workflowRecord.Active__c = true;
            
        } Catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage());	
        }
        return workflowRecord;
    }
    
    /** Inserting Accounts **/
    public static Account createAccount(){
        Account objAcc = new Account();
        objAcc.Name = 'Test Account';
        objAcc.BillingStreet='Test Street';
        objAcc.BillingCity='Test City';
        objAcc.BillingState='Test State';
        objAcc.BillingCountry='Test Country';
        objAcc.BillingPostalCode='Test Postal Code';
        
        return objAcc;
    }
    
    public static contact createContact(Account objAcc){
        Contact objCon = new Contact();
        objCon.LastName='Contact';
        objCon.FirstName='Test';
        objCon.AccountId = objAcc.Id;
        return objCon;
    }
    
    public static EntitySubscription createEntitySubscription(string strReqId,User objUser){
        EntitySubscription objSubscription = new EntitySubscription();
        objSubscription.ParentId = strReqId;
        objSubscription.SubscriberId = objUser.id;
        return objSubscription;
    }
    
    public static list<FeedItem> createFeedItem(list<IFv2_Request__c> lstRequest){
        list<FeedItem> lstsObj = new list<FeedItem>(); 
        for (Integer i= 0 ; i < testDataSize ; i++){
            FeedItem obj = new FeedItem(); 
            obj.ParentId = lstRequest[0].id;
            obj.Body = 'Hello';
            lstsObj.add(obj);
        }   
        return lstsObj;
    }
    
    public static IFv2_Request__Share createRequestShare(User objUser,list<FeedItem> lstFeedItem){
        IFv2_Request__Share chatterShare = new IFv2_Request__Share();
        chatterShare.ParentId = lstFeedItem[0].ParentId;
        chatterShare.UserOrGroupId = objUser.id;
        chatterShare.AccessLevel = 'read';
        return chatterShare;
    }
    
    /*
public static Workflow__c createOldWorkflow(){
Workflow__c objWorkflow = new Workflow__c();
objWorkflow.Name = 'eSignature';
return objWorkflow;
}

public static Request_EMEA__c createRequestEMEA(Workflow__c objWF,User objUser){
Request_EMEA__c obj1 = new Request_EMEA__c();
obj1.Workflow_Name__c = objWF.id;
obj1.BatchCompleted__c = False;
obj1.Predefined_Approver_1__c = objUser.id;
obj1.Status__c = 'Approved';
return obj1;
}
public static Request_APAC__c createRequestAPAC(Workflow__c objWF,User objUser){
Request_APAC__c obj1 = new Request_APAC__c();
//bj1.WF_Workflow_Name__c
obj1.WF_Workflow_Name__c = objWF.id;
obj1.BatchCompleted__c = False;
obj1.Approver_01__c = objUser.id;
obj1.Status__c = 'Approved';
return obj1;
}
public static Request_NALA__c createRequestNALA(Workflow__c objWF,User objUser){
Request_NALA__c obj1 = new Request_NALA__c();
//bj1.WF_Workflow_Name__c
obj1.WF_Workflow_Name__c = objWF.id;
obj1.BatchCompleted__c = False;
obj1.Approver_01__c = objUser.id;
obj1.Predefined_Approver_01__c=objUser.id;
obj1.Status__c = 'Approved';
return obj1;
}


public static WF_Request__c createRequestOld(Workflow__c objWF,User objUser){
WF_Request__c obj1 = new WF_Request__c();
obj1.WF_Workflow_Name__c = objWF.id;
obj1.BatchCompleted__c = False;
obj1.WF29_Approver__c=objUser.id;
obj1.Status__c = 'Approved';
return obj1;
}
*/
    /* Iteration 3 Start */
    public static LIST<Scan__c> createScanRecord(Integer recordSize){
        testDataSize = recordSize;
        LIST<Scan__c> scanRecordList = new LIST<Scan__c>();
        for (Integer i= 0 ; i < testDataSize ; i++){
            Scan__c scanObj = new Scan__c();
            scanObj.Barcode__c = '71F09999995';
            scanObj.IFv2_DateTime__c = system.now();
            scanObj.Company_Code__c = '68C0';
            scanObj.IFv2_SAPStatus__c = 'Failed';
            scanObj.IsArchived__c = 'N';
            
            scanRecordList.add(scanObj);
        }
        return scanRecordList;
    }
    
    public static Attachment insertXmlAttachment(Id recordId) {
        Attachment att = new Attachment();
        att.ContentType = 'application/xml';
        att.Body = Blob.valueOf('<DOCUMENT><FIELDGROUP Name="Header">'
                                + '<FIELD Name="INV_AMOUNT" />'
                                + '<FIELD Name="INV_COMPLIANT"/>'
                                +'<FIELD Name="INV_CREDIT_NOTE"/>'
                                +'<FIELD Name="INV_CURRENCY"/>'
                                +'<FIELD Name="INV_NET_AMOUNT1"/>'
                                +'<FIELD Name="INV_NET_AMOUNT2"/>'
                                +'<FIELD Name="INV_NET_AMOUNT3"/>'
                                +'<FIELD Name="INV_NUMMER" />'
                                +'<FIELD Name="INV_DATE" />'
                                +'<FIELD Name="INV_TAX_AMOUNT1"/>'
                                +'<FIELD Name="INV_TAX_AMOUNT2" />'
                                +'<FIELD Name="INV_TAX_AMOUNT3" />'
                                +'<FIELD Name="INV_TAX_RATE1"/>'
                                +'<FIELD Name="INV_TAX_RATE2" />'
                                +'<FIELD Name="INV_TAX_RATE3" />'
                                +'<FIELD Name="VE_PBANKTYPE" />'
                                +'<FIELD Name="INV_UNPL_DEL_AMOUNT" />'
                                +'<FIELD Name="INV_UNPL_DEL_TAX_RATE" />'
                                +'<FIELD Name="INV_BARCODE" />'
                                +'<FIELD Name="VE_COUNTRY" />'
                                +'<FIELD Name="VE_VENDOR_NO" />'
                                +'<FIELD Name="RE_RECIPIENT_NO" />'
                                +'<FIELD Name="VE_ACCOUNT_NO" />'
                                +'<FIELD Name="RE_RECIEPIENT_NO" />'
                                +'<FIELD Name="INV_AMOUNT_ROUNDING" />'
                                +'<FIELD Name="INV_DISCOUNT_AMOUNT1" />'
                                +'<FIELD Name="INV_DISCOUNT_AMOUNT2" />'
                                +'<FIELD Name="INV_DISCOUNT_PERCENT1" />'
                                +'<FIELD Name="INV_DISCOUNT_PERCENT2" />'
                                +'<FIELD Name="INV_IS_INTERCOMPANY" />'
                                +'<FIELD Name="INV_IS_MM" />'
                                +'<FIELD Name="INV_TAX_TYPE" />'
                                +'<FIELD Name="INV_TOTAl_TAX_AMOUNT" />'
                                
                                +'</FIELDGROUP><TABLE Name="InvoiceItems">'
                                +'<ROW><FIELD Name="INVI_POS_NO" />'
                                +'<FIELD Name="INVI_ORI_ARTICLE_NO" />'
                                +'<FIELD Name="INVI_ORI_DESCRIPTION" />'
                                +'<FIELD Name="INVI_QUANTITY" />'
                                +'<FIELD Name="INVI_QUANTITY_UNIT" />'
                                +'<FIELD Name="INVI_SINGLE_NET_PRICE" />'
                                +'<FIELD Name="INVI_PRICE_PER_UNIT" />'
                                +'<FIELD Name="INVI_TOTAL_NET_PRICE" />'
                                +'<FIELD Name="INVI_DISCOUNT_AMOUNT1" />'
                                +'<FIELD Name="INVI_DISCOUNT_AMOUNT2"/>'
                                +'<FIELD Name="INVI_DISCOUNT_AMOUNT3" />'
                                +'+<FIELD Name="INVI_DISCOUNT_PERCENT1" />'
                                +'+<FIELD Name="INVI_DISCOUNT_PERCENT2" />'
                                +'<FIELD Name="INVI_DISCOUNT_PERCENT3" />'
                                +'<FIELD Name="INVI_DELIVERY_NO" />'
                                +'<FIELD Name="INVI_DELIVERY_POS" />'
                                +'<FIELD Name="INVI_HSN_CODE" />'
                                +'<FIELD Name="INVI_ORDER_NO" />'
                                +'</ROW></TABLE></DOCUMENT>');
        
        att.Name = '9000905428_9000_20190328155246';
        att.ParentId = recordId;
        return att;
    }
    
    public static Attachment insertPdfAttachment(Id recordId) {
        Attachment attach=new Attachment();  
        attach.parentId=recordId;
        attach.Name='Pdf attachment';
        Blob bodyBlob=Blob.valueOf(' Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.ContentType = 'application/pdf';
        return attach;
    }
    /* Iteration 3 End */
    
    /** Inserting IFv2_Request__c object **/
    public static list<IFv2_Request__c> createRequestWithExt(){
        list<IFv2_Request__c> lstsObj = new list<IFv2_Request__c>(); 
        IFv2_RequestExtension1__c ext1 = new IFv2_RequestExtension1__c();
        IFv2_RequestExtension2__c ext2 = new IFv2_RequestExtension2__c();
        IFv2_RequestExtension3__c ext3 = new IFv2_RequestExtension3__c();
        insert ext1;
        insert ext2;
        insert ext3;
        for (Integer i= 0 ; i < testDataSize ; i++){
            IFv2_Request__c obj = new IFv2_Request__c(); 
            
            obj.Status__c = 'Submitted' ;
            obj.RequestExtension1__c = ext1.Id;
            obj.RequestExtension2__c = ext2.id;
            obj.RequestExtension3__c = ext3.id;
            lstsObj.add(obj);
        }   
        return lstsObj;
    }
    
    /** Inserting IFv2_Request__c object **/
    public static LIST<IFv2_Request__c> createRequestForScan(Id scanId) {
        LIST<IFv2_Request__c> requestLIST = new LIST<IFv2_Request__c>();
        LIST<Account> extensionAccountLIST = new LIST<Account>();
        MAP<Id,String> scanIdNameMap = new MAP<Id,String>();
        User newUser = [SELECT Id,Name,DelegatedApproverId FROM User limit 1];
        
        
        LIST<Id> userIds = new LIST<Id>();
        userIds.add(newUser.Id);
        for(Scan__c scan : [SELECT Id,Name FROM Scan__c WHERE Id =: scanId]) {
            scanIdNameMap.put(scan.Id, scan.Name);
        }
        
        for (Integer i= 0 ; i < testDataSize ; i++){
            IFv2_Request__c request = new IFv2_Request__c();
            request.Scan__c = scanId; 
            request.Workflow__c = 'eSignature';
            request.Status__c = 'Submitted';
            request.Approver1__c = newUser.Id;
            request.Approver2__c = newUser.Id;
            requestLIST.add(request);
        }
        insert requestLIST;
        
        for(IFv2_Request__c req: requestLIST) {
            Account acc = new Account();
            acc.Name = 'Test Account';
            acc.IFv2_Request__c = req.Id;
            acc.IFv2_SalesforceID__c = scanIdNameMap.get(req.Scan__c);
            acc.IFv2_SequenceNumber__c = '';
            acc.IFv2_WorkflowNumber__c = '03';
            acc.IFv2_InvoiceNumber__c = 'AB190018';
            acc.IFv2_FiscalYear__c = '2018';
            extensionAccountLIST.add(acc);
        }
        insert extensionAccountLIST;
        
        requestLIST[0].Account__c = extensionAccountLIST[0].Id;
        update requestLIST;
        return requestLIST;
    }
    
    Public static LIST<IFv2_AdminOnly__c> adminOnlyRecords(){
        String outofofficelogsrecordtypeid = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('OutOfOfficeLogs').getRecordTypeId();
        
        LIST<IFv2_AdminOnly__c> adminOnlyLIST = new LIST<IFv2_AdminOnly__c>();
        for (Integer i= 0 ; i < testDataSize ; i++){
            IFv2_AdminOnly__c adminOnly = new IFv2_AdminOnly__c();
            adminOnly.WorkflowName__c ='eSignature';
            adminOnly.Active__c = true;
            adminOnly.RecordTypeId= outofofficelogsrecordtypeid;
            adminOnlyLIST.add(adminOnly);
        }
        return adminOnlyLIST;
    }
    
    
}