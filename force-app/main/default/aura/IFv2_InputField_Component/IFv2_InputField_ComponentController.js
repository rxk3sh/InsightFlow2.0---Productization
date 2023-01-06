({
    /*Initialize Component*/
    doInit : function(component, event, helper) {
        helper.toggleView(component);
    },
    handleChangeTransportType : function(component, event) {
        var field = component.get("v.field");
        var changedField = event.getParam("field");
        var objectName = component.get("v.field.LookupObject");
        if(changedField === "TransportationType__c" && field.APIName === "SupplierCustomerNo__c" && objectName === "Account" && component.get("v.record.Workflow__c") === $A.get("$Label.c.CLIFv20052")){
            var transportType = event.getParam("value");
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
        }
    }
})