/*******************************************************************************************************
* 
* @ Name    			:   IFv2_PrintableViewController
* @ Purpose 			:   Printable view controller
* @ Author  			:   Naga Sai
* @ Test class Name  	: 	IFv2_PrintableViewControllerTest, IFV2_ArchivalBatchTest,IFv2_ScanArchivalBatchTest
*
*   Date        |  Developer Name                   |  Version      |  Changes
* ======================================================================================================
*   04-11-2018  |  nagasai.chalamalasetti@absyz.com |  1.0          |  Initial Version
*   20-03-2019  |  nagasai.chalamalasetti@absyz.com |   2.0         |   Added logic to handle fields which are lookup to a field 
and in return that field is again a look Up to another field.
*   01-04-2019  |  nagasai.chalamalasetti@absyz.com |   3.0         |  Added logic to generate xml along with pdf 
*   17-07-2019  |  nagasai.chalamalasetti@absyz.com |   4.0         |   Moved Html tags to custom metadata.
*   26-07-2019  |  nagasai.chalamalasetti@absyz.com |   4.1         |   Added HTML output tags and logic to handle materials of MGP.
*******************************************************************************************************/

public class IFv2_PrintableViewController {
    
    public IFv2_Request__c Request{get;set;}    //To store queried Request record
    public MAP<string,LIST<IFv2_FieldWrapperClass>>SectionFieldMap{get;set;}    //Holds section name and its respective fields
    public MAP<IFv2_FieldWrapperClass,string> FieldAPIAndValueMap{get;set;}    //Holds Field wrapper and its respective data
    public MAP<string,LIST<IFv2_FieldWrapperClass>> RelatedlistNameAndFieldWrapperListmap = new MAP<string,LIST<IFv2_FieldWrapperClass>>();
    public MAP<string,string> LookupRecordIdnNameMap = new MAP<string,string>();
    public static MAP<String, SObject> labels = new MAP<string,SObject>();
    public static LIST<string> Textfieldsshowntobelookup = new LIST<string>();
    public static LIST<string> TextfieldsshowntobelookupforCurrentWorkflow = new LIST<string>();
    public static LIST<sObject> OldApprovalRecords = new LIST<sObject>();
    public LIST<Object> getMetadataList{get;set;}
    public LIST<IFv2_FieldWrapperClass> getFields{get;set;}    //holds  fields of a section
    public LIST<IFv2_FieldWrapperClass> FieldWrapperList{get;set;}    //holds allthe fields of currentpage layout
    public LIST<sobject> RelatedRecords = new LIST<sobject>();
    public static decimal datetimeoffset{get;set;}
    public String logoURL{get;set;}
    /**Start of declaration of variables used to generate related list in XML view**/
    public static MAP<String,String> relatedListAPIValueMap;//holds value against API name of related list record
    public static MAP<String,String> approvalListAPIValueMap;//holds value against API name of Approval list record
    public static MAP<String,String> oldApprovalListAPIValueMap;//holds value against API name of Old Approval list record
    public transient XmlStreamWriter relatedListXMLStreamWriter = new XmlStreamWriter(); 
    public transient XmlStreamWriter approvalListXMLStreamWriter = new XmlStreamWriter() ;
    public transient XmlStreamWriter oldApprovalListXMLStreamWriter = new XmlStreamWriter();
    public static transient XmlStreamWriter chatterListXMLStreamWriter = new XmlStreamWriter();
    public static transient XmlStreamWriter attachmentsListXMLStreamWriter = new XmlStreamWriter();
    public static boolean constructorInitialized=FALSE;
    public  static Id chatterparentId;
    public  Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    public static LIST<IFv2_PrintableViewLayout__mdt> printableViewLayoutList = new LIST<IFv2_PrintableViewLayout__mdt>();
    public static MAP<String,IFv2_PrintableViewLayout__mdt> sectionPrintableView = new MAP<String,IFv2_PrintableViewLayout__mdt>();
    /** End of declaration of variables used to generate related list in XML view**/
    
    /* Defining two constructors one with parameters that uses standad controller */
    /* and other with non parameters that uses  parametrs in URL of currrent pagee(this is used for XML generation) */
    public IFv2_PrintableViewController() {
        //forming logo url
        LIST<document> DocumentLIST = [select id from document where name =:label.CLIFv20247];
        if(DocumentLIST.size()>0)
            logourl =  URL.getSalesforceBaseUrl().toExternalForm()+'/servlet/servlet.ImageServer?id='+DocumentLIST[0].id+'&oid='+ UserInfo.getOrganizationId();
        else
            logourl ='';
        // Initialization of variables
        SectionFieldMap = new MAP<string,LIST<IFv2_FieldWrapperClass>>();
        FieldAPIAndValueMap = new MAP<IFv2_FieldWrapperClass,string>();
        FieldWrapperList = new LIST<IFv2_FieldWrapperClass>();
        relatedListAPIValueMap = new MAP<String,String>();
        approvalListAPIValueMap = new MAP<String,String>();
        oldApprovalListAPIValueMap = new MAP<String,String>();
        Request = new IFv2_Request__c();
        Id Requestid = ApexPages.currentPage().getParameters().get('id');
        chatterparentId = Requestid;
        formSectionFieldMap(Requestid);
    }
    
