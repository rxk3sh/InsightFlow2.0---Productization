({
    /** Loads the data on page load **/
    doInit : function(component, event, helper) {
        helper.requestDetails(component, event);
    },
    
    /** Getting the Requests based on the status**/
    RequestStatus : function(component, event, helper) {
        helper.requestStatusData(component, event, '');
    },
    
    /* trigger sorting function */
    handleColumnSorting: function (component, event, helper) {
        var fieldName = event.getParam("fieldName");
        var sortDirection = event.getParam("sortDirection");
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    }
})