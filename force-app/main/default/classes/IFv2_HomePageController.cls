/*******************************************************************************************************
* 
* @ Name          : IFv2_HomePageController
* @ Purpose       : Controller to display the Request details
* @ Author        : Madhura Vani
* @ TestclassName : IFv2_HomePageControllerTest
*
*   Date        |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   30-10-2018      |  madhuravani.b@absyz.com|  1.0          |  Initial Version
*
*******************************************************************************************************/
public with sharing class IFv2_HomePageController {
    
    /** Get request details based on the status **/
    @AuraEnabled 
    public static Map<String,String> getRequestDetails (String strStatus ,string sObjectName) {
        Map<String, String> mapCreatedRequests = new Map<String, String>();
        try{
            //get the request record based on the status
            List<IFv2_Request__c> lstRequest = IFv2_UtilsController.createRequest(strStatus);
            //calculate total number of requests
            Integer totalRequests = 0;
            if (lstRequest.size() > 0) {
                totalRequests = totalRequests + lstRequest.size();        
            }
            
            //while not all requests are in map 
            while(mapCreatedRequests.size() < totalRequests) {
                //used to store index and list of next request to be put in map
                Integer currentIndex = -1;
                
                //To get the latest request
                if(lstRequest.size() >0) {
                    for(Integer i=0; i<lstRequest.size(); i++) {
                        currentIndex = i;
                    }
                }
                //Add new request to map
                mapCreatedRequests.put(lstRequest.get(currentIndex).Id, lstRequest.get(currentIndex).Name);
                lstRequest.remove(currentIndex);
            }
            //return map of Id,Name sorted by CreatedDate
        }catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        return mapCreatedRequests;
    }
    
    
    /** Gets the Items to Approve records for Version 2**/
    @AuraEnabled
    public static LIST<ProcessInstanceWorkitem> getItemsToApproveVersion2 (string sObjectName) {
        SET<Id> targetObjectIds = new SET<Id>();
        LIST<ProcessInstanceWorkitem> lstItems = new LIST<ProcessInstanceWorkitem>();
        LIST<ProcessInstanceWorkitem> lstItemstoReturn = new LIST<ProcessInstanceWorkitem>();
        MAP<Id,sObject> requestIdRecordMAP = new MAP<Id,sObject>();
        lstItems = IFv2_UtilsController.createProcessInstanceWI();
        for(ProcessInstanceWorkitem objPI: lstItems) {
            targetObjectIds.add(objPI.ProcessInstance.TargetObjectId);
        }
        if(String.isNotBlank(sObjectName) && !targetObjectIds.isEmpty()) {
            List<String> lstObj = sObjectName.split(',');
            
            string query = 'SELECT ';
            query +='Id,name,Status__c'+
                ' FROM '+String.join(lstObj, ',')+' where Status__c = \'Submitted\' AND Id IN: targetObjectIds Order by NAME DESC LIMIT 50000';
            
            LIST<sObject> lstsObjects = new LIST<sObject>();
            lstsObjects = database.query(query);
            requestIdRecordMAP.putAll(lstsObjects);
            
			/* Handling extension objects requests */
			/* commented for cleaning up of Insightflow 1.0 components    
			* LIST<sObject> requestNALAList = new List<sObject>();
			LIST<sObject> requestEMEAList = new List<sObject>();
			LIST<sObject> requestAPACList = new List<sObject>(); 

			if(sObjectName == 'WF_Request__c') {
			// Querying NALA requests 
			requestNALAList = [SELECT Id, Name , Status__c
			FROM Request_NALA__c 
			WHERE Status__c = 'Submitted'
			AND Id IN : targetObjectIds
			Order BY Name DESC 
			LIMIT 50000];

			// Querying EMEA requests 
			requestEMEAList = [SELECT Id, Name , Status__c
			FROM Request_EMEA__c 
			WHERE Status__c = 'Submitted'
			AND Id IN : targetObjectIds
			Order BY Name DESC
			LIMIT 50000];

			// Querying APAC requests 
			requestAPACList = [SELECT Id, Name , Status__c
			FROM Request_APAC__c 
			WHERE Status__c = 'Submitted'
			AND Id IN : targetObjectIds
			Order BY Name DESC
			LIMIT 50000];

			// Adding all requests to comon map 
			requestIdRecordMAP.putAll(requestNALAList);
			requestIdRecordMAP.putAll(requestEMEAList);
			requestIdRecordMAP.putAll(requestAPACList);
			}
			*/
            
            //Get the ProcessInstanceWorkitems to return
            for(ProcessInstanceWorkitem objPI : lstItems) {
                if(requestIdRecordMAP.containsKey(objPI.ProcessInstance.TargetObjectId)) {
                    lstItemstoReturn.add(objPI);
                }
            }
        }
        return lstItemstoReturn;
    }
}