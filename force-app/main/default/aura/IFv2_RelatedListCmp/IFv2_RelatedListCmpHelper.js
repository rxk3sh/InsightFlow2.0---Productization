({
    /* Generic call to server */
    callToServer: function(component, method, callback, params) {
        var action = component.get(method);
        if (params) {
            action.setParams(params);
        }
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                callback.call(this, response.getReturnValue());
            } else if(state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        /* Iteration 3 change - removed AlertApplication event Start */
                        component.set("v.alertMessage", "Error message: " + errors[0].message);
                        component.set("v.isAlert", true);
                    }
                }
            } else {
                component.set("v.alertMessage", "ERROR: Unknown Error");
                component.set("v.isAlert", true);
            }
            /* Iteration 3 change - removed AlertApplication event END */
        });
        $A.enqueueAction(action);
    },
    
    /** Gets the data on load**/    
    getRelatedListData: function(component, event, helper) {
        
        var tableActions = [{ label: "View", name: "view_details" }];
        
        var self = this;
        //var listType = component.get("v.listType");
        /* Fetch the records */
        self.callToServer(
            component,
            "c.fetchRelatedList", /* server method */
            function(response){
                var listType = component.get("v.listType");
                var wrapperList = response;
                var oldRequest = wrapperList.oldRequest;
                var displayApprovalHistory = wrapperList.displayApprovalHistory;
                if(oldRequest !== null && oldRequest !== undefined && oldRequest.length > 0 && displayApprovalHistory === true) {
                    component.set("v.noOldRequest",true);
                    
                    var columns = [];
                    var approvalSteps;
                    var records = wrapperList.records;
                    var labels = wrapperList.columnLabels.split(',');
                    var apiNames = wrapperList.apiNames.split(',');
                    var types = wrapperList.fieldType;
                    var fieldTypesList = types.substring(1, types.length).split(',');
                    var userProfile = wrapperList.userProfile;
                    
                    /* setting logged In user profile name */
                    component.set("v.userProfile", userProfile);
                    
                    if(listType === "ProcessInstance") {
                        for(var i=0;i<apiNames.length;i++) {
                            if(apiNames[i]=="Actor.Name") {
                                apiNames[i] = "ActorName";
                            } else if (apiNames[i]=="ProcessNode.Name") {
                                apiNames[i] = "ProcessNodeName";
                            } else if (apiNames[i]=="OriginalActor.Name"){
                                apiNames[i] = "OriginalActorName";
                            }  
                        }
                    } else { 
                        for(var i=0;i<apiNames.length;i++) {
                            if (apiNames[i] == "Name") {
                                fieldTypesList[i] = "url";
                            }
                        }
                    }
                    
                    var recordList = [];
                    
                    /* Total records count for displaying it above the related list table */
                    var count = 0;
                    
                    /* Pre processing for the Approval History Related List */
                    if(listType === "ProcessInstance" && records !== undefined && records !== null) {
                        for(var i=0; i<records.length;i++) {
                            var ifReassign = false;
                            approvalSteps = records[i].StepsAndWorkitems;
                            for(var j=0; j<approvalSteps.length; j++) {
                                count++;
                                if(j>0 && approvalSteps[j-1].StepStatus === "Reassigned" && approvalSteps[j].StepStatus === "Pending") {
                                    ifReassign = true;
                                }
                                /* change deafault status name from Started to Submitted */
                                if(approvalSteps[j].StepStatus === "Started" && approvalSteps[j] !== undefined && approvalSteps[j] !== null){
                                    approvalSteps[j].StepStatus = "Submitted";
                                    approvalSteps[j].ProcessNodeName = "Approval Request Submitted";
                                    approvalSteps[j].ProcessNodeId = '/lightning/r/ProcessInstanceStep/'+ approvalSteps[j].Id+'/view';
                                } if(approvalSteps[j].StepStatus === "Removed" && approvalSteps[j] !== undefined && approvalSteps[j] !== null){
                                    approvalSteps[j].StepStatus = "Recalled";
                                }
                                if (approvalSteps[j].ProcessNode && approvalSteps[j] !== undefined && approvalSteps[j] !== null) {
                                    approvalSteps[j].ProcessNodeName = approvalSteps[j].ProcessNode.Name;
                                    approvalSteps[j].ProcessNodeId = '/lightning/r/ProcessInstanceStep/'+ approvalSteps[j].Id+'/view';
                                } if (approvalSteps[j].OriginalActor && approvalSteps[j] !== undefined && approvalSteps[j] !== null) {
                                    approvalSteps[j].OriginalActorName = approvalSteps[j].OriginalActor.Name;
                                    approvalSteps[j].OriginalActorId = '/'+ approvalSteps[j].OriginalActor.Id;
                                } if(approvalSteps[j].Actor && approvalSteps[j] !== undefined && approvalSteps[j] !== null) {
                                    approvalSteps[j].ActorName = approvalSteps[j].Actor.Name; 
                                    approvalSteps[j].ActorId = '/'+ approvalSteps[j].Actor.Id;
                                } if(approvalSteps[j].StepStatus === "NoResponse" && approvalSteps[j] !== undefined && approvalSteps[j] !== null && approvalSteps[j] !== ''){
                                    approvalSteps[j].ActorName = null; 
                                    approvalSteps[j].ActorId = null;
                                } if( ifReassign === true &&  approvalSteps[j].StepStatus === "Pending" && approvalSteps[j-1].StepStatus === "Reassigned") {
                                    var tempStepStatus = approvalSteps[j-1];
                                    approvalSteps[j-1] = approvalSteps[j];
                                    approvalSteps[j] = tempStepStatus;
                                    ifReassign = false;
                                    recordList.splice(j-1,1,approvalSteps[j-1]);
                                } 
                                recordList.push(approvalSteps[j]);
                            } 
                        } 
                    } else {
                        for(var i=0; i<records.length; i++) {
                            count++;
                            records[i].Id = '/'+records[i].Id;
                        }
                        recordList = records;
                    }
                    
                    /* set value for the count attribute */
                    if(approvalSteps !== undefined) {
                        component.set("v.relatedListCount",count); 
                    } 
                    
                    /* for approval history lists */
                    if(listType === "ProcessInstance") {
                        for(var i=0; i<labels.length; i++) {
                            if(labels[i] !== "Step Name" && labels[i] !== "Actual Approver" 
                               && labels[i] !=="Assigned To") {
                                columns.push({
                                    label: labels[i],
                                    fieldName: apiNames[i]
                                });  
                            } else if(labels[i] === "Step Name") {
                                columns.push({
                                    label: labels[i], type: "url", fieldName: "ProcessNodeId",
                                    typeAttributes: { label: { fieldName: apiNames[i]},
                                                     tooltip: " "}
                                });
                            } else if(labels[i] === "Actual Approver") {
                                columns.push({
                                    label: labels[i], type: "url", fieldName: "ActorId",
                                    typeAttributes: { label: { fieldName: apiNames[i]},
                                                     tooltip: " "}
                                });
                            } else if(labels[i] === "Assigned To") {
                                columns.push({
                                    label: labels[i], type: "url", fieldName: "OriginalActorId",
                                    typeAttributes: { label: { fieldName: apiNames[i]},
                                                     tooltip: " "}
                                });
                            } else if(labels[i] === "Date") {
                                columns.push({
                                    label: labels[i],
                                    fieldName: apiNames[i],
                                    type: date
                                });
                            }
                        }
                        
                        columns.push({
                            type: "action", typeAttributes: { rowActions: tableActions }
                        }) 
                    } 
                    
                    /* all other related lists */
                    else {
                        for(var i=0; i<labels.length; i++) {
                            if(apiNames[i] !== "Name") {
                                columns.push({
                                    label: labels[i],
                                    fieldName: apiNames[i],
                                    type: fieldTypesList[i]
                                });
                            } if(apiNames[i] === "Name") {
                                columns.push({
                                    label: labels[i],
                                    fieldName: "Id",
                                    type: fieldTypesList[i],
                                    typeAttributes: { label: { fieldName: apiNames[i]},
                                                     tooltip: " ", target: "_self"}
                                });
                            } 
                        }
                    } 
                    component.set("v.columnLabels", columns);
                    var accountList = [];
                    var accountmap = component.get("v.AllRecordList");
                    for ( var key in accountmap ) {
                        accountList.push({accountdate:key, value:accountmap[key]});
                    }
                    if(records.length > 0 && records !== undefined){
                        component.set("v.AllRecordList", recordList);
                        component.set("v.isEmpty", false);
                        this.sortData(component, component.get("v.sortedBy"), 
                                      component.get("v.sortedDirection"));
                        
                    } else if(records.length === 0 || records === undefined) {
                        component.set("v.alertMessage", "No Records to display");
                        component.set("v.isEmpty", true);
                    } 
                } else if(oldRequest !== null && oldRequest !== undefined && oldRequest.length > 0) {
                    component.set("v.noOldRequest",false);
                } else {
                    var columns = [];
                    var approvalSteps;
                    var records = wrapperList.records;
                    var labels = wrapperList.columnLabels.split(',');
                    var apiNames = wrapperList.apiNames.split(',');
                    var types = wrapperList.fieldType;
                    var fieldTypesList = types.substring(1, types.length).split(',');
                    var userProfile = wrapperList.userProfile;
                    
                    /* setting logged In user profile name */
                    component.set("v.userProfile", userProfile);
                    
                    if(listType === "ProcessInstance") {
                        for(var i=0;i<apiNames.length;i++) {
                            if(apiNames[i]=="Actor.Name") {
                                apiNames[i] = "ActorName";
                            } else if (apiNames[i]=="ProcessNode.Name") {
                                apiNames[i] = "ProcessNodeName";
                            } else if (apiNames[i]=="OriginalActor.Name"){
                                apiNames[i] = "OriginalActorName";
                            }  
                        }
                    } else { 
                        for(var i=0;i<apiNames.length;i++) {
                            if (apiNames[i] == "Name") {
                                fieldTypesList[i] = "url";
                            }
                        }
                    }
                    
                    var recordList = [];
                    
                    /* Total records count for displaying it above the related list table */
                    var count = 0;
                    
                    /* Pre processing for the Approval History Related List */
                    if(listType === "ProcessInstance" && records !== undefined && records !== null) {
                        for(var i=0; i<records.length;i++) {
                            var ifReassign = false;
                            approvalSteps = records[i].StepsAndWorkitems;
                            for(var j=0; j<approvalSteps.length; j++) {
                                count++;
                                if(j>0 && approvalSteps[j-1].StepStatus === "Reassigned" && approvalSteps[j].StepStatus === "Pending") {
                                    ifReassign = true;
                                }
                                /* change deafault status name from Started to Submitted */
                                if(approvalSteps[j].StepStatus === "Started" && approvalSteps[j] !== undefined && approvalSteps[j] !== null){
                                    approvalSteps[j].StepStatus = "Submitted";
                                    approvalSteps[j].ProcessNodeName = "Approval Request Submitted";
                                    approvalSteps[j].ProcessNodeId = '/lightning/r/ProcessInstanceStep/'+ approvalSteps[j].Id+'/view';
                                } if(approvalSteps[j].StepStatus === "Removed" && approvalSteps[j] !== undefined && approvalSteps[j] !== null){
                                    approvalSteps[j].StepStatus = "Recalled";
                                }
                                if (approvalSteps[j].ProcessNode && approvalSteps[j] !== undefined && approvalSteps[j] !== null) {
                                    approvalSteps[j].ProcessNodeName = approvalSteps[j].ProcessNode.Name;
                                    approvalSteps[j].ProcessNodeId = '/lightning/r/ProcessInstanceStep/'+ approvalSteps[j].Id+'/view';
                                } if (approvalSteps[j].OriginalActor && approvalSteps[j] !== undefined && approvalSteps[j] !== null) {
                                    approvalSteps[j].OriginalActorName = approvalSteps[j].OriginalActor.Name;
                                    approvalSteps[j].OriginalActorId = '/'+ approvalSteps[j].OriginalActor.Id;
                                } if(approvalSteps[j].Actor && approvalSteps[j] !== undefined && approvalSteps[j] !== null) {
                                    approvalSteps[j].ActorName = approvalSteps[j].Actor.Name; 
                                    approvalSteps[j].ActorId = '/'+ approvalSteps[j].Actor.Id;
                                } if(approvalSteps[j].StepStatus === "NoResponse" && approvalSteps[j] !== undefined && approvalSteps[j] !== null && approvalSteps[j] !== ''){
                                    approvalSteps[j].ActorName = null; 
                                    approvalSteps[j].ActorId = null;
                                } if( ifReassign === true &&  approvalSteps[j].StepStatus === "Pending" && approvalSteps[j-1].StepStatus === "Reassigned") {
                                    var tempStepStatus = approvalSteps[j-1];
                                    approvalSteps[j-1] = approvalSteps[j];
                                    approvalSteps[j] = tempStepStatus;
                                    ifReassign = false;
                                    recordList.splice(j-1,1,approvalSteps[j-1]);
                                } 
                                recordList.push(approvalSteps[j]);
                            } 
                        } 
                    } else {
                        for(var i=0; i<records.length; i++) {
                            count++;
                            records[i].Id = '/'+records[i].Id;
                        }
                        recordList = records;
                    }
                    
                    /* set value for the count attribute */
                    if(approvalSteps !== undefined) {
                        component.set("v.relatedListCount",count); 
                    } 
                    
                    /* for approval history lists */
                    if(listType === "ProcessInstance") {
                        for(var i=0; i<labels.length; i++) {
                            if(labels[i] !== "Step Name" && labels[i] !== "Actual Approver" 
                               && labels[i] !=="Assigned To") {
                                columns.push({
                                    label: labels[i],
                                    fieldName: apiNames[i]
                                });  
                            } else if(labels[i] === "Step Name") {
                                columns.push({
                                    label: labels[i], type: "url", fieldName: "ProcessNodeId",
                                    typeAttributes: { label: { fieldName: apiNames[i]},
                                                     tooltip: " "}
                                });
                            } else if(labels[i] === "Actual Approver") {
                                columns.push({
                                    label: labels[i], type: "url", fieldName: "ActorId",
                                    typeAttributes: { label: { fieldName: apiNames[i]},
                                                     tooltip: " "}
                                });
                            } else if(labels[i] === "Assigned To") {
                                columns.push({
                                    label: labels[i], type: "url", fieldName: "OriginalActorId",
                                    typeAttributes: { label: { fieldName: apiNames[i]},
                                                     tooltip: " "}
                                });
                            } else if(labels[i] === "Date") {
                                columns.push({
                                    label: labels[i],
                                    fieldName: apiNames[i],
                                    type: date
                                });
                            }
                        }
                        
                        columns.push({
                            type: "action", typeAttributes: { rowActions: tableActions }
                        }) 
                    } 
                    
                    /* all other related lists */
                    else {
                        for(var i=0; i<labels.length; i++) {
                            if(apiNames[i] !== "Name") {
                                columns.push({
                                    label: labels[i],
                                    fieldName: apiNames[i],
                                    type: fieldTypesList[i]
                                });
                            } if(apiNames[i] === "Name") {
                                columns.push({
                                    label: labels[i],
                                    fieldName: "Id",
                                    type: fieldTypesList[i],
                                    typeAttributes: { label: { fieldName: apiNames[i]},
                                                     tooltip: " ", target: "_self"}
                                });
                            } 
                        }
                    } 
                    component.set("v.columnLabels", columns);
                    var accountList = [];
                    var accountmap = component.get("v.AllRecordList");
                    for ( var key in accountmap ) {
                        accountList.push({accountdate:key, value:accountmap[key]});
                    }
                    if(records.length > 0 && records !== undefined){
                        component.set("v.AllRecordList", recordList);
                        component.set("v.isEmpty", false);
                        this.sortData(component, component.get("v.sortedBy"), 
                                      component.get("v.sortedDirection"));
                        
                    } else if(records.length === 0 || records === undefined) {
                        component.set("v.alertMessage", "No Records to display");
                        component.set("v.isEmpty", true);
                    } 
                }
                
            },
            {
                /* params */
                "objectId" :  component.get("v.recordId"),
                "listType" :  component.get("v.listType")
            },
            true
        );
    },
    
    /* triggers this logic to handle sorting */
    sortData: function (component, fieldName, sortDirection) {
        var data = component.get("v.modalRecordList");
        var reverse = sortDirection !== "asc";
        if(data !== undefined && data !== null) {
            data.sort(this.sortBy(fieldName, reverse))
        }
        component.set("v.modalRecordList", data);
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
    },
    
    /* onclick handler for View Action */
    navigateToRelatedRecord : function(component,event,helper,row){
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": row.Id,
            "slideDevName": "related"
        });
        navEvt.fire();
    },
    
    /* display modal for complete approval history list */
    displayModal : function(component,event,helper){
        
        // for Display Model,set the "isOpen" attribute to "true"
        component.set("v.isOpen", true);
        
        var self = this;
        
        self.callToServer(
            component,
            "c.completeRelatedList", /* server method */
            function(response){
                var listType = component.get("v.listType");
                var wrapperList = response;
                var columns = [];
                var approvalSteps;
                var records = wrapperList.records;
                var labels = wrapperList.columnLabels.split(',');
                var apiNames = wrapperList.apiNames.split(',');
                /* var types = wrapperList.fieldType;
                var fieldTypesList = types.substring(1, types.length).split(','); */
                if(listType === "ProcessInstance") {
                    for(var i=0; i<apiNames.length; i++) {
                        if(apiNames[i] === "Actor.Name") {
                            apiNames[i] = "ActorName";
                        }  if (apiNames[i] === "ProcessNode.Name") {
                            apiNames[i] = "ProcessNodeName";
                        }  if (apiNames[i] === "OriginalActor.Name"){
                            apiNames[i] = "OriginalActorName";
                        }  
                    }
                } else { 
                    for(var i=0;i<apiNames.length;i++) {
                        if (apiNames[i] === "Name") {
                            fieldTypesList[i] = "url";
                        }
                    }
                }
                
                var recordList = [];
                
                /* Total records count for displaying it above the related list table */
                var count=0;
                
                /* Pre processing for the Approval History Related List */
                if(listType === "ProcessInstance" && records !== undefined && records !== null) {
                    for(var i=0; i<records.length;i++) {
                        approvalSteps = records[i].StepsAndWorkitems;
                        var ifReassign = false;
                        for(var j=0; j<approvalSteps.length; j++) {
                            count++;
                            if(j>0 && approvalSteps[j-1].StepStatus === "Reassigned" && approvalSteps[j].StepStatus === "Pending") {
                                ifReassign = true;
                            }
                            /* change deafault status name from Started to Submitted */
                            if(approvalSteps[j].StepStatus === "Started" && approvalSteps[j] !== undefined && approvalSteps[j] !== null && approvalSteps[j] !== ''){
                                approvalSteps[j].StepStatus = "Submitted";
                                approvalSteps[j].ProcessNodeName = "Approval Request Submitted";
                                approvalSteps[j].ProcessNodeId = '/lightning/r/ProcessInstanceStep/'+ approvalSteps[j].Id+'/view';
                            } if(approvalSteps[j].StepStatus === "Removed" && approvalSteps[j] !== undefined && approvalSteps[j] !== null && approvalSteps[j] !== ''){
                                approvalSteps[j].StepStatus = "Recalled";
                            } if(approvalSteps[j].ProcessNode && approvalSteps[j] !== undefined && approvalSteps[j] !== null && approvalSteps[j] !== '') {
                                approvalSteps[j].ProcessNodeName = approvalSteps[j].ProcessNode.Name;
                                approvalSteps[j].ProcessNodeId = '/lightning/r/ProcessInstanceStep/'+ approvalSteps[j].Id+'/view';
                            } if(approvalSteps[j].OriginalActor && approvalSteps[j] !== undefined && approvalSteps[j] !== null && approvalSteps[j] !== '') {
                                approvalSteps[j].OriginalActorName = approvalSteps[j].OriginalActor.Name;
                                approvalSteps[j].OriginalActorId = '/'+ approvalSteps[j].OriginalActor.Id;
                            } if(approvalSteps[j].Actor && approvalSteps[j] !== undefined && approvalSteps[j] !== null && approvalSteps[j] !== '') {
                                approvalSteps[j].ActorName = approvalSteps[j].Actor.Name; 
                                approvalSteps[j].ActorId = '/'+ approvalSteps[j].Actor.Id;
                            } if(approvalSteps[j].StepStatus === "NoResponse" && approvalSteps[j] !== undefined && approvalSteps[j] !== null && approvalSteps[j] !== ''){
                                approvalSteps[j].ActorName = null; 
                                approvalSteps[j].ActorId = null;
                            } if( ifReassign === true &&  approvalSteps[j].StepStatus === "Pending" && approvalSteps[j-1].StepStatus === "Reassigned") {
                                var tempStepStatus = approvalSteps[j-1];
                                approvalSteps[j-1] = approvalSteps[j];
                                approvalSteps[j] = tempStepStatus;
                                ifReassign = false;
                                recordList.splice(j-1,1,approvalSteps[j-1]);
                            }
                            recordList.push(approvalSteps[j]);
                        } 
                    } 
                } else if(records !== undefined && records !== null) {
                    for(var i=0; i<records.length; i++) {
                        count++;
                        records[i].Id = '/'+records[i].Id;
                    }
                    recordList = records;
                }
                
                /* set value for the count attribute */
                if(approvalSteps !== undefined) {
                    component.set("v.relatedListCount",count); 
                } 
                
                /* for approval history lists */
                if(listType === "ProcessInstance") {
                    for(var i=0; i<labels.length; i++) {
                        if(labels[i] !== "Step Name" && labels[i] !== "Actual Approver" 
                           && labels[i] !== "Assigned To" && labels[i] !== "Date") {
                            columns.push({
                                label: labels[i],
                                fieldName: apiNames[i],
                                sortable: true
                            });  
                        } else if(labels[i] === "Step Name") {
                            columns.push({
                                label: labels[i], type: "url", fieldName: "ProcessNodeId",
                                typeAttributes: { label: { fieldName: apiNames[i]},
                                                 tooltip: " "},
                                sortable: true
                            });
                        } else if(labels[i] === "Actual Approver") {
                            columns.push({
                                label: labels[i], type: "url", fieldName: "ActorId",
                                typeAttributes: { label: { fieldName: apiNames[i]},
                                                 tooltip: " "},
                                sortable: true
                            });
                        } else if(labels[i] === "Assigned To") {
                            columns.push({
                                label: labels[i], type: "url", fieldName: "OriginalActorId",
                                typeAttributes: { label: { fieldName: apiNames[i]},
                                                 tooltip: " "},
                                sortable: true
                            });
                        } else if(labels[i] === "Date") {
                            columns.push({
                                label: labels[i],
                                fieldName: apiNames[i],
                                type: "date",
                                typeAttributes: {
                                    year: 'numeric',
                                    month: '2-digit',
                                    day: '2-digit',
                                    hour: '2-digit',
                                    minute: '2-digit'
                                },
                                sortable: true
                            });
                        }
                    }
                } 
                
                /* all other related lists */
                else {
                    for(var i=0; i<labels.length; i++) {
                        if(apiNames[i] !== "Name") {
                            columns.push({
                                label: labels[i],
                                fieldName: apiNames[i],
                                type: fieldTypesList[i],
                                sortable: true
                            });
                        } if(apiNames[i] === "Name") { //changing field type of Name to url
                            columns.push({
                                label: labels[i],
                                fieldName: "Id",
                                type: fieldTypesList[i],
                                typeAttributes: { label: { fieldName: apiNames[i]},
                                                 tooltip: " ", target: "_self"},
                                sortable: true
                            });
                        } 
                    }
                }
                component.set("v.modalColumnLabels", columns);
                
                if(records.length > 0 && records !== undefined){
                    component.set("v.modalRecordList", recordList);
                    component.set("v.isEmpty", false);
                    
                } else if(records.length == 0 || records == undefined) {
                    component.set("v.alertMessage", "No Records to display");
                    component.set("v.isEmpty", true);
                }
            },
            {
                //params
                "objectId" :  component.get("v.recordId"),
                "listType" :  component.get("v.listType")
            },
            true
        );
    }
})