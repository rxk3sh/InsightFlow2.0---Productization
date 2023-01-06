/*******************************************************************************************************
* 
* @ Name    	:   IFv2_P28ControllerTest
* @ Purpose 	:   Test class for IFv2_P28Controller
* @ Author  	:   Naga sai/Vivek
* @ Class Name 	:	IFv2_P28Controller
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   18-03-2019  |  nagasai.chalamalasetti@absyz.com |  1.0          |  Initial Version
*   02-05-2019	|  vivek.kothalanka@absyz.com		|  1.1			|  Updated comma with semicolan
*
*******************************************************************************************************/
@isTest
public class IFv2_P28ControllerTest {
    
    //Method to call getp28 Logs method
    public static testmethod void CreateFileInAdminOnlyObject(){
        string CSVAsString='Personnel number;Salutation;Last Name;First Name;Company;Org. Unit;Employee type;Cost Center;Employee subgroup'+'\r\n'+'71350481;Mr.;PANG;Jingyu;SGCN Changsha;SG/NE-CN;Grade 6 and above Office Staff;000069F250;Z2'+'\r\n'+'85000797;Ms.;GAO;Ruili;SGCN Changshaaa;SG/MOE1-PVSSS2-CN;Leasing;000069F338;ZN';
        IFv2_P28Controller.CreateFileInAdminOnlyObject(CSVAsString,'contacts.csv','Inserting Contacts'); 
        LIST<IFv2_P28Controller.p28Logswrapper> p28LogswrapperLIST = IFv2_P28Controller.getp28Logs(2,0);
        system.assertEquals(1,p28LogswrapperLIST.size());
        system.assertEquals('Pending',p28LogswrapperLIST[0].status);
    }
    //Method to call CreateFileInAdminOnlyObject method
    public static testmethod void CreateFileInAdminOnlyObjectWithFieldMismatch(){
        string CSVAsString='Personnel number;Salutation;Last Name;First Name;Comp;Org. Unit;Employee type;Cost Center;Employee subgroup'+'\r\n'+'71350481;Mr.,PANG;Jingyu;SGCN Changsha;SG/NE-CN;Grade 6 and above Office Staff;000069F250;Z2'+'\r\n'+'85000797;Ms.,GAO;Ruili;SGCN Changshaaa;SG/MOE1-PVSSS2-CN;Leasing;000069F338;ZN';
        IFv2_P28Controller.CreateFileInAdminOnlyObject(CSVAsString,'contacts.csv','Inserting Contacts'); 
        LIST<IFv2_AdminOnly__c> adminOnlyLIST = new LIST<IFv2_AdminOnly__c>();
        adminOnlyLIST = [SELECT Id,Status__c 
                         FROM IFv2_AdminOnly__c LIMIT 1];
        system.assertEquals('Pending',adminOnlyLIST[0].Status__c);
    }
}