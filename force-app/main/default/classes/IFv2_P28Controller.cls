/*******************************************************************************************************
* 
* @ Name    :IFv2_P28Controller
* @ Purpose : Class that implements P28 functionality which is basically a replication of data loader
* @ Author  : Naga Sai
* @ Test Class Name : IFv2_P28ControllerTest
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   18-03-2019  |  nagasai.chalamalasetti@absyz.com     |  1.0          |  Initial Version

*******************************************************************************************************/

public without sharing class IFv2_P28Controller {
    
    //1. Inserts Admin only record with pending as status
    //2. Inserts the input parameter  "csvAsString" as contentversion under that Admin only record
    //3. Inserts contentdocumentlink record with linked entity id as adminonly record.
    
    @AuraEnabled
    public static void CreateFileInAdminOnlyObject(String csvAsString,String filename,String description){
        try{
            //Creating adminonly record of type P28 
            IFv2_AdminOnly__c adminonly = new IFv2_AdminOnly__c();
            adminonly.Status__c = 'Pending';
            adminonly.RecordTypeId = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get(label.CLIFv20111).getRecordTypeId();
            IFv2_DmlController.GenericDMLOperation(adminonly, 'insert');
            //Inserting contentVersions
            ContentVersion p28csv = new ContentVersion();
            p28csv.VersionData = Blob.valueOf(csvAsString);  
            p28csv.Title = filename;
            p28csv.PathOnClient = filename;
            IFv2_DmlController.GenericDMLOperation(p28csv, 'insert');
            //querying content doucment id for creating contentdocumentlink and storing description
            if(p28csv.id != Null) {
                String  contentdocumentid = [
                    SELECT ContentDocumentId 
                    FROM ContentVersion 
                    WHERE Id =:p28csv.id
                ].ContentDocumentId;
                if(contentdocumentid != Null) {
                    contentdocument contentDoc=[SELECT Description 
                                                FROM Contentdocument 
                                                WHERE Id=:contentdocumentid];
                    contentDoc.Description = description;
                    IFv2_DmlController.GenericDMLOperation(contentDoc, 'update');
                    //inserting contentdocument link
                    ContentDocumentLink contentDocLink = new ContentDocumentLink();
                    contentDocLink.contentdocumentid = ContentDocumentId;
                    contentDocLink.LinkedEntityId = adminonly.id;
                    // ShareType is either 'V', 'C', or 'I'
                    // V = Viewer, C = Collaborator, I = Inferred
                    contentDocLink.ShareType = 'V';
                    IFv2_DmlController.GenericDMLOperation(contentDocLink, 'insert');
                }
            }
        }
        Catch(Exception e){
            
        }
    }
    
    //1. getting the map of label and APIname , also viceversa map using schema class
    //2. decoding the csv String and separating header and data, from header ,we will get
    //labels and using above map APInames are taken and a contact record is formed with data
    //3. The record is upserted with field ID as external field and the success and erros are
    //caught using database.upsert result.
    //4. iterating over result class forming the success and failure csv files, using a boolean variable 
    //"insertFailed" to identify there is a failure and failure file exists.
    //5. Inserting the CSV files back to adminonly record using   input paramter "adminonlyId" and
    //also these success and error files are sent through mail to the logged in user. 
    
    @future 
    public static void CreateContact(String csvAsString,String adminonlyId){
        //Used to identify a failure
        Boolean insertFailed = False;
        Boolean insertSuccess = False;
        String textdataInNumberFieldErrormessage='';
        if(adminonlyId != Null){
            IFv2_AdminOnly__c adminonly=[
                SELECT Status__c 
                FROM IFv2_AdminOnly__c 
                WHERE id =:adminonlyId]; 
            if(adminonly.Status__c == 'Pending') {
                try{
                    //variables declaration and map formation of labels and API names
                    String[] csvFileLines;
                    /* List of contacts */
                    LIST<contact> contactLIST = new LIST<contact>();
                    String type='Contact';
                    Integer successandfailureindexes=-1;
                    Integer[] successindexes = new Integer[]{};
                        String successsheet='';
                    String failuresheet='';
                    /* Set of mismatched field labels */
                    SET<String> misMatchedFieldLabelSET = new SET<String>();
                    /* List of contentVersion */
                    LIST<contentversion> contentVersionLIST = new LIST<contentversion>();
                    /* List of contentDocuments */
                    LIST<ContentDocumentLink> contentDocumentLIST = new LIST<ContentDocumentLink>();
                    /* Maps for field schema Start */
                    MAP<String, Schema.SObjectType> schemaMAP = Schema.getGlobalDescribe();
                    Schema.SObjectType contactSchema = schemaMAP.get(type);
                    MAP<String, Schema.SObjectField> fieldMAP = contactSchema.getDescribe().fields.getMap();
                    MAP<String,String> labelFieldAPINameMAP = new MAP<String,String>();
                    MAP<String,String> fieldAPINameLabelMAP = new MAP<String,String>();
                    MAP<String,String> fieldAPINameTypeMAP = new MAP<String,String>();
                    /* Maps for field schema End */
                    
                    for (String fieldName: fieldMAP.keySet()) {
                        Schema.SObjectField fieldsc = fieldMAP.get(fieldName);
                        Schema.DisplayType FldType = fieldsc.getDescribe().getType();
                        fieldAPINameTypeMAP.put(fieldName,String.valueof(FldType));
                        labelFieldAPINameMAP.put(fieldMAP.get(fieldName).getDescribe().getLabel().replaceAll( '\\s+', '').toLowercase(),fieldName);
                        fieldAPINameLabelMAP.put(fieldName, fieldMAP.get(fieldName).getDescribe().getLabel());
                    }
                    //decoding CSv String starts
                    csvFileLines = csvAsString.split('\n'); 
                    system.debug('csvFileLines[0]'+csvFileLines[0]);
                    String[] headerData = csvFileLines[0].split(';');//separating header
                    String[] headerAPINames = new String[]{};
                        //getting APInames for header labels
                        for(Integer j=0;j<headerData.size();j++){
                            system.debug('headerData[j]'+headerData[j]);
                            if(headerData[j]!=Null){
                                
                                if(labelFieldAPINameMAP.get(headerData[j].trim().replaceAll( ',', '').replaceAll( '\\s+', '').tolowerCase())==Null){
                                    insertFailed = true;
                                    misMatchedFieldLabelSET.add(headerData[j]);
                                    
                                }
                                else{
                                    
                                    if(j==headerData.size()-1){
                                        
                                        headerAPINames.add(labelFieldAPINameMAP.get(headerData[j].trim().replaceAll( ',', '').replaceAll( '\\s+', '').tolowerCase()));
                                    }
                                    else{
                                        headerAPINames.add(labelFieldAPINameMAP.get(headerData[j].replaceAll( ',', '').replaceAll( '\\s+', '').tolowerCase()));
                                    }
                                }
                            }
                        }
                    if(insertFailed)
                        failuresheet =  handleMismatchOfColumns('cannot find field with this label '+misMatchedFieldLabelSET,csvAsString);
                    if(!insertFailed){
                        system.debug('insert not failed');
                        //forming contact data ,by iterating over each row in CSV file and having necessary null checks
                        for(Integer i=1; i<csvFileLines.size(); i++){
                            if(!insertFailed){
                                Contact contactRecord = new Contact();           
                                String[] csvRecordData = csvFileLines[i].split(';');
                                for(Integer k=0; k<csvRecordData.size(); k++){
                                    if(csvRecordData[k] != Null){
                                        if(String.isNotBlank(csvRecordData[k])){
                                            
                                            //Depending on the field data types converting the data respectively
                                            String fieldType = fieldAPINameTypeMAP.get(headerAPINames[k]);
                                            if(fieldType == 'currency' || fieldType == 'double' || fieldType == 'percent' || fieldType == 'decimal' )
                                            {
                                                if(csvRecordData[k].remove('.').remove('-').isNumeric()){
                                                    contactRecord.put(headerAPINames[k],decimal.valueOf(csvRecordData[k]));
                                                }
                                                else {
                                                    insertFailed = True;
                                                    failuresheet =  handleMismatchOfColumns(label.CLIFv20191+' '+headerAPINames[k],csvAsString);
                                                    break;
                                                }
                                            }
                                            else if(fieldType == 'boolean')
                                            {
                                                contactRecord.put(headerAPINames[k], Boolean.valueOf(csvRecordData[k])); 
                                            }                   
                                            else if(fieldType == 'date')
                                            {
                                                contactRecord.put(headerAPINames[k], date.valueOf(csvRecordData[k])); 
                                            }                
                                            else
                                            {
                                                if(k!=csvRecordData.size()-1)
                                                    contactRecord.put(headerAPINames[k], csvRecordData[k].trim());
                                                else{
                                                    contactRecord.put(headerAPINames[k],csvRecordData[k].replaceall(',','').trim());
                                                }
                                                
                                            }
                                        }
                                    }
                                    
                                }
                                
                                //making a list
                                contactLIST.add(contactRecord);
                            }
                        }
                        for(contact c:contactLIST){
                            if(String.isblank(c.id))
                                c.id=Null;
                        }
                        //using database.upsert upserting the list and here Id is the external field
                        Schema.SObjectField field = Contact.Fields.Id;
                        if(!insertFailed){
                            Database.UpsertResult [] srList = Database.upsert(contactLIST,field , false);
                            //appending ID to success sheet
                            successsheet = successsheet+','+ 'Id';
                            //forming headers for both sheets
                            for(String header : headerAPINames){
                                successsheet = successsheet+','+ fieldAPINameLabelMAP.get(header);
                                failuresheet = failuresheet+','+ fieldAPINameLabelMAP.get(header);
                            }
                            //adding error column to the failure sheet(CLIFv20150---Error Description)
                            failuresheet = label.CLIFv20150+','+failuresheet;
                            //formattign the sheet by removing the initial commas
                            successsheet = successsheet.replaceFirst(',','');
                            failuresheet =  failuresheet.replaceFirst(',','');
                            //iterating over result and making the body for success and failure file
                            for (Database.UpsertResult successRecord : srList) {
                                successandfailureindexes++;
                                if (successRecord.isSuccess()) {
                                    insertSuccess = True;
                                    successindexes.add(successandfailureindexes);
                                    successsheet=successsheet+'\n';
                                    //using a separate varibale for holding row, it is childsuccesssheet
                                    String childsuccesssheet='';
                                    sobject contact = contactlist[successandfailureindexes];
                                    childsuccesssheet = childsuccesssheet+','+ contact.get('id');
                                    for(String header:headerAPINames){
                                        childsuccesssheet = childsuccesssheet+','+ contact.get(header);
                                    }
                                    childsuccesssheet =   childsuccesssheet.replaceFirst(',','');
                                    successsheet = successsheet+childsuccesssheet;
                                }
                                else {
                                    insertFailed = True;
                                    // Operation failed, so get all errors                
                                    for(Database.Error errorDetail : successRecord.getErrors()) {
                                        failuresheet = failuresheet+ '\n';
                                        //using a separate varibale for holding row, it is childfailuresheet
                                        String childfailuresheet='';
                                        //getting error message and storing it
                                        childfailuresheet = childfailuresheet+ errorDetail.getStatusCode() + ': ' + errorDetail.getMessage();
                                        sobject contact = contactlist[successandfailureindexes];
                                        for(Integer p = 0; p<headerAPINames.size(); p++){
                                            childfailuresheet = childfailuresheet+','+ contact.get(headerAPINames[p]);
                                        }
                                        failuresheet = failuresheet+childfailuresheet.replace('\n','');
                                        
                                    }
                                }
                                
                            }
                            
                            //updating status of admin only record 
                        }
                    }
                    if(insertFailed) 
                        adminonly.Status__c = 'Fail';
                    else {
                        adminonly.Status__c = 'Success';
                    }
                    IFv2_DmlController.GenericDMLOperation(adminonly, 'update');
                    ContentVersion SuccessCv = new ContentVersion();
                    ContentVersion FailureCv = new ContentVersion();
                    //inserting success and failures in admin only and it follows this order
                    //1. inserting contentversions.
                    //2. getting contentdocument ids of contentversions inserted and using them creating contentdocuemnt link
                    
                    if(insertSuccess){
                        
                        SuccessCv.VersionData = Blob.valueOf(successsheet);
                        SuccessCv.Title = label.CLIFv20151;
                        SuccessCv.PathOnClient = label.CLIFv20151;
                        contentVersionLIST.add(SuccessCv);
                        
                    }
                    //only if insert failed creating failure file
                    if(insertFailed){
                        
                        FailureCv.VersionData = Blob.valueOf(failuresheet);
                        FailureCv.Title = label.CLIFv20152;
                        FailureCv.PathOnClient =  label.CLIFv20152;
                        contentVersionLIST.add(FailureCv);
                    }
                    
                    try {
                        IFv2_DmlController.GenericListDMLOperation(contentVersionLIST, 'insert');
                        //contentdocumentlink insertion logic
                        LIST<contentversion>  resultContentVersionLIST = [
                            SELECT ContentDocumentId 
                            FROM ContentVersion 
                            WHERE Id =:SuccessCv.id or id=:FailureCv.id
                        ];
                        
                        for( contentversion cdv :resultContentVersionLIST){
                            ContentDocumentLink cdl = new ContentDocumentLink();
                            cdl.contentdocumentid = cdv.ContentDocumentId;
                            cdl.LinkedEntityId = adminonly.Id;
                            // ShareType is either 'V', 'C', or 'I'
                            // V = Viewer, C = Collaborator, I = Inferred
                            cdl.ShareType = 'V';
                            contentDocumentLIST.add(cdl);
                        }
                        try {
                            IFv2_DmlController.GenericListDMLOperation(contentDocumentLIST, 'insert');
                            
                        } catch(DMLException e) {
                            
                        }
                    } catch(DMLException e) {
                    }
                    //Email logic, sending success and failure files to the logged in user
                    
                    //Sucesss
                    if(insertSuccess){
                        Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
                        Blob csvBlob = blob.valueOf(successsheet);
                        String csvName = label.CLIFv20151;
                        csvAttachment.setFileName(csvName);
                        csvAttachment.setBody(csvBlob);
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        String[] toAddresses = new String[]{userinfo.getUserEmail()};
                            String subject = label.CLIFv20153;
                        email.setSubject(subject);
                        email.setToAddresses(toAddresses);
                        email.setPlainTextBody(label.CLIFv20154);
                        email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment});
                        Messaging.SendEmailResult[] successResult = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                    }
                    //Sending failure file only if failure exists
                    if(insertFailed){
                        Messaging.EmailFileAttachment csvAttachment1 = new Messaging.EmailFileAttachment();
                        Blob csvBlob1 = blob.valueOf(failuresheet);
                        String csvName1 =  label.CLIFv20152;	//CLIFv20152 contains name of file which is sent via email
                        csvAttachment1.setFileName(csvName1);
                        csvAttachment1.setBody(csvBlob1);
                        Messaging.SingleEmailMessage email1 = new Messaging.SingleEmailMessage();
                        String[] toAddresses1 = new String[]{userinfo.getUserEmail()};
                            String subject1 = label.CLIFv20153;		//CLIFv20153 contains subject of email
                        email1.setSubject(subject1);
                        email1.setToAddresses(toAddresses1);
                        email1.setPlainTextBody(label.CLIFv20154);//CLIFv20154 contains body of email
                        email1.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment1});
                        Messaging.SendEmailResult[] failureResult = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email1});
                    }
                    
                    
                }
                catch (Exception e)
                {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(e);
                }  
            }
        }
    }
    
    //1. This method will be invoked if there is a column in csv ,whose header does not match with any of 
    //field label in the contact object
    //2. It just takes two input parameters  a. Error message which contains the mismatched field labels 
    // b. uploaded csv file in form of String    
    //3. then failure sheet is formed and is returned.
    
    public static String handleMismatchOfColumns(String errormessage,String csvString){
        //Variables declaration
         String[] csvFileLines = csvString.split('\n'); 
        String header;
        String AllChilds='';
        //Iterating over file lines and just appending the error cell to the sheet
        for(integer i=0;i<csvFileLines.size();i++){
            
            if(i==0){
                LIST<String> labelList = csvFileLines[i].split(';') ;
                header = label.CLIFv20150;
                for(String label:labelList){
                    header = header+','+label;
                }
                header += '\n';
            }
            else {
                
                LIST<String> data = csvFileLines[i].split(';') ;
                String child = '';
                for(String cell:data){
                    child = child+','+cell;
                }
                //Appending erorr cell
                AllChilds += errormessage.replace(',','')+child+'\n';
            }
        }
        return header+AllChilds;
    }
    //1. This is used by lightning component to display history of P28
    //2. It returns a wrapper which is directly used by datatable in lightning.
    //3. firstly it gets all the admin only records of type P28 and using the data in them a 
    // wrapper is formed.
    //4. using admin only ids ,contentversionIds and description of contentdocument are queried. these are 
    //also stored in that wrapper
    
    @AuraEnabled(cacheable = true)
    public static LIST<p28Logswrapper> getp28Logs(Integer pageSize, Integer offset){
        //Variable declaration
        SET<String> adminonlyIds = new SET<String>();
        LIST<p28Logswrapper> p28LogswrapperList = new LIST<p28Logswrapper>();
        MAP<String,String> linkedentityContentDocumentIdMAP = new MAP<String,String>();
        MAP<String,String> linkedentityContentVersionIdMAP = new MAP<String,String>();
        MAP<String,String> linkedentityDescriptionMAP = new MAP<String,String>();
        MAP<String,String> linkedentityTitleMap = new MAP<String,String>();
        //querying admin only data of type P28
        LIST<IFv2_AdminOnly__c> p28LogLIST = [
            SELECT Status__c, Id, CreatedDate 
            FROM IFv2_AdminOnly__c 
            WHERE RecordTypeId =:Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get(label.CLIFv20111).getRecordTypeId() 
            ORDER BY CreatedDate DESC LIMIT :pageSize OFFSET :offset];
        //preparing the wrapper with data from the p28LogLIST
        if(!p28LogLIST.isEmpty()) {
            for(IFv2_AdminOnly__c adminonly : p28LogLIST){
                adminonlyids.add(adminonly.id);
                p28Logswrapper p28log = new p28Logswrapper(adminonly.id,adminonly.createddate,Null,Null,adminonly.status__c,Null,Null);
                p28LogswrapperList.add(p28log); 
            }
            //contentversion and contentdocuemnt logic starts, we need them for getting
            //1. file description
            //2. file name 
            //3. contentversion id which is used for downloading
            //forming respective maps 
            if(!adminonlyids.isEmpty()){
                LIST<ContentDocumentLink> contentDocumentLIST = [SELECT ContentDocumentId,linkedentityid from ContentDocumentLink where linkedentityid in:adminonlyids];
                for(ContentDocumentLink cdl:[SELECT ContentDocumentId,linkedentityid from ContentDocumentLink where linkedentityid in:adminonlyids]){
                    linkedentityContentDocumentIdMAP.put( cdl.contentdocumentid,cdl.linkedentityid);
                }
                if(!linkedentityContentDocumentIdMAP.isEmpty()){
                    for(Contentversion cv:[SELECT Id,TITLE,contentdocumentid,contentdocument.description from Contentversion where contentdocumentid in:linkedentityContentDocumentIdMap.keyset()]){
                        String linkedentityId = linkedentityContentDocumentIdMAP.get(cv.contentdocumentid);
                        linkedentityContentVersionIdMAP.put(linkedentityId+'.'+cv.title,cv.id);
                        if(cv.title != label.CLIFv20151 && cv.title != label.CLIFv20152){
                            linkedentityDescriptionMAP.put(linkedentityId, cv.contentdocument.description);
                            linkedentityTitleMap.put(linkedentityId, cv.title);
                        }
                    }
                    //completing the wrapper data with the files information queried above
                    for(p28Logswrapper p28log:p28LogswrapperList){
                        if(linkedentityContentVersionIdMAP.keySet().contains(p28log.adminonlyId+'.'+label.CLIFv20151))
                            p28log.successfile = linkedentityContentVersionIdMAP.get(p28log.adminonlyId+'.'+label.CLIFv20151);
                        if(linkedentityContentVersionIdMAP.keySet().contains(p28log.adminonlyId+'.'+ label.CLIFv20152))
                            p28log.failurefile = linkedentityContentVersionIdMAP.get(p28log.adminonlyId+'.'+ label.CLIFv20152);
                        p28log.description = linkedentityDescriptionMAP.get(p28log.adminonlyId);
                        p28log.filename = linkedentityTitleMap.get(p28log.adminonlyId);
                    }
                    return p28LogswrapperList;
                }
                else{
                    return null;
                }
            }
            else {
                return null;
            }
        }
        else{
            
            return null;
        }
        
    }
    
    public class p28Logswrapper{
        @AuraEnabled
        public String adminonlyId;//Holds record it
        @AuraEnabled
        public Datetime createddate;//holds created date of admin only record
        @AuraEnabled
        public String description;//holds file description
        @AuraEnabled
        public String filename;//holds file name
        @AuraEnabled
        public String status;//holds status of upsert operation
        @AuraEnabled
        public String successfile;//holds id of success file
        @AuraEnabled
        public String failurefile;//holds id of failure file
        
        public p28Logswrapper(String adminonlyId,Datetime createddate,String description,String filename,String status,String successfile,String failurefile){
            this.adminonlyId = adminonlyId; 
            this.createddate = createddate;
            this.description = description;
            this.filename = filename;
            this.status = status;
            this.successfile = successfile;
            this.failurefile = failurefile;
        }
    }
}