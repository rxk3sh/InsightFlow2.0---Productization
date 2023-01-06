/*******************************************************************************************************
* 
* @ Name   	 		: IFv2_HistoricScanRecordsBatchHandler
* @ Purpose 		: Batch handler to migrate related records
* @ Author  		: Pradeep Chary
* @Test class name	:  
*
*   Date        |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   21-05-2019  |  pradeep.chary@absyz.com(yv)  |  1.0          |  Initial Version
*
*******************************************************************************************************/

public class IFv2_HistoricScanRecordsBatchHandler {

    public static void populateScanFields(LIST<Scan__c> scanRecordsLIST) {
        
        /* Map of Scan Id attachment Name */
        MAP<Id,LIST<String>> attachmentParentIdTitleMap = new MAP<Id,LIST<String>>();
        /* List to update the scan records */
        LIST<Scan__c> updateScanLIST = new LIST<Scan__c>();
        SET<Id> scanRecordsIdSET = new SET<Id>();
        
        for(Scan__c scan : scanRecordsLIST) {
            scanRecordsIdSET.add(scan.Id);		//set of Scan Record Ids to be updated
        }
        
        /* Querying for the xml attachments of the Scan records */
        if(!scanRecordsIdSET.isEmpty()) {
            for(Attachment attach : [SELECT Id, ParentId, Name 
                                     FROM Attachment 
                                     WHERE (ContentType ='application/xml' OR ContentType ='text/xml')
                                     AND ParentId IN :scanRecordsIdSET]) {
                                         attachmentParentIdTitleMap.put(attach.ParentId,attach.Name.substringBefore('.').split('_',3));   
                                     } 
        }
        
        for(Scan__c scan : scanRecordsLIST) {
            
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
            updateScanLIST.add(scan);	// adding scan record for Update 
        }
        if(!updateScanLIST.isEmpty()) {
            IFv2_DmlController.GenericListDMLOperation(updateScanLIST, 'update');
        }
    }
}