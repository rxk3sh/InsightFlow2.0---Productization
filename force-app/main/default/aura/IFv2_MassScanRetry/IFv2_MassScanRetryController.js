({
    getFailedrecords : function(component, event, helper) {
        var fromdate = component.get("v.fromDate");
        var todate = component.get("v.toDate");
        var action = component.get("c.getFailedRecord");
        if(fromdate == null || todate == null)
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Error',
                message:'please Enter from date and to date value',
                duration:' 5000',
                key: 'info_alt',
                type: 'error',
                mode: 'dismissible'
            });
            toastEvent.fire();
        }
        else
        {component.set("v.Spinner",true);
            action.setParams({
                
                fromdate :fromdate,
                todate :todate
            });
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var count= response.getReturnValue();
                    component.set("v.recordcount",count);
                    component.set("v.Spinner",false);
                    component.set("v.isSuccess",'True');
                } else if(state === "ERROR") {
                    component.set("v.Spinner",false);
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
            
        }
    },
    
    retryFailedrecords : function(component, event, helper) {
        component.set("v.Spinner",true);
        var fromdate = component.get("v.fromDate");
        var todate = component.get("v.toDate");
        var action = component.get("c.reprocessFailedRecord");
        component.set("v.isSuccess",'True');
        action.setParams({
            fromdate :fromdate,
            todate :todate
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var response= response.getReturnValue();
                component.set("v.resultResponse",response);
                component.set("v.Spinner",false);
            } else if(state === "ERROR") {
                component.set("v.Spinner",false);
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
        
        
    }
})