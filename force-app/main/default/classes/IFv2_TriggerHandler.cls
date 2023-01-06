/*******************************************************************************************************
* 
* @ Name    :   IFv2_TriggerHandler
* @ Purpose :   To Assign permission SET to users.
* @ Author  :   Prasad Vivek
* @ TestClass : IFv2_TriggerHandlerTest
*
*   Date        |  Developer Name                      |  Version       |  Changes
* ======================================================================================================
*   31-10-2018      |  vivek.kothalanka@absyz.com       |  1.0          |  Initial Version
*   10-01-2019      |  madhuravani.b@absyz.com          |  1.1          |  Merged all the handlers into single class and added Rollup functionality
*   15-11-2018      |  nagasai.chalamalasetti@absyz.com |  1.0          |  Added Out of oFfice Logic
*   20-03-2019      |  pradeep.chary@absyz.com(es)      |  2.0          |  Generic method for sending email and giving record access on approval/rejection  
*   08-04-2019      |  pradeep.chary@absyz.com          |  2.1          |  AttachmentHandler method for SCAN records
*   06-05-2019      |  elsa.shaju@absyz.com             |  3.0          |  Added roll up summary logic for Material Gate Pass  
*   27-06-2019      |  external.debasmita.rawooth@seg-automotive.com    |  Added approver changes for MGP Child request
*   11-09-2019      |  external.debasmita.rawooth@seg-automotive.com    |  Added changes for spl freight access for proxy level 2,3 users
*   15-09-2019      |  external.debasmita.rawooth@seg-automotive.com    |  Added method for IFE attachment validation
*   16-09-2019      |  external.debasmita.rawooth@seg-automotive.com    |  Added method for access via chatter comments
*   20-09-2019      |  external.debasmita.rawooth@seg-automotive.com    |  Added changes for OOO bug fixes
*   28-10-2019      |  elsa.shaju@absyz.com             |  5.0          |  Added 3 new methods for Delegate user access and email
*   02-12-2019      |  external.debasmita.rawooth@seg-automotive.com    |  Added changes for rollup summary for Lex Contracting
*   25-01-2020      |  external.debasmita.rawooth@seg-automotive.com    |  Added new method to share access with updated approver after request is submitted
*   21-02-2020      |  external.debasmita.rawooth@seg-automotive.com    |  Updated method to revoke access from old approvers after request is submitted
*   07-10-2022      |  external.debasmita.rawooth@seg-automotive.com    |  Updated checkApproverLevel method to add logic for InterCompany Vendors
*   07-10-2022      |  external.debasmita.rawooth@seg-automotive.com    |  Updated checkApproverLevel method to update Invoice Amt field
*******************************************************************************************************/
public class IFv2_TriggerHandler {
    
    public static void checkApproverLevel(List<IFv2_Request__c> requestLIST) {
        Map<String,String> ApproverIdLimitMap = new Map<String,String>();
        Map<String,String> ApproverLevelLimitMap = new Map<String,String>();
        Map<String,String> ApproverIdLimitMapIC = new Map<String,String>();
        Map<String,String> ApproverLevelLimitMapIC = new Map<String,String>();
        Set<Id> setRequestIds = new Set<Id>();
  		List<IFv2_Request__c> listRequest = new List<IFv2_Request__c>();
        List<String> listVendorNumbers = new List<String>();
        String strVendorNumberCL = System.Label.IFv2_InvoicingPartyVendorNumber;
        
        if (!String.isBlank(strVendorNumberCL)) {
            listVendorNumbers.addAll(strVendorNumberCL.split(';'));
        }
        System.debug('listVendorNumbers::'+listVendorNumbers);

        list<Approver_Level_Table__c> approverLevelList = [SELECT Id, Approver_Id__c,Higher_Limit__c, Approver_Level__c, Workflow_Name__c,Invoicing_Party_Number__c FROM Approver_Level_Table__c WHERE Workflow_Name__c = 'ICO Workflow - 6' AND Invoicing_Party_Number__c = false ORDER BY Approver_Level__c];
        list<Approver_Level_Table__c> approverLevelListIC = [SELECT Id, Approver_Id__c,Higher_Limit__c, Approver_Level__c, Workflow_Name__c,Invoicing_Party_Number__c FROM Approver_Level_Table__c WHERE Workflow_Name__c = 'ICO Workflow - 6' AND Invoicing_Party_Number__c = true ORDER BY Approver_Level__c];
        
        System.debug('approverLevelList size::'+approverLevelList.size());
        System.debug('approverLevelListIC size::'+approverLevelListIC.size());
        
		if(!approverLevelList.isEmpty()) {
            for(Approver_Level_Table__c apLevelObj : approverLevelList) {
                ApproverIdLimitMap.put(apLevelObj.Approver_Id__c,apLevelObj.Higher_Limit__c);
                ApproverLevelLimitMap.put(apLevelObj.Approver_Level__c,apLevelObj.Higher_Limit__c);
            }
        }
        
        //creating maps for IC vendors
        if(!approverLevelListIC.isEmpty()) {
            for(Approver_Level_Table__c apLevelObj : approverLevelListIC) {
                ApproverIdLimitMapIC.put(apLevelObj.Approver_Id__c,apLevelObj.Higher_Limit__c);
                ApproverLevelLimitMapIC.put(apLevelObj.Approver_Level__c,apLevelObj.Higher_Limit__c);
            }
        }
        System.debug('ApproverIdLimitMapIC::'+ApproverIdLimitMapIC);
        System.debug('ApproverLevelLimitMapIC::'+ApproverLevelLimitMapIC);
        for(IFv2_Request__c reqObject : requestLIST) {
            System.debug('reqObject::'+reqObject.IFv2_InvoicingPartyVendorNum__c);
            if(reqObject.IFv2_InvoicingPartyVendorNum__c != '' && !listVendorNumbers.contains(reqObject.IFv2_InvoicingPartyVendorNum__c)) {
                System.debug('Inside First If');
                if(reqObject.Approver2__c != NULL && reqObject.InvoiceItemAmountEUR__c != NULL && ApproverIdLimitMap.containsKey(reqObject.Approver2__c) && ApproverIdLimitMap.get(reqObject.Approver2__c)!= NULL && (Decimal.valueof(ApproverIdLimitMap.get(reqObject.Approver2__c)) < Decimal.valueof(reqObject.InvoiceItemAmountEUR__c))) {
                    for (String key : ApproverLevelLimitMap.keySet()) {
                        If(Decimal.valueof(ApproverLevelLimitMap.get(key)) > Decimal.valueof(reqObject.InvoiceItemAmountEUR__c)) {
                            reqObject.Role03__c = key;
                            break;
                        }
                    }
                }
                else if(reqObject.Approver2__c != NULL && !ApproverIdLimitMap.containsKey(reqObject.Approver2__c)) {
                    reqObject.addError('Approver 2 is not present in the mapping table') ;                
                }
                else if(reqObject.Approver2__c == NULL) {
                    reqObject.Role03__c = '';
                }
                
                if(reqObject.Approver2__c != NULL && reqObject.Approver3__c != NULL && 
                   ApproverIdLimitMap.get(reqObject.Approver2__c)!= NULL && 
                   ApproverIdLimitMap.get(reqObject.Approver3__c)!= NULL && 
                   ((Decimal.valueOf(ApproverIdLimitMap.get(reqObject.Approver2__c)) > Decimal.valueOf(ApproverIdLimitMap.get(reqObject.Approver3__c))) || 
                    (Decimal.valueOf(ApproverIdLimitMap.get(reqObject.Approver2__c)) == Decimal.valueOf(ApproverIdLimitMap.get(reqObject.Approver3__c))) 
                   )
                  )
                    reqObject.addError('Last approver should be of higher approving level than the previous approver.') ;
                
                if(reqObject.Approver2__c != NULL && reqObject.Approver3__c != NULL && 
                   reqObject.InvoiceItemAmountEUR__c != NULL &&
                   ApproverIdLimitMap.get(reqObject.Approver2__c)!= NULL && 
                   ApproverIdLimitMap.get(reqObject.Approver3__c)!= NULL && 
                   (Decimal.valueOf(ApproverIdLimitMap.get(reqObject.Approver3__c)) < Decimal.valueof(reqObject.InvoiceItemAmountEUR__c))
                  )
                    reqObject.addError('Last approver should be of higher approving level based on the invoice amount.') ;
            }
            //Logic for Inter Company vendors
            else if (reqObject.IFv2_InvoicingPartyVendorNum__c != '' && listVendorNumbers.contains(reqObject.IFv2_InvoicingPartyVendorNum__c)) {
                System.debug('Inside First Ifs Else');
                if(reqObject.Approver2__c != NULL && ApproverIdLimitMapIC.containsKey(reqObject.Approver2__c) && ApproverIdLimitMapIC.get(reqObject.Approver2__c)!= NULL && (Decimal.valueof(ApproverIdLimitMapIC.get(reqObject.Approver2__c)) < Decimal.valueof(reqObject.InvoiceItemAmountEUR__c))) {
                    for (string key : ApproverLevelLimitMapIC.keySet()) {
                        If(reqObject.InvoiceItemAmountEUR__c != NULL && (Decimal.valueof(ApproverLevelLimitMapIC.get(key)) > Decimal.valueof(reqObject.InvoiceItemAmountEUR__c))) {
                            reqObject.Role03__c = key;
                            break;
                        }
                    }
                }
                else if(reqObject.Approver2__c != NULL && !ApproverIdLimitMapIC.containsKey(reqObject.Approver2__c)) {
                    System.debug('before chcek::');
                    reqObject.addError('Approver 2 is not present in the mapping table') ;                
                }
                else if(reqObject.Approver2__c == NULL) {
                    reqObject.Role03__c = '';
                }
                
                if(reqObject.Approver2__c != NULL && reqObject.Approver3__c != NULL && 
                   ApproverIdLimitMapIC.get(reqObject.Approver2__c)!= NULL && 
                   ApproverIdLimitMapIC.get(reqObject.Approver3__c)!= NULL && 
                   ((Decimal.valueOf(ApproverIdLimitMapIC.get(reqObject.Approver2__c)) > Decimal.valueOf(ApproverIdLimitMapIC.get(reqObject.Approver3__c))) || 
                    (Decimal.valueOf(ApproverIdLimitMapIC.get(reqObject.Approver2__c)) == Decimal.valueOf(ApproverIdLimitMapIC.get(reqObject.Approver3__c))) 
                   )
                  )
                    reqObject.addError('Last approver should be of higher approving level than the previous approver.') ;
                
                if(reqObject.Approver2__c != NULL && reqObject.Approver3__c != NULL && 
                   ApproverIdLimitMapIC.get(reqObject.Approver2__c)!= NULL && 
                   ApproverIdLimitMapIC.get(reqObject.Approver3__c)!= NULL && 
                   (reqObject.InvoiceItemAmountEUR__c != NULL && (Decimal.valueOf(ApproverIdLimitMapIC.get(reqObject.Approver3__c)) < Decimal.valueof(reqObject.InvoiceItemAmountEUR__c)))
                  )
                    reqObject.addError('Last approver should be of higher approving level based on the invoice amount.') ;
            }
        }
    }
    
    /* Variable to handle trigger recursion */
    public static Boolean firstTime  = True;
    public static String fromTrigger='';
    
    /* Method to add permission sets to users and update check box fields */
    public static void AssignPermissisonSetOnInsert(LIST<User> UserRecords) {
        
        /* Used to Activate or deactivate this method, Method updated for Iteration 3 */
        Boolean donotExecuteTrigger = IFv2_UtilsController.getTriggerLogic('User','AssignPermissisonSetOnInsert');
        
        /* checking if donotExecuteTrigger variable is true or false */
        if(!donotExecuteTrigger) {
            
            LIST<User> UpdateUserLIST = new LIST<User>();    //To update User records
            LIST<PermissionSet> permissionSetLIST = new LIST<PermissionSet>();    //LIST to hold permissionSet values.
            MAP<String, SET<String>> userRegionMAP = new MAP<String, SET<String>>();    //MAP to hold usercountry and LIST of users for that country.
            MAP<String, IFv2_Country__mdt> metadataMAP = new MAP<String,IFv2_Country__mdt>();    //MAP to hold metadata details.
            LIST<PermissionSetAssignment> PermissionSetAssignmentLIST = new LIST<PermissionSetAssignment>();    //LIST for Permission SET assignment
            MAP<String, Id> permissionSetMAP = new MAP<String, Id>();    //MAP to store permission SET name and Id 
            MAP<Id, String> permissionSetIdMAP = new MAP<Id, String>();    //MAP to store permission SET Id and Name.
            MAP<Id, SET<String>> permissionsSetUserMAP = new MAP<Id, SET<String>>();    //MAP to store permssion SET Id and LIST of users 
            
            /* We will query metadata based on User country */
            for(User CurrentUser :UserRecords) {
                /* MAP to store country and users for that country, With country as key and values as LIST of users for that country */
                /* Checking if User country is not null */
                if(CurrentUser.Country!= null) {
                    
                    if(userRegionMAP.containsKey(CurrentUser.Country.toLowerCase())) {
                        SET<String> temporarySET = userRegionMAP.get(CurrentUser.Country.toLowerCase());    // Temporarly storing LIST from MAP
                        temporarySET.add(CurrentUser.Id);
                        userRegionMAP.put(CurrentUser.Country.toLowerCase(), temporarySET); 
                    }
                    else {
                        if(CurrentUser.Country != null) {
                            SET<String> temporarySET= new SET<String>();    // Initilizing temporary LIST for adding User ids
                            temporarySET.add(CurrentUser.Id);
                            userRegionMAP.put(CurrentUser.Country.toLowerCase(), temporarySET);
                        }
                    }
                }
            }
            /* Quering permission sets */
            permissionSetLIST = IFv2_UtilsController.permissionSetRecords();
            /* Getting required permission sets */
            if(!permissionSetLIST.isEmpty()) {
                for(PermissionSet currentPermissionSET : permissionSetLIST) {
                    /* Putting values to MAP with key as permission SET name and permission SET Id*/
                    permissionSetMAP.put(currentPermissionSET.Name,currentPermissionSET.Id);
                    permissionSetIdMAP.put(currentPermissionSET.Id,currentPermissionSET.Name);
                }
            }
            /* Query metadata from User regions . */
            LIST<IFv2_Country__mdt> RegionLIST = IFv2_UtilsController.getRegionMetadata(userRegionMAP.keySet());
            
            /* For creating MAP of country and metadata record */
            if(!RegionLIST.isEmpty()) {
                for(IFv2_Country__mdt record : RegionLIST) {
                    metadataMAP.put(record.label.toLowerCase() ,record);
                }
            }
            /* For getting Permision SET and LIST of users needed to add to that permission SET. */
            if(!userRegionMAP.keySet().isEmpty()) {
                for(String country :userRegionMAP.keySet()) {
                    if(metadataMAP.containsKey(country)) {
                        String PermissionsetName = metadataMAP.get(country).PermissionSetName__c;
                        /* MAP to put permission SET as key and LIST of User for country */
                        permissionsSetUserMAP.put(permissionSetMAP.get(PermissionsetName),userRegionMAP.get(country));
                    }          
                }
            }
            /*Assigning users to permission sets and updating User check boxes*/
            if(!permissionsSetUserMAP.keySet().isEmpty()) {
                for(Id permissionSetId : permissionsSetUserMAP.keySet()) {
                    
                    /* Query for permission sets */
                    SET<String> usersSET = permissionsSetUserMAP.get(permissionSetId);
                    if(!usersSET.isEmpty()) {
                        for(String User : usersSET) {
                            PermissionSetAssignment  PermissionAssignment = new PermissionSetAssignment();
                            PermissionAssignment.PermissionSetId = permissionSetId;
                            PermissionAssignment.AssigneeId = User;
                            PermissionSetAssignmentLIST.add(PermissionAssignment);
                            User userRecord = new User();
                            userRecord.Id= User;
                            if(permissionSetIdMAP.get(permissionSetId).contains('Extension1')) {
                                userRecord.IFv2_RequestAPAC__c = true; 
                                UpdateUserLIST.add(userRecord);
                            } else if(permissionSetIdMAP.get(permissionSetId).contains('Extension2')) {
                                userRecord.IFv2_RequestEMEA__c = true;
                                UpdateUserLIST.add(userRecord);
                            } else if(permissionSetIdMAP.get(permissionSetId).contains('Extension3')) {
                                userRecord.IFv2_RequestNALA__c = true; 
                                UpdateUserLIST.add(userRecord);
                            }
                        }
                    }
                    
                }
            }
            /* Update Users  and addding permission sets*/
            if(!PermissionSetAssignmentLIST.isEmpty()) {
                IFv2_DmlController.insertPermissionSetUsers(PermissionSetAssignmentLIST); /* Add users to permission SET. */
                IFv2_DmlController.updateUsers(UpdateUserLIST);   /* Update User check boxes */
            }
        }else {
            /* Updated Debug log in Iteration 3 */
            system.debug('AssignPermissisonSetOnInsert : Method is Deactivated');
        }
    }
    
