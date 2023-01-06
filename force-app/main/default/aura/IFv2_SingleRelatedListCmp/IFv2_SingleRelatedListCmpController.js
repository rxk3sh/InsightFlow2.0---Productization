({
    doInit : function(component, event, helper) {
        var wrapper = component.get("v.wrapper");
        var sectionMetadata = wrapper.section;
        var records = wrapper.Record;
        var fields = wrapper.fields;
        var requestRecord = wrapper.requestRecord;
        component.set("v.requestStatus", requestRecord.Status__c);
        var userNames = wrapper.userName;
        
        
        /* Table actions */
        var editActions = [
            { label: "View", name: "View" },
            { label: "Edit", name: "Edit" },
            { label: "Delete", name: "Delete" }
        ]
        
        var viewActions = [
            { label: "View", name: "View" }
        ]
        
        
        /* preprocessing to fetch the names of contact and users*/
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
         /* Hot fixes for bug number W-010304 START*/
        var miniRecordList = [];
        /* Hot fixes for bug number W-010304 END*/
        
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
            
            if(tableMap[records[i].IFv2_EmployeeUser__c] != null && 
               tableMap[records[i].IFv2_EmployeeUser__c] != '') {
                record.employeeUser =  tableMap[records[i].IFv2_EmployeeUser__c];
                record.IFv2EmployeeUser = '/'+ record.IFv2_EmployeeUser__c;
            } else {
                record.employeeUser = null;
                record.IFv2EmployeeUser = '';
            }
            
            if(tableMap[records[i].CreatedById] != null && 
               tableMap[records[i].CreatedById] != '') {
                record.CreatedByName =  tableMap[records[i].CreatedById];
                record.IFv2CreatedById = '/'+ record.CreatedById;
            } else {
                record.CreatedByName = null;
                record.IFv2CreatedById = '';
            }
            
            if(tableMap[records[i].LastModifiedById] != null && 
               tableMap[records[i].LastModifiedById] != '') {
                record.LastModifiedByName =  tableMap[records[i].LastModifiedById];
                record.IFv2LastModifiedById = '/'+ record.LastModifiedById;
            } else {
                record.LastModifiedByName = null;
                record.IFv2LastModifiedById = '';
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
            
            if(tableMap[records[i].IFv2_LegacyAssignedTo__c] != null && 
               tableMap[records[i].IFv2_LegacyAssignedTo__c] != '') {
                record.legacyAssignedTo =  tableMap[records[i].IFv2_LegacyAssignedTo__c];
                record.IFv2LegacyAssignedTo = '/'+ record.IFv2_LegacyAssignedTo__c;
            } else {
                record.legacyAssignedTo = null;
                record.IFv2LegacyAssignedTo = '';
            }
            
            newRecordList.push(record);
             /* Hot fixes, for bug number W-010304 START*/
            if(i<5) {
                miniRecordList.push(record);
            }
            /* Hot fixes for bug number W-010304  END*/
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
            } else if(fields[i].APIName === "IFv2_PersonnelNo__c") {
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
            } else if(fields[i].APIName === "CreatedById") {
                columns.push({
                    label: fields[i].Label, 
                    type: "url", 
                    fieldName: "IFv2CreatedById",
                    typeAttributes: { label: { fieldName: "CreatedByName"},
                                     tooltip: " ",
                                     target: "_self" },                        
                });
            } else if(fields[i].APIName === "LastModifiedById") {
                columns.push({
                    label: fields[i].Label, 
                    type: "url", 
                    fieldName: "IFv2LastModifiedById",
                    typeAttributes: { label: { fieldName: "LastModifiedByName"},
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
            });
        } else {
            component.set("v.isDraft", false);
            columns.push({
                type: "action", typeAttributes: { rowActions: viewActions }
            });
        }
        
        /* When no records in the list */
        if(records.length>0){
            component.set("v.isEmpty", false);
        } else {
            component.set("v.isEmpty", true);
        }
        component.set("v.relatedListLabel", sectionMetadata.Name__c);
        component.set("v.relatedListType", sectionMetadata.RelatedListType__c);
        component.set("v.headerIcon", sectionMetadata.ExtendedValue__c);
         /* HotFix Bug number W-010304 START */
        component.set("v.AllRecordList", miniRecordList);
        component.set("v.BackupRecordList", newRecordList);
        component.set("v.modalRecordList", newRecordList);
        if(records.length>5) {
            component.set("v.relatedListCount", '5+');
        } else {
            component.set("v.relatedListCount", records.length);
        }
        /* HotFix Bug number W-010304 END */
        
        component.set("v.columnLabels", columns);
        component.set("v.fields", wrapper.fields);
        component.set("v.sectionList", sectionMetadata);
        component.set("v.requestRecord", requestRecord);
    },
    /*=== END of doInit === */
    
    /* triggers on click of New button */
    createNewRecord : function(component, event, helper) {
        component.set("v.record",{sobjectType:component.get("v.sObjectName")});
        component.set("v.isOpen", true);
        component.set("v.isEditMode", true);
        component.set("v.isView", false);
        component.set("v.isEdit", false);
        component.set("v.isNew", true);
    },
    
    /* function to close the modal */
    closeModal : function(component, event, helper) {
        // for closing Modal,set the "isOpen" attribute to "false"  
        component.set("v.isOpen", false);
        component.set("v.isEditMode", false);
        var editEvent = $A.get("e.c:IFv2_EditButtonHandleEvent");
        editEvent.setParams({
            "isEdit":false
        });
        editEvent.fire();
    },
    
    /*Handle Edit button click*/
    editPage : function(component, event, helper) {
        component.set("v.isEditMode", true);
    },
    
    /* triggers on click of save */
    saveEvent : function(component, event, helper) {
        var fields = component.get("v.fields");
        var queryFields="Id";
        for(var i=0; i<fields.length; i++) {
            queryFields = queryFields + ',' + fields[i].APIName;
        }
        helper.saveRecord(component, event, queryFields);
    },
    
    /* Menu button actions in the related list- Edit, Delete, View */
    handleRowAction : function(component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        
        switch (action.name) {
                
                /* onclick of Edit Action */
            case "Edit":
                component.set("v.isView", false);
                component.set("v.isNew", false);
                component.set("v.isEdit", true);
                helper.editRecord(component, event, row);
                break;
                
                /* onclick of Delete Action */    
            case "Delete":
                component.set("v.isViewAll", false);
                component.set("v.isDelete", true);
                component.set("v.recordToBeDeleted", row.Id);
                break;
                
                /* onclick of View Action */
            case "View":
                component.set("v.isNew", false);
                component.set("v.isEdit", false);
                component.set("v.isView", true);
                helper.viewRecord(component, row);
                break;
                
            default:
                break;
        };
    },
    
    /**Action to delete the record **/
    confirmDelete : function(component, event, helper) {
        var fields = component.get("v.fields");
        var queryFields="Id";
        for(var i=0; i<fields.length; i++) {
            queryFields = queryFields + ',' + fields[i].APIName;
        }
        helper.deleteRec(component, event, queryFields);
    },
    
    /* function to close the modal */
    closeModal: function(component, event, helper) {
        // for closing Modal,set the "isOpen" attribute to "false"  
        component.set("v.isOpen", false);
        component.set("v.isDelete", false);
        component.set("v.isViewAll", false);
        component.set("v.isEditMode", false);
        component.set("v.isRequiredEmpty", false);
        var editEvent = $A.get("e.c:IFv2_EditButtonHandleEvent");
        editEvent.setParams({
            "isEdit":false
        });
        editEvent.fire();
    },
    
    /* triggers on click of View All to open complete related list in a modal*/
    handleViewAll: function(component, event, helper) {
        
        /* for opening Related list in Modal,set the "isViewAll" attribute to "true"  */
        component.set("v.isViewAll", true);
        
        /* For edit,delete and view actions in the modal data table */
        var editActions = [
            { label: "View", name: "View" },
            { label: "Edit", name: "Edit" },
            { label: "Delete", name: "Delete" }
        ]
        
        var viewActions = [
            { label: "View", name: "View" }
        ]
        
        var wrapper = component.get("v.wrapper");
        var sectionMetadata = wrapper.section;
         /* HotFix Bug number W-010304 START */
        var records =  component.get("v.modalRecordList");
        /* HotFix Bug number W-010304 END */
        var requestStatus = component.get("v.requestStatus");
        var fields = wrapper.fields;
        var requestRecord = wrapper.requestRecord;
        /* creating of the data table */
        var columns = [];
        for(var i=0; i<fields.length; i++) {
            
            if(fields[i].Type !== "REFERENCE" 
               && fields[i].Type !== "DATETIME" 
               && fields[i].APIName !== "IFv2_LegacyActualApprover__c"
               && fields[i].APIName !== "IFv2_LegacyAssignedTo__c"
               && fields[i].APIName !== "IFv2_Legacysubmitter__c"
               && fields[i].Type !== "DOUBLE") {
                columns.push({
                    label: fields[i].Label,
                    fieldName: fields[i].APIName,
                    type: fields[i].Type
                });  
            } else if(fields[i].APIName === "IFv2_PersonnelNo__c") {
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
            } else if(fields[i].APIName === "CreatedById") {
                columns.push({
                    label: fields[i].Label, 
                    type: "url", 
                    fieldName: "IFv2CreatedById",
                    typeAttributes: { label: { fieldName: "CreatedByName"},
                                     tooltip: " ",
                                     target: "_self" },                        
                });
            } else if(fields[i].APIName === "LastModifiedById") {
                columns.push({
                    label: fields[i].Label, 
                    type: "url", 
                    fieldName: "IFv2LastModifiedById",
                    typeAttributes: { label: { fieldName: "LastModifiedByName"},
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
        
        component.set("v.relatedListLabel", sectionMetadata.Name__c);
        component.set("v.relatedListType", sectionMetadata.RelatedListType__c);
        component.set("v.headerIcon", sectionMetadata.ExtendedValue__c);
        /* HotFix Bug number W-010304 START */
        component.set("v.modalRecordListCount", records.length);
        /* HotFix Bug number W-010304 END */
        component.set("v.modalRecordList", records);
        component.set("v.modalColumnLabels", columns);
        component.set("v.fields", wrapper.fields);
    },
    
    /* triggers on creation or deletion of a record */
    updateRecords : function(component, event, helper) {
        var relatedRecords = event.getParam("relatedRecords");
        var userNames = event.getParam("userNames");
        var relatedListType =  event.getParam("relatedListType");
        var subWorkflowType =  event.getParam("subWorkflowType");
        var subWorkflowChanged =  event.getParam("subWorkflowChanged");
        component.get("v.subWorkflowChanged", subWorkflowChanged);
        
        if(relatedListType === component.get("v.relatedListType")) {
            helper.updateTable(component, relatedRecords, userNames);
        }
    },
    
    /* triggers when record is submitted or recalled or restarted */
    changeActions : function(component, event, helper) {
        
        var requestStatus = event.getParam("requestStatus");
        var eventFired = event.getParam("eventFired");        
        var wrapper = component.get("v.wrapper");
        var fields = wrapper.fields;
        var requestRecord = wrapper.requestRecord;
        
        if(requestStatus === "Draft" || requestStatus === "Submitted") {
            /* Table actions */
            var editActions = [
                { label: "View", name: "View" },
                { label: "Edit", name: "Edit" },
                { label: "Delete", name: "Delete" }
            ]
            
            var viewActions = [
                { label: "View", name: "View" }
            ]
            
            if(requestStatus !== undefined && requestStatus.length > 0) {
                component.set("v.requestStatus", requestStatus);
            } else {
                component.set("v.requestStatus", requestRecord.Status__c);
                requestStatus = requestRecord.Status__c;
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
                } else if(fields[i].APIName === "IFv2_PersonnelNo__c") {
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
                } else if(fields[i].APIName === "CreatedById") {
                    columns.push({
                        label: fields[i].Label, 
                        type: "url", 
                        fieldName: "IFv2CreatedById",
                        typeAttributes: { label: { fieldName: "CreatedByName"},
                                         tooltip: " ",
                                         target: "_self" },                        
                    });
                } else if(fields[i].APIName === "LastModifiedById") {
                    columns.push({
                        label: fields[i].Label, 
                        type: "url", 
                        fieldName: "IFv2LastModifiedById",
                        typeAttributes: { label: { fieldName: "LastModifiedByName"},
                                         tooltip: " ",
                                         target: "_self" },                        
                    });
                } else if(fields[i].APIName === "IFv2_EmployeeUser__c") {
                    columns.push({
                        label: fields[i].Label, 
                        type: "url", 
                        fieldName: "IFv2_EmployeeUser__c",
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
            
            component.set("v.columnLabels", columns);
        }
    },
})