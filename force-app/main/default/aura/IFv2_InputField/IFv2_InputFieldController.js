({
    doInit: function(component, event, helper) {
        if(component.get("v.type") === "multipicklist") {
            var selectedvalueslist = [];
            var result = component.get("v.value");
            if(result !== undefined) {
                if(result !== null) {
                    var valList = result.split(";");
                    for(var i=0;i<valList.length;i++) {
                        selectedvalueslist.push(valList[i]);
                    }
                    component.set("v.selectedList", selectedvalueslist);
                }
            }
        } else if(component.get("v.type") === "picklist") {
            var field = component.get("v.field");
            if(field.ControllerField!== undefined && field.ControllerField!==''){
                var value = component.get("v.controllingFieldVal");
                var controllerField = field.ControllerField;
                var dependentField = field.APIName;
                helper.getDependentPickListValues(component,value,dependentField,controllerField);
            }
         }
            else if( component.get("v.type")=== "double"){
                var decimalFields = $A.get("$Label.c.CLIFv20013");
                if(decimalFields.split(',').indexOf(component.get("v.field.APIName"))>=0){
                    component.set("v.isDecimal",true);
                }
            }
    },
    
    /*Handle Picklist change*/
    picklistValue: function(component) {
        var evt = $A.get("e.c:IFv2_DependentPicklistChangeEvt");
        evt.setParams({
            "field" : component.get("v.field.APIName"),
            "source" : "field",
            "value" : component.get("v.value")
        });
        evt.fire();
    },
    
    handleDependentValues: function(component, event, helper) {
        var field = component.get("v.field");
             
        var controllerField = field.ControllerField;
        var dependentField = field.APIName;
        var source = event.getParam("source");
        
        if(source === "field" && controllerField !== undefined && dependentField !== undefined) {
            var value = event.getParam("value");
            var fieldAPI = event.getParam("field");
            if(fieldAPI === field.ControllerField) {
                helper.getDependentPickListValues(component,value,dependentField,controllerField);
            }
        }
    },
    
    handleChange: function(component, event) {
        var selectedOptionsList = event.getParam("value");
        component.set("v.value", selectedOptionsList.join(";"));
    }
})