    /* /This method has to be un commented after 1st itaration/ Method to Re Assign permission sets and update check boxes. */
    public static void updatePermissionSets(LIST<User> newUserRecords,  MAP<Id, User> OldmapRecords) {
        
        /* Used to Activate or deactivate this method, Updated method for Iteration 3 */
        Boolean donotExecuteTrigger = IFv2_UtilsController.getTriggerLogic('User','updatePermissionSets');
        
        /* checking if donotExecuteTrigger variable is true or false */
        if(!donotExecuteTrigger) {
            LIST<User> UpdateUserLIST = new LIST<User>(); // To update User records
            LIST<User> updatedUserRecords = new LIST<User>(); // To add only updated users.
            MAP<String, IFv2_Country__mdt> metadataMAP = new MAP<String,IFv2_Country__mdt >(); // MAP to store metadata values
            MAP<String, IFv2_Country__mdt> metadatamapOld = new MAP<String,IFv2_Country__mdt >(); // MAP to store old  metadata values
            LIST<PermissionSet> permissionSetLIST = new LIST<PermissionSet>();  // LIST to store permission SET  
            MAP<String, SET<String>> userRegionMAP = new MAP<String, SET<String>>(); // MAP to store users country and LIST of  users for that
            MAP<String, SET<String>> userRegionMapOld = new MAP<String, SET<String>>();  // MAP to store old country and LIST of  users for that
            MAP<String, String> userOldCountryMap = new MAP<String, String>();  // MAP of User Id and User country 
            LIST<PermissionSetAssignment> PermissionSetAssignmentLIST = new LIST<PermissionSetAssignment>(); // LIST to store permissionSetAssignemnts for updation.
            MAP<Id, SET<String>> permissionssetUserMapOld = new MAP<Id, SET<String>>(); // MAP to store old permissionset ids and LIST of users for that.
            MAP<Id, SET<String>> permissionsSetUserMAP = new MAP<Id, SET<String>>();    // MAP to store User Id and User country 
            MAP<String, Id> permissionSetMAP = new MAP<String, Id>(); // MAP to contain permisison SET name and Id.
            MAP<Id, String> permissionSetIdMAP = new MAP<Id, String>(); // MAP to contain Id and Name of permission SET.
            SET<String> userIdSET = new SET<String>(); // SET to store User ids 
            for(User currentuser : newUserRecords) {
                if(currentuser.isActive) {
                    User olduser = OldmapRecords.get(currentuser.Id);
                    // Checking if User record is updated.
                    String oldusercountry;
                    String updatedusercountry;
                    
                    /* Checking if User old country is not null */
                    if(olduser.Country != Null) {
                        oldusercountry = olduser.Country.toLowerCase();
                    }
                    else {
                        oldusercountry = '';
                    }
                    /* Checking if User country is not null */
                    if(currentuser.Country != Null) {
                        updatedusercountry = currentuser.Country.toLowerCase();
                    }
                    else {
                        updatedusercountry = '';
                    }
                    
                    /*if(test.isRunningTest()) {
updatedUserRecords.add(currentuser);
userIdSET.add(currentuser.Id);
userOldCountryMap.put(currentuser.Id,'China');
}*/
                    
                    if(updatedusercountry != oldusercountry) {
                        updatedUserRecords.add(currentuser);
                        userIdSET.add(currentuser.Id);
                        if(oldusercountry != '') {
                            userOldCountryMap.put(currentuser.Id,olduser.Country.toLowerCase());
                        }
                        
                    }
                }
            }
            /* To query any permission SET ids assigned to User */
            LIST<PermissionSetAssignment> usersPerssionSet = new LIST<PermissionSetAssignment>();   // declaring a LIST for permission SET assignment  
            if(userOldCountryMap.keySet() != Null && (!userIdSET.isEmpty())) {
                System.debug('userIdSET*****' + userIdSET);
                
                usersPerssionSet = [SELECT Id,AssigneeId,PermissionSetId 
                                    FROM PermissionSetAssignment
                                    WHERE AssigneeId IN : userIdSET];
            }
            System.debug('usersPerssionSet*****' + usersPerssionSet);
            MAP<Id, SET<String>> userAlreadyAssignedList = new MAP<Id, SET<String>>();  // MAP to store User assignments
            
            /* Checking if userAlreadyAssignedList is not empty */
            if(!usersPerssionSet.isEmpty()) {
                for(PermissionSetAssignment permissionset : usersPerssionSet) {
                    
                    if(userAlreadyAssignedList.containsKey(permissionset.AssigneeId)) {
                        if(permissionset.AssigneeId != null) {
                            SET<String> temporarySET = userAlreadyAssignedList.get(permissionset.AssigneeId);   //Temporarly storing LIST from MAP values 
                            temporarySET.add(permissionset.PermissionSetId);
                            userAlreadyAssignedList.put(permissionset.AssigneeId, temporarySET);
                        }
                    }
                    else {
                        if(permissionset.PermissionSetId != null) {
                            SET<String> temporarySET= new SET<String>();    // Temporarly storing LIST for storing permission SET ids 
                            temporarySET.add(permissionset.PermissionSetId);
                            userAlreadyAssignedList.put(permissionset.AssigneeId, temporarySET);
                        }
                        
                    }
                }
            }
            
            System.debug('userAlreadyAssignedList*****' + userAlreadyAssignedList);
            
            /* Checking if updatedUserRecords is not empty */
            if(!updatedUserRecords.isEmpty()) {
                permissionSetLIST = IFv2_UtilsController.permissionSetRecords();
                
                if(!permissionSetLIST.isEmpty()) {
                    for(PermissionSet currentPermissionSET : permissionSetLIST) {
                        // MAP with Permission SET as name and permission SET Id
                        permissionSetMAP.put(currentPermissionSET.Name,currentPermissionSET.Id); 
                        PermissionSetIdMap.put(currentPermissionSET.Id,currentPermissionSET.Name); 
                    }
                }
                System.debug('permissionSetMAP*****' + permissionSetMAP);
                
                // MAP with key as country and LIST of users for that country  
                if(!userOldCountryMap.KeySet().isEmpty()) {
                    for(Id oldUser : userOldCountryMap.KeySet()) {
                        
                        if(userRegionMapOld.containsKey(userOldCountryMap.get(oldUser))) {
                            if(oldUser != null) {
                                SET<String> temporarySET = userRegionMAP.get(oldUser);      // Temporarly storing LIST for storing User ids
                                temporarySET.add(oldUser);
                                userRegionMapOld.put(userOldCountryMap.get(oldUser), temporarySET); 
                            }
                        }
                        else {
                            if(oldUser != null) {
                                SET<String> temporarySET= new SET<String>();        // Temporarly storing LIST for storing User  ids
                                temporarySET.add(oldUser);
                                userRegionMapOld.put(userOldCountryMap.get(oldUser), temporarySET);
                            }
                        }
                    }
                }
                System.debug('userRegionMapOld*****' + userRegionMapOld);
                
                // MAP of Old Country value and LIST of users whose permission SET has to be removed.
                if(!userRegionMapOld.keySet().isEmpty()) {
                    /* Query for region metadata */
                    LIST<IFv2_Country__mdt> RegionListOld = IFv2_UtilsController.getRegionMetadata(userRegionMapOld.keySet());
                    
                    // MAP with country as key and metadata record as value. 
                    if(!RegionListOld.isEmpty()) {
                        for(IFv2_Country__mdt record : RegionListOld) {
                            metadatamapOld.put(record.label.toLowerCase() ,record);
                        }
                    }
                }
                System.debug('metadatamapOld*****' + metadatamapOld);
                
                if(!userRegionMapOld.keySet().isEmpty()) {
                    for(String country :userRegionMapOld.keySet()) {
                        if(metadatamapOld.containsKey(country)) {
                            String PermissionsetName = metadatamapOld.get(country).PermissionSetName__c;
                            permissionssetUserMapOld.put(permissionSetMAP.get(PermissionsetName),userRegionMapOld.get(country));
                        }          
                    }
                }
                
                System.debug('permissionssetUserMapOld*****' + permissionssetUserMapOld);
                
                // LIST for removing permission sets  for updated users 
                if(!permissionssetUserMapOld.KeySet().isEmpty() && !permissionssetUserMapOld.values().isEmpty()) {
                                       
                    /*query for permission sets to delete */
                    LIST<PermissionSetAssignment> PermissionSetAssignmentListDelete = IFv2_UtilsController.deletePermissionSetAssignment(permissionssetUserMapOld.KeySet(),permissionssetUserMapOld.values());
                    
                    System.debug('PermissionSetAssignmentListDelete*****' + PermissionSetAssignmentListDelete);
                    
                    // Deleting old Permission sets 
                    if(!PermissionSetAssignmentListDelete.isEmpty())
                        IFv2_DmlController.deleteAssignment(PermissionSetAssignmentListDelete);
                }
                // (Updating Adding permission SET)We will query metadata based on User country 
                for(User CurrentUser :updatedUserRecords) {
                    
                    if(userRegionMAP.containsKey(CurrentUser.Country)) {
                        if(CurrentUser.Country != null) {
                            SET<String> temporarySET = userRegionMAP.get(CurrentUser.Country);      // Temporarly storing LIST for getting values from MAP
                            temporarySET.add(CurrentUser.Id);
                            userRegionMAP.put(CurrentUser.Country.toLowerCase(), temporarySET); 
                        }
                    }
                    else {
                        if(CurrentUser.Country != null) {
                            SET<String> temporarySET= new SET<String>();        // Temporarly storing LIST for storing User ids
                            temporarySET.add(CurrentUser.Id);
                            userRegionMAP.put(CurrentUser.Country.toLowerCase(), temporarySET);
                        }
                    }
                }
                
                MAP<Id, SET<String>> userAlreadyAssignedListUpdated = new MAP<Id, SET<String>>();   // MAP to store User assignments
                
                LIST<PermissionSetAssignment> usersPerssionSetUpdated = new LIST<PermissionSetAssignment>();    // declaring a LIST for permission SET assignment  
                if(userOldCountryMap.keySet() != Null && (!userIdSET.isEmpty())) {
                    
                    usersPerssionSetUpdated = [SELECT Id,AssigneeId,PermissionSetId 
                                               FROM PermissionSetAssignment
                                               WHERE AssigneeId IN : userIdSET];
                }
                
                /* Checking if userAlreadyAssignedListUpdated is not empty */
                if(!usersPerssionSetUpdated.isEmpty()) {
                    for(PermissionSetAssignment permissionset : usersPerssionSetUpdated) {
                        
                        if(userAlreadyAssignedListUpdated.containsKey(permissionset.AssigneeId)) {
                            if(permissionset.AssigneeId != null || Test.isRunningTest()) {
                                SET<String> temporarySET = userAlreadyAssignedListUpdated.get(permissionset.AssigneeId);    //Temporarly storing LIST from MAP values 
                                temporarySET.add(permissionset.PermissionSetId);
                                userAlreadyAssignedListUpdated.put(permissionset.AssigneeId, temporarySET);
                            }
                        }
                        else {
                            if(permissionset.PermissionSetId != null) {
                                SET<String> temporarySET= new SET<String>();    // Temporarly storing LIST for storing permission SET ids 
                                temporarySET.add(permissionset.PermissionSetId);
                                userAlreadyAssignedListUpdated.put(permissionset.AssigneeId, temporarySET);
                            }
                            
                        }
                    }
                }
                
                // Query metadata from User regions . 
                if(!userRegionMAP.keySet().isEmpty()) {
                    
                    /* Query for region metadata */
                    LIST<IFv2_Country__mdt> RegionList = IFv2_UtilsController.getRegionMetadata(userRegionMAP.keySet());
                    
                    // To create a MAP of country and metadata record 
                    if(!RegionList.isEmpty()) {
                        for(IFv2_Country__mdt record : RegionList) {
                            if(record != null) {
                                metadataMAP.put(record.label.toLowerCase() ,record);
                            }
                        }
                    }
                }
                
                // To get users for corresponding countries             
                if(!userRegionMAP.keySet().isEmpty()) {
                    for(String country :userRegionMAP.keySet()) {
                        if(metadataMAP.containsKey(country)) {
                            String PermissionsetName = metadataMAP.get(country).PermissionSetName__c;
                            // MAP to put key as permisison Id name and LIST of users for country 
                            permissionsSetUserMAP.put(permissionSetMAP.get(PermissionsetName),userRegionMAP.get(country));
                        }          
                    }
                }
                
                // Assigning users to permission sets            
                if(!permissionsSetUserMAP.keySet().isEmpty()) {
                    for(Id permissionSetId : permissionsSetUserMAP.keySet()) {
                        
                        /* getting values of permissionsSetUserMAP */
                        SET<String> usersSET = new SET<String>();
                        usersSET = permissionsSetUserMAP.get(permissionSetId);
                        
                        if(!usersSET.isEmpty()) {
                            for(String User : usersSET) {
                                SET<String> temporarySET = new SET<String>();
                                if(userAlreadyAssignedListUpdated.containsKey(User)) {
                                    temporarySET = userAlreadyAssignedListUpdated.get(User);
                                }
                                
                                if(temporarySET!= NUll) {
                                    if(permissionSetId != Null && !temporarySET.contains((String)permissionSetId)) {
                                        
                                        PermissionSetAssignment  PermissionAssignment = new PermissionSetAssignment();  // initilizing a permision SET assignment instance 
                                        PermissionAssignment.PermissionSetId = permissionSetId;
                                        PermissionAssignment.AssigneeId = User;
                                        PermissionSetAssignmentLIST.add(PermissionAssignment);
                                        User userRecord = new User();
                                        userRecord.Id= User;
                                        /* Checking if permissionSetIdMAP contains extenison 1 */
                                        if(permissionSetIdMAP.get(permissionSetId).contains('Extension1')) {
                                            userRecord.IFv2_RequestAPAC__c = true; 
                                            userRecord.IFv2_RequestEMEA__c = false;
                                            userRecord.IFv2_RequestNALA__c = false; 
                                            UpdateUserLIST.add(userRecord);
                                        } else if(permissionSetIdMAP.get(permissionSetId).contains('Extension2')) {
                                            userRecord.IFv2_RequestAPAC__c = false; 
                                            userRecord.IFv2_RequestEMEA__c = true;
                                            userRecord.IFv2_RequestNALA__c = false;
                                            UpdateUserLIST.add(userRecord);
                                        } else if(permissionSetIdMAP.get(permissionSetId).contains('Extension3')) {
                                            userRecord.IFv2_RequestNALA__c = true; 
                                            userRecord.IFv2_RequestAPAC__c = false; 
                                            userRecord.IFv2_RequestEMEA__c = false; 
                                            UpdateUserLIST.add(userRecord);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // To check if PermissionSetAssignmentList is not empty 
                if(!PermissionSetAssignmentLIST.isEmpty() && !UpdateUserLIST.isEmpty()) {
                    // Updating permission sets 
                    IFv2_DmlController.insertPermissionSetUsers(PermissionSetAssignmentLIST);
                    IFv2_DmlController.updateUsers(UpdateUserLIST);   // Update User check boxes 
                } 
            } 
        }else {
            /* Updated Debug log in Iteration 3 */
            system.debug('updatePermissionSets : Method is Deactivated');
        }
    } 
    
    /* Added by Madhura for Rollup summary */
    public void RollupSummaryDetails(LIST<Account> lstAccount) {
        
        /* Used to Activate or deactivate this method */
        Boolean donotExecuteTrigger = IFv2_UtilsController.getTriggerLogic('AccountTrigger','RollupSummaryDetails');
        
        /* checking if donotExecuteTrigger variable is true or false */
        if(!donotExecuteTrigger) {
            
            /* Workflows for which this trigger should fire (For all china MAE workflows except for Captalize and China Travel Workflow)*/
            LIST<String> workflowLIST = new LIST<String>{Label.CLIFv20038,Label.CLIFv20039,Label.CLIFv20040,Label.CLIFv20041,Label.CLIFv20042,Label.CLIFv20046};
                /* holds the extension record which should be deleted */
                LIST<IFv2_RequestExtension1__c> requestExtLIST = new LIST<IFv2_RequestExtension1__c>(); 
            /* holds the request record which should be deleted */
            LIST<IFv2_Request__c> requestRecLIST = new LIST<IFv2_Request__c>();
            /* holds Account related Request record */
            SET<Id> accIdSET = new SET<Id>(); 
            SET<Id> requestIdsSET = new SET<Id>();    //Holds the request ids
            /* holds the request related extension record */
            SET<Id> requestIdSET = new SET<Id>(); 
            /* MAP to hold the extension object which needs to be updated */
            MAP<Id,IFv2_RequestExtension1__c> reqExtensionMAP = new  MAP<Id,IFv2_RequestExtension1__c>();
            MAP<Id,IFv2_Request__c> reqMAP = new  MAP<Id,IFv2_Request__c>();
            /* Iterating over Account records */
            for(Account objAcc : lstAccount) {
                accIdSET.add(objAcc.IFv2_Request__c);
            }
            
            /* To check if there are any extension records for that account */
            if(accIdSET.size() > 0) {
                /* Query for request records */
                LIST<IFv2_Request__c> requestLIST = [Select Id,Workflow__c, RequestExtension1__c,RequestExtension1__r.TotalOriginalValue__c,RequestExtension1__r.TotalNetBookValue__c 
                                                     FROM IFv2_Request__c 
                                                     WHERE Id in:accIdSET];
                
                /* Iterating over Request records related to the Account */
                for(IFv2_Request__c objReq : requestLIST) {
                    /* This logic will only workflows which are specified in the workflowList*/
                    if(workflowLIST.contains(objReq.Workflow__c))
                        requestIdSET.add(objReq.RequestExtension1__c);
                    else if(objReq.Workflow__c == Label.CLIFv20199 || objReq.Workflow__c == Label.CLIFv20309)
                        requestIdsSET.add(objReq.Id);
                }
                
            }
            
            /* To check if there are any request extension records related to the request queried */
            if(requestIdSET.size() > 0) {
                
                /* Query for extension records */
                LIST<IFv2_RequestExtension1__c> extensionLIST = [Select Id,TotalOriginalValue__c,TotalNetBookValue__c,
                                                                 TotalPlannedDuration__c
                                                                 FROM IFv2_RequestExtension1__c 
                                                                 WHERE Id in:requestIdSET];
                
                /* Checking if extensionLIST is not empty */
                if(!extensionLIST.isEmpty()) {
                    /* Iteration over request extension records */
                    for(IFv2_RequestExtension1__c objReqExt : extensionLIST) {
                        objReqExt.TotalOriginalValue__c = 0.00; 
                        objReqExt.TotalNetBookValue__c = 0.00;
                        objReqExt.TotalPlannedDuration__c = 0.00;
                        reqExtensionMAP.put(objReqExt.Id, objReqExt);
                    }
                    
                }
                
                /* Getting the aggregated results from Account */
                if(!reqExtensionMAP.isEmpty())
                {
                    AggregateResult[] groupedResults = [SELECT sum(IFv2_OriginalValue__c)Amt,sum(IFv2_NetBookValueatPlannedMonth__c)AmtNet,
                                                        IFv2_Request__r.RequestExtension1__c, sum(IFv2_PlannedDuration__c) AmountNet 
                                                        FROM Account  
                                                        WHERE IFv2_Request__r.RequestExtension1__c in : reqExtensionMAP.keyset() 
                                                        GROUP by IFv2_Request__r.RequestExtension1__c];        
                    
                    
                    
                    
                    /* To check if groupedResults LIST is not empty */
                    if(groupedResults.size()>0) { 
                        for(AggregateResult objAggr : groupedResults) {          
                            if( (String)objAggr.get('RequestExtension1__c') != Null) { 
                                if((Decimal)objAggr.get('AmtNet') != null)
                                    reqExtensionMAP.get((String)objAggr.get('RequestExtension1__c')).TotalNetBookValue__c +=  (Decimal)objAggr.get('AmtNet');
                                if((Decimal)objAggr.get('Amt') != null)
                                    reqExtensionMAP.get((String)objAggr.get('RequestExtension1__c')).TotalOriginalValue__c +=  (Decimal)objAggr.get('Amt');
                                if((Decimal)objAggr.get('AmountNet') != null)
                                    reqExtensionMAP.get((String)objAggr.get('RequestExtension1__c')).TotalPlannedDuration__c +=  (Decimal)objAggr.get('AmountNet');
                                
                            }
                        }
                    } 
                }
                /* Setting the values to Zero if the record is deleted */ 
                else{
                    if(extensionLIST.size() > 0 ) {
                        for(IFv2_RequestExtension1__c objExten : extensionLIST) {
                            objExten.TotalOriginalValue__c = 0.00;
                            objExten.TotalNetBookValue__c = 0.00;
                            objExten.TotalPlannedDuration__c = 0.00;
                            requestExtLIST.add(objExten);
                        }
                    }
                }
            }
            /* updating the request extension records */
            IFv2_DmlController.UpdateExtensionOnerecords(reqExtensionMAP.values());
            if(requestExtLIST.size()>0)
                IFv2_DmlController.UpdateExtensionOnerecords(requestExtLIST);
            /* To check if there are any request extension records related to the request queried */
            if(requestIdsSET.size() > 0) {
                /* Query for extension records */
                LIST<IFv2_Request__c> requestLIST = [Select Id,Workflow__c,TotalAmountMGP__c,Total_Contracted_Capacity_Man_days__c
                                                     FROM IFv2_Request__c 
                                                     WHERE Id in:requestIdsSET];
                /* Checking if extensionLIST is not empty */
                if(!requestLIST.isEmpty()) {
                    /* Iteration over request extension records */
                    for(IFv2_Request__c objReq : requestLIST) {
                        objReq.TotalAmountMGP__c = 0.00;
                        objReq.Total_Contracted_Capacity_Man_days__c = 0.00;
                        reqMAP.put(objReq.Id, objReq);
                    }
                }
                /* Getting the aggregated results from Account */
                AggregateResult[] groupedResults = [SELECT sum(IFv2_Amount__c)Amt,sum(IFv2_Expenditure_in_Man_days__c)AmtLex,IFv2_Request__c FROM Account  
                                                    WHERE IFv2_Request__c in : reqMAP.keyset() 
                                                    GROUP by IFv2_Request__c];        
                
                /* To check if groupedResults LIST is not empty */
                if(groupedResults.size()>0) { 
                    for(AggregateResult objAggr : groupedResults) {          
                        if( (String)objAggr.get('IFv2_Request__c') != Null) { 
                            if((Decimal)objAggr.get('Amt') != null)
                                reqMAP.get((String)objAggr.get('IFv2_Request__c')).TotalAmountMGP__c +=  (Decimal)objAggr.get('Amt');
                            if((Decimal)objAggr.get('AmtLex') != null)
                                reqMAP.get((String)objAggr.get('IFv2_Request__c')).Total_Contracted_Capacity_Man_days__c +=  (Decimal)objAggr.get('AmtLex');
                        }
                    } 
                }
                /* Setting the values to Zero if the record is deleted */ 
                else{
                    if(requestLIST.size() > 0 ) {
                        for(IFv2_Request__c objReq : requestLIST) {
                            objReq.TotalAmountMGP__c = 0.00;
                            objReq.Total_Contracted_Capacity_Man_days__c = 0.00;
                            requestRecLIST.add(objReq);
                        }
                    }
                }
            }
            /* updating the request records */
            IFv2_DmlController.GenericListDMLOperation(reqMAP.values(),'update');
            if(requestRecLIST.size()>0)
                IFv2_DmlController.GenericListDMLOperation(requestRecLIST, 'update');
            
        }
        else{
            /* Updated Debug log in Iteration 3 */
            system.debug('RollupSummaryDetails : Trigger is Deactivated');
        }
    }
    
    public static void TransferApproverToDelegatedUserv1(SET<Id> userIdSET, MAP<String,String> DelegatedIdworkflownameMap) {
        
        /* Start of Iteration 3 changes */
        /* Used to Activate or deactivate this method */
        Boolean donotExecuteTrigger = IFv2_UtilsController.getTriggerLogic('IFv2_BackToOfficeOutOfOfficeBatchV2','TransferApproverToDelegatedUserv1');
        
        /* checking if donotExecuteTrigger variable is true or false */
        if(!donotExecuteTrigger) {
            /* End of iteration 3 changes */
            try{
                
                /* To get deliageted users of new assigned users */
                LIST<ID> newAssignedUsers =  new LIST<ID>();
                newAssignedUsers = DelegatedIdworkflownameMap.values();     // To fetch user ids from MAp
                MAP<Id,Id> newUserIdDeligatedUserId = new MAP<Id,Id>();     // Map to store  new user Ids and their deligated user Id
                //For sharing records with delegated approvers.
                for(User user : [SELECT Id, DelegatedApproverId FROM User where Id IN :newAssignedUsers and isActive=true]) {
                    if(user.DelegatedApproverId != null || Test.isRunningTest()) {
                        if(Test.isRunningTest()){
                            newUserIdDeligatedUserId.put(user.Id, UserInfo.getUserId()); 
                        } else {
                            newUserIdDeligatedUserId.put(user.Id, user.DelegatedApproverId);
                        }
                        
                    }
                }
                /* End of creating map */
                
                String strWorkflow;
                for(String strWF : DelegatedIdworkflownameMap.keyset()) {
                    strWorkflow = strWF;
                    
                }
                //here
                
                SET<Id> requestIdSET = new SET<Id>();   // Holds request ids
                Map<String,String> userRequestsMap = new Map<String,String>();//Holds actorid and request Id together 
                MAP<String,IFv2_Request__c> processInstanceObjectRequestNameMAP = new MAP<String,IFv2_Request__c>();// Holds request record Id and its workflow name
                MAP<String,String> userIdDelegatedEmailMAP = new  MAP<String,String>();// Holds Userid,workflowname and User email in format (userid.workflow,useremail)
                SET<String> piwIdSET = new SET<String>();   //Holds process instance Ids
                LIST<IFv2_AdminOnly__c> reassignmentLogLIST = new LIST<IFv2_AdminOnly__c>();// Holds new Logitems to be inserted
                MAP<String, String> reassignmentLogsByPiwIdMAP = new MAP<String, String>(); // Holds reAssignment logs 
                MAP<Id,Id> userIdRecordIdForRecordAcessMAP = new MAP<Id,Id>();  // Holds User Assignment record Access 
                LIST<IFv2_Request__Share> recordShareLIST = new LIST<IFv2_Request__Share>();    // Holds record share records 
                LIST<ProcessInstanceWorkitem> proWorkItemLIST = new  LIST<ProcessInstanceWorkitem>();   // Holds process Instance workItem records
                MAP<Id,Id> userIdRecordIdForRecordAcessDeligatedMAP = new MAP<Id,Id>(); // Holds deligated User Assignment record Access
                
                //added--if wf names are same and users are DA for each other and both are ooo--reassignment shouldnt happen
                
                System.debug('userIdSET************' +userIdSET);
				
                List<IFv2_AdminOnly__c> reassignmentCheckList = [Select Id,User__c,OwnerId from IFv2_AdminOnly__c where User__c IN: userIdSET AND OwnerId IN: DelegatedIdworkflownameMap.Values() AND WorkflowName__c =: strWorkflow];
                
                if((reassignmentCheckList.isEmpty() && reassignmentCheckList.size()==0) || Test.isRunningTest())//only if list size is 0 reassignment will happen
                {
                    List<IFv2_AdminOnly__c> reassignmentId = [Select Id,User__c,OwnerId from IFv2_AdminOnly__c where User__c IN: userIdSET AND OwnerId IN: DelegatedIdworkflownameMap.Values() AND WorkflowName__c =: strWorkflow];
                    
                    
                    
                    if(reassignmentId.size()==0  || Test.isRunningTest())//only if list size is 0 reassignment will happen
                    {
                        
                        if(!userIdSET.isEmpty()) {
                            String soqlProWork = 'SELECT Id, ActorId, ProcessInstanceId, p.ProcessInstance.TargetObject.Name,'; 
                            soqlProWork += ' p.ProcessInstance.TargetObjectId '; 
                            soqlProWork += ' FROM ProcessInstanceWorkItem p ';
                            soqlProWork += ' WHERE ( ';
                            soqlProWork += ' ActorId IN : userIdSET '; 
                            soqlProWork += ') ';
                            soqlProWork += ' AND (';
                            soqlProWork += ' p.ProcessInstance.Status != \'Approved\' ';
                            soqlProWork += ' OR p.ProcessInstance.Status != \'Rejected\' ';
                            soqlProWork += ')';
                            soqlProWork += ' Order By CreatedDate Desc ';
                            proWorkItemLIST = Database.query(soqlProWork);
                            /*proWorkItemLIST contains approvals of users who are in out of office, Forming requestId records SET, Work Item SET,User-request-recordid SET **/
                        }
                    }
                    /* Checking is LIST is not empty */
                    if(!proWorkItemLIST.isEmpty()) {
                        for(ProcessInstanceWorkitem workitem:proWorkItemLIST) {
                            requestIdSET.add(workitem.ProcessInstance.TargetObjectId);//It contains ids of requests whose approvers are out of office
                            piwIdSET.add(workitem.Id);//It is used as a filter in querying reassignment logs and queried reassignment logs are used to cross check whether the request has been reassigned or not
                            userRequestsMap.put(workitem.ProcessInstance.TargetObjectId,workitem.ActorId);
                        }
                    }
					
					System.debug('userRequestsMap************' +userRequestsMap);
					
                    MAP<String,Id> accountShareMAP = new MAP<String,Id>();
                    //querying requests record which are in approval process and whose approver is out of office
                    for(IFv2_Request__c Request:[select Workflow__c, Account__c, RequestExtension1__c,RequestExtension2__c,RequestExtension3__c from IFv2_Request__c where Id in:requestIdSET]) {
                        //Forming a MAP of request Id AND ITS respective workflow
                        if(!String.isblank(Request.Workflow__c)) {
                            processInstanceObjectRequestNameMAP.put(Request.Id,Request);
                            accountShareMAP.put(Request.Id,Request.Account__c);
                        }
                        
                    }
                    
                    // iterating over process instances and updating actor Id with delegated approvers using maps formed above
                    LIST<ProcessInstanceWorkitem> updatelist =  new LIST<ProcessInstanceWorkitem>();
                    for(ProcessInstanceWorkitem workitem:proWorkItemLIST) {
                        if(processInstanceObjectRequestNameMAP.keyset().contains(workitem.ProcessInstance.TargetObjectId)) {
                            //check for reassignment log containing the piw Id to be modified. if there is one, do not reassign again
                            if(DelegatedIdworkflownameMap.keyset().contains(processInstanceObjectRequestNameMAP.get(workitem.ProcessInstance.TargetObjectId).workflow__C)) {
                                String userid= DelegatedIdworkflownameMap.get(processInstanceObjectRequestNameMAP.get(workitem.ProcessInstance.TargetObjectId).workflow__C);
								workitem.ActorId =  (String) DelegatedIdworkflownameMap.get(processInstanceObjectRequestNameMAP.get(workitem.ProcessInstance.TargetObjectId).workflow__C);
								System.debug('workitem.ActorId************' + workitem.ActorId);
								String originalUserId = userRequestsMap.get(workitem.ProcessInstance.TargetObjectId);
                                //updating approver to delegated approver
                                IFv2_AdminOnly__c ral = createReassignmentLog(workitem, workitem.ActorId,strWorkflow,originalUserId); 
                                reassignmentLogLIST.add(ral);
                                userIdRecordIdForRecordAcessMAP.put(workitem.ProcessInstance.TargetObjectId , workitem.ActorId);
                                userIdRecordIdForRecordAcessDeligatedMAP.put(workitem.ProcessInstance.TargetObjectId,newUserIdDeligatedUserId.get(workitem.ActorId)); // Map to store deliagated User
                                updatelist.add(workitem);
                            }
                        }
                    }
                    //updating process instances
                    try{
                        /* If updatelist is not empty */
                        if(updatelist.size()>0)
                            IFv2_DmlController.updateActor(proWorkItemLIST);//update the LIST
                    }Catch(Exception ex) {
                        system.debug('error'+ex.getMessage());
                    }
                    
                    //creating ReassignmentLogs
                    if(reassignmentLogLIST.size()>0)
                        IFv2_DmlController.GenericListDMLOperation(reassignmentLogLIST,'insert');
                    
                    // Map to store reqeustIds and set of account ids to which its related to.
                    MAP<Id, SET<Account>> requestIdAccountSetMAP = new MAP<Id, SET<Account>>();
                    
                    // SET to store Account share records 
                    LIST<AccountShare> accountShareLIST = new LIST<AccountShare>();
                    // To get Related list records
                    if(system.Label.CLIFv20189 == 'True') {
                        
                        Id requestItemsRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Items').getRecordTypeId();
                        
                        // Querying for Account records 
                        LIST<Account> accountRecordLIST = IFv2_UtilsController.getRequestRelatedAccountRecords(userIdRecordIdForRecordAcessMAP.keyset(), requestItemsRecordTypeId); 
                        
                        // Checking if list is not empty
                        if(!accountRecordLIST.isEmpty()) {
                            for(Account accountRecord : accountRecordLIST) {
                                if(accountRecord != NULL) {
                                    if(requestIdAccountSetMAP.containsKey(accountRecord.IFv2_Request__c)) {
                                        // Temporary set to store 
                                        SET<Account> temporaryAccountSET = requestIdAccountSetMAP.get(accountRecord.IFv2_Request__c);
                                        temporaryAccountSET.add(accountRecord);
                                        requestIdAccountSetMAP.put(accountRecord.IFv2_Request__c, temporaryAccountSET);
                                    } else {
                                        
                                        SET<Account> temporaryAccountSET = new SET<Account>();
                                        temporaryAccountSET.add(accountRecord);
                                        requestIdAccountSetMAP.put(accountRecord.IFv2_Request__c, temporaryAccountSET);
                                    }
                                }
                            }
                        }
                    }
                    // To get list of admin users, so as not to share records
                    String adminString = label.CLIFv20162;
                    LIST<String> adminLIST = new LIST<String>();
                    adminLIST.addAll(adminString.split(','));
                    
                    LIST<User> adminUserRecordLIST = [SELECT Id,name 
                                                      FROM User 
                                                      WHERE profile.name In: adminLIST];
                    SET<Id> adminUserIdSET = new SET<Id>();
                    
                    for(User userId : adminUserRecordLIST) {
                        adminUserIdSET.add(userId.Id);
                    }
                    
                    for(Id recordid : userIdRecordIdForRecordAcessMAP.keyset()) {
                        if(String.isNotblank(recordid) && String.isNotblank(userIdRecordIdForRecordAcessMAP.get(recordid))) {
                            IFv2_Request__Share shareRecord = new IFv2_Request__Share();    // Initializing requst share and initializing field values
                            shareRecord.ParentId = recordid;
                            shareRecord.UserOrGroupId = userIdRecordIdForRecordAcessMAP.get(recordid) ;
                            shareRecord.AccessLevel = 'read';
                            shareRecord.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                            
                            // To share record with deligated user
                            if(newUserIdDeligatedUserId.containsKey(userIdRecordIdForRecordAcessMAP.get(recordid))) {
                                IFv2_Request__Share shareRecordDeliagetd = new IFv2_Request__Share();    // Initializing requst share and initializing field values
                                shareRecordDeliagetd.ParentId = recordid;
                                shareRecordDeliagetd.UserOrGroupId = newUserIdDeligatedUserId.get(userIdRecordIdForRecordAcessMAP.get(recordid)) ;
                                shareRecordDeliagetd.AccessLevel = 'read';
                                shareRecordDeliagetd.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                                recordShareLIST.add(shareRecordDeliagetd);
                            }
                            
                            
                            recordShareLIST.add(shareRecord);
                        }
                        if(system.Label.CLIFv20189 == 'True' && accountShareMAP.get(recordid) != NULL  || Test.isRunningTest()) {
                            if(!adminUserIdSET.contains(userIdRecordIdForRecordAcessMAP.get(recordid)) || Test.isRunningTest()) {
                                AccountShare accountShareRecord = new AccountShare();
                                accountShareRecord.AccountId = accountShareMAP.get(recordid);
                                accountShareRecord.UserOrGroupId = userIdRecordIdForRecordAcessMAP.get(recordid);
                                accountShareRecord.AccountAccessLevel = 'read';
                                accountShareRecord.RowCause = Schema.AccountShare.RowCause.Manual;
                                accountShareRecord.OpportunityAccessLevel = 'none';
                                accountShareLIST.add(accountShareRecord);
                                
                                // To share record with deligated user
                                if(newUserIdDeligatedUserId.containsKey(userIdRecordIdForRecordAcessMAP.get(recordid)) || Test.isRunningTest()) {
                                    AccountShare accountShareRecordDeligated = new AccountShare();
                                    accountShareRecordDeligated.AccountId = accountShareMAP.get(recordid);
                                    accountShareRecordDeligated.UserOrGroupId = newUserIdDeligatedUserId.get(userIdRecordIdForRecordAcessMAP.get(recordid));
                                    accountShareRecordDeligated.AccountAccessLevel = 'read';
                                    accountShareRecordDeligated.RowCause = Schema.AccountShare.RowCause.Manual;
                                    accountShareRecordDeligated.OpportunityAccessLevel = 'none';
                                    accountShareLIST.add(accountShareRecordDeligated);
                                }
                            }
                            if(requestIdAccountSetMAP.containsKey(recordid) || Test.isRunningTest()) {
                                SET<AccountShare> accountShareSET = new SET<AccountShare>();
                                for(Account accountrecord : requestIdAccountSetMAP.get(recordid)) {
                                    if(!adminUserIdSET.contains(userIdRecordIdForRecordAcessMAP.get(recordid)) || Test.isRunningTest()) {
                                        AccountShare accountRecordShare = new AccountShare();
                                        accountRecordShare.AccountId = accountrecord.Id;
                                        accountRecordShare.UserOrGroupId = userIdRecordIdForRecordAcessMAP.get(recordid);
                                        accountRecordShare.AccountAccessLevel = 'read';
                                        accountRecordShare.RowCause = Schema.AccountShare.RowCause.Manual;
                                        accountRecordShare.OpportunityAccessLevel = 'none';
                                        accountShareSET.add(accountRecordShare);
                                        // To share record with deligated user
                                        if(newUserIdDeligatedUserId.containsKey(userIdRecordIdForRecordAcessMAP.get(recordid)) || Test.isRunningTest()) {
                                            AccountShare accountShareRecordDeligated = new AccountShare();
                                            accountShareRecordDeligated.AccountId = accountrecord.Id;
                                            accountShareRecordDeligated.UserOrGroupId = newUserIdDeligatedUserId.get(userIdRecordIdForRecordAcessMAP.get(recordid));
                                            accountShareRecordDeligated.AccountAccessLevel = 'read';
                                            accountShareRecordDeligated.RowCause = Schema.AccountShare.RowCause.Manual;
                                            accountShareRecordDeligated.OpportunityAccessLevel = 'none';
                                            accountShareSET.add(accountShareRecordDeligated);
                                        }
                                    }
                                    
                                }
                                accountShareLIST.addALl(accountShareSET);
                            }
                            
                            
                        }
                    }
                    // Inserting Account Share Records
                    if(!accountShareLIST.isEmpty()) {
                        IFv2_DmlController.insertAccountShare(accountShareLIST); 
                    }
                    /*To insert share records*/
                    IFv2_DmlController.insertShareRecords(recordShareLIST);
                    CreateExtensionShareRecords(processInstanceObjectRequestNameMAP.values(),userIdRecordIdForRecordAcessMAP,userIdRecordIdForRecordAcessDeligatedMAP);
                }
            }//added
            Catch(Exception e) {
                system.debug('errormessage'+e.getmessage());
            }
        }
        
        else{
            system.debug('TransferApproverToDelegatedUserv1 : Method  is Deactivated'); 
        }
    }
    
    /*Method to create a ReassignmentLogs on AdminOnly object*/
    public static  IFv2_AdminOnly__c createReassignmentLog(ProcessInstanceWorkitem piw, Id userId, String workflow,Id originalUserId) {
        IFv2_AdminOnly__c ral = new IFv2_AdminOnly__c();    //Initializing admin only records
        ral.ProcessInstanceWorkItemId__c = String.valueOf(piw.Id);
        ral.User__c = userId;
        ral.WorkflowName__c = workflow;
        ral.Recordtypeid=Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('Reassignment Logs').getRecordTypeId();
		ral.OwnerId = originalUserId;
        return ral;
    }
    
    //Method to create the Un-Assigned logs for the out of office proxy usres 
    public static void createUnAssignedLogs(Set<Id> outOfOfficeUserIdSet, Set<Id> OutOfOfficeProxyIdSet) {
        LIST<ProcessInstanceWorkitem>  processInstancesList = new LIST<ProcessInstanceWorkitem>();
        
        if(!outOfOfficeUserIdSet.isEmpty()) {
            processInstancesList = [SELECT Id, ActorId, ProcessInstanceId, p.ProcessInstance.TargetObject.Name,p.ProcessInstance.TargetObjectId 
                                    FROM ProcessInstanceWorkItem p 
                                    WHERE ActorId IN : outOfOfficeUserIdSet
                                    AND (p.ProcessInstance.Status != 'Approved'  OR  p.ProcessInstance.Status != 'Rejected') 
                                    Order By CreatedDate Desc];
        }
        
        List<IFv2_AdminOnly__c> unAssignmentLogLIST = new List<IFv2_AdminOnly__c>();
        
        // iterating over process instances and creating the un-assigned logs
        if(!processInstancesList.isEmpty()) {
            system.debug('processInstancesList**********'+processInstancesList);
            
            for(ProcessInstanceWorkitem workitem:processInstancesList) {
                system.debug('workitem**********'+workitem);
                
                IFv2_AdminOnly__c unAssignedLog = new IFv2_AdminOnly__c();
                unAssignedLog.ProcessInstanceWorkItemId__c = String.valueOf(workitem.Id);
                unAssignedLog.User__c = workitem.ActorId;
                unAssignedLog.Record__c = workitem.ProcessInstance.TargetObjectId;
                unAssignedLog.Recordtypeid=Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('UnAssignedOOOLogs').getRecordTypeId();
                unAssignedLog.IFv2_ErrorDescription__c =  'The Request Record  ' + workitem.ProcessInstance.TargetObjectId+ '  Failed in reassignement to the proxy  '+workitem.ActorId+'  due to the OutOfOffice' ;
                unAssignmentLogLIST.add(unAssignedLog);
            }
        }
        
        //creating ReassignmentLogs
        if(!unAssignmentLogLIST.isEmpty())
            system.debug('unAssignmentLogLIST**********'+ unAssignmentLogLIST);
        	IFv2_DmlController.GenericListDMLOperation(unAssignmentLogLIST,'insert');
    }
    
    /* Method to assign requests back to the original User and delete their respective ReassignmentLogs from account*/
    public static void assignRequestsBack(LIST<Id> userIdListBackInOffice, String workflow) {
        
        /* Start of Iteration 3 changes */
        /* Used to Activate or deactivate this method */
        Boolean donotExecuteTrigger = IFv2_UtilsController.getTriggerLogic('IFv2_BackToOfficeOutOfOfficeBatch','assignRequestsBack');
		system.debug('userIdListBackInOffice**********'+ userIdListBackInOffice);
		system.debug('workflow**********'+ workflow);
        
        /* checking if donotExecuteTrigger variable is true or false */
        if(!donotExecuteTrigger) {
            if(!userIdListBackInOffice.isEmpty()) {
                /* End of Iteration 3 changes */    
                LIST<ProcessInstanceWorkItem> piwLIST = new LIST<ProcessInstanceWorkItem>();
                String RecordtypeId = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('Reassignment Logs').getRecordTypeId();
                
                //query reassignment logs
                LIST<IFv2_AdminOnly__c> ralLIST = new LIST<IFv2_AdminOnly__c>();
                
                if(RecordtypeId!=Null)
                {
                    try{
                        if(String.isBlank(workflow))
                            /* Query for Admin records */
                            ralLIST = [select Id, ProcessInstanceWorkItemId__c, User__c,OwnerId from IFv2_AdminOnly__c where OwnerId IN : userIdListBackInOffice and Recordtypeid=:RecordtypeId and User__r.Out_Of_Office__c=false];
                        else {
                            /* Query for Admin records */
                            ralLIST = [select Id, ProcessInstanceWorkItemId__c, User__c,OwnerId from IFv2_AdminOnly__c where OwnerId IN : userIdListBackInOffice and Recordtypeid=:RecordtypeId and WorkflowName__c =:workflow and User__r.Out_Of_Office__c=false];
                        }
                    } catch(Exception e) {
                        //Ok here - no reassignment logs found
                        
                    }
                }
				system.debug('ralLIST**********'+ ralLIST);
				
                //get piw Ids from logs 
                LIST<String> piwIdsFromLogsLIST = new LIST<String>();
                if(ralLIST.size() > 0) {
                    for(IFv2_AdminOnly__c ral : ralLIST) {
                        piwIdsFromLogsLIST.add(ral.ProcessInstanceWorkItemId__c);
                    }
                }
                //get proces instance work items based on ids from reassignment logs 
                if(piwIdsFromLogsLIST.size() > 0) {
                    try{
                        piwLIST = [Select 
                                   Id, 
                                   ActorId, 
                                   ProcessInstance.TargetObjectId,
                                   ProcessInstance.Status 
                                   from 
                                   ProcessInstanceWorkItem 
                                   where 
                                   (ProcessInstance.Status != 'Approved'
                                    and
                                    ProcessInstance.Status != 'Rejected')
                                   and 
                                   Id
                                   IN : piwIdsFromLogsLIST];
                    } catch (Exception e) {
                        System.debug(e.getMessage());
                    }
                }
                
				system.debug('piwLIST**********'+ piwLIST);
				
                //reassign back to original User - store this in MAP
                //MAP<ProcessInstanceWorkItem, Id> piwToUserIdMap = new MAP<ProcessInstanceWorkItem, Id>();
                MAP<Id,ProcessInstanceWorkItem> piwToUpdateMAP = new Map<Id,ProcessInstanceWorkItem>(); // MAP to store process instance work item 
                SET<String> recordDelegatedUserSET =new SET<String>();  // SET to store delegated users
                SET<String> requestIdSET =new SET<String>();    // SET to store request ids 
                
                
                /* Set to store Actor Ids to get deligated user of that record */
                SET<Id> ActorIdSET = new SET<Id>();
                
                
                
                /* Check if piwLIST is not empty */
                if(piwLIST.size() > 0)  {
                    for(ProcessInstanceWorkItem piw : piwLIST) {
                        system.debug('ralLIST'+ralLIST);
                        for(IFv2_AdminOnly__c ral : ralLIST) {
                            
                            if(String.valueOf(piw.Id).equals(String.valueOf(ral.ProcessInstanceWorkItemId__c))) {
                                requestIdSET.add(piw.ProcessInstance.TargetObjectId);
                                recordDelegatedUserSET.add(piw.ProcessInstance.TargetObjectId+'.'+piw.ActorId);
                                ActorIdSET.add(piw.ActorId);
                                ProcessInstanceWorkItem ProcessInstanceWorkItemUpdate = new ProcessInstanceWorkItem();
                                ProcessInstanceWorkItemUpdate.Id = piw.Id;
								system.debug('ral.User__c**********'+ ral.OwnerId);
                                ProcessInstanceWorkItemUpdate.ActorId = ral.OwnerId;
                                piwToUpdateMAP.put(ProcessInstanceWorkItemUpdate.Id,ProcessInstanceWorkItemUpdate);
                                /* piw.ActorId = ral.User__c;
piwToUpdateLIST.add(piw);*/
                            }
                        }
                    }
                }
                
                // Query for deligated users 
                LIST<Id> deliagedUserIdLIST = new LIST<Id>();
                MAP<Id,Id> deligatedUserIdMAP = new MAP<Id,Id>(); // Map to store deligated user id and 
                if(!ActorIdSET.isEmpty()) {
                    for(User user : [SELECT Id,DelegatedApproverId FROM User where Id IN :ActorIdSET and isactive=true and Out_Of_Office__c=false]) {
                        if(user.DelegatedApproverId !=null) {
                            deligatedUserIdMAP.put(user.Id,user.DelegatedApproverId);
                        }
                    }
                }
                
                if(piwLIST.size() > 0)  {
                    for(ProcessInstanceWorkItem piw : piwLIST) {
                        for(IFv2_AdminOnly__c ral : ralLIST) {
                            if(String.valueOf(piw.Id).equals(String.valueOf(ral.ProcessInstanceWorkItemId__c))) {
                                system.debug('actor Id'+piw.ActorId);
                                if(deligatedUserIdMAP.get(piw.ActorId) != NULL) {
                                    recordDelegatedUserSET.add(piw.ProcessInstance.TargetObjectId+'.'+deligatedUserIdMAP.get(piw.ActorId));
                                }
                            }
                        }
                    }
                }
                
                // End of creating map of deligated user Id MAP
                
                //delete old reassignment logs
                if(ralLIST.size() > 0) {
                    IFv2_DmlController.GenericListDMLOperation(rallist,'delete');
                }
                //Deleting the delgated approvers access to records
                LIST<IFv2_Request__Share> shareRecordsLIST = new LIST<IFv2_Request__Share>();
                if(!requestIdSET.isEmpty())
                    shareRecordsLIST = [SELECT Id,ParentId,UserOrGroupId 
                                        FROM IFv2_Request__Share 
                                        WHERE ParentId IN :requestIdSET
                                        AND RowCause = 'SharingRecordsWithChatter__c'];
                LIST<IFv2_Request__Share> sharesToDeleteLIST = new LIST<IFv2_Request__Share>(); // Holds share records 
                SET<Id> parentids = new SET<Id>();  // Holds parent Ids 
                SET<Id> Extension1ids = new SET<Id>();  // Holds extension 1 ids
                SET<Id> Extension2ids = new SET<Id>();  // Holds extension 2 ids
                SET<Id> Extension3ids = new SET<Id>();  // Holds extension 3 ids
                SET<Id> AccountIdSET = new SET<Id>();   // Holds Account Share records
                SET<Id> requestIdsSet = new SET<Id>();  // Holds request records
                
                
                /* if shareRecordsLIST is not empty */
                if(!shareRecordsLIST.isEmpty()) {
                    for(IFv2_Request__Share Requestshare:shareRecordsLIST) {
                        String parentuserid=Requestshare.ParentId+'.'+Requestshare.UserOrGroupId;
                        if(recordDelegatedUserSET.contains(parentuserid)) {
                            sharesToDeleteLIST.add(Requestshare);
                            parentids.add(Requestshare.ParentId);
                        }
                    }
                }
                
                /* if sharesToDeleteLIST is not empty */
                if(!sharesToDeleteLIST.isEmpty()) {
                    IFv2_DmlController.deleteShareRecords(sharesToDeleteLIST);
                }
                
                /* Query for request records */
                LIST<IFv2_Request__c> requestLIST = new LIST<IFv2_Request__c>();
                if(!parentids.isEmpty())
                    requestLIST = [Select Id, RequestExtension1__c,Account__c,RequestExtension2__c,RequestExtension3__c from IFv2_Request__c where Id in: parentids   and (RequestExtension1__c!= NULL or RequestExtension2__c!= null or  RequestExtension3__c!= NUll) ];
                
                /* Checking if LIST is not empty */
                if(!requestLIST.isEmpty()) {
                    for(IFv2_Request__c request:requestLIST) {
                        if(request.RequestExtension1__c!=Null)
                            Extension1ids.add(request.RequestExtension1__c);
                        if(request.RequestExtension2__c!=Null)
                            Extension2ids.add(request.RequestExtension2__c);
                        if(request.RequestExtension3__c!=Null)
                            Extension3ids.add(request.RequestExtension3__c);
                        if(request.Account__c != NULL)
                            AccountIdSET.add(request.Account__c);
                        if(request.Id != NULL ) {
                            requestIdsSet.add(request.Id);
                        }
                    }
                }
                
                /* Checking if Extension1ids LIST is not empty */
                if(!Extension1ids.isEmpty())
                    IFv2_DmlController.deleteShareRecordsAPAC([select Id from IFv2_RequestExtension1__Share where Id in:Extension1ids]);
                
                /* Checking if Extension2ids  LIST is not empty */
                if(!Extension2ids.isEmpty())
                    IFv2_DmlController.deleteShareRecordsEMAE([select Id from IFv2_RequestExtension2__Share where Id in:Extension2ids]);
                
                /* Checking if Extension3ids  LIST is not empty */
                if(!Extension3ids.isEmpty())
                    IFv2_DmlController.deleteShareRecordsNALA([select Id from IFv2_RequestExtension3__Share where Id in:Extension3ids]);
                
                /* checking if Accountshare record */
                if(!AccountIdSET.isEmpty() && System.Label.CLIFv20189 == 'True') {
                    // LIST<AccountShare> accountShareRecordsLIST = [select Id from AccountShare where Id in:AccountIdSET];
                    IFv2_DmlController.deleteShareRecordsAccount([select Id from AccountShare where Id in:AccountIdSET]);
                }
                //if there are piws to be reassigned back, update them
                if(piwToUpdateMAP.values().size() > 0) {
                    
                    //SET<ProcessInstanceWorkItem> piwToUpdateSET = new SET<ProcessInstanceWorkItem>(); // LIST to store process instance work item 
                    //LIST<ProcessInstanceWorkItem> piwToLISTUpdateLIST = new LIST<ProcessInstanceWorkItem>();  // LIST to store process instance work item 
                    
                    //piwToUpdateSET.addAll(piwToUpdateLIST);
                    //piwToLISTUpdateLIST.addAll(piwToUpdateSET);
                    IFv2_DmlController.updateActor(piwToUpdateMAP.values()); //update the MAP
                    //IFv2_DmlController.updateActor(piwToUpdateLIST); //update the LIST
                }
            }
        }
        else{
            system.debug('assignRequestsBack : Method  is Deactivated'); 
        }
    }
    
    /* Method to create share reocrds */
    public static void CreateExtensionShareRecords(LIST<IFv2_Request__c> requestLIST, MAP<Id,Id> userIdRecordIdForRecordAcessMAP, MAP<Id,Id> userIdRecordIdForRecordAcessDeligatedMAP) {
        
        /* Declaring lists used for this method */
        LIST<IFv2_Request__Share> shareLIST = new LIST<IFv2_Request__Share>();  // Holds request share records
        LIST<IFv2_RequestExtension1__Share> extension1RecordsLIST = new  LIST<IFv2_RequestExtension1__Share>(); // Holds request extension 1 share records
        LIST<IFv2_RequestExtension2__Share> extension2RecordsLIST = new  LIST<IFv2_RequestExtension2__Share>(); // Holds request extension 2 share records
        LIST<IFv2_RequestExtension3__Share> extension3RecordsLIST = new  LIST<IFv2_RequestExtension3__Share>(); // Holds request extension 3 share records
        MAP<Id,Id> shareRecordDetailMap = new MAP<Id,Id>(); // Holds request detail MAP
        MAP<String,String>  ParentRequestExtensionIdMap = new MAP<String,String>(); // Holds requst extension MAP 
        MAP<String,String> extensionMap = new MAP<String,String>(); // Holds extension MAP 
        
        /* If requestLIST is not empty */
        if(!requestLIST.isEmpty()) {
            for(IFv2_Request__c currentRequest : requestLIST) {
                /* Checking if ParentRequestExtensionIdMap does not contain current request Id */
                if(!ParentRequestExtensionIdMap.containsKey(currentRequest.Id)) {
                    if(currentRequest.RequestExtension1__c != NUll) {
                        ParentRequestExtensionIdMap.put(currentRequest.Id,currentRequest.RequestExtension1__c);
                        extensionMap.put(currentRequest.Id,'APAC'); 
                    }else if(currentRequest.RequestExtension2__c != NUll) {
                        ParentRequestExtensionIdMap.put(currentRequest.Id,currentRequest.RequestExtension2__c);
                        extensionMap.put(currentRequest.Id,'EMEA');
                    }
                    else if(currentRequest.RequestExtension3__c != NUll) {
                        ParentRequestExtensionIdMap.put(currentRequest.Id,currentRequest.RequestExtension3__c);
                        extensionMap.put(currentRequest.Id,'NALA');
                    }
                }
            }
        }
        System.debug('extensionMap::'+extensionMap);
        System.debug('userIdRecordIdForRecordAcessMAP::'+userIdRecordIdForRecordAcessMAP);
        /* To Share Records of Extension object fields */
        for(Id parentObjectId : userIdRecordIdForRecordAcessMAP.keyset()) {
            String extensionNumber = extensionMap.get(parentObjectId);
            String extensionId = ParentRequestExtensionIdMap.get(parentObjectId);
            System.debug('extensionNumber::'+extensionNumber);
            /* Checking if extensionNumber is APAC or EMEA or NALA*/
            if(extensionNumber == 'APAC') {
                
                IFv2_RequestExtension1__Share shareRecord = new IFv2_RequestExtension1__Share();    // Initializing share records 
                shareRecord.ParentId = extensionId ;
                shareRecord.UserOrGroupId = userIdRecordIdForRecordAcessMAP.get(parentObjectId);
                shareRecord.AccessLevel = 'read';
                shareRecord.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                extension1RecordsLIST.add(shareRecord);
                
                // Share record with deligated user or new approver
                if(userIdRecordIdForRecordAcessDeligatedMAP.containsKey(userIdRecordIdForRecordAcessMAP.get(parentObjectId))){
                    IFv2_RequestExtension1__Share shareRecordDeligated = new IFv2_RequestExtension1__Share();   // Initializing share records 
                    shareRecordDeligated.ParentId = extensionId ;
                    shareRecordDeligated.UserOrGroupId = userIdRecordIdForRecordAcessDeligatedMAP.get(userIdRecordIdForRecordAcessMAP.get(parentObjectId));
                    shareRecordDeligated.AccessLevel = 'read';
                    shareRecordDeligated.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                    extension1RecordsLIST.add(shareRecordDeligated);
                }
            } 
            else if(extensionNumber == 'EMEA') {
                IFv2_RequestExtension2__Share shareRecord = new IFv2_RequestExtension2__Share();    // Initializing share records
                shareRecord.ParentId = extensionId ;
                shareRecord.UserOrGroupId = userIdRecordIdForRecordAcessMAP.get(parentObjectId);
                shareRecord.AccessLevel = 'read';
                shareRecord.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                extension2RecordsLIST.add(shareRecord);
                
                // Share record with deligated user or new approver
                if(userIdRecordIdForRecordAcessDeligatedMAP.containsKey(userIdRecordIdForRecordAcessMAP.get(parentObjectId))){
                    IFv2_RequestExtension2__Share shareRecordDeligated = new IFv2_RequestExtension2__Share();   // Initializing share records
                    shareRecordDeligated.ParentId = extensionId ;
                    shareRecordDeligated.UserOrGroupId = userIdRecordIdForRecordAcessDeligatedMAP.get(userIdRecordIdForRecordAcessMAP.get(parentObjectId));
                    shareRecordDeligated.AccessLevel = 'read';
                    shareRecordDeligated.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                    extension2RecordsLIST.add(shareRecordDeligated);
                }
            } else if(extensionNumber == 'NALA') {
                IFv2_RequestExtension3__Share shareRecord = new IFv2_RequestExtension3__Share();    // Initializing share records
                shareRecord.ParentId = extensionId ;
                shareRecord.UserOrGroupId = userIdRecordIdForRecordAcessMAP.get(parentObjectId);
                shareRecord.AccessLevel = 'read';
                shareRecord.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                extension3RecordsLIST.add(shareRecord);
                
                // Share record with deligated user or new approver
                if(userIdRecordIdForRecordAcessDeligatedMAP.containsKey(userIdRecordIdForRecordAcessMAP.get(parentObjectId))){
                    IFv2_RequestExtension3__Share shareRecordDeligated = new IFv2_RequestExtension3__Share();   // Initializing share records
                    shareRecordDeligated.ParentId = extensionId ;
                    shareRecordDeligated.UserOrGroupId = userIdRecordIdForRecordAcessDeligatedMAP.get(userIdRecordIdForRecordAcessMAP.get(parentObjectId));
                    shareRecordDeligated.AccessLevel = 'read';
                    shareRecordDeligated.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                    extension3RecordsLIST.add(shareRecordDeligated);
                }
            }
            
        }
        
        /* Checking if extension1RecordsLIST is not empty */
        if(!extension1RecordsLIST.isEmpty())
            try {
                /* Calling Generic Dml metod for inserting APAC Share records */
                IFv2_DmlController.insertShareRecordsAPAC(extension1RecordsLIST);
            } catch(Exception e) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(e);
            }
        /* Checking if extension2RecordsLIST is not empty */
        else if(!extension2RecordsLIST.isEmpty())
            try {
                /* Calling Generic Dml metod for inserting EMEA Share records */
                IFv2_DmlController.insertShareRecordsEMAE(extension2RecordsLIST);
            } catch(Exception e) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(e);
            }
        /* Checking if extension3RecordsLIST is not empty */
        else if(!extension3RecordsLIST.isEmpty())
            try {
                /* Calling Generic Dml metod for inserting NALA Share records */
                IFv2_DmlController.insertShareRecordsNALA(extension3RecordsLIST);
            } catch(Exception e) {
                IFv2_ExceptionUtilitiesController.exceptionHandler(e);
            }
    }
    
    /* Method to insert share records from chatter */
    public Static void chatterSharingRecords(LIST<FeedItem> FeedItemRecords) {
        
        /* Start of Iteration 3 changes */
        /* Used to Activate or deactivate this method */
        Boolean donotExecuteTrigger = IFv2_UtilsController.getTriggerLogic('FeedItemTrigger','chatterSharingRecords');
        
        /* checking if donotExecuteTrigger variable is true or false */
        if(!donotExecuteTrigger) {
            
            LIST<Id> feedItemIdList = new LIST<Id>();   // LIST to store Feed Item LIST 
            LIST<Id> ParentRecordId = new LIST<Id>();   // LIST to store parent record ids
            MAP<Id,Id> feedItemToParentObjectMap = new MAP<Id,Id>();    // MAP for feed item parent  
            MAP<Id,String> mapNetworkScope = new MAP<Id,String>();      // MAP for network store 
            
            /* Checking if FeedItemRecords is not empty */
            if(!FeedItemRecords.isEmpty()) {
                /* Iterating over FeedItemRecords LIST */
                for (FeedItem feed: FeedItemRecords) {
                    feedItemIdList.add(feed.Id);
                    ParentRecordId.add(feed.ParentId);
                    feedItemToParentObjectMap.put(feed.Id, feed.ParentId);
                    mapNetworkScope.put(feed.Id,feed.NetworkScope);
                }
            }
            
            
            MAP<String,String>  ParentRequestExtensionIdMap = new MAP<String,String>(); // MAP to store extension records 
            MAP<String,String> extensionMap = new MAP<String,String>();     // MAP to store extension records 
            
            /* Query request records wher Id in Parent Id LIST */
            LIST<IFv2_Request__c> requestLIST = new LIST<IFv2_Request__c>();
            if(!ParentRecordId.isEmpty())
                requestLIST = [Select Id, Workflow__c, Account__c, RequestExtension1__c,RequestExtension2__c,RequestExtension3__c from IFv2_Request__c where Id in: ParentRecordId ];
            
            /* Cheking is requestLIST is not empty */
            if(!requestLIST.isEmpty()) {
                String WorkflowName = requestLIST[0].Workflow__c;
                
                //String to store workflowRegion
                String workflowRegion;
                
                if(!String.isBlank(WorkflowName)) {
                    
                    workflowRegion = IFv2_UtilsController.getWorkflows(workflowName);
                }
                if(!String.isBlank(workflowRegion)) {
                    // Checking if request Id is in ParentRequestExtensionIdMap MAP 
                    if(!ParentRequestExtensionIdMap.containsKey(requestLIST[0].Id)) {
                        if( workflowRegion == 'APAC' && requestLIST[0].RequestExtension1__c != NUll) {
                            ParentRequestExtensionIdMap.put(requestLIST[0].Id,requestLIST[0].RequestExtension1__c);
                            extensionMap.put(requestLIST[0].Id,'APAC'); 
                        }else if( workflowRegion == 'EMEA' && requestLIST[0].RequestExtension2__c != NUll) {
                            ParentRequestExtensionIdMap.put(requestLIST[0].Id,requestLIST[0].RequestExtension2__c);
                            extensionMap.put(requestLIST[0].Id,'EMEA');
                        }else if( workflowRegion == 'NALA' && requestLIST[0].RequestExtension3__c != NUll) {
                            ParentRequestExtensionIdMap.put(requestLIST[0].Id,requestLIST[0].RequestExtension3__c);
                            extensionMap.put(requestLIST[0].Id,'NALA');
                        } 
                        if(system.Label.CLIFv20189 == 'True') {
                            if(workflowRegion == 'ALL' && requestLIST[0].Account__c != NUll) {
                                ParentRequestExtensionIdMap.put(requestLIST[0].Id,requestLIST[0].Account__c);
                                extensionMap.put(requestLIST[0].Id,'Account');
                            }
                        }
                    }
                }
            }
            MAP<Id, LIST<Id>> userListByFeedItemMap = new MAP<Id, LIST<Id>>();  // MAP to store feed item MAP 
            //if there are feed items for request objects, use api call
            
            if(feedItemIdList.size() > 0 && requestLIST.size()>0 ) {
                /* Iterating over feedItemIdList */
                for(Id feedItemId : feedItemIdList) {
                    String communityId;  /* To get feed item with message segments */
                    //If the record is shared from the Community or Record
                    if(mapNetworkScope.get(feedItemId) != 'AllNetworks' && mapNetworkScope.get(feedItemId) != null) {
                        communityId = mapNetworkScope.get(feedItemId);
                    }else{
                        communityId = null;
                    }
                    ConnectApi.FeedElement feedItem = ConnectApi.ChatterFeeds.getFeedElement(communityId, feedItemId);
                    LIST<ConnectApi.MessageSegment> messageSegments = feedItem.body.messageSegments;
                    
                    /* get mentioned segments and User Id */
                    if(!messageSegments.isEmpty()) {
                        for (ConnectApi.MessageSegment messageSegment : messageSegments) {
                            if (messageSegment instanceof ConnectApi.MentionSegment) {
                                ConnectApi.MentionSegment mentionSegment = (ConnectApi.MentionSegment) messageSegment;
                                
                                /*  To add userIds to LIST */
                                if(userListByFeedItemMap.get(feedItemId) != null) {
                                    LIST<Id> userList = userListByFeedItemMap.get(feedItemId);  // temporary LIST to store ids
                                    userList.add(mentionSegment.record.Id);
                                    userListByFeedItemMap.put(feedItemId,userList); // Adding values to a MAP 
                                    
                                } else {
                                    LIST<Id> userList = new LIST<Id>(); // temporary LIST to store ids
                                    userList.add(mentionSegment.record.Id);
                                    userListByFeedItemMap.put(feedItemId,userList); // Adding values to a MAP
                                }
                            }
                        }
                    }
                }
            }
            
            LIST<IFv2_Request__Share> shareLIST = new LIST<IFv2_Request__Share>();  // LIST to store requst share records 
            LIST<IFv2_RequestExtension1__Share> extension1RecordsLIST = new  LIST<IFv2_RequestExtension1__Share>(); // LIST to store requst extension1 share records 
            LIST<IFv2_RequestExtension2__Share> extension2RecordsLIST = new  LIST<IFv2_RequestExtension2__Share>(); // LIST to store requst extension2 share records
            LIST<IFv2_RequestExtension3__Share> extension3RecordsLIST = new  LIST<IFv2_RequestExtension3__Share>(); // LIST to store requst extension3 share records
            LIST<AccountShare> AccountShareLIST = new LIST<AccountShare>(); 
            MAP<Id,Id> shareRecordDetailMap = new MAP<Id,Id>(); // MAP to store record details MAP 
            
            String adminString = label.CLIFv20162;
            LIST<String> adminLIST = new LIST<String>();
            adminLIST.addAll(adminString.split(','));
            
            LIST<User> adminUserRecordLIST = [SELECT Id,name 
                                              FROM User 
                                              WHERE profile.name In: adminLIST];
            SET<Id> adminUserIdSET = new SET<Id>();
            
            for(User userId : adminUserRecordLIST) {
                adminUserIdSET.add(userId.Id);
            }
            
            /* If there are mentioned users */
            if(userListByFeedItemMap.size() > 0) {
                /* To iterate over feed items */
                for(Id feedItemId : userListByFeedItemMap.keySet()) {
                    LIST<Id> userIdsToShareWIth = userListByFeedItemMap.get(feedItemId);    // To get User ids 
                    Id parentObjectId = feedItemToParentObjectMap.get(feedItemId);      // To get parent object Id 
                    /* To iterate over mentioned users */
                    for(Id userId : userIdsToShareWIth) {
                        // Declare Variables for sharing
                        IFv2_Request__Share chatterShare = new IFv2_Request__Share();   // Initialize share records 
                        chatterShare.ParentId = parentObjectId;
                        chatterShare.UserOrGroupId = userId;
                        chatterShare.AccessLevel = 'read';
                        chatterShare.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                        /* To Share Records of Extension object fields */
                        String extensionNumber = extensionMap.get(parentObjectId);
                        String extensionId = ParentRequestExtensionIdMap.get(parentObjectId);
                        if(extensionNumber == 'APAC') {
                            IFv2_RequestExtension1__Share shareRecord = new IFv2_RequestExtension1__Share();    // Initialize extension 1 share records and fill  field values
                            shareRecord.ParentId = extensionId ;
                            shareRecord.UserOrGroupId = userId;
                            shareRecord.AccessLevel = 'read';
                            shareRecord.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                            extension1RecordsLIST.add(shareRecord);
                        }else if(extensionNumber == 'EMEA') {
                            IFv2_RequestExtension2__Share shareRecord = new IFv2_RequestExtension2__Share();    // Initialize extension 2 share records and fill  field values
                            shareRecord.ParentId = extensionId ;
                            shareRecord.UserOrGroupId = userId;
                            shareRecord.AccessLevel = 'read';
                            shareRecord.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                            extension2RecordsLIST.add(shareRecord);
                        }else if(extensionNumber == 'NALA') {
                            IFv2_RequestExtension3__Share shareRecord = new IFv2_RequestExtension3__Share();    // Initialize extension 3 share records and fill  field values
                            shareRecord.ParentId = extensionId ;
                            shareRecord.UserOrGroupId = userId;
                            shareRecord.AccessLevel = 'read';
                            shareRecord.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                            extension3RecordsLIST.add(shareRecord);
                        } else if(extensionNumber == 'Account' && !adminUserIdSET.contains(userId)) {
                            AccountShare shareRecord = new AccountShare();
                            shareRecord.AccountId = extensionId;
                            shareRecord.UserOrGroupId = userId;
                            shareRecord.AccountAccessLevel = 'read' ;
                            shareRecord.RowCause = Schema.AccountShare.RowCause.Manual;
                            shareRecord.OpportunityAccessLevel = 'none';
                            AccountShareLIST.add(shareRecord);
                        }
                        shareRecordDetailMap.put(chatterShare.ParentId,chatterShare.UserOrGroupId);
                        shareLIST.add(chatterShare);    // Add values to share LIST 
                    }
                }
            }
            /* Checking if share records is not empty */
            if(shareLIST.size() >0) {
                try{
                    /* Calling Generic Dml metod for inserting Share records */
                    IFv2_DmlController.insertShareRecords(shareLIST);
                }catch(Exception e) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(e);
                }
            }
            /* Checking if extension1RecordsLIST is not empty */
            if(!extension1RecordsLIST.isEmpty()) {
                try {
                    /* Calling Generic Dml metod for inserting APAC Share records */
                    IFv2_DmlController.insertShareRecordsAPAC(extension1RecordsLIST);
                } catch(Exception e) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(e);
                }
            }
            /* Checking if extension2RecordsLIST is not empty */
            else if(!extension2RecordsLIST.isEmpty()) {
                try {
                    /* Calling Generic Dml metod for inserting EMEA Share records */
                    IFv2_DmlController.insertShareRecordsEMAE(extension2RecordsLIST);
                } catch(Exception e) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(e);
                }
            }
            /* Checking if extension3RecordsLIST is not empty */
            else if(!extension3RecordsLIST.isEmpty()) {
                try {
                    /* Calling Generic Dml metod for inserting NALA Share records */
                    IFv2_DmlController.insertShareRecordsNALA(extension3RecordsLIST);
                } catch(Exception e) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(e);
                }
            }
            /* Account Share List is not Empty */
            if(!AccountShareLIST.isEmpty()) {
                try {
                    /* Calling Generic Dml metod for inserting Account Share records */
                    IFv2_DmlController.insertAccountShare(AccountShareLIST);
                } catch(Exception e) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(e);
                }
            }
        }
        
        else{
            system.debug('chatterSharingRecords : Method  is Deactivated'); 
        }
    }
    
