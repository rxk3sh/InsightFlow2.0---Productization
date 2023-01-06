/*******************************************************************************************************
* 
* @ Name		:  IFv2_GeneralHomeController
* @ Purpose		:  Server side controller for IFv2_GeneralHomeComponent
* @ Author		:  Anoop Ravindran
* @ Test Class  :  IFv2_GeneralHomeControllerTest
*
*   Date            |  Developer Name               	|  Version      |  Changes
* ======================================================================================================
*   05-06-2019      |  anoop.ravindran@absyz.com    	|  1.0          |  Initial Version
*   22-06-2019      |  vivek.kothalanka@absyz.com    	|  1.0          |  Added favorite logic.

*******************************************************************************************************/
public with sharing class IFv2_GeneralHomeController {
    /*Method to retrive all Home Sceren Tab Custom Setting Records*/
    @AuraEnabled(cacheable=true)
    public static list<SObject> getHomeScreenTabs(){
        
        LIST<IFv2_HomeScreenTab__c> homeScreenTabs = new LIST<IFv2_HomeScreenTab__c>();
        LIST<IFv2_HomeScreenTab__c> homeScreenTabsAll = new LIST<IFv2_HomeScreenTab__c>();
                
        homeScreenTabsAll = [  SELECT Id,Name__c,IsActive__c,Link__c,ImageName__c,AppOldName__c,Description__c,Starred__c,Country__c
                          FROM IFv2_HomeScreenTab__c
                          WHERE IsActive__c = TRUE
                          ORDER BY Sequence__c ASC NULLS LAST];
        system.debug('homeScreenTabs-->'+homeScreenTabs);
        User userRecord = IFv2_UtilsController.getLoggedInDetails();
        System.debug('Label.CLIFv20309>'+Label.CLIFv20319+'>>getLoggedInDetails>>'+userRecord);
        for(IFv2_HomeScreenTab__c homeScreenRecord:homeScreenTabsAll)
        {
            List<String> countrylist=new List<String>();
            if(homeScreenRecord.Country__c!=null || String.isNotBlank(homeScreenRecord.Country__c))
            {
                System.debug('entering if case>>'+countrylist);
                countrylist=homeScreenRecord.Country__c.split(',');
                System.debug('countrylist>>'+countrylist);
            }
            if(countrylist.contains(userRecord.Country) || countrylist.contains(Label.CLIFv20319))
            {
                homeScreenTabs.add(homeScreenRecord);
                System.debug('tabs>>'+homeScreenTabs);
            }
                      
        }
        
        SET<String> imageNamesSET = new SET<String>();
        for(IFv2_HomeScreenTab__c tab:homeScreenTabs){
            imageNamesSET.add(tab.ImageName__c);
        }
        Set<String> validStaticResourcesSET = new SET<String>();
        for(StaticResource resource:[SELECT Id,Name FROM StaticResource WHERE Name IN :imageNamesSET]){
            validStaticResourcesSET.add(resource.Name);
        }                    
        for(IFv2_HomeScreenTab__c tab:homeScreenTabs){
            String imageName = Label.CLIFv20241;
            if(tab.ImageName__c!=null && validStaticResourcesSET.contains(tab.ImageName__c)){
                imageName = tab.ImageName__c;
            }
            tab.ImageName__c = PageReference.forResource(imageName).getUrl();
        }  
        
        LIST<IFv2_AdminOnly__c> adminOnlyLIST = new LIST<IFv2_AdminOnly__c>();
        
        
        Id devRecordTypeId = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('Favorite').getRecordTypeId();
        
        adminOnlyLIST = [SELECT Id,User__c,HomeScreenCustomSettingId__c,Active__c,recordTypeId 
                         FROM IFv2_AdminOnly__c
                         WHERE User__c =: userRecord.Id AND  recordTypeId =:devRecordTypeId]; 
        
        LIST<Id> favoriteTabLIST = new LIST<Id>();
        LIST<Id> nonFavoriteTabLIST = new LIST<Id>();
        
        system.debug('adminOnlyLIST'+adminOnlyLIST);
        
        for(IFv2_AdminOnly__c adminRecords : adminOnlyLIST) {
            if(adminRecords.Active__c){
                favoriteTabLIST.add(adminRecords.HomeScreenCustomSettingId__c);
            } 
        }
        system.debug('favoriteTabLIST.size:'+favoriteTabLIST.size());
        system.debug('favoriteTabLIST:'+favoriteTabLIST);
        for(IFv2_HomeScreenTab__c hometabs : homeScreenTabs){
            
            if(favoriteTabLIST.contains(hometabs.Id)) {
                hometabs.Starred__c = true;
            } else {
                hometabs.Starred__c = false;
            }
        }
        return homeScreenTabs;
       
    }
    
    
    @AuraEnabled
    Public static void updateFavorite(String CustomSettingId, Boolean isFavorite) { 
        
       
        
        User userRecord = IFv2_UtilsController.getLoggedInDetails();
        LIST<IFv2_AdminOnly__c> adminOnlyLIST = new LIST<IFv2_AdminOnly__c>();
        LIST<IFv2_AdminOnly__c> adminOnlyUpdateLIST = new LIST<IFv2_AdminOnly__c>();
        LIST<IFv2_AdminOnly__c> adminOnlyDeleteLIST = new LIST<IFv2_AdminOnly__c>();
        
        Id devRecordTypeId = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('Favorite').getRecordTypeId();
        
        adminOnlyLIST = [SELECT Id,User__c,HomeScreenCustomSettingId__c,Active__c,recordTypeId 
                         FROM IFv2_AdminOnly__c
                         WHERE User__c =: userRecord.Id AND HomeScreenCustomSettingId__c =: CustomSettingId AND  recordTypeId =:devRecordTypeId limit 1];
        
        system.debug('adminOnlyLIST'+adminOnlyLIST);
        
        if(adminOnlyLIST.isEmpty()){
            IFv2_AdminOnly__c adminRecord = new IFv2_AdminOnly__c();
            adminRecord.User__c = userRecord.Id;
            adminRecord.HomeScreenCustomSettingId__c = CustomSettingId;
            adminRecord.RecordTypeId = devRecordTypeId;
            adminRecord.Active__c = isFavorite;
            adminOnlyUpdateLIST.add(adminRecord);
        } else {
            IFv2_AdminOnly__c adminRecord  = new IFv2_AdminOnly__c();
            adminRecord.id = adminOnlyLIST[0].Id;
            adminOnlyDeleteLIST.add(adminRecord);
        }
        system.debug('admin only List'+adminOnlyUpdateLIST);
        if(!adminOnlyUpdateLIST.isEmpty()) {
            IFv2_DmlController.GenericListDMLOperation(adminOnlyUpdateLIST,'upsert');
        }
        if(!adminOnlyDeleteLIST.isEmpty()){
             IFv2_DmlController.GenericListDMLOperation(adminOnlyDeleteLIST,'delete');
        }
        
    }
}