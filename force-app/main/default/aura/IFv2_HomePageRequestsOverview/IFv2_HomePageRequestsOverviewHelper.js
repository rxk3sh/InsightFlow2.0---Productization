({
    /* Generic call to server */
    callToServer: function(component, method, callback, params) {
        component.set("v.showSpinner", true);
        var action = component.get(method);
        action.setStorable();
        if (params) {
            action.setParams(params);
        }
        action.setCallback(this, function(response) {
            component.set("v.showSpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                callback.call(this, response.getReturnValue());
            } else if(state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.alertMessage", "Error message: " + errors[0].message);
                        component.set("v.isAlert", true);
                    }
                }
            } else {
                component.set("v.alertMessage", "ERROR: Unknown Error");
                component.set("v.isAlert", true);
            }
        });
        $A.enqueueAction(action);
    },
    
    requestDetails : function(component, event) {
        component.set("v.displayChart", false);
        var self = this;
        /* Fetch the Request records */
        self.callToServer(
            component,
            "c.getRequests", /* server method to fetch the Request details */
            function(response) {
                var mapObject = {}; //map to hold the label and requests
                var mapColor = {};
                var requests = response.lstRequest;
                var delegateRequests = response.lstDelegate;
                var requestLength = requests.length;
                var draftRecords = []; //Draft records
                var approvedRecords = []; //Approved Records
                var rejectedRecords = []; // Rejected Records
                var sumittedRecords = []; //Submitted Records
                //renju
                var MySubmittedRecords=[];
                //
                var overdueRecords = []; //Overdue Records
                var itemToApproveRecords = []; //Pending Records (Items to Approve)
                var approvedByMeRecords =[]; //Approved By Me
                var metadata = []; //Metadata records
                var overDueReq = []; //Overdue records
                var itemsToApprove = []; // Items to Approve
                var approvedByMe = []; // Approved by me
                var DelegateRecords = []; //delegated Requests
				var proxyApprovedRequests = response.lstItemsApprovedByProxy; // proxy approved Request records
				var proxyRejectedRequests = response.lstItemsRejectedByProxy; // proxy rejected Request records
				var approvedReqRecords = []; //delegated Requests
				var rejectedReqRecords = []; //delegated Requests
                
                if(response.lstMetadata !== undefined)
                    metadata = response.lstMetadata;
               // alert(JSON.stringify(metadata));
                
                if(response.lstItemsToApprove !== undefined) {
                    for(var i=0; i<response.lstItemsToApprove.length; i++) {
                        if(response.lstItemsToApprove[i].lstOverdueProcessInstance !== undefined
                           && response.lstItemsToApprove[i].lstOverdueProcessInstance !== null) {
                            overDueReq.push(response.lstItemsToApprove[i]); 
                        } else if(response.lstItemsToApprove[i].lstToApproveProcessInstance !== undefined
                                  && response.lstItemsToApprove[i].lstToApproveProcessInstance !== null) {
                            itemsToApprove.push(response.lstItemsToApprove[i]);
                        }
                    }
                } 
                
                if(response.lstItemsApprovedByMe !== undefined)
                    approvedByMe = response.lstItemsApprovedByMe;
                
                mapObject[$A.get("$Label.c.CLIFv20115")] = []; //Draft
                mapObject[$A.get("$Label.c.CLIFv20114")] = []; //Approved
                mapObject[$A.get("$Label.c.CLIFv20116")] = []; //Rejected
                mapObject[$A.get("$Label.c.CLIFv20117")] = []; //Submitted
				mapObject[$A.get("$Label.c.proxyApproved")] = []; //proxyApproved
				mapObject[$A.get("$Label.c.proxyRejected")] = []; //proxyRejected 
                
                //Datatable for Applicant"s Request
                for(var i=0; i<requestLength; i=i+1) {
                    var request = requests[i];
                    request.Id = "/"+requests[i].Id;
                    if(requests[i].CreatedBy.Name !== undefined) {
                        request.RequestorName = requests[i].CreatedBy.Name;
                        request.RequestorId = requests[i].CreatedBy.Id;
                    }
                    
                    //Preparing the list of Draft records
                    if(request.Status__c !== undefined) {
                        if(request.Status__c === "Draft") {
                            draftRecords.push(request);
                            if(draftRecords !== undefined) {
                                mapObject[$A.get("$Label.c.CLIFv20115")] = draftRecords;
                            }
                        } else if(request.Status__c === "Approved") { //Preparing the list of Approved Records
                            approvedRecords.push(request);
                            if(approvedRecords !== undefined) {
                                mapObject[$A.get("$Label.c.CLIFv20114")] = approvedRecords;
                            }
                        } else if(request.Status__c === "Rejected") { //Preparing the list of Rejected Records
                            rejectedRecords.push(request);
                            if(rejectedRecords !== undefined) {
                                mapObject[$A.get("$Label.c.CLIFv20116")] = rejectedRecords;
                            }
                        } 
                           /* 
                            else if(request.Status__c === "Submitted") { //Preparing the list of Rejected Records
                            sumittedRecords.push(request);
                            var sumittedPI = [];
                            sumittedPI=response.MySubmittedWrapper;
                          //  alert('>'+JSON.stringify(response.PIWIDetails));
                            if(request !== undefined) {      
                                mapObject[$A.get("$Label.c.CLIFv20117")] = sumittedRecords;
                            }
                        } */
                    }
                } 
                //Preparing Overdue requests
                if(overDueReq.length > 0) {
                    component.set("v.overDueRequestSize",true);
                    for(var i=0; i<overDueReq.length; i=i+1) {
                        var overdueRec = {};
                        if(overDueReq[i].objOverdueRequest !== undefined) {
                            if(overDueReq[i].objOverdueRequest.Name !== undefined) {
                                overdueRec.Name = overDueReq[i].objOverdueRequest.Name;
                            }
                            if(overDueReq[i].objOverdueRequest.Id !== undefined) {
                                overdueRec.Id = "/" + overDueReq[i].objOverdueRequest.Id;
                            }
                            if(overDueReq[i].objOverdueRequest.Workflow__c !== undefined) {
                                overdueRec.Workflow__c = overDueReq[i].objOverdueRequest.Workflow__c;
                            }
                            if(overDueReq[i].objOverdueRequest.CreatedBy.Name !== undefined) {
                                overdueRec.RequestorName =overDueReq[i].objOverdueRequest.CreatedBy.Name;
                            }
                            if(overDueReq[i].objOverdueRequest.CreatedBy.Id !== undefined) {
                                overdueRec.RequestorId ='/'+overDueReq[i].objOverdueRequest.CreatedBy.Id;
                            }
                            if(overDueReq[i].lstOverdueProcessInstance !== undefined) {
                                if(overDueReq[i].lstOverdueProcessInstance.CreatedDate !== undefined) {
                                    overdueRec.SubmittedDate = overDueReq[i].lstOverdueProcessInstance.CreatedDate;
                                }
                                if(overDueReq[i].objOverdueRequest.CreatedDate !== undefined)
                                {
                                    overdueRec.CreatedDate = overDueReq[i].objOverdueRequest.CreatedDate; 
                                }
                            }
                            if(overDueReq[i].objOverdueRequest.Status__c !== undefined) {
                                overdueRec.Status__c = overDueReq[i].objOverdueRequest.Status__c;
                            }
                            overdueRecords.push(overdueRec);
                        }
                    }
                    if(overdueRecords !== undefined) {
                        mapObject[$A.get("$Label.c.CLIFv20119")] = overdueRecords;
                    }
                } else {
                    mapObject[$A.get("$Label.c.CLIFv20119")] = [];
                    component.set("v.overDueRequestSize",false);
                }
                // renju
                MySubmittedRecords=response.lstItemsSubmitted;
                var MySubmitted=[];
                
                 //Preparing Overdue requests
                if(MySubmittedRecords.length > 0) {
                  //  component.set("v.overDueRequestSize",true);
                    for(var i=0; i<MySubmittedRecords.length; i=i+1) {
                        var SubmittedRec = {};
                                                
                        if(MySubmittedRecords[i].MySubmittedRequest !== undefined) {
                            if(MySubmittedRecords[i].MySubmittedRequest.Name !== undefined) {
                                SubmittedRec.Name = MySubmittedRecords[i].MySubmittedRequest.Name;
                            }
                            if(MySubmittedRecords[i].MySubmittedRequest.Id !== undefined) {
                                SubmittedRec.Id = "/" + MySubmittedRecords[i].MySubmittedRequest.Id;
                            }
                            if(MySubmittedRecords[i].MySubmittedRequest.Workflow__c !== undefined) {
                                SubmittedRec.Workflow__c = MySubmittedRecords[i].MySubmittedRequest.Workflow__c;
                            }
                            if(MySubmittedRecords[i].MySubmittedRequest.CreatedBy.Name !== undefined) {
                                SubmittedRec.RequestorName =MySubmittedRecords[i].MySubmittedRequest.CreatedBy.Name;
                            }
                            if(MySubmittedRecords[i].MySubmittedRequest.CreatedBy.Id !== undefined) {
                                SubmittedRec.RequestorId ='/'+MySubmittedRecords[i].MySubmittedRequest.CreatedBy.Id;
                            }
                            if(MySubmittedRecords[i].MySubmittedPI !== undefined) {
                                if(MySubmittedRecords[i].MySubmittedPI.CreatedDate !== undefined) {
                                    SubmittedRec.SubmittedDate = MySubmittedRecords[i].MySubmittedPI.CreatedDate;
                                }
                                if(MySubmittedRecords[i].MySubmittedRequest.CreatedDate !== undefined)
                                {
                                    SubmittedRec.CreatedDate = MySubmittedRecords[i].MySubmittedRequest.CreatedDate; 
                                }
                            }
                            if(MySubmittedRecords[i].MySubmittedRequest.Status__c !== undefined) {
                                SubmittedRec.Status__c = MySubmittedRecords[i].MySubmittedRequest.Status__c;
                            }
                            MySubmitted.push(SubmittedRec);
                        } 
                    }
                    if(MySubmitted !== undefined) {
                        mapObject[$A.get("$Label.c.CLIFv20117")]=MySubmitted;
                    }
                } else {
                    	mapObject[$A.get("$Label.c.CLIFv20117")] = [];
                   // component.set("v.overDueRequestSize",false);
                }
                // renju
                
                //Items to Approve
                if(itemsToApprove.length > 0) {
                    component.set("v.requestToApproveFlag",true);
                    for(var i=0; i<itemsToApprove.length; i=i+1) {
                        var itemsToApproveRec = {};
                        if(itemsToApprove[i].objToApproveRequest !== undefined) {
                            if(itemsToApprove[i].objToApproveRequest.Name !== undefined) {
                                itemsToApproveRec.Name = itemsToApprove[i].objToApproveRequest.Name;
                            }
                            if(itemsToApprove[i].objToApproveRequest.Id !== undefined) {
                                itemsToApproveRec.Id = "/" + itemsToApprove[i].objToApproveRequest.Id;
                            }
                            if(itemsToApprove[i].objToApproveRequest.Workflow__c !== undefined) {
                                itemsToApproveRec.Workflow__c = itemsToApprove[i].objToApproveRequest.Workflow__c;
                            }
                            if(itemsToApprove[i].objToApproveRequest.CreatedBy.Name !== undefined) {
                                itemsToApproveRec.RequestorName =itemsToApprove[i].objToApproveRequest.CreatedBy.Name;
                            }
                            if(itemsToApprove[i].objToApproveRequest.CreatedBy.Id !== undefined) {
                                itemsToApproveRec.RequestorId ='/'+itemsToApprove[i].objToApproveRequest.CreatedBy.Id;
                            }
                            if(itemsToApprove[i].lstToApproveProcessInstance !== undefined) {
                                if(itemsToApprove[i].lstToApproveProcessInstance.CreatedDate !== undefined) {
                                    itemsToApproveRec.SubmittedDate = itemsToApprove[i].lstToApproveProcessInstance.CreatedDate;
                                }
                                if(itemsToApprove[i].objToApproveRequest.CreatedDate !== undefined)
                                {
                                    itemsToApproveRec.CreatedDate = itemsToApprove[i].objToApproveRequest.CreatedDate; 
                                }
                            }
                            if(itemsToApprove[i].objToApproveRequest.Status__c !== undefined) {
                                itemsToApproveRec.Status__c = itemsToApprove[i].objToApproveRequest.Status__c;
                            }
                            itemToApproveRecords.push(itemsToApproveRec);
                        }
                    }
                    if(itemToApproveRecords !== undefined) {
                        mapObject[$A.get("$Label.c.CLIFv20118")] = itemToApproveRecords; 
                    }
                } else {
                    component.set("v.requestToApproveFlag",false);
                    mapObject[$A.get("$Label.c.CLIFv20118")] = []; //creating empty map if there are no records
                }
                //Requests Approved By Me
                if(approvedByMe.length  > 0) {
                    for(var i=0; i<approvedByMe.length; i=i+1) {
                        var approvedByMeRec = {};
                        if(approvedByMe[i].strRequest !== undefined) {
                            if(approvedByMe[i].strRequest.Name !== undefined) {
                                approvedByMeRec.Name = approvedByMe[i].strRequest.Name;
                            }
                            if(approvedByMe[i].strRequest.Id !== undefined) {
                                approvedByMeRec.Id = "/" + approvedByMe[i].strRequest.Id;
                            }
                            if(approvedByMe[i].strRequest.Workflow__c !== undefined) {
                                approvedByMeRec.Workflow__c = approvedByMe[i].strRequest.Workflow__c;
                            }
                            if(approvedByMe[i].strRequest.CreatedBy.Name !== undefined) {
                                approvedByMeRec.RequestorName =approvedByMe[i].strRequest.CreatedBy.Name;
                            }
                            if(approvedByMe[i].strRequest.CreatedBy.Id !== undefined) {
                                approvedByMeRec.RequestorId ='/'+approvedByMe[i].strRequest.CreatedBy.Id;
                            }
                            if(approvedByMe[i].strRequest.CreatedDate !== undefined){
                                approvedByMeRec.CreatedDate = approvedByMe[i].strRequest.CreatedDate; 
                            }
                            if(approvedByMe[i].objProcessInstance !== undefined) {
                                if(approvedByMe[i].objProcessInstance.ProcessInstance !== undefined) {
                                    if(approvedByMe[i].objProcessInstance.ProcessInstance.CreatedDate !== undefined) {
                                     //   approvedByMeRec.SubmittedDate = approvedByMe[i].objProcessInstance.ProcessInstance.CreatedDate;
                                    }
                                }
                            }
                            /* code update for migrated Account  start here */
                            if(approvedByMe[i].AccountProcessInstance !== undefined) {
                                //if(approvedByMe[i].AccountProcessInstance.ProcessInstance !== undefined) {
                                    if(approvedByMe[i].AccountProcessInstance.CreatedDate !== undefined) {
                                    //    approvedByMeRec.SubmittedDate = approvedByMe[i].AccountProcessInstance.CreatedDate;
                                    }
                                //}
                            }
                            /* code end here */
                            if(approvedByMe[i].strRequest.Status__c !== undefined) {
                                approvedByMeRec.Status__c = approvedByMe[i].strRequest.Status__c;
                            }
                            approvedByMeRecords.push(approvedByMeRec);
                        }
                    }
                    if(approvedByMeRecords !== undefined) {
                        mapObject[$A.get("$Label.c.CLIFv20120")] = approvedByMeRecords;
                    }
                } else{
                    mapObject[$A.get("$Label.c.CLIFv20120")] = [];
                }
                //delegated Requests
                if(delegateRequests.length > 0) {
                    var delegated=[];
                    component.set("v.DelegatedOverDueRequestflag",true);
                    for(var i=0; i<delegateRequests.length; i=i+1) {
                        var SubmittedRec = {};
                                                
                        if(delegateRequests[i].DelegatedRequest !== undefined) {
                            if(delegateRequests[i].DelegatedRequest.Name !== undefined) {
                                SubmittedRec.Name = delegateRequests[i].DelegatedRequest.Name;
                            }
                            if(delegateRequests[i].DelegatedRequest.Id !== undefined) {
                                SubmittedRec.Id = "/" + delegateRequests[i].DelegatedRequest.Id;
                            }
                            if(delegateRequests[i].DelegatedRequest.Workflow__c !== undefined) {
                                SubmittedRec.Workflow__c = delegateRequests[i].DelegatedRequest.Workflow__c;
                            }
                            if(delegateRequests[i].DelegatedRequest.CreatedBy.Name !== undefined) {
                                SubmittedRec.RequestorName =delegateRequests[i].DelegatedRequest.CreatedBy.Name;
                            }
                            if(delegateRequests[i].DelegatedRequest.CreatedBy.Id !== undefined) {
                                SubmittedRec.RequestorId ='/'+delegateRequests[i].DelegatedRequest.CreatedBy.Id;
                            }
                            if(delegateRequests[i].DelegatedPI !== undefined) {
                                if(delegateRequests[i].DelegatedPI.CreatedDate !== undefined) {
                                    SubmittedRec.SubmittedDate = delegateRequests[i].DelegatedPI.CreatedDate;
                                }
                                if(delegateRequests[i].DelegatedRequest.CreatedDate !== undefined)
                                {
                                    SubmittedRec.CreatedDate = delegateRequests[i].DelegatedRequest.CreatedDate; 
                                }
                            }
                            if(delegateRequests[i].DelegatedRequest.Status__c !== undefined) {
                                SubmittedRec.Status__c = delegateRequests[i].DelegatedRequest.Status__c;
                            }
                            delegated.push(SubmittedRec);
                        } 
                    }
                    if(delegated.length > 0) {
                            mapObject[$A.get("$Label.c.CLIFv20121")] = delegated;
                        } else {
                            mapObject[$A.get("$Label.c.CLIFv20121")] = [];  
                        }
                    /*
                    
                    for(var i=0; i<delegateRequests.length; i=i+1) {
                        var delegateRequest = delegateRequests[i];
                        delegateRequest.Id = "/"+delegateRequests[i].Id;
                        if(delegateRequests[i].CreatedBy.Name !== undefined) {
                            delegateRequest.RequestorName = delegateRequests[i].CreatedBy.Name;
                            delegateRequest.RequestorId = delegateRequests[i].CreatedBy.Id;
                        }
                        DelegateRecords.push(delegateRequest);
                        //Delegated Approvers
                        if(response.lstDelegate.length > 0) {
                            mapObject[$A.get("$Label.c.CLIFv20121")] = DelegateRecords;
                        } else {
                            mapObject[$A.get("$Label.c.CLIFv20121")] = [];  
                        }
                    }
                    */
                }
                else {
                    component.set("v.DelegatedOverDueRequestflag",false);
                }
                
				//Proxy approved Records when user OOO
				if(proxyApprovedRequests.length > 0) {
					component.set("v.proxyApprovedflag",true);
					
					for(var i=0; i<proxyApprovedRequests.length; i=i+1) {
						
                        var approvedRequest = proxyApprovedRequests[i];
                        approvedRequest.Id = "/"+proxyApprovedRequests[i].Id;
						
						if(proxyApprovedRequests[i].CreatedBy.Name !== undefined) {
                            approvedRequest.RequestorName = proxyApprovedRequests[i].CreatedBy.Name;
                            approvedRequest.RequestorId = proxyApprovedRequests[i].CreatedBy.Id;
                        }
						approvedReqRecords.push(approvedRequest);
						//Proxy approved Records
                        if(response.lstItemsApprovedByProxy.length > 0) {
                            mapObject[$A.get("$Label.c.proxyApproved")] = approvedReqRecords;
                        } else {
                            mapObject[$A.get("$Label.c.proxyApproved")] = [];  
                        }
					}
				} else {
                    component.set("v.proxyApprovedflag",false);
                }
				
				//Proxy rejected Records when user OOO
				if(proxyRejectedRequests.length > 0) {
					component.set("v.proxyRejectedflag",true);
					
					for(var i=0; i<proxyRejectedRequests.length; i=i+1) {
						
                        var rejectedRequest = proxyRejectedRequests[i];
                        rejectedRequest.Id = "/"+proxyRejectedRequests[i].Id;
						
						if(proxyRejectedRequests[i].CreatedBy.Name !== undefined) {
                            rejectedRequest.RequestorName = proxyRejectedRequests[i].CreatedBy.Name;
                            rejectedRequest.RequestorId = proxyRejectedRequests[i].CreatedBy.Id;
                        }
						rejectedReqRecords.push(rejectedRequest);
						//Proxy rejected Records
                        if(response.lstItemsRejectedByProxy.length > 0) {
                            mapObject[$A.get("$Label.c.proxyRejected")] = rejectedReqRecords;
                        } else {
                            mapObject[$A.get("$Label.c.proxyRejected")] = [];  
                        }	
					}
				} else {
                    component.set("v.proxyRejectedflag",false);
                }
				
                component.set("v.mapObject", mapObject); //holds label and list of requests
                var strStatusCount = [];
                var count = 0;
                for(var i=0; i<metadata.length; i++) {
                    var record = metadata[i];
                    mapColor[record.Label] = record.Color__c;
                    component.set("v.mapColors", mapColor);
                    var APIName = record.DeveloperName;
                    if(mapObject[APIName] !== undefined) {
                        if(mapObject[APIName].length > 0) {
                            if(record.Default__c || count === 0) {                             
                                if(component.get("v.overDueRequestSize")===true)
                                {
                                    component.set("v.index", "RequeststoApproveApprovalOverdue");
                                    self.requestStatusData(component, event, "RequeststoApproveApprovalOverdue");
                                //    alert('check due index>'+component.get("v.index"));
                                }   
                                else if(component.get("v.requestToApproveFlag")===true)
                                {
                                    component.set("v.index", "RequeststoApprove");
                                    self.requestStatusData(component, event, "RequeststoApprove");
                                }
                                else if(component.get("v.DelegatedOverDueRequestflag")===true)
                                {
                                    component.set("v.index", "RequeststoApproveAsDelegated");
                                    self.requestStatusData(component, event, "RequeststoApproveAsDelegated");
                                }
								else if(component.get("v.proxyApprovedflag")===true) {
									component.set("v.index", "RequestsApprovedByProxy");
                                    self.requestStatusData(component, event, "RequestsApprovedByProxy");
								}
								else if(component.get("v.proxyRejectedflag")===true) {
									component.set("v.index", "RequestsRejectedByProxy");
                                    self.requestStatusData(component, event, "RequestsRejectedByProxy");
								}
                                else
                                {                                    
                                    component.set("v.index", APIName);
                                    self.requestStatusData(component, event, APIName);
                                   // alert('check other index>>'+component.get("v.index"));
                                }
                               //   component.set("v.index", APIName);  
                                
                                
                                count = count + 1;
                            }
                            strStatusCount.push({"developerName": APIName, "segment":  record.Label , "value": (mapObject[APIName] !== undefined)  ? (mapObject[APIName].length) : 0});
                        }
                    }
                }
                component.set("v.pieChartData", strStatusCount);
                
                component.set("v.fieldset", response.lstFields); //holds fieldsets
                var columns = [];
                var fields = component.get("v.fieldset");
                var numberOfFields = fields.length;
                for(var i=0;i<numberOfFields;i=i+1) {
                    if(fields[i].APIName === "Name") {
                        columns.push({
                            label: fields[i].Label, 
                            type: "url",
                            sortable: true,
                            fieldName: "Id",
                            typeAttributes: { label: { fieldName: "Name"},
                                             tooltip: " ",
                                             target: "_self" }
                        });
                    } else {
                        if(fields[i].Type !== "REFERENCE" && fields[i].Type !== "DATETIME"&& fields[i].Type !== "DOUBLE") {
                            if(fields[i].Label === "Full Name") {
                                columns.push({
                                    label: "Requestor",
                                    type: "url",
                                    sortable: true,
                                    fieldName: "RequestorId",
                                    typeAttributes: {label: {fieldName: "RequestorName"},
                                                     tooltip: " ",
                                                     target: "_self"}
                                });
                            } else {
                                columns.push({
                                    label: fields[i].Label,
                                    fieldName: fields[i].APIName,
                                    type: fields[i].Type,
                                    sortable: true,
                                });  
                            }
                        } else if(fields[i].Type === "REFERENCE") {
                            columns.push({
                                label: fields[i].Label, 
                                type: "url",
                                sortable: true,
                                fieldName: fields[i].APIName,
                                typeAttributes: {label: {fieldName: fields[i].APIName},
                                                 tooltip: " ",
                                                 target: "_self"}
                            });
                        } else if(fields[i].Type === "DATETIME") {
                            columns.push({
                                label: fields[i].Label,
                                sortable: true,
                                fieldName: fields[i].APIName,
                                type: "date",
                                typeAttributes: {
                                    year: "numeric",
                                    month: "2-digit",
                                    day: "2-digit",
                                    hour: "2-digit",
                                    minute: "2-digit",
                                }
                            }); 
                            /*
                            if(fields[i].APIName === "SubmittedDate")
                            {
                                columns.push({
                                label: fields[i].Label,
                                sortable: true,
                                fieldName: fields[i].APIName,
                                type: "date",
                                typeAttributes: {
                                    year: "numeric",
                                    month: "2-digit",
                                    day: "2-digit",
                                    hour: "2-digit",
                                    minute: "2-digit",
                                }
                            }); 
                                
                            } */
                        } else if(fields[i].Type === "DOUBLE") {
                            columns.push({
                                label: fields[i].Label,
                                fieldName: fields[i].APIName,
                                type: "number",
                                sortable: true,
                            }); 
                        }
                    }
                }
                component.set("v.columns", columns);
                component.set("v.columnsCopy", columns);
                var chartData = component.get("v.pieChartData");
                if(chartData.length > 0) {
                    component.set("v.displayChart", true);
                    component.set("v.noRecords", false);
                } else if(chartData.length === 0) {
                    component.set("v.displayChart", false);
                    component.set("v.noRecords", true);
                }
            });
    },
    
    /** Displays the data on datatable based on the status **/
    requestStatusData : function(component, event, label) {
      //  alert(event.getParam("status"));
        var statusVal = "";
        if(event !== undefined) {
            statusVal = event.getParam("status");
        }
        if(label !== "" && label !== null && label !== undefined) {
            statusVal = label;
        }
        if(statusVal !== "") {
            /*
          if(statusVal===$A.get("$Label.c.CLIFv20115") || statusVal===$A.get("$Label.c.CLIFv20114") || statusVal===$A.get("$Label.c.CLIFv20116") || statusVal===$A.get("$Label.c.CLIFv20117") || statusVal===$A.get("$Label.c.proxyApproved") || statusVal===$A.get("$Label.c.proxyRejected") || statusVal===$A.get("$Label.c.CLIFv20121"))
            {
                var columns=component.get("v.columnsCopy");
                let mycolumns = columns.filter(col => col.label !== 'Received Date');
                        	component.set('v.columns',mycolumns);
            }
            else
            {
				component.set('v.columns',component.get("v.columnsCopy"));                
            }
            */    
            component.set("v.requestDetails", component.get("v.mapObject")[statusVal]);

            /* sorting the data table by Name initially */
            this.sortData(component, component.get("v.sortedBy"), 
                          component.get("v.sortedDirection"));
           // alert(JSON.stringify(component.get("v.mapObject")[statusVal]))
        }
        label = "";
    },
    
    /* triggers this logic to handle sorting */
    sortData: function (component, fieldName, sortDirection) {
        var data = component.get("v.requestDetails");
        var reverse = sortDirection !== "asc";
        if(fieldName === "Id") {
            fieldName = "Name";
        }
        if(data !== undefined && data !== null) {
            data.sort(this.sortBy(fieldName, reverse))
        }
        component.set("v.requestDetails", data);
    },
    
    /* column to sort by logic (case-insensitive) */
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x.hasOwnProperty(field) ? 
                                       (typeof x[field] === 'string' ? x[field].toLowerCase() : x[field]) : 'aaa')} :
        function(x) {return x.hasOwnProperty(field) ? 
            (typeof x[field] === 'string' ? x[field].toLowerCase() : x[field]) : 'aaa'};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {            
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    }
})