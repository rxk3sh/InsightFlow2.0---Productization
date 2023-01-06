@isTest
public class IFv2_sendNotificationEmail_test {
 static testMethod void createrequest() {
     
     User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
     System.runAs ( thisUser ) {
         EmailTemplate validEmailTemplate = new EmailTemplate();
         validEmailTemplate.isActive = true;
         validEmailTemplate.Name = 'IFv2_emailNotificationOnSAPerror1';
         validEmailTemplate.DeveloperName = 'unique_name_addSomethingSpecialHere';
         validEmailTemplate.TemplateType = 'text';
         validEmailTemplate.FolderId = UserInfo.getUserId();
         
         insert validEmailTemplate;
     }
     
    
     Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
     User u = new user();
        u.alias = 'alias';
        u.LastName = 'lastName';
        u.Username = 'test@testingfsagdgdsbggfbsajkdf.com';
        u.Email = 'test@seg-automotive.com';
        u.TimeZoneSidKey = 'Europe/Berlin';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        u.ProfileId = profileId.Id;
        u.Department = '123';
        insert u;
        Contact contact=new Contact();
        contact.FirstName='test name';
        contact.DCA_NameofSAPSystem__c='SAP test';
        contact.DCA_AuthType__c='Auth test';
        contact.DCA_Authorization__c='Authorization test';
        contact.DCA_AuthorizationDescription__c='test';
        contact.DCA_Function__c='function';
        contact.DCA_BusinessCase__c='case test';
        contact.DCA_User__c=u.id;
        contact.LastName=u.LastName;
        contact.DCA_Risk__c='risk';
        contact.DCA_Role__c='role';
        contact.DCA_RoleDescription__c='dis';
        contact.DCA_LockedBy__c='locked';
        contact.DCA_ValidFrom__c=System.today();
        contact.DCA_ValidTo__c=System.today()+1;
        contact.DCA_Department__c='Department';
        contact.DCA_DepartmentActive__c='Dep';
        contact.DCA_Location__c='Goa';
        contact.DCA_Company__c='SEG';
        contact.DCA_Status__c='Pending';
        contact.email ='test@mlb.com';
        contact.DCA_DisciplinaryManager__c=UserInfo.getUserId();
        contact.CreatedDate=Date.today();
        insert(Contact);
     // Contact testContact = IFv2_sendNotificationEmail_test.createContact();
      EmailTemplate validEmailTemplate2 = createtemplate();
      IFv2_request__c req = new IFv2_request__c();
        req.Workflow__c='Concession';
        req.Status__c = 'Draft';
        
        req.Approver1__c=u.id;
        req.CategoryCodeDescription__c='QS-RM001-0010 Concession inhouse production (product)';
        req.MaterialNo__c='123';
        req.SupplierName__c='123';
        req.Full8Dreportnecessary__c='No';
        req.SAPInstance__c='PSI';
        req.Remarks__c='Remark';
        req.ConcessionDescription__c='concession desc';
        req.ConcessionErrorResponse__c = 'test1';
        insert req;
     req.ConcessionErrorResponse__c = 'test12';
     update req;
 
 }
    
    static testMethod EmailTemplate createtemplate() {
        EmailTemplate validEmailTemplate1 = new EmailTemplate();
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
     System.runAs ( thisUser ) {
         EmailTemplate validEmailTemplate = new EmailTemplate();
         validEmailTemplate.isActive = true;
         validEmailTemplate.Name = 'IFv2_emailNotificationOnSAPerror';
         validEmailTemplate.DeveloperName = 'unique_name_addSomethingSpecialHere1';
         validEmailTemplate.TemplateType = 'text';
         validEmailTemplate.FolderId = UserInfo.getUserId();
         
         insert validEmailTemplate;
         validEmailTemplate1 = validEmailTemplate;
     }
        return validEmailTemplate1;
    }
   public  static testMethod Contact createContact() {
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
     User u = new user();
        u.alias = 'alias';
        u.LastName = 'lastName';
        u.Username = 'test@testing456.com';
        u.Email = 'test@seg-automotive.com';
        u.TimeZoneSidKey = 'Europe/Berlin';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        u.ProfileId = profileId.Id;
        u.Department = '123';
        insert u;
        
        Contact contact=new Contact();
        contact.FirstName='test12 name';
        contact.DCA_NameofSAPSystem__c='SAP test';
        contact.DCA_AuthType__c='Auth test';
        contact.DCA_Authorization__c='Authorization test';
        contact.DCA_AuthorizationDescription__c='test';
        contact.DCA_Function__c='function';
        contact.DCA_BusinessCase__c='case test';
        //contact.DCA_User__c=u.id;
        contact.LastName='DummyContact';
        contact.DCA_Risk__c='risk';
        contact.DCA_Role__c='role';
        contact.DCA_RoleDescription__c='dis';
        contact.DCA_LockedBy__c='locked';
        contact.DCA_ValidFrom__c=System.today();
        contact.DCA_ValidTo__c=System.today()+1;
        contact.DCA_Department__c='Department';
        contact.DCA_DepartmentActive__c='Dep';
        contact.DCA_Location__c='Goa';
        contact.DCA_Company__c='SEG';
        contact.DCA_Status__c='Pending';
        contact.email ='test123@mlb.com';
        contact.DCA_DisciplinaryManager__c=UserInfo.getUserId();
        contact.CreatedDate=Date.today();
        insert(Contact);
        return contact;
        
    }
}