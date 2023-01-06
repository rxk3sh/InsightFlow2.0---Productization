({
    /* Generic call to server */
    callToServer : function(component, method, callback, params, storable) {
        var action = component.get(method);
        if(storable) {
            action.setStorable(true);
        }
        if(params) {
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
                        component.set("v.alertMessage", $A.get("$Label.c.CLIFv20032") + " " + errors[0].message);
                        component.set("v.isAlertError", true);
                    }
                }
            } else {
                component.set("v.alertMessage", $A.get("$Label.c.CLIFv20057"));
                component.set("v.isAlertError", true);
            }
        });
        $A.enqueueAction(action);
    },
    
    /* Method to get the list of buttons to be displayed */
    getHeaderButtonList: function(component) {
        var self = this;
        self.callToServer(
            component,
            "c.getButtonList",
            function(response) {
                component.set("v.isApprover", false);
                component.set("v.buttons", response);
                component.set("v.status", response.status);
                component.set("v.buttonLabels", response.button);
                component.set("v.createdById", response.createdById);
                component.set("v.oldRequest", response.oldRequest);
                component.set("v.approverRoleName",response.privilegedRoleName);
                if(component.get("v.buttonLabels[0]") !== null && component.get("v.buttonLabels[0]") !== undefined) {
                    
                    var approveButton = component.get("v.buttonLabels[0]").Label__c;
                    var buttonsList = component.get("v.buttonLabels");
                    var buttonListString = '';
                    for(var i=0; i<buttonsList.length; i++) {
                        buttonListString = buttonListString + ','+ buttonsList[i].Label__c;
                    }
                    if(buttonListString.includes("Upload Files")) {
                        /* Upload Files event for IFv2_NotesAndAttachmentCmp */
                        var notesAndAttachmentsEvent = $A.get("e.c:IFv2_RefreshRelatedListEvent");
                        notesAndAttachmentsEvent.setParams({
                            "hasUploadFiles":true,
                            "forNotesAndAttachments":true
                        });
                        notesAndAttachmentsEvent.fire();
                        /* Upload Files event End */
                    } else {
                        /* Upload Files event for IFv2_NotesAndAttachmentCmp */
                        var notesAndAttachmentsEvent = $A.get("e.c:IFv2_RefreshRelatedListEvent");
                        notesAndAttachmentsEvent.setParams({
                            "hasUploadFiles":false,
                            "forNotesAndAttachments":true
                        });
                        notesAndAttachmentsEvent.fire();
                        /* Upload Files event End */
                    }
                    console.log('attachmentList'+response.attachmentList);
                    if(response.attachmentList !== undefined) {
                        component.set("v.isApprover", true);
                        var alertMsg = $A.get("$Label.c.CLIFv20066");
                        component.set("v.alertMsg", alertMsg);
                        self.openAttachments(component);
                    } else {
                        /* Iteration 3 Changes, not to display error message */ 
                        /* Removed code which displays message that there are no PDF to check */
                        /* End of Iteration 3 changes */
                    }
                }
            },
            {
                "requestId" : component.get("v.recordId")
            },
            false
        );
    },
    
    /* for opening PDF attachments in a new window if approver open the request */
    openAttachments : function(component) {
        var pdfResults = component.get("v.buttons.attachmentList");
        if(pdfResults !== undefined) {
            for (var i=0; i<pdfResults.length; i++) {
                if(pdfResults[i].substring(0,3) === '069') {
                    window.open("/sfc/servlet.shepherd/document/download/"+pdfResults[i]);
                }
            }
        }
    },
    
    /* for opening content documents in a new window if help icon is clicked*/
    openContentDocument: function(component) {
        var self = this;
        self.callToServer(
            component,
            "c.returnContentDocumentURL",
            function(response) {
                var contentDocumenturl = response;
                if(contentDocumenturl !== undefined) {
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": contentDocumenturl
                    });
                    urlEvent.fire(); 
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type" : "error",
                        "message": $A.get("$Label.c.CLIFv20139")
                    });
                    toastEvent.fire();
                }
            },
            {
                "workflow" : component.get("v.buttons")["workflow"]
            },
            true
        );
    },
    
    /* For opening help url documents in a new window if help icon is clicked */
    openHelpUrlDocument: function(component) {
        var self = this;
        self.callToServer(
            component,
            "c.returnHelpDcoument",
            function(response) {
                var Documenturl = response;
                if(Documenturl !== undefined) {
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": Documenturl
                    });
                    urlEvent.fire(); 
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Warning!",
                        "type" : "warning",
                        "message": $A.get("$Label.c.CLIFv20163")
                    });
                    /* Firing error message if no help url is present for that workflow */
                    toastEvent.fire();
                }
            },
            {
                "workflow" : component.get("v.buttons")["workflow"]
            },
            true
        );
    },
    
    /* Method used to Delete a request record */
    deleteAction: function(component) {
        var self = this;
        self.callToServer(
            component,
            "c.deleteRecord",
            function(response) {
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Deleted",
                    "type": "success",
                    "message": $A.get("$Label.c.CLIFv20170")
                });
                var navEvent = $A.get("e.force:navigateToList");
                navEvent.setParams({
                    "listViewId": null,
                    "listViewName": null,
                    "scope": "IFv2_Request__c"
                });
                setTimeout(function(){ resultsToast.fire(); }, 1500);
                navEvent.fire();
            },
            {
                "reqId": component.get("v.recordId")
            });
    }
})