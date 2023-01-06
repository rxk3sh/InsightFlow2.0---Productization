({
    /** doInit to display the requests **/
    doInit: function(component, event, helper) {
        if(component.get("v.status") !== "Pending") {
            helper.requestDataHelper(component);
            
        } else {
            helper.requestItemsToApproveV2(component);
        }
    },
    
    /** Shows or hide divs **/
    showMoreDiv: function(component) {
        var limit = component.get("v.requestData").length;
        component.set("v.limit", limit);
        component.set("v.showMore", false);
    },
    
    /** Shows or hide divs **/
    showLessDiv: function (component) {
        component.set("v.limit", component.get("v.limitAll"));
        component.set("v.showMore", true);
    }
})