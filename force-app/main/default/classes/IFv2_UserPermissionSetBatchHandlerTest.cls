/*******************************************************************************************************
* 

* @ Class Name 		: IFv2_UserPermissionSetAssignmentBatch
* @ Purpose 		: Test class for Batch Class for assigning permission set to SG Standard Users based on User Country in InsightFlow 2.0
* @ Author 			: Madhuravani B
* @ Test Class Name : IFv2_UserPermissionSetAssignmentBatchTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   28-11-2018      |  madhuravani.b@absyz.com      |  1.0          |  Initial Version
*******************************************************************************************************/
@isTest
public class IFv2_UserPermissionSetBatchHandlerTest {
    public static user objUser;
    @testsetup static void createTestData() {
        
        PermissionSet ps = [SELECT ID From PermissionSet WHERE Name = 'IFv2_Extension2'];
        
        //inserting User
        objUser = IFv2_testDataUtility.createSGStandardUser();
        objUser.LastName = 'permissionsetUser';
        objUser.Email = 'sgtestuser123@test.com';
        objUser.Username = 'veernedra123atestuser@test.com';
        objUser.Country = 'Germany';
        objUser.IFv2_RequestAPAC__c = true;
        insert objUser;
               
    }
    
    static testMethod void UserPermission(){ 
        
        objUser = [SELECT Id,Name,Country,LastName 
                   FROM User  
                   WHERE Username = 'veernedra123atestuser@test.com' limit 1];
        user obj = IFv2_testDataUtility.createUser();
        
        LIST<PermissionSetAssignment> TestAssignement = new LIST<PermissionSetAssignment>();
        TestAssignement = [SELECT id 
                           FROM PermissionSetAssignment limit 1];
        
        system.assertEquals(1, TestAssignement.size());
        list<sObject> lstuser = new list<sObject>();
        lstuser.add(objUser);
        system.assertEquals('permissionsetUser', objUser.LastName);
        test.startTest();
        system.runAs(obj){
            IFv2_UserPermissionSetAssignmentBatch objBatch = new IFv2_UserPermissionSetAssignmentBatch();
        	database.executeBatch(objBatch,200);
        }
        test.stopTest();
    }
    
}