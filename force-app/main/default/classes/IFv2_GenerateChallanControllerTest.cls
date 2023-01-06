/*******************************************************************************************************
* 
* @ Name    	:   IFv2_GenerateChallanControllerTest
* @ Purpose 	:   Test class for IFv2_GenerateChallanController
* @ Author  	:   Nagasai
* @ Class Name	:	IFv2_GenerateChallanController
*
*   Date        |  Developer Name                   	|  Version      |  Changes
* ======================================================================================================
*   21-05-2019  |  nagasai.chalamalasetti@absyz.com     |  1.0          |  Initial Version
*
*******************************************************************************************************/
@isTest
public class IFv2_GenerateChallanControllerTest {
    
    
    public static testmethod void getchallanHTML(){
        test.startTest();
        IFv2_Request__c r = new IFv2_Request__c();
        r.Status__c = 'Draft';
        r.Workflow__c = 'Material Gate Pass';
        insert r;
        system.assertEquals('Material Gate Pass',r.Workflow__c);
        PageReference pr = new PageReference('/apex/IFv2_GenerateChallanPage');
        pr.getParameters().put('id', r.Id);
        apexpages.StandardController sc = new ApexPages.StandardController(r);
        //leveragin the printableview controller for the XML purpose, this class returns map of field name and its value
        IFv2_GenerateChallanController v=new IFv2_GenerateChallanController(sc);
        IFv2_GenerateChallanController.requestid = r.id;
        IFv2_GenerateChallanController.getchallanHTML();
        test.stopTest();
    }
}