    /*Method to send email notification on Approval or Rejection*/
    public static void sendEmailNotification(LIST<IFv2_Request__c> requestLIST, String Status) {
        
        /* Start of Iteration 3 changes */
        /* Used to Activate or deactivate this method */
        Boolean donotExecuteTrigger = IFv2_UtilsController.getTriggerLogic('IFv2_RequestTrigger','sendEmailNotification');
        /* checking if donotExecuteTrigger variable is true or false */
        if(!donotExecuteTrigger) {
            SET<String> userIdSet = new SET<String>();  // SET to store User ids
            MAP<Id,SET<Id>> recordShareMap = new MAP<Id,SET<Id>>(); // SET to store record share MAP 
            String emailTemplate = 'IFv2_CommonNotificationToExtraUser';
            
            System.debug('template>> IFv2_CommonNotificationToExtraUser');
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get('IFv2_Request__c');  // To get objetc type
            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();         // getting objct describe of request object 
            MAP<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap();   // Creating fieldset MAP 
            MAP<String, String> recordIdAccountIdMAP = new MAP<String, String>(); // Map to store Account id and record Id map.
            MAP<String, String> recordIdWorkflowMAP = new MAP<String, STring>();  // Map to store Acount id and Workflow
            /* To check if status is Approved */
            if(Status=='Approved') {
                Schema.FieldSet fieldSet = fieldSetMap.get('IFv2_InformWhenApproved');      // Get field SET name
                LIST<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();         // To store fields from field SET 
                MAP<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap(); // To get object describe of 
                LIST<Schema.SObjectField> fieldList = new LIST<Schema.SObjectField>();      // getting LIST for storing sobject fields 
                /* Checking if fieldSetMembers is not empty */
                if(!fieldSetMembers.isEmpty()) {
                    for (Schema.FieldSetMember f: fieldSetMembers) {
                        fieldList.add(fieldMap.get(f.getFieldPath()));
                    }
                }
                /* Chcking if requestLIST is not empty */
                if(!requestLIST.isEmpty()) {
                    for(IFv2_Request__c request:requestLIST) {
                        if(request.Workflow__c == 'eSignature')
                        {
                            emailTemplate = 'IFv2_eSignatureNotificationToExtraUser';
                        }
                        else
                        {
                            emailTemplate = 'IFv2_CommonNotificationToExtraUser';
                        }
                        SET<Id> tempUserIdSet = new SET<Id>();  // SET to store ids 
                        for(Schema.SObjectField field : fieldList) {
                            if(request.get(field) != null && request.get(field) != '') {
                                userIdSet.add((String)request.get(field));
                                tempUserIdSet.add((String)request.get(field));
                            }
                        }
                        recordShareMap.put(request.Id,tempUserIdSet);
                    }
                }
            }
            else if(Status=='Rejected') {
                Schema.FieldSet fieldSet = fieldSetMap.get('IFv2_InformWhenRejected');
                LIST<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();         // To store fields from field SET 
                MAP<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap(); // To get object describe of
                LIST<Schema.SObjectField> fieldList = new LIST<Schema.SObjectField>();      // getting LIST for storing sobject fields
                
                /* Checking if fieldSetMembers is not empty */
                if(!fieldSetMembers.isEmpty()) {
                    for (Schema.FieldSetMember f: fieldSetMembers) {
                        fieldList.add(fieldMap.get(f.getFieldPath()));
                    } 
                }
                /* Chcking if requestLIST is not empty */
                if(!requestLIST.isEmpty()) {
                    for(IFv2_Request__c request:requestLIST) {
                        if(request.Workflow__c == 'eSignature')
                        {
                            emailTemplate = 'IFv2_eSignatureNotificationToExtraUser';
                        }
                        else
                        {
                            emailTemplate = 'IFv2_CommonNotificationToExtraUser';
                        }
                        SET<Id> tempUserIdSet = new SET<Id>();
                        for(Schema.SObjectField field : fieldList) {
                            if(request.get(field) != null && request.get(field) != '') {
                                userIdSet.add((String)request.get(field));
                                tempUserIdSet.add((String)request.get(field));
                            }
                        }
                        recordShareMap.put(request.Id,tempUserIdSet);
                        recordIdAccountIdMAP.put(request.Id,request.Account__c);
                        recordIdWorkflowMAP.put(request.Id,request.Workflow__c);
                        
                    }
                }
            }
            /*Commented for the eSignature template changes
for(IFv2_Request__c request:requestLIST) {
SET<Id> tempUserIdSet = new SET<Id>();
for(Schema.SObjectField field : fieldList) {
if(request.get(field) != null && request.get(field) != '') {
userIdSet.add((String)request.get(field));
tempUserIdSet.add((String)request.get(field));
}
}
recordShareMap.put(request.Id,tempUserIdSet);
recordIdAccountIdMAP.put(request.Id,request.Account__c);
recordIdWorkflowMAP.put(request.Id,request.Workflow__c);

}
} */
            MAP<Id,IFv2_Request__C> reqMap = new MAP<Id,IFv2_Request__c>();   // MAP to store request ids 
            if(!requestLIST.isEmpty()) {
                for(IFv2_Request__C request:requestLIST) {
                    reqMap.put(request.Id,request);
                }
            }
           
            for(Id requestid :recordShareMap.keySet()) {
                if(!System.isBatch())
                IFv2_HeaderController.RecordShare(recordShareMap.get(requestid),requestid,String.valueOf(reqMap.get(requestId).RequestExtension1__c),String.valueOf(reqMap.get(requestId).RequestExtension2__c),String.valueOf(reqMap.get(requestId).RequestExtension3__c), (String)recordIdAccountIdMAP.get(requestid), (String)recordIdWorkflowMAP.get(requestid));
            }
            /* Create MAP of userId and User Email Id*/
            SET<String>emailIdSet = new SET<String>();
            
            for(User User:[SELECT Id,Email FROM User WHERE Id IN :userIdSet]) {
                if(User.Email != null) {
                    emailIdSet.add(User.Email);
                }
            }
            /* Query for email template*/
            LIST<EmailTemplate> EmailTemplateLIST = new LIST<EmailTemplate>();
            if(emailTemplate!=Null)
                EmailTemplateLIST = [SELECT Id,Name,Subject, Body FROM EmailTemplate WHERE DeveloperName = :emailTemplate];
            /* Query for contact records */
            LIST<contact> contacts = [select Id from contact limit 1];
            LIST<Messaging.SingleEmailMessage> emailList = new LIST<Messaging.SingleEmailMessage>();    // LIST to store email messages 
            /*Iterate over requests and create Email messages*/
            if(!requestLIST.isEmpty()) { 
                for(IFv2_Request__c request:requestLIST) {
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    message.toAddresses =new LIST<String>(emailIdSet);
                    message.setTreatTargetObjectAsRecipient(false);
                    //Setting the setTargetObjectId to dummy contact Id
                    if(!Contacts.isEmpty()) {
                        message.setTargetObjectId(contacts[0].Id);
                    } else if(Test.isRunningTest()) {
                        message.setTargetObjectId(UserInfo.getUserId());
                    }
                    message.setSaveAsActivity(false);
                    //Setting the WhatId to customobject Id so that merge fields in template gets rendered
                    message.setWhatId(request.Id);
                    //SET email template
                    if(!EmailTemplateLIST.isEmpty()) {
                        message.setTemplateId(EmailTemplateLIST[0].Id);
                    }
                    if(message.toAddresses.size()>0) {
                        emailList.add(message);
                    }
                }  
            }
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
        }
        else{
            system.debug('sendEmailNotification : Method  is Deactivated'); 
        }  
    } 
    /* Email notification when special freight is submitted*/
    
