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
                        component.set("v.alertMessage", $A.get("$Label.c.CLIFv20032") + " " + errors[0].message);
                        component.set("v.isAlert", true);
                    }
                }
            } else {
                component.set("v.alertMessage", $A.get("$Label.c.CLIFv20057"));
                component.set("v.isAlert", true);
            }
        });
        $A.enqueueAction(action);
    },
    
    /* display workflow method called on page load */ 
    displayWorkflows: function(component, event, helper, row) {
        /* inline actions in the data table*/
        var tableActionsForAdmin = [
            { label: "View", name: "View" },
            { label: "Edit", name: "Edit"}
        ]
        
        //system admin profiles mentioned in the custom label
        var systemAdminProfiles = $A.get("$Label.c.CLIFv20162");
        
        var self = this;
        /* Fetch the Workflow records */
        self.callToServer(
            component,
            "c.fetchWorkflows", /* server method to fetch the Workflow custom settings */
            function(response) {
                var wrapperList = response;
                var userProfile = wrapperList.userProfileName;    
                
                var labels = $A.get("$Label.c.CLIFv20036");
                var labelList = labels.split(',');
                
                var apiNames = wrapperList.apiNames;
                var apiList = apiNames.substring(1, apiNames.length).split(',');
                
                var types = wrapperList.fieldsType;
                var typeList = types.substring(1, types.length).split(',');
                
                var columns = [];
                
                /* to push column labels into data table */
                var settings = wrapperList.settings;
                
                /* fetching user data */
                var userName = [];
                if(wrapperList.userName !== undefined) {
                    userName = wrapperList.userName;
                }
                
                /* Creating a virtual map for expert id and name */
                var tableMap = {};
                function addToMap(key, value) {
                    tableMap[key] = value;
                }
                
                if(userName !== undefined && userName.length != null && userName.length) {
                    for(var i=0; i<userName.length; i++) {
                        addToMap(userName[i].Id, userName[i].Name);   
                    }
                }
                
                /* updated list with user(expert and process owner) names */
                var records = [];
                var iteration = settings.length;
                for(var i=0; i<iteration; i++) {
                    var record = {};
                    record = settings[i];
                    
                    if(settings[i].LocalExpert__c !== undefined) {
                        if(tableMap[settings[i].LocalExpert__c] !== null && 
                           tableMap[settings[i].LocalExpert__c] !== '') {
                            record.expertName =  tableMap[settings[i].LocalExpert__c];
                        } else {
                            record.expertName = null;
                        }
                    }
                    
                    /* checking for the null conditions for ProcessOwner and LocalExpert */
                    if(settings[i].ProcessOwner__c !== undefined) {
                        if(tableMap[settings[i].ProcessOwner__c] !== null && 
                           tableMap[settings[i].ProcessOwner__c] !== '') {
                            record.processOwnerName = tableMap[settings[i].ProcessOwner__c];
                        } else {
                            record.processOwnerName = null;
                        }
                    }
                    
                    records.push(record);
                    
                    if(records[i].LocalExpert__c !== undefined 
                       && records[i].LocalExpert__c !== null 
                       && records[i].LocalExpert__c !== '') {
                        records[i].LocalExpert__c = '/'+ records[i].LocalExpert__c;
                    } else {
                        records[i].LocalExpert__c = '';
                    }
                    
                    if(records[i].ProcessOwner__c !== undefined 
                       && records[i].ProcessOwner__c !== null 
                       && records[i].ProcessOwner__c !== '') {
                        records[i].ProcessOwner__c = '/'+ records[i].ProcessOwner__c;
                    } else {
                        records[i].ProcessOwner__c = null;
                    }
                } 
                
                /* pushing values into data table */
                /* push extra column 'Name' for the System Admin */
                if(systemAdminProfiles.includes(userProfile)) {
                    columns.push({
                        label: 'Name',
                        fieldName: 'Name',
                        sortable: true,
                    }); 
                }
                
                /* columns to be displayed for standard user */ 
                for(var i=0; i<labelList.length; i++) {
                    /* change type from 'DOUBLE' to 'number' for the datatable to handle */
                    if(typeList[i] === "DOUBLE") {
                        typeList[i] = "number"
                    }
                    
                    /* pushing all columns except process owner and local expert 
                    to change their type to url */
                    if(labelList[i] !== "Process Owner" && labelList[i] !== "Local Expert") {
                        if(labelList[i] === "Workflow"){
                            columns.push({
                                label: labelList[i],
                                fieldName: apiList[i],
                                type: typeList[i],
                                sortable: true,
                                initialWidth: 280,
                                cellAttributes: { alignment: 'left' }
                            });
                        }
                        else{
                            columns.push({
                                label: labelList[i],
                                fieldName: apiList[i],
                                type: typeList[i],
                                sortable: true,
                                cellAttributes: { alignment: 'left' }
                            });
                        }
                    }
                    
                    /* Making Process Owner and Local Expert fields of type url */
                    else if(labelList[i] === "Process Owner") {
                        columns.push({
                            label: "Process Owner", type: "url", fieldName: apiList[i],
                            typeAttributes: { label: { fieldName: "processOwnerName"},
                                             tooltip: " ",
                                             target: "_self" }, 
                            sortable: true,                       
                        });
                    } else if(labelList[i] === "Local Expert") {
                        columns.push({
                            label: "Key User", type: "url", fieldName: apiList[i],
                            typeAttributes: { label: { fieldName: "expertName"},
                                             tooltip: " ",
                                             target:"_self"},
                            title: "expertName",
                            sortable: true,                       
                        });
                    } 
                }
                
                /* Push Execute option in the last column manually */
                columns.push({
                    type: "button-icon",
                    label: "Execute",
                    typeAttributes: {
                        iconName: "utility:play",
                        name: "Execute", 
                        title: "Execute Workflow",
                        alternativeText: "Click to Execute Workflow",
                        class: "execute-icon" 
                    },
                    cellAttributes: { class: { fieldName: 'Workflow__c' } }
                });  
                
                /* Pushing Row Actions: View and Edit only for the System Admin*/
                if(systemAdminProfiles.includes(userProfile)){  
                    columns.push({
                        type: "action", typeAttributes: { rowActions: tableActionsForAdmin }
                    });
                    columns.push({});
                    component.set("v.isSystemAdmin", true);
                }
                
                /* for setting labels to the columns */
                component.set("v.columnLabels", columns);
                
                if(records.length > 0 && records !== undefined && records !== null) {
                    
                    /* setting data for the data table */
                    component.set("v.filteredData",records);
                    /* backup of all the data, to be used during search functions */
                    component.set("v.AllRecordList",records);
                    
                    /* sorting the data table by Workflow Name initially */
                    this.sortData(component, component.get("v.sortedBy"), component.get("v.sortedDirection"));
                } 
                /* display message when table is empty */
                else {
                    component.set("v.isEmpty", true);
                    component.set("v.emptyMessage", $A.get("$Label.c.CLIFv20182"));
                }
                
                /* storing logged In user's profile */
                component.set("v.userProfile",userProfile);
            },
            {
                /* params */
                "sObjectName" : component.get("v.sObjectName")
            },
            true
        );
    },    
    
    /* triggers this logic to handle sorting */
    sortData: function (component, fieldName, sortDirection) {
        var data = component.get("v.filteredData");
        var reverse = sortDirection !== "asc";
        if(data !== undefined && data !== null) {
            data.sort(this.sortBy(fieldName, reverse))
        }
        
        if(data.length < 9) {
            $A.util.addClass(component.find("datatable-id"), "custom-hide-scroll");
        } else {
            $A.util.removeClass(component.find("datatable-id"), "custom-hide-scroll");
        }
        component.set("v.filteredData", data);
    },
    
    /* column to sort by logic (case-insensitive) */
    sortBy: function(field, reverse, primer) {
        if(field === "ProcessOwner__c") {
            field = "processOwnerName";
        } else if(field === "LocalExpert__c") {
            field = "expertName";
        }
        var key = primer ?
            function(x) {
                return primer(x.hasOwnProperty(field) ? 
                              (typeof x[field] === 'string' ? 
                               x[field].toLowerCase() 
                               : x[field]) 
                              : 'aaa')} 
        : function(x) {
            return x.hasOwnProperty(field) ? 
                (typeof x[field] === 'string' ? 
                 x[field].toLowerCase() 
                 : x[field]) 
            : 'aaa'};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    
    /* search function based on the number of characters entered*/
    searchByText: function(component, event) {
        var self = this;
        var searchKey = event.getParam("searchKey");
        var AllRecordList = component.get("v.AllRecordList");
        var searchList = [];
        
        /* if search string cleared to null return all records */
        if(searchKey.length === 0 && AllRecordList !== undefined && AllRecordList !== null) {
            component.set("v.filteredData", AllRecordList);
            self.sortData(component, component.get("v.sortedBy"), component.get("v.sortedDirection"));
        }
        
        /* if search string has 3 or more characters, start the search */
        else if(searchKey.length >= 3 && AllRecordList !== undefined && AllRecordList !== null) {
            for(var i=0; i<AllRecordList.length; i++) {
                var tempRecord = AllRecordList[i];
                for(var j in tempRecord) {
                    if(tempRecord[j] !== null && tempRecord[j] !== undefined 
                       && JSON.stringify(tempRecord[j]).toLowerCase().indexOf(searchKey.toLowerCase()) > -1) {
                        if(!searchList.includes(AllRecordList[i])) {
                            searchList.push(AllRecordList[i]);
                        }
                    }
                }
            }
            component.set("v.filteredData", searchList);
            self.sortData(component, component.get("v.sortedBy"), component.get("v.sortedDirection"));
        }
    },
    
    /* trigger this on click of execute icon to create request of the executed workflow */
    executeWorkflow: function(component, action, event, workflowId, workflowRecords) {
        var self = this;
        self.callToServer(
            component,
            "c.createRequestRecord", /* server method in IFv2_WorkflowListviewController*/
            function(response){
                if(response !== undefined && response.Id !== undefined){
                    var recordId = response.Id;
                    var recordName = response.Name;
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "message" : "Request \""+recordName+"\" was created",
                        "title" : "Success!",
                        "type" : "success"
                    });
                    toastEvent.fire();
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": recordId,
                        "slideDevName": "details"
                    });
                    navEvt.fire();
                }
            },
            {
                /* params */
                "workflow" : workflowRecords
            },
            false
        );
    },
    
    /* triggers this on click of View or Edit action on the workflow listview page */
    goToWorkflowDetails: function (component, action, event, workflowId, workflowName,buttonType) {
        var event = $A.get("e.force:navigateToComponent");
        event.setParams({
            componentDef : "c:IFv2_WorkflowDetailCmp",
            componentAttributes: {
                "recordId" : workflowId,
                "workFlowName" : workflowName,
                "sObjectName" : component.get("v.sObjectName"),
                "recordType" : 'Custom Setting',
                "actionType" : action.name,
                "newButton"  : buttonType
            }
        });
        event.fire();
    }
})