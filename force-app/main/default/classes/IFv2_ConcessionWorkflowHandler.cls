/*******************************************************************************************************
* 
* @ Name        : IFv2_ConcessionWorkflowHandler
* @ Purpose     : Doing a SAP Callout. Used only in Iteration 3
* @ Author      : Prasad Vivek/Kanchan
* @ Test Class  : IFv2_ConcessionWorkflowHandlerTest
*
*   Date            |  Developer Name                       |  Version          |  Changes
* ======================================================================================================
*   19-03-2019      |  vivek.kothalanka@absyz.com           |  1.0              |  Initial Version
*   19-03-2019      |  Kanchan.Bhagel@absyz.com             |  1.0              |  Initial Version
*   20-08-2018      |  external.debasmita.rawooth@seg-automotive.com            |  Updated RiskAssessment and Comment mappings 
*   15-02-2021      |  external.nirmal.christopher@seg-automotive.com           |  truncated more than 12 characters for PARNR related values
*******************************************************************************************************/

public class IFv2_ConcessionWorkflowHandler {
    //Used to create notifications for SG_WF_WS_Sap_Con_CreateNotif_NEW
    @Future(callout=true)
    public static void createNotificationWrapper(LIST<String> requestIdLIST, MAP<String, String> httpHeaders) {
        System.debug('inside IFv2_ConcessionWorkflowHandler');
        /* Used to Activate or deactivate this method */
        Boolean donotExecuteTrigger = IFv2_UtilsController.getTriggerLogic('IFv2_RequestTrigger','createNotificationWrapper');
        System.debug('inside IFv2_ConcessionWorkflowHandler>donotExecuteTrigger'+donotExecuteTrigger);
        /* Checking if method is active or not */
        if(!donotExecuteTrigger) {
            if(!requestIdLIST.isEmpty()) {
                System.debug('inside IFv2_ConcessionWorkflowHandler>req nonempty>'+donotExecuteTrigger);
                //used to hold requests which are of type concession
                LIST<IFv2_Request__c> requestLIST = new LIST<IFv2_Request__c>();
                List<Ifv2_request__c>errorRecords=new List<Ifv2_request__c>();
                requestLIST = IFv2_UtilsController.getConcessionRequest(requestIdLIST);
                //holds process instance records against its id
                MAP<Id, ProcessInstance> processInstancesMAP = new MAP<Id, ProcessInstance>([
                    SELECT Id, TargetObjectId
                    FROM ProcessInstance 
                    WHERE TargetObjectId IN: requestIdLIST
                ]);
                //holds process instance records against request ID
                MAP<String, ProcessInstance> requestIdToProcessInstanceMAP = new MAP<String, ProcessInstance>();
                if(!processInstancesMAP.isEmpty()) {
                    for(ProcessInstance pi : processInstancesMAP.values()) {
                        requestIdToProcessInstanceMAP.put(pi.TargetObjectId, pi);
                    }
                }
                //holds process instance step records
                LIST<ProcessInstanceStep> processInstaceStepLIST = new LIST<ProcessInstanceStep>();
                //get process instance steps
                processInstaceStepLIST = IFv2_UtilsController.getProcessInstanceStep(processInstancesMAP.keySet());
                //LIST for materials
                LIST<Account> additionalMaterialLIST = new LIST<Account>();
                //get material information from account
                additionalMaterialLIST =    IFv2_UtilsController.getAccountMaterial(requestIdLIST);
                
                //List for Actor Department and NT User as it is not retrievable via Actor field
                LIST<String> actorIdLIST = new LIST<String>();
                if(!processInstaceStepLIST.isEmpty()) {
                    for(ProcessInstanceStep pis : processInstaceStepLIST) {
                        actorIdLIST.add(pis.ActorId);
                    }
                }
                //Map for getting Actor by Id
                MAP<Id, User> actorMAP = new MAP<Id, User>();
                if(!actorIdLIST.isEmpty()) {
                    actorMAP = new MAP<Id, User>([SELECT Id, NT_User__c, Department FROM User WHERE Id IN: actorIdLIST]);
                }
                //List for attachment calls
                LIST<String> reqIdLIST = new LIST<String>();
                //List to store account fields
                LIST<Account> UpdateAccountLIST = new LIST<Account>(); 
                //map to store request id and notification
                MAP<String, String> reqIdToNotificationIdMAP = new MAP<String, String>();
                //used to hold material code description 
                FINAL SET<String> materialCodeDescSET = new SET<String>();
                //get picklistvalues dynamically from request objcet 
                Schema.DescribeFieldResult  fieldResult = IFv2_Request__c.CategoryCodeDescription__c.getDescribe();
                LIST<Schema.PicklistEntry> picklistValueLIST = (fieldResult != null)?fieldResult.getPicklistValues():new LIST<Schema.PicklistEntry>();
                if(!picklistValueLIST.isEmpty()) {
                    for(Schema.PicklistEntry FieldValue : picklistValueLIST) {
                        materialCodeDescSET.add(FieldValue.getValue());
                    }
                }
                if(!requestLIST.isEmpty()) {
                    //iterating over request list and forming notification header
                    for(IFv2_Request__c request : requestLIST) {
                        
                        Boolean isMaterialCodeCategory = materialCodeDescSET.contains(request.CategoryCodeDescription__c);
                        //HEADER for callout
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.Concession_Notif_Header notificationHeader = new SG_WF_WS_Sap_Con_CreateNotif_NEW.Concession_Notif_Header();
                        notificationHeader.STRNO = request.Name;
                        notificationHeader.STRMN = request.CreatedDate.format('YYYY-MM-DD');
                        notificationHeader.QMART = 'QS';
                        if(!String.isBlank(request.CategoryCodeDescription__c)) {
                            LIST<String> splittedCatCodeDescription = request.CategoryCodeDescription__c.substring(0,13).split('-');
                            notificationHeader.QMGRP = splittedCatCodeDescription[0] + '-' + splittedCatCodeDescription[1];
                            notificationHeader.QMCOD = splittedCatCodeDescription[2];
                        }
                        notificationHeader.MATNR = isMaterialCodeCategory ? String.valueOf(request.MaterialNo__c) : ''; 
                        
                        if(!String.isBlank(request.Account__r.IFv2_Plant__c)) {
                            notificationHeader.SWERK = request.Account__r.IFv2_Plant__c.left(4);  
                        }
                        
                        notificationHeader.REVLV = isMaterialCodeCategory ? request.Account__r.IFv2_RevisionLevel__c : '';
                        notificationHeader.QMTXT = request.SpecificRequirement__c; //To ask Nadja if it is ok that it is html
                        notificationHeader.STRMN = String.valueOf(request.Account__r.Valid_from__c);
                        notificationHeader.LTRMN = String.valueOf(request.Account__r.Valid_to__c);
                        notificationHeader.BZMNG = String.valueOf(request.Account__r.IFv2_Limitedtothefollowingquantity__c);
                        notificationHeader.MBLNR = isMaterialCodeCategory ? String.valueOf(request.Account__r.IFv2_GoodsReceiptDocument__c) : '';
                        notificationHeader.DEVICEID = isMaterialCodecategory ? request.Account__r.IFv2_MaterialUsage__c : request.Account__r.IFv2_UsageProcess__c;
                        notificationHeader.SACHNUMMERN = !isMaterialCodecategory ? request.Account__r.IFv2_Process__c : '';
                        
                        //Additional materials
                        LIST<SG_WF_WS_Sap_Con_CreateNotif_NEW.AddMaterials> addMaterialsForCall= new LIST<SG_WF_WS_Sap_Con_CreateNotif_NEW.AddMaterials>();
                        if(isMaterialCodecategory) {
                            for(Account addMat : additionalMaterialLIST) {
                                if(addMat.IFv2_Request__c == request.Id) {
                                    SG_WF_WS_Sap_Con_CreateNotif_NEW.AddMaterials material = new SG_WF_WS_Sap_Con_CreateNotif_NEW.AddMaterials();
                                    material.Materials = addMat.IFv2_MaterialNumber__c;
                                    material.Revisions = addMat.IFv2_RevisionLevel__c;
                                    addMaterialsForCall.add(material);
                                }
                            }
                        }
                        
                        //HEADER LONG TEXT to store Concession Description
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.CONCESSION_NOTIF_HEADER_LTXT notificationHeaderLongText = new SG_WF_WS_Sap_Con_CreateNotif_NEW.CONCESSION_NOTIF_HEADER_LTXT();
                        
                        if(!String.isBlank(request.ConcessionDescription__c)) {
                            notificationHeaderLongText.TDLINE = request.ConcessionDescription__c.stripHtmlTags();
                        }
                        //Notification Items which stores Concession Comment
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.NotificationItem_Tabl notificationItem1 = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NotificationItem_Tabl();
                        notificationItem1.FETXT = request.Account__r.IFv2_Actualvaluenonconformity__c;
                        
                        /*Uncommented as mapping is missing on SAP*/
                        if(!String.isBlank(request.ConcessionComment__c)) {
                        notificationItem1.TDLINE = request.ConcessionComment__c.stripHtmlTags();
                        }
                        
                        //PARTNERS
                        LIST<SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_PARTNER_TABL> notPartnerLIST = new LIST<SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_PARTNER_TABL>();
                        
                        //get ApplicantNTUser
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_PARTNER_TABL currentAssignee = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_PARTNER_TABL();
                        currentAssignee.PARVW = 'AO';
                        currentAssignee.PARNR = request.ApplicantNTUser__c;//'BLN3SI'; //2HARDCODE
                        notPartnerLIST.add(currentAssignee);
                        
                        
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_PARTNER_TABL applicant = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_PARTNER_TABL();
                        applicant.PARVW = 'YN';
                        applicant.PARNR = request.ApplicantNTUser__c;//'BLN3SI';//2HARDCODE
                        notPartnerLIST.add(applicant);
                        
                        //if customer number is not blank
                        if(String.isNotBlank(String.valueOf(request.Account__r.IFv2_CustomerNo__c)) && isMaterialCodeCategory) {
                            SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_PARTNER_TABL customer = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_PARTNER_TABL();
                            customer.PARVW = 'AG';
                            customer.PARNR = String.valueOf(request.Account__r.IFv2_CustomerNo__c);
                            customer.NAME1 = request.Account__r.IFv2_CustomerName__c;
                            notPartnerLIST.add(customer);
                        }
                        //if supplier number is not blank
                        if(String.isNotBlank(String.valueOf(request.Account__r.IFv2_SupplierNo__c)) && isMaterialCodeCategory) {
                            SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_PARTNER_TABL supplier = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_PARTNER_TABL();
                            supplier.PARVW = 'HR';
                            supplier.PARNR = String.valueOf(request.Account__r.IFv2_SupplierNo__c);
                            supplier.NAME1 = request.Account__r.IFv2_ConcessionSupplierName__c;
                            notPartnerLIST.add(supplier);
                        }
                        
                        /*Ask*/
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_PARTNER_TABL coordinator = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_PARTNER_TABL();
                        coordinator.PARVW = 'YK';
                        coordinator.PARNR = request.Approver1__r.NT_User__c;
                        notPartnerLIST.add(coordinator);
                        
                        //Creation of Notification TASKS start
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL notTask1 = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL();
                        notTask1.MNGRP = 'QS-RM002';
                        notTask1.MNCOD = '0030';
                        /*Added after checking code in UAT*/
                        if(request.Account__r.IFv2_Escalatetomanagementlevel__c == 'YES') {
                            notTask1.USTXT = 'YES';
                        } else {
                            notTask1.USTXT = 'NO';
                        }
                        notTask1.TDLINE = request.Account__r.IFv2_Escalatetomanagementlevel__c;
                        
                        
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL notTask2 = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL();
                        notTask2.MNGRP = 'QS-RM002';
                        notTask2.MNCOD = '0041';
                        if(!Test.isRunningTest())
                        {
                            notTask2.TDLINE = request.Account__r.IFv2_Furtherprocessing__c.left(40);
                        }
                        
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL notTask3 = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL();
                        notTask3.MNGRP = 'QS-RM002';
                        notTask3.MNCOD = '0044';
                        notTask3.TDLINE = request.Account__r.IFv2_Reliability__c; /* This is used as reliability */
                        
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL notTask4 = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL();
                        notTask4.MNGRP = 'QS-RM002';
                        notTask4.MNCOD = '0045';
                        notTask4.TDLINE = request.Account__r.IFv2_Function__c;
                        
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL notTask5 = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL();
                        notTask5.MNGRP = 'QS-RM002';
                        notTask5.MNCOD = '0050';
                        notTask5.PARVW = 'YM';
                        notTask5.TDLINE = request.Riskassessment__c;//changed from MATXT to TDLINE
                        notTask5.PSTER = String.valueOf(request.ReleaseDate__c);
                        notTask5.PARNR = request.Buyer__r.NT_User__c; //Not sure if should be department here to ask Nadja /* ASK about this*/
                        
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL notTask6 = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL();
                        notTask6.MNGRP = 'QS-RM002';
                        notTask6.MNCOD = '0060';
                        notTask6.USTXT = request.Account__r.IFv2_Yescustomerreferenceno__c ? 'YES' : 'NO';
                        notTask6.TDLINE = request.Account__r.IFv2_CustomerApprovalInformation__c;
                        
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL notTask7 = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL();
                        notTask7.MNGRP = 'QS-RM002';
                        notTask7.MNCOD = '0070';
                        notTask7.USTXT = request.Full8Dreportnecessary__c;
                        notTask7.TDLINE = request.Account__r.IFv2_Full8Dreportnecessarydescription__c;
                        
                        //End  of Notification TASKS start
                        
                        
                        //Containment action only one - to ask Nadja about other ones
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL notTask8 = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL();
                        notTask8.MNGRP = 'QS-RM002';
                        notTask8.MNCOD = '3000';
                        notTask8.PARNR = 'YM';
                        notTask8.STTXT = request.Account__r.IFv2_Containmentaction__c;
                        notTask8.TDLINE = request.Account__r.IFv2_Containmentactionlongtext__c;
                        string PARNR_substringed2 = string.valueof(request.Account__r.IFv2_Responsible__c);
                            if(PARNR_substringed2 != NULL)
                            {
                                if(PARNR_Substringed2.length() > 12)
                                    PARNR_Substringed2 = PARNR_Substringed2.substring(0, 12);
                            }
                        notTask8.PARNR = PARNR_substringed2;
                        notTask8.PSTER = String.valueOf(request.Account__r.IFv2_Effectivefrom__c);
                        notTask8.PETER = String.valueOf(request.Account__r.IFv2_Introducedon__c);
                        
                        // Additional Containment Actions START 
                        LIST<SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL> additionalContainmentActions = new LIST<SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL>();
                        if(!String.isBlank(request.Account__r.IFv2_ContainmentAction2__c)) {
                            SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL notTask8_2 = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL();
                            notTask8_2.MNGRP = 'QS-RM002';
                            notTask8_2.MNCOD = '3000';
                            notTask8_2.PARNR = 'YM';
                            notTask8_2.STTXT = request.Account__r.IFv2_ContainmentAction2__c;
                            notTask8_2.TDLINE = request.Account__r.IFv2_ContainmentActionLongText2__c;
                            string PARNR_substringed = string.valueof(request.Account__r.IFv2_Responsible2__c);
                            if(PARNR_substringed != NULL)
                            {
                                if(PARNR_Substringed.length() > 12)
                                    PARNR_Substringed = PARNR_Substringed.substring(0, 12);
                            }
                            notTask8_2.PARNR = PARNR_substringed;
                            notTask8_2.PSTER = String.valueOf(request.Account__r.IFv2_EffectiveFrom2__c);
                            notTask8_2.PETER = String.valueOf(request.Account__r.IFv2_IntroducedOn2__c);
                            additionalContainmentActions.add(notTask8_2);
                        }
                        
                        if(!String.isBlank(request.Account__r.IFv2_ContainmentAction3__c)) {
                            SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL notTask8_3 = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL();
                            notTask8_3.MNGRP = 'QS-RM002';
                            notTask8_3.MNCOD = '3000';
                            notTask8_3.PARNR = 'YM';
                            notTask8_3.STTXT = request.Account__r.IFv2_ContainmentAction3__c;
                            notTask8_3.TDLINE = request.Account__r.IFv2_ContainmentActionLongText3__c;
                            string PARNR_substringed = string.valueof(request.Account__r.IFv2_Responsible3__c);
                            if(PARNR_substringed != NULL)
                            {
                                if(PARNR_Substringed.length() > 12)
                                    PARNR_Substringed = PARNR_Substringed.substring(0, 12);
                            }
                            notTask8_3.PARNR = PARNR_substringed;
                            notTask8_3.PSTER = String.valueOf(request.Account__r.IFv2_EffectiveFrom3__c);
                            notTask8_3.PETER = String.valueOf(request.Account__r.IFv2_IntroducedOn3__c);
                            additionalContainmentActions.add(notTask8_3);
                        }
                        
                        if(!String.isBlank(request.Account__r.IFv2_ContainmentAction4__c)) {
                            SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL notTask8_4 = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL();
                            notTask8_4.MNGRP = 'QS-RM002';
                            notTask8_4.MNCOD = '3000';
                            notTask8_4.PARNR = 'YM';
                            notTask8_4.STTXT = request.Account__r.IFv2_ContainmentAction4__c;
                            notTask8_4.TDLINE = request.Account__r.IFv2_ContainmentActionLongText4__c;
                            string PARNR_substringed = string.valueof(request.Account__r.IFv2_Responsible4__c);
                            if(PARNR_substringed != NULL)
                            {
                                if(PARNR_substringed.length() > 12)
                                    PARNR_substringed = PARNR_substringed.substring(0, 12);
                            }
                            notTask8_4.PARNR = PARNR_substringed;
                            notTask8_4.PSTER = String.valueOf(request.Account__r.IFv2_EffectiveFrom4__c);
                            notTask8_4.PETER = String.valueOf(request.Account__r.IFv2_IntroducedOn4__c);
                            additionalContainmentActions.add(notTask8_4);
                        }
                        
                        if(!String.isBlank(request.Account__r.IFv2_ContainmentAction5__c)) {
                            SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL notTask8_5 = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL();
                            notTask8_5.MNGRP = 'QS-RM002';
                            notTask8_5.MNCOD = '3000';
                            notTask8_5.PARNR = 'YM';
                            notTask8_5.STTXT = request.Account__r.IFv2_ContainmentAction5__c;
                            notTask8_5.TDLINE = request.Account__r.IFv2_ContainmentActionLongText5__c;
                            string PARNR_substringed = string.valueof(request.Account__r.IFv2_Responsible5__c);
                           if(PARNR_substringed != NULL)
                            {
                                if(PARNR_substringed.length() > 12)
                                    PARNR_substringed = PARNR_substringed.substring(0, 12);
                            }
                            notTask8_5.PARNR = PARNR_substringed;
                            notTask8_5.PSTER = String.valueOf(request.Account__r.IFv2_EffectiveFrom5__c);
                            notTask8_5.PETER = String.valueOf(request.Account__r.IFv2_IntroducedOn5__c);
                            additionalContainmentActions.add(notTask8_5);
                        }
                        // Additional Containment Actions END 
                        
                        
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL notTask9 = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL();
                        notTask9.MNGRP = 'QS-RM002';
                        notTask9.MNCOD = '0081';
                        notTask9.PARVW = 'YM';
                       string  PARNR_Substringed = string.valueOf(request.Account__r.IFv2_Responsiblefortrackingthequantities__c);
                        system.debug('PARNR_Substringed ='+PARNR_Substringed);
                        if(PARNR_Substringed != NULL && PARNR_Substringed.length() > 12)
                        PARNR_Substringed = PARNR_Substringed.substring(0, 12);
                        notTask9.PARNR = PARNR_Substringed;
                        notTask9.PSTER = request.Account__r.IFv2_QuantitiesDeadlinedescription__c;
                        
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL notTask10 = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL();
                        notTask10.MNGRP = 'QS-RM002';
                        notTask10.MNCOD = '0082';
                        if(String.isNotBlank(request.Remarks__c)) {
                            notTask10.TDLINE = request.Remarks__c.stripHtmlTags();
                        }
                        
                        /***Commented after checking code in UAT ****/
                        //User_Select__c // Validator
                        //SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL notTask11 = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL();
                        //notTask11.MNGRP = 'QS-RM002';
                        //notTask11.MNCOD = '0101';
                        //notTask11.PARVW = 'YM';
                        //notTask11.MATXT = request.Approver2__r.NT_User__c;
                        
                        //First Approver as approver from 5/6
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL notTask12 = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL();
                        notTask12.MNGRP = 'QS-RM002';
                        notTask12.MNCOD = '0100';
                        notTask12.PARVW = 'YM';
                        notTask12.MATXT = request.Approver23__r.NT_User__c; //Updted after comparing code from UAT
                        
                        // APPROVAL HISTORy
                        ProcessInstance reqApprovalProcess = requestIdToProcessInstanceMAP.get(request.Id);
                        //holds Approval process notification tasks
                        LIST<SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL> approvalProcessNotificationTasks = new LIST<SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL>();
                        //holds process instance steps
                        LIST<ProcessInstanceStep> reqApprovalProcessSteps = new LIST<ProcessInstanceStep>();
                        for(ProcessInstanceStep pis : processInstaceStepLIST) {
                            if(pis.ProcessInstanceId == reqApprovalProcess.Id) {
                                SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL task = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL();
                                task.MNGRP = 'QS-RM002';
                                task.MNCOD = '0101';
                                task.STTXT = 'MAER MERF';
                                task.PARVW = 'YM';
                                string PARNR_substringed1 = string.valueOf(actorMAP.get(pis.ActorId).Department);
                                if(PARNR_substringed1 != NULL)
                                { 
                                    if(PARNR_substringed1.length() >12)
                                    PARNR_substringed1 = PARNR_substringed1.substring(0, 12);
                                }
                                task.PARNR = PARNR_substringed1;
                                task.MATXT = actorMAP.get(pis.ActorId).NT_User__c;//'BLN3SI'; //2HARDCODE
                                
                                //Commented to restrict the size to 132 chars/ commented after checking code in UAT
                                //task.TDLINE = 'Action: \nApprover Id: '+pis.ActorId+'\nApprover Name: '+pis.Actor.Name+'\nAssignee Id: '+pis.OriginalActorId+'\nAssignee Name: '+pis.OriginalActor.Name+'\nApprover Time: '+pis.CreatedDate+'\nComments: '+pis.Comments;
                                
                                /**Added after checking code in UAT****/
                                String tdlineText = 'Approver Name: '+pis.Actor.Name+'\nAssignee Name: '+pis.OriginalActor.Name+'\nApprover Time: '+pis.CreatedDate+'\nComments: '+pis.Comments;
                                Integer maxSize = 132;
                                if(tdlineText.length() > maxSize) {
                                    tdlineText = tdlineText.substring(0, maxSize);
                                }
                                
                                task.TDLINE = tdlineText;
                                approvalProcessNotificationTasks.add(task);
                            }
                        }
                        Boolean someBoolValue = false;
                        
                        if (request.SAPInstance__c == 'PSI') {
                            someBoolValue = true;
                        } else {
                            someBoolValue = false;
                        }
                        
                        
                        //method for callout
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.HTTP_Basic stub = new SG_WF_WS_Sap_Con_CreateNotif_NEW.HTTP_Basic(someBoolValue);
                        stub.timeout_x = 60000;
                        stub.inputHttpHeaders_x = httpHeaders;
                        
                        //Lists preparation for call
                        LIST<SG_WF_WS_Sap_Con_CreateNotif_NEW.CONCESSION_NOTIF_HEADER_LTXT> notHeaderLtLIST = new SG_WF_WS_Sap_Con_CreateNotif_NEW.CONCESSION_NOTIF_HEADER_LTXT[] {notificationHeaderLongText};
                            
                            LIST<SG_WF_WS_Sap_Con_CreateNotif_NEW.NotificationItem_Tabl> notItemLIST = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NotificationItem_Tabl[] {notificationItem1};
                                
                                LIST<SG_WF_WS_Sap_Con_CreateNotif_NEW.ZYT2_NOTIFICATION_CAUSE_TABL> notCauseLIST = new LIST<SG_WF_WS_Sap_Con_CreateNotif_NEW.ZYT2_NOTIFICATION_CAUSE_TABL>();
                        
                        LIST<SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL> notTaskLIST = new SG_WF_WS_Sap_Con_CreateNotif_NEW.NOTIFICATION_TASK_TABL[] {
                            notTask1,
                                notTask2,
                                notTask3,
                                notTask4,
                                notTask5,
                                notTask6,
                                notTask7
                                };
                                    
                                    If(request.Full8Dreportnecessary__c == 'No') {
                                        notTaskList.add(notTask8);
                                    }      
                        else if (request.Full8Dreportnecessary__c == 'Yes') {
                            notificationHeader.Q8_IQIS = request.X8Dreportno__c;
                        }
                        notTaskList.add(notTask9);
                        notTaskList.add(notTask10);                                    
                        if(!additionalContainmentActions.isEmpty()) {
                            notTaskList.addAll(additionalContainmentActions);
                        }
                        notTaskList.addAll(approvalProcessNotificationTasks);
                        
                        notTaskList.add(notTask12);
                        
                        //Method to store the notification response
                        SG_WF_WS_Sap_Con_CreateNotif_NEW.ZYT2_CONCESSION_CREATE_INRES response = stub.ConcessionCreate_IN(notificationHeader,addMaterialsForCall,notHeaderLtLIST,notItemLIST,notCauseLIST,notPartnerLIST,notTaskLIST);
                        String updateResult = 'Response: ';
                        String qsNotifications = '';
                        String qiNotifications = '';
                        System.debug('concession>res>'+response);
                        
                        if(response != NULL) {
                            System.debug('inside response!=null>response>'+response);                          
                            if(response.ConcessionResp != null && !response.ConcessionResp.isEmpty()) {
                                for(SG_WF_WS_Sap_Con_CreateNotif_NEW.CONCESSION_TEXT ct : response.ConcessionResp) {
                                    String notificationIds = 'QI_QMNUM: '+ ct.QI_QMNUM + ', QS_QMNUM: ' + ct.QS_QMNUM + ';';
                                    updateResult += notificationIds;
                                    qsNotifications = ct.QS_QMNUM+';';
                                    qiNotifications = ct.QI_QMNUM+';';
                                }
                                qiNotifications = qiNotifications.removeEnd(';');
                                qsNotifications = qsNotifications.removeEnd(';');
                            }
                            else
                            {   
                                System.debug('Concession>ConcessionLogItem>'+response.Log.ConcessionLogItem);
                                String error_message= (response.Log.ConcessionLogItem[0].Message);
                                System.debug('Error message>'+error_message);
                                request.ConcessionErrorResponse__c=error_message;
                                errorRecords.add(request);
                                System.debug('Consession>insde else >success');
                            }
                                
                            if(response != null) {
                                if(response.Log != null && response.Log.ConcessionLogItem != null && !response.Log.ConcessionLogItem.isEmpty()) {
                                    for(SG_WF_WS_Sap_Con_CreateNotif_NEW.ZT2_WSRNOTIF_LOG_ITEM cli : response.Log.ConcessionLogItem) {
                                        updateResult += cli.Type_x + ' ' + cli.Id + ' ' + cli.Number_x + ' ' + cli.Message + ' ' + cli.MessageV1 + ' ' + cli.MessageV2 + ' ' + cli.MessageV3 + ' ' + cli.MessageV4;
                                    }
                                }
                            }
                        }
                       
                        //updating Account details from the responce
                        Account existingAccount = new Account(Id= request.Account__c);
                        
                        if(String.isNotBlank(qsNotifications)) {
                            String notificationId = qsNotifications.contains(';') ? qsNotifications.split(';')[0] : qsNotifications;
                            existingAccount.IFv2_NotificationNo__c = notificationId;
                            reqIdToNotificationIdMAP.put(request.Id, notificationId);
                        }
                        
                        existingAccount.IFv2_SAPUPDATERESULT__c = updateResult;
                        existingAccount.IFv2_QINotifications__c =  qiNotifications;
                        existingAccount.IFv2_QSNotifications__c = qsNotifications;
                        
                        UpdateAccountLIST.add(existingAccount);
                        if(String.isNotBlank( existingAccount.IFv2_NotificationNo__c)) {
                            reqIdLIST.add(request.Id);
                        }
                    }
                }
                
                //update account records
                if(!UpdateAccountLIST.isEmpty()) {
                    IFv2_DmlController.updateAccountRecords(UpdateAccountLIST);
                }
                if(!errorRecords.isEmpty())
                {
                    System.debug('Consession>inside errorRecords not empty>'+errorRecords);
                    update(errorRecords);
                }
            }
        }
    }
}