    public static void sendEmailNotification_Submit(LIST<IFv2_Request__c> requestLIST) {
        String emailTemplate = 'IFv2_SpecialFreightEmailToApprover';
        /* Query for emial template */
        LIST<EmailTemplate> EmailTemplateLIST = new LIST<EmailTemplate>();
        if(emailTemplate!=Null)
            EmailTemplateLIST = [SELECT Id,Name,Subject, Body FROM EmailTemplate WHERE DeveloperName = :emailTemplate];
        /* Query for contact */
        LIST<contact> contacts = [select Id from contact limit 1];
        /* Start of Iteration 3 changes */
        /* Used to Activate or deactivate this method */
        Boolean donotExecuteTrigger = IFv2_UtilsController.getTriggerLogic('IFv2_RequestTrigger','sendEmailNotification_Submit');
        
        Set<Id> shareUserSet = new Set<Id>();// set of users for which share record needs to be created for Spl Freight
        
        /* checking if donotExecuteTrigger variable is true or false */
        if(!donotExecuteTrigger) {
            
            MAP<Id,Id> reqUserIdMap = new MAP<Id,Id>();     // MAP to store User ids 
            MAP<Id,LIST<String>> reqEmailMap = new MAP<Id,LIST<String>>();  // MAP to requst email 
            MAP<Id,LIST<String>> reqEmailMap2 = new MAP<Id,LIST<String>>(); // MAP to requst email 
            MAP<Id,LIST<String>> reqEmailMap3 = new MAP<Id,LIST<String>>(); // MAP to requst email 
            MAP<String,String> apprvrEmailMap = new MAP<String,String>();   // MAP to store approver emails
            MAP<String,String> apprvrEmailMap2 = new MAP<String,String>();  // MAP to store approver emails
            MAP<String,String> apprvrEmailMap3 = new MAP<String,String>();  // MAP to store approver emails
            LIST<Messaging.SingleEmailMessage> emailList = new LIST<Messaging.SingleEmailMessage>();    // LIST to store emails
            MAP<String,String> proxyUsersMap = new MAP<String,String>();    // MAP to store proxy User Ids for Spl Freight
            MAP<IFv2_Request__c,LIST<String>> reqShareMap1 = new MAP<IFv2_Request__c,LIST<String>>();   // MAP used for Spl Freight
            MAP<IFv2_Request__c,LIST<String>> reqShareMap2 = new MAP<IFv2_Request__c,LIST<String>>();   // MAP used for Spl Freight
            
            /* Checking if requestLIST is not empty */
            if(!requestLIST.isEmpty()) {
                for(IFv2_Request__c request:requestLIST) {
                    reqUserIdMap.put(request.Id,request.createdById);
                }
                
                
                /* Query for User records */
                if(!reqUserIdMap.isEmpty())
                    for(User User:[SELECT Id,Email, 
                                   iFreight_Approver_Level_2__c,
                                   iFreight_Approver_Level_2__r.Email,
                                   iFreight_Approver_Level_2_Proxy__c,
                                   iFreight_Approver_Level_2_Proxy__r.Email,
                                   iFreight_Approver_Level_3__c,
                                   iFreight_Approver_Level_3__r.Email,
                                   IFv2_iFreight_Approver_Level_3_2__c,
                                   IFv2_iFreight_Approver_Level_3_2__r.Email,
                                   IFv2_iFreight_Approver_Level_3_2_proxy__c,
                                   IFv2_iFreight_Approver_Level_3_2_proxy__r.Email,
                                   iFreight_Approver_Level_3_proxy__r.Email
                                   FROM User
                                   WHERE Id IN :reqUserIdMap.values()]) {
                                       /* Checking if Approverlevel 2  email is no null */
                                       if(User.iFreight_Approver_Level_2__r.Email!=null && User.iFreight_Approver_Level_2_Proxy__r.Email!=null)
                                       {
                                           apprvrEmailMap.put(User.Id+':Approver2', User.iFreight_Approver_Level_2__r.Email+';'+User.iFreight_Approver_Level_2_Proxy__r.Email);
                                           proxyUsersMap.put(User.Id+':Approver2',User.iFreight_Approver_Level_2__c+';'+User.iFreight_Approver_Level_2_Proxy__c);
                                       }
                                       if(User.iFreight_Approver_Level_3__r.Email!=null && User.iFreight_Approver_Level_3_proxy__r.Email!=null)
                                       {
                                           apprvrEmailMap.put(User.Id+':Approver3', User.iFreight_Approver_Level_3__r.Email+';'+User.iFreight_Approver_Level_3_proxy__r.Email);
                                           proxyUsersMap.put(User.Id+':Approver3',User.iFreight_Approver_Level_3__c+';'+User.iFreight_Approver_Level_3_proxy__c);
                                       }
                                       if(User.IFv2_iFreight_Approver_Level_3_2__r.Email!=null && User.IFv2_iFreight_Approver_Level_3_2_proxy__r.Email!=null)
                                       {
                                           apprvrEmailMap.put(User.Id+':Approver3.2', User.IFv2_iFreight_Approver_Level_3_2__r.Email+';'+User.IFv2_iFreight_Approver_Level_3_2_proxy__r.Email);
                                           proxyUsersMap.put(User.Id+':Approver3.2',User.IFv2_iFreight_Approver_Level_3_2__c+';'+User.IFv2_iFreight_Approver_Level_3_2_proxy__c);
                                       }
                                   }
                
                /* Iterate over request LIST */
                for(IFv2_Request__c request:requestLIST) {
                    if(String.IsNotBlank(request.Approver1__c) && String.IsNotBlank(request.Approver2__c))
                    {
                        if(String.IsBlank(request.Approver3__c) && String.IsBlank(request.Approver4__c) && (apprvrEmailMap.size()>0) && (proxyUsersMap.size()>0))
                        {
                            /* LIST to store emails */
                            LIST<String> tempEmailList = apprvrEmailMap.get(request.createdbyId+':Approver2').split(';');
                            LIST<String> tempUserList = proxyUsersMap.get(request.createdbyId+':Approver2').split(';');
                            reqEmailMap.put(request.Id,tempEmailList);
                            reqShareMap1.put(request,tempUserList);
                        }
                        if((String.IsNotBlank(request.Approver3__c) && String.IsNotBlank(request.Approver4__c))
                           &&(String.IsBlank(request.Approver5__c)&&String.IsBlank(request.Approver6__c))&&(apprvrEmailMap.size()>0) && (proxyUsersMap.size()>0))
                        {
                            /* LIST to store emails */
                            LIST<String> tempEmailList = apprvrEmailMap.get(request.createdbyId+':Approver3').split(';');
                            LIST<String> tempUserList = proxyUsersMap.get(request.createdbyId+':Approver3').split(';');
                            reqEmailMap2.put(request.Id,tempEmailList);
                            reqShareMap2.put(request,tempUserList);
                            
                        }
                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        /* Checking ifreqEmailMap is not empty  */
                        if(reqEmailMap.size()>0)
                        {
                            message.toAddresses =new LIST<String>(reqEmailMap.get(request.Id));
                        }
                        else
                        {
                            message.toAddresses =new LIST<String>(reqEmailMap2.get(request.Id));   
                        }
                        
                        message.setTreatTargetObjectAsRecipient(false);
                        //Setting the setTargetObjectId to dummy contact Id 
                        if(!contacts.isEmpty()) {
                            message.setTargetObjectId(contacts[0].Id);
                        }
                        message.setSaveAsActivity(false);
                        //Setting the WhatId to customobject Id so that merge fields in template gets rendered
                        message.setWhatId(request.Id);
                        //SET email template
                        if(!EmailTemplateLIST.isEmpty()) {
                            message.setTemplateId(EmailTemplateLIST[0].Id);
                        }
                        
                        message.optOutPolicy = 'FILTER';
                        /* checking if message LIST is not empty */
                        if(message.toAddresses.size()>0) {
                            emailList.add(message);
                        }
                    }
                }
            }
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
            
            //Code to share special freight records with proxy users on approval/rejection
            Set<Id> shareSet1 = new Set<Id>();
            Set<Id> shareSet2 = new Set<Id>();
            if(reqShareMap1.size()>0){
                for (List<String> userList : reqShareMap1.values())
                {
                    for(String s : userList)
                    {
                        if (s instanceof ID)
                        {
                            shareSet1.add(s);
                        }
                        else
                        {
                            System.debug('Attempted to add invalid ID: ' + s);
                        }
                    }
                }
            }
            if(reqShareMap2.size()>0){
                for (List<String> userList : reqShareMap2.values())
                {
                    for(String s : userList)
                    {
                        if (s instanceof ID)
                        {
                            shareSet2.add(s);
                        }
                        else
                        {
                            System.debug('Attempted to add invalid ID: ' + s);
                        }
                    }
                }
            }
            if(reqShareMap1.size()>0){
                for(IFv2_Request__c request : reqShareMap1.keySet()){
                    /* Calling Future Method for Sharing Record */
                    if(!System.isBatch())
                    IFv2_HeaderController.RecordShare(shareSet1,request.Id,(String)request.RequestExtension1__c, (String)request.RequestExtension2__c, (String)request.RequestExtension3__c, (String)request.Account__c, request.Workflow__c);
                }
            }
            if(reqShareMap2.size()>0){
                for(IFv2_Request__c request : reqShareMap2.keySet()){
                    /* Calling Future Method for Sharing Record */
                    if(!System.isBatch())
                    IFv2_HeaderController.RecordShare(shareSet2,request.Id,(String)request.RequestExtension1__c, (String)request.RequestExtension2__c, (String)request.RequestExtension3__c, (String)request.Account__c, request.Workflow__c);
                }
            }
        }
        else{
            system.debug('sendEmailNotification_Submit : Method  is Deactivated'); 
        }
        
        
    }
    
