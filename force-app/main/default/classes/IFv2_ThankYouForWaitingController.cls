/*******************************************************************************************************
* 
* @ Name 				: IFv2_ThankYouForWaitingController
* @ Purpose 			: Thank you page to redirect to the current system
* @ Author				: Madhura vani 
* @ Test class name    	: IFv2_ThankYouForWaitingControllerTest
*
*   Date            |  Developer Name               |T  Version     |  Changes
* ======================================================================================================
*   26-11-2018      |  madhuravani.b@absyz.com  	|  1.0          |  Initial Version   
*   08-01-2018      |  madhuravani.b@absyz.com  	|  1.1          |  Changed the controller to IFv2_ThankYouForWaitingController to navigate to the new system
*******************************************************************************************************/

public with sharing class IFv2_ThankYouForWaitingController {
    
    public static boolean displayPopUp {get; set;}
    public static String recordId; //holds the ID from the URL
    
    public IFv2_ThankYouForWaitingController() {
        try {
            recordId = ApexPages.currentPage().getParameters().get('Id');
            System.debug('recordid in class>>'+recordId);
        } catch (Exception e) {
            system.debug('Exception in ThankYouForWaiting - Couldnt parse id: ' + e.getMessage());
        }
    }
    
    /** Method to redirect to the Actual record **/
    public static PageReference redirectToActualRecord() {
        string strRedirectURL;
        LIST<IFv2_Request__Share> ShareList = new LIST<IFv2_Request__Share>();
        if(recordId != null) {
            LIST<IFv2_Request__c> objReq = new LIST<IFv2_Request__c>();
            //gets the request record from the Current System
            
            String parameterId = String.escapeSingleQuotes(recordId);
            
            objReq = [SELECT Id, Name, OldRequest__c 
                      FROM IFv2_Request__c 
                      WHERE id =: parameterId LIMIT 1];
            
            if(!objReq.isEmpty()) {
                //navigates to the detail page
                strRedirectURL = System.Label.Production_URL+ '/' + objReq[0].Id;
            } else {
                try {
                    //gets the record from the Previous system
                    objReq = [SELECT Id, Name, OldRequest__c 
                              FROM IFv2_Request__c 
                              WHERE OldRequest__c =: parameterId 
                              LIMIT 1];
                    
                    if(!objReq.isEmpty()) {
                        //navigates to the new record
                        strRedirectURL = System.Label.Production_URL+ '/' + objReq[0].Id;
                        
                        //Get Process Workitem actorId
                        ProcessInstanceWorkItem processItem = IFv2_UtilsController.getProcessInstance(recordId);
                        
                        //Share the record
                        IFv2_Request__Share chatterShare = new IFv2_Request__Share();
                        chatterShare.ParentId = objReq[0].Id;
                        System.debug('processItem>>'+processItem);
                        System.debug(' objReq[0]>>'+ objReq[0]);
                        System.debug('chatterShare.ParentId>>'+objReq[0].Id);
                        chatterShare.UserOrGroupId = processItem.ActorId;
                        System.debug('chatterShare.UserOrGroupId>>'+processItem.ActorId);
                        chatterShare.AccessLevel = 'read';
                        chatterShare.RowCause = Schema.IFv2_Request__Share.RowCause.SharingRecordsWithChatter__c;
                        ShareList.add(chatterShare);
                        if(!ShareList.isEmpty()) {
                            //inserting the share request record
                            insert ShareList;
                        }
                    } 
                    /*commented for cleaning up of Insightflow 1.0 components
* else {
ThankYouForWaitingController objThankyou = new ThankYouForWaitingController(parameterId);
strRedirectURL = ThankYouForWaitingController.redirectToActualRecord();
} */
                } catch(Exception ex) {
                    System.debug('Error: ' + ex.getMessage()); 
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Record does not exists')); 
                }
            }
        }
        //Navigates to the respective URL
        if(strRedirectURL != null && strRedirectURL != '') {
            PageReference pageRef = new PageReference(strRedirectURL);
            pageRef.setRedirect(true);
            return pageRef;
        } else {
            displayPopUp = true;
            return null;
        }
    }
    
    public PageReference clickHme() {
        string navigateHome = System.Label.Production_URL+ '/';
        PageReference pageRef = new PageReference(navigateHome);
        pageRef.setRedirect(true);
        return pageRef;
    }
}