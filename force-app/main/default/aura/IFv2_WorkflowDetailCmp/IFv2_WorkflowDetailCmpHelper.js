({
    /** Generic method which handles the server calls **/
    callToServer :function(component,method,callback,params,storable){
        //component.set("v.showSpinner", true);
        var action = component.get(method);
        if(storable){
            //  action.setStorable();
        }
        if(params){
            action.setParams(params);
        }
        action.setCallback(this,function(responsethis){
            component.set("v.showSpinner", false);
            var state = responsethis.getState();
            if (state === "SUCCESS") {
                callback.call(this, responsethis.getReturnValue());
            } 
            else if(state === "ERROR"){
                var errors = responsethis.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.alertMessage", $A.get("$Label.c.CLIFv20032") + " " + errors[0].message);
                        component.set("v.isAlert", true);
                    }
                }
            } else {
                component.set("v.alertMessage", $A.get("$Label.c.CLIFv20057"));
                component.set("v.isAlert", true);
            }
        });
        $A.enqueueAction(action);
    }, 
    
    /** Executing the workflow **/
    executeWorkflowHelper : function(component, event, helper) {
        var self = this;
        /* get all the  fileds to display */
        self.callToServer(
            component,
            "c.createRequestRecord",    /* server method */
            function(response) {
                if(response!==undefined){
                    if(response!==null && response!=='' && response.Id !== undefined){
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
                }
            },
            {
                /* params */
                "workflow" : component.get("v.record")
            },
            true
        );
    },
	
})