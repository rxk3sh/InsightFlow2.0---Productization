({
    /** Prepare the data on page load **/
    doInit : function(component, event, helper) {
        helper.getAttachments(component);
    },
    
    /* triggers this function onclick of any file */
    openAttachment : function(component, event, helper) {
        $A.get('e.lightning:openFiles').fire({
            recordIds: [event.currentTarget.getAttribute("data-Id")]
        });
    },
    
    /** Opens a modal on click of view All or Related List Name link**/
    handleOnclick : function(component, event, helper) {
        var relatedListEvent = $A.get("e.force:navigateToRelatedList"); 
        relatedListEvent.setParams({
            "relatedListId": "CombinedAttachments",
            "parentRecordId": component.get("v.recordId")
        });
        relatedListEvent.fire();
    },
    
    /* function to close the modal */
    closeModal: function(component, event, helper) {
        // for closing Modal,set the "isOpen" attribute to "false"  
        component.set("v.isOpen", false);
    },
    
    /* refresh notes and attachments on upload */
    refreshNotesAndAttachments : function(component, event, helper) {
        var appEvent = $A.get("e.c:IFv2_UploadFileEvent");
        appEvent.fire();
    },
    
    /* triggers when request is submitted */
    refreshOnSubmit : function(component, event, helper) {
        var hasUploadFiles = event.getParam("hasUploadFiles");
        var forNotesAndAttachments = event.getParam("forNotesAndAttachments");
        if(forNotesAndAttachments) {
            if(hasUploadFiles) {
                component.set("v.isDraft", true);
            } else {
                component.set("v.isDraft", false);
            }
        }
    },
    
    /* open modal onclick of view all */
    navigateToModal : function(component, event, helper) {
        helper.displayModal(component);
    },
    
    /* for toggling the visibility of the drop down menu */
    toggleVisibility : function(component, event, helper) {
        var dropDownDiv = component.find("dropDownId");
        $A.util.toggleClass(dropDownDiv, "slds-is-open");
    }
})