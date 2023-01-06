/*******************************************************************************************************
* 
* @ Name		:  IFv2_GeneralHomeControllerTest
* @ Purpose		:  Test class for IFv2_GeneralHomeController
* @ Author		:  Prasad Vivek
* @ Class  		:  IFv2_GeneralHomeController
*
*   Date            |  Developer Name               	|  Version      |  Changes
* ======================================================================================================
*   22-06-2019      |  vivek.kothalanka@absyz.com    	|  1.0          |  Added favorite logic.

*******************************************************************************************************/
@isTest
public class IFv2_GeneralHomeControllerTest {
    
    public static TestMethod void  getHomeScreenTabsTest(){
        LIST<SObject> sbojectLIST = new LIST<SObject>();
        LIST<IFv2_HomeScreenTab__c> customsettingLIST = new LIST<IFv2_HomeScreenTab__c>();
        customsettingLIST = IFv2_testDataUtility.createHomeScreenCustomSettings();
        
        insert customsettingLIST;
        
        LIST<IFv2_AdminOnly__c> adminOnlyLIST = new LIST<IFv2_AdminOnly__c>();
        
        String favoriteRecordTypeId = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('Favorite').getRecordTypeId();
        
        adminOnlyLIST = IFv2_testDataUtility.adminOnlyRecords();
        system.assertEquals(true, adminOnlyLIST.size()>0);
        
        for(IFv2_AdminOnly__c adminonly : adminOnlyLIST) {
            
            adminonly.RecordTypeId = favoriteRecordTypeId;
            adminonly.User__c = userInfo.getUserId();
        }
        insert adminOnlyLIST;
        
        sbojectLIST = IFv2_GeneralHomeController.getHomeScreenTabs();
    }
    public static TestMethod void updateFavoriteTest(){
        
        LIST<IFv2_HomeScreenTab__c> customsettingLIST = new LIST<IFv2_HomeScreenTab__c>();
        customsettingLIST = IFv2_testDataUtility.createHomeScreenCustomSettings();
        
        insert customsettingLIST;
        
        LIST<IFv2_AdminOnly__c> adminOnlyLIST = new LIST<IFv2_AdminOnly__c>();
        
        String favoriteRecordTypeId = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('Favorite').getRecordTypeId();
        
        adminOnlyLIST = IFv2_testDataUtility.adminOnlyRecords();
         system.assertEquals(true, adminOnlyLIST.size()>0);
        
        for(IFv2_AdminOnly__c adminonly : adminOnlyLIST) {
            
            adminonly.RecordTypeId = favoriteRecordTypeId;
            adminonly.HomeScreenCustomSettingId__c = customsettingLIST[0].Id;
            adminonly.User__c = userInfo.getUserId();
        }
        insert adminOnlyLIST;
        
        IFv2_GeneralHomeController.updateFavorite(customsettingLIST[0].Id,true);
    }
    
    public static TestMethod void updateFavoriteTestTwo(){
        
        LIST<IFv2_HomeScreenTab__c> customsettingLIST = new LIST<IFv2_HomeScreenTab__c>();
        customsettingLIST = IFv2_testDataUtility.createHomeScreenCustomSettings();
        
        insert customsettingLIST;
        
        LIST<IFv2_AdminOnly__c> adminOnlyLIST = new LIST<IFv2_AdminOnly__c>();
        String favoriteRecordTypeId = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('Favorite').getRecordTypeId();
        
        adminOnlyLIST = IFv2_testDataUtility.adminOnlyRecords();
         system.assertEquals(true, adminOnlyLIST.size()>0);
        
        for(IFv2_AdminOnly__c adminonly : adminOnlyLIST) {
            
            adminonly.RecordTypeId = favoriteRecordTypeId;
        }
        insert adminOnlyLIST;
        
        IFv2_GeneralHomeController.updateFavorite(customsettingLIST[0].Id,true);
    }
    
}