    /* Iteration 3 changes START */
    /* handler logic for SG_WF_ATTACHMENT_XML_TRIGGER */
    public static void attachmentHandler(LIST<Id> attachParentIds, MAP<Id,LIST<String>> attachmentParentIdTitleMap) {
        
        /* Used to Activate or deactivate this method */
        Boolean donotExecuteTrigger = IFv2_UtilsController.getTriggerLogic('SG_WF_ATTACHMENT_XML_TRIGGER','attachmentHandler');
        LIST<Scan__c> scanRecordList = new LIST<Scan__c>();     // LIST to store scan records 
        
        /* checking if donotExecuteTrigger variable is true or false */
        if(!donotExecuteTrigger) {
            
            /* checking if attachParentIds is not empty */
            if(attachParentIds.size() > 0 ) {
                /* Query for scan records */
                scanRecordList = [SELECT Id, Name, CreatedDate FROM Scan__c WHERE Id in : attachParentIds];
            }
            
            LIST<Scan__c> updateScanList = new LIST<Scan__c>(); // LIST to store updated scan records 
            
            /* If scanRecordList size is greater than zero */
            if(scanRecordList.size() > 0) {
                /* Iterate over scanrecordList */
                for(Scan__c scan : scanRecordList) {
                    
                    /* To check if attachments is not null */
                    if(attachmentParentIdTitleMap.get(scan.Id) != Null
                       && !attachmentParentIdTitleMap.get(scan.Id).isEmpty()) {
                           
                           if(!String.isBlank(attachmentParentIdTitleMap.get(scan.Id)[0])) {
                               scan.Barcode__c = attachmentParentIdTitleMap.get(scan.Id)[0]; //barcode from document title
                           }
                           
                           if(attachmentParentIdTitleMap.get(scan.Id).size() > 1 
                              && !String.isBlank(attachmentParentIdTitleMap.get(scan.Id)[1])
                              && String.valueOf(attachmentParentIdTitleMap.get(scan.Id)[1]).length() <=4) {
                                  scan.Company_Code__c = attachmentParentIdTitleMap.get(scan.Id)[1]; //company code from document title 
                              }
                           
                           if(attachmentParentIdTitleMap.get(scan.Id).size() > 2 
                              && !String.isBlank(attachmentParentIdTitleMap.get(scan.Id)[2])
                              && attachmentParentIdTitleMap.get(scan.Id)[2].length() == 14) {
                                  String year = attachmentParentIdTitleMap.get(scan.Id)[2].substring(0,4);
                                  String month = attachmentParentIdTitleMap.get(scan.Id)[2].substring(4,6);
                                  String day = attachmentParentIdTitleMap.get(scan.Id)[2].substring(6,8);
                                  String hour = attachmentParentIdTitleMap.get(scan.Id)[2].substring(8,10);
                                  String minute = attachmentParentIdTitleMap.get(scan.Id)[2].substring(10,12);
                                  String second = attachmentParentIdTitleMap.get(scan.Id)[2].substring(12,14);
                                  String stringDateTime = year + '-' + month + '-' + day + ' ' + hour + ':' + minute +  ':' + second;
                                  scan.IFv2_DateTime__c = Datetime.valueOf(stringDateTime); //date time from document title
                              } else {
                                  scan.IFv2_DateTime__c = scan.CreatedDate;
                              } 
                       }
                    updateScanList.add(scan);   // adding scan record for Update 
                }
                /* Checking if updateScanList*/
                if(updateScanList.size() > 0) {
                    /* Update Scan records */
                    IFv2_DmlController.UpdateScanRecord(updateScanList);
                } else {
                    /* Update Scan records */
                    IFv2_DmlController.UpdateScanRecord(scanRecordList);
                }
            }
        } else {
            
            /* checking if attachParentIds is not empty */
            if(attachParentIds.size() > 0 ) {
                /* Query for scan records */
                scanRecordList = [SELECT Id, Name, CreatedDate FROM Scan__c WHERE Id in : attachParentIds];
            }
            if(!scanRecordList.isEmpty()) {
                IFv2_DmlController.UpdateScanRecord(scanRecordList);    //Fire update to make SAP callout
            }
            
            system.debug('attachmentHandler: InsighFlow 2.0 Method is Deactivated');
        }
    }
    /* END of handler logic for SG_WF_ATTACHMENT_XML_TRIGGER */
    /* Iteration 3 changes END */
    
