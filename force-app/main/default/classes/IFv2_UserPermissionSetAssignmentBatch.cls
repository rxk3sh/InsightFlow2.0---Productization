/*******************************************************************************************************
* 
* @ Name 			: IFv2_UserPermissionSetAssignmentBatch
* @ Purpose 		: Batch Class for assigning permission set to SG Standard Users based on User Country in InsightFlow 2.0
* @ Author 			: Prasad Vivek
* @ Test Class Name : IFv2_UserPermissionSetAssignmentBatchTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   28-11-2018      |  vivek.kothalanka@absyz.com   |  1.0          |  Initial Version
*   23-03-2019      |  vivek.kothalanka@absyz.com   |  2.0          |  Update for Permission set Assignment based on check boxes
*******************************************************************************************************/

Global class IFv2_UserPermissionSetAssignmentBatch implements Database.batchable<Sobject> {
    
    /* Global variables used */
    global integer Totalnumber = 0;
    global integer successnumber = 0;
    public String query;
    
    public IFv2_UserPermissionSetAssignmentBatch() {
        query = 'SELECT Id, Country, Name, IFv2_RequestEMEA__c, IFv2_RequestAPAC__c, IFv2_RequestNALA__c FROM User WHERE Profile.Name = \'SG Standard User\' AND IsActive = true AND Country != null'+(Test.isRunningTest()?' LIMIT 200':'');
    }
    
    global database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, LIST<Sobject> userRecords) {
        
        Totalnumber += userRecords.size();
        /* Calling batch handler */
        
        IFv2_UserPermissionSetBatchHandler.checkPermissionSetAssignment(userRecords);
        successnumber += userRecords.size();
    }
    
    global void finish(Database.BatchableContext bc) {
        /* Quering the AsyncApexJob object */
        AsyncApexJob a = [SELECT Id, Status, JobType, NumberOfErrors, JobItemsProcessed, TotalJobItems, CompletedDate, ExtendedStatus, MethodName
                          FROM AsyncApexJob WHERE Id =:BC.getJobId()];
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> mailToAddresses = new List<String>();	// List to store mail addresses
        Set<id> idList = new Set<id>();						// Set to store ids
        
        /* Query for group object */
        Group g = [SELECT (select userOrGroupId from groupMembers) FROM group WHERE name = 'IFv2_Admins'];
        for (GroupMember gm : g.groupMembers) {
            idList.add(gm.userOrGroupId);
        }
        
        /* Query for user record */
        User[] user = [SELECT email FROM user WHERE id IN :idList];
        for(User u : user) {
            mailToAddresses.add(u.email);
        }
        
        String body='<Html><body>The batch Apex job completed on  ' + a.CompletedDate + ',<br/><br/>' +
            '<b>Job Status : ' + a.Status + '<br/>'+
            '<b>Total Job Items processed : <b>' + Totalnumber + '<br/>'+
            '<b>Number of Job Items processed : <b>' + successnumber + '<br/>' +
            '<b>Number of Failures : <b>'+ (Totalnumber-successnumber) + '<br/>' +
            '<b>Extended Status : <b>'+ a.ExtendedStatus + '</body></Html>';
        
        mail.setToAddresses(mailToAddresses);
        mail.setSubject('Permission Set Assignement Batch ' + a.Status);
        mail.setHtmlBody(body);
        
        if(a.NumberOfErrors != 0) {
            //Insert logs other than standard validation error 
            IFv2_ExceptionUtilitiesController.batchJobError(a);
        }    
    }
}