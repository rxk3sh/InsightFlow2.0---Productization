/*******************************************************************************************************
* 
* @ Name    :   IFv2_LocalExpertDetailsTest
* @ Purpose :   Test class for IFv2_LocalExpertDetails.
* @ Author  :   external.debasmita.rawooth@seg-automotive.com
*
*   Date        |  Developer Name                      					|  Version       |  Changes
* ======================================================================================================
*   04-10-2019  |  external.debasmita.rawooth@seg-automotive.com        |  	1.0			 | Initial Version
*******************************************************************************************************/
@isTest(SeeAllData=true)
public class IFv2_LocalExpertDetailsTest {
    
    public static testmethod void testLocalExpert() {
        User user1 = [Select id,name from user Limit 1];
        IFv2_Request__c req = new IFv2_Request__c(); 
        req.Local_Expert_Id__c = user1.Id;
        req.Status__c = 'Draft';
        insert req;
        List<User> getUserList = IFv2_LocalExpertDetails.getLocalExpertDetails(req.Id);
    }
    
}