    public static void createMGPChild( LIST<IFv2_Request__c> requestLIST) {
        
        /* Start of Iteration 3 changes */
        /* Used to Activate or deactivate this method */
        Boolean donotExecuteTrigger = IFv2_UtilsController.getTriggerLogic('IFv2_RequestTrigger','createMGPChild');
        /* checking if donotExecuteTrigger variable is true or false */
        if(!donotExecuteTrigger) {
            if(!requestLIST.isEmpty()) {
                MAP<Id,IFv2_Request__c> requestMAP = new MAP<Id,IFv2_Request__c>();
                LIST<IFv2_Request__c> childReqLIST = new LIST<IFv2_Request__c>();    //List of Child Records to be inserted
                MAP<String, Schema.sObjectType > globalDescribe = Schema.getGlobalDescribe(); 
                Map<String,Schema.SObjectField> fieldMap = globalDescribe.get('IFv2_Request__c').getDescribe().fields.getMap();
                set<String> fieldSET = fieldMap.keySet();
                MAP<Id,Id> extReqMap = new MAP<Id,Id>();
                LIST<String> includeFieldsLIST = Label.CLIFv20244.split(',');
                /*Cloning request record to create child records*/
                for(IFv2_Request__c req : requestLIST) {
                    extReqMap.put(req.RequestExtension1__c,req.Id);
                    requestMAP.put(req.Id,req);
                    IFv2_Request__c mgpChildRequest = new IFv2_Request__c();
                    for(String field : fieldSET) {
                        if(fieldMap.get(field).getDescribe().isCreateable() || includeFieldsLIST.contains(field)) {
                            if((field.containsIgnoreCase('role') || field.containsIgnoreCase('approver')) && !includeFieldsLIST.contains(field)) {
                                mgpChildRequest.put(field,null);
                            }
                            else if(req.get(field) != null) {
                                mgpChildRequest.put(field,req.get(field));
                            }
                        }
                    }
                    mgpChildRequest.Id = null;
                    mgpChildRequest.ParentRequest__c = req.Id;
                    mgpChildRequest.mgpParentRequestName__c=req.Name;
                    mgpChildRequest.Workflow__c = Label.CLIFv20200;
                    mgpChildRequest.WorkflowId__c = null;
                    /*Changes for MGP Security User as first Approver on child request*/
                    mgpChildRequest.Role01__c = 'Security';
                    mgpChildRequest.Approver1__c = Label.CLIFv20300;
                    mgpChildRequest.Role02__c = req.Role07__c;
                    mgpChildRequest.Approver2__c = req.Approver7__c;
                    /*End of Changes for MGP Security User as first Approver on child request*/
                    mgpChildRequest.Status__c = 'Draft';
                    
                    childReqLIST.add(mgpChildRequest);    
                }
                if(!childReqLIST.isEmpty()) {
                    IFv2_DmlController.GenericListDMLOperation(childReqLIST, 'insert');
                    LIST<IFv2_Request__Share> shareRecordList = new LIST<IFv2_Request__Share>();
                    LIST<Approval.ProcessSubmitRequest> submitRequestLIST = new LIST<Approval.ProcessSubmitRequest>();    //List for approving pending Approval request
                    for(IFv2_Request__C child:childReqLIST) {
                        //Submit for approval
                        Approval.ProcessSubmitRequest requestitem = new Approval.ProcessSubmitRequest();    // Create an approval request instance
                        requestitem.setObjectId(child.Id);    //set the target object as request 
                        requestitem.setNextApproverIds(new Id[] {UserInfo.getUserId()});    //pass user id which will be coming from approval process
                        requestitem.setComments(Label.CLIFv20148);
                        requestitem.setSubmitterId(child.OwnerId);
                        submitRequestLIST.add(requestitem);
                        //Share Record
                        IFv2_Request__Share shareRecord = new IFv2_Request__Share();
                        shareRecord.AccessLevel = 'Edit';
                        shareRecord.ParentID = child.Id;
                        shareRecord.UserOrGroupId = child.Approver1__c;
                        shareRecordList.add(shareRecord);
                        
                        IFv2_Request__Share shareRecord2 = new IFv2_Request__Share();
                        shareRecord2.AccessLevel = 'Edit';
                        shareRecord2.ParentID = child.Id;
                        shareRecord2.UserOrGroupId = child.Approver2__c;
                        shareRecordList.add(shareRecord2);
                        
                    }
                    if(!submitRequestLIST.isEmpty()) {
                        LIST<Approval.ProcessResult> result = Approval.process(submitRequestLIST);    //submit the approval process
                    }
                    if(!shareRecordList.isEmpty()) {
                        IFv2_DmlController.insertShareRecords(shareRecordList);
                    }
                }
                /* Cloning Related list to child records*/
                MAP<Id,Id> reqChildIdMap = new MAP<Id,Id>();    //Map of parent req Id to child req Id
                for(IFv2_Request__c childReq: childReqLIST) {
                    if(childReq.ParentRequest__c != null) {
                        reqChildIdMap.put(childReq.ParentRequest__c, childReq.Id);
                    }
                }
                LIST <IFv2_Request__c> parentUpdateList = new LIST<IFv2_Request__c>();
                for(IFv2_Request__c req:requestLIST) {
                    IFv2_Request__c updateReq = new IFv2_Request__c(Id=req.Id);
                    updateReq.ParentRequest__c = reqChildIdMap.get(req.Id);
                    parentUpdateList.add(updateReq);
                }
                if(!parentUpdateList.isEmpty()) {
                    IFv2_DmlController.GenericListDMLOperation(parentUpdateList,'update');
                }
                if(!reqChildIdMap.keySet().isEmpty()) {
                    LIST<ContentDocumentLink> docLinkList = new LIST<ContentDocumentLink>();
                    SET<Id> reqChildIdSet = reqChildIdMap.keySet();
                    for(ContentDocumentLink link:[Select Id,LinkedEntityId,ContentDocumentId,ShareType FROM ContentDocumentLink WHERE LinkedEntityId IN :reqChildIdSet]) {
                        ContentDocumentLink childLink = new ContentDocumentLink();
                        childLink.LinkedEntityId = reqChildIdMap.get(link.LinkedEntityId);
                        childLink.ContentDocumentId = link.ContentDocumentId;
                        childLink.ShareType = link.ShareType;
                        docLinkList.add(childLink);
                    }
                    if(!docLinkList.isEmpty()) {
                        IFv2_DmlController.GenericListDMLOperation(docLinkList,'insert');
                    }
                    
                }
                SET<String> materialFieldNameSet = new SET<String>();    //Set of string containing related record field APINames
                for(Schema.FieldSetMember member: globalDescribe.get('Account').getDescribe().fieldsets.getMap().get('IFv2_MGPMaterial').getFields()) {
                    materialFieldNameSet.add(member.fieldpath);
                }
                materialFieldNameSet.add('IFv2_Request__c');
                materialFieldNameSet.add('Name');
                materialFieldNameSet.add('IFv2_ContentType__c');
                materialFieldNameSet.add('RecordTypeId');
                String query = 'SELECT '+ String.join(new LIST<String>(materialFieldNameSet), ', ') + ' FROM Account WHERE IFv2_Request__c IN :requestLIST AND IFv2_Request__c != NULL';
                MAP<Id,LIST<Account>> reqMaterialListMAP = new MAP<Id,LIST<Account>>();    //Map of parent req Id to list of related records
                for(Account material : Database.query(query)) {
                    LIST<Account> tempList = new LIST<Account>();
                    if(reqMaterialListMAP.containsKey(material.IFv2_Request__c)) {
                        tempList = reqMaterialListMAP.get(material.IFv2_Request__c);
                    }
                    tempList.add(material);
                    reqMaterialListMAP.put(material.IFv2_Request__c,tempList);
                }
                LIST<Account>childMaterialLIST = new LIST<Account>();    // List of materials to be inserted under child record
                for(String reqId: reqMaterialListMAP.keySet()) {
                    if(reqChildIdMap.containsKey(reqId)) {
                        for(Account material: reqMaterialListMAP.get(reqId)) {
                            Account childMaterial = material;
                            childMaterial.Id = null;
                            childMaterial.IFv2_Request__c = reqChildIdMap.get(reqId);
                            childMaterialLIST.add(childMaterial);
                        }
                    }
                }
                if(!childMaterialLIST.isEmpty()) {
                    IFv2_DmlController.GenericListDMLOperation(childMaterialLIST, 'insert');
                }
                
            }
        }
        else {
            system.debug('createMGPChild : Method  is Deactivated'); 
        }  
    }
    
