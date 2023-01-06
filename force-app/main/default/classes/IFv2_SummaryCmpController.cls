/*******************************************************************************************************
* 
* @ Name			:  IFv2_SummaryCmpController
* @ Purpose			:  Server side controller for IFv2_SummaryCmp
* @ Author			:  Anoop Ravindran
* @ Test class name :  IFv2_SummaryCmpControllerTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   04-04-2019      |  anoop.ravindran@absyz.com    |  1.0          |  Initial Version

*******************************************************************************************************/

public without sharing class IFv2_SummaryCmpController {
    
    /*Method to return the request list, workflow name and workflow description if the logged in user is an approver */
    @AuraEnabled
    public static SummaryData fetchRelatedRequests(String recId, String status) {
        
        SummaryData data= new SummaryData();						// Initilizing SummaryData class
        LIST<String> statusLIST = new LIST<String>();				//for storing list of statuses received from component
        
        /* Checking if status is not empty or blank */
        if(status != null && status != '') {
            statusLIST=status.split(',');
        }
        System.debug('statuslist>'+statusLIST);
        /* Calling checkUserIsApprover method with recId as parameter */
        data.isApprover = checkUserIsApprover(recId);
        
        /* Checking if isApprover is true */
        if(data.isApprover) {
            
            /* Query for request record wher id of the record matches */
            LIST<IFv2_Request__c> currentReq = new LIST<IFv2_Request__c>();
            if(!String.isBlank(recId)){
                currentReq = [SELECT Id, Scan__c,Workflow__c FROM IFv2_Request__c where Id = :recId];
            }
            /* Checking if currentReq is not empty */
            if(!currentReq.isEmpty()) {
                /* assigning workflowName with  workflow value */
                data.workflowName = currentReq[0].Workflow__c;
                
                /* Query for workflow records with request id*/
                LIST<IFv2_Workflow__c> workflow = new LIST<IFv2_Workflow__c>();
                if(currentReq[0].Workflow__c != null){
                    workflow = [SELECT Id,Name,Description__c FROM IFv2_Workflow__c WHERE Workflow__c = :currentReq[0].Workflow__c LIMIT 1];
                }
                /* Checking if workflow list is not empty */
                if(!workflow.isEmpty()) {
                    
                    /* Checking description is not null */
                    if(workflow[0].Description__c != null) {
                        data.workflowDesc = workflow[0].Description__c;
                    }
                }
                
                String scanId = currentReq[0].Scan__c;
                
                /* Checking if scanId is not null */
                if(scanId != null) {
                    
                    LIST<IFv2_Request__c> relReqs;    // creating a list variable
                    
                    /* chcking if statusLIST is not empty */
                    if(statusLIST.isEmpty()) {
                        /* Query for request record */
                        relReqs = [SELECT Id, Name, Status__c FROM IFv2_Request__c WHERE Scan__c = :scanId AND Id != :recId];
                        data.allScanRequestCount=relReqs.size();
                        System.debug('all rec count>>'+data.allScanRequestCount);
                    } else {
                        /* Query for request record where status in  statusLIST*/
                        User userRecord = IFv2_UtilsController.getLoggedInDetails();
                        List<IFv2_Request__c>allReqs = [SELECT Id, Name, Status__c FROM IFv2_Request__c WHERE Scan__c = :scanId AND Id != :recId AND Status__c IN :statusLIST];
                      //  relReqs = [SELECT Id, Name, Status__c FROM IFv2_Request__c WHERE Scan__c = :scanId AND Id != :recId AND Status__c IN :statusLIST];
                        data.allScanRequestCount=[SELECT COUNT() FROM IFv2_Request__c WHERE Scan__c = :scanId];
                        data.scanAllPendingCount=[SELECT COUNT() FROM IFv2_Request__c WHERE Scan__c = :scanId AND Status__c IN :statusLIST];
                      //  data.scanOtherPendingUserCount=[SELECT COUNT() FROM IFv2_Request__c WHERE Scan__c = :scanId AND Id != :recId AND Status__c IN :statusLIST AND Approver1__c!=:userRecord.id];
                       // data.scanOtherPendingReqList=[SELECT Id, Name, Status__c FROM IFv2_Request__c WHERE Scan__c = :scanId AND Id != :recId AND Status__c IN :statusLIST AND Approver1__c!=:userRecord.id];
                        
                        
                        //// check ////
                        List<id>requestIds=new List<id>();
                        for(IFv2_Request__c req:allReqs)
                            requestIds.add(req.id);
                        // find request pending for current user
                        List<ProcessInstanceWorkitem>recordsPendingUser = [SELECT Id, Actor.Name, ActorId, originalActorId, ProcessInstance.TargetObjectId, ProcessInstance.Status 
                          FROM ProcessInstanceWorkitem 
                          WHERE ProcessInstance.TargetObjectId IN: requestIds 
                          AND ActorId=:userRecord.id
                          AND ProcessInstance.Status = 'Pending'];
                        System.debug('recordsPendingUser>>'+recordsPendingUser);
                        List<id>PendingCurrentId=new List<id>();
                        for(ProcessInstanceWorkitem item:recordsPendingUser)
                            PendingCurrentId.add(item.ProcessInstance.TargetObjectId);
                        relReqs=[SELECT Id, Name, Status__c FROM IFv2_Request__c WHERE Scan__c = :scanId AND id IN:PendingCurrentId];

                       
                        //find request pending for other user //
                         List<ProcessInstanceWorkitem>recordsPendingOtherUser = [SELECT Id, Actor.Name, ActorId, originalActorId, ProcessInstance.TargetObjectId, ProcessInstance.Status 
                          FROM ProcessInstanceWorkitem 
                          WHERE ProcessInstance.TargetObjectId IN: requestIds 
                          AND ActorId!=:userRecord.id
                          AND ProcessInstance.Status = 'Pending'];
                         System.debug('recordsPendingOtherUser>>'+recordsPendingOtherUser);
               
                        List<id>PendingOtherId=new List<id>();
                        for(ProcessInstanceWorkitem item:recordsPendingOtherUser)
                            PendingOtherId.add(item.ProcessInstance.TargetObjectId);
                        data.scanOtherPendingReqList=[SELECT Id, Name, Status__c FROM IFv2_Request__c WHERE Scan__c = :scanId AND id in:PendingOtherId];
						data.scanOtherPendingUserCount=data.scanOtherPendingReqList.size();
                        System.debug('all rec pending records>>'+(data.scanOtherPendingReqList.size()+1));
                    }
                    System.debug('Related Requests>>'+relReqs);
                    data.reqList = relReqs;
                }
            }
        }
        return data;
    }
    /*Generic method to check whether the logged in user is an Approver of the current record */
    public static Boolean checkUserIsApprover(String requestId) {
        
        /* Declaring a boolean variable */
        Boolean isApprover = false;
                
         LIST<ProcessInstanceWorkitem> approvalItem = IFv2_UtilsController.getRecordAcccess(requestId);    // Query for ProcessInstanceWorkitem records which matches requst id 
        SET<Id> approverSET = new SET<Id>(); 	// Set to add approvers 
        /* Checking if approvalItem is not empty */
        if(!approvalItem.isEmpty()) {
            
            /* Iterating over approvalItem list */
            for(ProcessInstanceWorkitem item : approvalItem) {
                approverSET.add(item.ActorId);
            }
        }
        /* Query for user records */
        for(User usr:[SELECT Id,DelegatedApproverId FROM User where Id IN :approverSET]) {
            
            /* Checking if DelegatedApproverId is not null */
            if(usr.DelegatedApproverId!=null) {
                approverSET.add(usr.DelegatedApproverId);
            }
        }
        /*/// Added for testing by renju /////
        User userRecord = IFv2_UtilsController.getLoggedInDetails();
        System.debug('user details>>'+userRecord.Profile.Name);
        if(userRecord.Profile.Name=='System Administrator')
        {
            isApprover = true;
        } 
        /////////////////////////////// */
        /* Checking if approverSET contains logged in userId */
        if(approverSET.contains(Userinfo.getUserId())) {
            isApprover = true;
        }
        
        return isApprover;
    }
    
    /* Creating a wrapper class */
    public class SummaryData {
        
        /* Initializing constructor  */
        public SummaryData(){
            reqList = new LIST<IFv2_Request__c>();
        }
        
        /* Variable to store count of Total wokflows triggered for scan record */
        @AuraEnabled
        public integer allScanRequestCount;
        
        /* Variable to store count of pending approval of other users for scan record */
        @AuraEnabled
        public integer scanOtherPendingUserCount;
        
        /* Variable to store request records */
        @AuraEnabled
        public LIST<IFv2_Request__c> scanOtherPendingReqList;
        
        /* Variable to store count of pending approval of all users for scan record */
        @AuraEnabled
        public integer scanAllPendingCount;
		           
        /* Variable to store request records */
        @AuraEnabled
        public LIST<IFv2_Request__c> reqList;
        
        /* variable to store workflow name */
        @AuraEnabled
        public String workflowName;
        
        /* variable to store workflow description */
        @AuraEnabled
        public String workflowDesc;
        
        /* variable to store boolean variable for approver */
        @AuraEnabled
        public Boolean isApprover;
    }
}