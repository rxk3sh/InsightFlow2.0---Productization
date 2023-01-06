({
    /** This calls verifySubmit function in helper  **/
    verifySubmit : function(component, event, helper) {
        var eventParam = event.getParam("recordId");
        component.set("v.approverSectionMetadata",event.getParam("approverSectionMetadata"));
        if(component.get("v.Request.Id") === eventParam && event.getParam("CheckNow") === false) {
            helper.checkRequiredFields(component);
        } else if(event.getParam("CheckNow") === true) {
             helper.CheckNowValidations(component,event);
        }
    }
})