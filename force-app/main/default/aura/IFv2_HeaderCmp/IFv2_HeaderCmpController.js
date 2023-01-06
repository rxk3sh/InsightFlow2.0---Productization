({
    doInit : function(component, event, helper) {
        helper.getHeaderButtonList(component);
    },
    
    /* Handles the Approve/Reject or Reassign Events */
    handleApprovalEvent: function(component, event, helper) {
        var modalValue =event.getParam("isModalPopup");
        var recordId =event.getParam("recordId");
        var buttonLabel =event.getParam("buttonLabel");
        component.set("v.recordID", recordId);
        component.set("v.buttonName", buttonLabel);
        component.set("v.isModalParent", modalValue);
        /* If reassigning, shows lookup to list of approvers */
        if(buttonLabel === "Reassign" || buttonLabel === "Consult") {
            component.set("v.showLookupCmp", true);
        } else {
            component.set("v.showLookupCmp", false);
        }
    },
    
    /* Handling alerts */
    handleAlerts : function(component, event, helper) {
        var alertMessage = event.getParam("alertMessage");
        var isError = event.getParam("isError");
        component.set("v.alertMessage", alertMessage);
        if(isError) {
            component.set("v.isAlertError", true);
        }
    },
    
    handleToast : function(component, event, helper) {
        component.set("v.isModalParent", false);
        var message = event.getParam("message");
        var type = event.getParam("type");
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": type.toUpperCase(), //Passing parameters for toast messages
            "type": type,
            "message": message
        });
        var refreshEvent = $A.get("e.c:IFv2_Headerevent");
        refreshEvent.fire();
        toastEvent.fire();
    },
    
    editEventAction : function(component, event, helper) {
        component.set("v.disabled", true);
    },
    
    handleDeleteRecord : function(component, event, helper) {
        component.set("v.isModalOpen", true);
    },
    
    editButtonAction : function(component, event, helper) {
        if(event.getParam("isEdit")) {
            component.set("v.disabled",true);
        } else {
            component.set("v.disabled",false);
        }
    },
    
    /*Help button  before Back up.*/
    helpPage : function(component, event, helper) {
        helper.openContentDocument(component);
    },
    
    /*Help button  before Back up.*/
    openHelpDocument : function(component, event, helper) {
        helper.openHelpUrlDocument(component);
    },
    
    /** Closes the modal **/
    closeModel: function(component, event, helper) {
        component.set("v.isModalOpen", false);
    },
    
    /** Deletes the Request record**/
    deleteRequest: function(component, event, helper) {
        helper.deleteAction(component, event, helper);
    },
    
    /** Toggle the visibility of the drop down menu **/
    toggleVisibility : function(component, event) {
        var dropDownDiv = component.find('dropDownId');
        $A.util.toggleClass(dropDownDiv,'slds-is-open');
    },
    
    handleSectionMetadata : function(component, event) {
        var approverSectionsData = event.getParam("approverSectionMetadata");
        component.set("v.approverSectionMetadata",approverSectionsData);
        var buttonsId = component.find('buttons-id');
        $A.util.removeClass(buttonsId,'slds-hide');
        $A.util.addClass(buttonsId,'slds-show');
    }
})