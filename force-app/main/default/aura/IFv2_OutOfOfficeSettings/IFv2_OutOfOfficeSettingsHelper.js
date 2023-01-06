({
    /* Generic call to server */
    callToServer: function(component, method, callback, params, storable) {
        component.set("v.showSpinner", true);
        var action = component.get(method);
        if(storable) {
            action.setStorable();
        }
        if(params) {
            action.setParams(params);
        }
        action.setCallback(this, function(response) {
            component.set("v.showSpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
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
    
    setColumns: function(component) {
        var columns = [
            {label: $A.get("$Label.c.CLIFv20108"), fieldName: "Name", sortable: true, type: "text"},
            {label: $A.get("$Label.c.CLIFv20112"), fieldName: "userId", sortable: true, type: "url", typeAttributes: {label: { fieldName: "UserName" }, target: "_self"}},
            {label:"Delete", type: "button", typeAttributes: {iconName: "utility:delete", name: "deleteRecord", title: "Delete", disabled : component.get("v.disableDelete")}}];
        component.set("v.columns", columns);
    },
    
    
    loadDetails : function(component) {
        var self = this;
        /* Fetch the Request records */
        self.callToServer(
            component,
            "c.getOutOfOfficeData", /* server method to fetch the Request details */
            function(response) {
                component.set("v.OutOfOfficeWF", response.lstOutOfOfficeSettings);
                var options = [];
                if(component.get("v.OutOfOfficeWF").length > 0) {
                    for(var i=0; i<component.get("v.OutOfOfficeWF").length; i=i+1) {
                        options.push({ value: component.get("v.OutOfOfficeWF")[i], label: component.get("v.OutOfOfficeWF")[i] });
                    }
                    component.set("v.WorkflowOptions", options);
                }
                if(response.status !== undefined) {
                    component.set("v.enableOutOfOffice", response.status);
                }
                if(response.lstOutOfOfficeUsers.length > 0) {
                    component.set("v.UserDetails" , response.lstOutOfOfficeUsers);
                    self.displayOutOfOfficeRecords(component);
                }
            });
    },
    
    displayOutOfOfficeRecords : function(component) {
        var records = [];
        var miniRecords = [];
        var recordDetails = component.get("v.UserDetails")
        for(var i=0; i<recordDetails.length; i=i+1) {
            var record = {};
            var data = recordDetails[i];
            if(data !== undefined) {
                if(data.WorkflowName__c !== undefined) {
                    record.Name = data.WorkflowName__c;
                }
                if(data.Id !== undefined) {
                    record.Id = data.Id;
                }
                if(data.User__c !== undefined) {
                    record.userId = "/" + data.User__c;
                }
                if(data.User__r.Name !== undefined) {
                    record.UserName = data.User__r.Name;
                }
                if(data.Active__c !== undefined) {
                    record.Active = data.Active__c;
                }
                records.push(record);
                if(i < 3) {
                    miniRecords.push(record);
                }
            }
        }
        
        component.set("v.UserDetails", records);
        component.set("v.UserDetailsMini", miniRecords);
        /* sorting the data table by Name initially */
        this.sortData(component, component.get("v.sortedBy"),component.get("v.sortedDirection"));
    },
    
    /**OutofOffice functionality on Save **/
    saveOutOfOfficeHlpr : function(component) {
        var self = this;
        component.set("v.isAlert", false);
        self.callToServer(
            component,
            "c.saveOutOfOfficeSettings", /* server method to Save */
            function(response) {
                if(response === null || response === undefined) {
                    component.set("v.alertMessage", "Error message: Record Already Exists");
                    component.set("v.isAlert", true);
                } else {
                    component.set("v.UserDetails" , response);
                    component.set("v.selectedId", "");
                    component.set("v.selectedWF", null);
                    self.displayOutOfOfficeRecords(component);
                    
                    //making to reload the data if record is saved successfully
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": $A.get("$Label.c.CLIFv20129"),
                        "type": "success",
                        "message": "Record Created successfully."
                    });
                    resultsToast.fire();
                }
            },
            {
                "enable" : component.get("v.enableOutOfOffice"), //pass parameters
                "strWorkflow" : component.get("v.selectedWF"),
                "objUserId" : component.get("v.selectedId"),
                "recId" : component.get("v.recordId")
            }  
        );
    },
    
    /**BacktoOffice functionality on delete **/
    DisableOutOfOfficeHlpr : function(component, record) {
        component.set("v.isAlert", false);
        var self = this;
        self.callToServer(
            component,
            "c.DisableOutOfOfficeSettings", /* server method to Save */
            function(response) {
                var records = component.get("v.UserDetails");
                var updatedList = [];
                var miniRecords = [];
                for(var i=0;i<records.length;i=i+1) {
                    if(records[i] === record) {

                    } else {
                        if(i < 4) {
                            miniRecords.push(records[i]);
                        }
                        updatedList.push(records[i]);
                    }
                }
                component.set("v.UserDetails", updatedList);
                component.set("v.UserDetailsMini", miniRecords);
                
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": $A.get("$Label.c.CLIFv20129"),
                    "type": "success",
                    "message": "Record Deleted successfully."
                });
                resultsToast.fire();
            },          
            {
                "DisableOutOfOffice" : JSON.stringify(record)
            }
        );
    },
    
    /* triggers this logic to handle sorting */
    sortData : function (component, fieldName, sortDirection) {
        var data = component.get("v.UserDetailsMini");
        var data2 = component.get("v.UserDetails");
        var reverse = sortDirection !== "asc";
        if(data !== undefined && data !== null) {
            data.sort(this.sortBy(fieldName, reverse))
        }
        if(data2 !== undefined && data2 !== null) {
            data2.sort(this.sortBy(fieldName, reverse))
        }
        component.set("v.UserDetails", data2);
        component.set("v.UserDetailsMini", data);
    },
    
    /* column to sort by logic (case-insensitive) */
    sortBy : function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x.hasOwnProperty(field) ? 
                                       (typeof x[field] === 'string' ? x[field].toLowerCase() : x[field]) : 'aaa')} :
        function(x) {return x.hasOwnProperty(field) ? 
            (typeof x[field] === 'string' ? x[field].toLowerCase() : x[field]) : 'aaa'};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {            
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    
    /* Update all for out of office and back to office records */
    updateAllRecords : function(component) {
        var self = this;
        self.callToServer(
            component,
            "c.UpdateOutOfOfficeBackToOffice", /* Method to update records */
            function(response) {
                if(response === "success") {
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": $A.get("$Label.c.CLIFv20129"),
                        "type": "success",
                        "message": "Record updated successfully"
                    });
                    resultsToast.fire();
                } else {
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": $A.get("$Label.c.CLIFv20129"),
                        "type": "failure",
                        "message": response
                    });
                    resultsToast.fire();
                }
            },
            {
                "updateValue" : component.get("v.enableOutOfOffice")
            }
        );
    }
})