/***************************************************************************************************************
* 
* @ Name            :   IFv2_PendingApprovalReportPart3
* @ Purpose         :   For sending report regarding ICO workflows
* @ Author          :   Renjumol PS
* @ Test class name :   IFv2_PendingApprovalReportTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ==================================================================================================================
*   05-11-2018      |  renjumol.punnarath@absyz.com   |  1.1          |   Initial version to send ICO workflows reorts  
*
*******************************************************************************************************************/
global class IFv2_PendingApprovalReportPart3 implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        
        List<ProcessInstance> ProcessInstanceList = new List<ProcessInstance>();
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
        
        //string code71F0= '71F0';
        //string code70A0= '70A0';
        string code70B0= '70B0';
        string code68C0= '68C0';
        string code69F0= '69F0';  
        string code75B0= '75B0';
        string header = HEADERvALUE+NEWLINE;
        //string finalstr9000 = header;
       // string finalstr71F0 = header;  
       // string finalstr70A0 = header; 
        string finalstr70B0= header;
        string finalstr68C0= header;
        string finalstr69F0= header;
        string finalstr75B0= header;
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
        for(ProcessInstanceWorkItem piw : ProcessInstanceWorkItemList) {
            mapWorkitem.put(piw.ProcessInstanceId,piw.Actor.name);
            approversEmailsMap.put(piw.ProcessInstanceId,piw.Actor.Email);
        }
        
        Map<Id, User> UserList = new Map<Id, User>([Select id, Name from User where isActive = True]);
        
        ProcessInstanceList = [SELECT Id, ProcessDefinitionID, ProcessDefinition.name, TargetObjectId, TargetObject.name, status, CreatedDate,lastModifiedDate FROM ProcessInstance where status = 'pending' and ProcessDefinition.name like '%ICO%'];
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
                                                                                AND (CompanyCode__c != '69D0' OR CompanyCode__c != '68D0' 
                                                                                    OR CompanyCode__c != '68F0' OR CompanyCode__c != '69A0' 
                                                                                    OR CompanyCode__c != '69C0' OR CompanyCode__c != '71D0')]);
        
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
                        
                       
                        if(wr.CompanyCode__c == code70B0) {
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
                        else if(wr.CompanyCode__c == code75B0) {
                            string recordString75B0 = SEPERATOR+wr.Name+SEPERATORcOLUMN+wr.Account__r.IFv2_SalesforceID__c+SEPERATORcOLUMN+wr.CompanyCode__c+SEPERATORcOLUMN+wr.Account__r.IFv2_WorkflowNumber__c +SEPERATORcOLUMN+pi.status+SEPERATORcOLUMN+pi.CreatedDate+SEPERATORcOLUMN+mapWorkitem.get(pi.id)+SEPERATORcOLUMN+approversEmailsMap.get(pi.id)+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoicingPartyvendorname__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_InvoicingPartyvendornumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_InvoiceNumber__c+SEPERATORcOLUMN+wr.Account__r.IFv2_FiscalYear__c+SEPERATORcOLUMN+wr.Account__r.IFv2_ItemText__c+SEPERATORcOLUMN+wr.Account__r.IFv2_PurchaseOrderNumber__c+SEPERATORcOLUMN+wr.InvoiceItemAmount__c+SEPERATORcOLUMN+wr.InvoiceDateDocumentDate__c+SEPERATORcOLUMN+ wr.Account__r.IFv2_PlantSAP__c+SEPERATORcOLUMN+wr.ApplicantFirstName__c+SEPERATORcOLUMN+wr.ApplicantLastName__c+SEPERATORcOLUMN+wr.CreatedDate+SEPERATORcOLUMN+pi.lastModifiedDate+SEPERATORcOLUMN+varApprover+SEPERATORcOLUMN+varApprover2+SEPERATORcOLUMN+varApprover3+SEPERATORcOLUMN+varApprover4+SEPERATORcOLUMN+varApprover5+SEPERATORcOLUMN+varApprover6 +ENDLINE;
                            finalstr75B0 = finalstr75B0 +recordString75B0;
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
                 
                
                // sending mail for Company code70B0
                if(mapCustomSetting.containsKey(code70B0) && finalstr70B0 != null){ 
                    toAddresses.clear();
                    if(mapCustomSetting.get(code70B0).Pex_Email1__c != null) {
                        toAddresses.add(mapCustomSetting.get(code70B0).Pex_Email1__c);
                    } 
                    if(mapCustomSetting.get(code70B0).Pex_Email2__c != null) {
                        toAddresses.add(mapCustomSetting.get(code70B0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code70B0).Pex_Email3__c != null) {
                        toAddresses.add(mapCustomSetting.get(code70B0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code70B0).Pex_Email4__c != null) {
                        toAddresses.add(mapCustomSetting.get(code70B0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code70B0).Pex_Email5__c != null) {
                        toAddresses.add(mapCustomSetting.get(code70B0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code70B0).Pex_Email6__c != null) {
                        toAddresses.add(mapCustomSetting.get(code70B0).Pex_Email6__c);
                    } 
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code70B0;                     
                    sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr70B0);
                }
                // sending mail for Company code68C0
                if(mapCustomSetting.containsKey(code68C0) && finalstr68C0 != null){ 
                    toAddresses.clear();
                    if(mapCustomSetting.get(code68C0).Pex_Email1__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68C0).Pex_Email1__c);
                    } 
                    if(mapCustomSetting.get(code68C0).Pex_Email2__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68C0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code68C0).Pex_Email3__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68C0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code68C0).Pex_Email4__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68C0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code68C0).Pex_Email5__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68C0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code68C0).Pex_Email6__c != null) {
                        toAddresses.add(mapCustomSetting.get(code68C0).Pex_Email6__c);
                    } 
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code68C0;                      
                    sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr68C0);
                }   
                // sending mail for Company code69F0
                if(mapCustomSetting.containsKey(code69F0) && finalstr69F0 != null){ 
                    toAddresses.clear();
                    if(mapCustomSetting.get(code69F0).Pex_Email1__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69F0).Pex_Email1__c);
                    } 
                    if(mapCustomSetting.get(code69F0).Pex_Email2__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69F0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code69F0).Pex_Email3__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69F0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code69F0).Pex_Email4__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69F0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code69F0).Pex_Email5__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69F0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code69F0).Pex_Email6__c != null) {
                        toAddresses.add(mapCustomSetting.get(code69F0).Pex_Email6__c);
                    }   
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code69F0;                      
                    sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr69F0);
                }  
                // sending mail for Company code69F0
                if(mapCustomSetting.containsKey(code75B0) && finalstr75B0 != null){ 
                    toAddresses.clear();
                    if(mapCustomSetting.get(code75B0).Pex_Email1__c != null) {
                        toAddresses.add(mapCustomSetting.get(code75B0).Pex_Email1__c);
                    } 
                    if(mapCustomSetting.get(code75B0).Pex_Email2__c != null) {
                        toAddresses.add(mapCustomSetting.get(code75B0).Pex_Email2__c);
                    }  
                    if(mapCustomSetting.get(code75B0).Pex_Email3__c != null) {
                        toAddresses.add(mapCustomSetting.get(code75B0).Pex_Email3__c);
                    }  
                    if(mapCustomSetting.get(code75B0).Pex_Email4__c != null) {
                        toAddresses.add(mapCustomSetting.get(code75B0).Pex_Email4__c);
                    }  
                    if(mapCustomSetting.get(code75B0).Pex_Email5__c != null) {
                        toAddresses.add(mapCustomSetting.get(code75B0).Pex_Email5__c);
                    }  
                    if(mapCustomSetting.get(code75B0).Pex_Email6__c != null) {
                        toAddresses.add(mapCustomSetting.get(code75B0).Pex_Email6__c);
                    }   
                    tempSUBJECT = tempSUBJECTBLANK;
                    tempSUBJECT = SUBJECT + code75B0;                      
                    sendtheEmail (toAddresses, tempSUBJECT, PLAINTEXT, csvname, finalstr75B0);
                }    
            }
        }
    }
    
    // Function to send mails
    public void sendTheEmail( String[] toAddresses, String tempSUBJECT, String PLAINTEXT, string csvname, string finalstr ) {
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        System.debug('DEBUG::finalstr******' + finalstr);
        
        blob csvBlob = Blob.valueOf(finalstr);
        csvAttc.setFileName(csvname);
        csvAttc.setBody(csvBlob);
        Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
        email.setSubject(tempSUBJECT);
        email.setToAddresses( toAddresses );
        email.setHtmlBody(PLAINTEXT);
        System.debug('DEBUG::csvAttc******' + csvAttc);
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
    }  
    
}