({
    handleSectionHeaderClick : function(component, event) {
        var button = event.getSource();
        button.set("v.state", !button.get("v.state"));
        
        var container = component.find("container-id");
        $A.util.toggleClass(container, "slds-is-open");
        component.set("v.stateAll", "changed");
    },
    
    handleChangeStateAll : function(component) {
        var stateAll = component.get("v.stateAll");
        var container = component.find("container-id");
        if(stateAll === "expand") {
            component.set("v.state", false);
            $A.util.addClass(container, "slds-is-open");
        } else if(stateAll === "collapse") {
            $A.util.removeClass(container, "slds-is-open");
            component.set("v.state", true);
        }
    }
})