    public IFv2_PrintableViewController(apexpages.StandardController RequestStandardController) {
        //forming logo url
        LIST<document> DocumentLIST = [select id from document where name =:label.CLIFv20247];
        if(DocumentLIST.size()>0)
            logourl =  URL.getSalesforceBaseUrl().toExternalForm()+'/servlet/servlet.ImageServer?id='+DocumentLIST[0].id+'&oid='+ UserInfo.getOrganizationId();
        else
            logourl =''; 
        // Initialization of variables
        
        SectionFieldMap=new MAP<string,LIST<IFv2_FieldWrapperClass>>();
        FieldAPIAndValueMap=new MAP<IFv2_FieldWrapperClass,string>();
        FieldWrapperList=new LIST<IFv2_FieldWrapperClass>();
        relatedListAPIValueMap = new MAP<String,String>();
        approvalListAPIValueMap = new MAP<String,String>();
        oldApprovalListAPIValueMap = new MAP<String,String>();
        IFv2_Request__c RequestRecord = (IFv2_Request__c)RequestStandardController.getRecord();
        Id Requestid = RequestRecord.id;
        chatterparentId = Requestid;
        formSectionFieldMap(Requestid);
    }
    /* forms the map of section name and its respective fields, also Field wrapper and its respective data */
    public  void formSectionFieldMap(id Requestid) {
        try{
            /**HotFix start-Email from Anand**/
            TimeZone tz = UserInfo.getTimeZone();
            //Milliseconds to Day
            System.debug('tz>>'+tz);
            System.debug('tz without>>'+tz.getOffset(DateTime.now()));
            datetimeoffset= tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
            System.debug('tz>>offset>'+datetimeoffset);
            /**HotFix End-Email from Anand**/
			System.debug('datetimeoffset>'+datetimeoffset);
            boolean ChinatrainingApp = False;
            // Initialization of variables
            // Invoking getRecord method to query and get record data , by passing recordid and object API name.     
            Request=(IFv2_Request__c)getRecord(string.valueof(Requestid.getsobjecttype()),Requestid);
            system.debug('Request ='+Request);	
            if(Request.Workflow__c=='China Training Application')
            {
                ChinatrainingApp = True;
            }
            User applicant=[select id,TimeZoneSidKey from User where id=:Request.CreatedById limit 1];
            // getting text fields which are  shown as lookup in Lightning component
            Textfieldsshowntobelookup = label.CLIFv20068.split(',');
            // Invoking  method by passing section name and workflow name ,to get list of sections for this resepctive workflow   
            getMetadataList = getMetadataList('IFv2_Section__mdt', Request.Workflow__c);
            LIST<string> Sectionids = new LIST<string>();
            // Iterate over metadata and collect section ids.
            // This is done, so if wepass section ids to fieldetformcontroller it return field labels which are changed in lightning Component.
            for(Object metadata : getMetadataList) {
                IFv2_Section__mdt Record = (IFv2_Section__mdt ) metadata;
                Sectionids.add((string)Record.get('id'));
            }
            // below variable holds the list of labels that need to be displayed with label other than their original label
            labels = IFv2_FieldSetFormController.getFieldLabels(sectionIDs);
            Schema.SObjectType objectType = null;
            objectType = Request.id.getSobjectType();
            // Iterating over sectionlist and forming sectionname and its respective fieldlist map
            for(Object metadata : getMetadataList) {
                IFv2_Section__mdt Record = (IFv2_Section__mdt ) metadata;
                // getting fields for respective sections and forming map
                getFields=getFields(Request.id,'IFv2_Request__c',(string)Record.get('Value__c'),Request,objectType);/* Comment this line*/
                SectionFieldMap.put((string)Record.get('Name__c'), getFields);
                FieldWrapperList.addall(getFields);
            }
            /***** Text Fields that are shown as look up in page******/
            MAP<string,string> useridnamemap = new MAP<string,string>();
            MAP<string,string> requestidnamemap = new MAP<string,string>();
            if(TextfieldsshowntobelookupforCurrentWorkflow.size()>0) {
                //Querying for respective usernames with ids, and forming id,name map
                SET<string> Userids = new SET<string>();
                SET<string> MGPrequestIds = new SET<string>();
                for(string Fieldapiname:TextfieldsshowntobelookupforCurrentWorkflow) {
                    Id id = (Id)Request.get(Fieldapiname);
                    if(id!=Null){
                        if(String.valueof(id.getSobjectType())=='user')
                            Userids.add((string)Request.get(Fieldapiname));
                        if(String.valueof(id.getSobjectType())=='IFv2_Request__c')
                            MGPrequestIds.add((string)Request.get(Fieldapiname));
                    }
                }
                LIST<user> userlist = [select id, name from user where id in :Userids];
                LIST<IFv2_Request__c> requestList = [select id, name from IFv2_Request__c where id in :MGPrequestIds];
                for(user u : userlist)
                    useridnamemap.put(u.id, u.name);
                for(IFv2_Request__c request : requestList)
                    requestidnamemap.put(request.id, request.name);
            }
            /********Text Fields that are shown as look up in page *************/
            // Iterating over fieldlist and forming map of fieldwrapper and  data that field contains
            for(IFv2_FieldWrapperClass field : FieldWrapperList) {
                // segregating custom look up fields,standard look up fields and normal fields and forming map
                if(string.valueof(field.type) == 'REFERENCE' && field.APIName != 'lastmodifiedbyId' && field.APIName != 'CreatedbyId' && !field.APIName.contains('.')) {
                    
                    if(string.isNotBlank(string.valueof(Request.get(field.APIName))) && string.valueof(Request.get(field.APIName))!=Label.CLIFv20022) {
                        string nameval =field.APIName.replace('__c','__r');//Replacing suffix with relationship suffix
                        FieldAPIAndValueMap.put(field,string.valueof(Request.getsobject(nameval).get('name')));
                    } 
                    else {
                        FieldAPIAndValueMap.put(field,'');
                    }
                } else if(field.APIName == 'lastmodifiedbyId') {
                    string nameval ='lastmodifiedby';
                    Datetime dt = (Datetime)Request.get('LastModifiedDate');
                    FieldAPIAndValueMap.put(field,string.valueof(Request.getsobject(nameval).get('Name')) +' '+dt.format('dd.MM.yyyy h:mm a'));
                    
                }
                else if(field.APIName=='CreatedbyId') {
                    string nameval ='Createdby';
                    Datetime dt = (Datetime)Request.get('CreatedDate');
                    FieldAPIAndValueMap.put(field,string.valueof(Request.getsobject(nameval).get('Name'))+' '+dt.format('dd.MM.yyyy h:mm a'));
                }
                // fields that are look up and in turn look up to another field will go into this for evaluation
                else if(field.APIName.contains('.') && !field.APIName.contains('lastmodifiedby') && !field.APIName.contains('createdby')) {
                    //splitting the API name into individual fields
                    LIST<String> namelist = field.APIName.split('\\.');
                    //getting the type of object used for relationship using id
                    if(Request.getsobject(namelist[0])!=Null){
                        id referenceid = Request.getsobject(namelist[0]).id;
                        String type=string.valueof(referenceid.getsobjecttype());
                        //using schema classes getting field type of the first look up field of that respective object
                        //if the field type of the first look up is again a look up then we will be replacing that field API name with '__r.name'
                        Schema.SObjectType RequestSchema = schemaMap.get(type);
                        Map<String, Schema.SObjectField> fieldMap = RequestSchema.getDescribe().fields.getMap();
                        Schema.SObjectField fieldsc = fieldMap.get(namelist[1]);
                        Schema.DisplayType FldType = fieldsc.getDescribe().getType();system.debug('string.valueof(FldType) '+string.valueof(FldType));
                        if(string.valueof(FldType)!='REFERENCE'){
                            if(Request.getsobject(namelist[0]) != NULL && string.valueof(FldType)!='Date'&&string.valueof(FldType)!='DATETIME' & string.valueof(FldType)!='Boolean')
                                FieldAPIAndValueMap.put(field,string.valueof(Request.getsobject(namelist[0]).get(namelist[1])));
                            else if(string.valueof(FldType)=='Date' ){
                                Datetime dt = (Datetime)Request.getsobject(namelist[0]).get(namelist[1]);
                                if(dt!=Null)
                                    FieldAPIAndValueMap.put(field,string.valueof(dt.format('dd.MM.yyyy')));
                                else
                                    FieldAPIAndValueMap.put(field,'');
                            }
                             //Timezone problem in Incident code debug addition
                            else if(string.valueof(FldType)=='DATETIME' ){
                                if(ChinatrainingApp == True && (field.APIName=='RequestExtension1__r.PlannedStartDateTime__c' ||field.APIName=='RequestExtension1__r.PlannedEndDateTime__c'))
                                {
                                    Datetime dt = (Datetime)Request.getsobject(namelist[0]).get(namelist[1]);system.debug('dt = '+dt);
                                    if(dt!=Null)
                                    {   Integer currentoffset = UserInfo.getTimezone().getOffset(DateTime.now()); 
                                        TimeZone tz1 =Timezone.getTimeZone(applicant.TimeZoneSidKey);
                                        datetimeoffset= (tz1.getOffset(DateTime.now())-currentoffset )/ (1000 * 3600 * 24.0);
                                        string value =  string.valueof((dt+datetimeoffset).format('dd.MM.yyyy hh:mm a'));
                                        FieldAPIAndValueMap.put(field,value); 
                                    }
                                    else
                                        FieldAPIAndValueMap.put(field,'');
                                }
                            }
                            //Time zone problem in planned date Incident report ends here
                            else if(string.valueof(FldType)=='Boolean'){
                                if(Boolean.valueOf(Request.getsobject(namelist[0]).get(namelist[1]))==True)
                                    FieldAPIAndValueMap.put(field, 'Checked');
                                else 
                                    FieldAPIAndValueMap.put(field, 'Blank');
                            }
                        }
                        else{
                            string referencefieldname = namelist[1].replace('__c','__r');
                            if(Request.getsobject(namelist[0]).getsobject(referencefieldname)!=Null)
                                FieldAPIAndValueMap.put(field,string.valueof(Request.getsobject(namelist[0]).getsobject(referencefieldname).get('name')));
                        }
                    }
                }
                // Fields like Inform when approved, which are text but shown as lookupp will go this for evaluation
                else if(TextfieldsshowntobelookupforCurrentWorkflow.contains(field.APIName)) {
                    string userid=string.valueof(Request.get(field.APIName));
                    Id id= (Id)userid;
                    if(id!=Null){
                        if(String.valueof(id.getSobjectType())=='user')
                            FieldAPIAndValueMap.put(field,useridnamemap.get(userid));
                        if(String.valueof(id.getSobjectType())=='IFv2_Request__c')
                            FieldAPIAndValueMap.put(field,requestidnamemap.get(userid));
                    }
                } else if(field.type=='Currency' && string.valueof(Request.get(field.APINAME))!=Null) {
                    FieldAPIAndValueMap.put(field,string.valueof(Request.get(field.APINAME))+UserInfo.getDefaultCurrency());
                } else if( field.APINAME=='SubjectType__c'  && string.valueof(Request.get(field.APINAME))=='Debit Notes' && string.valueof(Request.get('Workflow__c'))==label.CLIFv20005) {
                    FieldAPIAndValueMap.put(field,'Credit Notes');
                } 
                else if(field.Type=='Date' ){
                    Datetime dt = (Datetime)Request.get(field.APINAME);
                    if(dt!=Null)
                        FieldAPIAndValueMap.put(field, string.valueof(dt.format('dd.MM.yyyy')));
                    else {
                        FieldAPIAndValueMap.put(field,'');
                    }
                }
                else if(field.Type=='Boolean'){
                    if(Boolean.valueOf(Request.get(field.APIName))==True)
                        FieldAPIAndValueMap.put(field, 'Checked');
                    else 
                        FieldAPIAndValueMap.put(field, 'Blank');
                }
                else {
                    FieldAPIAndValueMap.put(field,string.valueof(Request.get(field.APIName)));
                }
            }
            /******* Related list logic********/
            LIST<IFv2_GenericRelatedListController.FieldSetForm> relatedRecordswrapper = IFv2_GenericRelatedListController.getForm(Requestid,'Account');
            LIST<sobject> LookUprecords = new LIST<sobject>();
            
            // Iterating over related records wrapper and doing 
            // 1. Forming a map of related list name and lts list of fields
            // 2. Adding all related records to a list
            // 3. Adding all reference records(lookups) of related records to a list
            
            for(IFv2_GenericRelatedListController.FieldSetForm Fieldsetform : relatedRecordswrapper) {
                System.debug('i m here Fieldsetform>'+Fieldsetform);
                LIST<IFv2_FieldWrapperClass> fields =Fieldsetform.fields;
                if(Fieldsetform.Record.size()>0) {
                    if((string)Fieldsetform.Record[0].get('IFv2_ContentType__c') != 'Approval History') {
                        System.debug('i m here > inside if Fieldsetform.Record>'+Fieldsetform.Record);
                        RelatedlistNameAndFieldWrapperListmap.put((string)Fieldsetform.Record[0].get('IFv2_ContentType__c'), fields);
                        RelatedRecords.addall(Fieldsetform.Record);
                        LookUprecords.addall(Fieldsetform.userName);
                    } else {
                        System.debug('i m here > inside else');
                        OldApprovalRecords.addall(Fieldsetform.Record);
                        LookUprecords.addall(Fieldsetform.userName);
                        
                    }
                }
            }
            
            // Iterating over lookup records and forming map of id,name
            for(sobject lookuprecord:LookUprecords) {
                LookupRecordIdnNameMap.put((string)lookuprecord.get('id'),(string)lookuprecord.get('name'));
            }
        } catch(Exception e) {
            system.debug('error'+e.getmessage());
            system.debug('errorline'+e.getLineNumber());
        }
    }
    
    
    // Returns record details
    public static IFv2_Request__c getRecord(String objectName, String recordId) {
        sobject record = schema.getGlobalDescribe().get(objectName).newSobject();
        MAP<String,schema.FieldSet> fieldSetMap = schema.getGlobalDescribe().get(objectName).getDescribe().fieldSets.getMap();
        SET<String> fields = new SET<String>();
        
        for(String fieldSetName : fieldSetMap.keySet()) {
            for(schema.FieldSetMember fieldSetMember: fieldSetMap.get(fieldSetName).getFields()) {
                //segregating custom look up fields,standard look up fields and normal fields and forming map
                
                if(string.valueof(fieldSetMember.type) == 'REFERENCE' && fieldSetMember.getFieldPath() != 'lastmodifiedbyId' && fieldSetMember.getFieldPath() != 'CreatedbyId') {
                    fields.add(fieldSetMember.getFieldPath());
                    fields.add(fieldSetMember.getFieldPath().replace('__c','__r.Name'));
                } else if(fieldSetMember.getFieldPath()=='lastmodifiedbyId' || fieldSetMember.getFieldPath()=='CreatedbyId') {
                    fields.add(fieldSetMember.getFieldPath());
                    fields.add(fieldSetMember.getFieldPath().replace('id','.Name'));
                } else {
                    fields.add(fieldSetMember.getFieldPath());
                }
            }
        }
        
        // Forming a dynamic Query with the fields obtained
        if(fields.size()>0) {
            String query = 'select ';
            if(!fields.contains('CreatedDate'))
                query += 'createddate,';
            for(String field : fields) {
                if(field.toLowerCase() != 'id' && field.toLowerCase() != 'workflow__c') {
                    query += field + ', ';
                }
            }
            query += 'id, Workflow__c, OldRequestName__c, lastmodifiedby.name,ownerId from ' + objectName + ' where id = \'' + recordId + '\'';
            LIST<Sobject> queryResult = Database.query(query);
            if(queryResult.size()>0) {
                record = queryResult[0];
            }
        }
        
        IFv2_Request__c Request = (IFv2_Request__c) record;
        return Request;
    }
    
