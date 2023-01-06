/*******************************************************************************************************
* 
* @ Name 		: IFv2_FieldWrapperClass
* @ Purpose		: Wrapper class used for displaying fields in Generic Layout component
* @ Author		: Anoop Ravindran
* @ Test Class 	: IFv2_FieldSetFormControllerTest 
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   31-10-2018      |  anoop.ravindran@absyz.com    |  1.0          |  Initial Version

*******************************************************************************************************/

public with sharing class IFv2_FieldWrapperClass {
    
    public static MAP<Schema.SObjectType, Schema.DescribeSObjectResult> objectDescribeMAP = new MAP<Schema.SObjectType, Schema.DescribeSObjectResult>();
    public static MAP<String, MAP<String, Schema.SObjectField>> fieldDescribeMAP = new MAP<String, MAP<String, Schema.SObjectField>>();
    
    public IFv2_FieldWrapperClass(Schema.FieldSetMember fieldSetMember) {
        this.DBRequired = fieldSetMember.DBRequired;
        this.APIName = fieldSetMember.fieldPath;
        this.Label = fieldSetMember.label;
        this.Required = fieldSetMember.required;
        this.Type = String.valueOf(fieldSetMember.getType());
        this.HelpText = '';
        this.PickListValues = new LIST<String>();
        this.Disabled = false;
    }
    
    public IFv2_FieldWrapperClass(Schema.FieldSetMember fieldSetMember, String objectname, SObject record, MAP<String, Schema.SObjectField> fieldMAP) {
        this.DBRequired = fieldSetMember.DBRequired;
        this.APIName = fieldSetMember.fieldPath;
        this.Label = fieldSetMember.label;
        this.Required = fieldSetMember.required;
        this.Type = String.valueOf(fieldSetMember.getType());
        this.pickListValues = new LIST<String>();
        this.ControllerField = '';
        this.LookupObject = '';
        this.Disabled = false;
        String objName = objectName;
        if(this.Type.toLowerCase() == 'textarea'){
            if(fieldMAP.containsKey(fieldSetMember.fieldPath)){
                if(fieldMap.get(fieldSetMember.fieldPath).getDescribe().isHtmlFormatted()){
                    this.Type = 'richTextArea';
                }
            }
        }
        if(this.Type.toLowerCase() == 'reference') {
            if(fieldMAP.containsKey(fieldSetMember.fieldPath)) {
                LIST<Schema.SObjectType> referenceLIST = fieldMAP.get(fieldSetMember.fieldPath).getDescribe().getReferenceTo();
                if(!referenceLIST.isEmpty()) {
                    if(objectDescribeMAP.containsKey(referenceLIST[0])) {
                        Schema.DescribeSObjectResult objectDescribe = objectDescribeMAP.get(referenceLIST[0]);
                        this.LookupObject = objectDescribe.getName();
                        this.isCreateable = objectDescribe.isCreateable();
                    } else {
                        Schema.DescribeSObjectResult objectDescribe = referenceLIST[0].getDescribe();
                        this.LookupObject = objectDescribe.getName();
                        this.isCreateable = objectDescribe.isCreateable();
                        objectDescribeMAP.put(referenceLIST[0], objectDescribe);
                    }
                }
            }
        }
        if(!(fieldSetMember.fieldPath).contains('.')) {
            Schema.DescribeFieldResult fieldDescribe = fieldMAP.get(fieldSetMember.fieldPath).getDescribe();
            this.HelpText = fieldDescribe.getInlineHelpText();
            
            String controllingField = fieldDescribe.getController() != null ? fieldDescribe.getController().getDescribe().getName() : null;
            String controllingVal;
            if(controllingField != null) {
                this.ControllerField = controllingField;
                String recordId = String.valueOf(record.get('Id'));
                string query = 'SELECT ' + controllingField + ' FROM ' + objectName + ' WHERE Id = :recordId';
                LIST<Sobject> recordLIST = Database.query(query);	//LIST to store queried records
                if(!recordLIST.isEmpty()) {
                    controllingVal = String.valueOf(recordLIST[0].get(controllingField));
                }
            }
            
            if(record != null && controllingField != null && controllingVal != null) {
                MAP<String, LIST<string>> depPickListMAP = IFv2_TStringUtils.GetDependentOptions(objectname, controllingField, fieldSetMember.fieldPath);	//MAP of dependent PickList
                if(depPickListMAP.containsKey(controllingVal)) {
                    this.PickListValues.addAll(depPickListMAP.get(controllingVal));
                }
            } else if(controllingField == null) {
                LIST<Schema.PickListEntry> pickLIST = fieldDescribe.getPickListValues();
                for(Schema.PickListEntry pickEntry : pickLIST) {
                    this.PickListValues.add(pickEntry.getValue());
                }
            }
            this.ReadOnly = !fieldDescribe.isUpdateable();
        } else {
            String field = fieldSetMember.fieldPath;
            LIST<String> tempLIST = field.split('\\.');
            String lookupFieldName;
            if(tempLIST[0].contains('__r')) {
                lookupFieldName = tempLIST[0].replace('__r','__c');
            } else {
                lookupFieldName = tempLIST[0] + 'Id';
            }
            String fieldName = tempLIST[1];
            String relObjName = fieldMAP
                .get(lookupFieldName)
                .getDescribe()
                .getReferenceTo()[0]
                .getDescribe()
                .getName();
            
            MAP<String, Schema.SObjectField> relatedFieldsMap = new MAP<String, Schema.SObjectField>();
            if(fieldDescribeMAP.containsKey(relObjName)) {
                relatedFieldsMap = fieldDescribeMAP.get(relObjName);
            } else {
                relatedFieldsMap = Schema.getGlobalDescribe().get(relObjName).getDescribe().fields.getMAP();
                fieldDescribeMAP.put(relObjName, relatedFieldsMap);
            }
            Schema.DescribeFieldResult fieldDescribe = (relatedFieldsMap.get(fieldName)).getDescribe();
            if(this.Type.toLowerCase() == 'textarea'){
                if(fieldDescribe.isHtmlFormatted()){
                    this.Type = 'richTextArea';
                }
            }
            
            this.HelpText = fieldDescribe.getInlineHelpText();
            this.ReadOnly = !fieldDescribe.isUpdateable();
            LIST<Schema.PickListEntry> pickLIST = fieldDescribe.getPickListValues();
            for(Schema.PickListEntry pickEntry : pickLIST) {
                this.PickListValues.add(pickEntry.getValue());
            }
        }
    }
    
    public IFv2_FieldWrapperClass() {}
    public IFv2_FieldWrapperClass(Boolean DBRequired) {
        this.DBRequired = DBRequired;
    }
    
    @AuraEnabled public LIST<String> pickListValues{ get; set; }
    @AuraEnabled public String APIName { get;set; }
    @AuraEnabled public String Label { get;set; }
    @AuraEnabled public String Type { get; set; }
    @AuraEnabled public String HelpText { get; set; }
    @AuraEnabled public String ControllerField { get; set; }
    @AuraEnabled public String LookupObject { get; set; }
    @AuraEnabled public String DisplayLabel { get;set; }
    @AuraEnabled public String LookupFilter { get;set; }
    @AuraEnabled public Boolean DBRequired { get;set; }
    @AuraEnabled public Boolean isCreateable { get;set; }
    @AuraEnabled public Boolean Disabled { get;set; }
    @AuraEnabled public Boolean ReadOnly { get; set; }
    @AuraEnabled public Boolean Required { get;set; }
}