({
    
    doInit : function(component, event, helper) {
        var buttonName = component.get("v.buttonName");
        component.set("v.buttonDisplayName", component.get("v.buttonName"));
        if(buttonName == 'Reassign') {
            component.set("v.userLookupLabel","Reassign To");
        }
        else if(buttonName == 'Consult') {
            component.set("v.userLookupLabel","Select User");
            component.set("v.buttonDisplayName","Post");
        }
    },
    
    /** Closes the modal **/
    closeModel: function(component, event, helper) {
        component.set("v.isOpen", false);
       
    },   
    /** saves the data based on button click **/
    ApproverRequest: function(component, event, helper) {
        
        if(component.get("v.buttonName") == 'Approve'){
            helper.ApproveRequestHelper(component, event, helper); 
        } else if(component.get("v.buttonName") == 'Reject'){
            if(component.get("v.comments") === undefined || component.get("v.comments") === '') {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!", //Passing parameters for toast messages
                    "type": "error",
                    "message": $A.get("$Label.c.CLIFv20174")
                });
                toastEvent.fire();
            } else {
                helper.RejectRequestHelper(component, event, helper);
            }
        } else if(component.get("v.buttonName") == "Reassign"){
            if(component.get("v.selectedId") === component.get("v.createdById")) {
                component.set("v.isAlertError",true);
                component.set("v.alertMessage",$A.get("$Label.c.CLIFv20067"));
            }else {
                component.set("v.isAlertError",false);
                helper.ReassignRequestHelper(component, event, helper);
            }
        } else if(component.get("v.buttonName") == "Consult") {
            helper.ConsultRequestHelper(component, event, helper); 
        }
    },
})