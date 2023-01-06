/*******************************************************************************************************
* 
* @ Name : IFv2_ScanArchivalBatch
* @ Purpose : Class that collects Scan Records which are ready for archiving and proces them for archiving
* @ Author: Naga Sai
* @ Test Class Name : IFv2_ScanArchivalBatchTest
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   13-04-2019  |  nagasai.chalamalasetti@absyz.com     |  1.0          |  Initial Version

*********************************************************************************************************/

global class IFv2_ScanArchivalBatch implements Database.Batchable<sObject>{
    
    /** Each scan record which satisfies the condition of archival and also records which are archived will be queried **/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        date todaydate = date.today();
        LIST<String> sapStatusValues = label.CLIFv20192.split(',');
        String requestquery = 'SELECT Id, Name, ArchivingStatus__c, IFv2_ContentversionIds__c,(SELECT id,Name,ArchivalStatus__c,Workflow__c,lastmodifieddate,Status__c,ContentversionIds__c  from Requests__r) ' +
            'FROM Scan__c ' +
            'WHERE ArchivingStatus__c != \'considerforzipping\' ' +
            'AND (ArchivingStatus__c = \'Archived\' ' +
            'OR ArchivingDate__c <= :todaydate OR ArchivingStatus__c = \'Error\') AND IFv2_SAPStatus__c in:sapStatusValues order by lastmodifieddate Limit 1000';
        return Database.getQueryLocator(requestquery);      
    }
    
    //1. checks whether the scan record satisfies the archival conditon and separates them to a list
    //2. if the record is already archived, then an archival log is created in admin only object with record type archival logs, and once they are created ,respective scan is deleted
    //3. if not archived and if it satisfies archival conditon, then xml and pdf of the scan are created using IFv2_ParseScanToXMLANDPDF class.
    //4. Finally all the contentversions are queried and are filled into a IFv2_ContentversionIds__c field of request and status is changed to 'considerforzipping'. 
    
    global void execute(Database.BatchableContext BC, LIST<Scan__c> scanLIST) {
        /*Start of Logic to handle ICO requetss*/
        System.debug('enteirng execute');
        Boolean continueScanArchiving ;
        Boolean allICOsApproved=true;
        String WorkflowName ;
        DateTime ICOLastModifeddate;
        LIST<String> requestStatusValues = label.CLIFv20197.split(',');
        System.debug('scanLIST.size()'+scanLIST.size()); 
        if(scanLIST.size()==1){
            
            if(scanLIST[0].requests__r.size()==0 || scanLIST[0].ArchivingStatus__c == 'Archived'){
                continueScanArchiving = true;
                IFv2_ArchivalHandler.executeArchivalLogic(scanLIST[0].requests__r,WorkflowName);
            }
            
            
            else{
                 continueScanArchiving = false;
                for(IFv2_Request__c request : scanLIST[0].requests__r){
                    if(ICOLastModifeddate==Null){
                        ICOLastModifeddate = request.lastmodifieddate;
                        WorkflowName = request.Workflow__c;
                    }
                    if(ICOLastModifeddate!=Null){
                        if(request.lastmodifieddate > ICOLastModifeddate){
                            ICOLastModifeddate = request.lastmodifieddate;
                            WorkflowName = request.Workflow__c;
                            System.debug(request.name);
                        }
                    }system.debug('allICOsApproved '+allICOsApproved);
                    System.debug('request.Status__c'+request.Status__c); system.debug('requestStatusValues '+requestStatusValues);
                    if(!requestStatusValues.contains(request.Status__c)){
                        allICOsApproved = false;
                       
                    }
                    System.debug('allICOsApproved'+allICOsApproved);
                }
                //Now checkign for archival date
                System.debug('ICOLastModifeddate'+ICOLastModifeddate+'WorkflowName'+WorkflowName);
                if(allICOsApproved){
                    for(IFv2_Workflow__c workflow : [SELECT Id, Workflow__c , ArchivingAfterDays__c FROM IFv2_Workflow__c  where Workflow__c =:WorkflowName]){
                        system.debug('workflow '+workflow);
                        system.debug('ICOLastModifeddate.adddays((Integer)workflow.ArchivingAfterDays__c '+ICOLastModifeddate.adddays((Integer)workflow.ArchivingAfterDays__c));
                        system.debug('System.now() '+System.now());
                        if(ICOLastModifeddate.adddays((Integer)workflow.ArchivingAfterDays__c)<=System.now()) {
                            continueScanArchiving = true;
                            IFv2_ArchivalHandler.executeArchivalLogic(scanLIST[0].requests__r,WorkflowName);
                        }
                    }
                }
            }
            /*End of Logic to handle ICO requetss*/
            system.debug('continueScanArchiving '+continueScanArchiving);
            
            if(continueScanArchiving){
                /** Start of Variables Declaration **/
                //holds scans that are to be archived
                LIST<Scan__c> tobearchivedScanLIST = new LIST<Scan__c>();
                //holds scans that are archived
                LIST<Scan__c> archivedScanLIST = new LIST<Scan__c>();
                //holds admin only records that are to be inserted
                LIST<IFv2_AdminOnly__c> archivalLogLIST= new LIST<IFv2_AdminOnly__c>();
                //holds ids of scans to be archived
                SET<id> scanIdsToBeArchived = new SET<id>();
                //holds content document id mapped against request id 
                MAP<String,String> contentdocumentIdScanIdMAP = new MAP<String,String>();
                //holds request id against contentdocument version record ids
                MAP<String,String> scanIdcontentdocumentVersionsMAP = new MAP<String,String>();
                /** End of Variables Declaration **/
                
                //separating requests into two LISTs,
                //1. Adding to ArchivedScanLIST
                //2. Adding to TobeArchivedScanLIST
                for(Scan__c Scan : scanLIST ) {
                    if(Scan.ArchivingStatus__c == 'Archived') {
                        Scan.ArchivingStatus__c = 'ToBeDeleted';
                        archivedScanLIST.add(Scan);
                    } else {
                        
                        tobearchivedScanLIST.add(Scan);
                        scanIdsToBeArchived.add(Scan.id);
                        
                    }
                }
                system.debug('scanIdsToBeArchived '+scanIdsToBeArchived); system.debug('archivedScanLIST '+archivedScanLIST);
                //Creating Admin only records and the important fields are glacier id and scan name, which MAPs the scans
                // against its glacier location
                for(Scan__c Scan : archivedScanLIST) {
                    IFv2_AdminOnly__c ArchivalLog = new IFv2_AdminOnly__c();
                    ArchivalLog.RecordName__c = Scan.name;
                    //splitting the ContentversionIds__c into glacier id and region using separator ';'
                    LIST<String> GlacierInfo =  Scan.IFv2_ContentversionIds__c.split(';');
                    if(GlacierInfo.size()>0)
                        ArchivalLog.GlacierId__c = GlacierInfo[0];
                    if(GlacierInfo.size()>1)
                        ArchivalLog.Region__c = GlacierInfo[1];
                    if(GlacierInfo.size()>2)
                        ArchivalLog.Vault__c = GlacierInfo[2];
                    ArchivalLog.RecordTypeId = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('Archival Logs').getRecordTypeId();
                    archivalLogLIST.add(ArchivalLog);
                }
                //performing insert and delete 
                if(!archivalLogLIST.isEmpty()) 
                    IFv2_DmlController.GenericListDMLOperation(archivalLogLIST,'insert');
                if(!archivedScanLIST.isEmpty()){
                    if(Label.CLIFv20051=='Delete') 
                        IFv2_DmlController.GenericListDMLOperation(archivedScanLIST,'delete');
                    else
                        IFv2_DmlController.GenericListDMLOperation(archivedScanLIST,'update');
                }
                
                
                if(!scanIdsToBeArchived.isEmpty()) {
                    //generating XML and PDF for the scan record
                    for(Scan__c Scan : tobearchivedScanLIST) {
                        if(Scan.ArchivingStatus__c != 'Error')
                            IFv2_ParseScanToXMLANDPDF.generateXMLANDPDF(Scan);
                    }
                    
                    //From here querying contentversions and forming a MAP of scan id and contentversionids in comma separated form
                    //and this MAP will be used while updating requests to consider for zippping
                    //using LinkedEntityId getting the contentdpcumentlink,with which we can query content documentid
                    for(contentdocumentlink contentdocumentlink: [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in:scanIdsToBeArchived]) {
                        contentdocumentIdScanIdMAP.put(contentdocumentlink.ContentDocumentId,contentdocumentlink.LinkedEntityId);
                    }
                    //checking if contentversions are there or not 
                    if(!contentdocumentIdScanIdMAP.keySET().isEmpty()){
                        //querying contentversions using contentdocumentids
                        for(contentversion cv : [SELECT Id, ContentDocumentId FROM contentversion WHERE contentdocumentid in:contentdocumentIdScanIdMAP.keySET() AND islatest=true]) {
                            String scanId = contentdocumentIdScanIdMAP.get(cv.contentdocumentid);
                            
                            if(scanIdcontentdocumentVersionsMAP.keySET().contains(scanId)) {
                                //forming comma separated ids 
                                String cvidSET = scanIdcontentdocumentVersionsMAP.get(scanId).subStringbeforelast(')')+',\''+cv.id+'\')';
                                scanIdcontentdocumentVersionsMAP.put(scanId, cvidSET);
                            } else {
                                //forming comma separated ids 
                                String cvidSET = '(\''+cv.id+'\')';
                                scanIdcontentdocumentVersionsMAP.put(scanId, cvidSET);
                            }
                        }
                        //Iterating and updating status to considerforzipping
                        for(scan__c scan : tobearchivedScanLIST) {
                            if(scanIdcontentdocumentVersionsMAP.keyset().contains(scan.id)){
                                scan.IFv2_ContentversionIds__c = scanIdcontentdocumentVersionsMAP.get(scan.id);
                                scan.ArchivingStatus__c = 'considerforzipping';
                            }
                        }
                        if(!tobearchivedScanLIST.isEmpty())
                            IFv2_DmlController.GenericListDMLOperation(tobearchivedScanLIST,'update');
                        
                        
                    }
                }
            }
            
            
        }       
    }
    
    /* Finish method */
    global void finish(Database.BatchableContext BC) {
        
    }
}