/*******************************************************************************************************
* 
* @ Name		:  IFv2_FieldSetFormController
* @ Purpose		:  Server side controller for IFv2_FieldSetFormParent_Component
* @ Author		:  Anoop Ravindran
* @ Test Class  :  IFv2_FieldSetFormControllerTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   30-10-2018      |  anoop.ravindran@absyz.com    |  1.0          |  Initial Version
*   02-12-2019		|  external.debasmita.rawooth@seg-automotive.com|  Added changes for Lex contracting custom mapping
*******************************************************************************************************/

public without sharing class IFv2_FieldSetFormController {
    
    public class FieldSetWrapper {
        
        @AuraEnabled public LIST<FieldSetForm> metadata { get; set; }
        @AuraEnabled public LIST<String> fieldNames{ get;set; }
        @AuraEnabled public LIST<IFv2_PurchasingApproval__mdt> directIndirectdefaultList{ get; set; }
        @AuraEnabled public SObject record { get; set; }
        
        public FieldSetWrapper() {
            metadata = new LIST<FieldSetForm>();
            fieldNames = new LIST<String>();
            directIndirectdefaultList = new LIST<IFv2_PurchasingApproval__mdt>();
        }
    }
    
    public class FieldSetForm {
        
        @AuraEnabled public IFv2_Section__mdt section;
        @AuraEnabled public LIST<IFv2_FieldWrapperClass> fields { get; set; }
        @AuraEnabled public LIST<String> fieldNames{ get; set; }
        
        public FieldSetForm() {
            section = new IFv2_Section__mdt();
            fields = new LIST<IFv2_FieldWrapperClass>();
            fieldNames = new LIST<String>();
        }
    }
    
    public class mapWrapper {
        
        @AuraEnabled public String key{ get;set; }
        @AuraEnabled public MAP<String, String> value{ get;set; }
        
        public mapWrapper() {}
    }
    
    /*Method to get query the record*/
    @AuraEnabled
    public static FieldSetWrapper getForm(String objectName, String recordId, String recordType) {
        //Return parameter
        FieldSetWrapper wrapper = new FieldSetWrapper();
        //map of section name and section
        MAP<String, IFv2_Section__mdt> sectionMap = new MAP<String, IFv2_Section__mdt>();
        //list of the sections for the workflow
        LIST<IFv2_Section__mdt> sections = new LIST<IFv2_Section__mdt>();
        //list to store the section ids
        LIST<String> sectionIDs = new LIST<String>();
        //list to store the fieldsets from the sections
        LIST<String> fieldSetNameLIST = new LIST<String>();
        //list of APIs of all the fields on the layout
        LIST<String> fieldAPIs = new LIST<String>();
        //list of FieldSetForm wrapper containing all sections and fields
        LIST<FieldSetForm> details = new LIST<FieldSetForm>();
        
        //checking logged in User is Approver
        Boolean isApprover = (!String.isBlank(recordId)) ? checkUserIsApprover(recordId) : false;
        //SObject Global describe
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        //Converting String to SObject
        SObject record = objectType.newSObject();
        
        //If record type is Custom Object
        if(recordType == 'Custom Object') {
            LIST<IFv2_Request__c> requestLIST = new LIST<IFv2_Request__c>();
            try {
                if(!String.isBlank(recordId)) {
                    requestLIST = [SELECT Id, Workflow__c, Region__c, SubjectType__c FROM IFv2_Request__c WHERE Id=:recordId];
                } 
            } catch(Exception e) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(e); 
            }
            
            if(!requestLIST.isEmpty()) {
                //taking the first record
                IFv2_Request__c request = requestLIST[0];
                //workflow name of the request record
                String workflow = request.Workflow__c;
                
                //To do mapping only on page load of clone functionality for Purchasing workflows
                if(workflow == Label.CLIFv20005 || workflow == Label.CLIFv20007) {
                    //Region of the Request Record
                    String Region = request.Region__c;
                    //Subject Type of the Request Record
                    String SubjectType = request.SubjectType__c;
                    //Getting Purchasing mapping
                    wrapper.directIndirectdefaultList = getPurchasingApproval(Region, SubjectType, workflow);
                }
                
                //Retrieveing section metadata for request records
                sections = getSectionMetadata(workflow, 'request details', isApprover);
                if(!sections.isEmpty()) {
                    for(IFv2_Section__mdt section : sections) {
                        //listing section Ids
                        sectionIDs.add(section.Id);
                        //listing field set names
                        fieldSetNameLIST.add(section.Value__c);
                        //mapping key as fieldset name and value as section record
                        sectionMap.put(section.Value__c, section);
                    }
                    
                    //If Workflow is Special Frieghts
                    if(workFlow == Label.CLIFv20052) {
                        fieldSetNameLIST.add('IFv2_UserFields'); 
                    }
                    
                    //additional generic lookup fields, like created by, modified by
                    fieldSetNameLIST.add('IFv2_LookupFields');
                    System.debug('sectionIDs****' +sectionIDs);
                    //get custom field labels
                    MAP<String, SObject> labelMAP = getFieldLabels(sectionIDs);
                    //Object Global Describe
                    Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
                    //Getting Field Sets under the Object
                    MAP<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap();
                    //Getting Fields under the Object
                    MAP<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
                    System.debug('fieldSetNameLIST****' +fieldSetNameLIST);
                    //create field wrapper from fieldset
                    for(String fieldSetName : fieldSetNameLIST) {
                        //Initialization
                        FieldSetForm data = new FieldSetForm();
                        //Getting the particular Field Set
                        Schema.FieldSet fieldSet = fieldSetMap.get(fieldSetName);
                        System.debug('fieldSetName****' +fieldSetName);
                        System.debug('fieldSet****' +fieldSet);
                        //Getting Fields under the Field Set
                        LIST<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
                        //Initialization
                        LIST<IFv2_FieldWrapperClass> fields = new LIST<IFv2_FieldWrapperClass>();
                        for(Schema.FieldSetMember fieldSetMember : fieldSetMembers) {
                            //Describing the fields under FieldSet
                            IFv2_FieldWrapperClass field = new IFv2_FieldWrapperClass(fieldSetMember, objectName, request, fieldMap);
                            //listing Field APIs
                            fieldAPIs.add(field.APIName);
                            
                            //Changes to handle different search fields for Lookup Component - Start
                            //Changing the labels
                            if(labelMAP.containsKey(field.APIName)) {
                                if(labelMAP.get(field.APIName).get('FieldLabel__c') != null) {
                                    field.Label = String.valueOf(labelMAP.get(field.APIName).get('FieldLabel__c'));
                                }
                                if(labelMAP.get(field.APIName).get('DisplayLabel__c') != null) {
                                    field.DisplayLabel = String.valueOf(labelMAP.get(field.APIName).get('DisplayLabel__c'));
                                }
                                if(labelMAP.get(field.APIName).get('LookupFilter__c') != null) {
                                    field.LookupFilter = String.valueOf(labelMAP.get(field.APIName).get('LookupFilter__c'));
                                }
                                if(labelMAP.get(field.APIName).get('LookupObject__c') != null) {
                                    field.LookupObject = String.valueOf(labelMAP.get(field.APIName).get('LookupObject__c'));
                                }
                                if((Boolean)labelMAP.get(field.APIName).get('AllowCreate__c')) {
                                    field.isCreateable = (Boolean)labelMAP.get(field.APIName).get('AllowCreate__c');
                                }
                            }
                            //Changes to handle different search fields for Lookup Component - End
                            fields.add(field);
                        }
                        if(sectionMap.containsKey(fieldSetName)) {
                            data.section = sectionMap.get(fieldSetName);
                            data.fields = fields;
                            details.add(data);
                        }
                    }
                }
            }
            fieldAPIs.add('Id');
            wrapper.metadata = details;
            wrapper.fieldNames = fieldAPIs;
        } 
        //Custom setting
        else if(recordType == 'Custom Setting') {
            //list of workflow custom settings
            LIST<IFv2_Workflow__c> workflows = new LIST<IFv2_Workflow__c>();
            try {
                if(!String.isBlank(recordId)) {
                    workflows = [SELECT Workflow__c,Id FROM IFv2_Workflow__c WHERE Id=:recordId];
                }
            } catch(Exception e) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(e);    
            }
            IFv2_Workflow__c workflow;
            String workflowName = '';
            if(!workflows.isEmpty()) {
                workflow = workflows[0];
                workflowName = workflow.Workflow__c;
            } else {
                workflow = new IFv2_Workflow__c();
            }
            
            //Get sections
            sections = getSectionMetadata(workflowName, 'workflow details', isApprover);
            //list of string of the fields for workflow detail section
            LIST<String>fieldNamesList = new LIST<String>();
            if(!sections.isEmpty()) {
                //get list of fields from the section
                for(IFv2_Section__mdt section : sections) {
                    sectionIDs.add(section.Id);
                    fieldNamesList.addAll(section.Value__c.split(','));
                    //Assigning the fields to variable
                    String fieldNames = section.Value__c;
                    //Check if the section is using ExtendedValue__c for storing additional fields
                    if(section.HasExtendedValue__c && section.ExtendedValue__c != null) {
                        fieldNames += ',' + section.ExtendedValue__c;
                    }
                    fieldNamesList.addAll(fieldNames.split(','));
                    sectionMap.put(fieldNames, section);
                }
                
                //Global Object describe
                Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
                //Create fields for each section
                for(String fieldNames : sectionMap.keySet()) {
                    FieldSetForm data = new FieldSetForm();
                    LIST<IFv2_FieldWrapperClass> fields;
                    if(recordId != null && recordId != '') {
                        fields = IFv2_FieldSetUtility.getFieldFromAPINames(recordId,'IFv2_Workflow__c', fieldNames);
                    } else {
                        fields = IFv2_FieldSetUtility.getFieldFromAPINames(null, 'IFv2_Workflow__c', fieldNames);
                    }
                    
                    data.section = sectionMap.get(fieldNames); 
                    data.fields = fields;
                    details.add(data);
                }
            }
            
            wrapper.metadata = details;
            //get the record
            wrapper.record = getRecord(fieldAPIs, objectName, record, recordType, recordId);
            wrapper.fieldNames = fieldAPIs;
        }
        
        return wrapper;
    }
    
    
    /* method to query Section metadata*/
    @AuraEnabled
    public static LIST<IFv2_Section__mdt> getSectionMetadata(String workflow, String sectionType, Boolean isApprover) {
        
        LIST<Schema.SObjectField> fieldList = Schema.getGlobaldescribe().get('IFv2_Section__mdt').getDescribe().fields.getMap().values();	//list of schema of the fields
        
        String query = 'SELECT '+ fieldList[0].getDescribe().getName() ;	//string for the dynamic query
        
        Integer flag = 0;
        for(Schema.SObjectField field : fieldList) {
            if(flag != 0) {
                query += ', ' + field.getDescribe().getName();
            } else {
                flag = 1;
            }
        }
        
        query += ' FROM IFv2_Section__mdt';
        if(!String.isBlank(workflow)) {
            query += ' WHERE Workflows__r.Name__c = \'' + workflow + '\'' +
                ' AND Type__c = \'' + sectionType + '\' '+
                ' AND Active__c = true ';
            if(!isApprover && sectionType == 'request details') {
                query += ' AND IsApproverOnly__c = false';
            }
        } else {
            query += ' WHERE Type__c = \'' + sectionType + '\' '+
                ' AND Active__c = true' +
                ' AND Workflows__c = null';
        }
        
        query += ' ORDER BY SectionNumber__c ASC';
        LIST<IFv2_Section__mdt> sectionMetadata = new LIST<IFv2_Section__mdt>();	//list of section metadata
        try {
            sectionMetadata = Database.query(query);
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e); 
        }
        return sectionMetadata;
    }
    
    /*Method to fetch custom field labels*/
    public static MAP<String, SObject> getFieldLabels(LIST<String> sections) {
        //map of custom labels
        MAP<String, SObject> labelMAP = new MAP<String, SObject>();
        /*Changes to handle different search fields for Lookup Component - Start*/
        for(SObject label : [SELECT Id, FieldAPIName__c, FieldLabel__c, DisplayLabel__c, LookupFilter__c, LookupObject__c, AllowCreate__c
                             FROM IFv2_CustomFieldLabel__mdt 
                             WHERE Section__c IN :sections]) {
                                 labelMAP.put(String.valueOf(label.get('FieldAPIName__c')), label);
                             }
        return labelMAP;
    }
    /*Changes to handle different search fields for Lookup Component - End*/
    
    /*method to get Record*/
    public static SObject getRecord(LIST<String> fieldAPIs, String objectName, SObject record, String recordType, String recordId) {
        /* Query for Custom Object*/
        if(recordType == 'Custom Object') {
            if(!fieldAPIs.isEmpty()) {
                String query = 'SELECT ';	
                for(String field : fieldAPIs) {
                    if(field.toLowerCase() != 'id' && field.toLowerCase() != 'workflow__c') {
                        query += field + ', ';
                    }
                }
                query += 'Id, Workflow__c, OwnerId FROM ' + objectName + ' WHERE Id = \'' + recordId + '\'';
                
                LIST<SObject> queryResult = IFv2_FieldSetUtility.recordQuery(query);	//list to store the fetched records
                if(!queryResult.isEmpty()) {
                    record = queryResult[0];
                }
            }
        } else {
            /*Query for Custom setting*/
            MAP<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
            if(fieldMap.keySet().size()>0) {
                String query = 'SELECT ';
                for(String field : fieldMap.keySet()) {
                    if(field.toLowerCase() != 'id') {
                        query += field + ', ';
                    }
                }
                query += 'id FROM ' + objectName;
                
                query += ' WHERE id = \'' + recordId + '\'';
                LIST<SObject> queryResult = new LIST<SObject>();
                try {
                    queryResult = Database.query(query);
                } catch(Exception e) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(e);   
                }
                
                if(!queryResult.isEmpty()) {
                    record = queryResult[0];
                }
            }
        }
        
        return record;
    }
    /*Method to refresh Record based on record Id and field names*/
    @AuraEnabled
    public static sobject refreshRecord(String recordId, LIST<String> fieldNames, String objectName, Boolean isRelatedList) {
        Sobject record = Schema.getGlobalDescribe().get(objectName).newSobject();
        if(isRelatedList == null) {
            isRelatedList = false;
        }
        SET<String> fieldNamesSet = new SET<String>();
        //if(fieldNames != NULL)
        fieldNamesSet.addAll(fieldNames);
        system.debug('fieldNamesSet:'+fieldNamesSet);
        if(recordId != null) {
            string query = 'SELECT ';
            if(fieldNamesSet!=null && !fieldNamesSet.isEmpty()) {
                query+=String.join(New LIST<String>(fieldNamesSet), ',');
            } else {
                query+= 'Id, Workflow__c';
            }
            query+=' FROM '+objectName+' WHERE Id= \''+recordId+'\' LIMIT 1';
            LIST<Sobject> records = new LIST<Sobject>();	//list of records
            try {
                records = database.query(query);
            } catch(Exception e) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(e);  
            }
            if(!records.isEmpty()){
                record = records[0];
                if(objectName == 'IFv2_Request__c' &&( record.get('Workflow__c') == Label.CLIFv20046 || record.get('Workflow__c') == Label.CLIFv20199) && isRelatedList){//China Travel Application and MGP India
                    MAP<string,Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
                    record = getRoleApproverMapping(record, null,null,objectName,fieldMap);
                    record = getPredefinedMapping(record, null,null,objectName,fieldMap);
                    IFv2_DmlController.GenericDMLOperation(record, 'update');                }
            }
            return record;
        }
        return null;
    }
    /* Save Record and call method for saving extension records*/
    @AuraEnabled
    public static SObject saveRecords(String recordStr, String relRecMap, String objectName,String recordType, Boolean buttonType, String previousRecord) {
        /* Change in RoleApproverMapping for removing hard coding - Start*/
        if(!String.isBlank(recordStr)){
            Sobject record = (Sobject)JSON.deserialize(recordStr, Sobject.class);
            
            LIST<mapWrapper> relatedRecordLIST = (LIST<mapWrapper>)JSON.deserialize(relRecMap, LIST<mapWrapper>.class);	//list of mapWrapper to store related records
            Account lexRec = new Account();
            
            if(recordType =='Custom Object') {
                map<string,Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap(); 	//map of field and its schema
                record = getRoleApproverMapping(record, relatedRecordLIST,previousRecord,objectName,fieldMap);
                /* Change in RoleApproverMapping for removing hard coding - End*/
                
                record = getPredefinedMapping(record, relatedRecordLIST,previousRecord,objectName,fieldMap);
                if(!relatedRecordLIST.isEmpty()) {
                    mapWrapper relatedRecord = relatedRecordLIST[0];
                    if(record.get(relatedRecord.key) != null &&  record.get(relatedRecord.key) != '') {
                        if((String)record.get('Workflow__c') == Label.CLIFv20309){
                            lexRec = (Account)saveExtensionLexRecord((String)record.get(relatedRecord.key), relRecMap, objectName);
                        	Map<String, Object> mlexRec = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(lexRec));
                            if(mlexRec.get(String.valueOf(Account.IFv2_Nominated_LEX2__c)) == null)
                                lexRec.IFv2_Nominated_LEX2__c=null;
                            if(mlexRec.get(String.valueOf(Account.IFv2_PEX_Name__c)) == null)
                                lexRec.IFv2_PEX_Name__c=null;
                        }else
                            saveExtensionRecord((String)record.get(relatedRecord.key), relRecMap, objectName);
                    }
                }
                User lexMgr = new User();
                User pexMgr = new User();
                System.debug('lex record>>'+lexRec);
                //Lex approver update
                try{
                    if(lexRec != null && (String)record.get('Workflow__c') == Label.CLIFv20309){
                    If(lexRec.IFv2_Nominated_LEX2__c != null){
                        lexMgr = IFv2_UtilsController.getUserManager(lexRec.IFv2_Nominated_LEX2__c);
                        record.put('Approver1__c',lexRec.IFv2_Nominated_LEX2__c);
                    }else{
                        record.put('Approver1__c',null);
                    }
                    
                    if(lexMgr != null){
                        record.put('Approver2__c',lexMgr.Id);
                    }else
                        record.put('Approver2__c',null);
                    
                    If(lexRec.IFv2_PEX_Name__c != null){
                        pexMgr = IFv2_UtilsController.getUserManager(lexRec.IFv2_PEX_Name__c);
                        record.put('InformWhenApproved__c',lexRec.IFv2_PEX_Name__c);
                        record.put('InformWhenRejected__c',lexRec.IFv2_PEX_Name__c);
                    }else{
                        record.put('InformWhenApproved__c',null);
                        record.put('InformWhenRejected__c',null);
                    }
                    
                    if(pexMgr != null){
                        record.put('InformWhenApproved2__c',pexMgr.Id);
                        record.put('InformWhenRejected2__c',pexMgr.Id);
                    }else{
                        record.put('InformWhenApproved2__c',null);
                        record.put('InformWhenRejected2__c',null);
                    }
                }
                else if( (String)record.get('Workflow__c') == Label.CLIFv20007 && (String)record.get('SubjectType__c')==Label.CLIFv20330){
                    System.debug('purchasing>entering');
                    record.put('InformWhenApproved__c',Label.CLIFv20331);
                   // record.put('InformWhenRejected__c','0051v000005ZGIRAA4');
                    }
                    else if( (String)record.get('Workflow__c') == Label.CLIFv20007 && (String)record.get('SubjectType__c')==Label.CLIFv20335){
                    System.debug('purchasing>entering');
                    record.put('InformWhenApproved__c',Label.CLIFv20336);
                     record.put('InformWhenApproved2__c',Label.CLIFv20337);
                   // record.put('InformWhenRejected__c','0051v000005ZGIRAA4');
                    }
                }Catch(Exception e)
                {
                    System.debug('Exception>>'+e);
                } 
                
                IFv2_DmlController.GenericDMLOperation(record, 'upsert');
            }
            else if(recordType =='Custom Setting') {
                LIST<IFv2_Workflows__mdt> MetaDataLIST = new LIST<IFv2_Workflows__mdt>();	//list of workflow metadata
                try {
                    MetaDataLIST = [select id,Name__c from IFv2_Workflows__mdt where Name__c =: (String)record.get('Workflow__c') limit 1];
                } catch(Exception e) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(e);
                }
                if(MetaDataLIST.size() > 0) {
                    //database.UpsertResult result = Database.upsert(record);
                    try {
                        IFv2_DmlController.GenericDMLOperation(record, 'upsert');
                    } catch(System.DmlException e) {
                        IFv2_ExceptionUtilitiesController.exceptionHandler(e);
                    }
                } else {
                    AuraHandledException exc = new AuraHandledException('Metadata record not found!');
                    //exc.setMessage(e.getMessage());
                    throw exc;
                }
            }
            return record;
        }
        else{
            return null;
        }
    }
    /*Method to Save fields on Extension Object for Lex WF*/
    //  @future
    public static Sobject saveExtensionLexRecord(String recordId, String relRecMap, String objectName) {
        
        LIST<mapWrapper> relatedRecordLIST = (LIST<mapWrapper>)JSON.deserialize(relRecMap, LIST<mapWrapper>.class);
        mapWrapper relRecord = relatedRecordLIST[0];
        String relObjName = Schema.getGlobalDescribe()
            .get(objectName)
            .getDescribe()
            .fields
            .getMap()
            .get(relRecord.key)
            .getDescribe()
            .getReferenceTo()[0]
            .getDescribe()
            .getName();
        
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(relObjName);
        SObject returnRec = objType.newSObject();
        
        if(!String.isBlank(recordId) && !String.isBlank(objectName) && !relatedRecordLIST.isEmpty()) {
            mapWrapper relatedRecord = relatedRecordLIST[0];
            String relatedObjName = Schema.getGlobalDescribe()
                .get(objectName)
                .getDescribe()
                .fields
                .getMap()
                .get(relatedRecord.key)
                .getDescribe()
                .getReferenceTo()[0]
                .getDescribe()
                .getName();
            
            MAP<String, String> relatedValueMAP = (MAP<String, String>)relatedRecord.value;	//map of related record values
            if(!relatedValueMAP.keySet().isEmpty()) {
                String query = 'SELECT ';
                for(Object fieldVal : relatedValueMAP.keySet()) {
                    String field = String.valueOf(fieldVal);
                    if(field.toLowerCase() != 'id') {
                        query += field + ', ';
                    }
                }
                query += 'id FROM ' + relatedObjName + ' WHERE id = \'' + recordId + '\'';
                LIST<SObject> queryResult = new LIST<SObject>();	//list to store the records retrieved
                try {
                    queryResult = database.query(query);
                } catch(Exception e) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(e);
                }
                
                if(!queryResult.isEmpty()) {
                    
                    /* SObject Global describe*/ 
                    Schema.SObjectType objectType = Schema.getGlobalDescribe().get(relatedObjName);
                    
                    /* Converting String to SObject*/ 
                    SObject record = objectType.newSObject();
                    record = queryResult[0];
                    MAP<String, SObjectField> fieldmap = objectType.getDescribe().fields.getMap();	//map of field and its schema
                    
                    for(Object fieldVal : relatedValueMAP.keySet()) {
                        String field = String.valueOf(fieldVal);
                        if(fieldmap.containsKey(field) && fieldmap.get(field).getDescribe().isUpdateable()){
                            if( relatedValueMAP.get(field)!=null && relatedValueMAP.get(field)!='') {
                                if(String.valueOf(fieldmap.get(field).getDescribe().getType()).toLowerCase() == 'datetime') {
                                    String val = String.valueOf(relatedValueMAP.get(field));
                                    val = val.replace('T', ' ');
                                    record.put(field, DateTime.valueOfGmt(val));
                                } else if(String.valueOf(fieldmap.get(field).getDescribe().getType()).toLowerCase() == 'date') {
                                    String val = String.valueOf(relatedValueMAP.get(field));
                                    val = val.split('T')[0];
                                    record.put(field, Date.valueOf(val));
                                } else if(String.valueOf(fieldmap.get(field).getDescribe().getType()).toLowerCase() == 'number' ||
                                          String.valueOf(fieldmap.get(field).getDescribe().getType()).toLowerCase() == 'currency' ||
                                          String.valueOf(fieldmap.get(field).getDescribe().getType()).toLowerCase() == 'percent' ||
                                          String.valueOf(fieldmap.get(field).getDescribe().getType()).toLowerCase() == 'double') {
                                              record.put(field, Decimal.valueOf((String)relatedValueMAP.get(field)));
                                          } else if(String.valueOf(fieldmap.get(field).getDescribe().getType()).toLowerCase() == 'boolean') {
                                              record.put(field, Boolean.valueOf((String)relatedValueMAP.get(field)));
                                          } else {
                                              record.put(field, (String)relatedValueMAP.get(field));
                                          }
                            }
                            else {
                                record.put(field,null);
                            }
                        }
                        
                    }
                    IFv2_DmlController.GenericDMLOperation(record, 'update');
                    returnRec = record;
                }
            }
        }
        return returnRec;
    }
    /*Method to Save fields on Extension Objects*/
    //  @future
    public static void saveExtensionRecord(String recordId, String relRecMap, String objectName) {
        LIST<mapWrapper> relatedRecordLIST = (LIST<mapWrapper>)JSON.deserialize(relRecMap, LIST<mapWrapper>.class);
        
        if(!String.isBlank(recordId) && !String.isBlank(objectName) && !relatedRecordLIST.isEmpty()) {
            mapWrapper relatedRecord = relatedRecordLIST[0];
            String relatedObjName = Schema.getGlobalDescribe()
                .get(objectName)
                .getDescribe()
                .fields
                .getMap()
                .get(relatedRecord.key)
                .getDescribe()
                .getReferenceTo()[0]
                .getDescribe()
                .getName();
            
            MAP<String, String> relatedValueMAP = (MAP<String, String>)relatedRecord.value;	//map of related record values
            
            if(!relatedValueMAP.keySet().isEmpty()) {
                String query = 'SELECT ';
                for(Object fieldVal : relatedValueMAP.keySet()) {
                    String field = String.valueOf(fieldVal);
                    if(field.toLowerCase() != 'id') {
                        query += field + ', ';
                    }
                }
                query += 'id FROM ' + relatedObjName + ' WHERE id = \'' + recordId + '\'';
                LIST<SObject> queryResult = new LIST<SObject>();	//list to store the records retrieved
                try {
                    queryResult = database.query(query);
                } catch(Exception e) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(e);
                }
                
                if(!queryResult.isEmpty()) {
                    
                    /* SObject Global describe*/ 
                    Schema.SObjectType objectType = Schema.getGlobalDescribe().get(relatedObjName);
                    
                    /* Converting String to SObject*/ 
                    SObject record = objectType.newSObject();
                    record = queryResult[0];
                    
                    MAP<String, SObjectField> fieldmap = objectType.getDescribe().fields.getMap();	//map of field and its schema
                    
                    for(Object fieldVal : relatedValueMAP.keySet()) {
                        String field = String.valueOf(fieldVal);
                        if(fieldmap.containsKey(field) && fieldmap.get(field).getDescribe().isUpdateable()){
                            if( relatedValueMAP.get(field)!=null && relatedValueMAP.get(field)!='') {
                                if(String.valueOf(fieldmap.get(field).getDescribe().getType()).toLowerCase() == 'datetime') {
                                    String val = String.valueOf(relatedValueMAP.get(field));
                                    val = val.replace('T', ' ');
                                    record.put(field, DateTime.valueOfGmt(val));
                                } else if(String.valueOf(fieldmap.get(field).getDescribe().getType()).toLowerCase() == 'date') {
                                    String val = String.valueOf(relatedValueMAP.get(field));
                                    val = val.split('T')[0];
                                    record.put(field, Date.valueOf(val));
                                } else if(String.valueOf(fieldmap.get(field).getDescribe().getType()).toLowerCase() == 'number' ||
                                          String.valueOf(fieldmap.get(field).getDescribe().getType()).toLowerCase() == 'currency' ||
                                          String.valueOf(fieldmap.get(field).getDescribe().getType()).toLowerCase() == 'percent' ||
                                          String.valueOf(fieldmap.get(field).getDescribe().getType()).toLowerCase() == 'double') {
                                              record.put(field, Decimal.valueOf((String)relatedValueMAP.get(field)));
                                          } else if(String.valueOf(fieldmap.get(field).getDescribe().getType()).toLowerCase() == 'boolean') {
                                              record.put(field, Boolean.valueOf((String)relatedValueMAP.get(field)));
                                          } else {
                                              record.put(field, (String)relatedValueMAP.get(field));
                                          }
                            }
                            else {
                                record.put(field,null);
                            }
                        }
                        
                    }
                    IFv2_DmlController.GenericDMLOperation(record, 'update');
                    
                }
            }
        }
    }
    
    /*Method to handle predefined Mapping based on multiple conditions before saving request*/
    public static Sobject getPredefinedMapping(sobject record, LIST<mapWrapper>relRecords,String previousRecord, String objectName,MAP<String,Schema.SobjectField>fieldMap) {
        sobject prevRecord = Schema.getGlobalDescribe().get(objectName).newSobject();
        System.debug('predefined record=>'+record);
        System.debug('predefined previousRecord=>'+previousRecord);
        if(previousRecord != null) {
            prevRecord = (IFv2_Request__c)JSON.deserialize(previousRecord, IFv2_Request__c.class);
        }
        
        /*Query for mapping conditions*/
        MAP<String, Schema.SObjectField> mappingFieldMap = Schema.getGlobalDescribe().get('IFv2_PredefinedWorkflowFields__mdt').getDescribe().fields.getMap();
        MAP<String, Schema.SobjectField> conditionFieldMap = Schema.getGlobalDescribe().get('IFv2_MappingCondition__mdt').getDescribe().fields.getMap();
        String query = 'SELECT '+String.join(new LIST<String>(mappingFieldMap.keySet()),',')+',(SELECT ' + String.join(new LIST<String>(conditionFieldMap.keySet()),',') + ' FROM MappingConditions__r WHERE Status__c = \'Active\') FROM IFv2_PredefinedWorkflowFields__mdt WHERE Status__c = \'Active\' AND Workflow__r.Name__c = \''+record.get('Workflow__c')+'\' AND isConditional__c = true';
        LIST<SObject> mappingList = new LIST<SObject>();	//list of mapping conditions
        try {
            mappingList = database.query(query);
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);  
        }
        /* Changes for handling currency conversion - Start*/
        String currencyQuery =  'SELECT CurrencyFrom__c,CurrencyTo__c,Rate__c,ValidFrom__c,ValidTill__c '+
            'FROM IFv2_ExchangeRate__c ';
        list<SObject> currencyConversionList = Database.query(currencyQuery);	//list of currency conversion records
        /* Changes for handling currency conversion - End*/
        /*Get field values for indirect field Mapping*/
        LIST<String> fieldList = new LIST<String>();
        for(SObject mapping:mappingList) {
            if(Boolean.valueOf(mapping.get('IsIndirectMapping__c'))) {
                if( mapping.get('Value__c') != null) {
                    fieldList.add(String.valueOf(mapping.get('Value__c')));
                }
            }
        }
        String recQuery = 'SELECT '; 
        for(String fieldName : fieldList) {
            recQuery += fieldName + ', ';
        }
        recQuery += 'Id FROM '+ objectName + ' WHERE Id = \''+String.valueOf(record.get('Id'))+'\'';
        
        LIST<SObject> recList = new LIST<SObject>();
        try {
            recList = Database.query(recQuery);
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e); 
        }
        
        /*Check for matching conditions and do mapping*/
        for(SObject mapping : mappingList) {
            
            Boolean conditionSatisfied = true;
            Boolean conditionChanged = false;
            
            String mapLogic = String.valueOf(mapping.get('MappingLogic__c'));
            if(mapLogic == 'ANY') {
                conditionSatisfied = false;
                if(mapping.getSObjects('MappingConditions__r')!=null) {
                    for(SObject condition : (LIST<Sobject>)(mapping.getSObjects('MappingConditions__r'))) {
                        String operator = String.valueOf(condition.get('Operator__c'));
                        String recValue = '';
                        String controllingField = String.valueOf(condition.get('ControllingField__c'));
                        /* Handle Extension object fields*/
                        if(controllingField.contains('.')) {
                            String relObj = controllingField.split('\\.')[0].replace('__r','__c');
                            String relField= controllingField.split('\\.')[1];
                            
                            for(mapWrapper wrap:relRecords) {
                                if(wrap.key == relObj) {
                                    MAP<String, String> valMap = wrap.value;
                                    if(valMap.containsKey(relField)) {
                                        recValue = valMap.get(relField);
                                    }
                                }
                            }
                        } else {
                            recValue = String.valueOf(record.get(controllingField));
                            if(recValue != String.valueOf(prevRecord.get(controllingField))){
                                conditionChanged = true;
                            }
                        }
                        /* Changes for Handling Currency conversion -Start*/
                        if((Boolean)condition.get('ConvertCurrency__c')){
                            String currencyField = (String)condition.get('CurrencyField__c');
                            String validDateField = (String)condition.get('CurrencyReferenceDateField__c');
                            if(fieldMap.containsKey(currencyField) && !currencyConversionList.isEmpty()){
                                Date validDate;
                                if(fieldMap.containsKey(validDateField) && record.get(validDateField) != null){
                                    validDate = (date)record.get(validDateField);
                                }
                                else{
                                    validDate = Date.valueOf((DateTime)record.get('CreatedDate')); 
                                }
                                recValue = String.valueOf(convertCurrency(currencyConversionList,Decimal.valueOf(recValue),  (String)record.get(currencyField), (String)condition.get('ConvertToCurrency__c'),validDate));
                            }
                            else{
                                System.debug('Invalid Field!');
                            }
                        }
                        /*Changes for Handling Currency conversion -End*/
                        
                        String condValue = String.valueOf(condition.get('Value__c'));
                        /* Check for different operators*/
                        switch on operator{
                            when 'Equals' {
                                if((recValue == condValue)) {
                                    conditionSatisfied = true;
                                    break;
                                }
                            }
                            when 'Not Equals' {
                                if((recValue != condValue)) {
                                    conditionSatisfied = true;
                                    break; 
                                }
                            }
                            when 'Less Than or Equals' {
                                if(!String.isBlank(recValue)) {
                                    if((Decimal.valueOf(recValue) <= Decimal.valueOf(condValue))) {
                                        conditionSatisfied = true;
                                        break;
                                    }
                                }
                            }
                            when 'Greater Than or Equals' {
                                if(!String.isBlank(recValue)) {
                                    if((Decimal.valueOf(recValue) >= Decimal.valueOf(condValue))) {
                                        conditionSatisfied = true;
                                        break;
                                    }
                                }
                            }
                            when 'Greater Than' {
                                if(!String.isBlank(recValue)) {
                                    if((Decimal.valueOf(recValue) > Decimal.valueOf(condValue))) {
                                        conditionSatisfied = true;
                                        break;
                                    }
                                }
                            }
                            when 'Less Than' {
                                if(!String.isBlank(recValue)) {
                                    if((Decimal.valueOf(recValue) < Decimal.valueOf(condValue))) {
                                        conditionSatisfied = true;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if(mapping.getSObjects('MappingConditions__r') != null) {
                    for(SObject condition : (LIST<Sobject>)(mapping.getSObjects('MappingConditions__r'))) {
                        String operator = String.valueOf(condition.get('Operator__c'));
                        String recValue = '';
                        String controllingField = String.valueOf(condition.get('ControllingField__c'));
                        if(controllingField.contains('.')) {
                            String relObj = controllingField.split('\\.')[0].replace('__r','__c');
                            String relField= controllingField.split('\\.')[1];
                            for(mapWrapper wrap:relRecords) {
                                if(wrap.key == relObj) {
                                    MAP<String, String> valMap = wrap.value;
                                    if(valMap.containsKey(relField)) {
                                        recValue = valMap.get(relField);
                                    }
                                }
                            }
                        } else {
                            recValue = String.valueOf(record.get(controllingField));
                            if(recValue != String.valueOf(prevRecord.get(controllingField))){
                                conditionChanged = true;
                            }
                        }
                        /* Changes for Handling Currency conversion -Start*/
                        if((Boolean)condition.get('ConvertCurrency__c')){
                            String currencyField = (String)condition.get('CurrencyField__c');
                            String validDateField = (String)condition.get('CurrencyReferenceDateField__c');
                            if(fieldMap.containsKey(currencyField) && !currencyConversionList.isEmpty()){
                                Date validDate;
                                if(fieldMap.containsKey(validDateField) && record.get(validDateField) != null){
                                    validDate = (Date)record.get(validDateField);
                                }
                                else{
                                    validDate = Date.valueOf((DateTime)record.get('CreatedDate')); 
                                }
                                recValue = String.valueOf(convertCurrency(currencyConversionList,Decimal.valueOf(recValue),  (String)record.get(currencyField), (String)condition.get('ConvertToCurrency__c'),validDate));
                            }
                            else{
                                System.debug('Invalid Field!');
                            }
                        }
                        /* Changes for Handling Currency conversion -End*/
                        
                        String condValue = String.valueOf(condition.get('Value__c'));
                        /* Check for different operators*/
                        switch on operator {
                            when 'Equals' {
                                if(!(recValue == condValue)) {
                                    conditionSatisfied = false;
                                    break;
                                }
                            }
                            when 'Not Equals' {
                                if(!(recValue != condValue)) {
                                    conditionSatisfied = false;
                                    break;
                                }
                            }
                            when 'Less Than or Equals' {
                                if(String.isEmpty(recValue)) {
                                    conditionSatisfied = false;
                                    break;
                                }
                                else if(!(Decimal.valueOf(recValue) <= Decimal.valueOf(condValue))) {
                                    conditionSatisfied = false;
                                    break;
                                }
                            }
                            when 'Greater Than or Equals' {
                                if(String.isEmpty(recValue)) {
                                    conditionSatisfied = false;
                                    break;
                                }
                                else if(!(Decimal.valueOf(recValue) >= Decimal.valueOf(condValue))) {
                                    conditionSatisfied = false;
                                    break;
                                }
                            }
                            when 'Greater Than' {
                                if(String.isEmpty(recValue)) {
                                    conditionSatisfied = false;
                                    break;
                                }
                                else if(!(Decimal.valueOf(recValue) > Decimal.valueOf(condValue))) {
                                    conditionSatisfied = false;
                                    break;
                                }
                            }
                            when 'Less Than' {
                                if(String.isEmpty(recValue)) {
                                    conditionSatisfied = false;
                                    break;
                                }
                                else if(!(Decimal.valueOf(recValue) < Decimal.valueOf(condValue))) {
                                    conditionSatisfied = false;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            
            if(conditionSatisfied && (((Boolean)mapping.get('AllowOverride__c') && conditionChanged) || !(Boolean)mapping.get('AllowOverride__c'))) {
                if(Boolean.valueOf(mapping.get('IsIndirectMapping__c'))) {
                    if(!recList.isEmpty()) {
                        String fieldName = String.valueOf(mapping.get('Value__c'));
                        if(!fieldName.contains('.')) {
                            record.put(String.valueOf(mapping.get('RequestFieldApi__c')),recList[0].get(fieldName));
                        } else {
                            record.put(String.valueOf(mapping.get('RequestFieldApi__c')),recList[0].getSobject(fieldName.split('\\.')[0]).get(fieldName.split('\\.')[1]));
                        }
                    }
                } else {
                    String fieldType = String.valueOf(fieldMap.get(String.valueOf(mapping.get('RequestFieldApi__c'))).getDescribe().getType()).toLowerCase();
                    if(fieldType=='number'||fieldType=='percent'||fieldType=='decimal'||fieldType=='double') {
                        record.put(String.valueOf(mapping.get('RequestFieldApi__c')),Decimal.valueOf(String.valueOf(mapping.get('Value__c'))));
                    }
                    else if(fieldType=='boolean'){
                        Boolean val = false;
                        if(String.valueOf(mapping.get('Value__c')).equalsIgnoreCase('true')){
                            val = true;
                        }
                        record.put(String.valueOf(mapping.get('RequestFieldApi__c')),val);
                    }else {
                        record.put(String.valueOf(mapping.get('RequestFieldApi__c')),mapping.get('Value__c'));
                    }
                }
            }
        }
        return record;
    }
    /* New RoleApproverMapping Method - Start*/
    /*Method to handle predefined Mapping based on multiple conditions before saving request*/
    public static Sobject getRoleApproverMapping(sobject record, LIST<mapWrapper> relRecords,String previousRecord, String objectName,Map<String,Schema.SobjectField> fieldMap) {
        sobject prevRecord = Schema.getGlobalDescribe().get(objectName).newSobject();
        System.debug('record=>'+record);
        System.debug('previousRecord=>'+previousRecord);
        if(previousRecord != null) {
            prevRecord = (IFv2_Request__c)JSON.deserialize(previousRecord, IFv2_Request__c.class);
        }
        /*Query for mapping conditions*/
        MAP<String, Schema.SObjectField> mappingFieldMap = Schema.getGlobalDescribe().get('IFv2_RoleApproverMapping__mdt').getDescribe().fields.getMap();
        MAP<String, Schema.SobjectField> conditionFieldMap = Schema.getGlobalDescribe().get('IFv2_MappingCondition__mdt').getDescribe().fields.getMap();
        String query = 'SELECT '+String.join(new LIST<String>(mappingFieldMap.keySet()),',')+',(SELECT ' + String.join(new LIST<String>(conditionFieldMap.keySet()),',') + ' FROM MappingConditions__r WHERE Status__c = \'Active\') FROM IFv2_RoleApproverMapping__mdt WHERE Status__c = \'Active\' AND Workflows__r.Name__c = \''+record.get('Workflow__c')+'\'';
        LIST<SObject> mappingList = new LIST<SObject>();
        
        try {
            mappingList = database.query(query);
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);  
        }
        System.debug('mappingList=>'+mappingList);
        //Query currency convert custom setting records*/
        /* Changes for Handling Currency Conversion -Start */
        String currencyQuery =  'SELECT CurrencyFrom__c,CurrencyTo__c,Rate__c,ValidFrom__c,ValidTill__c '+
            'FROM IFv2_ExchangeRate__c ';
        list<SObject> currencyConversionList = Database.query(currencyQuery);
        /* Changes for Handling Currency Conversion -End */
        /*Changes for handling Indirect Mapping in Role Approver Mapping - Start */
        SET<String> queryFieldSet= new SET<String>();	//set of fieldsets
        Boolean isIndirect= false;
        for(SObject mapping : mappingList) {
            if((Boolean)mapping.get('isIndirectMapping__c')){
                isIndirect = true;
                for(String value : mappingFieldMap.keySet()) {
                    if(value.contains('approver')) {
                        if((String)mapping.get(value)!=null && (String)mapping.get(value)!= ''){
                            queryFieldSet.add((String)mapping.get(value));
                        }
                    }
                }
            }
        }
        LIST<SObject> recList = new LIST<SObject>();
        if(!queryFieldSet.isEmpty()){
            queryFieldSet.add('Id');
            queryFieldSet.add('Workflow__c');
            String recId = (String)record.get('Id');
            String recQuery = 'SELECT '+String.join(new LIST<String>(queryFieldSet), ',')+' FROM '+ objectName + ' WHERE Id = :recId';
            
            try {
                recList = database.query(recQuery);
            } catch(Exception e) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(e);  
            }
            
        }
        /*Changes for handling Indirect Mapping in Role Approver Mapping - End */
        /*Check for matching conditions and do mapping*/
        for(SObject mapping : mappingList) {
            
            Boolean conditionSatisfied = false;
            Boolean conditionChanged = false;
            // String mapLogic = String.valueOf(mapping.get('MappingLogic__c'));
            if(mapping.getSObjects('MappingConditions__r') != null) {
                conditionSatisfied = true;
                for(SObject condition : (LIST<Sobject>)(mapping.getSObjects('MappingConditions__r'))) {
                    String operator = String.valueOf(condition.get('Operator__c'));
                    String recValue = '';
                    String controllingField = String.valueOf(condition.get('ControllingField__c'));
                    if(controllingField.contains('.')) {
                        String relObj = controllingField.split('\\.')[0];
                        String relField= controllingField.split('\\.')[1];
                        if(relRecords!= null && !relRecords.isEmpty()){
                            for(mapWrapper wrap:relRecords) {
                                relObj = controllingField.split('\\.')[0].replace('__r','__c');
                                if(wrap.key == relObj) {
                                    MAP<String, String> valMap = wrap.value;
                                    if(valMap.containsKey(relField)) {
                                        recValue = valMap.get(relField);
                                    }
                                }
                            }
                        }
                        else{
                            if(record.getSobject(relObj) != null && record.getSobject(relObj).get(relField) !=null ){
                                recValue = String.valueOf(record.getSobject(relObj).get(relField));
                            }
                        }
                    } else {
                        recValue = String.valueOf(record.get(controllingField));
                        if(recValue != String.valueOf(prevRecord.get(controllingField))){
                            conditionChanged = true;
                        }
                    }
                    /* Changes for Handling Currency conversion -Start*/
                    if((Boolean)condition.get('ConvertCurrency__c')){
                        String currencyField = (String)condition.get('CurrencyField__c');
                        String validDateField = (String)condition.get('CurrencyReferenceDateField__c');
                        if(fieldMap.containsKey(currencyField) && !currencyConversionList.isEmpty()){
                            Date validDate;
                            if(fieldMap.containsKey(validDateField) && record.get(validDateField) != null){
                                validDate = (Date)record.get(validDateField);
                            }
                            else{
                                validDate = Date.valueOf((DateTime)record.get('CreatedDate')); 
                            }
                            if(!String.isEmpty(recValue)){
                                recValue = String.valueOf(convertCurrency(currencyConversionList,Decimal.valueOf(recValue),  (String)record.get(currencyField), (String)condition.get('ConvertToCurrency__c'),validDate));
                            }
                        }
                        else{
                            System.debug('Invalid Field!');
                        }
                    }
                    /* Changes for Handling Currency conversion -End*/
                    String condValue = String.valueOf(condition.get('Value__c'));
                    /* Check for different operators*/
                    switch on operator {
                        when 'Equals' {
                            if(!(recValue == condValue)) {
                                conditionSatisfied = false;
                                break;
                            }
                        }
                        when 'Not Equals' {
                            if(!(recValue != condValue)) {
                                conditionSatisfied = false;
                                break;
                            }
                        }
                        when 'Less Than or Equals' {
                            if(String.isEmpty(recValue)) {
                                conditionSatisfied = false;
                                break;
                            }
                            else if(!(Decimal.valueOf(recValue) <= Decimal.valueOf(condValue))) {
                                conditionSatisfied = false;
                                break;
                            }
                        }
                        when 'Greater Than or Equals' {
                            if(String.isEmpty(recValue)) {
                                conditionSatisfied = false;
                                break;
                            }
                            else if(!(Decimal.valueOf(recValue) >= Decimal.valueOf(condValue))) {
                                conditionSatisfied = false;
                                break;
                            }
                        }
                        when 'Greater Than' {
                            if(String.isEmpty(recValue)) {
                                conditionSatisfied = false;
                                break;
                            }
                            else if(!(Decimal.valueOf(recValue) > Decimal.valueOf(condValue))) {
                                conditionSatisfied = false;
                                break;
                            }
                        }
                        when 'Less Than' {
                            if(String.isEmpty(recValue)) {
                                conditionSatisfied = false;
                                break;
                            }
                            else if(!(Decimal.valueOf(recValue) < Decimal.valueOf(condValue))) {
                                conditionSatisfied = false;
                                break;
                            }
                        }
                    }
                }
            }
            system.debug('record->'+record);
            if(conditionSatisfied) {
                /* Iterate over all fields and set all roles and approvers*/
                for(String value : mappingFieldMap.keySet()) {
                    system.debug('value-> '+value);
                    if((value.contains('role') || value.contains('approver')) &&(((Boolean)mapping.get('AllowOverride__c') && conditionChanged) || !(Boolean)mapping.get('AllowOverride__c'))) {
                        /*Changes for handling Indirect Mapping in Role Approver Mapping - Start */
                        if(mapping.get(value) != 'Change Me') {
                            if(mapping.get(value)!=null){
                                if(!(Boolean)mapping.get('isIndirectMapping__c') || value.contains('role')){
                                    record.put(value,mapping.get(value));
                                }
                                else if(!recList.isEmpty()){
                                    String fieldName = String.valueOf(mapping.get(value));
                                    if(!fieldName.contains('.')) {
                                        record.put(value,recList[0].get(fieldName));
                                    } else {
                                        record.put(value,recList[0].getSobject(fieldName.split('\\.')[0]).get(fieldName.split('\\.')[1]));
                                    } 
                                }
                            }
                            else{
                                record.put(value,null);
                            }
                        } else if(conditionChanged){
                            record.put(value,null);
                        }
                    }
                }
                /*Changes for handling Indirect Mapping in Role Approver Mapping - End */
            }
        }
        return record;
    }
    /* New RoleApproverMapping Method - End*/
    /* This is use to do mapping for Direct and InDirect Workflows */
    @AuraEnabled
    public static LIST<IFv2_PurchasingApproval__mdt> getPurchasingApproval(String Region, String SubjectType, String workflow) {
        if(Region == null) {
            Region = '';
        }
        if(SubjectType == null) {
            SubjectType = '';
        }
        /*Checking For Indirect workflow If subject type argeements MetaData is Empty*/ 
        boolean sizeisNull = true;
        try {
            if(SubjectType == Label.CLIFv20061 && workflow == Label.CLIFv20005 ) {
                Integer size = [SELECT id FROM IFv2_PurchasingApproval__mdt 
                                WHERE Workflow__r.Name__c = :Label.CLIFv20005
                                AND SubjectType__c = :Label.CLIFv20061].size();
                if(size > 0)
                    sizeisNull = false;
                /*Checking For Indirect workflow If subject type purchasing orders MetaData is Empty*/   
            } else if(SubjectType == Label.CLIFv20062 && workflow == Label.CLIFv20005 ) {
                Integer size = [SELECT id FROM IFv2_PurchasingApproval__mdt 
                                WHERE Workflow__r.Name__c = :Label.CLIFv20005
                                AND SubjectType__c = :Label.CLIFv20062].size();
                if(size > 0)
                    sizeisNull = false;
            }
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
        }
        
        /*Checking For Indirect workflow If subject type is argeements or purchasing orders 
then take price decision subject type MetaData Values*/
        LIST<String> subjectTypeNames = new LIST<String>{Label.CLIFv20061,Label.CLIFv20062};
            if( workflow == Label.CLIFv20005 && subjectTypeNames.contains(SubjectType) && sizeisNull ) {
                SubjectType = Label.CLIFv20060;
            }
        
        LIST<IFv2_PurchasingApproval__mdt> metadata = new LIST<IFv2_PurchasingApproval__mdt>();		//list of purchasing approval mapping metadata records
        try {
            /* Checking if Region starts with Europe or Global */
            if(((Region.startsWith('Europe')&& workflow == Label.CLIFv20005) || Region == 'Global') && !SubjectType.toLowerCase().contains(Label.CLIFv20023.toLowerCase())) {
                
                metadata = [SELECT Workflow__c, Region__c, SubjectType__c, Limit__c, User__c, ApproverRole__c,
                            ApproverApiName__c, RoleApiName__c, Group__c
                            FROM IFv2_PurchasingApproval__mdt 
                            WHERE Workflow__r.Name__c = :workflow
                            AND SubjectType__c = :SubjectType
                            AND Region__c = :Region
                            ORDER BY Limit__c ASC];
                
                if(metadata.isEmpty()) {
                    metadata = [SELECT Workflow__c, Region__c, SubjectType__c, Limit__c, User__c, ApproverRole__c,
                                ApproverApiName__c, RoleApiName__c, Group__c
                                FROM IFv2_PurchasingApproval__mdt 
                                WHERE Workflow__r.Name__c = :workflow
                                AND SubjectType__c = :SubjectType
                                AND Region__c = 'Europe - Germany'
                                ORDER BY Limit__c ASC];
                }
            } 
            else {
                /*Mapping data for Rest region or Rest group records */
                metadata = [SELECT Workflow__c, Region__c, SubjectType__c, Limit__c, User__c, ApproverRole__c,
                            ApproverApiName__c, RoleApiName__c, Group__c
                            FROM IFv2_PurchasingApproval__mdt 
                            WHERE Workflow__r.Name__c = :workflow
                            AND SubjectType__c = :SubjectType
                            AND Group__c = 'Rest'
                            ORDER BY Limit__c ASC];
            }
        } catch(QueryException qe) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(qe);
        }
        return metadata;
    }
    
    /* get dependent picklist values*/
    @AuraEnabled
    public static LIST<String> getDependentpickListVal(String value, String depField, String controllingfield) {
        
        String objectType = 'IFv2_Request__c';
        
        MAP<String, LIST<String>> depPickListMap = IFv2_TStringUtils.GetDependentOptions(objectType, controllingfield, depField);	//map for dependent picklist
        
        LIST<String> pickVals = new LIST<String>();
        if(depPickListMap.containsKey(value)) {
            pickVals.addAll(depPickListMap.get(value));
        }
        return pickVals;
    }
    /*Method to convert currency for mapping*/
    public static Decimal convertCurrency( list<SObject> convertList, Decimal amount, String convertFrom, String convertTo, Date validDate){
        if(convertFrom == convertTo){
            return amount;
        }
        for(SObject convert:convertList){
            if(convert.get('CurrencyFrom__c') == convertFrom && convert.get('CurrencyTo__c') == convertTo &&
               (Date)convert.get('ValidFrom__c') <= validDate &&  (Date)convert.get('ValidTill__c') >= validDate ){
                   if(convert.get('Rate__c') != null){
                       
                       return amount * (Decimal)convert.get('Rate__c');
                   }
               }            
        }
        AuraHandledException exc = new AuraHandledException(Label.CLIFv20018);
        throw exc;
    }
    
    /*Generic method to check whether the logged in user is an Approver of the current record */
    public static Boolean checkUserIsApprover(String requestId) {
        Boolean isApprover = false;
        LIST<ProcessInstanceWorkitem> approvalItem = IFv2_UtilsController.getRecordAcccess(requestId);	//list of processinstance records
        SET<Id>approverList = new SET<Id>();
        for(ProcessInstanceWorkitem item : approvalItem) {
            approverList.add(item.ActorId);
        }
        
        if(!approverList.isEmpty()) {
            LIST<User> userList = [SELECT Id, DelegatedApproverId FROM User WHERE Id IN :approverList];
            for(User usr : userList) {
                if(usr.DelegatedApproverId != null) {
                    approverList.add(usr.DelegatedApproverId);
                }
            }
        }
        if(approverList.contains(Userinfo.getUserId())) {
            isApprover = true;
        }
        
        return isApprover;
    }
    
}