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
    
    /**fetches the records from server inserted till date**/
    displayP28Logs: function(component, method, callback, params) {
        component.set("v.isEmpty", false);
        component.set("v.noMoreRecords", true);
        
        /* for display of number of records based on picklist */
        var pageSize = component.find("pageSize").get("v.value");
        component.set("v.pageSize", pageSize);
        
        var length;
        if(component.get("v.allRecordList") === undefined || component.get("v.allRecordList") === null) {
            length = 0;
        } else {
            length = component.get("v.allRecordList").length;
        }
        
        var self = this;
        /* Fetch the Workflow records */
        self.callToServer(
            component,
            "c.getp28Logs", /* server method to fetch the admin only records */
            function(response) {
                var records = []; 
                if(response !== null) {
                    /* setting column labels */
                    component.set("v.columnLabels", [
                        {label: "File Name", fieldName: "fileName", type: "text"},
                        {label: "Description", fieldName: "description", type: "text"},
                        {label: "Created Date", fieldName: "createdDate", type: "Date"},
                        {label: "Status", fieldName: "status", type: "text", 
                         cellAttributes: { iconName: 
                                          { fieldName: "statusname" }, 
                                          iconLabel: { fieldName: "statuslabel" }, 
                                          iconPosition: "right" }
                        },
                        {label:"Download", type: "button", 
                         typeAttributes: {
                             iconName: "action:download",
                             label: "",
                             name: "download",
                             title: "download",
                             disabled: {fieldName: "disablevalue"},
                             value: "test",
                             variant: {fieldName: "variantValue"},
                             class: "download-icon"
                         }}
                    ]);
                    
                    /** iterating over the responce from server and assigning the values to lightning data table **/
                    for(var i=0; i<response.length; i++) {
                        var record = {};
                        record.createdDate = $A.localizationService.formatDate( response[i].createddate, "dd-MM-yyyy, hh:mm:ss a");
                        record.disablevalue = false;
                        /* assigning lightning icons to display status */
                        if(response[i].status === "Success")
                            record.statusname = "action:approval";
                        if(response[i].status === "Fail")
                            record.statusname = "action:close";
                        if(response[i].status === "Pending") {
                            record.statusname = "action:more";
                            record.disablevalue = true;
                        }
                        record.description = response[i].description;
                        
                        record.fileName = response[i].filename;
                        /* contains the contentversion id of success file */
                        record.successfile = response[i].successfile;
                        /* contains the contentversion id of failure file */
                        record.failurefile = response[i].failurefile;
                        records.push(record);
                    }
                }
                
                if(records.length < 9) {
                    $A.util.addClass(component.find("datatable-id"), "custom-hide-scroll");
                } else {
                    $A.util.removeClass(component.find("datatable-id"), "custom-hide-scroll");
                }
                component.set("v.totalSize", records.length);       
                component.set("v.filteredData", records);
                component.set("v.allRecordList", records);
            },
            {
                pageSize : component.get("v.pageSize"),
                offset : component.get("v.start")
            },
            true
        );
    },
    
    /** downloads file to local system **/
    downloadfiletoLocalsystem: function(component, record) {
        /* 1. Contains two events */
        /* 2. first one is for downlaoding success file */
        /* 3. second event is for downlaoding error file only if it is present */
        if(record.successfile!=undefined) {
            var viewRecordEvent = $A.get("e.force:navigateToURL");
            viewRecordEvent.setParams({
                "url": "/" + record.successfile
            });
            viewRecordEvent.fire(); 
        }
        if(record.failurefile !== undefined) {
            var viewRecordEvent = $A.get("e.force:navigateToURL");
            viewRecordEvent.setParams({
                "url": "/" + record.failurefile
            });
            viewRecordEvent.fire();
        }
    },
    
    /* search function based on the number of characters entered*/
    searchByText: function(component, event) {
        var searchKey = component.find("searchBar").get("v.value");
        var AllRecordList = component.get("v.allRecordList");
        var searchList = [];
        /* if search string cleared to null return all records */
        if(searchKey.length === 0 && AllRecordList !== undefined && AllRecordList !== null) {
            component.set("v.filteredData", AllRecordList);
        }
        
        /* if search string has 3 or more characters, start the search */
        else if(searchKey.length >= 3 && AllRecordList !== undefined && AllRecordList !== null) {
            for(var i=0; i<AllRecordList.length; i++) {
                var tempRecord = AllRecordList[i];
                for(var j in tempRecord) {
                    if(j === "fileName" || j === "description") {
                        if(tempRecord[j] !== null && tempRecord[j] !== undefined && tempRecord[j].toLowerCase().indexOf(searchKey.toLowerCase()) > -1) {
                            if(!searchList.includes(AllRecordList[i])) {
                                searchList.push(AllRecordList[i]);
                            }
                        }
                    }
                }
            }
            component.set("v.filteredData", searchList);
        }
        
        var records = component.get("v.filteredData");
        if(records.length < 9) {
            $A.util.addClass(component.find("datatable-id"), "custom-hide-scroll");
        } else {
            $A.util.removeClass(component.find("datatable-id"), "custom-hide-scroll");
        }
    }
})