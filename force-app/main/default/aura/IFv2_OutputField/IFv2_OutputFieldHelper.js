({
    /* Generic call to server */
    callToServer : function(component, method, callback, params, storable) {
        var action = component.get(method);
        action.setBackground(true);
        if(storable) {
            action.setStorable();
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
                        console.error("Error message: " + errors[0].message);
                    }
                }
            } else {
                console.error("ERROR: Unknown Error");
            }
        });
        $A.enqueueAction(action);
    },
    
    /* Get Reference Name, parameter passed is Reference Id */
    getRecordByValue: function(component, event, helper) {
        var self = this;
        var value = component.get("v.value");
        var recordIds=[];
        var createdDate = component.get("v.createdDate");
        var modifiedDate=component.get("v.modifiedDate");
        var date;
        var label=component.get("v.label");
        if(label === "Created By"){
            date = createdDate;
        }
        else if(label === "Last Modified By"){
            date = modifiedDate;
        }
        recordIds.push(value);
        self.callToServer(
            component,
            "c.getRecordName",
            function(response) {
                if(response !== undefined && response !== null) {
                    //  var date = response["dateVal"];
                    if(response[0]!==undefined){
                        var searchField = component.get("v.searchField");
                       
                        date = $A.localizationService.formatDate(date, "DD.MM.YYYY hh:mm a");
                        if(date!==undefined && date!==null && date!=="Invalid Date"){
                            
                            component.set("v.name", response[0][searchField]+", "+date);
                        }
                        else{
                            component.set("v.name", response[0][searchField]);
                        }
                    } 
                }else {
                    component.set("v.name", "");
                }
            },
            {
                recordIds: recordIds,
                objectName: component.get("v.objectName"),
                searchField: component.get("v.searchField")
            },
            false
        );
    }
})