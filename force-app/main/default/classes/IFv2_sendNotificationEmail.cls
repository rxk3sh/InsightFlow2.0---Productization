/*******************************************************************************************************
* 
* @ Name        : IFv2_sendNotificationEmail
* @ Purpose     : All the generic classes related to email notification goes here 
* @ Author      : Nirmal Christopher
* @ Test Class  : IFv2_IFv2_sendNotificationEmailTest
*
*   Date            |  Developer Name                       |  Version          |  Changes
* ======================================================================================================
*   23-01-2021     |  nirmal.christopher@marlabs.com         |  1.0              |  Initial Version
*   
*******************************************************************************************************/
public class IFv2_sendNotificationEmail{
    
    
    public static void sendConcessionerrorAlert(set<id>userIds,ID rcdId){
        List<id>userList=new List<id>();
        Contact testContact =createContact();
        list<contact> dummycontact = [select id from contact  where email <> null limit 1];
        system.debug('*dummy contact'+dummycontact);
        System.debug('send email userList>'+userList);
        List<string>emailIdSet=new List<string>();
        for(User user:[select id, email from user where id IN: userIds])
        {
            emailIdSet.add(user.email);
        }
        System.debug('send email emailIdSet>'+emailIdSet);
        String emailTemplate = 'IFv2_emailNotificationOnSAPerror';
        /* Query for emial template */
        EmailTemplate emailTemplateRecord = new EmailTemplate();
        if(emailTemplate!=Null)
            emailTemplateRecord = [SELECT Id,Name,Subject, Body,HtmlValue FROM EmailTemplate WHERE DeveloperName = :emailTemplate limit 1];
        LIST<Messaging.SingleEmailMessage> emailList = new LIST<Messaging.SingleEmailMessage>();    // LIST to store email messages 
        if(!emailIdSet.isEmpty()) { 
            System.debug('email not null>>'+emailIdSet);
            String username=UserInfo.getName();
            Ifv2_request__c record=[select name,id from Ifv2_request__c limit 1];
            String recordName=record.name;
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses =new LIST<String>(emailIdSet);
            system.debug('emailIdSet'+emailIdSet);
            message.setTreatTargetObjectAsRecipient(false);
            message.setSaveAsActivity(false);
            //if(dummycontact.size()>0){
            message.setTargetObjectId(testContact.id);
            //}
            //Setting the WhatId to customobject Id so that merge fields in template gets rendered
            //if(dummycontact.size()>0){
            message.setWhatId(rcdId);
            
            // }
            //SET email template
            if(emailTemplateRecord != null) {
                message.setTemplateId(emailTemplateRecord.Id);                
            }
            
            if(message.toAddresses.size()>0) {
                emailList.add(message);
            }
        } 
        system.debug('emailList'+emailList);
        
        Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
        System.debug('email result>'+results);
        delete testContact;
    }
    
    public static Contact createContact() {
        
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