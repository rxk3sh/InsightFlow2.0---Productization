/*******************************************************************************************************
* 
* @ Name        : IFv2_MaterialController
* @ Purpose     : Controller tracking the count of returned materials for MGP India
* @ Author      : Elsa Shaju 
* @Test Class   : IFv2_MaterialControllerTest
*
*   Date            |  Developer Name                      |  Version         |  Changes
* ======================================================================================================
*   06-05-2019      |  elsa.shaju@absyz.com                |  1.0             |  Initial version
*******************************************************************************************************/

global without sharing class IFv2_MaterialController {
    
    public class MaterialWrapper {
        @AuraEnabled public Account material {get;set;}
        @AuraEnabled public Decimal currentQty {get;set;}
        public MaterialWrapper() {}
    }
    
    public class MaterialDisplayWrapper {
        @AuraEnabled public LIST<String> Labels {get;set;}
        @AuraEnabled public LIST<String> APINames {get;set;}
        @AuraEnabled public LIST<MaterialWrapper> materialDetailLIST {get;set;}
        @AuraEnabled public Boolean isParent {get;set;}
        public MaterialDisplayWrapper() {}
    }
    
    /* Retrieving general required details of Request */
    public static LIST<IFv2_Request__c> getBasicRequestDetails(String requestId) {
        LIST<IFv2_Request__c> requests = new LIST<IFv2_Request__c>();
        if(!String.isBlank(requestId)){
            requests = [SELECT Id, Name, Workflow__c FROM IFv2_Request__c WHERE Id = :requestId];
        }
        return requests;
    }
    
    /* Method to get Field Labels and API Names */
    public static LIST<Schema.FieldSetMember> getFieldMetadata(String fieldSetName) {
        LIST<Schema.FieldSetMember> fieldSetMembersLIST = new LIST<Schema.FieldSetMember>();
        if(!String.isBlank(fieldSetName)) {
            MAP<String, Schema.FieldSet> fieldSetMap = Schema.getGlobalDescribe().get('Account').getDescribe().fieldSets.getMap();
            if(fieldSetMap.containsKey(fieldSetName)) {
                fieldSetMembersLIST = fieldSetMap.get(fieldSetName).getFields();
            }
        }
        return fieldSetMembersLIST;
    }
    
    @AuraEnabled
    public static MaterialDisplayWrapper getMaterialDetails(String requestId) {
        MaterialDisplayWrapper displayWrapper = new MaterialDisplayWrapper();
        if(requestId != null) {
            LIST<IFv2_Request__c> requestLIST = getBasicRequestDetails(requestId);
            if(!requestLIST.isEmpty()) {
                String workflow = requestLIST[0].Workflow__c;
                String fieldSetName = '';
                Boolean isParent = false;
                System.debug('workflow: ' + workflow);
                if(workflow == Label.CLIFv20199) {
                    fieldSetName = 'IFv2_MGPMaterial';
                    isParent = true;
                } else if(workflow == Label.CLIFv20200) {
                    fieldSetName = 'IFv2_MGPChildMaterial';
                    isParent = false;
                }
                LIST<Schema.FieldSetMember> fieldSetMembersLIST = getFieldMetadata(fieldSetName);
                LIST<String> labelLIST = new LIST<String>();
                LIST<String> apiLIST = new LIST<String>();
                String fieldAPIs = 'IFv2_Request__c';
                
                if(!fieldSetMembersLIST.isEmpty()) {
                    for(Schema.FieldSetMember fieldSetMember : fieldSetMembersLIST) {
                        labelLIST.add(fieldSetMember.getLabel());
                        apiLIST.add(fieldSetMember.getFieldPath());
                        fieldAPIs += ', ' + fieldSetMember.getFieldPath();
                    }
                }
                LIST<MaterialWrapper> materialLIST = new LIST<MaterialWrapper>();
                LIST<Account> accountLIST = new LIST<Account>();
                accountLIST = IFv2_UtilsController.getMaterialsDetailList(requestId, fieldAPIs);
                for(Account acc : accountLIST) {
                    MaterialWrapper matWrap = new MaterialWrapper();
                    matWrap.material = acc;
                    matWrap.currentQty = 0;
                    materialLIST.add(matWrap);
                }
                displayWrapper.Labels = labelLIST;
                displayWrapper.APINames = apiLIST;
                displayWrapper.materialDetailLIST = materialLIST;
                displayWrapper.isParent = isParent;
            }
        }
        return displayWrapper;
    }
    
    @AuraEnabled
    public static LIST<MaterialWrapper> updateMaterialDetails(String requestId, LIST<MaterialWrapper> materialList) {
        if(requestId != null) {
            LIST<Account> accountLIST = new LIST<Account>();
            for(MaterialWrapper matWrap : materialList) {
                Account materialAccount = matWrap.material;
                if(materialAccount.IFv2_ReturnedQuantity__c != null) {
                    materialAccount.IFv2_ReturnedQuantity__c = materialAccount.IFv2_ReturnedQuantity__c + matWrap.currentQty;
                } else {
                    materialAccount.IFv2_ReturnedQuantity__c = matWrap.currentQty;
                }
                if(materialAccount.IFv2_ReturnedQuantity__c > materialAccount.IFv2_Quantity__c || materialAccount.IFv2_ReturnedQuantity__c < 0 || materialAccount.IFv2_Quantity__c == null) {
                    return null;
                }
                accountLIST.add(materialAccount);
                matWrap.currentQty = 0;
            }
            if(!accountLIST.isEmpty()) {
                IFv2_DmlController.GenericListDMLOperation(accountLIST, 'update');
            }
        }
        return materialList;
    }
}