/********************************************************************************************************
* 
* @ Name            : IFv2_ICORequestCreation
* @ Purpose         : This class is used for creating request record
* @ Author          : Prasad Vivek
* @ Test Class Name : IFv2_ICORequestCreationTest 
*
*   Date            |  Developer Name                 |  Version     |  Changes
* ======================================================================================================
*   28-10-2018      |  vivek.kothalanka@absyz.com     |  1.0         |  Initial Version
*   19-03-2019      |  pradeep.chary@absyz.com        |  1.1         |  Updated to query Attachment object for attachments 
*
*******************************************************************************************************/

global class IFv2_ICORequestCreation {
    
    /********************** WRAPPER CLASSES - Start **************************/
    global class ResponseObject {
        
        WebService String result;
        WebService String objectId;
        WebService String errorDescription;
        
        public ResponseObject(String result, String objectId, String errorDescription) {
            this.result = result;
            this.objectId = objectId;
            this.errorDescription = errorDescription;
        }
    }
    
    global class RequestWrapper {
        
        public RequestWrapper(SG_WF_WS_SAP_Cust_RequestCreation.RequestWrapper rw){
            this.Accounting_clerk_information = rw.Accounting_clerk_information;
            this.Approver_Proxy_name = rw.Approver_Proxy_name;
            this.Approver_name = rw.Approver_name;
            this.Company_Code = rw.Company_Code;
            this.Cost_Center = rw.Cost_Center;
            this.Document_Item = rw.Document_Item;
            this.Fiscal_Year = rw.Fiscal_Year;
            this.GL = rw.GL;
            this.II_is_blocked_due_to_other_reasons = rw.II_is_blocked_due_to_other_reasons;
            this.Internal_Order = rw.Internal_Order;
            this.Invoice_Item_Currency = rw.Invoice_Item_Currency;
            this.Invoice_Number = rw.Invoice_Number;
            this.Invoice_date_document_date = rw.Invoice_date_document_date;
            this.Invoice_item_amount = rw.Invoice_item_amount;
            this.Invoice_quantity = rw.Invoice_quantity;
            this.Invoice_type_Document_type = rw.Invoice_type_Document_type;
            this.Invoice_unit_of_measure = rw.Invoice_unit_of_measure;
            this.Invoicing_Party_vendor_name = rw.Invoicing_Party_vendor_name;
            this.Invoicing_Party_vendor_number = rw.Invoicing_Party_vendor_number;
            this.Item_Text = rw.Item_Text;
            this.Material_Number = rw.Material_Number;
            this.PV_between_PO_item_and_Invoice_item = rw.PV_between_PO_item_and_Invoice_item;
            this.Plant_SAP = rw.Plant_SAP;
            this.Posting_date = rw.Posting_date;
            this.Profit_Center = rw.Profit_Center;
            this.Purchase_order_item_s = rw.Purchase_order_item_s;
            this.Purchase_order_number = rw.Purchase_order_number;
            this.Purchasing_organization = rw.Purchasing_organization;
            this.QV_between_PO_item_and_Invoice_item = rw.QV_between_PO_item_and_Invoice_item;
            this.Salesforce_ID = rw.Salesforce_ID;
            this.Unit_Of_Measure = rw.Unit_Of_Measure;
            this.WBS_Element = rw.WBS_Element;
            this.Workflow_number = rw.Workflow_number;
            this.order_net_price = rw.order_net_price;
            this.order_quantity = rw.order_quantity;
        }
        
        WebService String Accounting_clerk_information;
        WebService String Approver_Proxy_name;
        WebService String Approver_name;
        WebService String Company_Code;
        WebService String Cost_Center;
        WebService String Document_Item;
        WebService String Fiscal_Year;
        WebService String GL;
        WebService String II_is_blocked_due_to_other_reasons;
        WebService String Internal_Order;
        WebService String Invoice_Item_Currency;
        WebService String Invoice_Number;
        WebService String Invoice_date_document_date;
        WebService String Invoice_item_amount;
        WebService String Invoice_quantity;
        WebService String Invoice_type_Document_type;
        WebService String Invoice_unit_of_measure;
        WebService String Invoicing_Party_vendor_name;
        WebService String Invoicing_Party_vendor_number;
        WebService String Item_Text;
        WebService String Material_Number;
        WebService String PV_between_PO_item_and_Invoice_item;
        WebService String Plant_SAP;
        WebService String Posting_date;
        WebService String Profit_Center;
        WebService String Purchase_order_item_s;
        WebService String Purchase_order_number;
        WebService String Purchasing_organization;
        WebService String QV_between_PO_item_and_Invoice_item;
        WebService String Salesforce_ID;
        WebService String Unit_Of_Measure;
        WebService String WBS_Element;
        WebService String Workflow_number;
        WebService String order_net_price;
        WebService String order_quantity;
    }
    
    /********************** WRAPPER CLASSES - End **************************/
    
    /* WebService method to create request record */
    WebService static IFv2_ICORequestCreation.ResponseObject createApmRequest(RequestWrapper sapRequest) {
        
        //To store the responce
        IFv2_ICORequestCreation.ResponseObject response;
        
        //To check whether Salesfoerce ID, Approver Name and workflowNumber
        if(String.isBlank(sapRequest.Salesforce_ID) || String.isBlank(sapRequest.Approver_name) || String.isBlank(sapRequest.Workflow_number)) {
            response = response = new IFv2_ICORequestCreation.ResponseObject('ERROR', '', 'Salesforce ID, Approver Name and Workflow number are required, please check if are filled properly');
        } else {
            
            
            LIST<String> draftStateWorkflowLIST = new LIST<String>();    //List to add Workflow Number 
            String workflowname ;   //To store the workflow name
            
            /*	Query for Workflow metadata based on workflow number */
            LIST<IFv2_Workflows__mdt> icoWorkflowMdtLIST = IFv2_UtilsController.getICOWorkflowMetadata(sapRequest.Workflow_number);
            
            //Error message to be returned if any error occors
            String errorMessage = '';
            
            //Initilization of request record 
            IFv2_Request__c icoRequest = new IFv2_Request__c();
            
            /* Checking if icoWorkflowMdtLIST list is not empty */
            if(!icoWorkflowMdtLIST.isEmpty()) {
                workflowname = icoWorkflowMdtLIST[0].Name__c;
                if(icoWorkflowMdtLIST[0].RequestStatus__c == System.label.CLIFv20140) {
                    draftStateWorkflowLIST.add(sapRequest.Workflow_number);
                }
                /* Account record initialization */
                Account icoRelatedAccount = new Account();
                
                /* Query for User records based on Approver name and Proxy approver name */
                LIST<User> retrievedUserLIST = IFv2_UtilsController.getUsersOfICO(sapRequest.Approver_name,sapRequest.Approver_Proxy_name);
                
                /* Query for Scan Record type Request */
                LIST<Scan__c> scanRecordLIST =  IFv2_UtilsController.getScanRecord(sapRequest.Salesforce_ID);
                Id scanRecordId;
                if(!scanRecordLIST.isEmpty()) {
                    scanRecordId = scanRecordLIST[0].Id;
                }
                
                /* Map to store NT user and User record */
                MAP<String, User> sapUserToSFDCUserMAP = new MAP<String, User>();      
                
                /* Checking if the  retrievedUserLIST list is not empty */
                if(!retrievedUserLIST.isEmpty()) {
                    
                    /* Iterating over retrievedUserLIST List */
                    for(User userRecord : retrievedUserLIST) {
                        if(userRecord.NT_User__c != null)
                            sapUserToSFDCUserMAP.put(userRecord.NT_User__c , userRecord);
                    }
                    
                    /* Checking if map is not empty */
                    if(!sapUserToSFDCUserMAP.isEmpty()) {
                        
                        /* Checking if scanRecordLIST list is not empty */
                        if(!scanRecordLIST.isEmpty()) {
                            
                            try { 
                                /* Filling fields which are on Account, this is a update in Iteration 3 as we moved some fields which are not used in logic to Account Object */
                                icoRelatedAccount.IFv2_AccountingClerkInformation__c = (sapRequest.Accounting_clerk_information != null || !String.isBlank(sapRequest.Accounting_clerk_information)) ? sapRequest.Accounting_clerk_information : '';
                                icoRelatedAccount.IFv2_ApproverProxyName__c = (sapRequest.Approver_Proxy_name != null || !String.isBlank(sapRequest.Approver_Proxy_name)) ? sapRequest.Approver_Proxy_name : '';
                                icoRelatedAccount.IFv2_ApproverName__c = (sapRequest.Approver_name != null || !String.isBlank(sapRequest.Approver_name)) ? sapRequest.Approver_name : '';
                                icoRelatedAccount.IFv2_DocumentItem__c = (sapRequest.Document_Item != null || !String.isBlank(sapRequest.Document_Item)) ? sapRequest.Document_Item : '';
                                icoRelatedAccount.IFv2_FiscalYear__c = (sapRequest.Fiscal_Year != null || !String.isBlank(sapRequest.Fiscal_Year)) ? sapRequest.Fiscal_Year : '';
                                icoRelatedAccount.IFv2_GL__c = (sapRequest.GL != null || !String.isBlank(sapRequest.GL)) ? sapRequest.GL : '';
                                icoRelatedAccount.IFv2_IIisblockedduetootherreasons__c = (sapRequest.II_is_blocked_due_to_other_reasons != null || !String.isBlank(sapRequest.II_is_blocked_due_to_other_reasons)) ? sapRequest.II_is_blocked_due_to_other_reasons : '';
                                icoRelatedAccount.IFv2_InternalOrder__c = (sapRequest.Internal_Order != null || !String.isBlank(sapRequest.Internal_Order)) ? sapRequest.Internal_Order : '';
                                icoRelatedAccount.IFv2_InvoiceNumber__c = (sapRequest.Invoice_Number != null || !String.isBlank(sapRequest.Invoice_Number)) ? sapRequest.Invoice_Number : '';
                                icoRelatedAccount.IFv2_InvoiceQuantity__c = (sapRequest.Invoice_quantity != null || !String.isBlank(sapRequest.Invoice_quantity)) ? sapRequest.Invoice_quantity : '';
                                icoRelatedAccount.IFv2_InvoiceTypeDocumentType__c = (sapRequest.Invoice_type_Document_type != null || !String.isBlank(sapRequest.Invoice_type_Document_type)) ? sapRequest.Invoice_type_Document_type : '';
                                icoRelatedAccount.IFv2_InvoiceUnitofMeasure__c = (sapRequest.Invoice_unit_of_measure != null || !String.isBlank(sapRequest.Invoice_unit_of_measure)) ? sapRequest.Invoice_unit_of_measure : '';
                                icoRelatedAccount.IFv2_InvoicingPartyvendorname__c = (sapRequest.Invoicing_Party_vendor_name != null || !String.isBlank(sapRequest.Invoicing_Party_vendor_name)) ? sapRequest.Invoicing_Party_vendor_name : '';
                                icoRelatedAccount.IFv2_InvoicingPartyvendornumber__c = (sapRequest.Invoicing_Party_vendor_number != null || !String.isBlank(sapRequest.Invoicing_Party_vendor_number)) ? sapRequest.Invoicing_Party_vendor_number : '';
                                icoRelatedAccount.IFv2_ItemText__c = (sapRequest.Item_Text != null || !String.isBlank(sapRequest.Item_Text)) ? sapRequest.Item_Text : '';
                                icoRelatedAccount.IFv2_MaterialNumber__c = (sapRequest.Material_Number != null || !String.isBlank(sapRequest.Material_Number)) ? sapRequest.Material_Number : '';
                                icoRelatedAccount.IFv2_PVbetweenPOitemandInvoiceitem__c = (sapRequest.PV_between_PO_item_and_Invoice_item != null || !String.isBlank(sapRequest.PV_between_PO_item_and_Invoice_item)) ? sapRequest.PV_between_PO_item_and_Invoice_item : '';
                                icoRelatedAccount.IFv2_PlantSAP__c = (sapRequest.Plant_SAP != null || !String.isBlank(sapRequest.Plant_SAP)) ? sapRequest.Plant_SAP : '';
                                icoRelatedAccount.IFv2_PostingDate__c = (sapRequest.Posting_date != null || !String.isBlank(sapRequest.Posting_date)) ? sapRequest.Posting_date : '';
                                icoRelatedAccount.IFv2_ProfitCenter__c = (sapRequest.Profit_Center != null || !String.isBlank(sapRequest.Profit_Center)) ? sapRequest.Profit_Center : '';
                                icoRelatedAccount.IFv2_Purchaseorderitems__c = (sapRequest.Purchase_order_item_s != null || !String.isBlank(sapRequest.Purchase_order_item_s)) ? sapRequest.Purchase_order_item_s : '';
                                icoRelatedAccount.IFv2_PurchaseOrderNumber__c = (sapRequest.Purchase_order_number != null || !String.isBlank(sapRequest.Purchase_order_number)) ? sapRequest.Purchase_order_number : '';
                                icoRelatedAccount.IFv2_PurchasingOrganization__c = (sapRequest.Purchasing_organization != null || !String.isBlank(sapRequest.Purchasing_organization)) ? sapRequest.Purchasing_organization : '';
                                icoRelatedAccount.IFv2_QVbetweenPOitemandInvoiceitem__c = (sapRequest.QV_between_PO_item_and_Invoice_item != null || !String.isBlank(sapRequest.QV_between_PO_item_and_Invoice_item)) ? sapRequest.QV_between_PO_item_and_Invoice_item : '';
                                icoRelatedAccount.IFv2_SalesforceID__c = (sapRequest.Salesforce_ID != null || !String.isBlank(sapRequest.Salesforce_ID)) ? sapRequest.Salesforce_ID : '';
                                icoRelatedAccount.IFv2_UnitofMeasure__c = (sapRequest.Unit_Of_Measure != null || !String.isBlank(sapRequest.Unit_Of_Measure)) ? sapRequest.Unit_Of_Measure : '';
                                icoRelatedAccount.IFv2_WBSElement__c = (sapRequest.WBS_Element != null || !String.isBlank(sapRequest.WBS_Element)) ? sapRequest.WBS_Element : '';
                                icoRelatedAccount.IFv2_WorkflowNumber__c = (sapRequest.Workflow_number != null || !String.isBlank(sapRequest.Workflow_number)) ? sapRequest.Workflow_number : '';
                                icoRelatedAccount.IFv2_OrderQuantity__c = (sapRequest.order_quantity != null || !String.isBlank(sapRequest.order_quantity)) ? sapRequest.order_quantity: '';
                                icoRelatedAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Extension').getRecordTypeId();
                                /*  End of filling the field values for Account object */
                                /*  Filling the field values for request object, these are the fields which are using in logic */
                                icoRequest.Ordernetprice__c = (sapRequest.order_net_price != null || !String.isBlank(sapRequest.order_net_price)) ? sapRequest.order_net_price : '';
                                icoRequest.InvoiceItemCurrency__c = (sapRequest.Invoice_Item_Currency != null || !String.isBlank(sapRequest.Invoice_Item_Currency)) ? sapRequest.Invoice_Item_Currency : '';
                                icoRequest.CostCenter__c = (sapRequest.Cost_Center != null || !String.isBlank(sapRequest.Cost_Center)) ? sapRequest.Cost_Center : '';
                                icoRequest.Workflow__c = System.Label.CLIFv20136 + ' - ' + sapRequest.Workflow_number.removeStart('0');
                                icoRequest.Approver1__c = sapUserToSFDCUserMAP.get(sapRequest.Approver_name).Id;
                                if(scanRecordId != null) {
                                    icoRequest.Scan__c = scanRecordId;	//Lookup to Scan from IFv2_Request__c
                                }
                                icoRequest.CompanyCode__c = (sapRequest.Company_Code != null || !String.isBlank(sapRequest.Company_Code)) ? sapRequest.Company_Code : '';
                                icoRequest.InvoiceItemAmount__c = (sapRequest.Invoice_item_amount != null || !String.isBlank(sapRequest.Invoice_item_amount)) ? sapRequest.Invoice_item_amount : '';
                                icoRequest.InvoiceDateDocumentDate__c = (sapRequest.Invoice_date_document_date != null || !String.isBlank(sapRequest.Invoice_date_document_date)) ? sapRequest.Invoice_date_document_date : '';
                                icoRequest.Status__c = 'Draft';
                                
                                /* Query for Role Approver Mapping */ 
                                LIST<IFv2_RoleApproverMapping__mdt> roleApproverMappingLIST = IFv2_UtilsController.getRoleApproverMapping(workflowname);
                                
                                /* Checking if roleApproverMappingLIST is not empty */ 
                                if(!roleApproverMappingLIST.isEmpty()) {
                                    /* Supplier Name field is being used to fill approver id field from SAP */
                                    icoRequest.SupplierName__c = sapUserToSFDCUserMAP.get(sapRequest.Approver_name).Id;
                                }
                                
                                Database.SaveResult RequestInsert = Database.insert(icoRequest, true);
                                
                                /* Checking if request record insertion is success or not*/
                                if(RequestInsert.isSuccess()) {
                                    
                                    /* Get Request Record */
                                    IFv2_Request__c newlyInsertedRequestRecord = IFv2_UtilsController.getICORequestRecord(RequestInsert.getId());
                                    if(newlyInsertedRequestRecord != NULL) {
                                        
                                        icoRelatedAccount.IFv2_Request__c = newlyInsertedRequestRecord.Id;
                                        icoRelatedAccount.Name = newlyInsertedRequestRecord.Name.replace('INF','ACC');
                                        
                                        /* Inserting SCAN Attachments as ContentDocuments for the ICO request created */
                                        if(scanRecordId != null) {
                                            LIST<ContentVersion> versionInsertList = new LIST<ContentVersion>();                          
                                            for(Attachment attach : [SELECT Name, Body, BodyLength, ContentType, Description, ParentId 
                                                                     FROM Attachment
                                                                     WHERE ParentId =: scanRecordId]) {
                                                                         ContentVersion version = new ContentVersion(VersionData = attach.body, Title = attach.Name, PathOnClient = attach.Name);
                                                                         versionInsertList.add(version);
                                                                     }
                                            if(!versionInsertList.isEmpty()) {
                                                Database.insert(versionInsertList);
                                            }
                                            MAP<Id,Id> contentVersionDocumentMap = new MAP<Id,Id>();
                                            for(ContentVersion version : [SELECT Id,ContentDocumentId  
                                                                          FROM ContentVersion 
                                                                          WHERE Id IN :versionInsertList]) {
                                                                              contentVersionDocumentMap.put(version.Id,version.ContentDocumentId);
                                                                          }
                                            LIST<ContentDocumentLink> documentLinkInsertlist = new LIST<contentDocumentLink>();
                                            for(ContentVersion version:versionInsertList) {
                                                if(contentVersionDocumentMap.containsKey(version.Id)) {
                                                    ContentDocumentLink link = new ContentDocumentLink(LinkedEntityId = newlyInsertedRequestRecord.Id,ContentDocumentId = contentVersionDocumentMap.get(version.Id),shareType = 'I');
                                                    documentLinkInsertlist.add(link);
                                                }
                                            }
                                            if(!documentLinkInsertlist.isEmpty()) {
                                                Database.insert(documentLinkInsertlist);
                                            }
                                        }
                                        /* END Inserting SCAN Attachments as ContentDocuments for the ICO request created */
                                        
                                        /* Inserting Account record */
                                        Database.SaveResult AccountInsert = Database.insert(icoRelatedAccount, true);
                                        
                                        /* If record insertion is successful */
                                        if(AccountInsert.isSuccess()) {
                                            /* To get status of submittion for approval process */
                                            String statusOfSubmition;    
                                            
                                            newlyInsertedRequestRecord.Account__c = AccountInsert.getId();
                                            IFv2_DmlController.GenericDMLOperation(newlyInsertedRequestRecord, 'Update');
                                            
                                            /* Checking if roleApproverMappingLIST list is not empty, this is done to check if mapping is there or not */
                                            if(!roleApproverMappingLIST.isEmpty()) {
                                                
                                                /* Fieldset, fieldApiLIST, section metadata Lists */
                                                LIST<String> sectionIdLIST = new LIST<String>();   //List to add section ids
                                                LIST<String> fieldSetNameLIST = new LIST<String>();   //List to get Fieldset names
                                                LIST<String> fieldApiLIST = new LIST<String>();   //List to add fieldapi names
                                                LIST<IFv2_Section__mdt> sectionLIST = new LIST<IFv2_Section__mdt>();   //List to add section metadata records 
                                                /* End of Lists used */
                                                
                                                /* Map of fieldset and section metadata record */
                                                MAP<String, IFv2_Section__mdt> sectionMAP = new MAP<String, IFv2_Section__mdt>();//Map to store value and section mdt
                                                
                                                /* Querying for Section metadata */
                                                sectionLIST = IFv2_FieldSetFormController.getSectionMetadata(workflowname, 'request details',false);
                                                
                                                /* Checking if sectionLIST is not empty */
                                                if(!sectionLIST.isEmpty()) {
                                                    
                                                    /* iterating over Section list */
                                                    for(IFv2_Section__mdt section : sectionLIST) {
                                                        sectionIdLIST.add(section.Id);
                                                        fieldSetNameLIST.add(section.Value__c);
                                                        sectionMAP.put(section.Value__c, section);
                                                    }
                                                    
                                                    /* To get formula field add to the field set */
                                                    fieldSetNameLIST.add('IFv2_LookupFields');
                                                    Schema.SObjectType objectType = Schema.getGlobalDescribe().get('IFv2_Request__c');
                                                    Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
                                                    /* Maps used for field schema */
                                                    MAP<String, Schema.FieldSet> fieldSetMAP = objectDescribe.fieldSets.getMap();
                                                    MAP<String, Schema.SObjectField> fieldMAP = objectDescribe.fields.getMap();
                                                    
                                                    /* iterate over fieldsetnames map */
                                                    for(String fieldSetName : fieldSetNameLIST) {
                                                        Schema.FieldSet fieldSet = fieldSetMAP.get(fieldSetName);
                                                        LIST<Schema.FieldSetMember> fieldSetMemberLIST = fieldSet.getFields();
                                                        for(Schema.FieldSetMember member : fieldSetMemberLIST) {
                                                            IFv2_FieldWrapperClass field = new IFv2_FieldWrapperClass(member, 'IFv2_Request__c',newlyInsertedRequestRecord, fieldMAP);
                                                            fieldApiLIST.add(field.APIName);
                                                        }
                                                    }
                                                }
                                                /* Query for APM request record*/
                                                String apIQuery = '';
                                                
                                                /* iterating over fieldApiLIST */
                                                for(String apinames : fieldApiLIST) {
                                                    apIQuery = apIQuery + apinames + ',';
                                                }
                                                apIQuery = ',' + apIQuery.removeEnd(',');
                                                
                                                /* query for newly inserted record */
                                                LIST<IFv2_Request__c> requestRecordLIST = IFv2_UtilsController.getRequestRecord(newlyInsertedRequestRecord.Id, apIQuery);
                                                if(!requestRecordLIST.isEmpty()) {
                                                    IFv2_Request__c requestRecord = requestRecordLIST[0];
                                                    /* Map of IFv2_Request__c object fields schema */
                                                    MAP<String, Schema.SObjectField> fieldMAP = Schema.getGlobalDescribe().get('IFv2_Request__c').getDescribe().fields.getMap();
                                                    /* Record of role approver mapping */
                                                    Sobject record = IFv2_FieldSetFormController.getRoleApproverMapping((Sobject)requestRecord, null, null, 'IFv2_Request__c', fieldMAP);
                                                    record = IFv2_FieldSetFormController.getPredefinedMapping((Sobject)requestRecord, null,null, 'IFv2_Request__c', fieldMAP);
                                                    
                                                    /* checking if record id not null */
                                                    if(record != null) {
                                                        IFv2_DmlController.GenericDMLOperation(record, 'Update');
                                                    }
                                                }
                                            }
                                            
                                            //WF6 changes - Updating Owner for ICO 6
                                            IFv2_Request__c requestRecord = new IFv2_Request__c();
                                            if(sapRequest.Workflow_number == System.Label.CLIFv20080 && !String.isBlank(sapRequest.Approver_Proxy_name) && sapRequest.Approver_Proxy_name != null) {
                                                requestRecord.Id = newlyInsertedRequestRecord.Id;
                                                requestRecord.OwnerId = sapUserToSFDCUserMAP.get(sapRequest.Approver_Proxy_name).Id;
                                            }
                                            if(requestRecord != Null && requestRecord.Id != Null) {
                                                IFv2_DmlController.GenericDMLOperation(requestRecord, 'Update');
                                            }
                                            
                                            /* Checking if draftStateWorkflowLIST does not contain workflow number */
                                            if(!draftStateWorkflowLIST.contains((sapRequest.Workflow_number))) {
                                                Sobject SobjectTypeRecord = (Sobject)newlyInsertedRequestRecord;
                                                LIST<IFv2_HeaderController.ApproverSectionWrapper> approverSectionList = IFv2_HeaderController.getApproverSectionWrapper(newlyInsertedRequestRecord.Id, newlyInsertedRequestRecord.Workflow__c);
                                                statusOfSubmition = IFv2_HeaderController.submitForApproval(SobjectTypeRecord,approverSectionList);
                                            }
                                        } else {
                                            /* To delete newly inserted record if account insertion fails */
                                            newlyInsertedRequestRecord = [SELECT ID FROM IFv2_Request__c WHERE id=:RequestInsert.getId()];
                                            IFv2_DmlController.deleteRequestRecord(newlyInsertedRequestRecord.Id);
                                        }
                                    }
                                } else {
                                    System.debug('Request Insertion Failed ' );
                                }
                            } catch(Exception e) {
                                /*Delete Request record if Account is not created*/
                                if(icoRequest.Id != null && icoRelatedAccount.Id == null){
                                    IFv2_DmlController.deleteRequestRecord(icoRequest.Id);
                                }
                                
                                /* Query for custom error messages */
                                LIST<IFv2_CustomErrorMessages__c> customErrorMessageLIST = IFv2_UtilsController.getCustomErrorMessages(e.getMessage());
                                
                                //Map to create a map of standard errormessages and custom errormessages
                                MAP<String,String> standardCustomErrorMAP = new MAP<String,String>();    
                                
                                /* iterating over customErrorMessageLIST */
                                if(!customErrorMessageLIST.isEmpty()) {
                                    
                                    /* Iterating over customErrorMessageLIST list */
                                    for(IFv2_CustomErrorMessages__c iterator : customErrorMessageLIST) {
                                        standardCustomErrorMAP.put(iterator.StandardErrorMessage__c, iterator.CustomErrorMessage__c);
                                    }
                                }
                                
                                /* Checking if standardCustomErrorMAP is not empty */
                                if(!standardCustomErrorMAP.isEmpty()) {
                                    /* iterating over standardCustomErrorMAP keyset */
                                    for(String iterator : standardCustomErrorMAP.keySet()) {
                                        if(iterator.contains(e.getMessage())) {
                                            errorMessage = standardCustomErrorMAP.get(iterator);
                                        }
                                    } 
                                }
                            }
                        } else { 
                            /* Display of error message Salesforce id is not valid */
                            errorMessage = System.label.CLIFv20145 + sapRequest.Salesforce_ID ;
                        }
                    } else {
                        /* Display of error message if Approver name or approver proxy name is empty */
                        errorMessage = System.label.CLIFv20146+ sapRequest.Approver_name + 'or'+ sapRequest.Approver_Proxy_name;
                    }
                } else {
                    /* Display of error message if Approver name or approver proxy name is empty */
                    errorMessage = System.label.CLIFv20146 + sapRequest.Approver_name + 'or'+ sapRequest.Approver_Proxy_name;
                }
            } else {
                /* Display of error message if workflow number is not valid */
                errorMessage = System.label.CLIFv20147 + sapRequest.Workflow_number;
            } 
            
            /* Checking if Error message is empty */
            if(String.isBlank(errorMessage)) {
                /* Sending the response message */
                response = new IFv2_ICORequestCreation.ResponseObject('SUCCESS', icoRequest.Id, '');
            } else {
                /* Sending the response message */
                response = new IFv2_ICORequestCreation.ResponseObject('ERROR', '', errorMessage);
            } 
        }
        return response;
    }
}