    // Returns section metadata list
    public static LIST<Object> getMetadataList(String metaDataName, String workFlowName) {
        String query = 'select Name__c, ReadOnly__c, SectionNumber__c, Type__c, Workflows__c, Value__c '+ 
            'from ' + metaDataName +
            ' where Workflows__r.Name__c = \''+ workFlowName + '\''+
            ' and Type__c = \'Request details\' '+
            ' order by SectionNumber__c asc';
        return database.query(query);
    }
    
    //Returns field wrapper list for a specific fieldset 
    public static LIST<IFv2_FieldWrapperClass> getFields(Id recordId, String objectName, String fieldSetName, SObject record, Schema.SObjectType objectType) {
        
        
        // Logic to get a fieldwrappers of a specific fieldset.
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        MAP<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap();
        MAP<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        Schema.FieldSet fieldSet = fieldSetMap.get(fieldSetName);
        LIST<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
        LIST<IFv2_FieldWrapperClass> fields = new LIST<IFv2_FieldWrapperClass>();
        
        for (Schema.FieldSetMember fsm : fieldSetMembers) {
            
            // This instaniation will return fieldwrapper of a particular fieldsetmember(field)
            IFv2_FieldWrapperClass fieldwrapper = new IFv2_FieldWrapperClass(fsm,objectName,record,fieldMap);
            
            // checking whether the field is present in the list of fields that is to be considerd for label change other than its original label
            if(labels.containsKey(fieldwrapper.APIName)) {
                if(labels.get(fieldwrapper.APIName).get('FieldLabel__c')!=null) {
                    fieldwrapper.Label = String.valueOf(labels.get(fieldwrapper.APIName).get('FieldLabel__c'));
                }
            }
            fields.add(fieldwrapper);
            
            // checking whether the field is present in the list of fields that is to be considerd for text field to be shown as lookup logic
            if(Textfieldsshowntobelookup.contains(fieldwrapper.APIName)) {
                TextfieldsshowntobelookupforCurrentWorkflow.add(fieldwrapper.APIName);
            } 
        }
        return fields;
    }
    
