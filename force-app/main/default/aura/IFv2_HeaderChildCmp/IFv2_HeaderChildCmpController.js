({
    doInit : function(component, event, helper) {
        /* Logic for dynamically creating buttons */
        
        if(component.get("v.button.Label__c") === "Follow") {
            helper.getFollowStatus(component);
            $A.createComponent(
                "lightning:buttonStateful",
                {
                    "labelWhenOff" : "Follow",
                    "labelWhenOn" : "Following",
                    "labelWhenHover" : "Unfollow",
                    "iconNameWhenOff" : "utility:add",
                    "iconNameWhenOn" : "utility:check",
                    "iconNameWhenHover" : "utility:close",
                    "state" : component.getReference("v.isFollowed"),
                    "onclick": component.getReference("c.handleButtonClick"),
                    "disabled" : component.getReference("v.disabled")
                },
                function(newButton, status, errorMessage){
                    if (status === "SUCCESS") {
                        var body = component.get("v.body");
                        body.push(newButton);
                        component.set("v.body", body);
                    } else if (status === "INCOMPLETE") {
                        var compEvent = component.getEvent("alertEvent");
                        compEvent.setParams({
                            "alertMessage" : $A.get("$Label.c.CLIFv20171"),
                            "isError" : true
                        });
                        compEvent.fire();
                    } else if (status === "ERROR") {
                        var compEvent = component.getEvent("alertEvent");
                        compEvent.setParams({
                            "alertMessage" : $A.get("$Label.c.CLIFv20032") + " " + errorMessage,
                            "isError" : true
                        });
                        compEvent.fire();
                    }
                });
        } else if(component.get("v.button.Label__c") === "Upload Files") {
            // do nothing
            /*$A.createComponent(
                "lightning:fileUpload",
                {
                    "name" : "fileUploader",
                    "recordId" : component.get("v.recordId"),
                    "onuploadfinished" : component.getReference("c.refreshNotesAndAttachments")
                  
                },
                function(newButton, status, errorMessage){
                    if (status === "SUCCESS") {
                        var body = component.get("v.body");
                        body.push(newButton);
                        component.set("v.body", body);
                    } else if (status === "INCOMPLETE") {
                        var compEvent = component.getEvent("alertEvent");
                        compEvent.setParams({
                            "alertMessage" : $A.get("$Label.c.CLIFv20171"),
                            "isError" : true
                        });
                        compEvent.fire();
                    } else if (status === "ERROR") {
                        var compEvent = component.getEvent("alertEvent");
                        compEvent.setParams({
                            "alertMessage" : $A.get("$Label.c.CLIFv20032") + " " + errorMessage,
                            "isError" : true
                        });
                        compEvent.fire();
                    }
                });*/
        } else {
            if(component.get("v.type") === "group") {
                $A.createComponent(
                    "lightning:button",
                    {
                        "label": component.get("v.button.Label__c"),
                        "aura:id": component.get("v.button.Label__c"),
                        "multiple" : true,
                        "disabled" : component.getReference("v.disabled"),
                        "onclick": component.getReference("c.handleButtonClick")
                    },
                    function(newButton, status, errorMessage){
                        if (status === "SUCCESS") {
                            var body = component.get("v.body");
                            body.push(newButton);
                            component.set("v.body", body);
                        } else if (status === "INCOMPLETE") {
                            var compEvent = component.getEvent("alertEvent");
                            compEvent.setParams({
                                "alertMessage" : $A.get("$Label.c.CLIFv20171"),
                                "isError" : true
                            });
                            compEvent.fire();
                        } else if (status === "ERROR") {
                            var compEvent = component.getEvent("alertEvent");
                            compEvent.setParams({
                                "alertMessage" : $A.get("$Label.c.CLIFv20032") + " " + errorMessage,
                                "isError" : true
                            });
                            compEvent.fire();
                        }
                    });
            } else {
                $A.createComponent(
                    "lightning:button",
                    {
                        "label": component.get("v.button.Label__c"),
                        "multiple" : true,
                        "disabled" : component.getReference("v.disabled"),
                        "onclick": component.getReference("c.handleButtonClick"),
                        "class": "custom-menu"
                    },
                    function(newButton, status, errorMessage){
                        if (status === "SUCCESS") {
                            var body = component.get("v.body");
                            body.push(newButton);
                            component.set("v.body", body);
                        } else if (status === "INCOMPLETE") {
                            var compEvent = component.getEvent("alertEvent");
                            compEvent.setParams({
                                "alertMessage" : $A.get("$Label.c.CLIFv20171"),
                                "isError" : true
                            });
                            compEvent.fire();
                        } else if (status === "ERROR") {
                            var compEvent = component.getEvent("alertEvent");
                            compEvent.setParams({
                                "alertMessage" : $A.get("$Label.c.CLIFv20032") + " " + errorMessage,
                                "isError" : true
                            });
                            compEvent.fire();
                        }
                    });
            }
        }
    },
    
    /* Calling helper action methods based on clicked button */
    handleButtonClick : function(component, event, helper) {
        var buttonLabel = component.get("v.button.Label__c");
        switch(buttonLabel) {
            case "Edit":
                helper.editAction(component, event);
                break;
            case "Add":
                helper.addAction(component, event);
                break;
            case "Approve":
                helper.approveAction(component);
                break;
            case "Check Now":
                helper.checkNowAction(component);
                break;
            case "Clone":
                helper.cloneAction(component);
                break;
            case "Consult":
                helper.consultAction(component);
                break;
            case "Delete":
                helper.deletePopUpAction(component);
                break;
            case "Follow":
                helper.followAction(component);
                break;
            case "Print":
                helper.printableViewAction(component);
                break;
                case "Generate Challan":
                helper.generateChallanAction(component);
                break;
            case "Reassign":
                helper.reassignAction(component);
                break;
            case "Recall":
                helper.recallAction(component);
                break;
            case "Reject":
                helper.rejectAction(component);
                break;
            case "Restart":
                if(!component.get("v.oldRequest")){
                    helper.restartAction(component);
                }else {
                    component.set("v.oldRequestRestart",true);
                }
                break;
            case "Verify & Submit":
                helper.verifySubmitAction(component);
                break;
        }
    },
    
    /* refresh notes and attachments on upload */
    refreshNotesAndAttachments : function(component, event, helper) {
        var appEvent = $A.get("e.c:IFv2_UploadFileEvent");
        appEvent.fire();
    }
})