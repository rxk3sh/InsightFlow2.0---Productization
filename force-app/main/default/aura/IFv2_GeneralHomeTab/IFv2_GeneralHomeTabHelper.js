({
    /* Generic method to call the server */
    callToServer : function(component, method, callback, params, storable) {
        var action = component.get(method);
        if(storable) {
            action.setStorable(true);
        }
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
                        component.set("v.alertMessage", $A.get("$Label.c.CLIFv20032") + " " + errors[0].message);
                        component.set("v.isAlertError", true);
                    }
                }
            } else {
                component.set("v.alertMessage", $A.get("$Label.c.CLIFv20057"));
                component.set("v.isAlertError", true);
            }
        });
        $A.enqueueAction(action);
    },
    /* Method to update tabs */
    updateFavoriteTab : function(component){
        var self = this;
        self.callToServer(
            component,
            "c.updateFavorite",
            function(response){
                var cmpEvent = component.getEvent("favoriteUpdate");
                cmpEvent.setParams({
                    "index" : component.get("v.index"),
                    "starred" : !component.get("v.tab").Starred__c,
                    "ListType" : component.get("v.listName")
                });
                cmpEvent.fire();
            },
            {
                "CustomSettingId":component.get("v.tab").Id,
                "isFavorite" : !component.get("v.tab").Starred__c
            },
            false
        );
    }
})