    //Forming dynamically html to be rendered
    public String getDynamicallyHTML() {
        try{
            //Query for HTMl Tags from metadata
            printableViewLayoutList =[select DeveloperName,HorizonatalLine__c,Division__c,Table__c,TableCellLabel__c,TableCellValue__c,TableRow__c from IFv2_PrintableViewLayout__mdt];
            for(IFv2_PrintableViewLayout__mdt printableLayout : printableViewLayoutList){
                sectionPrintableView.put(printableLayout.DeveloperName,printableLayout);
            }
            // Initializing a variable to hold entire html
            String table = '';
            
            //iterating over sections and displaying section names
            for(String s : SectionFieldMap.keySet()) {
                // adding sectionname
                table += sectionPrintableView.get('RecordDetailSection').Division__c + '<output>' + s + '</output>' + sectionPrintableView.get('EndTags').Division__c;
                
                // adding table attribute under every section
                table += sectionPrintableView.get('RecordDetailSection').Table__c;
                
                // getting respective fieldlist for sections
                LIST<IFv2_FieldWrapperClass> fieldwrapperlist = SectionFieldMap.get(s);
                
                // initiating a variable that acts as  a counter and used to display two columns
                Integer i = 0;
                String tr = '';
                
                // Iterating over field set of respective request ,creating a table row for two fields,table for a section.
                for(IFv2_FieldWrapperClass fieldwrapper : fieldwrapperlist) {
                    if(fieldwrapperlist.size() > 1) {
                        tr += sectionPrintableView.get('RecordDetailSection').TableCellLabel__c + '<output>' + fieldwrapper.label +'</output>' + sectionPrintableView.get('EndTags').TableCellLabel__c;
                        tr += sectionPrintableView.get('RecordDetailSection').TableCellValue__c + (FieldAPIAndValueMap.get(fieldwrapper) == null ? ' ' : '<output>' + FieldAPIAndValueMap.get(fieldwrapper) + '</output>') + sectionPrintableView.get('EndTags').TableCellValue__c;
                        i++;
                        
                        // checking for two columns and making table row empty ,so that next fields will come in next row
                        // last element if it is single it comes into thsi condition
                        if((math.mod(i,2) == 0) || (fieldwrapperlist.size() == i)) {
                            table += sectionPrintableView.get('RecordDetailSection').TableRow__c + tr + sectionPrintableView.get('EndTags').TableRow__c ;
                            tr = '';
                        }
                    } else {
                        tr += sectionPrintableView.get('RecordDetailSection').TableCellLabel__c  + '<output>' + fieldwrapper.label +'</output>' + sectionPrintableView.get('EndTags').TableCellLabel__c;
                        tr += sectionPrintableView.get('RecordDetailSection').TableCellValue__c + (FieldAPIAndValueMap.get(fieldwrapper) == Null? '' : '<output>'+ FieldAPIAndValueMap.get(fieldwrapper) + '</output>') + sectionPrintableView.get('EndTags').TableCellValue__c;
                        table += sectionPrintableView.get('RecordDetailSection').TableRow__c  + tr + sectionPrintableView.get('EndTags').TableRow__c ;
                        tr = '';
                    }
                }
                table += sectionPrintableView.get('RecordDetailSection').Table__c;
                
                // line after every section
                table += sectionPrintableView.get('RecordDetailSection').HorizonatalLine__c;
            }
            return table;
        }
        Catch(Exception e){
            system.debug('Error message'+e.getmessage());
            system.debug('Error line'+e.getLineNumber());
            system.debug('Error cause');
            return '';
        }
    }
    
