({
    callToServer: function(component, method, callback, params) {
        var action = component.get(method);
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
                        component.set("v.alertMessage", "Error message: " + errors[0].message);
                        component.set("v.isAlert", true);
                    }
                }
            } else {
                component.set("v.alertMessage", "ERROR: Unknown Error");
                component.set("v.isAlert", true);
            }
        });
        $A.enqueueAction(action);
    },
    
    updateScan: function(component, event, helper) {
        var self = this;
        var recordId = component.get("v.recordId");	
        /* Server call */
        self.callToServer(
            component,
            "c.updateScanRecord", /* server method */
            function(response) {
                var responseString = response;
                component.set("v.responseString",responseString); 
                if(responseString === 'Success') {
                    component.set("v.isSuccess",true);
                } else {
                    component.set("v.isFailure",true);
                }
                $A.get('e.force:refreshView').fire();
            },
            {
                /* params */
                "scanId" :  component.get("v.recordId")
            }
        );
    },
    
})