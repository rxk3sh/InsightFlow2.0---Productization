({
    /** Calls the server method for Approve data**/
    ApproveRequestHelper : function(component, event, helper) {
        var comments = component.get("v.comments");
        var recordId= component.get("v.recordId");
        var self = this;
        self.callToServer(
            component,
            "c.approveMethod", //calling server method
            function(response) {
                if(response == true){
                    var compEvent = component.getEvent("toastEvent");
                    var refreshEvent = $A.get("e.c:IFv2_Headerevent");
                    refreshEvent.setParams({
                        "requestStatus" : "Approved",
                        "eventFired" : "true" 
                    });
                    compEvent.setParams({
                        "message" : $A.get("$Label.c.CLIFv20175"),
                        "type" : "success"
                    });
                    compEvent.fire();
                    refreshEvent.fire();
                }
                else if(response === false) {
                    var compEvent = component.getEvent("toastEvent");
                    compEvent.setParams({
                        "message" : $A.get("$Label.c.CLIFv20141"),
                        "type" : "error"
                    });
                    compEvent.fire();
                }
                else {
                    var compEvent = component.getEvent("toastEvent");
                    compEvent.setParams({
                        "message" : $A.get("$Label.c.CLIFv20232"),
                        "type" : "error"
                    });
                    compEvent.fire();
                }
            }, {
                "recId": component.get("v.recordId"), //Pass params
                "strComments" : comments,
                "ApproverSectionMetadata" : component.get("v.approverSectionMetadata")
            });
    },
    
    /** Calls the server method for Rejected data**/
    RejectRequestHelper :  function(component, method, callback, params) {
        console.log('reject modal helper');
        var self = this;
        self.callToServer(
            component,
            "c.rejectMethod", //call to server
            function(response) {
                if(response == true){
                    var compEvent = component.getEvent("toastEvent");
                    var refreshEvent = $A.get("e.c:IFv2_Headerevent");
                    refreshEvent.setParams({
                        "requestStatus" : "Rejected",
                        "eventFired" : "true" 
                    });
                    compEvent.setParams({
                        "message" : $A.get("$Label.c.CLIFv20176"),
                        "type" : "success"
                    });
                    compEvent.fire();
                    refreshEvent.fire();
                }
                else {
                    var compEvent = component.getEvent("toastEvent");
                    compEvent.setParams({
                        "message" : $A.get("$Label.c.CLIFv20141"),
                        "type" : "error"
                    });
                    compEvent.fire();
                }
            }, 
            {
                "recId": component.get("v.recordId"), //Pass params
                "strComments" :component.get("v.comments")
                
            });
    },
    
    /** Reassigns the request record **/
    ReassignRequestHelper : function(component, event, helper) {
        console.log('Reassign---');
        var self = this;
        self.callToServer(
            component,
            "c.reassignMethod",
            function(response) {
                if(response == true){
                    console.log('response-----');
                    var compEvent = component.getEvent("toastEvent");
                    var refreshEvent = $A.get("e.c:IFv2_Headerevent");
                    compEvent.setParams({
                        "message" : $A.get("$Label.c.CLIFv20177"),
                        "type" : "success"
                    });
                    compEvent.fire();
                    refreshEvent.fire();
                }
                else {
                    var compEvent = component.getEvent("toastEvent");
                    compEvent.setParams({
                        "message" : $A.get("$Label.c.CLIFv20141"),
                        "type" : "error"
                    });
                    compEvent.fire();
                }
            },
            {
                "recId": component.get("v.recordId"), //Pass params
                "strComments" :component.get("v.comments"),
                "newApproverId" : component.get("v.selectedId")
            });
    },
    
    ConsultRequestHelper : function(component, event, helper) {
        
        var checkNowAppEvent = $A.get("e.c:IFv2_ShowSpinner");
        checkNowAppEvent.setParams({
            "showSpinner" : true,
        });
        checkNowAppEvent.fire();
        
        var self = this;
        self.callToServer(
            component,
            "c.consultMethod",
            function(response) {
                
                var checkNowAppEvent = $A.get("e.c:IFv2_ShowSpinner");
                checkNowAppEvent.setParams({
                    "showSpinner" : false,
                });
                checkNowAppEvent.fire();
            
                if(response == true){  
                    var compEvent = component.getEvent("toastEvent");
                    compEvent.setParams({
                        "message" : $A.get("$Label.c.CLIFv20178"),
                        "type" : "success"
                    });
                    compEvent.fire();
                }
                else {
                    var compEvent = component.getEvent("toastEvent");
                    compEvent.setParams({
                        "message" : $A.get("$Label.c.CLIFv20141"),
                        "type" : "error"
                    });
                    compEvent.fire();
                }
            },
            {
                "recId": component.get("v.recordId"), //Pass params
                "strComments" :component.get("v.comments"),
                "chatterUserId" : component.get("v.selectedId")
            });
    },
    
    /** Generic method to call server **/
    callToServer: function(component, method, callback, params) {
        var action = component.get(method);
        if (params) {
            action.setParams(params); //pass params
        }
         action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                callback.call(this, response.getReturnValue());
            } else if(state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error!", //Passing parameters for toast messages
                            "type": "error",
                            "message": $A.get("$Label.c.CLIFv20032") + errors[0].message
                        });
                        toastEvent.fire();
                    }
                } 
            }else {
                var compEvent = component.getEvent("alertEvent");
                compEvent.setParams({
                    "alertMessage" : $A.get("$Label.c.CLIFv20057"),
                    "isError" : true
                });
                compEvent.fire();
            }
        });
        $A.enqueueAction(action);
    }
})