    // Forming html for related list
    public String getDynamicallyHTMLforRelatedList() {
        // Initializing a variable to hold entire html
        try{
            String table = getDynamicallyHTML(); 
            relatedListXMLStreamWriter = new XmlStreamWriter();
            chatterListXMLStreamWriter = new XmlStreamWriter();
            approvalListXMLStreamWriter = new XmlStreamWriter();
            oldApprovalListXMLStreamWriter = new XmlStreamWriter();
            relatedListXMLStreamWriter.writeStartElement(null, 'RelatedRecords' , null);
            User applicant=[select id,TimeZoneSidKey from User where id=:Request.ownerid limit 1];
            // iterating over sections and displaying section names
             if(Request.Workflow__c!=label.CLIFv20199 && Request.Workflow__c !=label.CLIFv20200) {
            for(sobject s : RelatedRecords) {
                // adding sectionname
               System.debug('request>>'+Request.ownerid);
                table += sectionPrintableView.get('RelatedList').Division__c + '<output>' + s.get('IFv2_ContentType__c') + '</output>' + sectionPrintableView.get('EndTags').Division__c;
                relatedListXMLStreamWriter.writeStartElement(null, string.valueof(s.get('IFv2_ContentType__c')).replaceAll(' ', '') , null);
                relatedListXMLStreamWriter.writeEndElement();
                // adding table attribute under every section
                table += sectionPrintableView.get('RelatedList').Table__c;
                // getting respective fieldlist for related record
                LIST<IFv2_FieldWrapperClass> fieldwrapperlist = RelatedlistNameAndFieldWrapperListmap.get((string)s.get('IFv2_ContentType__c'));
                
                // initiating a variable that acts as  a counter and used to display two columns
                integer i = 0;
                string tr = '';
                
                // Iterating over field list of respective related record ,creating a table row for two fields,table for a section.
                for(IFv2_FieldWrapperClass fieldwrapper : fieldwrapperlist) {
                    String value;
                    if(fieldwrapper.Type=='Date' ){
                        Datetime dt = (Datetime)s.get(fieldwrapper.APINAME);
                        if(dt!=Null)
                            value =  string.valueof(dt.format('dd.MM.yyyy'));
                        else {
                            value ='';
                        }
                    }
                    else if(fieldwrapper.Type=='DATETIME')
                    {
                        
                        Datetime dt = (Datetime)s.get(fieldwrapper.APINAME);
                        if(dt!=Null)
                        {
                            Integer currentoffset = UserInfo.getTimezone().getOffset(DateTime.now()); 
                            TimeZone tz = Timezone.getTimeZone(applicant.TimeZoneSidKey);
                            System.debug('tz>>'+tz);
                            System.debug('tz without>>'+tz.getOffset(DateTime.now()));
                            datetimeoffset= (tz.getOffset(DateTime.now())-currentoffset )/ (1000 * 3600 * 24.0);
                            value =  string.valueof((dt+datetimeoffset).format('dd.MM.yyyy hh:mm a'));
                            /*

Datetime now = Datetime.now(); 
Integer offset = UserInfo.getTimezone().getOffset(now); 
Datetime local = now.addSeconds(offset/1000);
                            dt=dt.addSeconds(offset/1000);
                            System.debug('local>>'+dt);
                            value =  string.valueof(dt.format('dd.MM.yyyy hh:mm a')); 
                            System.debug('local>value>'+value);
                            
                            TimeZone tz = UserInfo.getTimeZone();
            				datetimeoffset= tz.getOffset(dt);
                            dt=dt+datetimeoffset;
                            value =  string.valueof(dt.format('dd.MM.yyyy hh:mm a')); */
                        }
                        else {
                            value ='';
                        }
                    }

                    else if(fieldwrapper.Type=='Boolean'){
                        value =(s.get(fieldwrapper.APINAME)==True?'Checked':'Blank');
                    }
                    else
                        value = String.valueof((s.get(fieldwrapper.APINAME) == Null? '' : (fieldwrapper.type == 'REFERENCE'? LookupRecordIdnNameMap.get((string)s.get(fieldwrapper.APINAME)) : (fieldwrapper.type == 'Currency'? s.get(fieldwrapper.APINAME) + UserInfo.getDefaultCurrency() :s.get(fieldwrapper.APINAME)))) );
                    
                    relatedListXMLStreamWriter.writeStartElement(null,FieldWrapper.APINAME , null);
                    relatedListXMLStreamWriter.writeCharacters(value);
                    relatedListXMLStreamWriter.writeEndElement();
                    
                    if(fieldwrapperlist.size() > 1) {
                        tr += sectionPrintableView.get('RelatedList').TableCellLabel__c + '<output>' + fieldwrapper.label + '</output>' + sectionPrintableView.get('EndTags').TableCellLabel__c;
                        tr += sectionPrintableView.get('RelatedList').TableCellValue__c + '<output>' + value + '</output>' + sectionPrintableView.get('EndTags').TableCellValue__c;
                        i++;
                        // checking for two columns and making table row empty ,so that next fields will come in next row
                        // last element if it is single it comes into thsi condition
                        if((math.mod(i,2) == 0) || (fieldwrapperlist.size() == i)) {
                            table += sectionPrintableView.get('RelatedList').TableRow__c + tr + sectionPrintableView.get('EndTags').TableRow__c;
                            tr = '';
                        }
                    } else {
                        tr += sectionPrintableView.get('RelatedList').TableCellLabel__c + '<output>' + fieldwrapper.label + '</output>' + sectionPrintableView.get('EndTags').TableCellLabel__c;
                        tr +=  sectionPrintableView.get('RelatedList').TableCellValue__c + '<output>' + value + '</output>' +sectionPrintableView.get('EndTags').TableCellValue__c;
                        table += sectionPrintableView.get('RecordDetailSection').TableRow__c+ tr +sectionPrintableView.get('EndTags').TableRow__c;
                        tr = '';
                    }
                }
                
                table += sectionPrintableView.get('RecordDetailSection').Table__c;
                
                // line after every section
                table += sectionPrintableView.get('RecordDetailSection').HorizonatalLine__c;
            }
        }
              else{
            IFv2_MaterialController.MaterialDisplayWrapper MDwrapper =  IFv2_MaterialController.getMaterialDetails(Request.id);
      
                for( IFv2_MaterialController.MaterialWrapper materialWrapper : MDwrapper.materialDetailLIST) {
                 Sobject   materialdetail = (Sobject)materialWrapper.material;
                // adding sectionname
                table += sectionPrintableView.get('RelatedList').Division__c + '<output>'+label.CLIFv20256 +'</output>' + sectionPrintableView.get('EndTags').Division__c;
                relatedListXMLStreamWriter.writeStartElement(null, 'MaterialChildDetails', null);
                relatedListXMLStreamWriter.writeEndElement();
                // adding table attribute under every section
                table += sectionPrintableView.get('RelatedList').Table__c;
                // getting respective fieldlist for related record
             //   LIST<IFv2_FieldWrapperClass> fieldwrapperlist = RelatedlistNameAndFieldWrapperListmap.get((string)s.get('IFv2_ContentType__c'));
                
                // initiating a variable that acts as  a counter and used to display two columns
                integer k = 0;
                string tr1 = '';
                
                // Iterating over field list of respective related record ,creating a table row for two fields,table for a section.
                for(integer j=0; j<MDwrapper.Labels.size();j++) {
                    String value = String.valueof((MDwrapper.APINAMES[j].contains('.')?materialdetail.getSObject(MDwrapper.APINAMES[j].split('\\.')[0]).get(MDwrapper.APINAMES[j].split('\\.')[1]):materialdetail.get(MDwrapper.APINAMES[j])));
                    value = (value==Null?'':value);
                    relatedListXMLStreamWriter.writeStartElement(null,MDwrapper.APINAMES[j] , null);
                    relatedListXMLStreamWriter.writeCharacters(value);
                    relatedListXMLStreamWriter.writeEndElement();
                    
                    if(MDwrapper.Labels.size() > 1) {
                        tr1 += sectionPrintableView.get('RelatedList').TableCellLabel__c + '<output>' + MDwrapper.LabelS[j] + '</output>' + sectionPrintableView.get('EndTags').TableCellLabel__c;
                        tr1 += sectionPrintableView.get('RelatedList').TableCellValue__c + '<output>' + value + '</output>' + sectionPrintableView.get('EndTags').TableCellValue__c;
                        k++;
                        // checking for two columns and making table row empty ,so that next fields will come in next row
                        // last element if it is single it comes into thsi condition
                        if((math.mod(k,2) == 0) || (MDwrapper.Labels.size() == k)) {
                            table += sectionPrintableView.get('RelatedList').TableRow__c + tr1 + sectionPrintableView.get('EndTags').TableRow__c;
                            tr1 = '';
                        }
                    } else {
                        tr1 += sectionPrintableView.get('RelatedList').TableCellLabel__c + '<output>' + MDwrapper.Labels[j] +'</output>' + sectionPrintableView.get('EndTags').TableCellLabel__c;
                        tr1 +=  sectionPrintableView.get('RelatedList').TableCellValue__c + '<output>' + value + '</output>' +sectionPrintableView.get('EndTags').TableCellValue__c;
                        table += sectionPrintableView.get('RecordDetailSection').TableRow__c+ tr1 +sectionPrintableView.get('EndTags').TableRow__c;
                        tr1 = '';
                    }
                }
                
                table += sectionPrintableView.get('RecordDetailSection').Table__c;
                
                // line after every section
                table += sectionPrintableView.get('RecordDetailSection').HorizonatalLine__c;
            }
            }
        
            relatedListXMLStreamWriter.writeEndElement();
            return table;
        }
        Catch(Exception e){
            system.debug('Error message'+e.getmessage());
            system.debug('Error line'+e.getLineNumber());
            system.debug('Error cause');
            return '';
        }
        
    }
    
