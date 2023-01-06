({
	doInit : function(component, event, helper) {
		var material = component.get("v.material");
        var displayValue = material[component.get("v.fieldName")];
        component.set("v.displayValue", displayValue);
        var isParent = component.get("v.isParent");
        var fieldName = component.get("v.fieldName");
        var role = component.get("v.role");
        component.set("v.inputField",(isParent && (fieldName == 'IFv2_HSN__c' && role == 'LOG1')) || (!isParent && ( fieldName == 'IFv2_Remark__c' && role == 'PRS' ) ));
        
    },
    handleChange : function(component, event, helper){
        var isParent = component.get("v.isParent");
        var fieldName = component.get("v.fieldName");
        var role = component.get("v.role");
        component.set("v.inputField",(isParent && (fieldName == 'IFv2_HSN__c' && role == 'LOG1')) || (!isParent && ( fieldName == 'IFv2_Remark__c' && role == 'PRS' ) ));
    },
    handleValueChange : function(component,event,helper){
        var material = component.get("v.material");
        var displayValue = component.get("v.displayValue");
        material[component.get("v.fieldName")] =  displayValue;
        component.set("v.material",material);
    }
    
})