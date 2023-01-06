({
    /** Prepare the data on page load **/
    doInit : function(component, event, helper) {
        helper.getRelatedListData(component);
    },
    
    /** Navigates to the standard detail page on click of view All or Related List Name link**/
    handleOnclick : function(component, event, helper) {
        
        var recordid = component.get("v.recordId");
        helper.displayModal(component);
    },
    
    /**Navigates to the respective record on click**/
    handleRowAction : function(component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        helper.navigateToRelatedRecord(component,event,helper,row);
    },
    
    /* trigger sorting function */
    handleColumnSorting: function (component, event, helper) {
        var fieldName = event.getParam("fieldName");
        var sortDirection = event.getParam("sortDirection");
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    },
    
    /* function to close the modal */
    closeModal: function(component, event, helper) {
        // for closing Modal,set the "isOpen" attribute to "false"  
        component.set("v.isOpen", false);
    },
})