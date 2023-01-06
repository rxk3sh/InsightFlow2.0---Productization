/*******************************************************************************************************
* 
* @ Name		:  IFv2_DummyApproveBatchHandler
* @ Purpose		:  Handler class for IFv2_DummyApproveBatch
* @ Author		:  Anoop Ravindran
* @ Test Class  :  IFv2_DummyApproveBatchTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   23-04-2019      |  anoop.ravindran@absyz.com    |  1.0          |  Initial Version

*******************************************************************************************************/

public with sharing class IFv2_DummyApproveBatchHandler {
    public static void dummyApprove(LIST<ProcessInstanceWorkitem> approvalLIST, String objectName){
        LIST<Approval.ProcessWorkitemRequest> workItemRequestLIST = new LIST<Approval.ProcessWorkitemRequest>();    //List for approving pending Approval request
        for(ProcessInstanceWorkitem item:approvalLIST){
            Id recId = item.ProcessInstance.TargetObjectId;
            if(recId != null){
                if(recId.getSObjectType().getDescribe().getName() == objectName){
                    
                    Approval.ProcessWorkitemRequest workItemRequest = new Approval.ProcessWorkitemRequest();  
                    workItemRequest.setAction('Approve');
                    workItemRequest.setComments('Automated Approval');
                    workItemRequest.setWorkItemId(item.id);
                    workItemRequestLIST.add(workItemRequest);
                }
            }
        }
        LIST<Approval.ProcessResult> result = Approval.process(workItemRequestLIST);
    }
}