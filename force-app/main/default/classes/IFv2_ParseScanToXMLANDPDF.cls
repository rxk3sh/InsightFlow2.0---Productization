/*******************************************************************************************************
* 
* @ Name            : IFv2_ParseScanToXMLANDPDF
* @ Purpose         : Class that takes input paramter as scan record and created a pdf and xml out of it
* @ Author          : Naga Sai
* @ Test Class Name : IFv2_ScanArchivalBatchTest
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   13-04-2019  |  nagasai.chalamalasetti@absyz.com     |  1.0          |  Initial Version
*   22-04-2019  |  nagasai.chalamalasetti@absyz.com     |  1.1          |  Added logic for relatedlist
*********************************************************************************************************/
public with sharing class IFv2_ParseScanToXMLANDPDF {
    
    //1. using IFv2_ScanPrintableViewController PDf will be generated
    //2. Using DOM class and its methods, also XML stream writer forming the XML
    //3. creating the contentversions and contentdocument links for the PDF and XML
    
    public static void generateXMLANDPDF(scan__c scanrecord)
    {
        //Using pagereference instaniating the printable view page and getting the blob as pdf
        PageReference pr = new PageReference('/apex/IFv2_ScanPrintableView');
        pr.getParameters().put('id', scanrecord.id);
        Blob pdfBlob;
        if(Test.IsRunningTest())
            pdfBlob = Blob.valueOf('testdata');  
        else
            pdfBlob = pr.getContent();
        apexpages.StandardController sc = new ApexPages.StandardController(scanrecord);
        //this class has a logic that process fields of a a fieldset queries them 
        IFv2_ScanPrintableViewController v = new IFv2_ScanPrintableViewController(scanrecord.id);
        v.getgeneratePDF();
        if(!v.records.isEmpty()){
            //getting the queried data
            SObject scan =  v.records[0];
            //logic for XML starts,initiating DOM class
            Dom.Document doc = new Dom.Document();
            //xmlstreamwriter is used to form the xml 
            XmlStreamWriter w = new XmlStreamWriter();
            w.writeStartDocument(null, '1.0');
            w.writeStartElement(null, 'Scan', null);
            w.writeStartElement(null, 'ScanDetail', null);
            //this FieldwrapperList is formed in getgeneratePDF method of IFv2_ScanPrintableViewController
            for(IFv2_ScanPrintableViewController.Fieldwrapper fielddescribe :v.FieldwrapperList){
                w.writeStartElement(null,fielddescribe.APIName , null);
                //segregating based on reference fields and normal fields and 
                //also considering last modified by ,creatd by and owner id fields in another condition
                if(fielddescribe.type=='REFERENCE' && fielddescribe.APIName.contains('__c'))
                    w.writeCharacters(string.valueof((scan.getsobject(fielddescribe.APIName.replace('__c','__r')).get('Name') == null ? ' ' : scan.getsobject(fielddescribe.APIName.replace('__c','__r')).get('Name')))) ;
                else if(fielddescribe.APIName =='LastModifiedById' || fielddescribe.APIName=='CreatedById' || fielddescribe.APIName=='OwnerId'){
                    if(!test.isRunningTest())
                        w.writeCharacters(string.valueof((scan.getsobject(fielddescribe.APIName.replace('Id','')).get('Name') == null ? ' ' : scan.getsobject(fielddescribe.APIName.replace('Id','')).get('Name'))));
                }
                else
                    w.writeCharacters(string.valueof((scan.get(fielddescribe.APIName) == null ? ' ' : scan.get(fielddescribe.APIName))));
                w.writeEndElement();
            }
            w.writeEndElement();
            //generating XML for related list
            Boolean chatterDone = false;
            Boolean attachmentsDone = false;
            String readerdata ;//Holds xml of related list
            if(v.relatedListXMLStreamWriter!=Null && v.relatedListXMLStreamWriter.getXmlString()!=''){
                readerdata = v.relatedListXMLStreamWriter.getXmlString();
            }
            else if(IFv2_PrintableViewController.chatterListXMLStreamWriter!=Null &&  IFv2_PrintableViewController.chatterListXMLStreamWriter.getXmlString()!=''){
                if(String.isNotblank(IFv2_PrintableViewController.chatterListXMLStreamWriter.getXmlString())){
                    chatterDone = true;
                    readerdata = IFv2_PrintableViewController.chatterListXMLStreamWriter.getXmlString();
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
                
                //used to identify end of related list xml
                Boolean isSafeToGetNextXmlElement = true;
                w.writeStartElement(null, 'RelatedListDetails', null);
                while(isSafeToGetNextXmlElement) {
                    //Filling start tag
                    if (relatedListreader.hasNext()) {
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
            //get the XML 
            String xmlOutput = w.getXmlString();
            w.close();
            doc.Load(xmlOutput);
            String xmldata = doc.toXmlString();//geeting the xml data in form of string
            Blob  xmlBlob  = Blob.valueOf(xmldata);  
            //contentversions and contentdocument links are inserted from here 
            LIST<ContentVersion> cvlist= new LIST<ContentVersion>();
            ContentVersion XMLcv = new ContentVersion();
            XMLcv.VersionData = xmlBlob;
            XMLcv.Title = scan.get('name')+'.xml';
            XMLcv.PathOnClient =  scan.get('name')+'.xml';
            cvlist.add(XMLcv);
            ContentVersion PDFcv = new ContentVersion();
            PDFcv.VersionData = pdfBlob;
            PDFcv.Title =  scan.get('name')+'.html';
            PDFcv.PathOnClient =  scan.get('name')+'.html';
            cvlist.add(PDFcv);
            //converting Existing attachments of scan to files
            LIST<Attachment> scanAttachments = new LIST<Attachment>(); 
            if(scanrecord != Null) {
                scanAttachments = [select id,name,body,parentid from Attachment where parentid=:scanrecord.id];    
            }
            
            for(Attachment record: scanAttachments) {
                ContentVersion cv = new ContentVersion();
                cv.VersionData = record.body;
                cv.Title = record.name;
                cv.PathOnClient = record.name;
                cvlist.add(cv);
            }
            try {
                IFv2_DmlController.GenericListDMLOperation(cvlist, 'insert');
                list<ContentDocumentLink> cdlList = new list<ContentDocumentLink>();
                SET<id> contentDocumentIds = new SET<Id>();
                SET<Id> cvids = new SET<Id>();
                for(ContentVersion cv:cvlist){
                    cvids.add(cv.id);   
                }
                if(!cvids.isEmpty()) {
                    for(ContentVersion cv: [select ContentDocumentId from ContentVersion where id in:cvids]){
                        contentDocumentIds.add(cv.ContentDocumentId); 
                    } 
                }
                
                for(Id contentdocumentid:contentDocumentIds) {
                    ContentDocumentLink cdl = new ContentDocumentLink();  
                    cdl.ContentDocumentId = contentdocumentid;
                    cdl.LinkedEntityId = scan.id;
                    // ShareType is either 'V', 'C', or 'I'
                    // V = Viewer, C = Collaborator, I = Inferred
                    cdl.ShareType = 'V';
                    cdlList.add(cdl);  
                }
                
                try {
                    IFv2_DmlController.GenericListDMLOperation(cdlList, 'insert');
                    
                } catch(DMLException e) {
                    System.debug(e);
                    
                }
            }
            catch(DMLException e) {
                System.debug(e);
                
            }
        }
    }
}