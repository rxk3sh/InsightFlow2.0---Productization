/*******************************************************************************************************
* 
* @ Name    	:   IFv2_FieldSetFormControllerTest
* @ Purpose 	:   Test data for fieldset preparation
* @ Author  	:   Madhura Vani
* @ Class Name 	:	IFv2_FieldSetFormController
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   20-11-2018      |  madhuravani.b@absyz.com      |  1.0          |  Initial Version
*
*******************************************************************************************************/
@isTest
public class IFv2_FieldSetFormControllerTest {
    
    public static list<IFv2_Request__c> lstsObject ;
    public static IFv2_Workflow__c objWF;
    public static User objUser;
    @testsetup static void createTestData() {
        objUser = IFv2_testDataUtility.createUser(); //inserting Workflow object
        objUser.IFv2_ByPassValidation__c = true;
        insert objUser;
        
        system.runAs(objUser)
        {
            lstsObject = IFv2_testDataUtility.createRequest();  //inserting Request  
            insert lstsObject ;
        }
        
        objUser.IFv2_ByPassValidation__c = false;
        update objUser;
    }
    
    static testMethod void prepareDataCusObject(){
        Test.startTest();
        //objWF = [select id,name,Workflow__c from IFv2_Workflow__c];
        lstsObject = [select id,Approver1__c,Account__c,FreightPrice__c,Currency__c,Workflow__c,ApprovalRoute__c,iFreightPlant__c from IFv2_Request__c Limit 1];
        lstsObject[0].Workflow__c = 'Approval Process for Special Freights';
        //lstsObject[0].FreightPrice__c = 2500;
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'Approval Process for Special Freights');
        Account objAcc = new Account();
        objacc.Name = 'Test Account';
        insert objAcc;
        
        
        IFv2_Workflow__c obj = new IFv2_Workflow__c();
        obj.Name = lstsObject[0].Workflow__c;
        obj.Workflow__c = 'Approval Process for Special Freights';
        insert obj;
        
        IFv2_RequestExtension1__c objExt = new IFv2_RequestExtension1__c();
        objExt.Name = 'Test';
        insert objExt;
        
        IFv2_ExchangeRate__c record = new IFv2_ExchangeRate__c();
        record.Name = 'test';
        record.CurrencyFrom__c = 'INR';
        record.CurrencyTo__c = 'USD';
        record.Rate__c = 70;
        record.ValidFrom__c = system.today() - 30;
        record.ValidTill__c = system.today() + 30;
        insert record;
        System.assertEquals(true, record.CurrencyFrom__c == 'INR');
        System.assertEquals(true, record.Rate__c == 70);
        
        IFv2_FieldSetFormController.getForm('IFv2_Request__c', lstsObject[0].id, 'Custom Object');
        string strRecord = '[{"key":"Account__c","value":{"Plant__c":"SGNA","Id":"0010D00000AVfaXQAT","IFv2_TransportationType__c":"Outbound","IFv2_CausesforSpecialFreightDelivery__c":"MAE breakdown (MAZE, spare parts)"}}]';
        IFv2_FieldSetFormController.saveRecords(JSON.serialize(lstsObject[0]) ,strRecord,'IFv2_Request__c','Custom Object',true,JSON.serialize(lstsObject[0])); 
        IFv2_FieldSetFormController.mapWrapper wrapperInstance = new IFv2_FieldSetFormController.mapWrapper();
        try{
            IFv2_FieldSetFormController.saveExtensionRecord(lstsObject[0].id,strRecord,'IFv2_Request__c');
        } catch (TypeException ee) {
            System.assertEquals(
                'Procedure is only valid for System.DmlException and System.MailException',
                ee.getMessage()
            );
        }
        
