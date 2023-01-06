/*******************************************************************************************************
* 
* @ Name 		: 	IFv2_SAPCalloutHandler
* @ Purpose 	: 	This class is used for APM workflows Integration on Account Object
* @ Author		: 	Prasad Vivek
* @ Test Class 	:  	IFv2_SAPCalloutHandlerTest
*
*   Date            |  Developer Name                     |  Version         |  Changes
* ======================================================================================================
*   28-10-2018      |  vivek.kothalanka@absyz.com	      |  1.0             |  Initial Version 
*******************************************************************************************************/

public class IFv2_SAPCalloutHandler {
    
    //Global Variables - variables used in the process
    public static String xmlShow {get;set;}
    public Dom.Document domDocument;
    private final Attachment singleAttachment;
    //Used for sending the attached pdf link
    public static String pdfLink;
    //Used for sending the attached pdf link
    public static String pdfId;
    //retrigger count variable
    public static Integer reTriggerCount = 0;
    
    //Call Sap and send required Structure
    @Future(callout=true)
    public static void httpSapCall (Id scanRecordId, String name) {
        //Invoking the SAP call
        sapCalloutMethod(scanRecordId,name);
    }
    
    //Send Status to SAP
    //Method to send callout to SAP
    @Future(callout=true)
    public static void soapUpdateSapStatus (LIST<Id> requestIdLIST) {
        
        //Used to Activate or deactivate this method 
        Boolean donotExecuteTrigger = IFv2_UtilsController.getTriggerLogic('IFv2_RequestTrigger','soapUpdateSapStatus');
        
        //Chekc if donotExecuteTrigger variable is true of false
        if(!donotExecuteTrigger) {
            String IvBarcodeValue = '';
            
            //Start of List's used
            //List of Account name
            LIST<Account> AccountLIST = new LIST<Account>();
            //List of Account Extension
            LIST<Account> ExtensionAccountLIST = new LIST<Account>();
            //End of list's used
            
            
            //To Store Account Ids for updating sapStatusUpdate field on Account 
            SET<Id> AccountIDsSET = new SET<Id>();
            //End of sets used
            
            //Quering for Request records od type list
            LIST<IFv2_Request__c> requestLIST = new LIST<IFv2_Request__c>();
            if(!requestIdLIST.isEmpty()) {
                requestLIST = [SELECT Id, Status__c, Workflow__c, Account__r.IFv2_SAPUPDATERESULT__c, Account__r.IFv2_SequenceNumber__c,
                               CompanyCode__c, Account__r.IFv2_InvoiceNumber__c, Account__r.IFv2_FiscalYear__c, Account__r.IFv2_DocumentItem__c,
                               Account__r.IFv2_SalesforceID__c,Account__r.IFv2_WorkflowNumber__c
                               FROM IFv2_Request__c 
                               WHERE Id IN : requestIdLIST 
                               AND (Status__c = 'Approved' 
                                    OR  Status__c = 'Rejected' 
                                    OR  Status__c = 'Canceled'
                                    OR  Status__c = 'Submitted')];
            }
            
            //To store Scan Name List
            LIST<String> scanNameLIST = new LIST<String>();
            
            //Iterating over request records
            if(!requestLIST.isEmpty()) {
                for(IFv2_Request__c request : requestLIST) {
                    
                    //To check if salesforce Id is not null
                    if(request.Account__r.IFv2_SalesforceID__c != null) {
                        scanNameLIST.add(request.Account__r.IFv2_SalesforceID__c);
                    }
                    //To check if account Id is not null
                    if(request.Account__c != null) {
                        AccountIDsSET.add(request.Account__r.Id);
                    }
                }
            }
            
            //Here we are quering Acount as we have stored Extension fields, This is for Updating Account Field, to get the response after call out
            if(!AccountIDsSET.isEmpty()) {
                ExtensionAccountLIST = [SELECT id, Name, IFv2_SAPUPDATERESULT__c, IFv2_Request__c 
                                        FROM Account 
                                        WHERE Id IN :AccountIDsSET];
            }
            
            //Map to store request id and account id
            MAP<Id, Id> AccountMAP = new MAP<Id, Id>();
            //Iterating over Account list and creating a map 
            if(!ExtensionAccountLIST.isEmpty()) {
                for(Account SingleAccount : ExtensionAccountLIST) {
                    AccountMAP.put(SingleAccount.IFv2_Request__c, SingleAccount.Id);
                }
            }
            
            //Initializing Scan record
            LIST<Scan__c> scanRecordLIST = new LIST<Scan__c>();
            
            if(!scanNameLIST.isEmpty()) {
                scanRecordLIST = [SELECT Id, Name FROM Scan__c WHERE Name IN : scanNameLIST];
            }
            
            LIST<Attachment> attachLIST = new LIST<Attachment>();
            
            if(!scanRecordLIST.isEmpty()) {
                attachLIST = [SELECT Id, Body, BodyLength, ContentType, Description, Name, ParentId, SystemModstamp
                              FROM Attachment 
                              WHERE ParentId = :scanRecordLIST[0].Id 
                              AND ContentType = 'application/xml'];
            }
            
            for(Attachment atm : attachList) {
                Dom.Document doc = new Dom.Document();
                Blob blobValue = EncodingUtil.base64Decode(EncodingUtil.base64encode(atm.body));
                doc.load(blobValue.toString());
                Dom.XMLNode env= doc.getRootElement();
                Dom.XmlNode node = doc.getRootElement().getChildElement('FIELDGROUP', null) ;
                String getNameValue = node.getname();
                dom.XmlNode SFNode = env.addChildElement('FIELDGROUP', null, null);
                dom.XmlNode SFChild;
                if(!scanRecordLIST.isEmpty()) {
                    SFChild = SFNode.addChildElement('FIELD Name = "SF_ID" Value ="' + scanRecordLIST[0].Name + '"', null, null);
                }
                SFnode.setAttribute('NAME', 'SALESFORCE');
                SFChild.setAttribute('SF_SAMPLE_ATTRIB', '12345678');
                xmlshow = doc.toXmlString();
                Dom.XmlNode tnode = doc.getRootElement().getChildElement('TABLE', null);
                
                for(Dom.XmlNode child1 :  node.getChildElements() ) {
                    if(child1.getAttributeValue('Name', '') == 'INV_BARCODE' ) {
                        IvBarcodeValue = child1.getAttributeValue('Value', '');
                    }
                }
            }
            
            Boolean isXsi = false;
            String subStringBarcode;
            if((IvBarcodeValue != null && IvBarcodeValue != '')) {
                subStringBarcode = IvBarcodeValue.substring(0,3);
            }
            
            SET<String> endpointIdentifierSET = new SET<String>(Label.Barcode_Identifier.split(';'));
            if(subStringBarcode != null || subStringBarcode != '') { 
                if(endpointIdentifierSET.contains(subStringBarcode)) {
                    isXsi = true;
                }
            }
            
            //To check if requestLIST is not empty
            if (!requestLIST.isEmpty()) {
                //List of request records 
                LIST<IFv2_Request__c> requestsForUpdateLIST = new LIST<IFv2_Request__c>();
                //List of Account record
                LIST<Account> AccountListUpdate = new LIST<Account>();
                
                //Iterating over requestLIST list
                for(IFv2_Request__c r : requestLIST) {
                    SG_WF_WS_Sap_Interface_4th.ZMM_SF_APM_WF requestStruc = new SG_WF_WS_Sap_Interface_4th.ZMM_SF_APM_WF();
                    
                    //To go inside if workflow name is not concession means all ICO worklows
                    requestStruc.ZBUKRS = r.CompanyCode__c;
                    requestStruc.ZBELNR = r.Account__r.IFv2_InvoiceNumber__c;
                    requestStruc.ZGJAHR = r.Account__r.IFv2_FiscalYear__c;
                    requestStruc.ZRBLGP = r.Account__r.IFv2_SequenceNumber__c;
                    requestStruc.ZSEQNO = r.Account__r.IFv2_WorkflowNumber__c;
                    requestStruc.ZSALID = r.Account__r.IFv2_SalesforceID__c;
                    requestStruc.ZWFNAM = r.Workflow__c;
                    
                    if (r.Status__c == 'Approved') {
                        requestStruc.ZWFSTA = 'X';
                    } else if (r.Status__c == 'Rejected') {
                        requestStruc.ZWFSTA = 'R';
                    } else if (r.Status__c == 'Canceled') {
                        requestStruc.ZWFSTA = 'C';
                    }
                    
                    SG_WF_WS_Sap_Interface_4th.Z_MM_API_WFSTATUS_INBOUND_element inboundElement = new SG_WF_WS_Sap_Interface_4th.Z_MM_API_WFSTATUS_INBOUND_element();
                    inboundElement.IV_INPUT = requestStruc;
                    SG_WF_WS_Sap_Interface_4th.ZMM_APM_BINDING_TEST stub = new SG_WF_WS_Sap_Interface_4th.ZMM_APM_BINDING_TEST(isXsi);
                    
                    //new basic auth
                    String username = (isXsi) ? Label.SAP_User_India.split(';')[0] : Label.SAP_User.split(';')[0] ;
                    String password = (isXsi) ? Label.SAP_User_India.split(';')[1] :  Label.SAP_User.split(';')[1] ;
                    Blob headerValue = Blob.valueOf(username+':'+password);
                    String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
                    MAP<String,String> headersMAP = new MAP<String, String>();
                    headersMAP.put('KeyId', Label.SAP_Key_Id);
                    headersMAP.put('Authorization', authorizationHeader);
                    stub.inputHttpHeaders_x = headersMAP;
                    stub.timeout_x = 30000;
                    
                    try {
                        SG_WF_WS_Sap_Interface_4th.Z_MM_API_WFSTATUS_INBOUNDResponse_element response = stub.Z_MM_API_WFSTATUS_INBOUND(inboundElement.IV_INPUT);
                        if(AccountMAP.get(r.Id) != null) {
                            Account ExistingAccount = new Account();
                            ExistingAccount.Id = AccountMAP.get(r.Id);
                            ExistingAccount.IFv2_SAPUPDATERESULT__c =!String.isBlank(response.EV_FAILURE) ? 'Failure: ' + response.EV_FAILURE : 'Success: '+response.EV_SUCCESS;
                            AccountListUpdate.add(ExistingAccount);
                        }
                    } catch (Exception e) {
                        if(AccountMAP.get(r.Id) != null) {
                            Account ExistingAccount = new Account();
                            ExistingAccount.id = AccountMAP.get(r.Id);
                            ExistingAccount.IFv2_SAPUPDATERESULT__c = e.getMessage() + '\n' + e.getStackTraceString();
                            AccountListUpdate.add(ExistingAccount);
                        }
                        //Creating error log
                        IFv2_ExceptionUtilitiesController.exceptionHandler(e);
                    }
                }
                //Checking if AccountListUpdate list is not empty
                if(!AccountListUpdate.isEmpty()) {
                    //Update account records  
                    IFv2_DmlController.updateAccountRecords(AccountListUpdate);
                }
            }
        } else {
            system.debug('soapUpdateSapStatus : Method  is Deactivated');
        }
    }
    
