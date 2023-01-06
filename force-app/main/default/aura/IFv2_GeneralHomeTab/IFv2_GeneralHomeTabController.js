({
    /* Method to handle hover */
    handleHover: function(component) {
        $A.util.addClass(component.find("front-end"), "slds-hide");
        $A.util.removeClass(component.find("back-end"), "slds-hide");
        $A.util.addClass(component.find("front-end-2"), "slds-hide");
        $A.util.removeClass(component.find("back-end-2"), "slds-hide");
        $A.util.addClass(component.find("card-id"), "custom-animation");
        
    },
    
    /* Method to handle back icon icon click */
    goBack: function(component) {
        $A.util.addClass(component.find("back-end"), "slds-hide");
        $A.util.removeClass(component.find("front-end"), "slds-hide");
        $A.util.addClass(component.find("back-end-2"), "slds-hide");
        $A.util.removeClass(component.find("front-end-2"), "slds-hide");
        $A.util.removeClass(component.find("card-id"), "custom-animation");
    },
    goToLink : function (component,event,helper) {
        var link = component.get("v.tab.Link__c");
        window.open(link);
    },
    
    favorite : function(component,event, helper) {
        helper.updateFavoriteTab(component);
    }
})