/*******************************************************************************************************
* 
* @ Name    		: IFv2_HistoricScanRecordsBatch
* @ Purpose 		: Batch Class for populating Barcode, Company Code, DateTime fields on the historic Scan Records
* @ Author  		: Pradeep Chary
* @ Test Class Name : 
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   21-05-2019  |  pradeep.chary@absyz.com				|  1.0          |  Initial Version

*******************************************************************************************************/

global class IFv2_HistoricScanRecordsBatch implements Database.batchable<Sobject> ,Database.Stateful{
	//Variables for displaying information about execution of batch in email
    global integer Totalnumber=0;
    global integer successnumber=0;
    public String query;
    
    public IFv2_HistoricScanRecordsBatch() {
        query = 'SELECT Id, Name, Company_Code__c, Barcode__c,SAP_Response__c,IFv2_SAPStatus__c, IFv2_DateTime__c, CreatedDate '+
            	'FROM Scan__c '+
            	'WHERE Company_Code__c = Null';
        system.debug(query);
    }
    
    global database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
        
    }
    
    global void execute(Database.BatchableContext bc, LIST<Scan__c> scanRecords) {
       
        LIST<Scan__c> scanRecordsToUpdate = new LIST<Scan__c>();
        Totalnumber+=scanRecordsToUpdate.size();
        
        for(Scan__c scanRecord : scanRecords){
            if(String.isBlank(scanRecord.SAP_Response__c) && scanRecord.IFv2_SAPStatus__c == 'Draft') {
                
            } else {
                scanRecordsToUpdate.add(scanRecord);
            }
        }
       IFv2_HistoricScanRecordsBatchHandler.populateScanFields(scanRecordsToUpdate);
        successnumber+=scanRecordsToUpdate.size();
    }
    
    global void finish(Database.BatchableContext bc) {
        AsyncApexJob a = [SELECT Id,Status,JobType,NumberOfErrors,JobItemsProcessed,TotalJobItems,CompletedDate,ExtendedStatus,MethodName
                          FROM AsyncApexJob WHERE Id =:BC.getJobId()];    //Query for getting job status
        
        LIST<String> mailToAddresses = new LIST<String>();    // To addresses
        SET<id> idList = new SET<id>();    // Set of User Ids to which mail should be sent
        LIST<Group> groups = [SELECT (select userOrGroupId from groupMembers) FROM Group WHERE name = 'IFv2_Admins'];    //Query for getting Admin group Id
        if(!groups.isEmpty()){
            Group g =groups[0];
            for (GroupMember gm : g.groupMembers) {
                idList.add(gm.userOrGroupId);
            }
        }
        User[] user = [SELECT email FROM user WHERE id IN :idList];    //Query for list of Admin users 
        for(User u : user) {
            mailToAddresses.add(u.email);
        } 
        /* Added workflow name in Batch finish Email **HOT FIX** */
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String body='<Html><body>The batch Apex job completed on  ' + a.CompletedDate + ',<br/><br/>' +
            '<b>Job Status : </b>' + a.Status + '<br/>'+
            '<b>Total Job Items processed : <b>' + Totalnumber + '<br/>'+
            '<b>Number of Job Items processed : <b>' + successnumber + '<br/>' +
            '<b>Number of Failures : <b>'+ (Totalnumber-successnumber) + '<br/>' +
            '<b>Extended Status : <b>'+ a.ExtendedStatus + '</body></Html>';
        if(!mailToAddresses.isEmpty()){
            mail.setToAddresses(mailToAddresses);
            mail.setSubject('Historic Scan Record Batch ' + a.Status);
            mail.setHtmlBody(body);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        if(a.NumberOfErrors != 0){
            IFv2_ExceptionUtilitiesController.batchJobError(a);
        }
    }
}