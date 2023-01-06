({
    /** Generic method which handles the server calls **/
    callToServer :function(component,method,callback,params) {
        component.set("v.showSpinner", true);
        var action=component.get(method);
        action.setStorable();
        if(params) {
            action.setParams(params); //getting the parameters
        }
        action.setCallback(this,function(responsethis) {
            //handling the response
            component.set("v.showSpinner", false);
            var state = responsethis.getState();
            if(state === "SUCCESS") {
                callback.call(this, responsethis.getReturnValue());
            } else if(state === "ERROR") {
                var errors = responsethis.getError();
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
    
    /** Gets the request details based on the status **/
    requestDataHelper : function(component) {
        var self = this;
        self.callToServer(
            component,
            "c.getRequestDetails",    /* server method */
            function(response) {
                var requestArr = [];
                component.set("v.limitAll",component.get("v.limit"));
                //Iterating over the request and pushing the data based on the status
                for (var key in response ) {
                    requestArr.push({value:response[key], key:key});
                }
                component.set("v.requestData", requestArr); //Setting the request records
                //If the total records exceeds the given limit Show More will be displayed
                if(component.get("v.requestData").length > component.get("v.limit")) {
                    component.set("v.isShowLink", true);
                    component.set("v.showMore", true);
                }
            },
            {
                "strStatus" : component.get("v.status"), //pass parameters
                "sObjectName" : component.get("v.sObjectName")
            }
        );
    },
    
    /** Getting the data for Items to Approve V2**/
    requestItemsToApproveV2: function(component) {
        var self = this;
        self.callToServer(
            component,
            "c.getItemsToApproveVersion2",    /* server method */
            function(response) {
                if(response.length > 0) {
                    var ItemsApprove = [];
                    component.set("v.limitAll", component.get("v.limit"));
                    //Iterating over the request and pushing the data based on the status
                    for (var key in response ) {
                        var ItemsApproveResult = response[key].ProcessInstance.TargetObject;
                        ItemsApprove.push({value:ItemsApproveResult.Name, key:ItemsApproveResult.Id});
                    }
                    component.set("v.requestData", ItemsApprove); //Setting the request data
                    if(component.get("v.sObjectName") === 'WF_Request__c'  && component.get("v.requestData").length> 0)
                        component.set("v.displaymessage",true);
                    
                    //If the total records exceeds the given limit Show More will be displayed
                    if(component.get("v.requestData").length > component.get("v.limit")) {
                        component.set("v.isShowLink", true);
                        component.set("v.showMore", true);
                    }
                }
            },
            {
                "sObjectName" : component.get("v.sObjectName") //Pass Parameters
            }
        );
    },
})