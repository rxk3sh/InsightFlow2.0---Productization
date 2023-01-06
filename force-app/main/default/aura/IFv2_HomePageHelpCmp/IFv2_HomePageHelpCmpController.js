({
    /* Invoking helper method */
    doInit : function(component, event, helper) {
        helper.displayHelpLinks(component);
    },
    
    /* trigger sorting function */
    handleColumnSorting : function (component, event, helper) {
        var fieldName = event.getParam("fieldName");
        var sortDirection = event.getParam("sortDirection");
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    }
})