    //Forming html for Approval related list
    public String getApprovalRelatedList() {
        //Calling other related lists
        try{
            String table = getDynamicallyHTMLforRelatedList();
            IFv2_RelatedListsController.RelatedList Approvalhistory = IFv2_RelatedListsController.completeRelatedList(Request.id, 'ProcessInstance');
            if(Approvalhistory.records.size() > 0) {
                //Declaration of variables
                MAP<string,string> APILABLEMAP = new MAP<string,string>();
                LIST<string> ApInameList = Approvalhistory.apiNames.split(',');
                LIST<string> LabelList = Approvalhistory.columnLabels.split(',');
                LIST<Sobject> ProcessInstanceHistorylist = new LIST<Sobject>();
                LIST<ProcessInstance> processInstancerecord = Approvalhistory.records;
                
                for(ProcessInstance processinstanceitem: processInstancerecord)
                    ProcessInstanceHistorylist.addall(processinstanceitem.StepsAndWorkitems);
                //forming a map of APIname and label  
                for(integer i=0;i<LabelList.size();i++) {
                    if(labellist[i] != 'Step Name' && labellist[i] != 'Actual Approver' && labellist[i] != 'Assigned To') {
                        APILABLEMAP.put(LabelList[i],ApInameList[i]);
                    } else if(LabelList[i] =='Actual Approver') {
                        APILABLEMAP.put(LabelList[i],'Actor.name');
                    } else if(LabelList[i] == 'Assigned To') {
                        APILABLEMAP.put(LabelList[i],'OriginalActor.name');
                    } else if(LabelList[i] == 'Date') {
                        APILABLEMAP.put(LabelList[i],ApInameList[i]);
                    }    
                    else if (LabelList[i]=='Step Name') {
                        APILABLEMAP.put(LabelList[i],'ProcessNode.Name');
                    }
                }
                approvalListXMLStreamWriter.writeStartElement(null,'ApprovalHistory', null);
                
                table += sectionPrintableView.get('ApprovalHistory').Division__c+ '<output>' + 'Approval history' + '</output>' +sectionPrintableView.get('EndTags').Division__c;
                table += sectionPrintableView.get('ApprovalHistory').Table__c;
                String tr = '';
                
                // Iterating over field set of respective request ,creating a table row for single field,table for a section.
                for(String label : APILABLEMAP.keyset()) {
                    
                    tr += sectionPrintableView.get('ApprovalHistory').TableCellLabel__c + '<output>' + label + '</output>' + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellLabel__c;
                }
                table += sectionPrintableView.get('ApprovalHistory').TableRow__c + tr + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableRow__c;
                tr = '';
                
                for(sobject s : ProcessInstanceHistorylist) {
                    for(String label : APILABLEMAP.keyset()) {
                        String APIName =  string.valueof(APILABLEMAP.get(label));
                        approvalListXMLStreamWriter.writeStartElement(null,APIName, null);
                        if(APIName.contains('.')) {
                            LIST<string> apinames =string.valueof(APILABLEMAP.get(label)).split('\\.');
                            if(s.getSobject(apinames[0]) != NULL){
                                String value =String.valueof((s.getSobject(apinames[0]).get(apinames[1]) == null? ' ' : (s.getSobject(apinames[0]).get(apinames[1]) == 'Started'? '<output>Submitted/output>' : (s.getSobject(apinames[0]).get(apinames[1]) == 'Removed'? '<output>Recalled</output>' : '<output>' + s.getSobject(apinames[0]).get(apinames[1])+ '</output>')) ));
                                approvalListXMLStreamWriter.writeCharacters(value);
                                approvalListXMLStreamWriter.writeEndElement();
                                tr += sectionPrintableView.get('ApprovalHistory').TableCellValue__c + '<output>' + value + '</output>' + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellValue__c;
                            }
                            else{
                                approvalListXMLStreamWriter.writeCharacters('');
                                approvalListXMLStreamWriter.writeEndElement();
                                tr += sectionPrintableView.get('ApprovalHistory').TableCellValue__c + '' + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellValue__c;
                                
                            }
                        }
                        
                        if(!APIName.contains('.')) {
                            if(APIName!='CreatedDate'){
                                String value = (String) (s.get(APIName) == Null? '' : (s.get(APIName) == 'Started'? + '<output>Submitted</output>' : (s.get(APIName) == 'Removed'? + '<output>Recalled</output>' : + '<output>'+s.get(APIName)+'</output>'))) ;
                                approvalListXMLStreamWriter.writeCharacters(value);
                                approvalListXMLStreamWriter.writeEndElement();
                                //   system.debug('value'+value);
                                tr += sectionPrintableView.get('ApprovalHistory').TableCellValue__c + '<output>' + value + '</output>' + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellValue__c;
                                system.debug('tr'+tr);
                            }
                            else {
                                Datetime dt = (Datetime)s.get('createddate');
                                approvalListXMLStreamWriter.writeCharacters(dt.format('dd.MM.yyyy h:mm a') );
                                approvalListXMLStreamWriter.writeEndElement();
                                
                                tr += sectionPrintableView.get('ApprovalHistory').TableCellValue__c + '<output>' + dt.format('dd.MM.yyyy h:mm a') + '</output>' + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellValue__c;
                                
                            }
                        }
                    }
                    table += sectionPrintableView.get('ApprovalHistory').TableRow__c + tr + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableRow__c;
                    tr = '';
                }
                table += sectionPrintableView.get('ApprovalHistory').Table__c;
                approvalListXMLStreamWriter.writeEndElement();
                // line after every section
                table += sectionPrintableView.get('ApprovalHistory').HorizonatalLine__c;
            }
            
            if(OldApprovalRecords.size() > 0) {
                table += getOldApprovalRelatedList();
            }
            return table + getchatterRelatedList() +getContentVersions();
        }
        Catch(Exception e){
            system.debug('Error message'+e.getmessage());
            system.debug('Error line'+e.getLineNumber());
            system.debug('Error cause');
            return '';
        }
    }
    
