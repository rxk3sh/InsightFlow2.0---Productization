({
    /*Method to create fields in Edit Mode*/
    createInputField: function(component) {
        var field = component.get("v.field");
        var type = field.Type.toLowerCase();
        var helpText = "";
        var hasHelpText = false;
        var options = [];
        var lookupFields = $A.get("$Label.c.CLIFv20068");
        var lookupFieldList = lookupFields.split(",");
        if(lookupFieldList.indexOf(field.APIName) >= 0 || (field.LookupObject !== undefined && field.LookupObject !== '')) {
            type="reference";
        }
        
        if(field.HelpText !== undefined) {
            if(field.HelpText !== null && field.HelpText !== "") {
                helpText = field.HelpText
                hasHelpText = true;
            }
        }
        
        if(type !== "reference") {
            if(type === "multipicklist") {
                if(field.pickListValues !== undefined) {
                    var pickListValues = field.pickListValues;
                    for(var i=0;i<pickListValues.length;i=i+1) {
                        options.push({
                            "label" : pickListValues[i],
                            "value" : pickListValues[i]
                        });
                    }
                }
            } else if(type === "picklist") {
                if(field.pickListValues !== undefined) {
                    options = field.pickListValues;
                }
            } else if(type === "string") {
                type = "text";
            }
            
            $A.createComponent(
                "c:IFv2_InputField", 
                {
                    "field" : field,
                    "controllingFieldVal" : component.getReference("v.record."+field.ControllerField),
                    "label" : field.Label,
                    "value" : component.getReference("v.record." + field.APIName),
                    "type" : type,
                    "picklistvalues" : options,
                    "hasHelpText" : hasHelpText,
                    "helpText" : helpText,
                    "required" : field.Required,
                    "workflow" : component.get("v.record.Workflow__c")
                },
                function(cmp, status) {
                    if (status === "SUCCESS") {
                        component.set("v.isEditBody", true);
                        component.set("v.editBody", cmp);
                    } else {
                        console.error("ERROR: Input Component error");
                    }
                });
        } else {
            var objectName;
            if(field.LookupObject !== undefined) {
                if(field.LookupObject) {
                    objectName = field.LookupObject;
                } else {
                    objectName = "User";
                }
            } else {
                objectName = "User";
            }
            var filter;
            var isCreateable = false;
            var recordType;
            if(objectName ==="User") {
                component.set("v.filter" , " isActive = TRUE");
                component.set("v.subTitle","Department");
            } else if(objectName === "Account") {
                isCreateable = field.isCreateable;
                if(field.APIName === "SupplierCustomerNo__c" && component.get("v.record.Workflow__c") === $A.get("$Label.c.CLIFv20052")){ //Special Freights
                    var transportType = component.get("v.record.TransportationType__c");
                    
                    if(transportType === "Inbound") {
                        component.set("v.recordType",$A.get("$Label.c.CLIFv20077"));//Supplier RecordType
                        component.set("v.subTitle","IFv2_Details__c");
                        component.set("v.filter","recordTypeId = '"+$A.get("$Label.c.CLIFv20077")+"'");
                        component.set("v.disabled",false);
                    } else if(transportType === "Outbound") {
                        component.set("v.recordType",$A.get("$Label.c.CLIFv20076"));//Customer RecordType
                        component.set("v.subTitle","IFv2_Details__c");
                        component.set("v.filter","recordTypeId = '"+$A.get("$Label.c.CLIFv20076")+"'");
                        component.set("v.disabled",false);
                    } else {
                        component.set("v.recordType",undefined);
                        component.set("v.subTitle",undefined);
                        component.set("v.filter",undefined);
                        component.set("v.disabled",true);
                    }
                } else if(component.get("v.record.Workflow__c") === $A.get("$Label.c.CLIFv20199") && field.APIName === "SupplierCustomerNo__c"){
                    component.set("v.recordType",$A.get("$Label.c.CLIFv20077"));//Supplier RecordType
                    component.set("v.filter","recordTypeId = '"+$A.get("$Label.c.CLIFv20077")+"'");
                }
            } else if(objectName === "Contact") {
                component.set("v.subTitle","IFv2_ContactDetail__c");
            }
            
            if(field.APIName === "SupplierName__c") {
                component.set("v.recordType",$A.get("$Label.c.CLIFv20077"));//Supplier RecordType
                component.set("v.filter","recordTypeId = '"+$A.get("$Label.c.CLIFv20077")+"'");
            }
            
            if(field.LookupFilter !== undefined && field.LookupFilter !== '') {
                var filter = component.get("v.filter");
                if(filter !== undefined && filter !== '') {
                    filter += " AND (" + field.LookupFilter + ")";
                }else {
                    filter = field.LookupFilter;
                }
                component.set("v.filter",filter);
            }
            
            $A.createComponent(
                "c:IFv2_LookupComponent",
                {
                    "label" : field.Label,
                    "object" : objectName,
                    "searchField" : "Name",
                    "iconName" : "standard:user",
                    "helpText" : helpText,
                    "required" : field.Required,
                    "readOnly" : false,
                    "filter"	:component.getReference("v.filter"),
                    "allowNewRecords":isCreateable,
                    "subtitleField":component.getReference("v.subTitle"),
                    "recordType":component.getReference("v.recordType"),
                    "value" : component.getReference("v.record." + field.APIName),
                    "disabled" : component.getReference("v.disabled")
                },
                function(cmp, status) {
                    if (status === "SUCCESS") {
                        component.set("v.isEditBody", true);
                        component.set("v.editBody", cmp);
                    } else {
                        console.error("ERROR: Input Reference Component error");
                    }
                });
        } 
    },
    
    /* Create Fields in View mode*/
    createOutputField: function(component) {
        var field = component.get("v.field");
        var type = field.Type.toLowerCase();
        var helpText = "";
        var hasHelpText = false;
        var lookupFields = $A.get("$Label.c.CLIFv20068");//list of text fields that should be shown as lookup
        var lookupFieldList = lookupFields.split(",");
        if(lookupFieldList.indexOf(field.APIName) >= 0 || (field.LookupObject !== undefined && field.LookupObject !== '')) {
            type="reference";
        }
        
        if(field.HelpText !== undefined) {
            if(field.HelpText !== null && field.HelpText !== "") {
                helpText = field.HelpText
                hasHelpText = true;
            }
        }
        
        var isReference = component.get("v.isReference");
        if(isReference) {
            type = "reference";
        }
        
        var record = component.get("v.record");
        var requestStatus = component.get("v.requestStatus");
        var editable = false;
        var userId = component.get("v.currentUser");
        var isApplicant = (userId === component.get("v.record.CreatedById"));
        
        if(record !== null) {
            var editableField = !component.get("v.readOnlySection") && !field.ReadOnly && isApplicant;
            if(field.APIName.toLowerCase().indexOf("role") >= 0){
                editableField = false;
            }
            if((record.Status__c === "Draft" || requestStatus === "Draft") && editableField) {
                editable = true;
            }
            if(type === "reference") {
                var objectName;
                if(field.LookupObject !== undefined) {
                    if(field.LookupObject) {
                        objectName = field.LookupObject;
                    } else {
                        objectName = "User";
                    }
                } else {
                    objectName = "User";
                }
            }
            var date;
            if(field.APIName === "CreatedById") {
                date = component.get("v.record.CreatedDate");
            } else if(field.APIName === "LastModifiedById") {
                date = component.get("v.record.LastModifiedDate");
            }
            
            date = $A.localizationService.formatDate(date, "DD-MM-YYYY hh:mm a");
            
            $A.createComponent(
                "c:IFv2_OutputField", 
                {
                    "type" : type,
                    "label" : field.Label,
                    "value" : component.getReference("v.record." + field.APIName),
                    "name"	: field.DisplayLabel,
                    "hasHelpText" : hasHelpText,
                    "helpText" : helpText,
                    "isEditable" : editable,
                    "isEditableInit" : editableField,
                    "createdDate" : component.get("v.record.CreatedDate"),
                    "modifiedDate" : component.getReference("v.record.LastModifiedDate"),
                    "requestStatus": component.getReference("v.record.Status__c"),
                    "objectName" : objectName,
                    "recordId" : component.get("v.record.Id"),
                    "fieldName" : component.get("v.field.APIName"),
                    "workflow" : component.get("v.record.Workflow__c")
                },
                function(cmp, status) {
                    if (status === "SUCCESS") {
                        component.set("v.isEditBody", false);
                        component.set("v.readOnlyBody", cmp);
                    } else {
                        console.error("ERROR: Output Component error");
                    }
                });
        }
    },
    
    /* Toggle view and edit mode */
    toggleView : function(component) {
        var self = this;
        component.set("v.editBody", []);
        component.set("v.readOnlyBody", []);
        var field = component.get("v.field");
        
        if(component.get("v.viewPage") && !field.ReadOnly) {
            //Changed to make role fields readonly only for request (01-03-2019)
            if(component.get("v.readOnlySection") || (field.APIName.toLowerCase().indexOf("role")>=0 && component.get("v.sObjectName") === "IFv2_Request__c")) {
                self.createOutputField(component);
            } else {
                self.createInputField(component);
            }
        } else {
            self.createOutputField(component);
        }
    },
    
    /* Generic call to server */
    callToServer : function(component, method, callback, params, storable) {
        var action = component.get(method);
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
    }
})