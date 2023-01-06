({
    searchKeyChange: function(component, event, helper) {
        var queryTerm = component.find("searchBar").get("v.value");
        
        if(queryTerm.length >= 3 || queryTerm.length === 0) {
            var myEvent = $A.get("e.c:IFv2_SearchBarForWorkflowEvent");
            myEvent.setParams({"searchKey": queryTerm});
            myEvent.fire();
        }
    }
})