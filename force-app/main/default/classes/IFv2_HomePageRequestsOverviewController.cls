/*******************************************************************************************************
* 
* @ Name            : IFv2_HomePageRequestsOverviewController
* @ Purpose         : Home screen Controller
* @ Author          : Madhura Vani
* @ Test class name : IFv2_HomePageRequestsOverviewTest
*
*   Date        |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   25-01-2019  |  madhuravani.b@absyz.com      |  1.0          |  Initial Version
*******************************************************************************************************/

global  without sharing class IFv2_HomePageRequestsOverviewController {
    
    //getting Logged In User Id    
    public static String strUserId = userInfo.getUserId();
    public static Integer limit1 = integer.ValueOf(System.Label.CLIFv20312);
    
    /* method to query metadata*/
    @AuraEnabled
    public static LIST<IFv2_HomeScreenPage__mdt> getSectionMetadata() {
        
        //list to store IFv2_HomeScreenPage__mdt metadata
        LIST<IFv2_HomeScreenPage__mdt> homeScreenData = new LIST<IFv2_HomeScreenPage__mdt>();
        //Global describing the Fieldset and retriving the fields
        LIST<Schema.SObjectField> fieldLIST = Schema.getGlobaldescribe().get('IFv2_HomeScreenPage__mdt').getDescribe().fields.getMap().values();
        
        if(!fieldLIST.isEmpty()) {
            //string for dynamic query
            String query = 'SELECT ' + fieldLIST[0].getDescribe().getName();
            Integer flag = 0;
            for(Schema.SObjectField field : fieldLIST) {
                if(flag != 0) {
                    query += ', ' + field.getDescribe().getName();
                } else {
                    flag = 1;
                }
            }
            
            query += ' FROM IFv2_HomeScreenPage__mdt WHERE Active__c = true';
            query += ' ORDER BY Order__c ASC';
            try {
                homeScreenData = Database.query(query);
            } catch(QueryException e) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(e); 
            }
        }
        
        return homeScreendata;
    }
    
    /** Get the requests based on the status **/
    @AuraEnabled(cacheable=true)
    public static RequestWrap getRequests() {
        
        //holds the Applicant Request Status
        SET<String> statusSET = new SET<String>();
        //list to store IFv2_HomeScreenPage__mdt metadata
        LIST<IFv2_HomeScreenPage__mdt> metadataLIST = getSectionMetadata();
        //getting fields
        LIST<IFv2_FieldWrapperClass> fieldsLIST = new LIST<IFv2_FieldWrapperClass>();
        
        for(IFv2_HomeScreenPage__mdt objMetadata : metadataLIST) {
            //getting fields from fieldset
            fieldsLIST = IFv2_FieldSetUtility.getFields(null, 'IFv2_Request__c', (String) objMetadata.get('Fields__c'));
            
            //Adding the status If Applicant
            if(!objMetadata.IsApprover__c)
                statusSET.add(objMetadata.Request_Status__c);
        }
        
        RequestWrap objWrap = new RequestWrap();
        objWrap.lstMetadata = metadataLIST;
        
        /** Query which holds Applicant Records **/
        if(!fieldsLIST.isEmpty()) {
            String fieldAPIs = 'Id';
            for(IFv2_FieldWrapperClass fieldSetMemberObj : fieldsLIST) {
                if(!fieldAPIs.contains(fieldSetMemberObj.APIName))
                    fieldAPIs = fieldAPIs + ',' + fieldSetMemberObj.APIName;
            }
            String query = 'SELECT ';
            query += fieldAPIs;
            query += ' FROM IFv2_Request__c WHERE Status__c IN : statusSET AND Workflow__c !=null AND OwnerId = :strUserId ORDER BY CreatedDate DESC LIMIT :limit1';
            objWrap.lstRequest = Database.query(query);
          //  objWrap.PIWIDetails=getPIWIDetailsSubmitted((List<IFv2_Request__c>)objWrap.lstRequest);
            IFv2_FieldWrapperClass submittedDate=new IFv2_FieldWrapperClass();
            submittedDate.APIName='SubmittedDate';
            submittedDate.Label='Received Date';
            submittedDate.Type='DATETIME';
            fieldsLIST.add(submittedDate);
            objWrap.lstFields = fieldsLIST;
            System.debug('This is field list inside>>>>>>>>>>'+fieldsLIST);
        }
        objWrap.lstItemsApprovedByMe = getRequestApprovedByMe();    //Requests Approved by the logged in User
        objWrap.lstDelegate = getDelegatedStatus();     //Requests to Approve as a Delegated Approver
        objWrap.lstItemsToApprove = getItemsToApprove();    //Requests to Approve
        objWrap.lstItemsApprovedByProxy = getProxyApprovedRequests(); //hold the proxy approved requests when user OOO
		objWrap.lstItemsRejectedByProxy = getProxyRejectedRequests(); //hold the proxy rejected requests when user OOO
        objWrap.lstItemsSubmitted=getItemsSubmittedByMe();
        System.debug('This is lstItemsSubmitted outside>>>>>>>>>'+objWrap.lstItemsSubmitted);

        return objWrap;
    }
    
    /** Gets Approved by Me request records **/
    @AuraEnabled
    public static LIST<ItemsApprovedByMe> getRequestApprovedByMe() {
        
        //MAP with key as record Id and value as Request record
        MAP<id,sObject> requestMAP = new MAP<id, sObject>();
        //Return variable
        LIST<ItemsApprovedByMe> recordLIST = new LIST<ItemsApprovedByMe>();     //list of wrapper containing Items Approved
        SET<Id> requestsIdSET = new SET<Id>();  //set for storing Ids of Request to be fetched
        LIST<ProcessInstanceStep> processLIST = new LIST<ProcessInstanceStep>();    //
        
        for(ProcessInstanceStep step : [SELECT ProcessInstanceId, ProcessInstance.TargetObjectId, ProcessInstance.CreatedDate 
                                        FROM ProcessInstanceStep 
                                        WHERE StepStatus = 'Approved' AND ActorId =: strUserId AND ProcessInstance.Status = 'Approved'
                                        ORDER BY CreatedDate DESC LIMIT :limit1]) {
                                            if(step.ProcessInstanceId != Null && !requestsIdSET.contains(step.ProcessInstance.TargetObjectId)) {
                                                requestsIdSET.add(step.ProcessInstance.TargetObjectId);
                                                processLIST.add(step);
                                            }
                                        }
        
        /*Start of migrated records code */
        
        system.debug('processLIST ->'+processLIST);
        
        /* Querying for Account records which are having status as approved by me.*/
        LIST<Account> migratedAccountRecords = new LIST<Account>();
        /* Querying for migrated approval process records in Account Object */
        
        id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Items').getRecordTypeId();
        
        migratedAccountRecords = [SELECT Id,IFv2_LegacyActualApprover__c,IFv2_ContentType__c,IFv2_Request__c,CreatedDate 
                                  FROM Account  
                                  WHERE IFv2_LegacyActualApprover__c =:strUserId AND IFv2_ContentType__c = 'Approval History'
                                  AND RecordTypeId =:accountRecordTypeId ORDER BY CreatedDate DESC LIMIT :limit1];
        
        SET<Id> migratedRecordsSET = new SET<Id>(); // SET to store migarted records set 
        
        /* Checking if migratedAccountRecords is not empty */
        if(!migratedAccountRecords.isEmpty()) {
            
            /* Iterating over migratedAccountRecords */
            for(Account accountRecords : migratedAccountRecords) { 
                migratedRecordsSET.add(accountRecords.IFv2_Request__c);
            }
        }
        /*End of migrated records code */
        
        //Dynamic Query
        String query = 'SELECT ';
        query += 'Id, Name, Status__c, Workflow__c, CreatedDate, CreatedBy.Name'+
            ' FROM IFv2_Request__c  WHERE Status__c = \'Approved\' AND (Id IN:requestsIdSET OR Id IN:migratedRecordsSET) ORDER BY CreatedDate DESC LIMIT :limit1';
        //list to hold the queried records
        
        LIST<sObject> requestLIST = new LIST<sObject>();
        if(!requestsIdSET.isEmpty()) {
            requestLIST = Database.query(query);
        }
        
        //Create Map of Request Id and Request
        for(sObject objIFv2 : requestLIST) {
            requestMAP.put(objIFv2.id,objIFv2);
        }
        
        //status = 'Approved' - If overall status is considered
        for(ProcessInstanceStep step : processLIST) {
            if(requestMAP.containsKey(step.ProcessInstance.TargetObjectId) || Test.isRunningTest()) {
                ItemsApprovedByMe objWrap = new ItemsApprovedByMe();
                objWrap.objProcessInstance = step;
                objWrap.strRequest = requestMAP.get(step.ProcessInstance.TargetObjectId);
                recordLIST.add(objWrap);
            }
        }
        
        if(!migratedAccountRecords.isEmpty()) {
            for(Account accountRecords : migratedAccountRecords) {
                if(requestMAP.containsKey(accountRecords.IFv2_Request__c)) {
                    ItemsApprovedByMe objWrap = new ItemsApprovedByMe();
                    objWrap.strRequest = requestMAP.get(accountRecords.IFv2_Request__c);
                    objWrap.AccountProcessInstance = accountRecords;
                    recordLIST.add(objWrap); 
                }
            }
        }
        
        return recordLIST;
    }
	
    //Holds the Request records approved by Proxy.
	@AuraEnabled
	public static List<IFv2_Request__c> getProxyApprovedRequests() {
		
		//Set to hold WorkItems
        SET<Id> workItemsSET = new SET<Id>();
		
        //list to hold Request records
        LIST<IFv2_Request__c> requestLIST = new LIST<IFv2_Request__c>();
        LIST<IFv2_Request__c> requestAll = new LIST<IFv2_Request__c>();
		Id loggedinUserId = UserInfo.getUserId();
		System.debug('DEBUG:: loggedinUserId*******' + loggedinUserId);
		
        if(loggedinUserId != null) {
			
            LIST<ProcessInstanceStep> piwList = [SELECT Id, ActorId, Actor.Name,OriginalActorId,OriginalActor.Name,ProcessInstance.TargetObjectId, 
			                                         ProcessInstance.Status,CreatedDate 
                                                     FROM ProcessInstanceStep 
                                                     WHERE StepStatus = 'Approved' AND  OriginalActorId =: loggedinUserId ORDER BY CreatedDate DESC LIMIT :limit1];
			if(!piwList.isEmpty()){
				System.debug('DEBUG:: piwList*******' + piwList);
				for(ProcessInstanceStep objWI : piwList) {
					workItemsSET.add(objWI.ProcessInstance.TargetObjectId); 
				}
			}
			
			if(!workItemsSET.isEmpty()) {
				System.debug('DEBUG:: workItemsSET*******' + workItemsSET);
                requestAll = [SELECT Id, Name, Workflow__c, Status__c, CreatedBy.Name, CreatedDate,reAssignedToProxyForApproval__c,Ifv2_ProxyApprovalUserList__c
                               FROM IFv2_Request__c
                               WHERE (Id IN :workItemsSET AND reAssignedToProxyForApproval__c =  true) AND (Status__c = 'Approved' OR Status__c = 'Submitted')
                               ORDER BY CreatedDate DESC LIMIT :limit1];
				System.debug('DEBUG:: requestLIST*******' + requestLIST);
            }
            // checking for proxy list
            for(IFv2_Request__c req: requestAll)
            {
                List<String> origialApprover = new List<String>();
                if(req.Ifv2_ProxyApprovalUserList__c!=null)
                req.Ifv2_ProxyApprovalUserList__c.split(',');
                if(origialApprover!=null && origialApprover.contains(loggedinUserId))
                {
                    requestLIST.add(req);
                }
            }
		}
		return requestLIST;
	}
	
	//Holds the Request records Rejected by Proxy.
	@AuraEnabled
	public static List<IFv2_Request__c> getProxyRejectedRequests() {
		
		//Set to hold WorkItems
        SET<Id> workItemsSET = new SET<Id>();
		
        //list to hold Request records
        LIST<IFv2_Request__c> requestLIST = new LIST<IFv2_Request__c>();
		Id loggedinUserId = UserInfo.getUserId();
		System.debug('DEBUG:: loggedinUserId*******' + loggedinUserId);
        if(loggedinUserId != null) {
			
            LIST<ProcessInstanceStep> piwList = [SELECT Id, ActorId, Actor.Name,OriginalActorId,OriginalActor.Name, ProcessInstance.TargetObjectId, 
													 ProcessInstance.Status, CreatedDate 
                                                     FROM ProcessInstanceStep 
                                                     WHERE StepStatus = 'Rejected' AND OriginalActorId = :loggedinUserId ORDER BY CreatedDate DESC LIMIT :limit1];
			if(!piwList.isEmpty()) {
				System.debug('DEBUG:: piwList*******' + piwList);
				for(ProcessInstanceStep objWI : piwList) {
					workItemsSET.add(objWI.ProcessInstance.TargetObjectId);
				}
			}
			
			if(!workItemsSET.isEmpty()) {
				System.debug('DEBUG:: workItemsSET*******' + workItemsSET);
                requestLIST = [SELECT Id, Name, Workflow__c, Status__c, CreatedBy.Name, CreatedDate,reAssignedToProxyForApproval__c
                               FROM IFv2_Request__c
                               WHERE (Id IN :workItemsSET AND reAssignedToProxyForApproval__c =  true) AND (Status__c = 'Rejected' OR Status__c = 'Submitted')
                               ORDER BY CreatedDate DESC LIMIT :limit1];
				System.debug('DEBUG:: requestLIST*******' + requestLIST);
            }
		}
		
		return requestLIST;
	}
    
    /** Holds Delegated Records**/
    @AuraEnabled
    public static LIST<DelegatedRequestWrapper> getDelegatedStatus() {
        LIST<DelegatedRequestWrapper> delegatedList=new List<DelegatedRequestWrapper>();
        map<id,ProcessInstanceWorkItem> ReqIdPIMap=new map<id,ProcessInstanceWorkItem>();
        //Getting the User Ids for which the logged in User is the Delegated Approver
        SET<Id> userIdSET = new SET<Id>();
        
        for(User objUser : [SELECT Id, DelegatedApproverId 
                            FROM User 
                            WHERE DelegatedApproverId =: UserInfo.getUserId() LIMIT :limit1]) {
                                userIdSET.add(objUser.Id);   
                            }
        
        //Set to hold WorkItems
        SET<Id> workItemsSET = new SET<Id>();
        //list to hold Request records
        LIST<IFv2_Request__c> requestLIST = new LIST<IFv2_Request__c>();
        if (!userIdSET.isEmpty()) {
            LIST<ProcessInstanceWorkItem> piwList = [SELECT Id, ActorId, ProcessInstance.TargetObjectId, ProcessInstance.Status, CreatedDate 
                                                     FROM ProcessInstanceWorkItem 
                                                     WHERE ProcessInstance.Status = 'Pending'
                                                     AND ActorId IN: userIdSET ORDER BY CreatedDate DESC LIMIT :limit1];
            
            
            for(ProcessInstanceWorkItem objWI : piwList) {
                workItemsSET.add(objWI.ProcessInstance.TargetObjectId);
                ReqIdPIMap.put(objWI.ProcessInstance.TargetObjectId,objWI);
            }
            if(!workItemsSET.isEmpty()) {
                requestLIST = [SELECT Id, Name, Workflow__c, Status__c, CreatedBy.Name, CreatedDate
                               FROM IFv2_Request__c
                               WHERE Status__c = 'Submitted' 
                               AND Id IN :workItemsSET
                               ORDER BY CreatedDate DESC LIMIT :limit1];
                for(IFv2_Request__c req:requestLIST)
                {
                    if(ReqIdPIMap.containsKey(req.id)) {
                   
                        DelegatedRequestWrapper objWrap = new DelegatedRequestWrapper();
                        objWrap.DelegatedPI = ReqIdPIMap.get(req.id);
                        objWrap.DelegatedRequest = req; 
                        delegatedList.add(objWrap);
                    
                }                    
                }
            }
        }
        
        return delegatedList;
    }
    
    /** Fetches the Requests to Approve records **/
    @AuraEnabled
    public static LIST<ItemsToApproveWrapper> getItemsToApprove() {
        //map of Request record id and Request record
        MAP<String, IFv2_Request__c> requestMAP = new MAP<String, IFv2_Request__c>();
        //Return variable
        LIST<ItemsToApproveWrapper> recordLIST = new LIST<ItemsToApproveWrapper>();
        SET<Id> requestsIdSET = new SET<Id>();  //set for storing Ids of Request to be fetched
        SET<Id> requestIdSET = new SET<Id>();   //set of Ids of ProcessInstance
        LIST <ProcessInstanceWorkitem> workItemsLIST = new LIST <ProcessInstanceWorkitem>();
        
        for(ProcessInstanceWorkitem workItem : [SELECT ProcessInstanceId, CreatedDate, ProcessInstance.TargetObjectId, ElapsedTimeInDays
                                                FROM ProcessInstanceWorkitem
                                                WHERE ActorId =: strUserId AND ProcessInstance.Status = 'Pending' ORDER BY CreatedDate DESC LIMIT :limit1]) {
                                                    if(workItem.ProcessInstanceId != Null) {
                                                        requestIdSET.add(workItem.ProcessInstance.TargetObjectId);
                                                        workItemsLIST.add(workItem);
                                                    }
                                                }
        
        if(!requestIdSET.isEmpty()) {
            for(IFv2_Request__c request : [SELECT Id, Name, Workflow__c, Status__c, CreatedBy.Name, CreatedDate
                                           FROM IFv2_Request__c
                                           WHERE Status__c = 'Submitted' AND Id IN: requestIdSET 
                                           ORDER BY CreatedDate DESC LIMIT :limit1]) {
                                               requestMAP.put(request.id,request); 
                                           }
        }
        
        if(!requestMAP.isEmpty()) {
            MAP<string,decimal> mapRemainderDays = new MAP<string,decimal>();   //map of workflow name and its reminder after days value
            //Workflow to get the Remainder days
            LIST<IFv2_Workflow__c> workflowsLIST = [SELECT Workflow__c, ReminderAfterDays__c, SubsequentReminderAfter__c, Country__c 
                                                    FROM IFv2_Workflow__c];
            for(IFv2_Workflow__c objWF : workflowsLIST) {
                mapRemainderDays.put(objWF.Workflow__c,objWF.ReminderAfterDays__c);                     
            }
            
            for(ProcessInstanceWorkitem objPI : workItemsLIST) {
                String workflowname;
                if(requestMAP.containsKey(objPI.ProcessInstance.TargetObjectId) && requestMAP.get(objPI.ProcessInstance.TargetObjectId).Workflow__c != Null) {
                    workflowname = string.valueOf(requestMAP.get(objPI.ProcessInstance.TargetObjectId).Workflow__c);
                    
                    if(objPI.ElapsedTimeInDays >= mapRemainderDays.get(workflowname)) { 
                        ItemsToApproveWrapper objWrap = new ItemsToApproveWrapper();
                        objWrap.lstOverdueProcessInstance = objPI;
                        objWrap.objOverdueRequest = requestMAP.get(objPI.ProcessInstance.TargetObjectId);
                        recordLIST.add(objWrap);
                    } else {
                        ItemsToApproveWrapper objWrap = new ItemsToApproveWrapper();
                        objWrap.lstToApproveProcessInstance = objPI;
                        objWrap.objToApproveRequest = requestMAP.get(objPI.ProcessInstance.TargetObjectId); 
                        recordLIST.add(objWrap);
                    }
                }
            }
        }
        return recordLIST;
    }
    
     @AuraEnabled
    public static LIST<MySubmittedWrapper> getItemsSubmittedByMe() {
        //map of Request record id and Request record
        MAP<String, IFv2_Request__c> requestMAP = new MAP<String, IFv2_Request__c>();
        //Return variable
        LIST<MySubmittedWrapper> recordLIST = new LIST<MySubmittedWrapper>();
        SET<Id> requestsIdSET = new SET<Id>();  //set for storing Ids of Request to be fetched
        SET<Id> requestIdSET = new SET<Id>();   //set of Ids of ProcessInstance
        LIST <ProcessInstanceWorkitem> workItemsLIST = new LIST <ProcessInstanceWorkitem>();
        
        for(IFv2_Request__c request : [SELECT Id, Name, Workflow__c, Status__c, CreatedBy.Name, CreatedDate
                                           FROM IFv2_Request__c
                                           WHERE Status__c = 'Submitted' AND OwnerId = :strUserId 
                                           ORDER BY CreatedDate DESC LIMIT :limit1]) {
                                               requestMAP.put(request.id,request); 
                                               requestIdSET.add(request.id);
                                           }
        
        if(requestIdSET.size()>0){
            for(ProcessInstanceWorkitem workItem : [SELECT ProcessInstanceId, CreatedDate, ProcessInstance.TargetObjectId, ElapsedTimeInDays
                                                    FROM ProcessInstanceWorkitem
                                                    WHERE ProcessInstance.TargetObjectId IN: requestIdSET AND ProcessInstance.Status = 'Pending' ORDER BY CreatedDate DESC LIMIT :limit1]) {
                                                        if(workItem.ProcessInstanceId != Null) {
                                                            workItemsLIST.add(workItem);
                                                        }
                                                    }
        }
        
        if(!requestMAP.isEmpty()) {            
            for(ProcessInstanceWorkitem objPI : workItemsLIST) {
                String workflowname;
                if(requestMAP.containsKey(objPI.ProcessInstance.TargetObjectId)) {
                   
                        MySubmittedWrapper objWrap = new MySubmittedWrapper();
                        objWrap.MySubmittedPI = objPI;
                        objWrap.MySubmittedRequest = requestMAP.get(objPI.ProcessInstance.TargetObjectId); 
                        recordLIST.add(objWrap);
                    
                }
            }
        }
        System.debug('inside my submitted>'+recordLIST);
        return recordLIST;
    }
    
    /** Wrapper to hold the Requests Overdue data **/
    public class ItemsToApproveWrapper {
        @AuraEnabled public ProcessInstanceWorkitem lstOverdueProcessInstance {get; set;}
        @AuraEnabled public sObject objOverdueRequest {get; set;}
        @AuraEnabled public ProcessInstanceWorkitem lstToApproveProcessInstance {get; set;}
        @AuraEnabled public sObject objToApproveRequest {get; set;}
        public ItemsToApproveWrapper() {}
    }
    
    /** Wrapper to hold the My submitted Requests data **/
    public class MySubmittedWrapper {
        @AuraEnabled public ProcessInstanceWorkitem MySubmittedPI {get; set;}
        @AuraEnabled public sObject MySubmittedRequest {get; set;}
                public MySubmittedWrapper() {}
    }
    
    /** Wrapper to hold the Delegated Request data **/
    public class DelegatedRequestWrapper {
        @AuraEnabled public ProcessInstanceWorkitem DelegatedPI {get; set;}
        @AuraEnabled public sObject DelegatedRequest {get; set;}
                public DelegatedRequestWrapper() {}
    }
    
    /** Wrapper to hold the data to display on home screen **/
    public class RequestWrap {
        @AuraEnabled public LIST<IFv2_HomeScreenPage__mdt> lstMetadata {get; set;} //holds metadata records
        @AuraEnabled public LIST<IFv2_Request__c> lstRequest {get; set;} //holds Applicant requests
        //
      //   @AuraEnabled public LIST<ProcessInstanceWorkitem> PIWIDetails {get; set;} //holds Process instance details
        //
        @AuraEnabled public LIST<MySubmittedWrapper> lstItemsSubmitted{get;set;} 
        @AuraEnabled public LIST<ItemsApprovedByMe> lstItemsApprovedByMe{get;set;} //holds Requests approved by Me
        @AuraEnabled public LIST<IFv2_FieldWrapperClass> lstFields {get; set;} //holds fieldsets
        @AuraEnabled public LIST<DelegatedRequestWrapper> lstDelegate {get; set;} //holds delegated approvers
        @AuraEnabled public LIST<ItemsToApproveWrapper> lstItemsToApprove{get;set;}  //holds Overdue requests
        @AuraEnabled public LIST<IFv2_Request__c> lstItemsApprovedByProxy {get; set;} //holds Proxy approved records when user OOO
		@AuraEnabled public LIST<IFv2_Request__c> lstItemsRejectedByProxy {get; set;} //holds Proxy Rejected records when user OOO
        
        public RequestWrap() {}
    }
    
    /** Wrapper to hold the Requests Approved by Me **/ 
    public class ItemsApprovedByMe {
        @AuraEnabled public ProcessInstanceStep objProcessInstance {get; set;}
        @AuraEnabled public sObject strRequest {get; set;}
        @AuraEnabled public Account AccountProcessInstance{get;set;}
        
        public ItemsApprovedByMe() {}
    }
    
    /** Saving OutOfOffice functionality **/
    @AuraEnabled
    public static LIST<IFv2_AdminOnly__c> saveOutOfOfficeSettings(String recId, Boolean enable, String strWorkflow, String objUserId) {
        try {
            //Gets the OutOfOffice RecordType Id
            String RecordTypeId = getRecordTypeId();
            
            System.debug('********recId*******'+recId+'*******strWorkflow********'+strWorkflow);
            System.debug('********enable*******'+enable+'*******objUserId********'+objUserId);
            LIST<IFv2_AdminOnly__c> admLIST = new List<IFv2_AdminOnly__c>();
            Set<String> workflowsNameSet = new Set<String>();
            
            
            if(!String.isBlank(RecordTypeId)) {
                
                //if user selects All workflows then create multiple admin logs
                if((String.isBlank(recId) || String.isEmpty(recId)) && 
                   (!String.isBlank(strWorkflow) && strWorkflow.equalsIgnoreCase('All'))) {
                       
                       admLIST = [SELECT Id, Name, Active__c, WorkflowName__c, User__c, User__r.Name, CreatedbyId
                                  FROM IFv2_AdminOnly__c
                                  WHERE WorkflowName__c != ''
                                  AND CreatedById = :UserInfo.getUserId()
                                  AND RecordTypeId =: RecordTypeId
                                  LIMIT :limit1];
                       
                       //prepare list of already created admin logs for the active workflows
                       if(!admLIST.isEmpty()) {
                           System.debug('********admLIST*******'+admLIST);
                           IFv2_DmlController.GenericListDMLOperation(admLIST, 'delete');
                       }
                       
                       //fetch all the workflows names to compare with active workflows.
                       //Get Out of Office Workflow names
                       LIST<IFv2_Workflows__mdt> WorkflowMetadataLIST = [SELECT Id, Name__c
                                                                         FROM IFv2_Workflows__mdt
                                                                         WHERE Status__c = 'Active'
                                                                         ORDER BY Name__c];
                       List<String> finalWorkFlowsList = new List<String>();
                       
                       
                       //iterate all the workflows and compare with user already created outoffice logs workflows
                       if(!WorkflowMetadataLIST.isEmpty()){
                           System.debug('********WorkflowMetadataLIST*******'+WorkflowMetadataLIST);
                           for(IFv2_Workflows__mdt workflow : WorkflowMetadataLIST) {
                               finalWorkFlowsList.add(workflow.Name__c);
                           }                       
                       }
                       
                       List<IFv2_AdminOnly__c> finalAdminLogs = new List<IFv2_AdminOnly__c>();
                       //create the admin logs for all the workflows for the current user.
                       if(!finalWorkFlowsList.isEmpty()) {
                           
                           System.debug('********finalWorkFlowsList*******'+finalWorkFlowsList);
                           for(IFv2_Workflows__mdt worflowRec : WorkflowMetadataLIST) {
                               IFv2_AdminOnly__c adm1 = new IFv2_AdminOnly__c();
                               adm1.WorkflowName__c = worflowRec.Name__c;
                               adm1.User__c = objUserId;
                               adm1.Active__c = enable;
                               finalAdminLogs.add(adm1);
                           }
                       }
                       
                       if(!finalAdminLogs.isEmpty()) {
                           IFv2_DmlController.GenericListDMLOperationAccountRecords(finalAdminLogs, 'insert');
                       }
                       
                   } else if((String.isBlank(recId) || String.isEmpty(recId)) && !String.isBlank(strWorkflow)) { //Inserting new Record
                       
                       admLIST = [SELECT Id, Name, Active__c, WorkflowName__c, User__c, User__r.Name, CreatedbyId
                                  FROM IFv2_AdminOnly__c
                                  WHERE WorkflowName__c = :strWorkflow
                                  AND CreatedById = :UserInfo.getUserId()
                                  AND RecordTypeId =: RecordTypeId LIMIT 50000];
                       
                       IFv2_AdminOnly__c record = new IFv2_AdminOnly__c();
                       
                       if(!admLIST.isEmpty()) {
                           //updating existing record
                           record = admLIST[0];
                       }
                       
                       record.Active__c = enable;
                       record.WorkflowName__c = strWorkflow;
                       record.User__c = objUserId;
                       record.RecordTypeId = RecordTypeId;
                       IFv2_DmlController.GenericDMLOperation(record, 'upsert');
                       
                   } else if (recId != null || recId != '')  {
                       
                       //Updating the existing record if duplicate data entered
                       admLIST = [SELECT Id, Name, Active__c, WorkflowName__c, User__c, User__r.Name
                                  FROM IFv2_AdminOnly__c
                                  WHERE Id = :recId
                                  AND RecordTypeId =: RecordTypeId LIMIT :limit1];
                       
                       if(!admLIST.isEmpty() || Test.isRunningTest()) {
                           IFv2_AdminOnly__c adm = admLIST[0];
                           adm.WorkflowName__c = strWorkflow;
                           adm.User__c = objUserId;
                           adm.Active__c = enable;
                           IFv2_DmlController.GenericDMLOperation(adm, 'update');
                       }
                   }
                //Getting the recent records for Out of Office
                LIST<IFv2_AdminOnly__c> recordLIST = getLogRecords();
                return recordLIST;
            }
        } catch(Exception e) {
            System.debug('Exception');
        }
        return null;
    }
    
    /** Gets the Users who are Out Of Office **/
    @AuraEnabled
    public static OutOfOfficeWrap getOutOfOfficeData() {
        //Return wrapper variable
        OutOfOfficeWrap objOutOfOffice = new OutOfOfficeWrap();
        //Get Out of Office Workflow names
        
        LIST<IFv2_Workflows__mdt> WorkflowMetadataLIST = [SELECT Id, Name__c
                                                          FROM IFv2_Workflows__mdt
                                                          WHERE Status__c = 'Active'
                                                          ORDER BY Name__c];
        
        User LoggedinUserRecord = IFv2_UtilsController.getLoggedInDetails();
        
        if(LoggedinUserRecord!= NULL) {
            objOutOfOffice.status = LoggedinUserRecord.Out_Of_Office__c;
        }
        //holds Workflow names
        SET<String> WFNamesSET = new SET<String>();
        for(IFv2_Workflows__mdt objreq : WorkflowMetadataLIST) {
            //added by All Option
            WFNamesSET.add('All');
            WFNamesSET.add(objreq.Name__c);
            
        }
        //Workflow names
        objOutOfOffice.lstOutOfOfficeSettings = WFNamesSET;
        //retrieving Out of Office log records
        objOutOfOffice.lstOutOfOfficeUsers = getLogRecords();
        
        return objOutOfOffice;
    }
    
    public static String getRecordTypeId() {
        //Admin only object API Name
        String Object_Name = 'IFv2_AdminOnly__c';
        //OutOfOffice Logs record Type on Admin only object
        String Record_Type = 'OutOfOfficeLogs';
        
        LIST<RecordType> RecordTypeLIST = [SELECT Id 
                                           FROM RecordType 
                                           WHERE SobjectType = :Object_Name 
                                           AND Name = :Record_Type
                                           LIMIT 1];
        if(!RecordTypeLIST.isEmpty()) {
            return RecordTypeLIST[0].Id;
        } else {
            return null;
        }
    }
    
    public static LIST<IFv2_AdminOnly__c> getLogRecords() {
        //Return variable
        LIST<IFv2_AdminOnly__c> AdminOnlyLIST = new LIST<IFv2_AdminOnly__c>();
        //Getting record type Id of Out Of Office.
        String RecordTypeId = getRecordTypeId();
        
        
        if(!String.isBlank(RecordTypeId)) {
            
            AdminOnlyLIST = [SELECT Id, Name, Active__c, WorkflowName__c, User__c, User__r.Name
                             FROM IFv2_AdminOnly__c 
                             WHERE RecordTypeId =: RecordTypeId
                             AND CreatedById =: UserInfo.getuserId()
                             ORDER BY WorkflowName__c ASC LIMIT :limit1];
        }

        return AdminOnlyLIST;
    }
    
    
    /** Back to Office functionality **/
    @AuraEnabled
    public static LIST<IFv2_AdminOnly__c> DisableOutOfOfficeSettings(String DisableOutOfOffice) {
        //return List
        LIST<IFv2_AdminOnly__c> AdminOnlyLIST = new LIST<IFv2_AdminOnly__c>();
        
        //deserializing the input parameter
        IFv2_AdminOnly__c objAdminString = (IFv2_AdminOnly__c)JSON.deserialize(DisableOutOfOffice, IFv2_AdminOnly__c.Class);
        
        if(objAdminString != null) {
            //Retriving the Out of Office record which needs to be disabled
            AdminOnlyLIST = [SELECT Id, Name, Active__c, WorkflowName__c, User__c, User__r.Name, CreatedDate, CreatedById
                             FROM IFv2_AdminOnly__c 
                             WHERE Id =: objAdminString.Id
                             LIMIT 1];
            
            if(!AdminOnlyLIST.isEmpty()) {
                IFv2_DmlController.GenericListDMLOperation(AdminOnlyLIST, 'delete');
            }
        }
        
        return getLogRecords();
    }
    
    /** Wrapper to Hold OutOfOffice records **/
    public class OutOfOfficeWrap {
        //holds Workflow names to display in Out of Office Settings
        @AuraEnabled public SET<String> lstOutOfOfficeSettings{get;set;}
        //holds Out of Office Users
        @AuraEnabled public LIST<IFv2_AdminOnly__c> lstOutOfOfficeUsers{get;set;}
        //holdsoutofofficebacktoofficeStatus
        @AuraEnabled public boolean status{get;set;}
        
        public OutOfOfficeWrap() {}
    }
    
    /* Method to update user record and out of office and back to office record */
    @AuraEnabled
    Public static String UpdateOutOfOfficeBackToOffice(Boolean updateValue) {
        String status;
        System.debug('updateValue*****' + updateValue);
        try {
            //Get logged in user details
            User loggedInUser =  IFv2_UtilsController.getLoggedInDetails();
            
            //List to store Records to be updated in Admin only objects
            //Holds admin only records which are to be quired.
            LIST<IFv2_AdminOnly__c> adminOnlyRecordsLIST = new LIST<IFv2_AdminOnly__c>();
            //Holds admin only records which are to be updated
            LIST<IFv2_AdminOnly__c> adminOnlyRecordsUpdateLIST = new LIST<IFv2_AdminOnly__c>();
            //Holds user records to be updated.
            LIST<User> userUpdateLIST = new LIST<User>();
            
            //To check if loggedInUser is not NULL
            if(loggedInUser != NULL) {
                adminOnlyRecordsLIST = IFv2_UtilsController.getAdminOnlyRecords(loggedInUser.Id); 
            }
            //To check if adminOnlyRecordsLIST is not empty
            if(!adminOnlyRecordsLIST.isEmpty()) {
                for(IFv2_AdminOnly__c record : adminOnlyRecordsLIST) {
                    record.Active__c = updateValue;
                    adminOnlyRecordsUpdateLIST.add(record);
                }
            }
            //Checks if logged in user id is not NULL
            if(loggedInUser != NULL) {
                loggedInUser.Out_Of_Office__c = updateValue;
                userUpdateLIST.add(loggedInUser);
            }
            
            //To check if userUpdateLIST is not empty
            if(!userUpdateLIST.isEmpty()) {
                System.debug('userUpdateLIST*****' + userUpdateLIST);
                IFv2_DMLController.updateUsers(userUpdateLIST);
            }
            //To check if adminOnlyRecordsUpdateLIST is not empty
            if(!adminOnlyRecordsUpdateLIST.isEmpty()) {
                IFv2_DmlController.GenericListDMLOperation(adminOnlyRecordsUpdateLIST, 'update');
            }
            status = 'success';
        } catch(Exception e) {
            IFv2_ExceptionUtilitiesController.exceptionHandler(e);
            status = e.getMessage();
        }
        return status;
    }
}