({
    /*Set Fields as required dynamically*/
    setFieldsRequired : function(component,event,helper) {
        var fields = component.get("v.fields");
        var requiredFieldList = []; 
        var oldRequiredFieldList = [];
        if(component.get("v.oldRequiredFieldList")) {
            oldRequiredFieldList = component.get("v.oldRequiredFieldList");
        }
        if(component.get("v.requiredFieldList")) {
            requiredFieldList = component.get("v.requiredFieldList");
        }
        for(var i=0;i<fields.length;i++) {
            if(requiredFieldList.indexOf(fields[i].APIName)!==-1) {
                fields[i].Required = true;
                fields[i].DBRequired = true;
            }
            else if(oldRequiredFieldList.indexOf(fields[i].APIName)!==-1) {
                fields[i].Required = false;
                fields[i].DBRequired = false;
            }
        }
        
        component.set("v.fields", fields);
        component.set("v.oldRequiredFieldList", JSON.parse(JSON.stringify(requiredFieldList)));
    }
})