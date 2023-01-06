({
    /* On Load action */
    onInit : function(component, event, helper) {
        var type = component.get("v.type");
        /* when data type is reference */
        if(type === "reference") {
            helper.getRecordByValue(component);
                        
        } else if(type === "url") {
            /* when data type is url */
            if(component.get("v.name") === undefined || component.get("v.name") === null){
                component.set("v.name", component.get("v.value"));
            }
        }
    },
    
    /* Changing from View form to Edit form */
    editMode : function(component, event, helper) {
        if(component.get("v.isEditable")){
            var cmpEvent = component.getEvent("cmpEvent");
            cmpEvent.setParams({
                "editMode": true
            });
            cmpEvent.fire();
            
            var editEvent = $A.get("e.c:IFv2_EditButtonHandleEvent");
            editEvent.setParams({
                "isEdit" : true
            });
            editEvent.fire();
        }
    },
    /*handle status change*/
    statusChange : function(component,event,helper){
        //alert(component.get("v.requestStatus"));
        if(component.get("v.requestStatus")!=='Draft'){
            component.set("v.isEditable",false)
        }
        else{
            component.set("v.isEditable",component.get("v.isEditableInit"));
        }
    } 
})