/*
 * Custom Labels Used
 * IFv2_Workflow_Approver_Mapping : List of Workflows requiring auto populating Approvers based on mapping before save
 */
({
    /*Initialize the component on page load*/
    doInit: function(component, event, helper) {
        component.set("v.currentUser", $A.get("$SObjectType.CurrentUser.Id"));
        var recordType = component.get("v.recordType");
        /* if object detail page */
        if (recordType === "Custom Object") {
            component.set("v.saveButtonLabel", $A.get("$Label.c.CLIFv20180"));
            
            helper.callToServer(
                component,
                "c.getForm",
                function(response) {
                    if(response.fieldNames !== undefined) {
                        component.set("v.fieldNames", response.fieldNames);
                        if(response.fieldNames.length > 0) {
                            component.set("v.loadRecord", true);
                            component.set("v.showSpinner", true);
                        } else {
                            var messages = component.get("v.alertMessage");
                            if(messages === undefined) {
                                messages = [];
                            }
                            messages.push($A.get("$Label.c.CLIFv20181"));
                            component.set("v.alertMessage", messages);
                            component.set("v.isAlert", true);
                        }
                    }
                    
                    if(response.metadata !== undefined) {
                        component.set("v.metadata", response.metadata);
                        helper.passMetadataToHeader(component);
                    }
                    /* Added to load purchasing data on page load */
                    if(response.directIndirectdefaultList !== undefined) {
                        component.set("v.purchaseMetadata", response.directIndirectdefaultList);
                    }
                    
                    $A.createComponent(
                        "c:IFv2_ValidationCheckComponent",
                        {
                            "Request" : component.getReference("v.record"),
                            "ObjectName" : component.get("v.sObjectName"),
                            "RequiredFieldList" : component.getReference("v.requiredFieldsList"),
                            "aura:id" : "validation",
                            "isAlert" : component.getReference("v.isAlert"),
                            "alertMessage": component.getReference("v.alertMessage"),
                            "RequiredFieldListWrapper" : component.getReference("v.metadata")
                        },
                        function(comp, status) {
                            if(status === "SUCCESS") {
                                var body = component.get("v.body");
                                body.push(comp);
                                component.set("v.body", body);
                            }
                        });
                },
                {
                    "objectName": component.get("v.sObjectName"),
                    "recordId": component.get("v.recordId"),
                    "recordType": component.get("v.recordType")
                },
                false);
        }
        /*if custom setting detail page*/
        else if (recordType === "Custom Setting") {
            if(component.get("v.newButton")) {
                component.set("v.recordId", "");
            }
            component.set("v.saveButtonLabel", $A.get("$Label.c.CLIFv20183"));
            /*get record and section list*/
            helper.callToServer(
                component,
                "c.getForm",
                function(response) {
                    if(response.record !== undefined && response.record !== null) {
                        component.set("v.record", response.record);
                        component.set("v.initRecord", JSON.parse(JSON.stringify(response.record)));
                    }
                    if(component.get("v.newButton")) {
                        component.set("v.record", {sobjectType:component.get("v.sObjectName")})
                    }
                    if(response.metadata !== undefined) {
                        if(response.metadata.length > 0) {
                            component.set("v.metadata", response.metadata);
                            component.set("v.recordLoad", true);
                        }
                    }
                }, 
                {
                    "objectName": component.get("v.sObjectName"),
                    "recordId": component.get("v.recordId"),
                    "recordType": component.get("v.recordType")
                }, 
                false);
        }
    },
    
    fireSaveEvent: function(component, event, helper) {
        var recordType = component.get("v.recordType");
        
        /*If object detail page and needs approver mapping, fire event and wait for response to save the mapping*/
        if (component.get("v.purchaseWorkflow") && recordType !== "Custom Setting") {
            helper.purchaseAssignments(component, true);
        } else {
            helper.saveRecord(component);
        }
    },
    
    /*Handle Edit button click*/
    toggleEditMode : function(component, event, helper) {
        if(event !== undefined && event.getParam("isPrivilegedApprover") !== undefined && event.getParam("approverRole") !== undefined){
            var metadata = component.get("v.metadata")!==undefined?component.get("v.metadata"):[];
            var approverRole =  event.getParam("approverRole");
            var reqStatus = component.get("v.record.Status__c");
            if(reqStatus === "Submitted"){
                for(var i=0;i<metadata.length;i++){
                    if(metadata[i].section.EditRoles__c !== undefined){
                        var roles = (metadata[i].section.EditRoles__c).split(',');
                        if(roles.indexOf(approverRole)>=0 && metadata[i].section.isApproverEditable__c){
                            metadata[i].section.ReadOnly__c = false;
                            continue;
                        } else{
                            metadata[i].section.ReadOnly__c = true;
                        }
                    } else {
                        metadata[i].section.ReadOnly__c = true;
                    }
                }
                component.set("v.metadata",metadata);
            }
            
        }
        component.set("v.isEditMode", true);
    },
    
    /*Handle Expand all click*/
    expandAll: function(component, event, helper) {
        component.set("v.expandAll", "expand");
    },
    
    /*Handle Collapse All click*/
    collapseAll: function(component, event, helper) {
        component.set("v.expandAll", "collapse");
    },
    
    /* Handle cancel click*/
    cancel: function(component,event){
        if(component.get("v.newButton")) {
            var evt = $A.get("e.force:navigateToComponent");
            evt.setParams({
                componentDef : "c:IFv2_WorkflowListViewCmp",
                componentAttributes: {
                }
            });
            evt.fire();
        } else {
            component.set("v.record", JSON.parse(JSON.stringify(component.get("v.initRecord"))));
            component.set("v.isEditMode", false);
            var editEvent = $A.get("e.c:IFv2_EditButtonHandleEvent");
            editEvent.setParams({
                "isEdit" : false
            });
            editEvent.fire();
        }
        component.set("v.isAlert", false);
        component.set("v.alertMessage",[]);
    },
    
    /*Call after record is loaded*/
    recordLoaded : function(component, event, helper) {
        var record = component.get("v.record");
        if(record !== undefined && record !== null) {
            component.set("v.recordLoad", true);
            component.set("v.showSpinner", false);
            component.set("v.initRecord", JSON.parse(JSON.stringify(component.get("v.record"))));
            
            /* purchasing approval condition */
            var workFlows = $A.get("$Label.c.CLIFv20054");
            var workFlowList = workFlows.split(",");
            var currentWorkFlowName = component.get("v.record.Workflow__c");
            
            if (workFlowList.indexOf(currentWorkFlowName) > -1) {
                component.set("v.purchaseWorkflow", true);
            }
        } else {
            helper.refreshRecord(component,false);            
        }
    },
    
    /*Reload record*/
    reloadRecord : function(component, event, helper) {
        var workflowName = event.getParam("workflowName");
        var forNotesAndAttachments = event.getParam("forNotesAndAttachments");
        var mappingFromRelatedList = event.getParam("mappingFromRelatedList");
        if(mappingFromRelatedList === undefined) {
            mappingFromRelatedList = false;
        }
        var workflowsToRefresh = $A.get("$Label.c.CLIFv20149");
        var workflowsToRefreshSplitted = [];
        if(workflowsToRefresh !== undefined && workflowsToRefresh !== null) {
            workflowsToRefreshSplitted = workflowsToRefresh.toLowerCase().split(",");
        }
        if(!forNotesAndAttachments || forNotesAndAttachments === undefined) {
            if(workflowName === undefined ||
               (workflowsToRefreshSplitted !== null && workflowsToRefreshSplitted.includes(workflowName.toLowerCase()))) {
                var record = component.get("v.record");
                if(component.find("forceRecord") !== undefined && record["Workflow__c"] !== $A.get("$Label.c.CLIFv20046") && record["Workflow__c"] !== $A.get("$Label.c.CLIFv20199")) {
                    component.find("forceRecord").reloadRecord(true);
                } else {
                    helper.refreshRecord(component,mappingFromRelatedList);  
                }
            }
        }
    },
    
    /* method to toggle spinner for checknow button */
    /* Start of code added for iteration 3  */
    toggleSpinner : function(component, event, helper) {
        /* variable to show and hide spinner */ 
        var showspinner = event.getParam("showSpinner");
        /* Checking for show spinner value from button component */
        if(showspinner) {
            component.set("v.showSpinner", true);
        } else {
            component.set("v.showSpinner", false);
        }
    },
    
    // To update concession record
    updateConcessionRecord : function(component, event, helper) {
        var updatedMaterialDescripition = event.getParam("materialdescription");
        var checkboxvalue = event.getParam("checkboxValue");
        var plantValue = event.getParam("plantvalue");
        var supplierName = event.getParam("supplierName");
        var customerText = event.getParam("custometText");
        component.set("v.record.MaterialDescription__c",updatedMaterialDescripition);
        component.set("v.record.AreAllMaterialsValidated__c",checkboxvalue);
        component.set("v.record.Account__r.IFv2_Concession_Plant_Name__c",plantValue);
        component.set("v.record.Account__r.IFv2_ConcessionSupplierName__c",supplierName);
        component.set("v.record.Account__r.IFv2_ConcessionCustomerText__c",customerText);
        
        // To remove error message from being displayed
        component.set("v.isAlert", false);
        component.set("v.alertMessage",[]);
    }
})