        lstsObject[0].Workflow__c = 'China MAE Application - Capitalize';
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'China MAE Application - Capitalize');
        IFv2_FieldSetFormController.getForm('IFv2_Request__c', lstsObject[0].id, 'Custom Object');
        IFv2_FieldSetFormController.getForm('IFv2_Workflow__c', '', 'Custom Setting');
        Test.stopTest();
        
    }
    static testMethod void prepareDataCusSettings(){
        Test.startTest();
        lstsObject = [select id,Approver1__c,Account__c,Workflow__c,FreightPrice__c,Currency__c,ApprovalRoute__c,iFreightPlant__c from IFv2_Request__c];
        lstsObject[0].Workflow__c = 'Approval Process for Special Freights';
        lstsObject[0].FreightPrice__c = 1500;
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'Approval Process for Special Freights');
        
        IFv2_Workflow__c obj = new IFv2_Workflow__c();
        obj.Name = lstsObject[0].Workflow__c;
        obj.Workflow__c = 'Approval Process for Special Freights';
        insert obj;
        System.assertEquals(true, obj.Workflow__c == 'Approval Process for Special Freights');
        
        IFv2_FieldSetFormController.getForm('IFv2_Request__c', obj.id, 'Custom Setting');
        MAP<string,Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('IFv2_Request__c').getDescribe().fields.getMap();
        
        IFv2_FieldSetFormController.getRoleApproverMapping(lstsObject[0],null,JSON.serialize(lstsObject[0]),'IFv2_Request__c',fieldMap);
        IFv2_FieldSetFormController.getPurchasingApproval('Global','Global','Indirect Purchasing Approval');
        
    }
    
    static testMethod void prepareDataMAE(){
        Test.startTest();
        lstsObject = [select id,Approver1__c,Account__c,Workflow__c,ApprovalRoute__c,iFreightPlant__c,Total__c,MAEClassification__c,TypeofInvestment__c from IFv2_Request__c];
        lstsObject[0].Workflow__c = 'MAE Approval Request';
        lstsObject[0].Total__c = 100.00;
        lstsObject[0].MAEClassification__c = 'IT';
        lstsObject[0].TypeofInvestment__c = 'MAE (with EWAK)';
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'MAE Approval Request');
        System.assertEquals(true, lstsObject[0].Total__c == 100.00);
        
    }
    
    static testMethod void prepareDataPredefinedWF(){
        Test.startTest();
        lstsObject = [select id,Approver1__c,RegionPredefinedWF__c,iFreightPlant__c,ApprovalRoute__c from IFv2_Request__c];
        lstsObject[0].Workflow__c = 'Predefined Workflow Approvals';
        lstsObject[0].RegionPredefinedWF__c = 'LA';
        lstsObject[0].PredefinedWorkflow__c = 'Product Release Request SG';
        lstsObject[0].Subcategory__c = 'Liberação AA => GE e CV-GE';
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'Predefined Workflow Approvals');
        System.assertEquals(true, lstsObject[0].RegionPredefinedWF__c == 'LA');
        
    }
    
    static testMethod void prepareDataPersonnelRequest(){
        Test.startTest();
        lstsObject = [select id,Approver1__c,ApprovalRoute__c,PersonnelType__c,iFreightPlant__c from IFv2_Request__c];
        lstsObject[0].Workflow__c = 'Personnel Request';
        lstsObject[0].ApprovalRoute__c = 'SGHU, Trainee';
        lstsObject[0].PersonnelType__c = '';
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'Personnel Request');
        System.assertEquals(true, lstsObject[0].ApprovalRoute__c == 'SGHU, Trainee');
        
    }
    
    static testMethod void prepareDataPersonnelRequest1(){
        Test.startTest();
        lstsObject = [select id,Approver1__c,ApprovalRoute__c,PersonnelType__c,iFreightPlant__c from IFv2_Request__c];
        lstsObject[0].Workflow__c = 'Personnel Request';
        lstsObject[0].ApprovalRoute__c = 'SG DE St';
        lstsObject[0].PersonnelType__c = 'Special working conditions – Praktikant'; 
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'Personnel Request');
        System.assertEquals(true, lstsObject[0].ApprovalRoute__c == 'SG DE St');
    }
    
    static testMethod void naJournalRequest1(){
        
        IFv2_Request__c ifv2_requestold = new IFv2_Request__c();
        ifv2_requestold.Workflow__c = 'NA Journal Entry Application';
        ifv2_requestold.Division__c ='SGMX';
        insert ifv2_requestold;
        System.assertEquals(true, ifv2_requestold.Workflow__c == 'NA Journal Entry Application');
        
        IFv2_Request__c ifv2_request = new IFv2_Request__c();
        ifv2_request.Workflow__c = 'NA Journal Entry Application';
        ifv2_request.Division__c ='SGMX';
        insert ifv2_request;
        System.assertEquals(true, ifv2_request.Workflow__c == 'NA Journal Entry Application');
        
        string strRecord = '[{"key":"Account__c"}]';
        IFv2_FieldSetFormController.saveRecords(JSON.serialize(ifv2_request) ,strRecord,'IFv2_Request__c','Custom Object',true,JSON.serialize(ifv2_requestold)); 
    }
    
    static testMethod void naJournalRequest2(){
        
        IFv2_Request__c ifv2_requestOld = new IFv2_Request__c();
        ifv2_requestOld.Workflow__c = 'NA Journal Entry Application';
        ifv2_requestOld.Division__c ='SGMX';
        insert ifv2_requestOld;
        System.assertEquals(true, ifv2_requestold.Workflow__c == 'NA Journal Entry Application');
        
        IFv2_Request__c ifv2_request = new IFv2_Request__c();
        ifv2_request.Workflow__c = 'NA Journal Entry Application';
        ifv2_request.Division__c ='SGMX';
        insert ifv2_request;
        System.assertEquals(true, ifv2_request.Workflow__c == 'NA Journal Entry Application');
        
        string strRecord = '[{"key":"Account__c"}]';
        IFv2_FieldSetFormController.saveRecords(JSON.serialize(ifv2_request),strRecord,'IFv2_Request__c','Custom Object',true,JSON.serialize(ifv2_requestOld)); 
    }
    
    static testMethod void chinaTravelRequest1(){
        
        IFv2_RequestExtension1__c extension = new IFv2_RequestExtension1__c();
        extension.TotalPlannedDuration__c = 6;
        insert extension;
        System.assertEquals(true, extension.TotalPlannedDuration__c == 6);
        
        IFv2_Request__c ifv2_requestOld = new IFv2_Request__c();
        ifv2_requestOld.Workflow__c = 'China Travel Application';
        ifv2_requestOld.RequestExtension1__c = extension.Id;
        ifv2_requestOld.TravelType__c = 'Business - Overseas';
        insert ifv2_requestOld;
        System.assertEquals(true, ifv2_requestOld.Workflow__c == 'China Travel Application');
        
        IFv2_Request__c ifv2_request = new IFv2_Request__c();
        ifv2_request.Workflow__c = 'China Travel Application';
        ifv2_request.RequestExtension1__c = extension.Id;
        ifv2_request.TravelType__c = 'Business - Domestic';
        insert ifv2_request;
        System.assertEquals(true, ifv2_request.Workflow__c == 'China Travel Application');
        
        string strRecord = '[{"key":"Account__c"}]';
        try{
            IFv2_FieldSetFormController.saveRecords(JSON.serialize(ifv2_request),strRecord,'IFv2_Request__c','Custom Object',true,JSON.serialize(ifv2_requestOld)); 
        }
        Catch(Exception e){}
    }
    
    static testMethod void chinaTravelRequest2(){
        
        IFv2_RequestExtension1__c extension = new IFv2_RequestExtension1__c();
        extension.TotalPlannedDuration__c = 6;
        insert extension;
        
        IFv2_Request__c ifv2_requestOld = new IFv2_Request__c();
        ifv2_requestOld.Workflow__c = 'China Travel Application';
        ifv2_requestOld.RequestExtension1__c = extension.Id;
        ifv2_requestOld.TravelType__c = 'Business - Overseas';
        insert ifv2_requestOld;
        System.assertEquals(true, ifv2_requestOld.Workflow__c == 'China Travel Application');
        
        IFv2_Request__c ifv2_request = new IFv2_Request__c();
        ifv2_request.Workflow__c = 'China Travel Application';
        ifv2_request.RequestExtension1__c = extension.Id;
        ifv2_request.TravelType__c = 'Business - Domestic';
        insert ifv2_request;
        System.assertEquals(true, ifv2_request.Workflow__c == 'China Travel Application');
        
        string strRecord = '[{"key":"RequestExtension1__c","value":{"TotalPlannedDuration__c":"7"}}]';
        try{
            IFv2_FieldSetFormController.saveRecords(JSON.serialize(ifv2_request),strRecord,'IFv2_Request__c','Custom Object',true,JSON.serialize(ifv2_requestOld)); 
        }
        Catch(Exception e){}
    }
    
    
    static testMethod void prepareDataSpecialFreights(){
        Test.startTest();
        objUser = [select id,iFreight_Plant__c from user limit 1];
        System.assertEquals(true, objUser != Null);
        
        lstsObject = [select id,Approver1__c,iFreightPlant__c,FreightPrice__c,Currency__c,ApprovalRoute__c from IFv2_Request__c];
        lstsObject[0].Workflow__c = 'Approval Process for Special Freights';
        lstsObject[0].FromDate__c=System.today();
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'Approval Process for Special Freights');
        System.assertEquals(true, lstsObject[0].FromDate__c == System.today());
        
        date d1 = date.newinstance(2016,01,12);
    }
    
    static testMethod void getPurchasingApproval(){
        Test.startTest();
        
        lstsObject = [select id,Approver1__c,Account__c,FreightPrice__c,Currency__c,Workflow__c,ApprovalRoute__c,iFreightPlant__c from IFv2_Request__c];
        lstsObject[0].Workflow__c = 'Indirect Purchasing Approval';
        update lstsObject;
        
        IFv2_Workflow__c obj = new IFv2_Workflow__c();
        obj.Name = lstsObject[0].Workflow__c;
        obj.Workflow__c = 'Indirect Purchasing Approval';
        insert obj;
        system.assertEquals('Indirect Purchasing Approval', obj.Workflow__c);
        IFv2_FieldSetFormController.getPurchasingApproval(null,'Agreements','Indirect Purchasing Approval');
        Test.stopTest();
    }
    
    static testMethod void getPurchasingApproval1(){
        
        Test.startTest();
        
        lstsObject = [select id,Approver1__c,Account__c,FreightPrice__c,Currency__c,Workflow__c,ApprovalRoute__c,iFreightPlant__c from IFv2_Request__c];
        lstsObject[0].Workflow__c = 'Indirect Purchasing Approval';
        update lstsObject;
        
        IFv2_Workflow__c obj = new IFv2_Workflow__c();
        obj.Name = lstsObject[0].Workflow__c;
        obj.Workflow__c = 'Indirect Purchasing Approval';
        insert obj;
        system.assertEquals('Indirect Purchasing Approval', obj.Workflow__c);
        IFv2_FieldSetFormController.getPurchasingApproval(null,'Purchasing Orders','Indirect Purchasing Approval');
        IFv2_FieldSetFormController.getDependentpickListVal(' ','Material Class','Product Class');
        Test.stopTest();
        
        
    }
    
    static testMethod void getInPurchasingApprovalRequest2(){
        
        IFv2_Request__c ifv2_requestOld = new IFv2_Request__c();
        ifv2_requestOld.Workflow__c = 'Indirect Purchasing Approval';
        ifv2_requestOld.SubjectType__c = 'Debit Notes';
        ifv2_requestOld.Role01__c = 'OL3';
        ifv2_requestOld.PurchasingArea__c = 'Packaging';
        insert ifv2_requestOld;
        System.assertEquals(true, ifv2_requestOld.Workflow__c == 'Indirect Purchasing Approval');
        
        IFv2_Request__c ifv2_request = new IFv2_Request__c();
        ifv2_request.Workflow__c = 'Indirect Purchasing Approval';
        ifv2_request.SubjectType__c = 'Debit Notes';
        ifv2_request.Role01__c = 'OL4';
        ifv2_request.PurchasingArea__c = 'Packaging';
        insert ifv2_request;
        System.assertEquals(true, ifv2_request.Workflow__c == 'Indirect Purchasing Approval');
        
        string strRecord = '[{"key":"Account__c"}]';
        IFv2_FieldSetFormController.saveRecords(JSON.serialize(ifv2_request),strRecord,'IFv2_Request__c','Custom Object',true,JSON.serialize(ifv2_requestOld)); 
        
    }
    static testMethod void getInPurchasingApprovalRequest3(){
        
        IFv2_Request__c ifv2_request = new IFv2_Request__c();
        ifv2_request.Workflow__c = 'Indirect Purchasing Approval';
        ifv2_request.SubjectType__c = 'Agreements';
        ifv2_request.Role02__c = 'OL4';
        ifv2_request.PurchasingArea__c = 'MAE - MAE1';
        insert ifv2_request;
        System.assertEquals(true, ifv2_request.Workflow__c == 'Indirect Purchasing Approval');
        
        IFv2_FieldSetFormController.FieldSetWrapper wrp = IFv2_FieldSetFormController.getForm('IFv2_Request__c', ifv2_request.Id, 'Custom Object');
        IFv2_FieldSetFormController.getRecord(new list<String>{'Id','Name','Workflow__c'}, 'IFv2_Request__c', ifv2_request, 'Custom Object', ifv2_request.Id);
        string strRecord = '[{"key":"Account__c"}]';
        IFv2_FieldSetFormController.saveRecords(JSON.serialize(ifv2_request),strRecord,'IFv2_Request__c','Custom Object',true,JSON.serialize(ifv2_request)); 
        
    }
    
    static testMethod void getInPurchasingApprovalRequest4(){
        
        IFv2_Request__c ifv2_request = new IFv2_Request__c();
        ifv2_request.Workflow__c = 'Indirect Purchasing Approval';
        ifv2_request.SubjectType__c = 'Agreements';
        ifv2_request.Region__c = 'Asia - China';
        ifv2_request.Role03__c = 'OL3';
        insert ifv2_request;
        System.assertEquals(true, ifv2_request.Workflow__c == 'Indirect Purchasing Approval');
        
        string strRecord = '[{"key":"Account__c"}]';
        IFv2_FieldSetFormController.saveRecords(JSON.serialize(ifv2_request),strRecord,'IFv2_Request__c','Custom Object',true,JSON.serialize(ifv2_request)); 
        
    }
    
    static testMethod void getChinaCaptalizeRequest1(){
        
        IFv2_Request__c ifv2_request = new IFv2_Request__c();
        ifv2_request.Workflow__c = 'China MAE Application - Capitalize';
        ifv2_request.ApplicationType__c = 'MAE';
        insert ifv2_request;
        
        System.assertEquals(true, ifv2_request.Workflow__c == 'China MAE Application - Capitalize');
        
        string strRecord = '[{"key":"Account__c"}]';
        IFv2_FieldSetFormController.saveRecords(JSON.serialize(ifv2_request),strRecord,'IFv2_Request__c','Custom Object',true,JSON.serialize(ifv2_request)); 
        
    }
    static testMethod void IFv2_TPicklistEntryTestMethod(){
        IFv2_TPicklistEntry TPicklistEntryInstance = new IFv2_TPicklistEntry();
        TPicklistEntryInstance.active = 'true';
        TPicklistEntryInstance.defaultValue = 'true';
        TPicklistEntryInstance.value = 'true';
        system.assertEquals('true',TPicklistEntryInstance.value);
    }
    
    static testMethod void prepareCusSettings1(){
        Test.startTest();
        Account objAcc = new Account();
        objacc.Name = 'Test Account';
        insert objAcc;
        System.assertEquals(true, objAcc.Name == 'Test Account');
        
        lstsObject = [select id,Approver1__c,Account__c,Workflow__c,ApprovalRoute__c,iFreightPlant__c,ProductClass__c,MaterialClass__c from IFv2_Request__c];
        lstsObject[0].Workflow__c = 'HU Scrapping WorkOn';
        lstsObject[0].Account__c = objAcc.Id;
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'HU Scrapping WorkOn');
        System.assertEquals(true, lstsObject[0].Account__c == objAcc.Id);
        
        IFv2_Workflow__c obj = new IFv2_Workflow__c();
        obj.Name = lstsObject[0].Workflow__c;
        obj.Workflow__c = 'HU Scrapping WorkOn';
        insert obj;
        System.assertEquals(true, obj.Workflow__c == 'HU Scrapping WorkOn');
        
        IFv2_FieldSetFormController.getForm('IFv2_Request__c', lstsObject[0].id, 'Custom Object');
        string strRecord = '[{"key":"Account__c","value":{"Plant__c":"SGNA","Id":"'+objAcc.Id+'","AnnualRevenue":"1000","IFv2_CapitalizedDate__c":"'+String.valueOf(System.today())+'","IFv2_ActClockOut__c":"'+String.valueOf(system.now())+'","IFv2_TransportationType__c":"Outbound","IFv2_CausesforSpecialFreightDelivery__c":"MAE breakdown (MAZE, spare parts)"}}]';
        IFv2_FieldSetFormController.saveRecords(JSON.serialize(lstsObject[0]),strRecord,'IFv2_Request__c','Custom Object',true,JSON.serialize(lstsObject[0])); 
        
        IFv2_FieldSetFormController.saveRecords('',strRecord,'IFv2_Request__c','Custom Object',true,JSON.serialize(lstsObject[0])); 
        
        
        string strField = 'Id,Name,Workflow__c,TravelType__c,BookAirTicket__c';
        list<string> lstStr = new list<string>();
        lstStr.addAll(strField.split(','));
        IFv2_RequestExtension1__c ext1= new IFv2_RequestExtension1__c(Name = 'Test', TotalPlannedDuration__c= 20);
        insert ext1;
        System.assertEquals(true, ext1.Name == 'Test');
        
        lstsObject[0].Workflow__c = 'China Travel Application';
        lstsObject[0].RequestExtension1__c=ext1.Id;
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'China Travel Application');
        System.assertEquals(true, lstsObject[0].RequestExtension1__c == ext1.Id);
        
        LIST<String> fieldNames = new LIST<String>();
        fieldNames.add('Workflow__c');
        try{
            IFv2_FieldSetFormController.refreshRecord((String)lstsObject[0].id,fieldNames,'IFv2_Request__c',true);
        }
        Catch(Exception e){}
        
        LIST<String> fieldStringLIST = new LIST<String>();
        fieldStringLIST.add('Name');
        //IFv2_FieldSetFormController.refreshRecord((String)lstsObject[0].id,fieldStringLIST,'IFv2_Workflow__c',true);
        
        // IFv2_FieldSetFormController.refreshRecord((String)lstsObject[0].id,fieldNames,'IFv2_Workflow__c',true);	//for else condition
        //IFv2_FieldSetFormController.refreshRecord(null,null,'IFv2_Workflow__c',true);	//for else condition
        
        
    }
    
    static testMethod void prepareCusSettings2(){
        lstsObject = [select id,Approver1__c,Account__c,Workflow__c,ApprovalRoute__c,iFreightPlant__c,ProductClass__c,MaterialClass__c from IFv2_Request__c];
        System.assertEquals(true, !lstsObject.isEmpty());
        
        IFv2_Workflow__c obj = new IFv2_Workflow__c();
        obj.Name = 'HU Scrapping WorkOn';
        obj.Workflow__c = 'HU Scrapping WorkOn';
        insert obj;
        System.assertEquals(true, obj.Workflow__c == 'HU Scrapping WorkOn');
        
        string strRecord = '[{"key":"Account__c","value":{"Plant__c":"SGNA","Id":"0010D00000AVfaXQAT","IFv2_TransportationType__c":"Outbound","IFv2_CausesforSpecialFreightDelivery__c":"MAE breakdown (MAZE, spare parts)"}}]';
        IFv2_FieldSetFormController.saveRecords(JSON.serialize(obj),strRecord,'IFv2_Workflow__c','Custom Setting',true,JSON.serialize(obj)); 
    }
    
    static testMethod void TStringUtilsTestMethod(){
        lstsObject = [select id,Approver1__c,Account__c,Workflow__c,ApprovalRoute__c,iFreightPlant__c,ProductClass__c,MaterialClass__c from IFv2_Request__c];
        System.assertEquals(true, !lstsObject.isEmpty());
        
        IFv2_Workflow__c obj = new IFv2_Workflow__c();
        obj.Name = 'HU Scrapping WorkOn';
        obj.Workflow__c = 'HU Scrapping WorkOn';
        insert obj;
        
        IFv2_TStringUtils.GetDependentOptions('IFv2_Request__c','Region__c','SubRegion__c');
        
    }
    static testMethod void RequiredFieldsTestMethod(){
        IFv2_FieldSetUtility.getRequiredFields('IFv2_Request__c','Overtime Request');
    }
    
    public static testMethod void getFieldsMethod(){
        IFv2_Request__c obj = new IFv2_Request__c();
        
        obj.Workflow__c = 'HU Scrapping WorkOn';
        insert obj;
        System.assertEquals(true, obj.Workflow__c == 'HU Scrapping WorkOn');
        IFv2_FieldSetUtility.getFields(obj,'IFv2_Request__c','IFv2_ApproversSet','abc');
    }
    
    static testMethod void getChinaCombineRequest(){
        
        IFv2_Request__c ifv2_request = new IFv2_Request__c();
        ifv2_request.Workflow__c = 'China MAE Application - Combine';
        ifv2_request.ApplicationType__c = 'MAE';
        insert ifv2_request;
        System.assertEquals(true, ifv2_request.Workflow__c == 'China MAE Application - Combine');
        
        string strRecord = '[{"key":"Account__c"}]';
        IFv2_FieldSetFormController.saveRecords(JSON.serialize(ifv2_request),strRecord,'IFv2_Request__c','Custom Object',true,JSON.serialize(ifv2_request)); 
        
    }
    
    static testMethod void getBadgeManagementRequest(){
        
        IFv2_Request__c ifv2_request = new IFv2_Request__c();
        ifv2_request.Workflow__c = 'Badge Management SEG - Stuttgart';
        ifv2_request.ApplicationType__c = 'MAE';
        insert ifv2_request;
        System.assertEquals(true, ifv2_request.ApplicationType__c == 'MAE');
        
        string strRecord = '[{"key":"Account__c"}]';
        IFv2_FieldSetFormController.saveRecords(JSON.serialize(ifv2_request),strRecord,'IFv2_Request__c','Custom Object',true,JSON.serialize(ifv2_request)); 
        
    }
    
    static testMethod void prepareLexExtRec(){
        Test.startTest();
        objUser = [select id from user limit 1];
        Account objAcc = new Account();
        objacc.Name = 'Test Account';
        objacc.IFv2_Nominated_LEX2__c = objUser.Id;
        objacc.IFv2_PEX_Name__c = objUser.Id;
        insert objAcc;
        System.assertEquals(true, objAcc.Name == 'Test Account');
        
        lstsObject = [select id,Approver1__c,Account__c,Workflow__c,ApprovalRoute__c,iFreightPlant__c,ProductClass__c,MaterialClass__c from IFv2_Request__c];
        lstsObject[0].Workflow__c = 'LEX Contracting - SEG Resource Agreement';
        lstsObject[0].Account__c = objAcc.Id;
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'LEX Contracting - SEG Resource Agreement');
        System.assertEquals(true, lstsObject[0].Account__c == objAcc.Id);
        
        
        IFv2_FieldSetFormController.getForm('IFv2_Request__c', lstsObject[0].id, 'Custom Object');
        string strRecord = '[{"key":"Account__c","value":{"Plant__c":"SGNA","Id":"'+objAcc.Id+'","AnnualRevenue":"1000","IFv2_CapitalizedDate__c":"'+String.valueOf(System.today())+'","IFv2_ActClockOut__c":"'+String.valueOf(system.now())+'","IFv2_TransportationType__c":"Outbound","IFv2_CausesforSpecialFreightDelivery__c":"MAE breakdown (MAZE, spare parts)"}}]';
        IFv2_FieldSetFormController.saveRecords(JSON.serialize(lstsObject[0]),strRecord,'IFv2_Request__c','Custom Object',true,JSON.serialize(lstsObject[0])); 
        
        IFv2_FieldSetFormController.saveRecords('',strRecord,'IFv2_Request__c','Custom Object',true,JSON.serialize(lstsObject[0])); 
        
        
        string strField = 'Id,Name,Workflow__c,TravelType__c,BookAirTicket__c';
        list<string> lstStr = new list<string>();
        lstStr.addAll(strField.split(','));
        IFv2_RequestExtension1__c ext1= new IFv2_RequestExtension1__c(Name = 'Test', TotalPlannedDuration__c= 20);
        insert ext1;
        System.assertEquals(true, ext1.Name == 'Test');
        
        lstsObject[0].Workflow__c = 'China Travel Application';
        lstsObject[0].RequestExtension1__c=ext1.Id;
        update lstsObject;
        System.assertEquals(true, lstsObject[0].Workflow__c == 'China Travel Application');
        System.assertEquals(true, lstsObject[0].RequestExtension1__c == ext1.Id);
        
        LIST<String> fieldNames = new LIST<String>();
        fieldNames.add('Workflow__c');
        try{
            IFv2_FieldSetFormController.refreshRecord((String)lstsObject[0].id,fieldNames,'IFv2_Request__c',true);
        }
        Catch(Exception e){}
        
        LIST<String> fieldStringLIST = new LIST<String>();
        fieldStringLIST.add('Name');
        //IFv2_FieldSetFormController.refreshRecord((String)lstsObject[0].id,fieldStringLIST,'IFv2_Workflow__c',true);
        
        // IFv2_FieldSetFormController.refreshRecord((String)lstsObject[0].id,fieldNames,'IFv2_Workflow__c',true);	//for else condition
        //IFv2_FieldSetFormController.refreshRecord(null,null,'IFv2_Workflow__c',true);	//for else condition
        
        
    }
    
    
    public static testMethod void currencyConversionMethod() {
        IFv2_ExchangeRate__c record = new IFv2_ExchangeRate__c();
        record.Name = 'test';
        record.CurrencyFrom__c = 'INR';
        record.CurrencyTo__c = 'USD';
        record.Rate__c = 70;
        record.ValidFrom__c = system.today() - 30;
        record.ValidTill__c = system.today() + 30;
        insert record;
        System.assertEquals(true, record.CurrencyTo__c == 'USD');
        System.assertEquals(true, record.CurrencyFrom__c == 'INR');
        
        String currencyQuery =  'SELECT CurrencyFrom__c,CurrencyTo__c,Rate__c,ValidFrom__c,ValidTill__c '+
            'FROM IFv2_ExchangeRate__c ';
        list<SObject> currencyConversionList = Database.query(currencyQuery);
        System.assertEquals(true, !currencyConversionList.isEmpty());
        Decimal finalAmount = IFv2_FieldSetFormController.convertCurrency(currencyConversionList, 5250, 'INR', 'USD', system.today());
    }
}