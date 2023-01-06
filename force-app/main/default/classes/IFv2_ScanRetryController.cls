/*******************************************************************************************************
    * 
    * @ Name 			:	IFv2_ScanRetryController
    * @ Purpose 		: 	Apex class for displaying scan records list
    *						Controller for IFv2_ScanListViewCmp, IFv2_ScanHeaderCmp			
    * @ Author			: 	Pradeep Chary
    * @ Test Class Name : 	IFv2_ScanRetryControllerTest
    *
    *   Date	        |  Developer Name               |  Version      |  Changes
    * ======================================================================================================
    *   26-12-2018      |	pradeep.chary@absyz.com		|  1.0          |  Initial Version
    *
    * *******************************************************************************************************/
    
    public class IFv2_ScanRetryController {
        public static LIST<Scan__c> scanList = new  LIST<Scan__c>();
        /* Iteration 3 method to re trigger SAP callout for SCAN records START*/
        @AuraEnabled
        public static String updateScanRecord(Id scanId) {
            //Message sent back to component
            String responseString;
            //List to store queried Scan records
            LIST<Scan__c> scanRecordLIST = new  LIST<Scan__c>();
            //Querying the Scan Status, Re-trigger count and SAP Response
            if(scanId != NULL) {
                scanRecordLIST = [SELECT ID, SAP_Response__c, IFv2_SAPStatus__c
                                  FROM Scan__c
                                  WHERE Id =: scanId];
            }
            try {
                if(!scanRecordLIST.isEmpty()) {
                    Scan__c scanRecord = scanRecordLIST[0];
                    //Check for Scan Status Failed
                    if(scanRecord.IFv2_SAPStatus__c == 'Failed') {
                        scanRecord.SAP_Response__c = null;
                        scanRecord.IFv2_SAPStatus__c = 'Draft';
                        //calling genericDML operation in IFv2_DmlController
                        IFv2_DmlController.GenericDMLOperation(scanRecord, 'update');
                        responseString = 'Success';
                    } else {
                        //else Retry will not be triggered
                        responseString = 'Failure';
                    }
                }
            } catch(QueryException queryexception) {
                //calling IFv2_ExceptionUtilitiesController class
                IFv2_ExceptionUtilitiesController.exceptionHandler(queryexception);
                responseString = 'Failure';
            }
            return responseString;
        }
        /* Iteration 3 method to re trigger SAP callout for SCAN records END*/
        
        @AuraEnabled
        public static integer getFailedRecord(date fromdate,date todate) 
        {
            list<scan__c> scanListtoprocess = [SELECT ID, SAP_Response__c, IFv2_SAPStatus__c,createddate,lastmodifieddate FROM Scan__c where createddate > :fromdate and createddate < :toDate
                                               and IFv2_SAPStatus__c = 'Failed'  ];
            integer count = 0;
            for(scan__c scanObj : scanListtoprocess )
            {  
                if(scanObj.createddate.date() == scanObj.LastModifiedDate.date())
                {
                    count = count+1;
                } 
            }
            return count;
        }
        @AuraEnabled
        public static string reprocessFailedRecord(date fromdate,date todate) 
        {
            string returnResult;String responseString;
            system.debug('fromdate111 '+fromdate+'  todat '+todate );
            list<scan__c> scanListtoprocess = [SELECT ID, SAP_Response__c, IFv2_SAPStatus__c,createddate,lastmodifieddate FROM Scan__c where createddate > :fromdate and createddate < :toDate
                                               and IFv2_SAPStatus__c = 'Failed'  ];
            for(scan__c scanObj : scanListtoprocess )
            {  
                if(scanObj.createddate.date() == scanObj.LastModifiedDate.date())
                {
                    scanList.add(scanObj);
                } 
            }
            integer count = scanList.size(); system.debug('count '+count);
            if(count > 0)
            {
                map<id, string> responseMap = new map<id,string>();
                for(integer i = 0; i<50 && i<count; i++)
                {
                    Scan__c scanObj = scanList[i];
                    try {
                        if(scanObj.IFv2_SAPStatus__c == 'Failed') {
                            scanObj.SAP_Response__c = null;
                            scanObj.IFv2_SAPStatus__c = 'Draft';
                            IFv2_DmlController.GenericDMLOperation(scanObj, 'update');
                            responseString = 'Success';
                        } else {
                            responseString = 'Failure';
                        }
                        
                    } catch(QueryException queryexception) {
                        IFv2_ExceptionUtilitiesController.exceptionHandler(queryexception);
                        responseString = 'Failure';
                    }
                    responseMap.put(scanObj.id, responseString);
                }
                system.debug('responseMap '+responseMap);
                integer failedcount = 0;
                integer successCount = 0;
                for(Id key: responseMap.keySet()){
                    if(responseMap.get(key) == 'Success')
                        successCount =successCount+1;
                    else
                        failedcount = failedcount+1; 
                }
                returnResult = 'No:Records Processed = '+successCount+'\n'+'No:Records failed during retry = '+failedcount;
            }
            return returnResult;
        }
    }