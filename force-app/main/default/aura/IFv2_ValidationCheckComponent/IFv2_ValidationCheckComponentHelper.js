({
    /**Server Call**/
    callToServer: function(component, method, callback, params) {
        var action = component.get(method);
        //action.setStorable();
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
                        console.log(errors[0].message);
                    }
                }
            } else {
                console.log($A.get("$Label.c.CLIFv20057"));
            }
        });
        $A.enqueueAction(action);
    },
    
    /**************Verify and submit custom button Action**************************/
    /*Checking for page layout level required fields*/
    checkRequiredFields: function(component) {
        var IsRequiredUndefined = false;//This variable is set to true if any required field is empty
        var isRequiredEmpty;
        var metadata = component.get("v.RequiredFieldListWrapper");//Storing the received response from server,this contains field wrapper list of respective request workflow fields
        var RequiredFieldList = component.get("v.RequiredFieldList");//This gets Required field list from parent component ,these required fields will be decided based on data entered by user.. This data will be coming from fired event-->
        var request = component.get("v.Request");//These request record will be coming from fired event 
        
        if(RequiredFieldList === undefined) {
            RequiredFieldList = [];
        }
        component.set("v.alertMessage", []);
        
        for(var i=0;i<metadata.length;i=i+1) {
            var RequiredFieldListWrapper = metadata[i].fields;
            for(var field=0;field<RequiredFieldListWrapper.length;field=field+1) {
                /**Checking for Required Fields-start**/
                /** 1. checks whether a field is required at page layout level  OR
                        2. checks whether a field is required based on data entered by user
                      **/
                if(RequiredFieldListWrapper[field].Required || RequiredFieldList.includes(RequiredFieldListWrapper[field].APIName))
                    //If it is undefined or if it is empty firing a toast message
                    if(!(RequiredFieldListWrapper[field].APIName).includes('.')) {
                        if(request[RequiredFieldListWrapper[field].APIName] === undefined || request[RequiredFieldListWrapper[field].APIName] === "" || request[RequiredFieldListWrapper[field].APIName] === null) {
                            IsRequiredUndefined = true;
                            
                            var message = component.get("v.alertMessage");
                            /* CLIFv20063 = "Please Fill" */
                            var template = $A.get("$Label.c.CLIFv20063");
                            message.push(template +': '+ RequiredFieldListWrapper[field].Label );
                            component.set("v.alertMessage", message);
                            component.set("v.isAlert", true);
                        }
                    } else {
                        var fieldAPI = RequiredFieldListWrapper[field].APIName.split('.');
                        if(fieldAPI.length > 1) {
                            var relObj = fieldAPI[0];
                            var relField = fieldAPI[1];
                            if(request[relObj] === undefined || request[relObj][relField] === undefined || request[relObj][relField] === "" || request[relObj][relField] === null) {
                                IsRequiredUndefined = true;
                                
                                var message = component.get("v.alertMessage");
                                message.push("Please Fill in "+ RequiredFieldListWrapper[field].Label + "! ");
                                component.set("v.alertMessage", message);
                                component.set("v.isAlert", true);
                            }
                        }
                    }
            }
            RequiredFieldListWrapper = [];
            RequiredFieldList = [];
            /**Checking for Required Fields-end**/
        }
        //if there is no error in required fields then firing check validations function
        if(!IsRequiredUndefined) { 
            var self = this;
            self.checkvalidations(component);
        }
        
    },
    
    /** This checks validations based on workflow type **/
    checkvalidations: function(component) {
        var self = this;
        self.callToServer(
            component,
            "c.returnValidationErrors",
            function(response) {
                /*The response contains error messages if the record data entered by user does match validations .Iterating over responce and firing toast messages*/
                if(response.length > 0) {
                    var message = component.get("v.alertMessage");
                    for (var i = 0; i < response.length; i++) {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error!",
                            "type" : "warning",
                            "mode" : "dismissible",
                            "message": response[i]
                        });
                        message.push(response[i]);
                        
                    }
                    component.set("v.alertMessage", message);
                    component.set("v.isAlert", true);
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type": "success",
                        "message": $A.get("$Label.c.CLIFv20179")
                    });
                    toastEvent.fire();
                    self.submitForApproval(component);
                    component.set("v.isAlert",false);
                }
            }, 
            {
                "Request": component.get("v.Request"),
                "ApproverSectionMetadata" : component.get("v.approverSectionMetadata")
            });
    },
    
    /**Submits a record for approval if it passes required fields criteria and validations criteria  **/
    submitForApproval:function(component) {
        var self = this;
        self.callToServer(
            component,
            "c.submitForApproval",
            function(response) {
                var refreshEvent = $A.get("e.c:IFv2_Headerevent");
                refreshEvent.setParams({
                    "requestStatus" : "Submitted",
                    "eventFired" : "true" 
                });
                refreshEvent.fire();
            }, 
            {
                "workflowname" : component.get("v.Request")['Workflow__c'],
                "RequestRecord" : component.get("v.Request"),
                "ApproverSectionMetadata" : component.get("v.approverSectionMetadata")
            });
    },
    /* Iteration 3 changes start */
    CheckNowValidations : function(component,event) {
       var message = [];
        var response= [];
        response = event.getParam("ErrorMessage");
        for(var i = 0; i < response.length; i++) {
            
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "type" : "warning",
                "mode" : "dismissible",
                "message": response[i]
            });
            message.push(response[i]);
        }
        component.set("v.alertMessage", message);
        component.set("v.isAlert", true);
        
    }
    /* Iteration 3 changes End */
})