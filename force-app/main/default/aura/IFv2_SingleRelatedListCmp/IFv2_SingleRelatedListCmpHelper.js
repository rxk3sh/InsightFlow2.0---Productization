({
    /* Call to server */
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
                component.set("v.isAlert", false);
                callback.call(this, response.getReturnValue());
            } else if(state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.alertMessage", $A.get("$Label.c.CLIFv20032") + " " + errors[0].message);
                        component.set("v.isRequiredEmpty", true);
                    }
                }
            } else {
                component.set("v.alertMessage", $A.get("$Label.c.CLIFv20057"));
                component.set("v.isRequiredEmpty", true);
            }
        });
        $A.enqueueAction(action);
    },
    
    /* helper method to save new record */
    saveRecord : function(component, event, queryFields) {
        
        var record = component.get("v.record");
        var sectionMetadata = component.get("v.fields");
        var isEdit = 'false';
        if(record['Id'] !== undefined) {
            isEdit = 'true';
        }
        var requiredFields = [];
        for(var i=0; i<sectionMetadata.length; i++) {
            if(sectionMetadata[i].Required){
                requiredFields.push(sectionMetadata[i].APIName); 
            }
        }
        component.set("v.isRequiredEmpty", false);
        for(var i=0; i<requiredFields.length; i++) {
            if(record[requiredFields[i]] === undefined || 
               record[requiredFields[i]] === null ||
               record[requiredFields[i]].length === 0 ||
               record[requiredFields[i]] === " ") {
                component.set("v.isRequiredEmpty", true);
            }
        }
        var self = this;
        if(!component.get("v.isRequiredEmpty")){
            /* Fetch the records */
            self.callToServer(
                component,
                "c.createRecord", /* server method */
                function(response){
                    var wrapperResponse = response;
                    
                    component.set("v.isOpen", false);
                    component.set("v.isEditMode", false);
                    var refreshEvent = $A.get("e.c:IFv2_RefreshRelatedListEvent");
                    refreshEvent.setParams({
                        "relatedRecords":wrapperResponse.Record,
                        "userNames" : wrapperResponse.userName,
                        "relatedListType" : component.get("v.relatedListType"),
                        "workflowName" : component.get("v.requestRecord.Workflow__c"),
                        "forNotesAndAttachments": false,
                        "mappingFromRelatedList": true
                    });
                    var editEvent = $A.get("e.c:IFv2_EditButtonHandleEvent");
                    editEvent.setParams({
                        "isEdit":false
                    });
                    var toastEvent = $A.get("e.force:showToast");
                    if(isEdit === 'false') {
                        toastEvent.setParams({
                            message : $A.get("$Label.c.CLIFv20185"),
                            duration:' 3000',
                            type: 'success',
                            mode: 'dismissible'
                        });
                    } else {
                        toastEvent.setParams({
                            message : $A.get("$Label.c.CLIFv20186"),
                            duration:' 3000',
                            type: 'success',
                            mode: 'dismissible'
                        });
                    }
                    refreshEvent.fire();
                    editEvent.fire();
                    toastEvent.fire();
                    
                },
                {
                    "recordId": component.get("v.entityId"),
                    "recordType": component.get("v.relatedListType"),
                    "record": component.get("v.record"),
                    "requestRecord": component.get("v.requestRecord"),
                    "queryFields" : queryFields
                },
                false
            );
        }
        else {
            component.set("v.alertMessage", "Please fill all mandatory fields");
            component.set("v.AllRecordList", component.get("v.BackupRecordList"));
            component.set("v.isEditMode", true);
        }
    },
    
    /* helper method to execute Edit action on record */
    editRecord : function(component, event, row) {
        component.set("v.isViewAll", false);
        component.set("v.record",row);
        component.set("v.isOpen",true);
        component.set("v.isEditMode", true);
        component.set("v.isRequiredEmpty", false);
        var editEvent = $A.get("e.c:IFv2_EditButtonHandleEvent");
        editEvent.setParams({
            "isEdit":false
        });
        editEvent.fire();
    },
    
    /* helper method to execute Delete action on record */
    deleteRec : function(component, event, queryFields) {
        var self = this;
        var recordId = component.get("v.recordToBeDeleted")
        /* Fetch the records */
        self.callToServer(
            component,
            "c.deleteRecord", /* server method */
            function(response){
                var wrapperResponse = response;
                component.set("v.isDelete", false);
                var deletedRecord = response;
                var updatedRecordsList = [];
                updatedRecordsList = component.get("v.AllRecordList");
                var refreshEvent = $A.get("e.c:IFv2_RefreshRelatedListEvent");
                refreshEvent.setParams({
                    "relatedRecords":wrapperResponse.Record,
                    "userNames" : wrapperResponse.userName,
                    "relatedListType" : component.get("v.relatedListType"),
                    "forNotesAndAttachments":false
                });
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    message : $A.get("$Label.c.CLIFv20187"),
                    duration:' 3000',
                    type: 'success',
                    mode: 'dismissible'
                });
                
                refreshEvent.fire();
                toastEvent.fire();
                
                
            },
            {
                //params
                "accountRecordId": recordId,
                "requestRecordId": component.get("v.entityId"),
                "queryFields" : queryFields,
                "recordType": component.get("v.relatedListType"),
            },
            false
        );
    },
    
    /* helper method to save new record */
    viewRecord : function(component, row) {
        component.set("v.isViewAll", false);
        component.set("v.record",row);
        component.set("v.isOpen",true);
        component.set("v.isRequiredEmpty", false);
    },
    
    /* updates table on creation, updation or deletion of records */
    updateTable : function (component, relatedRecords, userNames) {
        var wrapper = component.get("v.wrapper");
        var sectionMetadata = wrapper.section;
        var records = relatedRecords;
        var fields = wrapper.fields;
        var requestRecord = wrapper.requestRecord;
        var userNames = userNames;
        
        
        /* Table actions */
        var editActions = [
            { label: "View", name: "View" },
            { label: "Edit", name: "Edit" },
            { label: "Delete", name: "Delete" }
        ]
        
        var viewActions = [
            { label: "View", name: "View" }
        ]
        
        //component.set("v.AllRecordList", records);
        
        /* preprocessing to fetch the names of contact */
        /* Creating a virtual map for id and name */
        var tableMap = {};
        function addToMap(key, value) {
            tableMap[key] = value;
        }
        
        if(userNames !== undefined && userNames.length != null && userNames.length>0){
            for(var i=0; i<userNames.length; i++) {
                addToMap(userNames[i].Id, userNames[i].Name);   
            }
        }
        var newRecordList = [];
        /* HotFix Bug number W-010304 START */
        var miniRecordList = [];
        /* HotFix Bug number W-010304 END */
        for(var i=0; i<records.length; i++) {
            var record = {};
            record = records[i];
            
            if(tableMap[records[i].IFv2_PersonnelNo__c] != null && 
               tableMap[records[i].IFv2_PersonnelNo__c] != '') {
                record.personnelName =  tableMap[records[i].IFv2_PersonnelNo__c];
                record.IFv2PersonnelNo = '/'+ record.IFv2_PersonnelNo__c;
            } else {
                record.personnelName = null;
                record.IFv2PersonnelNo = '';
            }
            if(tableMap[records[i].IFv2_LegacyActualApprover__c] != null && 
               tableMap[records[i].IFv2_LegacyActualApprover__c] != '') {
                record.legacyActualApprover =  tableMap[records[i].IFv2_LegacyActualApprover__c];
                record.IFv2LegacyActualApprover = '/'+ record.IFv2_LegacyActualApprover__c;
            } else {
                record.legacyActualApprover = null;
                record.IFv2LegacyActualApprover = '';
            } 
            if(tableMap[records[i].IFv2_Legacysubmitter__c] != null && 
               tableMap[records[i].IFv2_Legacysubmitter__c] != '') {
                record.legacySubmitter =  tableMap[records[i].IFv2_Legacysubmitter__c];
                record.IFv2Legacysubmitter = '/'+ record.IFv2_Legacysubmitter__c;
            } else {
                record.legacySubmitter = null;
                record.IFv2Legacysubmitter = '';
            } 
            if(tableMap[records[i].IFv2_Legacy_Assigned_To__c] != null && 
               tableMap[records[i].IFv2_Legacy_Assigned_To__c] != '') {
                record.legacyAssignedTo =  tableMap[records[i].IFv2_LegacyAssignedTo__c];
                record.IFv2LegacyAssignedTo = '/'+ record.IFv2_LegacyAssignedTo__c;
            } else {
                record.legacyAssignedTo = null;
                record.IFv2LegacyAssignedTo = '';
            }
            if(tableMap[records[i].IFv2_EmployeeUser__c] != null && 
               tableMap[records[i].IFv2_EmployeeUser__c] != '') {
                record.employeeUser =  tableMap[records[i].IFv2_EmployeeUser__c];
                record.IFv2EmployeeUser = '/'+ record.IFv2_EmployeeUser__c;
            } else {
                record.employeeUser = null;
                record.IFv2EmployeeUser = '';
            }
            newRecordList.push(record);
            /* Added this for hot fix, for displaying only 5 records on detail page,  for bug number W-010304 */
            if(i<5) {
                miniRecordList.push(record);
            }
        }
        
        /* pushing values to the data table */
        var columns = [];
        
        var length = 0;
        if(fields.length >3) {
            length = 3;
        } else {
            length = fields.length;
        }
        
        /* display only first three columns from the fieldset in the data table */
        for(var i=0; i<length; i++) {
            
            if(fields[i].Type !== "REFERENCE" 
               && fields[i].Type !== "DATETIME"
               && fields[i].Type !== "DOUBLE"
               && fields[i].APIName !== "IFv2_LegacyActualApprover__c"
               && fields[i].APIName !== "IFv2_LegacyAssignedTo__c"
               && fields[i].APIName !== "IFv2_Legacysubmitter__c") {
                columns.push({
                    label: fields[i].Label,
                    fieldName: fields[i].APIName,
                    type: fields[i].Type
                });  
            } else if(fields[i].Type === "REFERENCE") {
                columns.push({
                    label: fields[i].Label, 
                    type: "url", 
                    fieldName: "IFv2PersonnelNo",
                    typeAttributes: { label: { fieldName: "personnelName"},
                                     tooltip: " ",
                                     target: "_self" },                        
                });
            } else if(fields[i].Type === "DATETIME") {
                columns.push({
                    label: fields[i].Label,
                    fieldName: fields[i].APIName,
                    type: "date",
                    typeAttributes: {
                        year: 'numeric',
                        month: '2-digit',
                        day: '2-digit',
                        hour: '2-digit',
                        minute: '2-digit'
                    },
                }); 
            } else if(fields[i].Type === "DOUBLE") {
                columns.push({
                    label: fields[i].Label,
                    fieldName: fields[i].APIName,
                    type: "number"
                }); 
            } else if(fields[i].APIName === "IFv2_LegacyActualApprover__c") {
                columns.push({
                    label: fields[i].Label, 
                    type: "url", 
                    fieldName: "IFv2LegacyActualApprover",
                    typeAttributes: { label: { fieldName: "legacyActualApprover"},
                                     tooltip: " ",
                                     target: "_self" },                        
                });
            } else if(fields[i].APIName === "IFv2_LegacyAssignedTo__c") {
                columns.push({
                    label: fields[i].Label, 
                    type: "url", 
                    fieldName: "IFv2LegacyAssignedTo",
                    typeAttributes: { label: { fieldName: "legacyAssignedTo"},
                                     tooltip: " ",
                                     target: "_self" },                        
                });
            } else if(fields[i].APIName === "IFv2_Legacysubmitter__c") {
                columns.push({
                    label: fields[i].Label, 
                    type: "url", 
                    fieldName: "IFv2Legacysubmitter",
                    typeAttributes: { label: { fieldName: "legacySubmitter"},
                                     tooltip: " ",
                                     target: "_self" },                        
                });
            } else if(fields[i].APIName === "IFv2_EmployeeUser__c") {
                columns.push({
                    label: fields[i].Label, 
                    type: "url", 
                    fieldName: "IFv2EmployeeUser",
                    typeAttributes: { label: { fieldName: "employeeUser"},
                                     tooltip: " ",
                                     target: "_self" },                        
                });
            }
        }
        
        /* Allow Edit and Delete actions when Request in Draft status */
        if(component.get("v.requestStatus") === "Draft") {
            component.set("v.isDraft", true);
            columns.push({
                type: "action", typeAttributes: { rowActions: editActions }
            })
        } else {
            component.set("v.isDraft", false);
            columns.push({
                type: "action", typeAttributes: { rowActions: viewActions }
            })
        }
        
        /* When no records in the list */
        if(records.length>0){
            component.set("v.isEmpty", false);
        } else {
            component.set("v.isEmpty", true);
            component.set("v.alertMessage", "No records to display");
        }
        
        component.set("v.relatedListLabel", sectionMetadata.Name__c);
        component.set("v.relatedListType", sectionMetadata.RelatedListType__c);
        component.set("v.headerIcon", sectionMetadata.ExtendedValue__c);
        /* HotFix Bug number W-010304 START */
        component.set("v.AllRecordList", miniRecordList);
        component.set("v.BackupRecordList", newRecordList);
        component.set("v.modalRecordList", newRecordList);
        /* HotFix Bug number W-010304 END */
        component.set("v.columnLabels", columns);
        component.set("v.fields", fields);
        component.set("v.sectionList", sectionMetadata);
        component.set("v.requestRecord", requestRecord);
        /* Added for hot fix,  bug number W-010304 START*/
        component.set("v.modalRecordListCount", records.length);
        if(records.length>5) {
            component.set("v.relatedListCount", '5+');
        } else {
            component.set("v.relatedListCount", records.length);
        }
        /* Added for hot fix bug number W-010304 END*/
    }
    
})