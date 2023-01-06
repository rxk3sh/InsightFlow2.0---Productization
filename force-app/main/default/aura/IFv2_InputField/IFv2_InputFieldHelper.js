({
    callToServer: function(component, method, callback, params, storable) {
        var action = component.get(method);
        action.setBackground(true);
        if (storable) {
            action.setStorable();
        }
        if (params) {
            action.setParams(params);
        }
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.isAlert", false);
                component.set("v.alertMessage", []);
                callback.call(this, response.getReturnValue());
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors && errors[0]) {
                    if(errors[0].message) {
                        var messages = component.get("v.alertMessage");
                        if(messages === undefined){
                            messages=[];
                        }
                        messages.push("Error message: " + errors[0].message);
                        component.set("v.alertMessage", messages);
                        component.set("v.isAlert", true);
                    }
                    var pageError = errors[0].pageErrors;
                    
                    if (pageError && pageError[0] && pageError[0].message) {
                        var messages = component.get("v.alertMessage");
                        messages.push("Error message: " + pageError[0].message);
                        component.set("v.alertMessage", messages);
                        component.set("v.isAlert", true);
                    }
                    var fieldError = errors[0].fieldErrors;
                    if (fieldError && fieldError.Name && fieldError.Name[0] &&  fieldError.Name[0].message) {
                        var messages = component.get("v.alertMessage");
                        messages.push("Error message: " + fieldError.Name[0].message);
                        component.set("v.alertMessage", messages);
                        component.set("v.isAlert", true);
                    }
                }
            } else {
                var messages = component.get("v.alertMessage");
                messages.push("ERROR: Unknown Error");
                component.set("v.alertMessage", messages);
                component.set("v.isAlert", true);
            }
        });
        $A.enqueueAction(action);
    },
    getDependentPickListValues : function(component,value,dependentField,controllerField){
        var self=this;
        self.callToServer(
            component,
            "c.getDependentpickListVal",
            function(response) {
                var options = [];
                var field = component.get("v.field");
                var values = response;
                for(var i=0;i<values.length;i=i+1) {
                    options.push(values[i]);
                }
                var value=component.get("v.value");
                if(options.indexOf(value) < 0) {
                    component.set("v.value", "");
                    
                }
                component.set("v.picklistvalues", options);
                if(options.length === 0){
                    component.set("v.disable",true);
                }
                else{
                    component.set("v.disable",false);
                }
            },
            {
                "value" : value,
                "depField" : dependentField,
                "controllingfield" : controllerField
            },
            false
        );
    }
    
})