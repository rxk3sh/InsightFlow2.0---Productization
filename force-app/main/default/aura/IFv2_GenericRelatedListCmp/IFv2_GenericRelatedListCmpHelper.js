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
                        /*var errorEvent = $A.get("e.c:IFv2_AlertApplicationEvent");
                        errorEvent.setParams({
                            "alertMessage" : "Error message: " + errors[0].message,
                            "isError" : true
                        });
                        errorEvent.fire(); */
                    }
                }
            } else {
                component.set("v.alertMessage", "ERROR: Unknown Error");
                component.set("v.isAlert", true);
            }
        });
        $A.enqueueAction(action);
    },
    
    fetchRelatedLists : function(component, method, callback, params) {
        var self = this;
        var recordId = component.get("v.recordId");
        var sobjectName = component.get("v.sObjectName");
        
        /* Fetch the records */
        self.callToServer(
            component,
            "c.getForm", /* server method */
            function(response) {
                component.set("v.wrapperList", response);
            },
            {
                /* params */
                "recordId" :  recordId,
                "objectName" :  sobjectName
            },
            false
        );
    },
})