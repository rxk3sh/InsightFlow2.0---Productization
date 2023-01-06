({
    /* Generic call to server */
    callToServer: function(component, method, callback, params) {
        var action = component.get(method);
        if (params) {
            action.setParams(params);
        }
        /* To display toast message on click of check now */
        if(method  === 'c.getMartialFromDetail' || method  === 'c.updateConcessionConcessionRecord') {
            var checkNowAppEvent = $A.get("e.c:IFv2_ShowSpinner");
            checkNowAppEvent.setParams({
                "showSpinner" : true,
            });
            checkNowAppEvent.fire();
        }
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            /* To stop spinner after we get response from server */
            if(method  === 'c.getMartialFromDetail' || method  === 'c.updateConcessionConcessionRecord') {
                var checkNowAppEvent = $A.get("e.c:IFv2_ShowSpinner");
                checkNowAppEvent.setParams({
                    "showSpinner" : false,
                });
                checkNowAppEvent.fire();
            }
            
            if (state === "SUCCESS") {
                callback.call(this, response.getReturnValue());
            } else if(state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        var compEvent = component.getEvent("alertEvent");
                        compEvent.setParams({
                            "alertMessage" : $A.get("$Label.c.CLIFv20032") + " " + errors[0].message,
                            "isError" : true
                        });
                        compEvent.fire();
                    }
                }
            } else {
                var compEvent = component.getEvent("alertEvent");
                compEvent.setParams({
                    "alertMessage" : $A.get("$Label.c.CLIFv20057"),
                    "isError" : true
                });
                compEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },
    
    /* Method to get the current follow status of a record */
    getFollowStatus: function(component) {
        var self = this;
        self.callToServer(
            component,
            "c.getFollowedRecord",
            function(response) {
                component.set("v.isFollowed", response);
            }, 
            {
                "reqId": component.get("v.recordId")
            });
    },
    
    /* Method to handle edit button action */
    editAction: function(component, event) {
        var isPrivilegedApprover = false;
        if(component.get("v.approverRoleName") !== null && component.get("v.approverRoleName") !== undefined && component.get("v.approverRoleName") !== ''){
            isPrivilegedApprover = true;
        }
        var appEvent = $A.get("e.c:IFv2_EditEvent");
        appEvent.setParams({
            "isPrivilegedApprover" : isPrivilegedApprover,
            "approverRole" : component.get("v.approverRoleName")
        });
        appEvent.fire();
    },
    
    /* Method to handle Approve button*/
    approveAction: function(component) {
        component.set("v.showModal", true);
        var compEvents = component.getEvent("componentEventFired");        
        compEvents.setParams({ 
            "isModalPopup" : component.get("v.showModal"),
            "recordId" : component.get("v.recordId"),
            "buttonLabel" : component.get("v.button.Label__c")
        });
        compEvents.fire();
    },
    
    /* Start of iteration 3 changes */
    /* Method to handle Check Now button*/
    checkNowAction: function(component) {
        var self = this;
        var errormessages = [];
        var material = {};
        self.callToServer(
            component,
            "c.getMartialFromDetail",
            function(response) {
                material = response;
                var temporaryplantValue;
                if( material.Account__r.IFv2_Plant__c !== undefined &&  material.Account__r.IFv2_Plant__c !=='') {
                    temporaryplantValue = material.Account__r.IFv2_Plant__c.substring(0,4); 
                }
                
                if((material.MaterialNo__c !== undefined && material.MaterialNo__c !=='' 
                    && material.SAPInstance__c !==undefined && material.SAPInstance__c !== '' 
                    && material.Full8Dreportnecessary__c !== undefined && material.Full8Dreportnecessary__c !== '' 
                    && material.Account__r.IFv2_Escalatetomanagementlevel__c !== undefined 
                    && material.Account__r.IFv2_Escalatetomanagementlevel__c !== '') 
                   && (material.SAPInstance__c === 'PSI' || (material.SAPInstance__c === 'PSG' && material.Language__c !== '' && material.Language__c !== undefined))) {
                    self.callToServer(
                        component,
                        "c.updateConcessionConcessionRecord",
                        function(calloutResponse) {
                            var jssonString = JSON.parse(calloutResponse);
                            if (jssonString.userMessage.length > 1) {
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    "mode" : "dismissible",
                                    "title" : "Error!",
                                    "type" : "error",
                                    "message" : jssonString.userMessage  
                                });
                                toastEvent.fire();
                            } else {
                                /* To update material description field */
                                var refreshConcessionEvent = $A.get("e.c:IFv2_UpdateConcessionRecord");
                                refreshConcessionEvent.setParams({
                                    "materialdescription" : jssonString.requestRecord.MaterialDescription__c,
                                    "checkboxValue" : jssonString.requestRecord.AreAllMaterialsValidated__c,
                                    "plantvalue" : jssonString.accountRecord.IFv2_Concession_Plant_Name__c,
                                    "supplierName" : jssonString.accountRecord.IFv2_ConcessionSupplierName__c,
                                    "custometText": jssonString.accountRecord.IFv2_ConcessionCustomerText__c
                                });
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    "title"		: "Success",
                                    "type"		: "success",
                                    "message" 	: $A.get("$Label.c.CLIFv20172")   
                                });
                                toastEvent.fire();
                                refreshConcessionEvent.fire();
                                $A.get("e.force:refreshView").fire();
                            }
                        },
                        {
                            idForOneMaterial : component.get("v.recordId"),
                            materialNo      : material.MaterialNo__c,
                            customerNo      : material.Account__r.IFv2_CustomerNo__c, 
                            supplierNo      : material.Account__r.IFv2_SupplierNo__c,
                            plant           : temporaryplantValue,
                            revisionLevel   : material.Account__r.IFv2_RevisionLevel__c,
                            language        : material.Language__c
                        },
                        false
                    );
                } else {
                    
                    if(material.SAPInstance__c === undefined || material.SAPInstance__c === '') {
                        errormessages.push("Error message: " + $A.get("$Label.c.CLIFv20133"));
                    }
                    if(material.SAPInstance__c === 'PSG' && (material.Language__c === '' || material.Language__c === undefined)) {
                        errormessages.push("Error message: " + $A.get("$Label.c.CLIFv20137"));
                    }
                    if(material.MaterialNo__c === undefined || material.MaterialNo__c === '') {
                        errormessages.push( "Error message: " + $A.get("$Label.c.CLIFv20132"));
                    }
                    if(material.Account__r.IFv2_Escalatetomanagementlevel__c === undefined || material.Account__r.IFv2_Escalatetomanagementlevel__c === '' ) {
                        errormessages.push("Error message: " + $A.get("$Label.c.CLIFv20135"));
                    }
                    if(material.Full8Dreportnecessary__c === undefined || material.Full8Dreportnecessary__c === '' ) {
                        errormessages.push("Error message: " + $A.get("$Label.c.CLIFv20134"));
                    } 
                    
                    var checkNowAppEvent = $A.get("e.c:IFv2_ValidationCheck_EVENT");
                    checkNowAppEvent.setParams({
                        "CheckNow" : true,
                        "ErrorMessage" : errormessages
                        
                    });
                    checkNowAppEvent.fire();
                }
            },
            {
                "requestId":component.get("v.recordId")
            });
    },
    
    /* End of Iteration 3 changes */
    /* Method used to Clone a request record */
    cloneAction: function(component) {
        var self = this;
        self.callToServer(
            component,
            "c.cloneRecord",
            function(response) {
                if(response.Id !== undefined) {
                    var recordId = response.Id;
                    var recordName = response.Name;
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "message" : "Request \""+recordName+"\" was created",
                        "title" : "Success!",
                        "type" : "success"
                    });
                    toastEvent.fire();
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": recordId,
                        "slideDevName": "details"
                    });
                    navEvt.fire();
                }
            }, 
            {
                "requestId": component.get("v.recordId")
            });
    },
    
    /** Popup to confirm when delete record is clicked**/
    deletePopUpAction: function(component) {
        var compEvents = component.getEvent("deleteEvent");        
        compEvents.fire();
    },
    
    /* Method used to Follow/Unfollow a record */
    followAction: function(component) {
        var self = this;
        self.callToServer(
            component,
            "c.followRecord",
            function(response) {
                component.set("v.isFollowed", response);
            }, 
            {
                "recordId": component.get("v.recordId"),
                "isFollowed": component.get("v.isFollowed")
            });
    },
    
    /* Method to generate a Printable view of the current record */
    printableViewAction: function(component) {
        var recordId = component.get("v.recordId");
        var url = '/apex/IFv2_PrintableView?id=' + recordId ;
        window.open(url);
    },
    
    /* Method to generate challan for mgp workflow of the current record */
    generateChallanAction: function(component) {
        var recordId = component.get("v.recordId");
        var url = '/apex/IFv2_GenerateChallanPage?id=' + recordId;
        window.open(url);
    },
    
    reassignAction: function(component) {
        component.set("v.showModal", true);
        var compEvents = component.getEvent("componentEventFired");
        compEvents.setParams({ 
            "isModalPopup" : component.get("v.showModal"),
            "recordId" : component.get("v.recordId"),
            "buttonLabel" : component.get("v.button.Label__c")
        });
        compEvents.fire(); 
    },
    
    /* Method to recall the submitted request record*/
    recallAction: function(component) {
        var self = this;
        self.callToServer(
            component,
            "c.reCallMethod",
            function(response) {
                if(response) {
                    var toastEvent = $A.get("e.force:showToast");
                    var appEvent = $A.get("e.c:IFv2_Headerevent");
                    appEvent.setParams({
                        "requestStatus" : "Draft",
                        "eventFired" : "true"
                    })
                    toastEvent.setParams({
                        "title": "Success!",
                        "type": "success",
                        "message": $A.get("$Label.c.CLIFv20173")
                    });
                    toastEvent.fire();
                    appEvent.fire();
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Warning!",
                        "type": "Error",
                        "message": $A.get("$Label.c.CLIFv20141")
                    });
                    toastEvent.fire();
                }
            }, 
            {
                "recId": component.get("v.recordId"),
                "workflow": component.get("v.workflow"),
                "ApproverSectionMetadata" : component.get("v.approverSectionMetadata")
            });
    },
    
    /* Method to reject the submitted request record*/
    rejectAction: function(component) {
        component.set("v.showModal", true);
        var compEvents = component.getEvent("componentEventFired");
        compEvents.setParams({ 
            "isModalPopup" : component.get("v.showModal"),
            "recordId" : component.get("v.recordId"),
            "buttonLabel" : component.get("v.button.Label__c")
        });
        compEvents.fire();
    },
    
    /* Method to restart the approval process if its rejected */
    restartAction: function(component) {
        var self = this;
        self.callToServer(
            component,
            "c.restartMethod",
            function(response) {
                if(response) {
                    var toastEvent = $A.get("e.force:showToast");
                    var appEvent = $A.get("e.c:IFv2_Headerevent");
                    appEvent.setParams({
                        "requestStatus" : "Draft",
                        "eventFired" : "true"
                    });
                    toastEvent.setParams({
                        "title": "Success!",
                        "type": "success",
                        "message": $A.get("$Label.c.CLIFv20143")
                    });
                    toastEvent.fire();
                    appEvent.fire();
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Warning!",
                        "type": "Error",
                        "message": $A.get("$Label.c.CLIFv20142")
                    });
                    toastEvent.fire();
                }
            }, 
            {
                "recId": component.get("v.recordId"),
                "workflow": component.get("v.workflow"),
                "ApproverSectionMetadata" : component.get("v.approverSectionMetadata")
            });
    },
    
    /*Method to handle Verify and Submit */
    verifySubmitAction: function(component) {
        var appEvent = $A.get("e.c:IFv2_ValidationCheck_EVENT");
        appEvent.setParams({
            "recordId": component.get("v.recordId"),
            "approverSectionMetadata" : component.get("v.approverSectionMetadata"),
            "CheckNow" :false
        });
        appEvent.fire();
    },
    
    consultAction : function(component) {
        component.set("v.showModal", true);
        var compEvents = component.getEvent("componentEventFired");
        compEvents.setParams({ 
            "isModalPopup" : component.get("v.showModal"),
            "recordId" : component.get("v.recordId"),
            "buttonLabel" : component.get("v.button.Label__c")
        });
        compEvents.fire();
    }
})