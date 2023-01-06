({
    /** Loads Workflows,User details and Active list of users **/
    doInit : function(component, event, helper) {
        helper.setColumns(component);
        helper.loadDetails(component);
        
        //To get the Logged in User to disable from User Lookup
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        component.set("v.userId" , userId);
    },
    
    /** Holds the value of the Checkbox **/
    onEnableChecked : function(component, event) {
        component.set("v.enableOutOfOffice", event.getSource().get("v.checked"));
        
        if(event.getSource().get("v.checked")) {
            component.set("v.displayMessage", $A.get("$Label.c.CLIFv20195"));
            component.set("v.displayBodyMessage", $A.get("$Label.c.CLIFv20193"));
        } else {
            component.set("v.displayMessage", $A.get("$Label.c.CLIFv20195"));
            component.set("v.displayBodyMessage", $A.get("$Label.c.CLIFv20194"));
        }
        component.set("v.enableCheckbox", true);
    },
    
    /** Holds the value of workflow picklist **/
    handleOptionSelected : function(component, event, helper) {
        component.set("v.selectedWF", event.getParam("value"));
    },
    
    /** On Add saves the OutofOffice record in IFv2_AdminOnly__c **/
    saveOutOfOffice : function(component, event, helper) {
        
        $A.util.removeClass(component.find("selectItem"), "slds-has-error");
        $A.util.removeClass(component.find("UserId"), "slds-has-error");
        var workflow = component.get("v.selectedWF");
        var user = component.get("v.selectedId");
        if( workflow !== undefined && user !== undefined) {
            if(workflow === "" || workflow === null) {
                $A.util.addClass(component.find("selectItem"), "slds-has-error");
                return;
            } else if(user === "") {
                $A.util.addClass(component.find("UserId"), "slds-has-error");
                return;
            } else {
                helper.saveOutOfOfficeHlpr(component);
            }
        } 
    },
    
    /** On delete BacktoOffice record is saved **/
    DisableOutOfOffice :  function(component, event, helper) {
        var action = event.getParam("action");
        var record = event.getParam("row");
        switch (action.name) {
            case "deleteRecord":
                helper.DisableOutOfOfficeHlpr(component, record);
                break;
        }
        //To close the modal on Edit or delete
        component.set("v.isOpen", false);
    },
    
    /** View All button to show all the records **/
    handleViewAll : function(component) {
        component.set("v.isOpen", true);
    },
    
    /** Close modal**/
    closeModal : function(component) {
        component.set("v.isOpen", false);
    },
    
    /**  Cancel button **/
    cancelButton : function(component) {
        component.set("v.disableDelete", false);
        component.set("v.isAlert", false);
        component.set("v.selectedId", "");
        component.set("v.selectedWF", null);
        component.set("v.recordId", "");
        $A.util.removeClass(component.find("selectItem"), "slds-has-error");	// To remove slds-has-error css 
        $A.util.removeClass(component.find("UserId"), "slds-has-error");		// To remove slds-has-error css
    },
    
    /* trigger sorting function */
    handleColumnSorting : function (component, event, helper) {
        var fieldName = event.getParam("fieldName");
        var sortDirection = event.getParam("sortDirection");
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    },
    
    /* To close modal*/
    closeUpdateModal : function (component) {
        component.set("v.enableCheckbox", false);
        var buttonstatus = component.get("v.enableOutOfOffice");
        if(buttonstatus) {
            component.set("v.enableOutOfOffice", false);
        } else {
            component.set("v.enableOutOfOffice", true);
        }
    },
    
    /* To update Out of office and back to office */
    saveModal : function (component, event, helper) {
         /* Check for records before saving*/
       
        if(component.get("v.UserDetails").length>0 && component.get("v.enableOutOfOffice")===true)
        {
            component.set("v.enableCheckbox", false);
            helper.updateAllRecords(component); 
        }
        else if(component.get("v.enableOutOfOffice")===false)
        {
            component.set("v.enableCheckbox", false);
            helper.updateAllRecords(component);
        }
        else if(component.get("v.UserDetails").length<=0 && component.get("v.enableOutOfOffice")===true)
        {
            var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": $A.get("$Label.c.CLIFv20129"),
                        "type": "failure",
                        "message": $A.get("$Label.c.CLIFv20318")
                    });
                    resultsToast.fire();
        } 
       
            
        /////////////////////
        
    }
})