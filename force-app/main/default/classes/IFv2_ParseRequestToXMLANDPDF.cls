/*******************************************************************************************************
* 
* @ Name    :IFv2_ParseRequestToXMLANDPDF
* @ Purpose : Class that creates XML and PDf of the request record 
* @ Author  : Naga Sai
* @ Test Class Name : IFv2_ParseRequestToXMLANDPDFTest
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   14-03-2018  |  nagasai.chalamalasetti@absyz.com     |  1.0          |  Initial Version
*   23-04-2018  |  nagasai.chalamalasetti@absyz.com     |  1.1          |  Added Logic for related list XML

*******************************************************************************************************/

public class IFv2_ParseRequestToXMLANDPDF
{
    /**
1. using IFv2_PrintableViewController PDf will be generated, leveraging the existing code.
2. Using DOM class and its methods, also XML stream writer forming the XML
3. creating the contentversions and contentdocument links for the PDF and XML
**/
    public static void generateXMLANDPDF(IFv2_Request__c Request)
    {
        if(Request != null) {
            //Using pagereference instaniating the printable view page and getting the blob as pdf
            PageReference pr = new PageReference('/apex/IFv2_PrintableView');
            pr.getParameters().put('Id', Request.Id);
            Blob pdfBlob;
            if(Test.IsRunningTest())
                pdfBlob = Blob.valueOf('testdata');  
            else{
                String modifiedPR = pr.getContent().tostring().replace('<button class="button" onclick="printPDF();"> Print </button>','');
                pdfBlob = blob.valueOf(modifiedPR);
            }
            apexpages.StandardController sc = new ApexPages.StandardController(Request);
            //leveragin the printableview controller for the XML purpose, this class returns map of field name and its value
            IFv2_PrintableViewController v=new IFv2_PrintableViewController(sc);
            //v.getDynamicallyHTMLforRelatedList();
            v.getApprovalRelatedList();
            //logic for XML starts,initiating DOM class
            Dom.Document doc = new Dom.Document();
            //xmlstreamwriter is used to form the xml 
            XmlStreamWriter w = new XmlStreamWriter();
            w.writeStartDocument(null, '1.0');
            w.writeStartElement(null, 'Request', null);
            w.writeStartElement(null, 'RequestDetails', null);
            for(String section :v.SectionFieldMap.keyset()){
                //getting the sections,in the form of section and its related data
                list<IFv2_FieldWrapperClass> FieldWrapperList=v.SectionFieldMap.get(section);
                //iterating over each section and writing the data using xml stream writer
                for(IFv2_FieldWrapperClass FieldWrapper:FieldWrapperList){
                    w.writeStartElement(null,FieldWrapper.APINAME , null);
                    if(String.valueOf(v.FieldAPIAndValueMap.get(FieldWrapper))!=Null)
                        w.writeCharacters(String.valueOf(v.FieldAPIAndValueMap.get(FieldWrapper)));
                    else {
                        w.writeCharacters('');
                    }
                    w.writeEndElement();
                }
            }
            w.writeEndElement();
            //XML for related list is formed
            //used to identify end of related list xml
            Boolean isSafeToGetNextXmlElement = true;
            //used to identify end of approval hsotory xml
            Boolean approvalHistoryDone = false;
            //used to identify end of legacy approval hsotory xml
            Boolean legacyApprovalHistoryDone = false;
            Boolean chatterDone = false;
            Boolean attachmentsDone = false;
            
            String readerdata ;//Holds xml of related list
            //Assigning the xml to the readerdata variable
            
            if(v.relatedListXMLStreamWriter!=Null && v.relatedListXMLStreamWriter.getXmlString()!=''){
                if(String.isNotblank(v.relatedListXMLStreamWriter.getXmlString()) && v.relatedListXMLStreamWriter.getXmlString()!=''){
                    readerdata = v.relatedListXMLStreamWriter.getXmlString();
                }
            }
            //Assigning the approval list xml to the readerdata variable
            else  if(v.approvalListXMLStreamWriter!=Null && v.approvalListXMLStreamWriter.getXmlString()!=''){
                if(String.isNotblank(v.approvalListXMLStreamWriter.getXmlString()) && v.approvalListXMLStreamWriter.getXmlString()!=''){
                    readerdata = v.approvalListXMLStreamWriter.getXmlString();
                    approvalHistoryDone = true;
                }
            }
            //Assigning the oldapproval xml to the readerdata variable
            else if(v.oldApprovalListXMLStreamWriter!=Null &&  v.oldApprovalListXMLStreamWriter.getXmlString()!=''){
                if(String.isNotblank(v.oldApprovalListXMLStreamWriter.getXmlString())){
                    readerdata = v.oldApprovalListXMLStreamWriter.getXmlString();
                    legacyApprovalHistoryDone = true;
                }
            }
            //Assigning the oldapproval xml to the readerdata variable
            else if(IFv2_PrintableViewController.chatterListXMLStreamWriter!=Null &&  IFv2_PrintableViewController.chatterListXMLStreamWriter.getXmlString()!=''){
                if(String.isNotblank(IFv2_PrintableViewController.chatterListXMLStreamWriter.getXmlString())){
                    readerdata = IFv2_PrintableViewController.chatterListXMLStreamWriter.getXmlString();
                    chatterDone = true;
                }
            }
            else if(IFv2_PrintableViewController.attachmentsListXMLStreamWriter!=Null &&  IFv2_PrintableViewController.attachmentsListXMLStreamWriter.getXmlString()!=''){
                if(String.isNotblank(IFv2_PrintableViewController.attachmentsListXMLStreamWriter.getXmlString())){
                    readerdata = IFv2_PrintableViewController.attachmentsListXMLStreamWriter.getXmlString();
                    attachmentsDone = true;
                }
            }
            if(readerdata!=Null){
                XmlStreamReader relatedListreader =new XmlStreamReader(readerdata);
                w.writeStartElement(null, 'RelatedListDetails', null);
                if(relatedListreader!=Null && String.isNotblank(readerdata))
                    while(isSafeToGetNextXmlElement) {
                        if (relatedListreader.hasNext() && relatedListreader!=Null) {
                            //Filling start tag
                            if (relatedListreader.getEventType() == XmlTag.START_ELEMENT) {
                                w.writeStartElement(null,relatedListreader.getLocalName() , null);
                            }
                            //filling value
                            if (relatedListreader.getEventType() == XmlTag.CHARACTERS) {
                                w.writeCharacters(relatedListreader.getText());
                            }
                            //filling end tag
                            if (relatedListreader.getEventType() == XmlTag.END_ELEMENT) {
                                w.writeEndElement();
                            }
                            relatedListreader.next();
                        } 
                        else {
                            //Filling start tag
                            if (relatedListreader.getEventType() == XmlTag.START_ELEMENT) {
                                w.writeStartElement(null,relatedListreader.getLocalName() , null);
                            }
                            //filling value
                            if (relatedListreader.getEventType() == XmlTag.CHARACTERS) {
                                w.writeCharacters(relatedListreader.getText());
                            }
                            //filling end tag
                            if (relatedListreader.getEventType() == XmlTag.END_ELEMENT) {
                                w.writeEndElement();
                            }
                            //setting Approval history for xml
                            if(v.ApprovalListXMLStreamWriter!=Null && !approvalHistoryDone && v.approvalListXMLStreamWriter.getXmlString()!=''){
                                readerdata = v.ApprovalListXMLStreamWriter.getXmlString();
                                relatedListreader =new XmlStreamReader(readerdata);
                                approvalHistoryDone = true;
                            }
                            //setting old Approval history for xml
                            else if(v.oldApprovalListXMLStreamWriter!=Null && !legacyApprovalHistoryDone && v.oldApprovalListXMLStreamWriter.getXmlString()!=''){
                                readerdata = v.oldApprovalListXMLStreamWriter.getXmlString();
                                relatedListreader =new XmlStreamReader(readerdata);
                                legacyApprovalHistoryDone = true;
                            }
                            //setting old Approval history for xml
                            else if(IFv2_PrintableViewController.chatterListXMLStreamWriter!=Null && !chatterDone && IFv2_PrintableViewController.chatterListXMLStreamWriter.getXmlString()!=''){
                                readerdata = IFv2_PrintableViewController.chatterListXMLStreamWriter.getXmlString();
                                relatedListreader =new XmlStreamReader(readerdata);
                                chatterDone = true;
                            }
                            else if(IFv2_PrintableViewController.attachmentsListXMLStreamWriter!=Null && !attachmentsDone && IFv2_PrintableViewController.attachmentsListXMLStreamWriter.getXmlString()!=''){
                                readerdata = IFv2_PrintableViewController.attachmentsListXMLStreamWriter.getXmlString();
                                relatedListreader =new XmlStreamReader(readerdata);
                                attachmentsDone = true;
                            }
                            else
                                isSafeToGetNextXmlElement = false;
                            
                        }
                        
                    }  
                w.writeEndElement();
            }          
            
            w.writeEndElement();
            w.writeEndDocument();
            String xmlOutput = w.getXmlString();
            w.close();
            doc.Load(xmlOutput);
            String xmldata = doc.toXmlString();//geeting the xml data in form of String
            Blob  xmlBlob  = Blob.valueOf(xmldata);  
            /*contentversions and contentdocument links are inserted from here */
            /* LIST of  ContentVersion */
            LIST<ContentVersion> contentVerionLIST= new LIST<ContentVersion>();
            /* ContentVerion object for XML*/
            ContentVersion xmlContentVersion = new ContentVersion();
            xmlContentVersion.VersionData = xmlBlob;
            xmlContentVersion.Title = Request.name+'.xml';
            xmlContentVersion.PathOnClient = Request.name+'.xml';
            contentVerionLIST.add(xmlContentVersion);
            /* ContentVerion object for PDF */
            ContentVersion pdfContentVersion = new ContentVersion();
            pdfContentVersion.VersionData = pdfBlob;
            pdfContentVersion.Title = Request.name+'.html';
            pdfContentVersion.PathOnClient = Request.name+'.html';
            contentVerionLIST.add(pdfContentVersion);
            
            try {
                if(!contentVerionLIST.isEmpty()) {
                    IFv2_DmlController.GenericListDMLOperation(contentVerionLIST, 'insert');
                }
                /* List of ContentDocument for xml and pdf */
                LIST<ContentDocumentLink> contentDocumentLIST = new LIST<ContentDocumentLink>();
                /* Inserting xml contentdocument link */
                ContentDocumentLink xmlContentDocumentLink = new ContentDocumentLink();
                if(xmlContentVersion != null) {
                    xmlContentDocumentLink.ContentDocumentId = [
                        SELECT ContentDocumentId 
                        FROM ContentVersion 
                        WHERE Id =:xmlContentVersion.id
                    ].ContentDocumentId;
                }
                
                xmlContentDocumentLink.LinkedEntityId = Request.id;
                // ShareType is either 'V', 'C', or 'I'
                // V = Viewer, C = Collaborator, I = Inferred
                xmlContentDocumentLink.ShareType = 'V';
                contentDocumentLIST.add(xmlContentDocumentLink);
                
                /* Inserting pdf contentdocument link */
                ContentDocumentLink pdfContentDocumentLink = new ContentDocumentLink();
                if(pdfContentVersion != null) {
                    pdfContentDocumentLink.ContentDocumentId = [
                        SELECT ContentDocumentId 
                        FROM ContentVersion 
                        WHERE Id =:pdfContentVersion.id
                    ].ContentDocumentId; 
                }
                pdfContentDocumentLink.LinkedEntityId = Request.id;
                // ShareType is either 'V', 'C', or 'I'
                // V = Viewer, C = Collaborator, I = Inferred
                pdfContentDocumentLink.ShareType = 'V';
                contentDocumentLIST.add(pdfContentDocumentLink);
                try {
                    if(!contentDocumentLIST.isEmpty()) {
                        IFv2_DmlController.GenericListDMLOperation(contentDocumentLIST, 'insert');
                    }  
                } catch(DMLException e) {
                    system.debug('Request.Id'+Request.Id);
                    System.debug(e); 
                }
            } catch(DMLException e) {
                system.debug('Request.Id'+Request.Id);
                System.debug(e);  
            } 
        }
    }     
}