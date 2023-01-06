/*******************************************************************************************************
* 
* @ Name : IFv2_ArchivalHandler
* @ Purpose : Class that collects Requests which are Approved,Rejected,Cancelled and meet Archival condition(currentdate=lastmodifieddate+workflowarchivaldate)
* @ Author: Naga Sai
* @ Test Class Name : IFV2_ArchivalBatchTest
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   06-06-2019  |  nagasai.chalamalasetti@absyz.com     |  1.0          |  Initial Version

********************************************************************************************************
/** Each reuqest record which satisfies the condition of archival and also records which are archived will be queried **/
public  class IFv2_ArchivalHandler {
   public static void executeArchivalLogic(LIST<IFv2_Request__c> RequestLIST,String Workflowname){
        /** Start of Variables Declaration **/
    LIST<IFv2_Request__c> TobeArchivedRequestLIST = new LIST<IFv2_Request__c>();
    LIST<IFv2_Request__c> ArchivedRequestLIST = new LIST<IFv2_Request__c>();
    LIST<IFv2_AdminOnly__c> ArchivalLogLIST= new LIST<IFv2_AdminOnly__c>();
    SET<id> RequestIdsToBeArchived = new SET<id>();
    MAP<String,String> contentdocumentIdRequestIdMAP = new MAP<String,String>();
    MAP<String,String> RequestIdcontentdocumentVersionsMAP = new MAP<String,String>();
    
    /** End of Variables Declaration **/
    system.debug('RequestLIST'+RequestLIST);
    /*Archive Parent request when Child request is archived for MGP*/
    if(Workflowname == Label.CLIFv20200){
        SET<Id> parentRequestIdSET = new SET<Id>();
        for(IFv2_Request__c req: RequestLIST){
            if(req.ParentRequest__c != null){
                parentRequestIdSET.add(req.ParentRequest__c);
            }
        }
        if(!parentRequestIdSET.isEmpty()){
            LIST<IFv2_Request__c> parentRequestLIST = new LIST<IFv2_Request__c>();
            String query =  'SELECT Id, Name, ArchivalStatus__c, ContentversionIds__c, Workflow__c, LastModifiedDate, ParentRequest__c, ChallanTypeofGatePass__c ' +
                            'FROM IFv2_Request__c ' +
                            'WHERE Id IN :parentRequestIdSET';
            parentRequestLIST = Database.query(query);
            if(!parentRequestLIST.isEmpty()){
                RequestLIST.addAll(parentRequestLIST);
            }
        }
    }
    /*Archive Parent request when Child request is archived for MGP - End*/
    
    
    
    //separating requests into two LISTs,
    //1. Adding to ArchivedRequestLIST
    //2. Adding to TobeArchivedRequestLIST
    for(IFv2_Request__c Request : RequestLIST ) {
        if(!(Workflowname == Label.CLIFv20199 && Request.ChallanTypeofGatePass__c == 'Returnable')){
            if(Request.ArchivalStatus__c == 'Archived') {
                Request.ArchivalStatus__c = 'ToBeDeleted';
                ArchivedRequestLIST.add(Request);
            } else {
                TobeArchivedRequestLIST.add(Request);
                RequestIdsToBeArchived.add(Request.id);
            }
        }
    }
    //Creating Admin only records and the important fields are glacier id and request name, which MAPs the requets against its glacier location
    for(IFv2_Request__c Request : ArchivedRequestLIST) {
        IFv2_AdminOnly__c ArchivalLog = new IFv2_AdminOnly__c();
        ArchivalLog.RecordName__c = Request.name;
        LIST<String> GlacierInfo = new LIST<String>();
        //splitting the ContentversionIds__c into glacier id and region using separator ';'
        if(string.isnotblank(Request.ContentversionIds__c))
        GlacierInfo = Request.ContentversionIds__c.split(';');
            if(GlacierInfo.size()>0)
        ArchivalLog.GlacierId__c = GlacierInfo[0];
        if(GlacierInfo.size()>1)
            ArchivalLog.Region__c = GlacierInfo[1];
        if(GlacierInfo.size()>2)
            ArchivalLog.Vault__c = GlacierInfo[2];
        ArchivalLog.RecordTypeId = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('Archival Logs').getRecordTypeId();
        ArchivalLogLIST.add(ArchivalLog);
    }
    if(!ArchivalLogLIST.isEmpty()) {
        IFv2_DmlController.GenericListDMLOperation(ArchivalLogLIST,'insert');
        if(label.CLIFv20081 =='Delete')
            IFv2_DmlController.GenericListDMLOperation(ArchivedRequestLIST,'delete');
            else
                IFv2_DmlController.GenericListDMLOperation(ArchivedRequestLIST,'update');
    }
    
    if(!RequestIdsToBeArchived.isEmpty()) {
        //generating XML and PDF for the request record
        /*Changes for Archiving Scan with ICO requests - Start*/
        /* Set<Id> ScanIdSet = new Set<Id>();
        for(IFv2_Request__c Request : TobeArchivedRequestLIST){
            if(Request.Scan__c != null){
                ScanIdSet.add(Request.Scan__c  );
            }
        }
        Map<Id,Scan__c> scanMap = new Map<Id,Scan__c>();
        if(!ScanIdSet.isEmpty()){
            scanMap = New MAP<Id,Scan__c>([SELECT Id, Name, ArchivingStatus__c, IFv2_ContentversionIds__c FROM Scan__c where Id IN :ScanIdSet]);
        }*/
        /*Changes for Archiving Scan with ICO requests - End*/

        for(IFv2_Request__c Request : TobeArchivedRequestLIST) {
            if(Request.ArchivalStatus__c!='fail'){
                IFv2_ParseRequestToXMLANDPDF.generateXMLANDPDF(Request);
                /*  if(Request.Scan__c != null && scanMap.containsKey(Request.Scan__c)){
                    IFv2_ParseScanToXMLANDPDF.generateXMLANDPDF(scanMap.get(Request.Scan__c),Request.Id);
                }*/
            }
        }
        
        //From here querying contentversions and forming a MAP of request id and contentversionids in comma separated form
        //and this MAP will be used while updating requests to consider for zippping
        //using LinkedEntityId getting the contentdpcumentlink,with which we can query content documentid
        for(contentdocumentlink contentdocumentlink: [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in:RequestIdsToBeArchived]) {
            contentdocumentIdRequestIdMAP.put(contentdocumentlink.ContentDocumentId,contentdocumentlink.LinkedEntityId);
        }
        
        //querying contentversions using contentdocumentids
        for(contentversion cv : [SELECT Id, ContentDocumentId FROM contentversion WHERE contentdocumentid in:contentdocumentIdRequestIdMAP.keySET() AND islatest=true]) {
            String RequestId = contentdocumentIdRequestIdMAP.get(cv.contentdocumentid);
            
            if(RequestIdcontentdocumentVersionsMAP.keySET().contains(RequestId)) {
                //forming comma separated ids 
                String cvidSET = RequestIdcontentdocumentVersionsMAP.get(RequestId).subStringbeforelast(')')+',\''+cv.id+'\')';
                RequestIdcontentdocumentVersionsMAP.put(RequestId, cvidSET);
            } else {
                //forming comma separated ids 
                String cvidSET = '(\''+cv.id+'\')';
                RequestIdcontentdocumentVersionsMAP.put(RequestId, cvidSET);
            }
        }
        //Iterating and updating status to considerforzipping
        for(IFv2_Request__c request : TobeArchivedRequestLIST) {
            
            request.ContentversionIds__c = RequestIdcontentdocumentVersionsMAP.get(request.id);
            request.ArchivalStatus__c = 'considerforzipping';
        }
        update TobeArchivedRequestLIST;
    }
   }
}