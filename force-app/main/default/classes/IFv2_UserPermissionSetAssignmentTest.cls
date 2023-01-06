/*******************************************************************************************************
* 
* @ Name 	   :  IFv2_UserPermissionSetAssignmentTest.
* @ Purpose    :  Test class for IFv2_UserPermissionSetAssignment.
* @ Author	   :  Prasad Vivek
* @ Class Name :  IFv2_UserPermissionSetAssignment
*
*   Date	        |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   28-10-2018      |  vivek.kothalanka@absyz.com	|  1.0          |  Initial Version
*******************************************************************************************************/
@isTest
public class IFv2_UserPermissionSetAssignmentTest {
    
    //Method to insert users
    Public static testMethod void AssignPermissisonSetOnInsert(){
        
        User userRecord = IFv2_testDataUtility.createSGStandardUser();
        system.assertEquals( 'SEG', userRecord.CompanyName);
        LIST<User> UserRecords = new LIST<User>();
        insert userRecord;
    }
    //Method to update user
    Public static testMethod void AssignPermissisonSetOnUpdate(){
        
        User userRecord = IFv2_testDataUtility.createSGStandardUser();
        LIST<User> UserRecords = new LIST<User>();
        userRecord.Username = 'testuserabc@abc.com'+DateTime.now().getTime(); 
        insert userRecord;
        //system.assertEquals('testuserabc@abc.com',userRecord.Username);
        userRecord.Country = 'India'; 
        update userRecord;
        system.assertEquals('India',userRecord.Country);
    }
    
    
}