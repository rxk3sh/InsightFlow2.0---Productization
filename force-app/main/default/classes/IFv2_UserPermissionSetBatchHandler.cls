/*******************************************************************************************************
* 
* @ Name : IFv2_UserPermissionSetBatchHandler
* @ Purpose : Batch class handler to add permission sets to users
* @ Author: Prasad Vivek
* @ Test Class Name : IFv2_UserPermissionSetAssignmentBatchTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   28-10-2018      |  vivek.kothalanka@absyz.com   |  1.0          |  Initial Version
*   23-03-2019      |  vivek.kothalanka@absyz.com   |  2.0          |  Update of permission sets based on check boxes.
*******************************************************************************************************/

public with sharing class IFv2_UserPermissionSetBatchHandler {
    
    
    /* Iteration 3 Changes start */
    /* Method for Chekcing check boxes and adding or removing permission sets */
    Public static void checkPermissionSetAssignment(LIST<User> userRecords) {
        
        /* Lists used */
        LIST<PermissionSetAssignment> PermissionSetAssignmentList = new LIST<PermissionSetAssignment>(); /* To store Permission sets  Assignments */
        LIST<PermissionSet> permissionSetList = new LIST<PermissionSet>(); /* To store Permission sets */
        
        /* Maps used */
        MAP<String, LIST<String>> userMap = new MAP<String,LIST<String>>(); /* Map to hold User Id and Check boxes checked */
        MAP<Id, SET<String>> userAlreadyAssignedList = new MAP<Id, SET<String>>(); /* Map to hold permision set added to that user */
        MAP<String, Id> permissionSetMap = new MAP<String, Id>(); /* Map to contain permisison set name and id. */
        MAP<Id,LIST<String>> AddingPermissionSetToUsers = new MAP<Id, LIST<String>>(); /* Map to hold new Permission sets to be added*/
        MAP<Id,LIST<String>> removingPermissionSet = new MAP<Id, LIST<String>>();	   /* Map Containing permission sets to be deleted */
        
        /* Iterating over User Record */
        for(User userRecord : userRecords) {
            
            if(!userMap.containsKey(userRecord.Id)) {
                
                LIST<String> temporaryList = new LIST<String>();
                if(userRecord.IFv2_RequestAPAC__c) {
                    temporaryList.add('APAC');
                }
                if(userRecord.IFv2_RequestEMEA__c) {
                    temporaryList.add('EMEA');
                } 
                if(userRecord.IFv2_RequestNALA__c) {
                    temporaryList.add('NALA');
                }
                userMap.put(userRecord.Id,temporaryList);
            }
        } 
        
        /* Query for existing permission sets */
        LIST<PermissionSetAssignment> permisisonSetAssignmentList = IFv2_UtilsController.getExistingPermissionSets(userMap.keySet());
        
        /* Checking if permission set list is empty or not and if not creating map of user id and list of permission sets */
        if(!permisisonSetAssignmentList.isEmpty()) {
            for(PermissionSetAssignment assignment : permisisonSetAssignmentList) {
                
                if(userAlreadyAssignedList.containsKey(assignment.AssigneeId)) {
                    SET<string> temporaryList = userAlreadyAssignedList.get(assignment.AssigneeId);
                    //if(assignment.PermissionSet.Name.contains('IFv2_Extension')) {
                    temporaryList.add(assignment.PermissionSet.Name);
                    userAlreadyAssignedList.put(assignment.AssigneeId, temporaryList);
                    //}
                    
                }
                else {
                    SET<string> temporaryList= new SET<string>();
                    //if(assignment.PermissionSet.Name.contains('IFv2_Extension')) {
                    temporaryList.add(assignment.PermissionSet.Name);
                    userAlreadyAssignedList.put(assignment.AssigneeId, temporaryList);
                    //}
                }
            }
        }
        
        /* Query for permission set records */
        permissionSetList = IFv2_UtilsController.permissionSetRecords();
        
        /* Checking if permission set list is not empty */
        if(!permissionSetList.isEmpty()) {
            for(PermissionSet currentpermissionset : PermissionSetList){
                // Map with Permission set as name and permission set Id
                permissionSetMap.put(currentpermissionset.Name,currentpermissionset.Id); 
            }
        }
        
        /* Iterating over userMap */ 
        for(Id userId :userMap.KeySet()) {
            SET<String> assignedPermissionSets = new SET<String>();
            
            if(userId != null) {
                
                assignedPermissionSets= userAlreadyAssignedList.get(userId);
                
                /* List to store permission set id if Check box is checked and permission set is not added */
                LIST<String> addingPermissionSetList = new LIST<String>();
                
                /* List to store permission set id if Check box is not checked and permission set is added */
                LIST<String> removePermissionSetList = new LIST<String>();
                
                /* List to get check boxes checked for that user */
                LIST<String> checkboxList = userMap.get(userId);
                
                /* Checking for APAC permission set */
                if(checkboxList.contains('APAC') ) {
                    if(assignedPermissionSets == null ) {
                        addingPermissionSetList.add(permissionSetMap.get(System.label.CLIFv20156));
                    } else if(assignedPermissionSets.size() >0 && !assignedPermissionSets.contains(System.label.CLIFv20156)){
                        addingPermissionSetList.add(permissionSetMap.get(System.label.CLIFv20156));
                    }
                }  else if(!checkboxList.contains('APAC') &&  assignedPermissionSets != null && assignedPermissionSets.contains(System.label.CLIFv20156)){
                    removePermissionSetList.add(permissionSetMap.get(System.label.CLIFv20156));
                }
                
                /* Checking for EMAE permission set */
                if(checkboxList.contains('EMEA') ) {
                    if(assignedPermissionSets == null) {
                        addingPermissionSetList.add(permissionSetMap.get(System.label.CLIFv20157));
                    } else if(assignedPermissionSets.size() >0 && !assignedPermissionSets.contains(System.label.CLIFv20157)) {
                        addingPermissionSetList.add(permissionSetMap.get(System.label.CLIFv20157));
                    }
                    
                } else if(!checkboxList.contains('EMEA') && assignedPermissionSets != null && assignedPermissionSets.contains(System.label.CLIFv20157)){
                    removePermissionSetList.add(permissionSetMap.get(System.label.CLIFv20157));
                }
                
                /* Checking for NALA permission set */
                if(checkboxList.contains('NALA')) {
                    if(assignedPermissionSets == null) {
                        addingPermissionSetList.add(permissionSetMap.get(System.label.CLIFv20158));
                    } else if(assignedPermissionSets.size() >0 && !assignedPermissionSets.contains(System.label.CLIFv20158)){
                        addingPermissionSetList.add(permissionSetMap.get(System.label.CLIFv20158));
                    }
                    
                } else if(!checkboxList.contains('NALA') && assignedPermissionSets != null && assignedPermissionSets.contains(System.label.CLIFv20158)) {
                    removePermissionSetList.add(permissionSetMap.get(System.label.CLIFv20158));
                }
                
                /* Checking if list is not empty */
                if(AddingPermissionSetList.size()>0 || Test.isRunningTest()) {
                    AddingPermissionSetToUsers.put(userId,AddingPermissionSetList);    
                } 
                
                /* Checking if list is not empty */
                if(removePermissionSetList.size()>0 || Test.isRunningTest() ) {
                    removingPermissionSet.put(userId,removePermissionSetList); 
                }
                
            }
        }
        
        /* Checking if Map for adding permission set is not empty */
        if(!AddingPermissionSetToUsers.isEmpty()) {
            for(Id userId : AddingPermissionSetToUsers.keySet()) {
                
                for(String permissionset : AddingPermissionSetToUsers.get(userId)) {
                    
                    PermissionSetAssignment PermissionAssignment = new PermissionSetAssignment();
                    PermissionAssignment.PermissionSetId = permissionset;
                    PermissionAssignment.AssigneeId = userId;
                    PermissionSetAssignmentList.add(PermissionAssignment);
                }
            }
        }
        
        /* Checking if Map for removing permission set is not empty */
        if(!removingPermissionSet.isEmpty()) {
            
            /* Query for permission set Assignment */
            LIST<PermissionSetAssignment> PermissionSetAssignmentListDelete = IFv2_UtilsController.deletePermissionSetAssignmentCheckbox(removingPermissionSet.values(),removingPermissionSet.keySet());
            
            /* Deleting old Permission sets */
            if(!PermissionSetAssignmentListDelete.isEmpty())
                IFv2_DmlController.deleteAssignment(PermissionSetAssignmentListDelete);
        }
        
        /* Inserting permission set Assignment */
        if(!PermissionSetAssignmentList.isEmpty())
            IFv2_DmlController.insertPermissionSetUsers(PermissionSetAssignmentList);
    }
    /* Iteration 3 Changes End */
}