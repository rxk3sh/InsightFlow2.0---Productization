({
    doInit : function(component, event, helper) {
        helper.getMaterials(component);
    },
    
    /** Closes the modal **/
    updateMaterial : function(component, event, helper) {
        helper.updateReturnedMaterial(component);
        component.set("v.showButton", false);
        component.set("v.role",'');
    },
    
    setRole : function(component, event, helper) {
        if(event !== undefined && event.getParam("isPrivilegedApprover") !== undefined && event.getParam("approverRole") !== undefined){
            component.set("v.role",event.getParam("approverRole"));
            if((event.getParam("approverRole") == "LOG1" && component.get("v.isParent"))){
                component.set("v.showButton", true);
            }
            if(!component.get("v.isParent"))
            {
                component.set("v.showButton", true);
            }
        }
    }
})