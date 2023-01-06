/*******************************************************************************************************
* 
* @ Name        :   IFv2_ScanPrintableViewController
* @ Purpose     :   Printable view controller
* @ Author      :   Naga Sai
* @ Test Class  :   IFv2_ScanPrintableViewControllerTest
*
*   Date        |  Developer Name                   |  Version      |  Changes
* ======================================================================================================
*   12-04-2019  |  nagasai.chalamalasetti@absyz.com |  1.0          |  Initial Version
*   23-04-2019  |  nagasai.chalamalasetti@absyz.com |  1.1          |  Added logic for XML related list 
********************************************************************************************************/

public with sharing class IFv2_ScanPrintableViewController {
    //Holds scan record id
    public Id  scanId;
    //holds list of field wrapper which is used in generation of table for print view
    public LIST<Fieldwrapper> fieldWrapperLIST;
    public String logoURL{get;set;}
    //holds queried scan record
    public  LIST<SObject> records;
    //this variable holds the xml of related list
    public transient XmlStreamWriter relatedListXMLStreamWriter ;
    public LIST<IFv2_PrintableViewLayout__mdt> printableViewLayoutList = new LIST<IFv2_PrintableViewLayout__mdt>();
    public static MAP<String,IFv2_PrintableViewLayout__mdt> sectionPrintableView = new MAP<String,IFv2_PrintableViewLayout__mdt>();
    
    //Specifically used to set the scanid variable with scan record id using parameters from page reference
    //This is useful when we invoke the vf page through apex class
    public IFv2_ScanPrintableViewController(apexpages.StandardController RequestStandardController){
        //forming logo url
        LIST<document> DocumentLIST = [select id from document where name =:label.CLIFv20247];
        if(DocumentLIST.size()>0)
            logourl =  URL.getSalesforceBaseUrl().toExternalForm()+'/servlet/servlet.ImageServer?id='+DocumentLIST[0].id+'&oid='+ UserInfo.getOrganizationId();
        else
            logourl ='';  system.debug('logourl'+logourl);
        ScanId=ApexPages.currentPage().getParameters().get('id');
        relatedListXMLStreamWriter = new XMLStreamWriter();
    }
    //specifically used to set the scanid variable with scan record id using input parameters
    public IFv2_ScanPrintableViewController(String scanid){
        //forming logo url
        LIST<document> DocumentLIST = [select id from document where name =:label.CLIFv20247];
        if(DocumentLIST.size()>0)
            logourl =  URL.getSalesforceBaseUrl().toExternalForm()+'/servlet/servlet.ImageServer?id='+DocumentLIST[0].id+'&oid='+ UserInfo.getOrganizationId();
        else
            logourl ='';   system.debug('logourl'+logourl);
        this.ScanId = scanid;
        relatedListXMLStreamWriter = new XMLStreamWriter();
    }
    //Method to generate the html table 
    public String getgeneratePDF(){
        //used to store field api names which is inturn used in dynaic soql query
        LIST<String> fieldNames = new LIST<String>();
        records = new LIST<SObject>();
        fieldwrapperList = new LIST<Fieldwrapper>();
        
        
        printableViewLayoutList =[select DeveloperName,HorizonatalLine__c,Division__c,Table__c,TableCellLabel__c,TableCellValue__c,TableRow__c from IFv2_PrintableViewLayout__mdt];
        for(IFv2_PrintableViewLayout__mdt printableLayout : printableViewLayoutList){
            sectionPrintableView.put(printableLayout.DeveloperName,printableLayout);
        }
        
        //get the object API name
        Schema.SObjecttype   objecttype = scanId.getSobjecttype();
        // start of Logic to get a fields of a specific fieldset.
        //used to get the entire metadata of the object
        Schema.DescribeSObjectResult objectDescribe = objecttype.getDescribe();
        //holds field set values against its API name
        MAP<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap();
        //retrieves the entire fields information in that field set
        Schema.FieldSet fieldSet = fieldSetMap.get('IFv2_ScanLayout');
        LIST<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
        // end of Logic to get a fields of a specific fieldset.
        
        //iterating over field set members and initializing field wrapper
        for (Schema.FieldSetMember fsm : fieldSetMembers) {
            Fieldwrapper f= new Fieldwrapper(fsm.getlabel(),fsm.getFieldpath(),String.valueof(fsm.gettype()));
            //fieldwrapper consists of
            //1. field label
            //2. field api name
            //3. field type
            fieldwrapperList.add(f);
            //adding relationship fields for the reference type fields
            if(String.valueof(fsm.gettype())=='REFERENCE'){
                if(fsm.getFieldpath().contains('__c'))
                    fieldNames.add(fsm.getFieldpath().replace('__c','__r.name'));
                if(fsm.getFieldpath() =='lastmodifiedbyId' || fsm.getFieldpath()=='CreatedbyId' || fsm.getFieldpath()=='ownerid')
                    fieldNames.add(fsm.getFieldpath().replace('Id','.Name'));
            }
            fieldNames.add(fsm.getFieldpath());
        }
        //forming a dynamic query
        String query =	  ' SELECT ' +	      String.join( fieldNames, ',' ) +	  ' FROM ' +	      objecttype +	  ' WHERE ' +	      ' id = :ScanId ' +	  ' LIMIT 1 '	;	
        
        records = Database.query( query );	
        //this variable holds entire html that is shown in pdf
        String table = '';
        if(!records.isEmpty()){
            table += sectionPrintableView.get('RecordDetailSection').Division__c + '<output>Scan Details</output>'+ sectionPrintableView.get('EndTags').Division__c;
            //holds row to be displayed in table
            String tr = '';
            // initiating a variable that acts as  a counter and used to display two columns
            Integer i = 0;
            //iterating over fieldwrappers and processing each field
            for(fieldwrapper fielddescribe : FieldwrapperList) {
                table += sectionPrintableView.get('RecordDetailSection').Table__c;
                tr += sectionPrintableView.get('RecordDetailSection').TableCellLabel__c + '<output>' + fielddescribe.label + '</output>' + sectionPrintableView.get('EndTags').TableCellLabel__c ;
                //checking for reference type fields and changing them to display the names instead of ids
                if(fielddescribe.type=='REFERENCE' && fielddescribe.apiName.contains('__c'))
                    tr += sectionPrintableView.get('RecordDetailSection').TableCellValue__c + (records[0].getsobject(fielddescribe.apiName.replace('__c','__r')).get('Name') == null ? ' ' : '<output>'+records[0].getsobject(fielddescribe.apiName.replace('__c','__r')).get('Name')+'</output>') + sectionPrintableView.get('EndTags').TableCellValue__c;
                else if(fielddescribe.apiName =='LastModifiedById' || fielddescribe.apiName=='CreatedById' || fielddescribe.apiName=='OwnerId'){
                    if(!test.isRunningTest())
                        tr +=sectionPrintableView.get('RecordDetailSection').TableCellValue__c + (records[0].getsobject(fielddescribe.apiName.replace('Id','')).get('Name') == null ? ' ' : '<output>'+ records[0].getsobject(fielddescribe.apiName.replace('Id','')).get('Name')+'</output>') + sectionPrintableView.get('EndTags').TableCellValue__c;
                }
                else
                    tr += sectionPrintableView.get('RecordDetailSection').TableCellValue__c + (records[0].get(fielddescribe.apiName) == null ? ' ' : '<output>'+records[0].get(fielddescribe.apiName)+'</output>') + sectionPrintableView.get('EndTags').TableCellValue__c;
                i++;
                // last element if it is single it comes into thsi condition
                
                if(math.mod(FieldwrapperList.size(),2)!=0 && FieldwrapperList.size()==i)
                    table += tr+ sectionPrintableView.get('EndTags').Table__c;
                // checking for two columns and making table row empty ,so that next fields will come in next row
                
                if(math.mod(i,2) == 0){
                    table += tr+sectionPrintableView.get('EndTags').Table__c;
                    tr='';
                }
                
            }
        }
        IFv2_PrintableViewController.chatterparentId = ScanId;
        IFv2_PrintableViewController.printableViewLayoutList = printableViewLayoutList;
        IFv2_PrintableViewController.sectionPrintableView = sectionPrintableView;
        return table+getRelatedList()+IFv2_PrintableViewController.getchatterRelatedList()+IFv2_PrintableViewController.getContentVersions();
    }
    public String getRelatedList(){
        //used to store field api names which is inturn used in dynaic soql query
        LIST<String> fieldNames = new LIST<String>();
        LIST<SObject> records = new LIST<SObject>();
        LIST<Fieldwrapper>  fieldwrapperList = new LIST<Fieldwrapper>();
        // start of Logic to get a fields of a specific fieldset.
        //used to get the entire metadata of the object
        Schema.DescribeSObjectResult objectDescribe = IFv2_Request__c.sObjectType.getDescribe();
        //holds field set values against its API name
        MAP<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap();
        //retrieves the entire fields information in that field set
        Schema.FieldSet fieldSet = fieldSetMap.get('IFv2_ScanICORequests');
        LIST<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
        // end of Logic to get a fields of a specific fieldset.
        
        //iterating over field set members and initializing field wrapper
        for (Schema.FieldSetMember fsm : fieldSetMembers) {
            Fieldwrapper f= new Fieldwrapper(fsm.getlabel(),fsm.getFieldpath(),String.valueof(fsm.gettype()));
            //fieldwrapper consists of
            //1. field label
            //2. field api name
            //3. field type
            fieldwrapperList.add(f);
            //adding relationship fields for the reference type fields
            if(String.valueof(fsm.gettype())=='REFERENCE'){
                if(fsm.getFieldpath().contains('__c'))
                    fieldNames.add(fsm.getFieldpath().replace('__c','__r.name'));
                if(fsm.getFieldpath() =='lastmodifiedbyId' || fsm.getFieldpath()=='CreatedbyId' || fsm.getFieldpath()=='ownerid')
                    fieldNames.add(fsm.getFieldpath().replace('Id','.Name'));
            }
            fieldNames.add(fsm.getFieldpath());
        }
        //forming a dynamic query
        String query =	  ' SELECT ' +	      String.join( fieldNames, ',' ) +	  ' FROM IFv2_Request__c' +	  ' WHERE ' +	      ' Scan__c = :ScanId ';	
        
        records = Database.query( query );	
        //this variable holds entire html that is shown in pdf
        String table = '';
        if(!records.isEmpty()){
            //setting the start element for XML
            relatedListXMLStreamWriter.writeStartElement(null, 'ICORequest', null);
            
            for(sobject request:records){
                table += sectionPrintableView.get('RelatedList').Division__c  + 'ICO Request'+ sectionPrintableView.get('EndTags').Division__c ;
                //holds row to be displayed in table
                String tr = '';
                // initiating a variable that acts as  a counter and used to display two columns
                Integer i = 0;
                //iterating over fieldwrappers and processing each field
                for(fieldwrapper fielddescribe : FieldwrapperList) {
                    //setting the element header for xml
                    relatedListXMLStreamWriter.writeStartElement(Null, fielddescribe.apiName, Null);
                    table += sectionPrintableView.get('RelatedList').Table__c;
                    tr +=  sectionPrintableView.get('RelatedList').TableCellLabel__c + fielddescribe.apiName + sectionPrintableView.get('EndTags').TableCellLabel__c;
                    //checking for reference type fields and changing them to display the names instead of ids
                    if(fielddescribe.type=='REFERENCE' && fielddescribe.apiName.contains('__c')){
                        String value = (String) (request.getsobject(fielddescribe.apiName.replace('__c','__r')).get('Name') == null ? ' ' : '<output>'+request.getsobject(fielddescribe.apiName.replace('__c','__r')).get('Name')+'</output>');
                        tr +=sectionPrintableView.get('RelatedList').TableCellValue__c + '<output>' + value  +'</output>' + sectionPrintableView.get('EndTags').TableCellValue__c;
                        //setting the element data
                        relatedListXMLStreamWriter.writeCharacters(value);
                    }
                    else if(fielddescribe.apiName =='LastModifiedById' || fielddescribe.apiName=='CreatedById' || fielddescribe.apiName=='OwnerId'){
                        String value = (String) (request.getsobject(fielddescribe.apiName.replace('Id','')).get('Name') == null ? ' ' : '<output>'+request.getsobject(fielddescribe.apiName.replace('Id','')).get('Name')+'</output>');
                        tr += sectionPrintableView.get('RelatedList').TableCellValue__c + '<output>' + value + '</output>' + sectionPrintableView.get('EndTags').TableCellValue__c;
                        //setting the element data
                        relatedListXMLStreamWriter.writeCharacters(value);
                    }
                    else{
                        String value = (String) (request.get(fielddescribe.apiName) == null ? ' ' : '<output>'+ request.get(fielddescribe.apiName)+'<output>') ;
                        tr += sectionPrintableView.get('RelatedList').TableCellValue__c + '<output>' +value + '</output>' + sectionPrintableView.get('EndTags').TableCellValue__c;
                        //setting the element data
                        relatedListXMLStreamWriter.writeCharacters(value); 
                    }
                    relatedListXMLStreamWriter.writeEndElement();
                    i++;
                    // last element if it is single it comes into thsi condition
                    
                    if(math.mod(FieldwrapperList.size(),2)!=0 && FieldwrapperList.size()==i)
                        table += tr+sectionPrintableView.get('EndTags').Table__c;
                    // checking for two columns and making table row empty ,so that next fields will come in next row
                    
                    if(math.mod(i,2) == 0){
                        table += tr+sectionPrintableView.get('EndTags').Table__c;
                        tr='';
                    }
                    
                }
                
            }
            relatedListXMLStreamWriter.writeEndElement(); 
        }
        return table;
    }
    
    //basic use is to have a label,apiname,type of  a field to be wrapped in one variable
    public class  Fieldwrapper{
        public String label;
        public String apiName;
        public String type;
        public Fieldwrapper(String label,String apiName,String type){
            this.label = label;
            this.apiName = apiName;
            this.type = type;
        }
    }
}