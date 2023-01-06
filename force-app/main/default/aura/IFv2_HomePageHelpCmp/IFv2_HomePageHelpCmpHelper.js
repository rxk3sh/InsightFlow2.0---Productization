({
    /* Generic call to server */
    callToServer: function(component, method, callback, params) {
        component.set("v.showSpinner", true);
        var action = component.get(method);
        action.setStorable();
        if(params) {
            action.setParams(params);
        }
        action.setCallback(this, function(response) {
            component.set("v.showSpinner", false);
            var state = response.getState();
            if(state === "SUCCESS") {
                callback.call(this, response.getReturnValue());
            } else if(state === "ERROR") {
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
    },
    
    /**fetches the records from server inserted till date**/
    displayHelpLinks: function(component) {
        var self = this;
        /* Fetch the Help Link records */
        self.callToServer(
            component,
            "c.getHelpURLRecords", /* server method to fetch the help custom setting records */
            function(response) {
                if(response.length > 0) {
                    //setting column labels
                    component.set("v.columnLabels", [
                        {label: "File Name", fieldName: "Name", type: "text", sortable: true},
                        {label: "Description", fieldName: "IFv2_Description__c", type: "text",sortable: true},
                        {label: "Action", fieldName: "IFv2_LinkURL__c", type: "url", typeAttributes: {label: "Click Here", target: "_self"}, sortable: true}
                    ]);
                    component.set("v.allRecordList", response);
                }
                //setting message if there are no records in the responce 
                else {
                    component.set("v.emptyMessage", $A.get("$Label.c.CLIFv20107"));
                    component.set("v.isEmpty", true);
                }
            });
    },
    
    /* triggers this logic to handle sorting */
    sortData: function (component, fieldName, sortDirection) {
        var data = component.get("v.allRecordList");
        var reverse = sortDirection !== "asc";
        if(data !== undefined && data !== null) {
            data.sort(this.sortBy(fieldName, reverse))
        }
        component.set("v.allRecordList", data);
    },
    
    /* column to sort by logic (case-insensitive) */
    sortBy: function (field, reverse, primer) {
        //using standard salesforce documented logic
        var key = primer ?
            function(x) {return primer(x.hasOwnProperty(field) ? 
                                       (typeof x[field] === 'string' ? x[field].toLowerCase() : x[field]) : 'aaa')} :
        function(x) {return x.hasOwnProperty(field) ? 
            (typeof x[field] === 'string' ? x[field].toLowerCase() : x[field]) : 'aaa'};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {            
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    }
})