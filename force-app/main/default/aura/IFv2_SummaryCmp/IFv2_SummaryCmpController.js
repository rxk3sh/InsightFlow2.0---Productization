({
    doInit : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        helper.callToServer(component,"c.fetchRelatedRequests",
                            function(response){
                                if(response !== undefined){
                                    console.log('response:',response);
                                    if(response.isApprover){
                                        component.set("v.isApprover",response.isApprover);
                                        if( response.reqList !== undefined){
                                            component.set("v.requestList",response.reqList);
                                            component.set("v.count",response.reqList.length+1);
                                            component.set("v.scanRequestCount",response.allScanRequestCount);
                                            component.set("v.scanOtherUserCount",response.scanOtherPendingUserCount);
                                            component.set("v.scanAllUserPendingCount",response.scanAllPendingCount);
                                            component.set("v.scanOtherRequestList",response.scanOtherPendingReqList);
                                        }
                                        else{
                                            component.set("v.count",1);
                                            component.set("scanRequestCount",1)
                                        }
                                        if( response.workflowName !== undefined){
                                            component.set("v.workflowName",response.workflowName);
                                        }
                                        if( response.workflowDesc !== undefined){
                                            component.set("v.workflowDesc"," - "+response.workflowDesc);
                                        }
                                    }
                                    else{
                                        component.set("v.isApprover",false);
                                    }
                                }
                            },
                            {
                                "recId" : recordId,
                                "status": component.get("v.status")
                            },
                            false);
        
    }
})