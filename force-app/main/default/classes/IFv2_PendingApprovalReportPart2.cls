/***************************************************************************************************************
* 
* @ Name 			:	IFv2_PendingApprovalReportPart2
* @ Purpose 		: 	For sending report regarding ICO workflows
* @ Author			: 	Prasad Vivek
* @ Test class name :   IFv2_PendingApprovalReportPart2Test
*
*   Date	        |  Developer Name               |  Version      |  Changes
* ==================================================================================================================
*   05-11-2018      |  vivek.kothalanka@absyz.com	|  1.1          | 	Initial version to send ICO workflows reports  
*
*******************************************************************************************************************/
global class IFv2_PendingApprovalReportPart2 implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        
        List<ProcessInstance> ProcessInstanceList;
        string NEWLINE= '\n';
        string SEPERATOR= '"';
        string SEPERATORcOLUMN= '","';
        string ENDLINE= '"\n';
       	string HEADERvALUE= 'Request Name, Salesforce ID , Company Code, WF Number , Status , Created Date , Current Approver,Current Approver Email, Invoicing Party Name,Invoicing Party (Vendor Number), Invoice Number, Fiscal Year , Item text, Purchase Order Number, Invoice Item Amount, Invoice Date, PlantSAP, Applicant First Name, Applicant Last Name, Request: Created Date, Request: Last Modified Date,Approver, Approver 2, Approver 3, Approver 4, Approver 5, Approver 6'; 
        //string PLAINTEXT= 'All APM Pending Approval CSV ';
        String SUBJECT ='All APM Pending Approval Report for Company Code: ';
        String tempSUBJECTBLANK = '';
        String tempSUBJECT;
        String csvname= 'All APM Pending Approval.csv';
        string code69D0= '69D0';
        string code68D0= '68D0';
        string code68F0= '68F0';
        string code69A0= '69A0';
        string code69C0= '69C0';
        string code71D0= '71D0';       
        string header = HEADERvALUE+NEWLINE;
        string finalstr69D0= header;
        string finalstr68D0= header;
        string finalstr68F0= header;
        string finalstr69A0= header;
        string finalstr69C0= header;
        string finalstr71D0= header;
        string varApprover;
        string varApprover2;
        string varApprover3;
        string varApprover4;
        string varApprover5;
        string varApprover6;
        string BLANKVALUE= 'NA';
        String sMessage;
        String PLAINTEXT = '<html lang="en"><body>'+
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
        for(ProcessInstanceWorkItem piw : ProcessInstanceWorkItemList)
        {
            mapWorkitem.put(piw.ProcessInstanceId,piw.Actor.name);
			approversEmailsMap.put(piw.ProcessInstanceId,piw.Actor.Email);
        }
        Map<Id, User> UserList = new Map<Id, User>([Select id, Name from User where isActive = True]);
        
        ProcessInstanceList = [SELECT Id, ProcessDefinitionID, ProcessDefinition.name, TargetObjectId, TargetObject.name, status, CreatedDate,lastModifiedDate FROM ProcessInstance where status = 'pending' and ProcessDefinition.name like '%ICO%'];
        Map<Id, IFV2_Request__c> RequestList = new  Map<Id, IFV2_Request__c>([SELECT Id, Name, 
                                                                              Status__c, CreatedDate, CompanyCode__c, Account__r.IFv2_SalesforceID__c, 
                                                                              Account__r.IFv2_WorkflowNumber__c, Workflow__c,lastModifiedDate, 
                                                                              Account__r.IFv2_InvoicingPartyVendorNumber__c, Account__r.IFv2_InvoicingPartyVendorName__c, 
                                                                              Account__r.IFv2_InvoiceNumber__c, Account__r.IFv2_FiscalYear__c, 
                                                                              Account__r.IFv2_ItemText__c, Account__r.IFv2_PurchaseOrderNumber__c, 
                                                                              InvoiceItemAmount__c, InvoiceDateDocumentDate__c, 
                                                                              Account__r.IFv2_PlantSAP__c,ApplicantFirstName__c,ApplicantLastName__c,
                                                                              Approver1__c, Approver2__c, 
                                                                              Approver3__c, Approver4__c, Approver5__c, Approver6__c 
                                                                              FROM IFv2_Request__c where Workflow__c like '%ICO%'
                                                                              AND Status__c = 'submitted' 
                                                                              AND (CompanyCode__c != '9000' 
                                                                                   OR CompanyCode__c != '71F0' OR CompanyCode__c != '70A0' 
                                                                                   OR CompanyCode__c != '70B0' OR CompanyCode__c != '68C0' 
                                                                                   OR CompanyCode__c != '69F0')]);
        
        if(ProcessInstanceList.size() > 0) {
            for ( ProcessInstance pi : ProcessInstanceList) {
                IFV2_Request__c wr = RequestList.get(pi.TargetObjectId);
                Try {
                    // To Store Pending Approval data on the basis of Company code.
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
                        
                        if(wr.CompanyCode__c == code69D0) {
                            string recordString69D0 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+ wr.ApplicantFirstName__c+SEPERATORcOLUMN+wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate+SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            
                            finalstr69D0 = finalstr69D0 +recordString69D0;
                        }  
                        else if(wr.CompanyCode__c == code68D0) {
                            string recordString68D0 =  SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+ wr.ApplicantFirstName__c+SEPERATORcOLUMN+wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate +SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr68D0 = finalstr68D0 +recordString68D0;
                        }  
                        else if(wr.CompanyCode__c == code68F0) {
                            string recordString68F0 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+ wr.ApplicantFirstName__c+SEPERATORcOLUMN+wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate +SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr68F0 = finalstr68F0 +recordString68F0;
                        }  
                        else if(wr.CompanyCode__c == code69A0) {
                            string recordString69A0 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+ wr.ApplicantFirstName__c+SEPERATORcOLUMN+wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate +SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr69A0 = finalstr69A0 +recordString69A0;
                        }  
                        else if(wr.CompanyCode__c == code69C0) {
                            string recordString69C0 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+ wr.ApplicantFirstName__c+SEPERATORcOLUMN+wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate +SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr69C0 = finalstr69C0 +recordString69C0;
                        }  
                        else if(wr.CompanyCode__c == code71D0) {
                            string recordString71D0 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+ wr.ApplicantFirstName__c+SEPERATORcOLUMN+wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate +SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr71D0 = finalstr71D0 +recordString71D0;
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
            String[] toAddresses = new list<string>();
            if(allPendingApprovalList.size() > 0) {
                for (All_Pending_Approval__c csVar : allPendingApprovalList) {
                    mapCustomSetting.put(csVar.Company_Code__c,csVar); 
                } 
                
                // sending mail for Company code69D0
                if(mapCustomSetting.containsKey(code69D0) && finalstr69D0 != null){ 
                    toAddresses.clear();
                    if(mapCustomSetting.get(code69D0).Pex_Email1__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69D0).Pex_Email1__c);
                    } 
                    if(mapCustomSetting.get(code69D0).Pex_Email2__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69D0).Pex_Email2__c);
                    }
                    if(mapCustomSetting.get(code69D0).Pex_Email3__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69D0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code69D0).Pex_Email4__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69D0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code69D0).Pex_Email5__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69D0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code69D0).Pex_Email6__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69D0).Pex_Email6__c);
                    } 
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code69D0;                    
                    sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr69D0);
                }   
                // sending mail for Company code68D0
                if(mapCustomSetting.containsKey(code68D0) && finalstr68D0 != null){ 
                    toAddresses.clear();
                    if(mapCustomSetting.get(code68D0).Pex_Email1__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68D0).Pex_Email1__c);
                    } 
                    if(mapCustomSetting.get(code68D0).Pex_Email2__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68D0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code68D0).Pex_Email3__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68D0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code68D0).Pex_Email4__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68D0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code68D0).Pex_Email5__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68D0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code68D0).Pex_Email6__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68D0).Pex_Email6__c);
                    }
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code68D0;                    
                    sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr68D0);
                }   
                // sending mail for Company code68F0
                if(mapCustomSetting.containsKey(code68F0) && finalstr68F0 != null){ 
                    toAddresses.clear();
                    if(mapCustomSetting.get(code68F0).Pex_Email1__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68F0).Pex_Email1__c);
                    } 
                    if(mapCustomSetting.get(code68F0).Pex_Email2__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68F0).Pex_Email2__c);
                    } 
                    if(mapCustomSetting.get(code68F0).Pex_Email3__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68F0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code68F0).Pex_Email4__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68F0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code68F0).Pex_Email5__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68F0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code68F0).Pex_Email6__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68F0).Pex_Email6__c);
                    }   
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code68F0;                     
                    sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr68F0);
                }   
                // sending mail for Company code69A0
                if(mapCustomSetting.containsKey(code69A0) && finalstr69A0 != null){ 
                    toAddresses.clear();
                    if(mapCustomSetting.get(code69A0).Pex_Email1__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69A0).Pex_Email1__c);
                    } 
                    if(mapCustomSetting.get(code69A0).Pex_Email2__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69A0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code69A0).Pex_Email3__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69A0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code69A0).Pex_Email4__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69A0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code69A0).Pex_Email5__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69A0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code69A0).Pex_Email6__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69A0).Pex_Email6__c);
                    }  
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code69A0;                     
                    sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr69A0);
                }   
                // sending mail for Company code69C0
                if(mapCustomSetting.containsKey(code69C0) && finalstr69C0 != null){ 
                    toAddresses.clear();
                    if(mapCustomSetting.get(code69C0).Pex_Email1__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69C0).Pex_Email1__c);
                    } 
                    if(mapCustomSetting.get(code69C0).Pex_Email2__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69C0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code69C0).Pex_Email3__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69C0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code69C0).Pex_Email4__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69C0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code69C0).Pex_Email5__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69C0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code69C0).Pex_Email6__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69C0).Pex_Email6__c);
                    }  
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code69C0;                      
                    sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr69C0);
                }   
                // sending mail for Company code71D0
                if(mapCustomSetting.containsKey(code71D0) && finalstr71D0 != null){ 
                    toAddresses.clear();
                    if(mapCustomSetting.get(code71D0).Pex_Email1__c != null) {
                        toAddresses.add(mapCustomSetting.get(code71D0).Pex_Email1__c);
                    } 
                    if(mapCustomSetting.get(code71D0).Pex_Email2__c != null) {
                        toAddresses.add(mapCustomSetting.get(code71D0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code71D0).Pex_Email3__c != null) {
                        toAddresses.add(mapCustomSetting.get(code71D0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code71D0).Pex_Email4__c != null) {
                        toAddresses.add(mapCustomSetting.get(code71D0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code71D0).Pex_Email5__c != null) {
                        toAddresses.add(mapCustomSetting.get(code71D0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code71D0).Pex_Email6__c != null) {
                        toAddresses.add(mapCustomSetting.get(code71D0).Pex_Email6__c);
                    } 
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code71D0;                     
                    sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr71D0);
                }                 
            }
        }
    }
    
    // Function to send mails
    public void sendTheEmail( String[] toAddresses, String tempSUBJECT, String PLAINTEXT, string csvname, string finalstr ) {
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();      
        blob csvBlob = Blob.valueOf(finalstr);
        csvAttc.setFileName(csvname);
        csvAttc.setBody(csvBlob);
        Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
        email.setSubject(tempSUBJECT);
        email.setToAddresses( toAddresses );
        email.setHtmlBody(PLAINTEXT);
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
    } 
}