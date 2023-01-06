({
    /* method called on page load */
    doInit : function(component, event, helper) {
        window.document.title = $A.get("{!$Label.c.CLIFv20028}");
        helper.displayWorkflows(component, event, helper)  
    },
    
    /* trigger sorting function */
    handleColumnSorting: function (component, event, helper) {
        var fieldName = event.getParam("fieldName");
        var sortDirection = event.getParam("sortDirection");
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    },
    
    /* trigger search funtion after entering 3 characters */
    handlesearchKeyChange : function(component, event, helper) {
        helper.searchByText(component,event); 
    },
    
    /* Inline row action handler - Edit,Execute and View in the datatable */
    handleRowAction : function(component, event, helper) {
        var action = event.getParam("action");
        var row = event.getParam("row");
        var workflowName = row.Workflow__c;
        var workflowId = row.Id;
        var workflowRecords = row;
        /* Switch case for the action selected */
        switch (action.name) {
                
                /* onclick of Edit Action */
            case "Edit":
                helper.goToWorkflowDetails(component, action, event, workflowId, workflowName,false);
                break;
                
                /* onclick of Execute Action */
            case "Execute":
                helper.executeWorkflow(component, action, event, workflowId, workflowRecords);
                break;
                
                /* onclick of View Action */
            case "View":
                helper.goToWorkflowDetails(component, action, event, workflowId, workflowName,false);
                break;
                
            default:
                break;
        }
    },
    
    createWorkflow:function(component, event, helper){
        helper.goToWorkflowDetails(component, ' ', event, ' ', ' ', true);
    }
})