    //Forming HTMl For OldApprovalRelatedList
    public String getOldApprovalRelatedList() {
        MAP<String,String> labelAPINameMap = new MAP<String,String>();
        MAP<String,schema.FieldSet> fieldSetMap = schema.getGlobalDescribe().get('Account').getDescribe().fieldSets.getMap();
        Schema.FieldSet fieldSet = fieldSetMap.get('IFv2_OldApprovalHistory');
        LIST<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
        Schema.SObjectType AccountSchema = schemaMap.get('Account');
        Map<String, Schema.SObjectField> fieldMap = AccountSchema.getDescribe().fields.getMap();
        try{
            for (Schema.FieldSetMember fsm :fieldSetMembers ) {
                // This instaniation will return fieldwrapper of a particular fieldsetmember(field)
                labelAPINameMap.put(fsm.label, fsm.getFieldPath());
            }
           
            String table = '';
            String tr = '';
            table = sectionPrintableView.get('ApprovalHistory').Division__c+ '<output>Approval history</output>'+sectionPrintableView.get('EndTagsApprovalChatterAttachments').Division__c;
            table += sectionPrintableView.get('ApprovalHistory').Table__c;
            
            for(String label : labelAPINameMap.keySet()){
                tr += sectionPrintableView.get('ApprovalHistory').TableCellLabel__c+ '<output>'+label+ '</output>' +sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellLabel__c;
            }
            table += sectionPrintableView.get('ApprovalHistory').TableRow__c+tr+sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableRow__c;
            tr = '';
            oldApprovalListXMLStreamWriter.writeStartElement(Null, 'LegacyApprovalHistory', Null);
            
            //iterating over sections and displaying section names
            for(sobject s : OldApprovalRecords) {
                for(String label : labelAPINameMap.keySet()){
                    Schema.SObjectField fieldsc = fieldMap.get(labelAPINameMap.get(label));
                    Schema.DisplayType FldType = fieldsc.getDescribe().getType();  
                    if(string.valueof(FldType)=='Datetime'){
                        Datetime dt = (Datetime)s.get(labelAPINameMap.get(label));
                        oldApprovalListXMLStreamWriter.writeStartElement(Null, labelAPINameMap.get(label), Null);
                        tr += sectionPrintableView.get('ApprovalHistory').TableCellValue__c + '<output>' + dt.format('dd.MM.yyyy h:mm a') +'</output>' + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellValue__c;
                        oldApprovalListXMLStreamWriter.writeCharacters(dt.format('dd.MM.yyyy h:mm a'));
                        oldApprovalListXMLStreamWriter.writeEndElement(); 
                    }
                    else if(string.valueof(FldType)=='REFERENCE' || labelAPINameMap.get(label)=='IFv2_LegacyActualApprover__c' || labelAPINameMap.get(label)=='IFv2_Legacysubmitter__c' || labelAPINameMap.get(label)=='IFv2_LegacyAssignedTo__c'){
                        oldApprovalListXMLStreamWriter.writeStartElement(Null, labelAPINameMap.get(label), Null);
                        tr += sectionPrintableView.get('ApprovalHistory').TableCellValue__c + '<output>' + LookupRecordIdnNameMap.get((String)s.get(labelAPINameMap.get(label))) + '</output>' + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellValue__c;
                        if(LookupRecordIdnNameMap.get((String)s.get(labelAPINameMap.get(label)))!=Null)
                            oldApprovalListXMLStreamWriter.writeCharacters(LookupRecordIdnNameMap.get((String)s.get(labelAPINameMap.get(label))));
                        else
                            oldApprovalListXMLStreamWriter.writeCharacters('');
                        oldApprovalListXMLStreamWriter.writeEndElement();
                    }
                    else{
                        String value ='';
                        if(String.isNotblank(String.valueof(s.get(labelAPINameMap.get(label)))) ){
                            value = String.valueof(s.get(labelAPINameMap.get(label)));
                        }
                        oldApprovalListXMLStreamWriter.writeStartElement(Null, labelAPINameMap.get(label), Null);
                        tr += sectionPrintableView.get('ApprovalHistory').TableCellValue__c +'<output>' + value + '</output>' + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellValue__c;
                        if(string.isNotBlank((String)s.get(labelAPINameMap.get(label))))
                            oldApprovalListXMLStreamWriter.writeCharacters(value);
                        else {
                            oldApprovalListXMLStreamWriter.writeCharacters('');
                        }
                        oldApprovalListXMLStreamWriter.writeEndElement();
                        
                    }
                }
                table += sectionPrintableView.get('ApprovalHistory').TableRow__c + tr + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableRow__c;
                tr = '';
            }
            oldApprovalListXMLStreamWriter.writeEndElement();
            table += sectionPrintableView.get('EndTagsApprovalChatterAttachments').Table__c;
            
            // line after every section
            table += sectionPrintableView.get('ApprovalHistory').HorizonatalLine__c;
            return table ;
        }
        Catch(Exception e){
             system.debug('labelAPINameMap'+labelAPINameMap);
            system.debug('Error message'+e.getmessage());
            system.debug('Error line'+e.getLineNumber());
            system.debug('Error cause'+e.getCause());
            
            return '';
        }
    }
    //Chatter related list
    public static String getchatterRelatedList() {
        LIST<FeedItem> feedLIST = new LIST<FeedItem>();
        try{
            //Querying the chatter feed items,feed comments, feed tracked changes
            if(String.isNotBlank(chatterparentId))  
                feedLIST =[SELECT Id,linkurl,HasLink,Body,Type,Title,isRichText,ParentId,RelatedRecordId,
                           CreatedById,CreatedBy.name,CreatedDate,LastEditById,LastEditDate,Visibility, 
                           (SELECT Id,FeedItemId,CommentBody,ParentId,RelatedRecordId,Status,createdById,createddate,CreatedBy.name FROM FeedComments), 
                           (SELECT ID, FieldName, OldValue, NewValue FROM FeedTrackedChanges) 
                           FROM FeedItem 
                           WHERE ParentId =:chatterparentId
                           AND (Type = 'ContentPost' OR Type = 'LinkPost' OR Type = 'TextPost' OR Type = 'TrackedChange')];
            //forming html table
            if(!feedLIST.isEmpty() || test.isRunningTest()){
                String table = '';
                String tr = '';
                table = sectionPrintableView.get('Chatter').Division__c+'Chatter Data'+ sectionPrintableView.get('EndTagsApprovalChatterAttachments').Division__c;
                table += sectionPrintableView.get('Chatter').Table__c;
                
                tr += sectionPrintableView.get('Chatter').TableCellLabel__c+'Created By'+sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellLabel__c;
                tr += sectionPrintableView.get('Chatter').TableCellLabel__c+'Post/Comment'+sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellLabel__c;
                
                table += tr+sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableRow__c;
                //forming xml
                chatterListXMLStreamWriter.writeStartElement(Null, 'Chatter', Null);
                
                //iterating over sections and displaying section names
                for(FeedItem feed : feedLIST) {
                    
                    tr = '';
                    Datetime dt = (Datetime)feed.get('createddate');
                    //Created Date and created by
                    chatterListXMLStreamWriter.writeStartElement(Null, 'CreatedBy', Null);
                    tr += sectionPrintableView.get('Chatter').TableCellValue__c + '<output>' +feed.CreatedBy.name +' '+dt.format('dd.MM.yyyy h:mm a')+ '</output>'+ sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellValue__c;
                    chatterListXMLStreamWriter.writeCharacters(feed.CreatedBy.name+' '+dt.format('dd.MM.yyyy h:mm a') );
                    chatterListXMLStreamWriter.writeEndElement();
                    //body
                    chatterListXMLStreamWriter.writeStartElement(Null, 'Body', Null);
                    if(feed.body!=Null){
                        tr += sectionPrintableView.get('Chatter').TableCellValue__c + '<output>' + feed.body + '</output>' + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellValue__c;
                        chatterListXMLStreamWriter.writeCharacters(feed.body );
                    }
                    else if(feed.type=='TrackedChange'){
                        String body = feed.CreatedBy.name+' changed '+ (string)feed.FeedTrackedChanges[0].FieldName.split('\\.')[1] +' from a '+((string)feed.FeedTrackedChanges[0].oldvalue==null?'blank value':(string)feed.FeedTrackedChanges[0].oldvalue) +' to '+(string)feed.FeedTrackedChanges[0].NewValue;
                        tr += sectionPrintableView.get('Chatter').TableCellValue__c + '<output>'+ body + '</output>' + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellValue__c;
                        chatterListXMLStreamWriter.writeCharacters(body);  
                    }
                    chatterListXMLStreamWriter.writeEndElement();
                    table += tr + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableRow__c;
                    tr = '';
                    //Chatter Comments
                    if(feed.feedcomments.size()>0){
                        table += getChatterComments(feed.feedcomments);   
                    }
                }
                
                chatterListXMLStreamWriter.writeEndElement();
                
                table += sectionPrintableView.get('EndTagsApprovalChatterAttachments').Table__c;
                
                // line after every section
                table += sectionPrintableView.get('EndTagsApprovalChatterAttachments').HorizonatalLine__c;
                return table;
            }
            else {
                return '';
            }
        }
        Catch(Exception e){
            system.debug('Error message'+e.getmessage());
            system.debug('Error line'+e.getLineNumber());
            system.debug('Error cause');
            return '';
        }
    }
    //chatter comments
    public static String getChatterComments(LIST<FeedComment> commentList){
        String table = '';
        String tr = '';
        //iterating over sections and displaying section names
        String feeddata='';
        try{
            for(FeedComment feed : commentList) {
                Datetime dt = (Datetime)feed.get('createddate');
                //Created Date
                if(feed!=null){
                    chatterListXMLStreamWriter.writeStartElement(Null, 'createdby', Null);
                    tr += sectionPrintableView.get('Chatter').TableCellValue__c + '<output>'+feed.CreatedBy.name +'</output>'+ ' '+ dt.format('dd.MM.yyyy h:mm a') +sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellValue__c;
                    
                    chatterListXMLStreamWriter.writeCharacters(feed.CreatedBy.name +' '+dt.format('dd.MM.yyyy h:mm a'));
                    chatterListXMLStreamWriter.writeEndElement();
                }
                
                tr += sectionPrintableView.get('Chatter').TableCellValue__c+ (feed.commentbody==Null ? '' : '<output>'+feed.commentbody.stripHtmlTags()+'</output>') + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellValue__c;
                
                chatterListXMLStreamWriter.writeStartElement(Null, 'Body', Null);
                chatterListXMLStreamWriter.writeCharacters((feed.commentbody==Null ? '' : feed.commentbody.stripHtmlTags()));
                chatterListXMLStreamWriter.writeEndElement();
                
                feeddata +=  tr + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableRow__c;
                tr = '';
            }
            
            return table+feeddata;
        }
        Catch(Exception e){
            system.debug('Error message'+e.getmessage());
            system.debug('Error line'+e.getLineNumber());
            system.debug('Error cause');
            return '';
        }
    }
    //get the files under it
    public static String getContentVersions(){
        try{
            attachmentsListXMLStreamWriter=new XmlStreamWriter();
            //Getting contentdocumentids and then querying for contentversions
            SET<id> contentDocumentIds = new SET<id>();
            if(String.isBlank(chatterparentId))
                chatterparentId =ApexPages.currentPage().getParameters().get('id');
            for(contentdocumentlink contentdocumentlink: [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =:chatterparentId]) {
                contentDocumentIds.add(contentdocumentlink.ContentDocumentId);
            }
            if(!contentDocumentIds.isEmpty()){
                String table = '';
                String tr = '';
                system.debug('from test>AttachmentsSection>'+sectionPrintableView.get('AttachmentsSection'));
                system.debug('from test>'+sectionPrintableView.get('EndTagsApprovalChatterAttachments'));
                table = sectionPrintableView.get('AttachmentsSection').Division__c+'Notes & Attachments'+sectionPrintableView.get('EndTagsApprovalChatterAttachments').Division__c;
                table += sectionPrintableView.get('AttachmentsSection').Table__c;
                tr += sectionPrintableView.get('AttachmentsSection').TableCellLabel__c+'TITLE'+sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellLabel__c;
                table += tr+sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableRow__c;
                tr='';
                attachmentsListXMLStreamWriter.writeStartElement(Null, 'NotesAndAttachments', Null);
                if(contentDocumentIds!=Null)
                    for(contentversion cv : [SELECT Id, TITLE FROM contentversion WHERE contentdocumentid in:contentDocumentIds AND islatest=true]) {
                        attachmentsListXMLStreamWriter.writeStartElement(Null, 'TITLE', Null);
                        tr += sectionPrintableView.get('Chatter').TableCellValue__c + '<output>'+cv.TITLE+'</output>'+ sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellValue__c;
                        attachmentsListXMLStreamWriter.writeCharacters(cv.TITLE);
                        attachmentsListXMLStreamWriter.writeEndElement();
                        table += tr + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableRow__c;
                        tr = '';
                    }
                //getting attachments 
                if(String.isnotBlank(chatterparentId))
                    for(Attachment file : [SELECT Id, Name FROM Attachment WHERE parentid=:chatterparentId]) {
                        attachmentsListXMLStreamWriter.writeStartElement(Null, 'TITLE', Null);
                        tr += sectionPrintableView.get('Chatter').TableCellValue__c + '<output>'+file.Name+'</output>'+ sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableCellValue__c;
                        attachmentsListXMLStreamWriter.writeCharacters(file.Name);
                        attachmentsListXMLStreamWriter.writeEndElement();
                        table += tr + sectionPrintableView.get('EndTagsApprovalChatterAttachments').TableRow__c;
                        tr = '';
                    }
                table += sectionPrintableView.get('EndTagsApprovalChatterAttachments').Table__c;
                // line after every section
                table += sectionPrintableView.get('EndTagsApprovalChatterAttachments').HorizonatalLine__c;
                attachmentsListXMLStreamWriter.writeEndElement();
                
                return table;
            }
            else {
                return '';
            }
        }
        Catch(Exception e){
            system.debug('Error message'+e.getmessage());
            system.debug('Error line'+e.getLineNumber());
            system.debug('Error cause');
            return '';
        }
    }      
    
}