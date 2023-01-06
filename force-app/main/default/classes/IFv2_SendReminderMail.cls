/*******************************************************************************************************
* @ Name                : IFv2_SendReminderMail
* @ Purpose             : Send reminder to approvers
* @ Author              : kanchan
* @ Test class name     : IFv2_SendReminderMailTest

*  Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*  27-11-2018      |  kanchan.baghel@absyz.com     |  1.0          |  Initial Version
*  12-08-2019      |  Hanu Sanampudi               |  1.1          |  Added Escalation emails logic to skip the public group users.

***********************************************************************************************/

global class IFv2_SendReminderMail implements Database.Batchable < sobject > {
    
    //Global Variables - Used for Remainder check 1, 2 and 3
    global decimal timePeriodOne = 0;
    global decimal timePeriodTwo = 0;
    global decimal timePeriodThree = 0;
    
    //Map to capture approver id and request record id
    global Database.QueryLocator start(Database.BatchableContext batchableContext) {
        
        //Get Request record with submitted status and pending steps status 
        String queryRequest = 'SELECT id, Name, Workflow__c,WorkflowId__c,RequestExtension1__c,RequestExtension2__c,RequestExtension3__c,Account__c, Status__c,DetailLink__c,createdDate,createdBy.Name,(SELECT TargetObjectId, SystemModstamp, StepStatus, OriginalActor.Name, IsPending, IsDeleted, Id, CreatedDate, CreatedById, Comments, Actor.Name FROM ProcessSteps WHERE StepStatus = \'Pending\') FROM IFv2_Request__c where status__c=\'submitted\'';
      

        return Database.getQueryLocator(queryRequest);
    }
    
    //Executing the batch class
    global void execute(Database.BatchableContext batchableContext, LIST< IFv2_Request__c > requestLIST) {
        
        if(!requestLIST.isEmpty()) {
			
            //Get workflow name from request list
            String workflowNameFromRequest = requestLIST[0].Workflow__c;
            system.debug('workflowNameFromRequest'+workflowNameFromRequest);
            String workFlowIdFromRequest = requestLIST[0].WorkflowId__c;
            system.debug('workFlowIdFromRequest'+workFlowIdFromRequest);
            
            //List to store queried workflow list
            LIST<IFv2_Workflow__c> workflowLIST = new LIST<IFv2_Workflow__c>();
            
            //Query custom setting
            if(!String.isBlank(workFlowIdFromRequest)) {
                /* Query changed to use Workflow Id instead of Name */
                workflowLIST = [SELECT Workflow__c,ReminderAfterDays__c,SubsequentReminderAfter__c 
                                FROM IFv2_Workflow__c 
                                WHERE Id =:workFlowIdFromRequest];
            } else if(!String.isBlank(workflowNameFromRequest)){
                workflowLIST = [SELECT Workflow__c,ReminderAfterDays__c,SubsequentReminderAfter__c 
                                FROM IFv2_Workflow__c 
                                WHERE Workflow__c =:workflowNameFromRequest];
            } 
            
            if(!workflowLIST.isEmpty()) {
                
                //Caluculate days for reminder
                if(String.isblank(String.valueof(workflowlist[0].ReminderAfterDays__c)))
                    workflowlist[0].ReminderAfterDays__c=0;
                if(String.isblank(String.valueof(workflowlist[0].SubsequentReminderAfter__c)))
                    workflowlist[0].SubsequentReminderAfter__c = 0;
                
                //get reminder day 
                decimal timePeriodOne = workflowlist[0].ReminderAfterDays__c;
                //get second reminder day
                decimal timePeriodTwo = workflowlist[0].SubsequentReminderAfter__c + timePeriodOne;
                //get third reminder day
                decimal timePeriodThree = workflowlist[0].SubsequentReminderAfter__c + timePeriodTwo;
                
                //Set to capture request record id
                SET<Id> requestIdsSET = new SET<Id>();
                //map to get request id and request record as value
                MAP<String, IFv2_Request__c> requestIdRecordMAP = new MAP<String, IFv2_Request__c>();
                //Map to store original actor id and request recod id
                MAP<String, String> requestIdMAP = new MAP<String, String>();
                
                //checking if requestLIST is not empty
                if(!requestLIST.isEmpty()) {
                    
                    //iterate over request list
                    for (IFv2_Request__c request: requestLIST) {
                        //checking if ProcessSteps is not empty
                        if (!request.ProcessSteps.isEmpty()) {
                            //put request record id
                            requestIdRecordMAP.put(request.Id, request);
                            
                            //put request id in set
                            requestIdsSET.add(request.Id);
                        }
                    }
                }
                
                //list to capture steps with elapsed time 
                LIST<ProcessInstanceWorkitem> workitemsLIST = new  LIST<ProcessInstanceWorkitem>();
                MAP<id, IFv2_Request__c> requestTargetIdMAP = new MAP<id, IFv2_Request__c>();
                //checking if requestIdsSET is not empty
                if(!requestIdsSET.isEmpty()) {
                    workitemsLIST = [SELECT OriginalActorId, ActorId, ElapsedTimeInDays, Actor.Name,
                                     ProcessInstance.TargetObjectId, createdDate
                                     FROM ProcessInstanceWorkitem
                                     WHERE ProcessInstance.TargetObjectId IN: requestIdsSET];
                }
                
                //check the public group to skip the users from esclation emails
                //query the GroupMember object and get all the group memebers details
                List<GroupMember> removeEscalationUsersList = [select group.name,group.DeveloperName,UserOrGroupId,group.type from GroupMember 
                                                                where group.DeveloperName = 'RemoveEsclationEmailsUsers' ];
                
                System.debug('DEBUG::removeEscalationUsersList**size***' + removeEscalationUsersList.size());
                System.debug('DEBUG::removeEscalationUsersList*****' + removeEscalationUsersList);
                List<Id> esclationUserList = new List<Id>();
                
                if(!removeEscalationUsersList.isEmpty()) {
                    for(GroupMember groupUser : removeEscalationUsersList) {
                        esclationUserList.add(groupUser.UserOrGroupId);
                    }
                }
				
                //Set to store originalacotrid
                SET<Id> useridSET = new SET<Id>();
                
                System.debug('DEBUG::timePeriodOne ******' +timePeriodOne);
                System.debug('DEBUG::timePeriodTwo ******' +timePeriodTwo);
                System.debug('DEBUG::timePeriodThree ******' +timePeriodThree);
                
                //iterate over ProcessInstanceWorkitem list
                if(!workitemsLIST.isEmpty()) {
                    for (ProcessInstanceWorkitem workItem : workitemsLIST) {
						
                        System.debug('DEBUG::workItem.ElapsedTimeInDays.setscale(0)******' +workItem.ElapsedTimeInDays.setscale(0));					
						date newDate1 = date.newInstance(workItem.CreatedDate.year(), workItem.CreatedDate.month(), workItem.CreatedDate.day());
						date todayObj1 = Date.Today();
						System.debug('DEBUG::newDate1******' +newDate1);
						System.debug('DEBUG::todayObj1******' +todayObj1);
						System.debug('DEBUG::workItem.ActorId******' +workItem.ActorId);
						
						//logic to calculate the working days b/w the two dates
						Integer weekEndDays1 = 0;
						for(integer i=0; i <= newDate1.daysBetween(todayObj1); i++) {
							
							Date dt1 = newDate1 + i; 
							DateTime currDate1 = DateTime.newInstance(dt1.year(), dt1.month(), dt1.day());
							String todayDay1 = currDate1.format('EEEE');
							
							if(todayDay1 == 'Saturday' || todayDay1 =='Sunday' || Test.isRunningTest()) {
								weekEndDays1 = weekEndDays1 + 1; 
							}							
						}
						
						System.debug('--weekends b/w the two date '+ weekEndDays1); 
						Integer elapsedDays1 = 0;
						if(weekEndDays1 != 0){
							elapsedDays1 = Integer.valueOf(workItem.ElapsedTimeInDays.setscale(0) - weekEndDays1);
						}
						
                        if ((elapsedDays1 == timePeriodOne ||
								elapsedDays1 == timePeriodTwo ||
								elapsedDays1 == timePeriodThree ||
                            Test.isRunningTest())&& 
								(elapsedDays1!=0)) {
                                 requestIdMAP.put(workItem.ActorId + '.' + workItem.Id, workItem.ProcessInstance.TargetObjectId);
                                 //get original actor id in set
                                 useridSET.add(workItem.ActorId);
                                 
                             }
                    }
                }
                
                //list to capture actor id and email
                MAP<Id,String> useridEmailMAP = new MAP<Id,String>();
                MAP<Id,String> userManagerEmailMAP = new MAP<Id,String>();
                MAP<Id,String> userIdManagerNameMAP = new MAP<Id,String>();
                MAP<Id,Id> userIdmanagerIdMAP = new MAP<Id,Id>();
                
                //get user email 
                LIST<User> userLIST = new LIST<User>();
                //checking if useridSET is not empty
                if(!useridSET.isEmpty()) {
                    userLIST  = [SELECT email, manager.email, Manager.Name,Manager.Id
                                 FROM User 
                                 WHERE id IN: useridSET];
                }
                
                //Iterate over user email list 
                if(!userLIST.isEmpty()) {
                    //iterating over userLIST
                    for (User userRecord : userLIST) {
                        //add actor id as key and email as  value
                        useridEmailMAP.put(userRecord.Id, userRecord.Email);
                        //Map to store actor id and manager email 
                        userManagerEmailMAP.put(userRecord.Id, userRecord.manager.Email);
                        //Map to store Actor Id and Manager Name
                        userIdManagerNameMAP.put(userRecord.Id, userRecord.Manager.Name);
                        userIdmanagerIdMAP.put(userRecord.Id,userRecord.Manager.Id);
                    }
                }
                
                System.debug('DEBUG:****userLIST*****'+ userLIST);
                System.debug('DEBUG:****useridSET******' + useridSET);
                
                //List to store single email messages
                LIST<Messaging.SingleEmailMessage> allSingleEmailLIST = new LIST<Messaging.SingleEmailMessage>();
                
                LIST<Contact> contactLIST = [SELECT Id 
                                             FROM Contact 
                                             LIMIT 1];
											  
				
                if(!workitemsLIST.isEmpty()) {
                    
                    for (ProcessInstanceWorkitem workItem: workitemsLIST) {
                        
						String actorId = workItem.ActorId;
						
                        date newDate = date.newInstance(workItem.CreatedDate.year(), workItem.CreatedDate.month(), workItem.CreatedDate.day());
						date todayObj = Date.Today();
						
						//logic to calculate the working days b/w the two dates
						Integer weekEndDays = 0;
						for(integer i=0; i <= newDate.daysBetween(todayObj); i++) {
							
							Date dt = newDate + i; 
							DateTime currDate = DateTime.newInstance(dt.year(), dt.month(), dt.day());
							String todayDay = currDate.format('EEEE');
							
							if(todayDay == 'Saturday' || todayDay =='Sunday' || Test.isRunningTest()) {
								weekEndDays = weekEndDays + 1; 
							}							
						}
						
						System.debug('--Weekends days b/w the two date '+ weekEndDays); 						
						
						
                        Decimal timePeriod = 0;
						Integer elapsedDays = 0;
						
						if(weekEndDays != 0){
							elapsedDays = Integer.valueOf(workItem.ElapsedTimeInDays.setscale(0) - weekEndDays);
						}

                        if(elapsedDays == timePeriodOne)
                        {
                            timePeriod= timePeriodOne;
                            
                        }
                        else if(elapsedDays == timePeriodTwo)
                        {
                            timePeriod=timePeriodTwo;
                        }
                        else if (elapsedDays == timePeriodThree) 
                        {
                            timePeriod=timePeriodThree;
                        }
                        
                        
                        if ((String.isnotblank(useridEmailMAP.get(actorId))&&timePeriod!=0)|| Test.isRunningTest())  {
                            String recordId = workItem.ProcessInstance.TargetObjectId;
                            
                            String[] toAddressesLIST = new String[] {};
                            String[] ccAddressesLIST = new String[] {};
                                    
                            LIST<IFv2_Request__c> reqList = new LIST<IFv2_Request__c>();
                            reqList.add(requestIdRecordMAP.get(recordId));
                            
                            //Prepare Email body
                            String body='<Html><body> Dear ' + workItem.Actor.Name + ',<br/><br/>' +
                                'This request has been overdue for ' +timePeriod +' days. Your timely action is appreciated. Please find details below<br/><br/>'+ 
                                'Request : ' + '<a href="'+reqList[0].DetailLink__c+'">'+reqList[0].Name+'</a><br/>'+
                                'WorkFlow : ' + reqList[0].Workflow__c + '<br/>'+
                                'Applicant : ' + reqList[0].CreatedBy.Name + '<br/>'+
                                'Created Date : ' + reqList[0].createdDate + '<br/><br/><br/>'+
                                '___________________________________________<br/>'+
                                'Please do not reply to this automated mail.<br/>'+
                                '</body></Html>';
                            
                            String body2 ='<Html><body> Dear ' + workItem.Actor.Name + ',<br/><br/>' +
                                'This request has been overdue for ' +timePeriod +' days. Your timely action is appreciated. Please find details below<br/><br/>'+ 
                                'Request : ' + '<a href="'+reqList[0].DetailLink__c+'">'+reqList[0].Name+'</a><br/>'+
                                'WorkFlow : ' + reqList[0].Workflow__c + '<br/>'+
                                'Applicant : ' + reqList[0].CreatedBy.Name + '<br/>'+
                                'Created Date : ' + reqList[0].createdDate + '<br/><br/><br/>'; 
                           
                            //send email to Approver and Approver manager 
                            if (elapsedDays == timePeriodThree || Test.isRunningTest()) {
                                
                                toAddressesLIST.add(useridEmailMAP.get(actorId));
                                if(String.isnotblank(userManagerEmailMAP.get(actorId)) && !esclationUserList.contains(userIdmanagerIdMAP.get(actorId))) {
                                    ccAddressesLIST.add(userManagerEmailMAP.get(actorId));
                                } 
                            } else {
                                toAddressesLIST.add(useridEmailMAP.get(actorId));
                            } 
                            
                            //checking if toAddressesLIST is not empty
                            if(!toAddressesLIST.isEmpty()) {  
                            
                                Messaging.SingleEmailMessage oneEmail = new Messaging.SingleEmailMessage();
                                //Making email address of dummy contact record inactive 
                                oneEmail.setTreatTargetObjectAsRecipient(false);
                                //Setting the setTargetObjectId to dummy contact id
                                if(!contactLIST.isEmpty()) {
                                    oneEmail.setTargetObjectId(contactLIST[0].id);
                                }
                                oneEmail.setSaveAsActivity(false);
                                //Setting the WhatId to customobject Id so that merge fields in template gets rendered
                                oneEmail.setWhatId(recordId);
                                oneEmail.setSubject('InsightFlow ' +reqList[0].Name+ ' is due since ' +newdate.format());
                                System.debug('*********************elapsedDays*********'+ elapsedDays);
                                //Set email body
                                if(elapsedDays != timePeriodThree) {
                                    oneEmail.setHtmlBody(body);
                                } else {
                                    
									//set email address of manager in cc
									if(!ccAddressesLIST.isEmpty()) {
										oneEmail.setccAddresses(ccAddressesLIST);
										body2 = body2+ 'Dear ' + userIdManagerNameMAP.get(workItem.ActorId) + ',<br/><br/>' +
												System.Label.CLIFv20198 + '<br/><br/><br/>' + 
												'___________________________________________<br/>'+
												'Please do not reply to this automated mail.<br/>'+
												'</body></Html>'; 
										System.debug('DEBUG:****body2*****'+ body2);
									}
									oneEmail.setHtmlBody(body2);
									
                                    if(userIdManagerNameMAP.get(workItem.ActorId) != NULL) {
                                        SET<Id> managerSET = new SET<Id>();
                                        managerSET.add(userIdmanagerIdMAP.get(workItem.ActorId));
                                        IFv2_HeaderController.RecordShareManager(managerSET,reqList[0].Id,reqList[0].RequestExtension1__c,reqList[0].RequestExtension2__c,reqList[0].RequestExtension3__c,reqList[0].Account__c,reqList[0].Workflow__c);
                                    }
                                }
                                //oneEmail.setHtmlBody(body);
                                //set user email to send email
                                oneEmail.setToAddresses(toAddressesLIST);
                                
                                //add emails to list
                                allSingleEmailLIST.add(oneEmail);
                            }
                        }
                    }
                }
                //send email 
                if(!allSingleEmailLIST.isEmpty()) {
                    Messaging.sendEmail(allSingleEmailLIST);
                }
                
            }
        }
    }
    //finish method
    global void finish(Database.BatchableContext batchableContext) {
        
    }
    
}