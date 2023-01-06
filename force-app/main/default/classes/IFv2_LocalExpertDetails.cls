/*******************************************************************************************************
* 
* @ Name    :   IFv2_LocalExpertDetails
* @ Purpose :   To get local expert details from Request.
* @ Author  :   external.debasmita.rawooth@seg-automotive.com
* @ TestClass : IFv2_LocalExpertDetailsTest
*
*   Date        |  Developer Name                      					|  Version       |  Changes
* ======================================================================================================
*   04-10-2019  |  external.debasmita.rawooth@seg-automotive.com        |  	1.0			 | Initial Version
*******************************************************************************************************/
public with sharing class IFv2_LocalExpertDetails {
     @AuraEnabled(cacheable=true)
    public static List<User> getLocalExpertDetails(string recordId) {
        system.debug('request'+recordId);
        IFv2_Request__c request =  [Select Id,Name,Local_Expert_Id__c from IFv2_Request__c where id =: recordId];
        string local=request.Local_Expert_Id__c;
        local = local.replaceAll('/','');
        system.debug('local====='+local);
        List<User> u = [Select Id,Name,Email from User where Id=:local];
        return u;
        
    //return [Select Id,Name,Local_Expert_Id__c from IFv2_Request__c where id =: recordId];

    }
}