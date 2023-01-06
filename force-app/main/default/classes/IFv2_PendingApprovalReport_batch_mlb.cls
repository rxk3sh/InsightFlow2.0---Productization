/***************************************************************************************************************
* 
* @ Name            :   IFv2_PendingApprovalReport_batch_mlb
* @ Purpose         :   For sending report regarding ICO workflows
* @ Author          :   Marlabs
* @ Test class name :   IFv2_PendingApprovalReportTest,IFv2_PendingApprovalReportTest2
*
*   Date            |  Developer Name               |  Version      |  Changes
* ==================================================================================================================
*   26-03-2018      |  Marlabs   |  1.1          |   Initial version of Batch class to send ICO workflows reorts  
*
*******************************************************************************************************************/
global class IFv2_PendingApprovalReport_batch_mlb implements Database.Batchable<sObject>,Database.Stateful,schedulable {
    
    global string HEADERvALUE= 'Request Name, Salesforce ID , Company Code, WF Number , Status , Created Date , Current Approver,Current Approver Email, Invoicing Party Name,Invoicing Party (Vendor Number), Invoice Number, Fiscal Year , Item text, Purchase Order Number, Invoice Item Amount, Invoice Date, PlantSAP, Applicant First Name, Applicant Last Name, Request: Created Date, Request: Last Modified Date,Approver, Approver 2, Approver 3, Approver 4, Approver 5, Approver 6';
    global string NEWLINE= '\n';
    global string header = HEADERvALUE+NEWLINE;
    global string finalstr9000 = header;
    global string finalstr71F0 = header;  
    global string finalstr70A0 = header; 
    global string finalstr70B0= header;
    global string finalstr68C0= header;
    global string finalstr69F0= header;
    global string finalstr69D0 = header;  
    global string finalstr68D0 = header; 
    global string finalstr68F0= header;
    global string finalstr69A0= header;
    global string finalstr69C0= header;
    global string finalstr71D0= header;
    global String PLAINTEXT;
    global String[] toAddresses9000 = new list<string>();
    global String[] toAddresses71F0 = new list<string>();
    global String[] toAddresses71D0 = new list<string>();
    global String[] toAddresses70A0 = new list<string>();
    global String[] toAddresses70B0 = new list<string>();
    global String[] toAddresses68C0 = new list<string>();
    global String[] toAddresses69F0 = new list<string>();
    global String[] toAddresses69D0 = new list<string>();
    global String[] toAddresses68D0 = new list<string>();
    global String[] toAddresses68F0 = new list<string>();
    global String[] toAddresses69A0 = new list<string>();
    global String[] toAddresses69C0 = new list<string>();
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, ProcessDefinitionID, ProcessDefinition.name, TargetObjectId, TargetObject.name, status, CreatedDate,lastModifiedDate '+
            '			FROM ProcessInstance where status = \'pending\' and ProcessDefinition.name like \'%ICO%\' ';
        return Database.getQueryLocator(query);
        
    }
    
    // Execute method
    
    global void execute(Database.BatchableContext BC, List<ProcessInstance> scope) {
        
        if (finalstr9000 != header )
        {
            // finalstr9000 = header;
        }
        
        List<ProcessInstance> ProcessInstanceList = new List<ProcessInstance>();
        ProcessInstanceList = scope; system.debug('count = '+ProcessInstanceList.size());
        
        string SEPERATOR= '"';
        string SEPERATORcOLUMN= '","';
        string ENDLINE= '"\n';
        //string PLAINTEXT= 'All APM Pending Approval CSV ';
        String SUBJECT ='All APM Pending Approval Report for Company Code: ';
        String tempSUBJECTBLANK = '';
        String tempSUBJECT;
        String csvname= 'All APM Pending Approval.csv';
        string code9000= '9000';
        string code71F0= '71F0';
        string code70A0= '70A0';
        string code70B0= '70B0';
        string code68C0= '68C0';
        string code69F0= '69F0'; 
        string code71D0= '71D0';
        string code69D0= '69D0';
        string code68D0= '68D0';
        string code68F0= '68F0';
        string code69A0= '69A0';
        string code69C0= '69C0';
        string varApprover;
        string varApprover2;
        string varApprover3;
        string varApprover4;
        string varApprover5;
        string varApprover6;
        string BLANKVALUE= 'NA';
        String sMessage;
        PLAINTEXT = '<html lang="en"><body>'+
            'Dear User,'+
            '<br><br>'+
            'Pending APM workflow report is generated for your company code. Please find attached the report.'+
            '<br><br>'+
            'Best Regards,'+
            '<br>'+
            'Salesforce System Admin'+
            '<br>'+
            '-----------------------------------------------------------------------------------'+
            '<br>'+
            'Please do not reply to this automatically generated e-mail.'+
            '<b>'+
            '</body></html>';   
        
        Map<Id, string> mapWorkitem= new Map<Id, string>();
        Map<Id, string> approversEmailsMap = new Map<Id, string>();
        List<ProcessInstanceWorkItem> ProcessInstanceWorkItemList = [Select ProcessInstanceId, Actorid, Actor.name,Actor.Email from ProcessInstanceWorkItem limit 50000];
        for(ProcessInstanceWorkItem piw : ProcessInstanceWorkItemList) {
            mapWorkitem.put(piw.ProcessInstanceId,piw.Actor.name);
            approversEmailsMap.put(piw.ProcessInstanceId,piw.Actor.Email);
        }
        
        Map<Id, User> UserList = new Map<Id, User>([Select id, Name from User where isActive = True]);
        Map<Id, IFV2_Request__c > RequestList = new  Map<Id, IFV2_Request__c >([SELECT Id, Name,  Status__c, CompanyCode__c, CreatedDate, lastModifiedDate, Account__r.IFv2_SalesforceID__c, 
                                                                                Account__r.IFv2_WorkflowNumber__c, Workflow__c,Account__r.IFv2_InvoicingPartyvendornumber__c, 
                                                                                Account__r.IFv2_InvoicingPartyvendorname__c, Account__r.IFv2_InvoiceNumber__c, 
                                                                                Account__r.IFv2_FiscalYear__c, Account__r.IFv2_ItemText__c, 
                                                                                Account__r.IFv2_PurchaseOrderNumber__c, InvoiceItemAmount__c, 
                                                                                InvoiceDateDocumentDate__c, 
                                                                                Account__r.IFv2_PlantSAP__c,ApplicantFirstName__c,ApplicantLastName__c,
                                                                                Approver1__c, Approver2__c, Approver3__c, Approver4__c, Approver5__c, Approver6__c 
                                                                                FROM IFV2_Request__c  where Workflow__c like '%ICO%' 
                                                                                AND Status__c = 'submitted' 
                                                                                AND (CompanyCode__c = '9000' OR CompanyCode__c = '71F0' 
                                                                                     OR CompanyCode__c = '71D0' OR CompanyCode__c = '70A0' 
                                                                                     OR CompanyCode__c = '70B0' OR CompanyCode__c = '68C0'
                                                                                     OR CompanyCode__c = '69F0' OR CompanyCode__c = '69D0' 
                                                                                     OR CompanyCode__c = '68D0' OR CompanyCode__c = '68F0' 
                                                                                     OR CompanyCode__c = '69A0' OR CompanyCode__c = '69C0')]);
        if(ProcessInstanceList.size() > 0) {
            for ( ProcessInstance pi : ProcessInstanceList) {
                IFv2_Request__c wr = RequestList.get(pi.TargetObjectId);
                Try {  
                    // To store Pending Approval data on the basis of Company code.
                    if(wr != null) {                  
                        if (UserList.get(wr.Approver1__c) != Null) {
                            User uApprover = UserList.get(wr.Approver1__c);
                            varApprover = uApprover.Name;
                        }
                        else
                            varApprover = BLANKVALUE; 
                        if (UserList.get(wr.Approver2__c) != Null) {                
                            User uApprover2 = UserList.get(wr.Approver2__c);
                            varApprover2 = uApprover2.Name;
                        }
                        else
                            varApprover2 = BLANKVALUE;
                        if (UserList.get(wr.Approver3__c) != Null) {                
                            User uApprover3 = UserList.get(wr.Approver3__c);
                            varApprover3 = uApprover3.Name;
                        }
                        else
                            varApprover3 = BLANKVALUE;
                        if (UserList.get(wr.Approver4__c) != Null) {                
                            User uApprover4 = UserList.get(wr.Approver4__c);
                            varApprover4 = uApprover4.Name;
                        }
                        else
                            varApprover4 = BLANKVALUE;  
                        if (UserList.get(wr.Approver5__c) != Null) {                
                            User uApprover5 = UserList.get(wr.Approver5__c);
                            varApprover5 = uApprover5.Name;
                        }
                        else
                            varApprover5 = BLANKVALUE; 
                        if (UserList.get(wr.Approver6__c) != Null) {                
                            User uApprover6 = UserList.get(wr.Approver6__c);
                            varApprover6 = uApprover6.Name;
                        }
                        else
                            varApprover6 = BLANKVALUE;   
                        
                        if(wr.CompanyCode__c == code9000) { 
                            //string recordString9000 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+uApprover.Name+SEPERATORcOLUMN+wr.Approver2__c+SEPERATORcOLUMN+wr.Approver3__c+SEPERATORcOLUMN+wr.Approver4__c+SEPERATORcOLUMN+wr.Approver5__c+SEPERATORcOLUMN+wr.Approver6__c +ENDLINE;
                            string recordString9000 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+wr.ApplicantFirstName__c+SEPERATORcOLUMN+ wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate+SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr9000 = finalstr9000 +recordString9000; 
                            
                        }
                        else if(wr.CompanyCode__c == code71F0) {
                            string recordString71F0 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+wr.ApplicantFirstName__c+SEPERATORcOLUMN+ wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate+SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr71F0 = finalstr71F0 +recordString71F0;
                        } 
                        else if(wr.CompanyCode__c == code70A0) {
                            string recordString70A0 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+wr.ApplicantFirstName__c+SEPERATORcOLUMN+ wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate+SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr70A0 = finalstr70A0 +recordString70A0;
                        }     
                        else if(wr.CompanyCode__c == code70B0) {
                            string recordString70B0 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+wr.ApplicantFirstName__c+SEPERATORcOLUMN+ wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate+SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr70B0 = finalstr70B0 +recordString70B0;
                        }     
                        else if(wr.CompanyCode__c == code68C0) {
                            string recordString68C0 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+wr.ApplicantFirstName__c+SEPERATORcOLUMN+ wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate+SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr68C0 = finalstr68C0 +recordString68C0;
                        }  
                        else if(wr.CompanyCode__c == code69F0) {
                            string recordString69F0 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+wr.ApplicantFirstName__c+SEPERATORcOLUMN+wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate+SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr69F0 = finalstr69F0 +recordString69F0;
                        } 
                        else if(wr.CompanyCode__c == code69D0) {
                            string recordString69D0 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+wr.ApplicantFirstName__c+SEPERATORcOLUMN+wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate+SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr69D0 = finalstr69D0 +recordString69D0;
                        }
                        else if(wr.CompanyCode__c == code68D0) {
                            string recordString68D0 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+wr.ApplicantFirstName__c+SEPERATORcOLUMN+wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate+SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr68D0 = finalstr68D0 +recordString68D0;
                        }
                        else if(wr.CompanyCode__c == code71D0) {
                            string recordString71D0 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+wr.ApplicantFirstName__c+SEPERATORcOLUMN+wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate+SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr71D0 = finalstr71D0 +recordString71D0;
                        }
                        else if(wr.CompanyCode__c == code68F0) {
                            string recordString68F0 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+wr.ApplicantFirstName__c+SEPERATORcOLUMN+wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate+SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr68F0 = finalstr68F0 +recordString68F0;
                        }
                        else if(wr.CompanyCode__c == code69A0) {
                            string recordString69A0 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+wr.ApplicantFirstName__c+SEPERATORcOLUMN+wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate+SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr69A0 = finalstr69A0 +recordString69A0;
                        }
                        else if(wr.CompanyCode__c == code69C0) {
                            string recordString69C0 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+wr.ApplicantFirstName__c+SEPERATORcOLUMN+wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate+SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr69C0 = finalstr69C0 +recordString69C0;
                        }
                    }
                }
                catch (exception ex) {                     
                    sMessage = 'ERROR: ' + 'An exception has occurred. Please contact your System Administrator quoting the following message -- '+ ex.getTypeName() + ':'+ex.getMessage() + ':' + ex.getLineNumber() + ':' + ex.getStackTraceString();
                    System.debug('All APM report Exception: '+ sMessage);
                }
            }    
            
            // To retreive email Id from Custom setting
            List<All_Pending_Approval__c> allPendingApprovalList = [Select Name, Company_Code__c, Pex_Email1__c, Pex_Email2__c, Pex_Email3__c, Pex_Email4__c, Pex_Email5__c, Pex_Email6__c from All_Pending_Approval__c limit 50000];
            Map<String, All_Pending_Approval__c> mapCustomSetting= new Map<String, All_Pending_Approval__c>();
            
            if(allPendingApprovalList.size() > 0) {
                for (All_Pending_Approval__c csVar : allPendingApprovalList) {
                    mapCustomSetting.put(csVar.Company_Code__c,csVar); 
                } 
                
                // sending mail for Company code9000
                if(mapCustomSetting.containsKey(code9000) && finalstr9000 != null){
                    //toAddresses.clear();
                    if(mapCustomSetting.get(code9000).Pex_Email1__c != null) {
                        toAddresses9000.add(mapCustomSetting.get(code9000).Pex_Email1__c);
                    }
                    if(mapCustomSetting.get(code9000).Pex_Email2__c != null) {
                        toAddresses9000.add(mapCustomSetting.get(code9000).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code9000).Pex_Email3__c != null) {
                        toAddresses9000.add(mapCustomSetting.get(code9000).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code9000).Pex_Email4__c != null) {
                        toAddresses9000.add(mapCustomSetting.get(code9000).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code9000).Pex_Email5__c != null) {
                        toAddresses9000.add(mapCustomSetting.get(code9000).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code9000).Pex_Email6__c != null) {
                        toAddresses9000.add(mapCustomSetting.get(code9000).Pex_Email6__c);
                    } 
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code9000;
                    // sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr9000);
                }
                
                // sending mail for Company code71F0
                if(mapCustomSetting.containsKey(code71F0) && finalstr71F0 != null){ 
                    //toAddresses.clear();
                    if(mapCustomSetting.get(code71F0).Pex_Email1__c != null) {
                        toAddresses71F0.add(mapCustomSetting.get(code71F0).Pex_Email1__c);
                    } 
                    if(mapCustomSetting.get(code71F0).Pex_Email2__c != null) {
                        toAddresses71F0.add(mapCustomSetting.get(code71F0).Pex_Email2__c);
                    }
                    if(mapCustomSetting.get(code71F0).Pex_Email3__c != null) {
                        toAddresses71F0.add(mapCustomSetting.get(code71F0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code71F0).Pex_Email4__c != null) {
                        toAddresses71F0.add(mapCustomSetting.get(code71F0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code71F0).Pex_Email5__c != null) {
                        toAddresses71F0.add(mapCustomSetting.get(code71F0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code71F0).Pex_Email6__c != null) {
                        toAddresses71F0.add(mapCustomSetting.get(code71F0).Pex_Email6__c);
                    }                      
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code71F0;
                    // sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr71F0);
                }
                
                // sending mail for Company code70A0
                if(mapCustomSetting.containsKey(code70A0) && finalstr70A0 != null){ 
                    // toAddresses.clear();
                    if(mapCustomSetting.get(code70A0).Pex_Email1__c != null) {
                        toAddresses70A0.add(mapCustomSetting.get(code70A0).Pex_Email1__c);
                    } 
                    if(mapCustomSetting.get(code70A0).Pex_Email2__c != null) {
                        toAddresses70A0.add(mapCustomSetting.get(code70A0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code70A0).Pex_Email3__c != null) {
                        toAddresses70A0.add(mapCustomSetting.get(code70A0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code70A0).Pex_Email4__c != null) {
                        toAddresses70A0.add(mapCustomSetting.get(code70A0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code70A0).Pex_Email5__c != null) {
                        toAddresses70A0.add(mapCustomSetting.get(code70A0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code70A0).Pex_Email6__c != null) {
                        toAddresses70A0.add(mapCustomSetting.get(code70A0).Pex_Email6__c);
                    }    
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code70A0;                    
                    // sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr70A0);
                }   
                
                // sending mail for Company code70B0
                if(mapCustomSetting.containsKey(code70B0) && finalstr70B0 != null){ 
                    //toAddresses.clear();
                    if(mapCustomSetting.get(code70B0).Pex_Email1__c != null) {
                        toAddresses70B0.add(mapCustomSetting.get(code70B0).Pex_Email1__c);
                    } 
                    if(mapCustomSetting.get(code70B0).Pex_Email2__c != null) {
                        toAddresses70B0.add(mapCustomSetting.get(code70B0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code70B0).Pex_Email3__c != null) {
                        toAddresses70B0.add(mapCustomSetting.get(code70B0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code70B0).Pex_Email4__c != null) {
                        toAddresses70B0.add(mapCustomSetting.get(code70B0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code70B0).Pex_Email5__c != null) {
                        toAddresses70B0.add(mapCustomSetting.get(code70B0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code70B0).Pex_Email6__c != null) {
                        toAddresses70B0.add(mapCustomSetting.get(code70B0).Pex_Email6__c);
                    } 
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code70B0;                     
                    // sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr70B0);
                }
                // sending mail for Company code68C0
                if(mapCustomSetting.containsKey(code68C0) && finalstr68C0 != null){ 
                    //toAddresses.clear();
                    if(mapCustomSetting.get(code68C0).Pex_Email1__c != null) {
                        toAddresses68C0.add(mapCustomSetting.get(code68C0).Pex_Email1__c);
                    } 
                    if(mapCustomSetting.get(code68C0).Pex_Email2__c != null) {
                        toAddresses68C0.add(mapCustomSetting.get(code68C0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code68C0).Pex_Email3__c != null) {
                        toAddresses68C0.add(mapCustomSetting.get(code68C0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code68C0).Pex_Email4__c != null) {
                        toAddresses68C0.add(mapCustomSetting.get(code68C0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code68C0).Pex_Email5__c != null) {
                        toAddresses68C0.add(mapCustomSetting.get(code68C0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code68C0).Pex_Email6__c != null) {
                        toAddresses68C0.add(mapCustomSetting.get(code68C0).Pex_Email6__c);
                    } 
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code68C0;                      
                    // sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr68C0);
                }   
                // sending mail for Company code69F0
                if(mapCustomSetting.containsKey(code69F0) && finalstr69F0 != null){ 
                    //toAddresses69F.clear();
                    if(mapCustomSetting.get(code69F0).Pex_Email1__c != null) {
                        toAddresses69F0.add(mapCustomSetting.get(code69F0).Pex_Email1__c);
                    } 
                    if(mapCustomSetting.get(code69F0).Pex_Email2__c != null) {
                        toAddresses69F0.add(mapCustomSetting.get(code69F0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code69F0).Pex_Email3__c != null) {
                        toAddresses69F0.add(mapCustomSetting.get(code69F0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code69F0).Pex_Email4__c != null) {
                        toAddresses69F0.add(mapCustomSetting.get(code69F0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code69F0).Pex_Email5__c != null) {
                        toAddresses69F0.add(mapCustomSetting.get(code69F0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code69F0).Pex_Email6__c != null) {
                        toAddresses69F0.add(mapCustomSetting.get(code69F0).Pex_Email6__c);
                    }   
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code69F0;                      
                    // sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr69F0);
                } 
                if(mapCustomSetting.containsKey(code71D0) && finalstr71D0 != null){
                    //toAddresses.clear();
                    if(mapCustomSetting.get(code71D0).Pex_Email1__c != null) {
                        toAddresses71D0.add(mapCustomSetting.get(code71D0).Pex_Email1__c);
                    }
                    if(mapCustomSetting.get(code71D0).Pex_Email2__c != null) {
                        toAddresses71D0.add(mapCustomSetting.get(code71D0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code71D0).Pex_Email3__c != null) {
                        toAddresses71D0.add(mapCustomSetting.get(code71D0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code71D0).Pex_Email4__c != null) {
                        toAddresses71D0.add(mapCustomSetting.get(code71D0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code71D0).Pex_Email5__c != null) {
                        toAddresses71D0.add(mapCustomSetting.get(code71D0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code71D0).Pex_Email6__c != null) {
                        toAddresses71D0.add(mapCustomSetting.get(code71D0).Pex_Email6__c);
                    } 
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code71D0;
                    // sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr9000);
                }
                if(mapCustomSetting.containsKey(code69D0) && finalstr69D0 != null){
                    //toAddresses.clear();
                    if(mapCustomSetting.get(code69D0).Pex_Email1__c != null) {
                        toAddresses69D0.add(mapCustomSetting.get(code69D0).Pex_Email1__c);
                    }
                    if(mapCustomSetting.get(code69D0).Pex_Email2__c != null) {
                        toAddresses69D0.add(mapCustomSetting.get(code69D0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code69D0).Pex_Email3__c != null) {
                        toAddresses69D0.add(mapCustomSetting.get(code69D0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code69D0).Pex_Email4__c != null) {
                        toAddresses69D0.add(mapCustomSetting.get(code69D0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code69D0).Pex_Email5__c != null) {
                        toAddresses69D0.add(mapCustomSetting.get(code69D0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code69D0).Pex_Email6__c != null) {
                        toAddresses69D0.add(mapCustomSetting.get(code69D0).Pex_Email6__c);
                    } 
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code69D0;
                    // sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr9000);
                }
                if(mapCustomSetting.containsKey(code68D0) && finalstr68D0 != null){
                    //toAddresses.clear();
                    if(mapCustomSetting.get(code68D0).Pex_Email1__c != null) {
                        toAddresses68D0.add(mapCustomSetting.get(code68D0).Pex_Email1__c);
                    }
                    if(mapCustomSetting.get(code68D0).Pex_Email2__c != null) {
                        toAddresses68D0.add(mapCustomSetting.get(code68D0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code68D0).Pex_Email3__c != null) {
                        toAddresses68D0.add(mapCustomSetting.get(code68D0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code68D0).Pex_Email4__c != null) {
                        toAddresses68D0.add(mapCustomSetting.get(code68D0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code68D0).Pex_Email5__c != null) {
                        toAddresses68D0.add(mapCustomSetting.get(code68D0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code68D0).Pex_Email6__c != null) {
                        toAddresses68D0.add(mapCustomSetting.get(code68D0).Pex_Email6__c);
                    } 
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code68D0;
                    // sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr9000);
                }
                if(mapCustomSetting.containsKey(code68F0) && finalstr68F0 != null){
                    //toAddresses.clear();
                    if(mapCustomSetting.get(code68F0).Pex_Email1__c != null) {
                        toAddresses68F0.add(mapCustomSetting.get(code68F0).Pex_Email1__c);
                    }
                    if(mapCustomSetting.get(code68F0).Pex_Email2__c != null) {
                        toAddresses68F0.add(mapCustomSetting.get(code68F0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code68F0).Pex_Email3__c != null) {
                        toAddresses68F0.add(mapCustomSetting.get(code68F0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code68F0).Pex_Email4__c != null) {
                        toAddresses68F0.add(mapCustomSetting.get(code68F0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code68F0).Pex_Email5__c != null) {
                        toAddresses68F0.add(mapCustomSetting.get(code68F0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code68F0).Pex_Email6__c != null) {
                        toAddresses68F0.add(mapCustomSetting.get(code68F0).Pex_Email6__c);
                    } 
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code68F0;
                    // sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr9000);
                }
                if(mapCustomSetting.containsKey(code69A0) && finalstr69A0 != null){
                    // toAddresses.clear();
                    if(mapCustomSetting.get(code69A0).Pex_Email1__c != null) {
                        toAddresses69A0.add(mapCustomSetting.get(code69A0).Pex_Email1__c);
                    }
                    if(mapCustomSetting.get(code69A0).Pex_Email2__c != null) {
                        toAddresses69A0.add(mapCustomSetting.get(code69A0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code69A0).Pex_Email3__c != null) {
                        toAddresses69A0.add(mapCustomSetting.get(code69A0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code69A0).Pex_Email4__c != null) {
                        toAddresses69A0.add(mapCustomSetting.get(code69A0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code69A0).Pex_Email5__c != null) {
                        toAddresses69A0.add(mapCustomSetting.get(code69A0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code69A0).Pex_Email6__c != null) {
                        toAddresses69A0.add(mapCustomSetting.get(code69A0).Pex_Email6__c);
                    } 
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code69A0;
                    // sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr9000);
                }
                if(mapCustomSetting.containsKey(code69C0) && finalstr69C0 != null){
                    //toAddresses.clear();
                    if(mapCustomSetting.get(code69C0).Pex_Email1__c != null) {
                        toAddresses69C0.add(mapCustomSetting.get(code69C0).Pex_Email1__c);
                    }
                    if(mapCustomSetting.get(code69C0).Pex_Email2__c != null) {
                        toAddresses69C0.add(mapCustomSetting.get(code69C0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code69C0).Pex_Email3__c != null) {
                        toAddresses69C0.add(mapCustomSetting.get(code69C0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code69C0).Pex_Email4__c != null) {
                        toAddresses69C0.add(mapCustomSetting.get(code69C0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code69C0).Pex_Email5__c != null) {
                        toAddresses69C0.add(mapCustomSetting.get(code69C0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code69C0).Pex_Email6__c != null) {
                        toAddresses69C0.add(mapCustomSetting.get(code69C0).Pex_Email6__c);
                    } 
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code69C0;
                    // sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr9000);
                }
            }
        }
        
    }   
    
    // Finish Method
    
    global void finish(Database.BatchableContext BC) {
        
        
        //string header = HEADERvALUE+NEWLINE;
        if(finalstr9000 != header)
        {   
            system.debug('toAddresses9000 '+toAddresses9000);
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            // System.debug('DEBUG::finalstr******' + finalstr);
            String[] toAddresses = new list<string>();
            blob csvBlob = Blob.valueOf(finalstr9000);
            csvAttc.setFileName('All APM Pending Approval.csv');
            csvAttc.setBody(csvBlob);
            Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
            email.setSubject('All APM Pending Approval Report for Company Code:9000');
            email.setToAddresses( toAddresses9000 ); 
            email.setHtmlBody(PLAINTEXT);
            System.debug('DEBUG::csvAttc******' + csvAttc);
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
        }
        if(finalstr71F0 != header)
        {   system.debug('toAddresses71F0 '+toAddresses71F0);    
         Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
         // System.debug('DEBUG::finalstr******' + finalstr);
         String[] toAddresses = new list<string>();
         blob csvBlob = Blob.valueOf(finalstr71F0);
         csvAttc.setFileName('All APM Pending Approval.csv');
         csvAttc.setBody(csvBlob);
         Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
         email.setSubject('All APM Pending Approval Report for Company Code: 71F0');
         email.setToAddresses( toAddresses71F0 );
         email.setHtmlBody(PLAINTEXT);
         System.debug('DEBUG::csvAttc******' + csvAttc);
         email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
         Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
        }
        if(finalstr71D0 != header)
        {   system.debug('toAddresses71D0 '+toAddresses71D0);    
         Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
         // System.debug('DEBUG::finalstr******' + finalstr);
         blob csvBlob = Blob.valueOf(finalstr71D0);
         csvAttc.setFileName('All APM Pending Approval.csv');
         csvAttc.setBody(csvBlob);
         Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
         email.setSubject('All APM Pending Approval Report for Company Code:71D0');
         email.setToAddresses( toAddresses71D0 );
         email.setHtmlBody(PLAINTEXT);
         System.debug('DEBUG::csvAttc******' + csvAttc);
         email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
         Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
        }
        if(finalstr70A0 != header)
        {    system.debug('toAddresses70A0 '+toAddresses70A0);   
         Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
         // System.debug('DEBUG::finalstr******' + finalstr);
         blob csvBlob = Blob.valueOf(finalstr70A0);
         csvAttc.setFileName('All APM Pending Approval.csv');
         csvAttc.setBody(csvBlob);
         Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
         email.setSubject('All APM Pending Approval Report for Company Code:70A0');
         email.setToAddresses( toAddresses70A0 );
         email.setHtmlBody(PLAINTEXT);
         System.debug('DEBUG::csvAttc******' + csvAttc);
         email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
         Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
        }if(finalstr70B0 != header)
        {   system.debug('toAddresses70B0 '+toAddresses70B0);     
         Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
         // System.debug('DEBUG::finalstr******' + finalstr);
         blob csvBlob = Blob.valueOf(finalstr70B0);
         csvAttc.setFileName('All APM Pending Approval.csv');
         csvAttc.setBody(csvBlob);
         Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
         email.setSubject('All APM Pending Approval Report for Company Code:70B0');
         email.setToAddresses( toAddresses70B0 );
         email.setHtmlBody(PLAINTEXT);
         System.debug('DEBUG::csvAttc******' + csvAttc);
         email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
         Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
        }if(finalstr68C0 != header)
        {       system.debug('toAddresses68C0 '+toAddresses68C0); 
         Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
         // System.debug('DEBUG::finalstr******' + finalstr);
         
         blob csvBlob = Blob.valueOf(finalstr68C0);
         csvAttc.setFileName('All APM Pending Approval.csv');
         csvAttc.setBody(csvBlob);
         Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
         email.setSubject('All APM Pending Approval Report for Company Code:68C0');
         email.setToAddresses( toAddresses68C0 );
         email.setHtmlBody(PLAINTEXT);
         System.debug('DEBUG::csvAttc******' + csvAttc);
         email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
         Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
        }if(finalstr69F0 != header)
        {   system.debug('toAddresses69F0 '+toAddresses69F0);     
         Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
         // System.debug('DEBUG::finalstr******' + finalstr);
         blob csvBlob = Blob.valueOf(finalstr69F0);
         csvAttc.setFileName('All APM Pending Approval.csv');
         csvAttc.setBody(csvBlob);
         Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
         email.setSubject('All APM Pending Approval Report for Company Code:69F0');
         email.setToAddresses( toAddresses69F0 );
         email.setHtmlBody(PLAINTEXT);
         System.debug('DEBUG::csvAttc******' + csvAttc);
         email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
         Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
        }if(finalstr69D0 != header)
        {     system.debug('toAddresses69D0 '+toAddresses69D0);   
         Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
         // System.debug('DEBUG::finalstr******' + finalstr);
         blob csvBlob = Blob.valueOf(finalstr69D0);
         csvAttc.setFileName('All APM Pending Approval.csv');
         csvAttc.setBody(csvBlob);
         Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
         email.setSubject('All APM Pending Approval Report for Company Code:69D0');
         email.setToAddresses( toAddresses69D0 );
         email.setHtmlBody(PLAINTEXT);
         System.debug('DEBUG::csvAttc******' + csvAttc);
         email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
         Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
        }if(finalstr68D0 != header)
        {    system.debug('toAddresses68D0 '+toAddresses68D0);  
         if(toAddresses68D0 != NULL)
         {
             Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
             // System.debug('DEBUG::finalstr******' + finalstr);
             
             blob csvBlob = Blob.valueOf(finalstr68D0);
             csvAttc.setFileName('All APM Pending Approval.csv');
             csvAttc.setBody(csvBlob);
             Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
             email.setSubject('All APM Pending Approval Report for Company Code:68D0');
             email.setToAddresses( toAddresses68D0 );
             email.setHtmlBody(PLAINTEXT);
             System.debug('DEBUG::csvAttc******' + csvAttc);
             email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
             Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
             
         }
         
        }if(finalstr68F0 != header)
        {       system.debug('toAddresses68F0 '+toAddresses68F0); 
         Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
         // System.debug('DEBUG::finalstr******' + finalstr);
         blob csvBlob = Blob.valueOf(finalstr68F0);
         csvAttc.setFileName('All APM Pending Approval.csv');
         csvAttc.setBody(csvBlob);
         Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
         email.setSubject('All APM Pending Approval Report for Company Code:68F0');
         email.setToAddresses( toAddresses68F0 );
         email.setHtmlBody(PLAINTEXT);
         System.debug('DEBUG::csvAttc******' + csvAttc);
         email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
         Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
        }if(finalstr69A0 != header)
        {       
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            // System.debug('DEBUG::finalstr******' + finalstr);
            blob csvBlob = Blob.valueOf(finalstr69A0);
            csvAttc.setFileName('All APM Pending Approval.csv');
            csvAttc.setBody(csvBlob);
            Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
            email.setSubject('All APM Pending Approval Report for Company Code:69A0');
            email.setToAddresses( toAddresses69A0 );
            email.setHtmlBody(PLAINTEXT);
            System.debug('DEBUG::csvAttc******' + csvAttc);
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
        }if(finalstr69C0 != header)
        {   system.debug('toAddresses69C0 '+toAddresses69C0);     
         Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
         // System.debug('DEBUG::finalstr******' + finalstr);
         blob csvBlob = Blob.valueOf(finalstr69C0);
         csvAttc.setFileName('All APM Pending Approval.csv');
         csvAttc.setBody(csvBlob);
         Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
         email.setSubject('All APM Pending Approval Report for Company Code:69C0');
         email.setToAddresses( toAddresses69C0 );
         email.setHtmlBody(PLAINTEXT);
         System.debug('DEBUG::csvAttc******' + csvAttc);
         email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
         Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
        }
        
        
        
    }
    global void execute(SchedulableContext SC) {
        database.executebatch(new IFv2_PendingApprovalReport_batch_mlb());
    }
    
}