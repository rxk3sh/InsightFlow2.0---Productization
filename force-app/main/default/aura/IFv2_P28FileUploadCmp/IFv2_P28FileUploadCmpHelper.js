({
    /* Generic call to server */
    callToServer: function(component, method, callback, params) {
        var action = component.get(method);
        if (params) {
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
                        var errorEvent = $A.get("e.c:IFv2_AlertApplicationEvent");
                        errorEvent.setParams({
                            "alertMessage" : "Error message: " + errors[0].message,
                            "isError" : true
                        });
                        errorEvent.fire();
                    }
                }
            } else {
                component.set("v.alertMessage", "ERROR: Unknown Error");
                component.set("v.isAlert", true);
            }
        });
        $A.enqueueAction(action);
    },
    
    /**uploaded csv is sent to server in the form of string **/
    sendFileToServer : function(component, textdata, filename, description) {
        var self=this;
        var toastMsg = $A.get("$Label.c.CLIFv20202");
        self.callToServer(
            component,
            "c.CreateFileInAdminOnlyObject", /* server method to insert file in admin only object */
            function(response) {
                component.set("v.showSpinner", false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": toastMsg,
                    "mode":"dismissible",
                    "type": "success"
                });
                toastEvent.fire();
                self.cancel(component);
                //Resetting description and filename fields
                component.set("v.descriptionText", "");
                component.set("v.fileName", "");
            },
            {
                /* params */
                "csvAsString" : textdata,
                "filename" : filename,
                "description" : description
            }
        );
    },
    
    cancel : function(component) {
        // when a component is dynamically created in lightning, we use destroy() method to destroy it.
        component.destroy();
        var myEvent = $A.get("e.c:IFv2_P28RefreshEvent");
        
        myEvent.fire();
    }
})