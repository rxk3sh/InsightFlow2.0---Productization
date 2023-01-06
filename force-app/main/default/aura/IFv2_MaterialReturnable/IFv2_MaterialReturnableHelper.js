({
    /* Generic call to server */
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
    
    getMaterials : function(component) {
        var self = this;
        self.callToServer(
            component,
            "c.getMaterialDetails",
            function(response) {
                component.set("v.materialsList",response.materialDetailLIST);
                component.set("v.labelList",response.Labels);
                component.set("v.apiList",response.APINames);
                component.set("v.isParent",response.isParent);
               /* if(!component.get("v.isParent")){
                    component.set("v.showButton", true);
                }*/
                if(response.isParent){
                    component.set("v.buttonLabel",'Update');
                }else{
                    component.set("v.buttonLabel",'Update Returned Quantity');
                }
            },
            {
                "requestId" : component.get("v.recordId")
            },
            false
        );
    },
    
    updateReturnedMaterial : function(component) {
        var self = this;
        self.callToServer(
            component,
            "c.updateMaterialDetails",
            function(response) {
                if(response != null && response != undefined) {
                    component.set("v.materialsList",response);
                    component.set("v.isAlertError", false);
                    //component.set("v.showButton", false);
                }
                else {
                    component.set("v.alertMessage", $A.get("$Label.c.CLIFv20231"));
                    component.set("v.isAlertError", true);
                }
            },
            {
                "requestId" : component.get("v.recordId"),
                "materialList" : component.get("v.materialsList")
            },
            false
        );
    }
})