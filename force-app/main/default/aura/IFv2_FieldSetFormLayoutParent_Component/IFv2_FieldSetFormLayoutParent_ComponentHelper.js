({
    /* Call to server */
    callToServer: function(component, method, callback, params, storable) {
        component.set("v.showSpinner", true);
        component.set("v.isAlert", false);
        component.set("v.alertMessage", []);
        var action = component.get(method);
        action.setBackground(true);
        if (storable) {
            action.setStorable();
        }
        if (params) {
            action.setParams(params);
        }
        action.setCallback(this, function(response) {
            component.set("v.showSpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.isAlert", false);
                component.set("v.alertMessage", []);
                callback.call(this, response.getReturnValue());
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors && errors[0]) {
                    if(errors[0].message) {
                        var messages = component.get("v.alertMessage");
                        if(messages === undefined){
                            messages=[];
                        }
                        messages.push($A.get("$Label.c.CLIFv20032") + " " + errors[0].message);
                        component.set("v.alertMessage", messages);
                        component.set("v.isAlert", true);
                    }
                    var pageError = errors[0].pageErrors;
                    
                    if (pageError && pageError[0] && pageError[0].message) {
                        var messages = component.get("v.alertMessage");
                        messages.push("Error message: " + pageError[0].message);
                        component.set("v.alertMessage", messages);
                        component.set("v.isAlert", true);
                    }
                    var fieldError = errors[0].fieldErrors;
                    if (fieldError && fieldError.Name && fieldError.Name[0] &&  fieldError.Name[0].message) {
                        var messages = component.get("v.alertMessage");
                        messages.push("Error message: " + fieldError.Name[0].message);
                        component.set("v.alertMessage", messages);
                        component.set("v.isAlert", true);
                    }
                }
            } else {
                var messages = component.get("v.alertMessage");
                messages.push($A.get("$Label.c.CLIFv20057"));
                component.set("v.alertMessage", messages);
                component.set("v.isAlert", true);
            }
        });
        $A.enqueueAction(action);
    },
    
    purchaseAssignments: function(component,saveCall) {
        var request = component.get("v.record");
        var metadata = component.get("v.purchaseMetadata");
        
        if(metadata.length > 0) {
            for(var i=0;i<metadata.length;i=i+1) {
                var detail = metadata[i];
                if(detail.Group__c !== "Rest") {
                    if(detail.ApproverApiName__c !== undefined && detail.User__c !== undefined) {
                        component.set("v.record." + detail.ApproverApiName__c, "");
                    }
                    if(detail.RoleApiName__c !== undefined && detail.ApproverRole__c !== undefined) {
                        component.set("v.record." + detail.RoleApiName__c, "");
                    }
                } else if(detail.Group__c === "Rest") {
                    if(detail.Region__c === "Rest" || detail.Region__c === request.Region__c) {
                        if(detail.ApproverApiName__c !== undefined && (detail.User__c !== undefined || detail.Limit__c > request.EstimatedValueWithoutTaxes__c)) {
                            //if(request.Workflow__c == 'Indirect Purchasing Approval')
                            //{
                               // component.set("v.record." + detail.ApproverApiName__c, "");
                           // }
                            
                        }
                        if(detail.RoleApiName__c !== undefined && detail.ApproverRole__c !== undefined) {
                            component.set("v.record." + detail.RoleApiName__c, "");
                        }
                    }
                }
            }
        }
        
        if(request.Region__c !== undefined && request.SubjectType__c !== undefined && request.Workflow__c !== undefined) {
            var self = this;
            self.callToServer(
                component,
                "c.getPurchasingApproval",
                function(response) {
                    if(response.length > 0) {
                        component.set("v.purchaseMetadata", response);
                        var requiredApiNames = []; /* List to collect all required api names*/
                        
                        for(var i=0; i<response.length; i=i+1) {
                            var data = response[i];
                            
                            if(request.EstimatedValueWithoutTaxes__c > data.Limit__c || data.Limit__c === 0) {
                                if(data.Group__c === "Not-Rest") {
                                    if(data.ApproverApiName__c !== undefined) {
                                        requiredApiNames.push(data.ApproverApiName__c);
                                        if(data.User__c !== undefined) {
                                            component.set("v.record."+data.ApproverApiName__c, data.User__c);
                                        }
                                    }
                                    if(data.RoleApiName__c !== undefined && data.ApproverRole__c !== undefined) {
                                        component.set("v.record."+data.RoleApiName__c, data.ApproverRole__c);
                                    }
                                } else if(data.Group__c === "Rest") {
                                    if(data.Region__c === "Rest" || data.Region__c === request.Region__c) {
                                        if(data.ApproverApiName__c !== undefined) {
                                            requiredApiNames.push(data.ApproverApiName__c);
                                            if(data.User__c !== undefined) {
                                                component.set("v.record."+data.ApproverApiName__c, data.User__c);
                                            }
                                        }
                                        if(data.RoleApiName__c !== undefined && data.ApproverRole__c !== undefined) {
                                            component.set("v.record."+data.RoleApiName__c, data.ApproverRole__c);
                                        }
                                    }
                                }
                            }
                        }
                        
                        if(requiredApiNames.length > 0) {
                            component.set("v.requiredFieldsList", requiredApiNames);
                        }
                    }
                    if(saveCall){
                        this.saveRecord(component);
                    }
                },
                {
                    "Region": request.Region__c,
                    "SubjectType": request.SubjectType__c,
                    "workflow": request.Workflow__c
                },
                true);
        }
    },
    
    saveRecord : function(component) {
        var record = component.get("v.record");
        var fieldList = component.get("v.fieldNames");
        if(record["ResponsibleBuyerIdenticalwRequester__c"] !== undefined) {
            if(record["ResponsibleBuyerIdenticalwRequester__c"] && record["Workflow__c"] === $A.get("$Label.c.CLIFv20005")) {
                record["Buyer__c"] = record["CreatedById"];
            }
        }
        component.set("v.record", record);
        
        var recList = [];
        var saveRec = {};
        var initRec = component.get("v.initRecord");
        var prevRec = {};
        var self = this;
        saveRec["attributes"] = {"type":component.get("v.sObjectName")};
        
        /* Handle Fields on related objects*/
        for (var key in record) {
            if (key.includes("__r")) {
                var temp = {};
                temp.key = key.replace("__r", "__c");
                if(record[key] !== null && record[key] !== undefined && record[key] !== "") {
                    temp.value = record[key];
                } else {
                    temp.value = null;
                }
                //    temp.value = record[key];
                recList.push(temp);
            } else {
                if(record[key] !== null && record[key] !== undefined && record[key] !== "") {
                    saveRec[key] = record[key];
                } else {
                    saveRec[key] = null;
                }
            }
        }
        //saveRec["sobjectType"] = component.get("v.sObjectName");
        //   saveRec["Id"] = component.get("v.recordId");
        
        for (var key in initRec) {
            if(initRec[key] !== null && initRec[key] !== undefined && initRec[key] !== "") {
                prevRec[key] = initRec[key];
            } else {
                prevRec[key] = null;
            }
        }
        
        if(saveRec !== undefined) {
            /*Call server method to save*/
            self.callToServer(
                component,
                "c.saveRecords",
                function(response) {
                    
                    component.set("v.newButton", false);
                    var returnRec = response;
                    
                    /*for populating newly mapped fields from backend on the page*/
                    for(var key in returnRec) {
                        if(fieldList.indexOf(key) > 0) {
                            if(key !== "CreatedBy") {
                                if(returnRec[key] !== undefined && returnRec[key] !== null) {
                                    record[key] = returnRec[key];
                                } else {
                                    record[key] = "";
                                }
                            }
                        }
                    }
                    
                    /*for clearing values on page when they're cleared in backend*/
                    for(var key in saveRec) {
                        if(fieldList.indexOf(key) > 0) {
                            if(key !== "CreatedBy") {
                                if(returnRec[key] !== undefined && returnRec[key] !== null) {
                                    record[key] = returnRec[key];
                                } else {
                                    record[key] = "";
                                }
                            }
                        }
                    }
                    component.set("v.record", record);
                    component.set("v.initRecord", (component.get("v.record")));
                    
                    var toast = $A.get("e.force:showToast");
                    toast.setParams({
                        "title": "Success!",
                        "type": "success",
                        "message": $A.get("$Label.c.CLIFv20184")
                    });
                    toast.fire();
                    if(component.find("forceRecord") !== undefined) {
                        component.find("forceRecord").reloadRecord(true);
                    }
                    component.set("v.isEditMode", false);
                    
                    var editEvent = $A.get("e.c:IFv2_EditButtonHandleEvent");
                    editEvent.setParams({
                        "isEdit":false
                    });
                    editEvent.fire();
                }, 
                {
                    "recordStr": JSON.stringify(saveRec),
                    "relRecMap": JSON.stringify(recList),
                    "objectName": component.get("v.sObjectName"),
                    "buttonType": component.get("v.newButton"),
                    "recordType": component.get("v.recordType"),
                    "previousRecord": JSON.stringify(prevRec)
                },
                false
            );
        }
    },
    
    refreshRecord : function(component,isRelatedList) {
        var self = this;
        self.callToServer(
            component,
            "c.refreshRecord",
            function(response){
                if(response !== undefined && response !== null) {
                    component.set("v.record", response);
                    component.set("v.initRecord", JSON.parse(JSON.stringify(component.get("v.record"))));
                    component.set("v.recordLoad", true);
                    
                    /* purchasing approval condition */
                    var workFlows = $A.get("$Label.c.CLIFv20054");
                    var workFlowList = workFlows.split(",");
                    var currentWorkFlowName = component.get("v.record.Workflow__c");
                    
                    if (workFlowList.indexOf(currentWorkFlowName) > -1) {
                        component.set("v.purchaseWorkflow", true);
                    }
                }
            },
            {
                "recordId":component.get("v.recordId"),
                "fieldNames":component.get("v.fieldNames"),
                "objectName":component.get("v.sObjectName"),
                "isRelatedList" : isRelatedList
            }
        );
    },
    
    passMetadataToHeader : function(component) {
        var metadata = component.get("v.metadata");
        var approverSectionMetadata = [];
        if(metadata !== undefined) {
            for(var i=0;i<metadata.length;i++) {
                if(metadata[i].section.isApproverSection__c) {
                    var approverSections = {};
                    approverSections.section = metadata[i].section;
                    approverSections.fields = metadata[i].fields;
                    approverSectionMetadata.push(approverSections);
                }
            }
            if(approverSectionMetadata !== undefined) {
                var approverSectionEvent = $A.get("e.c:IFv2_ApproverSectionMetadataEvent");
                approverSectionEvent.setParams({
                    "approverSectionMetadata" : approverSectionMetadata
                });
                approverSectionEvent.fire();
            } 
        }
    }
})