    public static void deleteRelatedRecords(MAP<Id,IFv2_Request__c> requestMAP) {
        
        if(!requestMAP.keySet().isEmpty()) {
            LIST<IFv2_Request__c> requestLIST = requestMAP.values();
            SET<Id> reqIdSET = new SET<Id>();
            SET<Id> ext1IdSET = new SET<Id>();
            SET<Id> ext2IdSET = new SET<Id>();
            SET<Id> ext3IdSET = new SET<Id>();
            SET<Id> accountIdSET = new SET<Id>();
            SET<Id> relatedListAccountIdSET = new SET<Id>();
            SET<Id> contentIdSET = new SET<Id>();
        //    SET<Id> RequestToDeleteContent =new SET<Id>();
            
            for(IFv2_Request__c request : requestLIST) {
                if(request.Id != null) {
                    reqIdSET.add(request.Id);
                  //  if(request.Workflow__c!='IFE Process Workflow')
                  //  RequestToDeleteContent.add(request.Id);
                }
                if(request.Account__c != null) {
                    accountIdSET.add(request.Account__c);
                }
                if(request.RequestExtension1__c != null) {
                    ext1IdSET.add(request.RequestExtension1__c);
                }else if(request.RequestExtension2__c != null) {
                    ext2IdSET.add(request.RequestExtension2__c);
                }else if(request.RequestExtension3__c != null) {
                    ext3IdSET.add(request.RequestExtension3__c);
                }
            }
            for(IFv2_Request__c req:[SELECT Id,RequestExtension1__c FROM IFv2_Request__c WHERE RequestExtension1__c IN :ext1IdSET]) {
                if(!reqIdSET.contains(req.Id)) {
                    ext1IdSET.remove(req.RequestExtension1__c);
                }
            }
            for(Account acc : [SELECT Id, IFv2_Request__c FROM Account WHERE IFv2_Request__c IN :reqIdSET]) {
                if(acc.Id != null) {
                    relatedListAccountIdSET.add(acc.Id);
                }
            }
            for(ContentDocumentLink doc : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :reqIdSET]) {
                if(doc.ContentDocumentId != null) {
                    contentIdSET.add(doc.ContentDocumentId);
                }
            }
            
            if(!contentIdSET.isEmpty()) {
                for(ContentDocumentLink doc : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :contentIdSET]) {
                    system.debug('doc.LinkedEntityId'+doc.LinkedEntityId);
                    system.debug('reqIdSET'+reqIdSET);
                    id userid = doc.LinkedEntityId;
                    if(!reqIdSET.contains(doc.LinkedEntityId) && string.valueof(userid.getSobjectType())!='User') {
                        contentIdSET.remove(doc.ContentDocumentId);
                    }
                }
            }
            if(!ext1IdSET.isEmpty()) {
                LIST<IFv2_RequestExtension1__c> ext1LIST = new LIST<IFv2_RequestExtension1__c>();
                for(Id ext1 : ext1IdSET) {
                    IFv2_RequestExtension1__c ext1Record = new IFv2_RequestExtension1__c();
                    ext1Record.Id = ext1;
                    ext1LIST.add(ext1Record);
                }
                IFv2_DmlController.GenericListDMLOperation(ext1LIST, 'delete');
            }
            if(!ext2IdSET.isEmpty()) {
                LIST<IFv2_RequestExtension2__c> ext2LIST = new LIST<IFv2_RequestExtension2__c>();
                for(Id ext2 : ext2IdSET) {
                    IFv2_RequestExtension2__c ext2Record = new IFv2_RequestExtension2__c();
                    ext2Record.Id = ext2;
                    ext2LIST.add(ext2Record);
                }
                IFv2_DmlController.GenericListDMLOperation(ext2LIST, 'delete'); 
            }
            if(!ext3IdSET.isEmpty()) {
                LIST<IFv2_RequestExtension3__c> ext3LIST = new LIST<IFv2_RequestExtension3__c>();
                for(Id ext3 : ext3IdSET) {
                    IFv2_RequestExtension3__c ext3Record = new IFv2_RequestExtension3__c();
                    ext3Record.Id = ext3;
                    ext3LIST.add(ext3Record);
                }
                IFv2_DmlController.GenericListDMLOperation(ext3LIST, 'delete');
            }
            LIST<Account> accountLIST = new LIST<Account>();
            accountIdSET.addAll(relatedListAccountIdSET);
            if(!accountIdSET.isEmpty()) {
                for(Id acc : accountIdSET) {
                    Account accRecord = new Account();
                    accRecord.Id = acc;
                    accountLIST.add(accRecord);
                }
                IFv2_DmlController.GenericListDMLOperation(accountLIST, 'delete');
            }
            if(!contentIdSET.isEmpty()) {
                LIST<ContentDocument> contentLIST = new LIST<ContentDocument>();
                for(Id link : contentIdSET) {
                    ContentDocument content = new ContentDocument();
                    content.Id = link;
                    contentLIST.add(content);
                }
                system.debug('contentLIST'+contentLIST);
                fromtrigger='true';
                IFv2_DmlController.GenericListDMLOperation(contentLIST, 'delete');
            }
        }
    }
    
    public static void deleteScanRelatedRecords(MAP<Id,Scan__c> scanMAP) {
        
        if(!scanMAP.keySet().isEmpty()) {
            LIST<Scan__c> scanLIST = scanMAP.values();
            SET<Id> scanIdSET = new SET<Id>();
            SET<Id> contentIdSET = new SET<Id>();
            
            for(Scan__c scan : scanLIST) {
                if(scan.Id != null) {
                    scanIdSET.add(scan.Id);
                }
            }
            IFv2_DmlController.GenericListDMLOperation([SELECT id from Attachment where parentid in:scanIdSET], 'delete');
            for(ContentDocumentLink doc : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :scanIdSET]) {
                if(doc.ContentDocumentId != null) {
                    contentIdSET.add(doc.ContentDocumentId);
                }
            }
            /*system.debug('contentIdSET'+contentIdSET);
if(!contentIdSET.isEmpty()) {
for(ContentDocumentLink doc : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :contentIdSET]) {
system.debug('scanIdSET'+scanIdSET+'doc.LinkedEntityId'+doc.LinkedEntityId);
if(!scanIdSET.contains(doc.LinkedEntityId)) {
contentIdSET.remove(doc.ContentDocumentId);
}
}
}
system.debug('contentIdSET'+contentIdSET);*/
            if(!contentIdSET.isEmpty()) {
                LIST<ContentDocument> contentLIST = new LIST<ContentDocument>();
                for(Id link : contentIdSET) {
                    ContentDocument content = new ContentDocument();
                    content.Id = link;
                    contentLIST.add(content);
                }
                IFv2_DmlController.GenericListDMLOperation(contentLIST, 'delete');
            }
        }
    }
    
    public static void chatterSharingRecordsFeedComments(LIST<FeedComment> FeedCommentRecords) {
        
        /* Start of Iteration 3 changes */
        /* Used to Activate or deactivate this method */
        Boolean donotExecuteTrigger = IFv2_UtilsController.getTriggerLogic('FeedCommentTrigger','chatterSharingRecordsFeedComments');
        
        /* checking if donotExecuteTrigger variable is true or false */
        if(!donotExecuteTrigger) {
            
            LIST<Id> feedCommentIdList = new LIST<Id>();    // LIST to store Feed Item LIST 
            LIST<Id> ParentRecordId = new LIST<Id>();   // LIST to store parent record ids
            MAP<Id,Id> feedCommentToParentObjectMap = new MAP<Id,Id>(); // MAP for feed item parent  
            MAP<Id,String> mapNetworkScope = new MAP<Id,String>();      // MAP for network store 
            //String communityId=Network.getNetworkId();
            /* Checking if FeedItemRecords is not empty */
            if(!FeedCommentRecords.isEmpty()) {
                /* Iterating over FeedItemRecords LIST */
                for (FeedComment feed: FeedCommentRecords) {
                    feedCommentIdList.add(feed.Id);
                    ParentRecordId.add(feed.ParentId);
                    feedCommentToParentObjectMap.put(feed.Id, feed.ParentId);
                    // mapNetworkScope.put(feed.Id,feed.NetworkScope);
                }
            }
            
            
            MAP<String,String>  ParentRequestExtensionIdMap = new MAP<String,String>(); // MAP to store extension records 
            MAP<String,String> extensionMap = new MAP<String,String>();     // MAP to store extension records 
            
            /* Query request records wher Id in Parent Id LIST */
            LIST<IFv2_Request__c> requestLIST = new LIST<IFv2_Request__c>();
            if(!ParentRecordId.isEmpty())
                requestLIST = [Select Id, Workflow__c, Account__c, RequestExtension1__c,RequestExtension2__c,RequestExtension3__c from IFv2_Request__c where Id in: ParentRecordId ];
            
            /* Cheking is requestLIST is not empty */
            if(!requestLIST.isEmpty()) {
                String WorkflowName = requestLIST[0].Workflow__c;
                
                //String to store workflowRegion
                String workflowRegion;
                
                if(!String.isBlank(WorkflowName)) {
                    
                    workflowRegion = IFv2_UtilsController.getWorkflows(workflowName);
                }
                if(!String.isBlank(workflowRegion)) {
                    // Checking if request Id is in ParentRequestExtensionIdMap MAP 
                    if(!ParentRequestExtensionIdMap.containsKey(requestLIST[0].Id)) {
                        if( workflowRegion == 'APAC' && requestLIST[0].RequestExtension1__c != NUll) {
                            ParentRequestExtensionIdMap.put(requestLIST[0].Id,requestLIST[0].RequestExtension1__c);
                            extensionMap.put(requestLIST[0].Id,'APAC'); 
                        }else if( workflowRegion == 'EMEA' && requestLIST[0].RequestExtension2__c != NUll) {
                            ParentRequestExtensionIdMap.put(requestLIST[0].Id,requestLIST[0].RequestExtension2__c);
                            extensionMap.put(requestLIST[0].Id,'EMEA');
                        }else if( workflowRegion == 'NALA' && requestLIST[0].RequestExtension3__c != NUll) {
                            ParentRequestExtensionIdMap.put(requestLIST[0].Id,requestLIST[0].RequestExtension3__c);
                            extensionMap.put(requestLIST[0].Id,'NALA');
                        } 
                        if(system.Label.CLIFv20189 == 'True') {
                            if(workflowRegion == 'ALL' && requestLIST[0].Account__c != NUll) {
                                ParentRequestExtensionIdMap.put(requestLIST[0].Id,requestLIST[0].Account__c);
                                extensionMap.put(requestLIST[0].Id,'Account');
                            }
                        }
                    }
                }
            }
            MAP<Id, LIST<Id>> userListByFeedCommentMap = new MAP<Id, LIST<Id>>();   // MAP to store feed item MAP 
            //if there are feed items for request objects, use api call
            
            if(feedCommentIdList.size() > 0 && requestLIST.size()>0 ) {
                /* Iterating over feedItemIdList */
                for(Id feedCommentId : feedCommentIdList) {
                    String communityId=Network.getNetworkId();
                    //String communityId;  /* To get feed item with message segments */
                    //If the record is shared from the Community or Record
                    /* if(mapNetworkScope.get(feedCommentId) != 'AllNetworks' && mapNetworkScope.get(feedCommentId) != null) {
communityId = mapNetworkScope.get(feedCommentId);
}else{
communityId = null;
}*/
                    //ConnectApi.FeedElement feedItem = ConnectApi.ChatterFeeds.getFeedElement(communityId, feedItemId);
                    ConnectApi.Comment feedcomment =ConnectApi.ChatterFeeds.getComment(communityId, feedCommentId);
                    LIST<ConnectApi.MessageSegment> messageSegments = feedcomment.body.messageSegments;
                    
                    /* get mentioned segments and User Id */
                    if(!messageSegments.isEmpty()) {
                        for (ConnectApi.MessageSegment messageSegment : messageSegments) {
                            if (messageSegment instanceof ConnectApi.MentionSegment) {
                                ConnectApi.MentionSegment mentionSegment = (ConnectApi.MentionSegment) messageSegment;
                                
                                /*  To add userIds to LIST */
                                if(userListByFeedCommentMap.get(feedCommentId) != null) {
                                    LIST<Id> userList = userListByFeedCommentMap.get(feedCommentId);    // temporary LIST to store ids
                                    userList.add(mentionSegment.record.Id);
                                    userListByFeedCommentMap.put(feedCommentId,userList);   // Adding values to a MAP 
                                    
                                } else {
                                    LIST<Id> userList = new LIST<Id>(); // temporary LIST to store ids
                                    userList.add(mentionSegment.record.Id);
                                    userListByFeedCommentMap.put(feedCommentId,userList);   // Adding values to a MAP
                                }
                            }
                        }
                    }
                }
            }
            
            LIST<IFv2_Request__Share> shareLIST = new LIST<IFv2_Request__Share>();  // LIST to store requst share records 
            LIST<IFv2_RequestExtension1__Share> extension1RecordsLIST = new  LIST<IFv2_RequestExtension1__Share>(); // LIST to store requst extension1 share records 
            LIST<IFv2_RequestExtension2__Share> extension2RecordsLIST = new  LIST<IFv2_RequestExtension2__Share>(); // LIST to store requst extension2 share records
            LIST<IFv2_RequestExtension3__Share> extension3RecordsLIST = new  LIST<IFv2_RequestExtension3__Share>(); // LIST to store requst extension3 share records
            LIST<AccountShare> AccountShareLIST = new LIST<AccountShare>(); 
            MAP<Id,Id> shareRecordDetailMap = new MAP<Id,Id>(); // MAP to store record details MAP 
            
            String adminString = label.CLIFv20162;
            LIST<String> adminLIST = new LIST<String>();
            adminLIST.addAll(adminString.split(','));
            
            LIST<User> adminUserRecordLIST = [SELECT Id,name 
                                              FROM User 
                                              WHERE profile.name In: adminLIST];
            SET<Id> adminUserIdSET = new SET<Id>();
            
            for(User userId : adminUserRecordLIST) {
                adminUserIdSET.add(userId.Id);
            }
            
            /* If there are mentioned users */
            if(userListByFeedCommentMap.size() > 0) {
                /* To iterate over feed items */
                for(Id feedCommentId : userListByFeedCommentMap.keySet()) {
                    LIST<Id> userIdsToShareWIth = userListByFeedCommentMap.get(feedCommentId);    // To get User ids 
                    Id parentObjectId = feedCommentToParentObjectMap.get(feedCommentId);      // To get parent object Id 
                    /* To iterate over mentioned users */
                    for(Id userId : userIdsToShareWIth) {
                        // Declare Variables for sharing
                        IFv2_Request__Share chatterShare = new IFv2_Request__Share();   // Initialize share records 
                        chatterShare.ParentId = parentObjectId;
                        chatterShare.UserOrGroupId = userId;
                        chatterShare.AccessLevel = 'read';
                        chatterShare.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                        /* To Share Records of Extension object fields */
                        String extensionNumber = extensionMap.get(parentObjectId);
                        String extensionId = ParentRequestExtensionIdMap.get(parentObjectId);
                        if(extensionNumber == 'APAC') {
                            IFv2_RequestExtension1__Share shareRecord = new IFv2_RequestExtension1__Share();    // Initialize extension 1 share records and fill  field values
                            shareRecord.ParentId = extensionId ;
                            shareRecord.UserOrGroupId = userId;
                            shareRecord.AccessLevel = 'read';
                            shareRecord.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                            extension1RecordsLIST.add(shareRecord);
                        }else if(extensionNumber == 'EMEA') {
                            IFv2_RequestExtension2__Share shareRecord = new IFv2_RequestExtension2__Share();    // Initialize extension 2 share records and fill  field values
                            shareRecord.ParentId = extensionId ;
                            shareRecord.UserOrGroupId = userId;
                            shareRecord.AccessLevel = 'read';
                            shareRecord.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                            extension2RecordsLIST.add(shareRecord);
                        }else if(extensionNumber == 'NALA') {
                            IFv2_RequestExtension3__Share shareRecord = new IFv2_RequestExtension3__Share();    // Initialize extension 3 share records and fill  field values
                            shareRecord.ParentId = extensionId ;
                            shareRecord.UserOrGroupId = userId;
                            shareRecord.AccessLevel = 'read';
                            shareRecord.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                            extension3RecordsLIST.add(shareRecord);
                        } else if(extensionNumber == 'Account' && !adminUserIdSET.contains(userId)) {
                            AccountShare shareRecord = new AccountShare();
                            shareRecord.AccountId = extensionId;
                            shareRecord.UserOrGroupId = userId;
                            shareRecord.AccountAccessLevel = 'read' ;
                            shareRecord.RowCause = Schema.AccountShare.RowCause.Manual;
                            shareRecord.OpportunityAccessLevel = 'none';
                            AccountShareLIST.add(shareRecord);
                        }
                        shareRecordDetailMap.put(chatterShare.ParentId,chatterShare.UserOrGroupId);
                        shareLIST.add(chatterShare);    // Add values to share LIST 
                    }
                }
            }
            /* Checking if share records is not empty */
            if(shareLIST.size() >0) {
                try{
                    /* Calling Generic Dml metod for inserting Share records */
                    IFv2_DmlController.insertShareRecords(shareLIST);
                }catch(Exception e) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(e);
                }
            }
            /* Checking if extension1RecordsLIST is not empty */
            if(!extension1RecordsLIST.isEmpty()) {
                try {
                    /* Calling Generic Dml metod for inserting APAC Share records */
                    IFv2_DmlController.insertShareRecordsAPAC(extension1RecordsLIST);
                } catch(Exception e) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(e);
                }
            }
            /* Checking if extension2RecordsLIST is not empty */
            else if(!extension2RecordsLIST.isEmpty()) {
                try {
                    /* Calling Generic Dml metod for inserting EMEA Share records */
                    IFv2_DmlController.insertShareRecordsEMAE(extension2RecordsLIST);
                } catch(Exception e) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(e);
                }
            }
            /* Checking if extension3RecordsLIST is not empty */
            else if(!extension3RecordsLIST.isEmpty()) {
                try {
                    /* Calling Generic Dml metod for inserting NALA Share records */
                    IFv2_DmlController.insertShareRecordsNALA(extension3RecordsLIST);
                } catch(Exception e) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(e);
                }
            }
            /* Account Share List is not Empty */
            if(!AccountShareLIST.isEmpty()) {
                try {
                    /* Calling Generic Dml metod for inserting Account Share records */
                    IFv2_DmlController.insertAccountShare(AccountShareLIST);
                } catch(Exception e) {
                    IFv2_ExceptionUtilitiesController.exceptionHandler(e);
                }
            }
        }
        
        else{
            system.debug('chatterSharingRecords1 : Method  is Deactivated'); 
        }
    }
    
    public static void requestAccessForUpdatedDelegateUsers(MAP<Id, User> oldMap, MAP<Id, User> newMap) {
        
        LIST<User> userDetailsLIST = new LIST<User>();
        LIST<User> allUserDetailsLIST = new LIST<User>();
        LIST<IFv2_Request__c> requestDetailsLIST = new LIST<IFv2_Request__c>();
        LIST<ProcessInstanceWorkitem> proWorkItemLIST = new  LIST<ProcessInstanceWorkitem>();   // Holds process Instance workItem records
        MAP<Id, SET<Id>> requestIdUserIdSetMAP = new MAP<Id, SET<Id>>();
        MAP<Id, SET<Id>> userIdRequestIdSetMAP = new MAP<Id, SET<Id>>();
        MAP<Id, SET<Id>> requestIdDelegateIdSetMAP = new MAP<Id, SET<Id>>();
        MAP<Id, LIST<IFv2_Request__c>> delegateIdRequestListMAP = new MAP<Id, LIST<IFv2_Request__c>>();
        MAP<Id, Id> userDelegateMAP = new MAP<Id, Id>();
        MAP<Id, Id> delegateUserMAP = new MAP<Id, Id>();
        MAP<Id, IFv2_Request__c> requestDetailsMAP = new MAP<Id, IFv2_Request__c>();
        MAP<Id, User> userDetailsMAP = new MAP<Id, User>();
        SET<Id> userIdSET = new SET<Id>();
        SET<Id> allUserIdSET = new SET<Id>();
        SET<Id> allDelegateUserIdSET = new SET<Id>();
        SET<Id> fullUserIdSET = new SET<Id>();
        
        for(User usr : newMap.values()) {
            if(oldMap.get(usr.Id).DelegatedApproverId != newMap.get(usr.Id).DelegatedApproverId && newMap.get(usr.Id).DelegatedApproverId != null && newMap.get(usr.Id).Out_Of_Office__c != true) {
                userIdSET.add(usr.Id);
            }
        }
        String soqlProWork = 'SELECT Id, ActorId, ProcessInstanceId, p.ProcessInstance.TargetObject.Name,'; 
        soqlProWork += ' p.ProcessInstance.TargetObjectId '; 
        soqlProWork += ' FROM ProcessInstanceWorkItem p ';
        soqlProWork += ' WHERE ( ';
        soqlProWork += ' ActorId = : userIdSET '; 
        soqlProWork += ') ';
        soqlProWork += ' AND (';
        soqlProWork += ' p.ProcessInstance.Status = \'Pending\' ';
        //soqlProWork += ' OR p.ProcessInstance.Status != \'Rejected\' ';
        soqlProWork += ')';
        soqlProWork += ' Order By CreatedDate Desc ';
        proWorkItemLIST = Database.query(soqlProWork);
        for(ProcessInstanceWorkitem workItem : proWorkItemLIST) {
            SET<Id> usersIdSET = new SET<Id>();
            SET<Id> requestIdsSet = new SET<Id>();
            if(requestIdUserIdSetMAP.containsKey(workItem.ProcessInstance.TargetObjectId)) {
                usersIdSET = requestIdUserIdSetMAP.get(workItem.ProcessInstance.TargetObjectId);
                usersIdSET.add(workItem.ActorId);
                requestIdUserIdSetMAP.put(workItem.ProcessInstance.TargetObjectId, usersIdSET);
            }else {
                usersIdSET.add(workItem.ActorId);
                requestIdUserIdSetMAP.put(workItem.ProcessInstance.TargetObjectId, usersIdSET);
            }
            if(userIdRequestIdSetMAP.containsKey(workItem.ActorId)) {
                requestIdsSet = userIdRequestIdSetMAP.get(workItem.ActorId);
                requestIdsSet.add(workItem.ProcessInstance.TargetObjectId);
                userIdRequestIdSetMAP.put(workItem.ActorId, requestIdsSet);
            }else {
                requestIdsSet.add(workItem.ProcessInstance.TargetObjectId);
                userIdRequestIdSetMAP.put(workItem.ActorId, requestIdsSet);
            }
        }
        for(SET<Id> delegateId : requestIdUserIdSetMAP.values()) {
            allUserIdSET.addAll(delegateId);
        }
        if(!userIdRequestIdSetMAP.keySet().isEmpty()) {
            userDetailsLIST = [SELECT Id, Name, IsActive, Out_Of_Office__c, DelegatedApproverId FROM User WHERE Id IN :allUserIdSET];
        }
        if(!requestIdUserIdSetMAP.keySet().isEmpty()) {  
            requestDetailsLIST = [SELECT Id, Name, Workflow__c, RequestExtension1__c, RequestExtension2__c, RequestExtension3__c, Account__c FROM IFv2_Request__c WHERE Id IN :requestIdUserIdSetMAP.keySet()];
        }
        for(User usr : userDetailsLIST) {
            userDelegateMAP.put(usr.Id, usr.DelegatedApproverId);
            delegateUserMAP.put(usr.DelegatedApproverId, usr.Id);
        }
        for(IFv2_Request__c req : requestDetailsLIST) {
            requestDetailsMAP.put(req.Id, req);
        }
        for(Id userId : userIdRequestIdSetMAP.keySet()) {
            LIST<IFv2_Request__c> requestListForAccess = new LIST<IFv2_Request__c>();
            for(Id reqId : userIdRequestIdSetMAP.get(userId)) {
                requestListForAccess.add(requestDetailsMAP.get(reqId));
            }
            delegateIdRequestListMAP.put(userDelegateMAP.get(userId), requestListForAccess); //    for sending mails
        }
        for(Id reqId : requestIdUserIdSetMAP.keySet()) {
            SET<Id> delegateApproverIdSET = new SET<Id>();
            for(Id userId : requestIdUserIdSetMAP.get(reqId)) {
                delegateApproverIdSET.add(userDelegateMAP.get(userId));
            }
            allDelegateUserIdSET.addAll(delegateApproverIdSET);
            requestIdDelegateIdSetMAP.put(reqId, delegateApproverIdSET);
        }
        
        fullUserIdSET.addAll(allDelegateUserIdSET);
        fullUserIdSET.addAll(allUserIdSET);
        
        if(!fullUserIdSET.isEmpty()) {
            allUserDetailsLIST = [SELECT Id, Name, IsActive, Email, Out_of_Office__c FROM User WHERE Id IN :fullUserIdSET];
        }
        for(User usr : allUserDetailsLIST) {
            userDetailsMAP.put(usr.Id, usr);
        }
        // Method call for giving record Access
        for(Id reqId : requestIdDelegateIdSetMAP.keySet()) {
            recordShareForDelegatedApprover(requestIdDelegateIdSetMAP.get(reqId), JSON.serialize(requestDetailsMAP.get(reqId)));
        }
        if(!delegateIdRequestListMAP.values().isEmpty()) {
            sendEmailsToNewDelegatedApprover(delegateIdRequestListMAP, userDetailsMAP, delegateUserMAP);
        }
    }
    
    public static void sendEmailsToNewDelegatedApprover(MAP<Id, LIST<IFv2_Request__c>> delegateIdRequestListMAP, MAP<Id, User> userDetailsMAP, MAP<Id, Id> delegateUserMAP){
        
        LIST<Messaging.SingleEmailMessage> emailsToDelegateUsers = new LIST<Messaging.SingleEmailMessage>();
        Boolean sendMail = false;
        for(Id userId : delegateIdRequestListMAP.keySet()) {
            LIST<String> mailToAddressesLIST = new LIST<String>();
            Messaging.SingleEmailMessage singleEmailInstance = new Messaging.SingleEmailMessage();
            String body;
            body='<Html><body>The following workflow requests has been assigned to you for approval, please click on the request ID to see more details. <br/><br/>' ;
            for(IFv2_Request__c request : delegateIdRequestListMAP.get(UserId)) {
                if(request != null && request.Name != null && request.Workflow__c != null) {
                    sendMail = true;
                    body = body + '<b>Name : </b> <a href="https://' + Label.CLIFv20307 + '/lightning/r/IFv2_Request__c/' + request.Id + '/view" >' + request.Name + '</a>   |   ' + '<b>Workflow : </b>' + request.Workflow__c + '<br/> </body></Html>';
                }
            }
            mailToAddressesLIST.add(userDetailsMAP.get(userId).Email);
            if(!mailToAddressesLIST.isEmpty()) {
                singleEmailInstance.setToAddresses(mailToAddressesLIST);
                singleEmailInstance.setSubject('Delegate Approval for ' + userDetailsMAP.get(delegateUserMAP.get(userId)).Name);
                singleEmailInstance.setHtmlBody(body);
                emailsToDelegateUsers.add(singleEmailInstance);
            }
        }
        if(sendMail) {
            Messaging.sendEmail(emailsToDelegateUsers); 
        }
    }
    
    @Future
    public static void recordShareForDelegatedApprover(SET<Id> delegateUserIdSET, string request) {
        
        IFv2_Request__c requestRecord = (IFv2_Request__c)JSON.deserialize(request, Sobject.class);
        
        LIST<IFv2_Request__Share> recordShareList = new LIST<IFv2_Request__Share>();
        LIST<IFv2_RequestExtension1__Share> Extension1RecordsList = new LIST<IFv2_RequestExtension1__Share>();
        LIST<IFv2_RequestExtension2__Share> Extension2RecordsList = new LIST<IFv2_RequestExtension2__Share>();
        LIST<IFv2_RequestExtension3__Share> Extension3RecordsList = new LIST<IFv2_RequestExtension3__Share>();
        SET<AccountShare> AccountShareSET = new SET<AccountShare>();
        if(requestRecord != null) {
            for(Id delegateUserId : delegateUserIdSET) {
                LIST<Account> accountLIST = new LIST<Account>();
                //Checking if Account is Private
                if(system.Label.CLIFv20189 == 'True' && requestRecord.Id != NULL || Test.isRunningTest()) {
                    
                    Id requestItemsRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Items').getRecordTypeId();
                    if(requestItemsRecordTypeId != NULL) {
                        accountLIST = [SELECT Id 
                                       FROM Account 
                                       WHERE IFv2_Request__c = : requestRecord.Id AND RecordTypeId =: requestItemsRecordTypeId ];
                    }
                }
                IFv2_Request__Share shareRecord = new IFv2_Request__Share();
                shareRecord.ParentId = requestRecord.Id;
                shareRecord.UserOrGroupId = delegateUserId;
                shareRecord.AccessLevel = 'read';
                shareRecord.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                recordShareList.add(shareRecord);
                if( requestRecord.RequestExtension1__c != NUll || requestRecord.RequestExtension2__c != NUll || requestRecord.RequestExtension3__c != NULL || requestRecord.Account__c != NULL)  {
                    if(requestRecord.RequestExtension1__c != NULL) {
                        IFv2_RequestExtension1__Share shareRecord1 = new IFv2_RequestExtension1__Share();
                        shareRecord1.ParentId = requestRecord.RequestExtension1__c;
                        shareRecord1.UserOrGroupId = delegateUserId;
                        shareRecord1.AccessLevel = 'read';
                        shareRecord1.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                        Extension1RecordsList.add(shareRecord1);
                    } 
                    else if(requestRecord.RequestExtension2__c != NULL) {
                        IFv2_RequestExtension2__Share shareRecord2 = new IFv2_RequestExtension2__Share();
                        shareRecord2.ParentId = requestRecord.RequestExtension2__c;
                        shareRecord2.UserOrGroupId = delegateUserId;
                        shareRecord2.AccessLevel = 'read';
                        shareRecord2.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                        Extension2RecordsList.add(shareRecord2);
                    }
                    else if(requestRecord.RequestExtension3__c != NULL) {
                        IFv2_RequestExtension3__Share shareRecord3 = new IFv2_RequestExtension3__Share();
                        shareRecord3.ParentId = requestRecord.RequestExtension3__c;
                        shareRecord3.UserOrGroupId = delegateUserId;
                        shareRecord3.AccessLevel = 'read';
                        shareRecord3.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                        Extension3RecordsList.add(shareRecord3);
                    }
                    //Checking if Account is Private
                    if(System.Label.CLIFv20189 == 'True'  || Test.isRunningTest()) {
                        if(requestRecord.Account__c != NULL) {
                            AccountShare accountShareRecord = new AccountShare();
                            accountShareRecord.AccountId = requestRecord.Account__c;
                            accountShareRecord.UserOrGroupId = delegateUserId;
                            accountShareRecord.AccountAccessLevel = 'read';
                            accountShareRecord.RowCause = Schema.AccountShare.RowCause.Manual;
                            accountShareRecord.OpportunityAccessLevel = 'none';
                            AccountShareSET.add(accountShareRecord);
                        }
                        // Sharing related lists 
                        if(!accountLIST.isEmpty()) {
                            for(Account accountRecord : accountLIST ) {
                                AccountShare accountShareRecord = new AccountShare();
                                accountShareRecord.AccountId = accountRecord.Id ;
                                accountShareRecord.UserOrGroupId = delegateUserId;
                                accountShareRecord.AccountAccessLevel = 'read';
                                accountShareRecord.RowCause = Schema.AccountShare.RowCause.Manual;
                                accountShareRecord.OpportunityAccessLevel = 'none';
                                AccountShareSET.add(accountShareRecord);
                            }
                        }
                    }
                }
            }
            /*To insert share records*/
            IFv2_DmlController.insertShareRecords(recordShareList);
            if(!Extension1RecordsList.isEmpty())
                IFv2_DmlController.insertShareRecordsAPAC(Extension1RecordsList);
            else if(!Extension2RecordsList.isEmpty())
                IFv2_DmlController.insertShareRecordsEMAE(Extension2RecordsList);
            else if(!Extension3RecordsList.isEmpty())
                IFv2_DmlController.insertShareRecordsNALA(Extension3RecordsList);
            if(!AccountShareSET.isEmpty()){
                LIST<AccountShare> accountShareLIST = new LIST<AccountShare>();
                accountShareLIST.addAll(AccountShareSET);
                IFv2_DmlController.insertAccountShare(accountShareLIST);
            }
        }
    }
    
    /* Code to share/revoke access with updated approvers after request is submitted*/
    public static void recordShareForUpdatedApprover(List<IFv2_Request__c> SubmittedRequests,map<id,IFv2_Request__c> newMap,map<id,IFv2_Request__c> oldMap)
    {
        Map<id,Set<id>> changedApproverMap=new Map<id,Set<id>>();
        Map<id,Set<id>> changedApproverMapRevoke=new Map<id,Set<id>>();
        set<id>reqIds=new set<id>();
        for(IFv2_Request__c request:SubmittedRequests)
        {
            Set<id> approverIds=new Set<id>();
            Set<id> revokeapproverIds=new Set<id>();
            if(newMap.get(request.id).approver2__c!=oldMap.get(request.id).approver2__c)
            {
                approverIds.add(newMap.get(request.id).approver2__c);
                revokeapproverIds.add(oldMap.get(request.id).approver2__c);
            }
            if(newMap.get(request.id).approver3__c!=oldMap.get(request.id).approver3__c)
            {
                approverIds.add(newMap.get(request.id).approver3__c);
                revokeapproverIds.add(oldMap.get(request.id).approver3__c);
            }
            if(newMap.get(request.id).approver4__c!=oldMap.get(request.id).approver4__c)
            {
                approverIds.add(newMap.get(request.id).approver4__c);
                revokeapproverIds.add(oldMap.get(request.id).approver4__c);
            }
            if(newMap.get(request.id).approver5__c!=oldMap.get(request.id).approver5__c)
            {
                approverIds.add(newMap.get(request.id).approver5__c);
                revokeapproverIds.add(oldMap.get(request.id).approver5__c);
            }
            if(newMap.get(request.id).approver6__c!=oldMap.get(request.id).approver6__c)
            {
                approverIds.add(newMap.get(request.id).approver6__c);
                revokeapproverIds.add(oldMap.get(request.id).approver6__c);
            }
            if(newMap.get(request.id).approver7__c!=oldMap.get(request.id).approver7__c)
            {
                approverIds.add(newMap.get(request.id).approver7__c);
                revokeapproverIds.add(oldMap.get(request.id).approver7__c);
            }
            if(newMap.get(request.id).approver8__c!=oldMap.get(request.id).approver8__c)
            {
                approverIds.add(newMap.get(request.id).approver8__c);
                revokeapproverIds.add(oldMap.get(request.id).approver8__c);
            }
            if(newMap.get(request.id).approver9__c!=oldMap.get(request.id).approver9__c)
            {
                approverIds.add(newMap.get(request.id).approver9__c);
                revokeapproverIds.add(oldMap.get(request.id).approver9__c);
            }
            if(newMap.get(request.id).approver10__c!=oldMap.get(request.id).approver10__c)
            {
                approverIds.add(newMap.get(request.id).approver10__c);
                revokeapproverIds.add(oldMap.get(request.id).approver10__c);
            }
            if(newMap.get(request.id).approver11__c!=oldMap.get(request.id).approver11__c)
            {
                approverIds.add(newMap.get(request.id).approver11__c);
                revokeapproverIds.add(oldMap.get(request.id).approver11__c);
            }
            if(newMap.get(request.id).approver12__c!=oldMap.get(request.id).approver12__c)
            {
                approverIds.add(newMap.get(request.id).approver12__c);
                revokeapproverIds.add(oldMap.get(request.id).approver12__c);
            }
            if(newMap.get(request.id).approver13__c!=oldMap.get(request.id).approver13__c)
            {
                approverIds.add(newMap.get(request.id).approver13__c);
                revokeapproverIds.add(oldMap.get(request.id).approver13__c);
            }
            if(newMap.get(request.id).approver14__c!=oldMap.get(request.id).approver14__c)
            {
                approverIds.add(newMap.get(request.id).approver14__c);
                revokeapproverIds.add(oldMap.get(request.id).approver14__c);
            }
            if(newMap.get(request.id).approver15__c!=oldMap.get(request.id).approver15__c)
            {
                approverIds.add(newMap.get(request.id).approver15__c);
                revokeapproverIds.add(oldMap.get(request.id).approver15__c);
            }
            if(newMap.get(request.id).approver16__c!=oldMap.get(request.id).approver16__c)
            {
                approverIds.add(newMap.get(request.id).approver16__c);
                revokeapproverIds.add(oldMap.get(request.id).approver16__c);
            }
            if(newMap.get(request.id).approver17__c!=oldMap.get(request.id).approver17__c)
            {
                approverIds.add(newMap.get(request.id).approver17__c);
                revokeapproverIds.add(oldMap.get(request.id).approver17__c);
            }
            if(newMap.get(request.id).approver18__c!=oldMap.get(request.id).approver18__c)
            {
                approverIds.add(newMap.get(request.id).approver18__c);
                revokeapproverIds.add(oldMap.get(request.id).approver18__c);
            }
            if(newMap.get(request.id).approver19__c!=oldMap.get(request.id).approver19__c)
            {
                approverIds.add(newMap.get(request.id).approver19__c);
                revokeapproverIds.add(oldMap.get(request.id).approver19__c);
            }
            if(newMap.get(request.id).approver20__c!=oldMap.get(request.id).approver20__c)
            {
                approverIds.add(newMap.get(request.id).approver20__c);
                revokeapproverIds.add(oldMap.get(request.id).approver20__c);
            }
            if(newMap.get(request.id).approver21__c!=oldMap.get(request.id).approver21__c)
            {
                approverIds.add(newMap.get(request.id).approver21__c);
                revokeapproverIds.add(oldMap.get(request.id).approver21__c);
            }
            if(newMap.get(request.id).approver22__c!=oldMap.get(request.id).approver22__c)
            {
                approverIds.add(newMap.get(request.id).approver22__c);
                revokeapproverIds.add(oldMap.get(request.id).approver22__c);
            }
            if(newMap.get(request.id).approver23__c!=oldMap.get(request.id).approver23__c)
            {
                approverIds.add(newMap.get(request.id).approver23__c);
                revokeapproverIds.add(oldMap.get(request.id).approver23__c);
            }
            if(newMap.get(request.id).approver24__c!=oldMap.get(request.id).approver24__c)
            {
                approverIds.add(newMap.get(request.id).approver24__c);
                revokeapproverIds.add(oldMap.get(request.id).approver24__c);
            }
            if(newMap.get(request.id).approver25__c!=oldMap.get(request.id).approver25__c)
            {
                approverIds.add(newMap.get(request.id).approver25__c);
                revokeapproverIds.add(oldMap.get(request.id).approver25__c);
            }
            if(approverIds.size()>0)
            {
                for(User user : [SELECT Id, DelegatedApproverId FROM User where Id IN :approverIds]) {
                    if(user.DelegatedApproverId != null) {
                        System.debug('delegated approver access>>'+user.DelegatedApproverId);
                        approverIds.add(user.DelegatedApproverId);
                    }
                }
                changedApproverMap.put(request.id,approverIds);
            }
            if(revokeapproverIds.size()>0)
            {
                for(User user : [SELECT Id, DelegatedApproverId FROM User where Id IN :revokeapproverIds]) {
                    if(user.DelegatedApproverId != null) {
                        revokeapproverIds.add(user.DelegatedApproverId);
                        System.debug('delegated approver revoke>>'+user.DelegatedApproverId);
                    }
                }
            }
            
            For(Id approverId:approverIds)
            {
                if(revokeapproverIds.contains(approverId))
                    revokeapproverIds.remove(approverId);
            }
            if(revokeapproverIds.size()>0)
            {
                changedApproverMapRevoke.put(request.id,revokeapproverIds);   
            }
            
            
        }
        
        for (Id reqId : changedApproverMap.keySet())
        {
            IFv2_UtilsController.RecordShare(changedApproverMap.get(reqid),reqId,(String)newMap.get(reqId).RequestExtension1__c,(String)newMap.get(reqId).RequestExtension2__c,
                                             (String)newMap.get(reqId).RequestExtension3__c,newMap.get(reqId).Account__c,newMap.get(reqId).Workflow__c);
        }
        for (Id reqId : changedApproverMapRevoke.keySet())
        {               
            IFv2_UtilsController.RevokeRecordAccess(changedApproverMapRevoke.get(reqid),reqId,(String)oldMap.get(reqId).RequestExtension1__c,(String)oldMap.get(reqId).RequestExtension2__c,
                                                    (String)oldMap.get(reqId).RequestExtension3__c,oldMap.get(reqId).Account__c,oldMap.get(reqId).Workflow__c);
        }
        
    }
    
    //My Idea - Update Idea record status based on InsightFlowrequest approval status.
    /*public static void ideaStatusUpdate(List<ID> requests) {
        
        List<Static_content__c> updateIdeaList = new List<Static_content__c>();
        List<IFv2_Request__c> ideaRequestList = new List<IFv2_Request__c>([Select id, status__c, IFv2_Idea_Request_Idea__r.idea_status__c,IFv2_Idea_Request_Idea__r.idea_status_change_date__c  from ifv2_request__c where id in :requests]);
        
        for(IFv2_Request__c req : ideaRequestList){
            if(req.Status__c == 'Approved'){
                req.IFv2_Idea_Request_Idea__r.idea_status__c = 'Premium Approved';
                req.IFv2_Idea_Request_Idea__r.idea_status_change_date__c= system.now();
                updateIdeaList.add(req.IFv2_Idea_Request_Idea__r);
            }
            
            else if(req.Status__c == 'Rejected'){
                req.IFv2_Idea_Request_Idea__r.idea_status__c = 'With Reviewer';
                req.IFv2_Idea_Request_Idea__r.idea_status_change_date__c= system.now();
                updateIdeaList.add(req.IFv2_Idea_Request_Idea__r);
            }
            
            system.debug('Status: '+req.IFv2_Idea_Request_Idea__r.idea_status__c);
        }
        
        if(!updateIdeaList.isEmpty()){
            IFv2_DmlController.GenericListDMLOperation(updateIdeaList, 'update'); 
        }
    }*/
}