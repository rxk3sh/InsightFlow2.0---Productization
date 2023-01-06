({
    /** Loads the component on load **/
    doInit : function(component, event, helper) {
        if(component.get("v.actionType") == 'View'){
            component.set("v.editMode",false);
        }else{
            component.set("v.editMode",true);
        }
    },
    
    /** Method to execute workflow **/
	executeWorkflow : function(component, event, helper) {
		helper.executeWorkflowHelper(component, event, helper);
	},
    
    /**Fires when we click on Edit button **/
    editRecord : function(component, event, helper) {
        var cmpEvent = $A.get("e.c:IFv2_EditEvent");
        cmpEvent.fire();
        component.set("v.actionType","Edit");
    }
})