    //Method for re-Triggering of the Failed SCAN records
    public static void sapCalloutMethod (Id scanRecordId, String name) {
        //Incrementing the callout count
        reTriggerCount++;
        //Used to Activate or deactivate this method 
        Boolean donotExecuteTrigger = IFv2_UtilsController.getTriggerLogic('IFv2_RequestTrigger','httpSapCall');
        
        //Checking if donotExecuteTrigger is true of false
        if(!donotExecuteTrigger) {
            String contentTypeString = System.Label.CLIFv20131;
            
            //List to store queried attachements
            LIST<Attachment> attachmentLIST = new LIST<Attachment>();
            
            //Checking if scanRecordId and contentTypeString is not NULL
            if(scanRecordId != NULL && !String.isBlank(contentTypeString)) {
                
                //Retrieving the attachments of the Scan record
                attachmentLIST = [SELECT Id, Name, ParentId, Body, BodyLength, ContentType, Description, SystemModstamp
                                  FROM Attachment 
                                  WHERE ParentId = :scanRecordId 
                                  AND (ContentType = 'application/xml' OR ContentType =: contentTypeString)];
            }
            
            if(!attachmentLIST.isEmpty()) {
                pdfId = [ SELECT Id
                         FROM Attachment 
                         WHERE ParentId = :scanRecordId 
                         AND ContentType = 'application/pdf' ].Id;
            }
            
            //Initializing Scan record
            Scan__c scanRecord = new Scan__c();
            //Retriving Scan Name of the Scan record
            if(scanRecordId != NULL) {
                scanRecord = [Select Id, Name 
                              FROM Scan__c 
                              WHERE Id =:scanRecordId];
            }
            
            //Populate required Header fields with parsed values of XML data from Reisswolf
            SG_WF_WS_Sap_Interface_MC_Style.ZmmSApmInHeader header = new SG_WF_WS_Sap_Interface_MC_Style.ZmmSApmInHeader();
            SG_WF_SAP_India_MC_Style.ZmmSApmInHeader headerI = new SG_WF_SAP_India_MC_Style.ZmmSApmInHeader();
            
            //Field values of Scan attachments which are sent to SAP - Start
            String IvAmountvalue = '';
            String IvBarcodeValue = '';
            String IvAmtRoundValue = '';
            String IvCreditNoteValue = '';
            String IvCurrencyValue = '';
            String IvDateValue = '';
            String IvDisAmt1Value = '';
            String IvDisAmt2Value = '';
            String IvDisPer1Value = '';
            String IvDisPer2Value = '';
            String IvIsIncompValue = '';
            String IvIsMmValue = '';
            String IvNetAmt1Value = '';
            String IvNetAmt2Value = '';
            String IvNetAmt3Value = '';
            String IvNumberValue = '';
            String IvTaxType = '';
            String IvTaxAmt1Value = '';
            String IvTaxAmt2Value = '';
            String IvTaxAmt3Value = '';
            String IvTaxRate1Value = '';
            String IvTaxRate2Value = '';
            String IvTaxRate3Value = '';
            String IvUnplDelAmtValue = '';
            String IvUnplDelTaxValue = '';
            String ReRecipientNoValue = '';
            String VeAccountNoValue = '';
            String VePbanktypeValue = '';
            String IvDisAmt11Value = '';
            String IvDisAmt22Value = '';
            String IvDisAmt33Value = '';
            String IvDisPer11Value = '';
            String IvDisPer22Value = '';
            String IvDisPer33Value = '';
            String IvOrderNoValue = '';
            String IvOriArticleNoValue = '';
            String IvOriDescValue = '';
            String IvPosNoValue = '';
            String IvQuantityValue = '';
            String IvUnitValue = '';
            String IvSinglePriceValue = '';
            String IvPriceUnitValue = '';
            String IvTotalPriceValue = '';
            String IvTaxRateValue = '';
            String IvCountryValue = '';//india
            String IvTotalTaxAmtValue = '';//india
            String IvDelNoValue = '';//india
            String IvDelPosValue = '';//india
            String IvHsnCodeValue = '';//India
            //Field values of Scan attachments which are sent to SAP - End
            
            //Populate required Invoice Fields with parsed Values of XML data from Reisswolf
            //MSWIST Here should be check if it is Indian Invoice, or 'Global' one.
            SG_WF_WS_Sap_Interface_MC_Style.ZmmSApmInInvT invoice = new SG_WF_WS_Sap_Interface_MC_Style.ZmmSApmInInvT();
            LIST<SG_WF_WS_Sap_Interface_MC_Style.ZmmSApmInInv> invoiceItemLIST = new LIST<SG_WF_WS_Sap_Interface_MC_Style.ZmmSApmInInv>();
            
            //Checking for PDF attachment
            if(!attachmentLIST.isEmpty()) {
                for(Attachment singleAttachment: attachmentLIST) {
                    
                    //XML creation which is sent to SAP
                    Dom.Document domDocument = new Dom.Document();
                    Blob blobValue = EncodingUtil.base64Decode(EncodingUtil.base64encode(singleAttachment.body));
                    domDocument.load(blobValue.toString());
                    Dom.XMLNode rootElement = domDocument.getRootElement();
                    Dom.XmlNode node = domDocument.getRootElement().getChildElement('FIELDGROUP', null) ;
                    String getName = node.getname();
                    pdfLink = URL.getSalesforceBaseUrl().toExternalForm()+ '/servlet/servlet.FileDownload?file='+ pdfId;
                    dom.XmlNode sfNode = rootElement.addChildElement('FIELDGROUP' , null, null);
                    dom.XmlNode sfChild = sfNode.addChildElement('FIELD Name = "SF_ID" Value ="' + scanRecord.Name +'"', null, null);
                    dom.XmlNode sfChild1 = sFNode.addChildElement('FIELD Name = "SF_ARCIVE_ID" Value = pdfLink', null, null);
                    dom.XmlNode sfChild2 = sfNode.addChildElement('FIELD Name = "SF_REFERENCE1" Value ="not used"', null, null);
                    dom.XmlNode sfChild3 = sfNode.addChildElement('FIELD Name = "SF_REFERENCE2" Value ="not used"', null, null);
                    dom.XmlNode sfChild4 = sfNode.addChildElement('FIELD Name = "SF_REFERENCE3" Value ="not used"', null, null);
                    SFnode.setAttribute('NAME', 'Salesforce');
                    xmlShow = domDocument.toXmlString();
                    Dom.XmlNode tNode = domDocument.getRootElement().getChildElement('TABLE', null);
                    
                    //Checking if childElements is not empty
                    if(!node.getChildElements().isEmpty()) {
                        
                        for (Dom.XmlNode child1 :  node.getChildElements() ) {
                            String c1 = child1.getname();
                            String c11 = child1.gettext();
                            
                            //Invoice Amount
                            if (child1.getAttributeValue('Name','') == 'INV_AMOUNT') {
                                IvAmountValue = child1.getAttributeValue('Value','');
                                if (IvAmountValue != null) {
                                    header.IvAmount = child1.getAttributeValue('Value','');
                                    headerI.IvAmount = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvAmount = '';
                                    headerI.IvAmount = '';
                                }
                            }
                            
                            //Invoice Currency
                            if (child1.getAttributeValue('Name','') == 'INV_CURRENCY' ) {
                                IvCurrencyValue = child1.getAttributeValue('Value','');
                                if (IvCurrencyValue != null) {
                                    header.IvCurrency = child1.getAttributeValue('Value','');
                                    headerI.IvCurrency = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvCurrency = '';
                                    headerI.IvCurrency = '';
                                }
                            }
                            
                            //Invoice Net Amount
                            if (child1.getAttributeValue('Name','') == 'INV_NET_AMOUNT1' ) {
                                IvNetAmt1Value = child1.getAttributeValue('Value','');
                                if (IvNetAmt1Value != null) {
                                    header.IvNetAmt1 = child1.getAttributeValue('Value','');
                                    headerI.IvNetAmt1 = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvNetAmt1 = '';
                                    headerI.IvNetAmt1 = '';
                                }
                            }
                            
                            //Invoice Net Amount 2
                            if (child1.getAttributeValue('Name','') == 'INV_NET_AMOUNT2' ) {
                                IvNetAmt2Value = child1.getAttributeValue('Value','');
                                if (IvNetAmt2Value != null) {
                                    header.IvNetAmt2 = child1.getAttributeValue('Value','');
                                    headerI.IvNetAmt2 = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvNetAmt2 = '';
                                    headerI.IvNetAmt2 = '';
                                }
                            }
                            
                            //Invoice Net Amount 3
                            if (child1.getAttributeValue('Name','') == 'INV_NET_AMOUNT3' ) {
                                IvNetAmt3Value = child1.getAttributeValue('Value','');
                                if (IvNetAmt3Value != null) {
                                    header.IvNetAmt3 = child1.getAttributeValue('Value','');
                                    headerI.IvNetAmt3 = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvNetAmt3 = '';
                                    headerI.IvNetAmt3 = '';
                                }
                            } 
                            
                            //Invoice Number
                            if (child1.getAttributeValue('Name','') == 'INV_NUMMER' ) {
                                IvNumberValue = child1.getAttributeValue('Value','');
                                if (IvNumberValue != null) {
                                    header.IvNumber = child1.getAttributeValue('Value','');
                                    headerI.IvNumber = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvNumber = '';
                                    headerI.IvNumber = '';
                                }
                            }
                            
                            //newly added fields for India APM
                            if (child1.getAttributeValue('Name','') == 'INV_TAX_TYPE' ) {
                                IvTaxType = child1.getAttributeValue('Value','');
                                if (IvTaxType != null) {
                                    header.IvTaxType = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvTaxType = '';
                                }
                            }
                            
                            //Invoice Date
                            if (child1.getAttributeValue('Name','') == 'INV_DATE' ) {
                                IvDateValue = child1.getAttributeValue('Value','');
                                if (IvDateValue != null) {
                                    header.IvDate = child1.getAttributeValue('Value','');
                                    headerI.IvDate = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvDate = '';
                                    headerI.IvDate = '';
                                }
                            }
                            
                            //Invoice Tax Amount
                            if (child1.getAttributeValue('Name','') == 'INV_TAX_AMOUNT1' ) {
                                IvTaxAmt1Value = child1.getAttributeValue('Value','');
                                if (IvTaxAmt1Value != null) {
                                    header.IvTaxAmt1 = child1.getAttributeValue('Value','');
                                    headerI.IvTaxAmt1 = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvTaxAmt1 = '';
                                    headerI.IvTaxAmt1 = '';
                                }
                            }
                            
                            //Invoice Tax Amount 2
                            if (child1.getAttributeValue('Name','') == 'INV_TAX_AMOUNT2' ) {
                                IvTaxAmt2Value = child1.getAttributeValue('Value','');
                                if (IvTaxAmt2Value != null) {
                                    header.IvTaxAmt2 = child1.getAttributeValue('Value','');
                                    headerI.IvTaxAmt2 = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvTaxAmt2 = '';
                                    headerI.IvTaxAmt2 = '';
                                }
                            }
                            
                            //Invoice Tax Amount 3
                            if (child1.getAttributeValue('Name','') == 'INV_TAX_AMOUNT3' ) {
                                IvTaxAmt3Value = child1.getAttributeValue('Value','');
                                if (IvTaxAmt3Value != null) {
                                    header.IvTaxAmt3 = child1.getAttributeValue('Value','');
                                    headerI.IvTaxAmt3 = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvTaxAmt3 = '';
                                    headerI.IvTaxAmt3 = '';
                                }
                            }
                            
                            //Invoice Tax Rate 1
                            if (child1.getAttributeValue('Name','') == 'INV_TAX_RATE1' ) {
                                IvTaxRate1Value = child1.getAttributeValue('Value','');
                                if (IvTaxRate1Value != null) {
                                    header.IvTaxRate1 = child1.getAttributeValue('Value','');
                                    headerI.IvTaxRate1 = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvTaxRate1 = '';
                                    headerI.IvTaxRate1 = '';
                                }
                            }
                            
                            //Invoice Tax Rate 2
                            if (child1.getAttributeValue('Name','') == 'INV_TAX_RATE2' ) {
                                IvTaxRate2Value = child1.getAttributeValue('Value','');
                                if (IvTaxRate2Value != null) {
                                    header.IvTaxRate2 = child1.getAttributeValue('Value','');
                                    headerI.IvTaxRate2 = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvTaxRate2 = '';
                                    headerI.IvTaxRate2 = '';
                                }
                            }
                            
                            //Invoice Tax Rate 3
                            if (child1.getAttributeValue('Name','') == 'INV_TAX_RATE3' ) {
                                IvTaxRate3Value = child1.getAttributeValue('Value','');
                                if (IvTaxRate3Value != null) {
                                    header.IvTaxRate3 = child1.getAttributeValue('Value','');
                                    headerI.IvTaxRate3 = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvTaxRate3 = '';
                                    headerI.IvTaxRate3 = '';
                                }
                            }
                            
                            //Invoice Unplanned Delivery Amount
                            if (child1.getAttributeValue('Name','') == 'INV_UNPL_DEL_AMOUNT' ) {
                                IvUnplDelAmtValue = child1.getAttributeValue('Value','');
                                if (IvUnplDelAmtValue != null) {
                                    header.IvUnplDelAmt = child1.getAttributeValue('Value','');
                                    headerI.IvUnplDelAmt = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvUnplDelAmt = '';
                                    headerI.IvUnplDelAmt = '';
                                }
                            }
                            
                            //Invoice Unplanned Delivery Tac Rate
                            if (child1.getAttributeValue('Name','') == 'INV_UNPL_DEL_TAX_RATE' ) {
                                IvUnplDelTaxValue = child1.getAttributeValue('Value','');
                                if (IvUnplDelTaxValue != null) {
                                    header.IvUnplDelTax = child1.getAttributeValue('Value','');
                                    headerI.IvUnplDelTax = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvUnplDelTax = '';
                                    headerI.IvUnplDelTax = '';
                                }
                            }
                            
                            //Invoice Barcode
                            if (child1.getAttributeValue('Name','') == 'INV_BARCODE' ) {
                                IvBarcodeValue = child1.getAttributeValue('Value','');
                                if (IvBarcodeValue != null) {
                                    header.IvBarcode = child1.getAttributeValue('Value','');
                                    headerI.IvBarcode = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvBarcode = '';
                                    headerI.IvBarcode = '';
                                }
                            }
                            
                            //Invoice Amount Rounding
                            if (child1.getAttributeValue('Name','') == 'INV_AMOUNT_ROUNDING' ) {
                                IvAmtRoundValue = child1.getAttributeValue('Value','');
                                if (IvAmtRoundValue != null) {
                                    header.IvAmtRound = child1.getAttributeValue('Value','');
                                    headerI.IvAmtRound = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvAmtRound = '';
                                    headerI.IvAmtRound = '';
                                }
                            }
                            
                            //Invoice Credit Note
                            if (child1.getAttributeValue('Name','') == 'INV_CREDIT_NOTE' ) {
                                IvCreditNoteValue = child1.getAttributeValue('Value','');
                                if (IvCreditNoteValue != null) {
                                    header.IvCreditNote = child1.getAttributeValue('Value','');
                                    headerI.IvCreditNote = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvCreditNote = '';
                                    headerI.IvCreditNote = '';
                                }
                            }
                            
                            //Invoice Discount Amount
                            if (child1.getAttributeValue('Name','') == 'INV_DISCOUNT_AMOUNT1' ) {
                                IvDisAmt1Value = child1.getAttributeValue('Value','');
                                if (IvDisAmt1Value != null) {
                                    header.IvDisAmt1 = child1.getAttributeValue('Value','');
                                    headerI.IvDisAmt1 = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvDisAmt1 = '';
                                    headerI.IvDisAmt1 = '';
                                }
                            }
                            
                            //Invoice Discount Amount 2
                            if (child1.getAttributeValue('Name','') == 'INV_DISCOUNT_AMOUNT2' ) {
                                IvDisAmt2Value = child1.getAttributeValue('Value','');
                                if (IvDisAmt2Value != null) {
                                    header.IvDisAmt2 = child1.getAttributeValue('Value','');
                                    headerI.IvDisAmt2 = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvDisAmt2 = '';
                                    headerI.IvDisAmt2 = '';
                                }
                            }
                            
                            //Invoice Discount Percentage 1
                            if (child1.getAttributeValue('Name','') == 'INV_DISCOUNT_PERCENT1' ) {
                                IvDisPer1Value = child1.getAttributeValue('Value','');
                                if (IvDisPer1Value != null) {
                                    header.IvDisPer1 = child1.getAttributeValue('Value','');
                                    headerI.IvDisPer1 = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvDisPer1 = '';
                                    headerI.IvDisPer1 = '';
                                }
                            }
                            
                            //Invoice Discount Percentage 2
                            if (child1.getAttributeValue('Name','') == 'INV_DISCOUNT_PERCENT2' ) {
                                IvDisPer2Value = child1.getAttributeValue('Value','');
                                if (IvDisPer2Value != null) {
                                    header.IvDisPer2 = child1.getAttributeValue('Value','');
                                    headerI.IvDisPer2 = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvDisPer2 = '';
                                    headerI.IvDisPer2 = '';
                                }
                            }
                            
                            //Invoice Intercompany
                            if (child1.getAttributeValue('Name','') == 'INV_IS_INTERCOMPANY' ) {
                                IvIsIncompValue = child1.getAttributeValue('Value','');
                                if (IvIsIncompValue != null) {
                                    header.IvIsIncomp = child1.getAttributeValue('Value','');
                                    headerI.IvIsIncomp = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvIsIncomp = '';
                                    headerI.IvIsIncomp = '';
                                }
                            }
                            
                            //Invoice
                            if (child1.getAttributeValue('Name','') == 'INV_IS_MM' ) {
                                IvIsMmValue = child1.getAttributeValue('Value','');
                                if (IvIsMmValue != null) {
                                    header.IvIsMm = child1.getAttributeValue('Value','');
                                    headerI.IvIsMm = child1.getAttributeValue('Value','');
                                } else {
                                    header.IvIsMm = '';
                                    headerI.IvIsMm = '';
                                }
                            }
                            
                            //Invoice Reciepient number
                            if (child1.getAttributeValue('Name','') == 'RE_RECIEPIENT_NO' ) {
                                ReRecipientNoValue = child1.getAttributeValue('Value','');
                                if (ReRecipientNoValue != null) {
                                    header.ReRecipientNo = child1.getAttributeValue('Value','');
                                    headerI.ReRecipientNo = child1.getAttributeValue('Value','');
                                } else {
                                    header.ReRecipientNo = '';
                                    headerI.ReRecipientNo = '';
                                }
                            }
                            
                            //Vendor account number
                            if (child1.getAttributeValue('Name','') == 'VE_ACCOUNT_NO' ) {
                                VeAccountNoValue = child1.getAttributeValue('Value','');
                                if (VeAccountNoValue != null) {
                                    header.VeAccountNo = child1.getAttributeValue('Value','');
                                    headerI.VeAccountNo = child1.getAttributeValue('Value','');
                                } else {
                                    header.VeAccountNo = '';
                                    headerI.VeAccountNo = '';
                                }
                            }
                            
                            //Vendor account bank type
                            if (child1.getAttributeValue('Name','') == 'VE_PBANKTYPE' ) {
                                VePbanktypeValue = child1.getAttributeValue('Value','');
                                if (VePbanktypeValue != null) {
                                    header.VePbanktype = child1.getAttributeValue('Value','');
                                    headerI.VePbanktype = child1.getAttributeValue('Value','');
                                } else {
                                    header.VePbanktype = '';
                                    headerI.VePbanktype = '';
                                }
                            }
                            
                            //Vendor country
                            if (child1.getAttributeValue('Name','') == 'VE_COUNTRY' ) {
                                IvCountryValue = child1.getAttributeValue('Value','');
                                if (IvCountryValue != null) {
                                    header.VeCountry = child1.getAttributeValue('Value','');
                                    headerI.VeCountry = child1.getAttributeValue('Value','');
                                } else {
                                    header.VeCountry = '';
                                    headerI.VeCountry = '';
                                }
                            }
                            
                            //Invoice Total Tax Amount
                            if (child1.getAttributeValue('Name','') == 'INV_TOTAl_TAX_AMOUNT' ) {
                                IvTotalTaxAmtValue = child1.getAttributeValue('Value','');
                                if (IvTotalTaxAmtValue != null) {
                                    headerI.IvTotalTaxAmount = child1.getAttributeValue('Value','');
                                } else {
                                    headerI.IvTotalTaxAmount = '';
                                }
                            }
                        }
                    }
                    //Reading nodes of the XML attachment.
                    if(!tNode.getchildelements().isEmpty()) {
                        
                        for(Dom.XmlNode tchild1 :  tNode.getchildelements()) {
                            SG_WF_WS_Sap_Interface_MC_Style.ZmmSApmInInv invoiceItem = new SG_WF_WS_Sap_Interface_MC_Style.ZmmSApmInInv();
                            
                            //Invoice discount Amount 1
                            for(Dom.XmlNode tchild2 : tchild1.getchildelements()) {
                                if (tchild2.getAttributeValue('Name','') == 'INVI_DISCOUNT_AMOUNT1' ) {
                                    IvDisAmt11Value = tchild2.getAttributeValue('Value','');
                                    if (IvDisAmt11Value != null) {
                                        invoiceItem.IvDisAmt1 = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvDisAmt1 = '';
                                    }
                                }
                                
                                //Invoice discount Amount 2
                                if (tchild2.getAttributeValue('Name','') == 'INVI_DISCOUNT_AMOUNT2' ) {
                                    IvDisAmt22Value = tchild2.getAttributeValue('Value','');
                                    if (IvDisAmt22Value != null) {
                                        invoiceItem.IvDisAmt2 = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvDisAmt2 = '';
                                    }
                                }
                                
                                //Invoice discount Amount 3
                                if (tchild2.getAttributeValue('Name','') == 'INVI_DISCOUNT_AMOUNT3' ) {
                                    IvDisAmt33Value = tchild2.getAttributeValue('Value','');
                                    if (IvDisAmt33Value != null) {
                                        invoiceItem.IvDisAmt3 = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvDisAmt3 = '';
                                    }
                                }
                                
                                //Invoice discount percentage 1
                                if (tchild2.getAttributeValue('Name','') == 'INVI_DISCOUNT_PERCENT1' ) {
                                    IvDisPer11Value = tchild2.getAttributeValue('Value','');
                                    if (IvDisPer11Value != null) {
                                        invoiceItem.IvDisPer1 = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvDisPer1 = '';
                                    }
                                }
                                
                                //Invoice discount percentage 2
                                if (tchild2.getAttributeValue('Name','') == 'INVI_DISCOUNT_PERCENT2' ) {
                                    IvDisPer22Value = tchild2.getAttributeValue('Value','');
                                    if (IvDisPer22Value != null) {
                                        invoiceItem.IvDisPer2 = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvDisPer2 = '';
                                    }
                                }
                                
                                //Invoice discount percentage 3
                                if (tchild2.getAttributeValue('Name','') == 'INVI_DISCOUNT_PERCENT3' ) {
                                    IvDisPer33Value = tchild2.getAttributeValue('Value','');
                                    if (IvDisPer33Value != null) {
                                        invoiceItem.IvDisPer3 = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvDisPer3 = '';
                                    }
                                }
                                
                                //Invoice order number
                                if (tchild2.getAttributeValue('Name','') == 'INVI_ORDER_NO' ) {
                                    IvOrderNoValue = tchild2.getAttributeValue('Value','');
                                    if (IvOrderNoValue != null) {
                                        invoiceItem.IvOrderNo = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvOrderNo = '';
                                    }
                                }
                                
                                //Invoice position number
                                if (tchild2.getAttributeValue('Name','') == 'INVI_POS_NO' ) {
                                    IvPosNoValue = tchild2.getAttributeValue('Value','');
                                    if (IvPosNoValue != null) {
                                        invoiceItem.IvPosNo = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvPosNo = '';
                                    }
                                }
                                
                                //Invoice article number
                                if (tchild2.getAttributeValue('Name','') == 'INVI_ORI_ARTICLE_NO' ) {
                                    IvOriArticleNoValue = tchild2.getAttributeValue('Value','');
                                    if (IvOriArticleNoValue != null) {
                                        invoiceItem.IvOriArticleNo = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvOriArticleNo = '';
                                    }
                                }
                                
                                //Invoice order description
                                if (tchild2.getAttributeValue('Name','') == 'INVI_ORI_DESCRIPTION' ) {
                                    IvOriDescValue = tchild2.getAttributeValue('Value','');
                                    if (IvOriDescValue != null) {
                                        invoiceItem.IvOriDesc = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvOriDesc = '';
                                    }
                                }
                                
                                //Invoice quantity
                                if (tchild2.getAttributeValue('Name','') == 'INVI_QUANTITY' ) {
                                    IvQuantityValue = tchild2.getAttributeValue('Value','');
                                    if (IvQuantityValue != null) {
                                        invoiceItem.IvQuantity = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvQuantity = '';
                                    }
                                }
                                
                                //Invoice quantity unit
                                if (tchild2.getAttributeValue('Name','') == 'INVI_QUANTITY_UNIT' ) {
                                    IvUnitValue = tchild2.getAttributeValue('Value','');
                                    if (IvUnitValue != null) {
                                        invoiceItem.IvUnit = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvUnit = '';
                                    }
                                }
                                
                                //Invoice single net price
                                if (tchild2.getAttributeValue('Name','') == 'INVI_SINGLE_NET_PRICE' ) {
                                    IvSinglePriceValue = tchild2.getAttributeValue('Value','');
                                    if (IvSinglePriceValue != null) {
                                        invoiceItem.IvSinglePrice = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvSinglePrice = '';
                                    }
                                }
                                
                                //Invoice price per unit
                                if (tchild2.getAttributeValue('Name','') == 'INVI_PRICE_PER_UNIT' ) {
                                    IvPriceUnitValue = tchild2.getAttributeValue('Value','');
                                    if (IvPriceUnitValue != null) {
                                        invoiceItem.IvPriceUnit = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvPriceUnit = '';
                                    }
                                }
                                
                                //Invoice total net price
                                if (tchild2.getAttributeValue('Name','') == 'INVI_TOTAL_NET_PRICE' ) {
                                    IvTotalPriceValue = tchild2.getAttributeValue('Value','');
                                    if (IvTotalPriceValue != null) {
                                        invoiceItem.IvTotalPrice = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvTotalPrice = '';
                                    }
                                }
                                
                                //Invoice delivery number
                                if (tchild2.getAttributeValue('Name','') == 'INVI_DELIVERY_NO' ) {
                                    IvDelNoValue = tchild2.getAttributeValue('Value','');
                                    if (IvDelNoValue != null || IvDelNoValue != '') {
                                        invoiceItem.IvDelNo = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvDelNo = '';
                                    }
                                    
                                } 
                                
                                //indian line items
                                if (tchild2.getAttributeValue('Name','') == 'INVI_DELIVERY_POS' ) {
                                    IvDelPosValue = tchild2.getAttributeValue('Value','');
                                    if (IvDelPosValue != null || IvDelPosValue != '') {
                                        invoiceItem.IvDelPos = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvDelPos = '';
                                    }
                                }
                                
                                if (tchild2.getAttributeValue('Name','') == 'INVI_HSN_CODE' ) {
                                    IvHsnCodeValue = tchild2.getAttributeValue('Value','');
                                    if (IvHsnCodeValue != null || IvHsnCodeValue != '') {
                                        invoiceItem.IvHsnCode = tchild2.getAttributeValue('Value','');
                                    } else {
                                        invoiceItem.IvHsnCode = '';
                                    }
                                }
                            }
                            
                            invoiceItemLIST.add(invoiceItem);
                        } 
                    }
                    invoice.item = invoiceItemLIST;
                }
            }
            
            Boolean isXsi = false;
            String subStringBarcode;
            if ((IvBarcodeValue != null && IvBarcodeValue != '')) {
                subStringBarcode = IvBarcodeValue.substring(0, 3);
            }
            SET<String> endpointIdentifierSET  = new SET<String>(Label.Barcode_Identifier.split(';'));
            
            if (subStringBarcode != null || subStringBarcode != '') {
                if (endpointIdentifierSET.contains(subStringBarcode)) {
                    isXsi = true;
                }
            }
            SG_WF_WS_Sap_Interface_MC_Style.ZmmSApmInSf sfId = new SG_WF_WS_Sap_Interface_MC_Style.ZmmSApmInSf();
            //populate with sfId
            sfId.sfId = name;
            sfId.SfArciveId = pdfLink;
            SG_WF_WS_Sap_Interface_MC_Style.ZMM_APM_XML_BINDING stub = new SG_WF_WS_Sap_Interface_MC_Style.ZMM_APM_XML_BINDING(isXsi);
            stub.timeout_x = 30000;
            String username = (isXsi) ? Label.SAP_User_India.split(';')[0] : Label.SAP_User.split(';')[0] ;
            String password = (isXsi) ? Label.SAP_User_India.split(';')[1] :  Label.SAP_User.split(';')[1] ;
            Blob headerValue = Blob.valueOf(username+':'+password);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            
            Map<String,String> headersMAP = new Map<String, String>();
            headersMAP.put('KeyId', Label.SAP_Key_Id);
            headersMAP.put('Authorization', authorizationHeader);
            stub.inputHttpHeaders_x = headersMAP;
            
            //List of SCAN records to update with the SAP response 
            LIST<Scan__c> updateScanLIST = new LIST<Scan__c>();
            
            //Checking if scanRecordId is not NULL
            if(scanRecordId != NULL) {
                updateScanLIST = [SELECT Id, Name, SAP_Response__c, IFv2_SAPStatus__c
                                  FROM Scan__c
                                  WHERE ID =: scanRecordId];
            }
            
            try {
                SG_WF_WS_Sap_Interface_MC_Style.ZMmApiXmlrespProviderResponse_element response = stub.ZMmApiXmlrespProvider(header, invoice, sfId);
                //Checking of updateScanLIST is not empty
                if(!updateScanLIST.isEmpty()) {
                    if(String.isBlank(response.EvFailure)) {
                        for(Scan__c scan : updateScanLIST) {
                            scan.SAP_Response__c = String.valueOf(response.EvSuccess);
                            scan.IFv2_SAPStatus__c = 'Success';
                        }
                        IFv2_DmlController.UpdateScanRecord(updateScanLIST);
                    } else {
                        if(reTriggerCount < 3) {
                            sapCalloutMethod(scanRecordId, name);
                        } else {
                            //To replace standard error message with custom error message 
                            //Query for custom error messages 
                            LIST<IFv2_CustomErrorMessages__c> customErrorMessageLIST = IFv2_UtilsController.getCustomErrorMessages(response.EvFailure);
                            
                            //Map to create a map of standard errormessages and custom errormessages
                            MAP<String,String> standardCustomErrorMAP = new MAP<String,String>();
                            
                            //iterating over customErrorMessageLIST 
                            if(!customErrorMessageLIST.isEmpty()) {
                                
                                //Iterating over customErrorMessageLIST list 
                                for(IFv2_CustomErrorMessages__c iterator : customErrorMessageLIST) {
                                    standardCustomErrorMAP.put(iterator.StandardErrorMessage__c, iterator.CustomErrorMessage__c);
                                }
                            }
                            //Checking if standardCustomErrorMAP is not empty and updateScanLIST is not empty
                            if(!customErrorMessageLIST.isEmpty()) {
                                
                                for(Scan__c scan : updateScanLIST) {
                                    scan.SAP_Response__c = customErrorMessageLIST[0].CustomErrorMessage__c;
                                    //Updating the SAP Status
                                    scan.IFv2_SAPStatus__c = 'Failed';
                                } 
                            } else {
                                for(Scan__c scan : updateScanLIST) {
                                    scan.SAP_Response__c = response.EvFailure;
                                    
                                    //Updating the SAP Statu in case of failures 
                                    scan.IFv2_SAPStatus__c = 'Failed';
                                }
                            }
                            IFv2_DmlController.UpdateScanRecord(updateScanLIST);
                        } 
                    }
                }
            } catch (Exception e) {
                if(!updateScanLIST.isEmpty()) {
                    for(Scan__c scan : updateScanLIST) {
                        scan.SAP_Response__c = e.getMessage() + '\n' + e.getStackTraceString();
                        scan.IFv2_SAPStatus__c = 'Failed';
                    }
                }
                //Calling Generic DMl for Update of scan record
                if(!updateScanLIST.isEmpty()) {
                    IFv2_DmlController.UpdateScanRecord(updateScanLIST);
                }
            }
        } else {
            system.debug('httpSapCall : Method  is Deactivated');
        }
    }
}