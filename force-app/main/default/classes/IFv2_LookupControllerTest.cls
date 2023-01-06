/*******************************************************************************************************
* 
* @ Name    :   IFv2_LookupControllerTest
* @ Purpose :   Test class for Lookup
* @ Author  :   Madhura Vani
* @ Class	: 	IFv2_LookupController
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   03-11-2018      |  anoop.ravindran@absyz.com    |  1.0          |  Initial Version
*   21-11-2018      |  madhuravani.b@absyz.com      |  1.0          |  Changed as per the best practices(Added testsetup method, data preparation, catch blocks)
*
*******************************************************************************************************/
@isTest
public class IFv2_LookupControllerTest {
    
    public static Account objAccount;
    public static contact objContact;
    @testsetup static void createTestData() {
        objAccount = IFv2_testDataUtility.createAccount();  //inserting Account
        insert objAccount;
        
        objContact = IFv2_testDataUtility.createContact(objAccount);
        insert objContact;
    }
    
    static testmethod void test_getRecentRecords() {
        String jsonString = '{"searchField":"Name", "object": "Account", "filter": "Name = \'Test Account\'"}';
        
        Test.startTest();
        String responseString = IFv2_LookupController.getRecentRecords(jsonString);
        Test.stopTest();
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        System.assertEquals(true, response.get('isSuccess'));
    }
    
    static testmethod void test_getRecordLabel() {
        objAccount = [select id,name from Account];
        
        String jsonString = '{"searchField":"Name", "object": "Account", "filter": "Name = \'Test Account\'"}';
        Test.startTest();
        String responseString = IFv2_LookupController.getRecordLabel(jsonString);
        Test.stopTest();
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        String objectLabel = String.valueOf(results.get('objectLabel'));
        System.assertEquals(objAccount.name, 'Test Account');
    }
    
    static testmethod  void test_getData() {
        objAccount = [select id,name from Account];
        system.assertEquals(true, objAccount!= NULL);
        
        String jsonString = '{"searchField":"Name", "object": "Account", "filter": "Name = \'Test Account\'", "order": "Name", "limit": "5", "searchTerm": "Test"}';
        
        Test.startTest();
        String responseString = IFv2_LookupController.getRecords(jsonString);
        Test.stopTest();
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        List<Object> data =(List<Object>)results.get('data');
        Map<String, Object> record = (Map<String, Object>)data.get(0);
    }
    
    static testmethod void test_getDataError() {
        
        Test.startTest();
        String jsonString = 'test';
        objAccount = [select id,name from Account];
        system.assertEquals(true, objAccount!= NULL);
        String responseString = IFv2_LookupController.getRecords(jsonString);
        Test.stopTest();
    }
    
    static testMethod void test_getData_subtitleField() {
        objAccount = [select id,name from Account];
        system.assertEquals(true, objAccount!= NULL);
        String jsonString = '{"searchField":"Name", "subtitleField": "Name", "object": "Account", "filter": "Name = \'Test Account\'", "searchTerm": "Test"}';
        
        Test.startTest();
        String responseString = IFv2_LookupController.getRecords(jsonString);
        Test.stopTest();
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        List<Object> data =(List<Object>)results.get('data');
        Map<String, Object> record = (Map<String, Object>)data.get(0);
    }
    
    static testMethod void test_getData_addressField() {
        
        objAccount = [select id,name from Account];
        system.assertEquals(true, objAccount!= NULL);
        String jsonString = '{"searchField":"Name", "subtitleField": "BillingAddress", "object": "Account", "filter": "Name = \'Test Account\'", "searchTerm": "Test"}';
        
        Test.startTest();
        String responseString = IFv2_LookupController.getRecords(jsonString);
        Test.stopTest();
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        List<Object> data =(List<Object>)results.get('data');
        Map<String, Object> record = (Map<String, Object>)data.get(0);
    }
    
    static testMethod void test_getData_reference() {
        objAccount = [select id,name from Account];
        system.assertEquals(true, objAccount!= NULL);
        
        objContact  = [select id,LastName from contact];
        String jsonString = '{"searchField":"FirstName", "subtitleField": "Account.Name", "object": "Contact", "filter": "Name = \'Test Contact\'", "searchTerm": "Test"}';
        
        Test.startTest();
        String responseString = IFv2_LookupController.getRecords(jsonString);
        Test.stopTest();
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        List<Object> data =(List<Object>)results.get('data');
        Map<String, Object> record = (Map<String, Object>)data.get(0);
    }
}