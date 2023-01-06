/*******************************************************************************************************
* 
* @ Name        : IFv2_WithoutSharingClass
* @ Purpose     : Class for do without sharing operations
* @ Author      : Naga Sai
* @ Test Class  : IFv2_HeaderControllerTest
*
* Date          | Developer Name            | Version   | Changes
* ======================================================================================================
* 28-10-2018    | pradeep.chary@absyz.com   | 1.0       | Initial Version
* 30-10-2018    | kanchan.baghel@absyz.com  | 1.1       | Added query 
*
*******************************************************************************************************/
public  without sharing class IFv2_WithoutSharingClass 
{ 
    public static void approveDummyApproversProcessInstances(LIST<ProcessInstanceWorkitem> approvalItemLIST, Boolean isAdmin,string strComments){
        //Approve dummy user
        if(!approvalItemLIST.isEmpty()){ 
            for(ProcessInstanceWorkitem item : approvalItemLIST){
                if((Label.CLIFv20022 == item.ActorId) || (Label.CLIFv20022 == item.OriginalActorId)||isAdmin)
                {
                    Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();  
                    pwr.setAction('Approve');
                    pwr.setComments(strComments);
                    pwr.setWorkItemId(item.id);
                    Approval.ProcessResult result = Approval.process(pwr);      
                    
                }
            }
        }
    }
}