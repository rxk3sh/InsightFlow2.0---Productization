/*******************************************************************************************************
* 
* @ Name :IFv2_FieldSetUtility
* @ Purpose :  utility class for generic page layout component
* @ Author: Anoop Ravindran
*
*   Date	        |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   31-10-2018      |  anoop.ravindran@absyz.com	|  1.0          |  Initial Version

*******************************************************************************************************/
public with sharing class IFv2_FieldSetUtility {
    /*method to get fields with custom labels from fieldset name*/
    /*method needs to be removed*/
   /* public static List<IFv2_FieldWrapperClass> getFields(Id recordId, String objectName, String fieldSetName, String sectionId) {
        Schema.SObjectType objectType = null;
        map<String,String> fieldLabelMap = new map<String,String>();
        for(sObject fieldLabel : [	SELECT Id,Section__c,FieldAPIName__c,FieldLabel__c
                                  FROM IFv2_CustomFieldLabel__mdt 
                                  WHERE Section__c = :sectionId ]){
                                      fieldLabelMap.put(String.valueOf(fieldLabel.get('FieldAPIName__c')),String.valueOf(fieldLabel.get('FieldLabel__c')));							
                                  }
        if (recordId != null) {
            objectType = recordId.getSobjectType();
        }
        else if (String.isNotBlank(objectName)) {
            objectType = Schema.getGlobalDescribe().get(objectName);
        }
        
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        Map<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap();
        Schema.FieldSet fieldSet = fieldSetMap.get(fieldSetName);
        List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
        MAP<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        List<IFv2_FieldWrapperClass> fields = new List<IFv2_FieldWrapperClass>();
        for (Schema.FieldSetMember fsm : fieldSetMembers) {
            IFv2_FieldWrapperClass f = new IFv2_FieldWrapperClass(fsm,objectName,null,fieldMap);
            if(fieldLabelMap.containsKey(f.APIName)){
                f.Label = fieldLabelMap.get(f.APIName);
            }
            fields.add(f);
        }
        
        return fields;
    }*/
    /*New method to use*/
    public static List<IFv2_FieldWrapperClass> getFields(Sobject record, String objectName, String fieldSetName, String sectionId) {
        Schema.SObjectType objectType = null;
        map<String,String> fieldLabelMap = new map<String,String>();
        for(sObject fieldLabel : [	SELECT Id,Section__c,FieldAPIName__c,FieldLabel__c
                                  FROM IFv2_CustomFieldLabel__mdt 
                                  WHERE Section__c = :sectionId ]){
                                      fieldLabelMap.put(String.valueOf(fieldLabel.get('FieldAPIName__c')),String.valueOf(fieldLabel.get('FieldLabel__c')));							
                                  }
        if (record != null) {
            objectType = ID.valueOf(String.valueOf(record.get('Id'))).getSobjectType();
        }
        else if (String.isNotBlank(objectName)) {
            objectType = Schema.getGlobalDescribe().get(objectName);
        }
        
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        Map<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap();
        Schema.FieldSet fieldSet = fieldSetMap.get(fieldSetName);
        List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
        MAP<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        List<IFv2_FieldWrapperClass> fields = new List<IFv2_FieldWrapperClass>();
        for (Schema.FieldSetMember fsm : fieldSetMembers) {
            IFv2_FieldWrapperClass f = new IFv2_FieldWrapperClass(fsm,objectName,record,fieldMap);
            if(fieldLabelMap.containsKey(f.APIName)){
                f.Label = fieldLabelMap.get(f.APIName);
            }
            fields.add(f);
        }
        
        return fields;
    }
    /* method to get fields from fieldSet name */
    public static List<IFv2_FieldWrapperClass> getFields(Id recordId, String objectName, String fieldSetName) {
        Schema.SObjectType objectType = null;
        if (recordId != null) {
            objectType = recordId.getSobjectType();
        }
        else if (String.isNotBlank(objectName)) {
            objectType = Schema.getGlobalDescribe().get(objectName);
        }
        
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        Map<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap();
        Schema.FieldSet fieldSet = fieldSetMap.get(fieldSetName);
        List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
        MAP<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        List<IFv2_FieldWrapperClass> fields = new List<IFv2_FieldWrapperClass>();
        for (Schema.FieldSetMember fsm : fieldSetMembers) {
            IFv2_FieldWrapperClass f = new IFv2_FieldWrapperClass(fsm,objectName,null,fieldMap); 
            fields.add(f);
        }
        
        return fields;
    }
    /* method to get fields taking list of field api names as param*/
    public static List<IFv2_FieldWrapperClass> getFieldFromAPINames(string recordId, String objectName, String fieldList) {
        List<IFv2_FieldWrapperClass> fields = new List<IFv2_FieldWrapperClass>();
        Schema.SObjectType objectType = null;
        
        if (recordId != null && recordId!='') {
            objectType = Id.valueOf(recordId).getSobjectType();
        }
        else if (String.isNotBlank(objectName)) {
            objectType = Schema.getGlobalDescribe().get(objectName);
        }
        
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        Map<String,Schema.SObjectField > fieldMap = objectDescribe.fields.getMap();
        system.debug('fieldMap:'+fieldMap);
        system.debug('fieldList:'+fieldList);
        for(String field:fieldList.split(',')){
            system.debug('field:'+field);
            IFv2_FieldWrapperClass f = new IFv2_FieldWrapperClass();
            if(fieldMap.containsKey(field)){
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(field).getDescribe();
                
                f.Label = fieldDescribe.getLabel();
                f.APIName = fieldDescribe.getName();
                f.Type = String.valueOf(fieldDescribe.getType());
                f.HelpText = fieldDescribe.getInlineHelpText();
                fields.add(f);
            }
        }
        system.debug('fields:'+fields);
        return fields;
    }
    
    @AuraEnabled
    public static List<IFv2_FieldWrapperClass> getRequiredFields(String objectName, String RequestType) {
        Schema.SObjectType objectType = null;
        
        List<IFv2_FieldWrapperClass> fields = new List<IFv2_FieldWrapperClass>();
        objectType = Schema.getGlobalDescribe().get(objectName);
        list<IFv2_Section__mdt> Fieldsetlist=[select value__c from IFv2_Section__mdt where Workflows__r.name__c=:RequestType and Type__c='Request details']; 
        map<String,String> fieldLabelMap = new map<String,String>();
        for(sObject fieldLabel : [	SELECT Id,Section__c,FieldAPIName__c,FieldLabel__c
                                  FROM IFv2_CustomFieldLabel__mdt 
                                  WHERE Section__c IN :Fieldsetlist ]){
                                      fieldLabelMap.put(String.valueOf(fieldLabel.get('FieldAPIName__c')),String.valueOf(fieldLabel.get('FieldLabel__c')));							
                                  }
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        Map<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap();
        MAP<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        for(IFv2_Section__mdt FieldsetRecord:Fieldsetlist){
            Schema.FieldSet fieldSet = fieldSetMap.get(FieldsetRecord.Value__c.toLowercase());
            List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
            for (Schema.FieldSetMember fsm : fieldSetMembers) {
                IFv2_FieldWrapperClass f = new IFv2_FieldWrapperClass(fsm,objectName,null,fieldMap);
                if(fieldLabelMap.containsKey(f.APIName)){
                    f.Label = fieldLabelMap.get(f.APIName);
                }
                fields.add(f);
            }    
        }
        return fields;
    }
    /* query */
    public static list<Sobject> recordQuery(String query){
        system.debug('query'+ query);
        list<Sobject> queryData = new list<Sobject>();
        try {
            queryData = Database.query(query);
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);    
        }
        system.debug('queryData:'+queryData);
        return queryData;
    }
    
    public class FieldSetForm {
        /*  @AuraEnabled
public List<IFv2_FieldWrapperClass> Fields { get; set; }

public FieldSetForm() {
Fields = new List<IFv2_FieldWrapperClass>();
}*/
    }
}