/*******************************************************************************************************
* 
* @ Name :IFv2_OutOfOfficeBatch
* @ Purpose : Class that collectss  users who are out of office assigns their requests to delegated approvers
* @ Author: Hanu Sanampudi
* @ Test Class Name : IFv2_BackToOfficeOutOfOfficeBatchV2test
*
*   Date        |  Developer Name                       |  Version      |  Changes
* ======================================================================================================
*   10-09-2019  |  hanumantharao.sanampudi@seg-automotive.com     |  1.0          |  Initial Version

*******************************************************************************************************/

global class IFv2_OutOfOfficeBatch implements Database.Batchable<sObject> {
    
    //Global Variables
    SET<Id> outOfOfficeUserIdSet = new SET<Id>(); 
    String outOfofficeLogsRecordtypeId = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('OutOfOfficeLogs').getRecordTypeId(); 
    
    //Querying users who should be considered in reassignment and delegate assignment of approval requests
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String strQuery = '';
        if(Test.isRunningTest()){
        	strQuery ='SELECT Id,Out_Of_Office__c from user where Out_Of_Office__c=true and ConsiderInReassignmentBatch__c=false and isActive=true limit 1';
        } else {
          strQuery ='SELECT Id,Out_Of_Office__c from user where Out_Of_Office__c=true and ConsiderInReassignmentBatch__c=false and isActive=true';  
        }
         
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.BatchableContext BC, LIST<User> usersList) {        
        if(!usersList.isEmpty()) {
			
			System.debug('Debug:: usersList*****' + usersList);

            MAP<String,String> delegatedIdworkflownameMap = new MAP<String,String>();
            List<IFv2_AdminOnly__c> adminonlyRecords = new List<IFv2_AdminOnly__c>();
            
			if(Test.isRunningTest()) {
                
                adminonlyRecords = [SELECT WorkflowName__c,User__c,createdbyid,Active__c From IFv2_AdminOnly__c Where recordtypeId=:outOfofficeLogsRecordtypeId ];
            } else {
                adminonlyRecords = [SELECT WorkflowName__c,User__c,createdbyid,Active__c From IFv2_AdminOnly__c 
									Where recordtypeId=:outOfofficeLogsRecordtypeId AND WorkflowName__c!=Null 
									AND User__c!=Null AND Active__c=true AND createdbyId IN : usersList];
            }
			            
            if(!adminonlyRecords.isEmpty()) {
				
				//Iterating and collecting the created by id and delegated id and allso workflow
				for(IFv2_AdminOnly__c admin : adminonlyRecords) {
					//Collecting out of office userids
					if(admin.Active__c) {
                        System.debug('Debug:: usersList**Proxy Name***' + admin.User__c);
						outOfOfficeUserIdSet.add(admin.CreatedById);
						delegatedIdworkflownameMap.put(admin.WorkflowName__c, admin.User__c);
					} 
				}
			}
            
            //check for the Proxy user out office is already enabled or not
            List<User>noOutofficeUsersList = [SELECT Id,Out_Of_Office__c from user where Id IN:delegatedIdworkflownameMap.values() 
                                              AND Out_Of_Office__c = false];
            
			 MAP<String,String> proxyWorkflowUserMap = new MAP<String,String>();
             Set<Id> proxyIdSet = new Set<Id>();
             Set<Id> OutOfOfficeProxyIdSet = new Set<Id>();
            
            //add the proxy users to map
            if(!noOutofficeUsersList.isEmpty()) {
                System.debug('Debug:: noOutofficeUsersList*****' + noOutofficeUsersList);
                for(User usrObj : noOutofficeUsersList) {
                    proxyIdSet.add(usrObj.Id);
                }
            } 

            if(!delegatedIdworkflownameMap.isEmpty()) {
                System.debug('Debug:: proxyIdSet*****' + proxyIdSet);
                for(String workflow : delegatedIdworkflownameMap.keySet()) {
                    String proxyId = (String)delegatedIdworkflownameMap.get(workflow);
                    if(proxyIdSet.contains(proxyId)) {
                        proxyWorkflowUserMap.put(workflow,proxyId);                        
                    } else {
                        OutOfOfficeProxyIdSet.add(proxyId);
                    }
                }
            }
            
            System.debug('Debug:: outOfOfficeUserIdSet*****' + outOfOfficeUserIdSet);
            
			
            //Invoking Out of office
            if(!outOfOfficeUserIdSet.isEmpty() && !proxyWorkflowUserMap.isEmpty()) {
                System.debug('Debug:: proxyWorkflowUserMap*****' + proxyWorkflowUserMap);
                OutOfOfficeAndBackToOfficeHelper.TransferApproverToDelegatedUserv1(outOfOfficeUserIdSet, proxyWorkflowUserMap);                
            }
            
            //Create Unassigned logs for the out of office proxy users.
            if(!outOfOfficeUserIdSet.isEmpty() && !OutOfOfficeProxyIdSet.isEmpty()){
                
                System.debug('Debug:: OutOfOfficeProxyIdSet*****' + OutOfOfficeProxyIdSet);
                OutOfOfficeAndBackToOfficeHelper.createUnAssignedLogs(outOfOfficeUserIdSet,OutOfOfficeProxyIdSet); 
            }
        }
    }
    
    //Finish method
    global void finish(Database.BatchableContext BC) {
        //do nothing
    }
}