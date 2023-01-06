({  
    gotoList : function (component) {
        var urlEvent = $A.get("e.force:navigateToURL"); 
        urlEvent.setParams({ 
            "url": "/lightning/o/IFv2_Request__c/home"  // Navigation "address" 
        }); 
        urlEvent.fire();
        
    }
})