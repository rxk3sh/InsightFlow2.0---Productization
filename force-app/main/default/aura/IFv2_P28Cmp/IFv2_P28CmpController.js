({
    /* method called on page load */
    doInit: function(component, event, helper) {
        window.document.title = "P28";
        component.find("pageSize").set("v.value", "50");
        helper.displayP28Logs(component, event, helper)  
    },
    
    /* Inline row action handler - downloads file*/
    downloadFile: function(component, event, helper) {
        var action = event.getParam("action");
        
        /* Contains row details of the button clicked */
        var record = event.getParam("row");
        helper.downloadfiletoLocalsystem(component, record);
    },
    
    /* opend modal window which is present in another component IFv2_P28FileUploadCmp */
    createP28: function(component, event, helper) {
        $A.createComponent("c:IFv2_P28FileUploadCmp", {
            "showModal" : true,
        }, function(modalComponent, status, errorMessage) {
            if (status === "SUCCESS") {
                
                /* Appending the newly created component in div */
                var body = component.find( 'showChildModal' ).get("v.body");
                body.push(modalComponent);
                component.find("showChildModal").set("v.body", body);
            } else if (status === "INCOMPLETE") {
                console.log('Server issue or client is offline.');
            } else if (status === "ERROR") {
                console.log('error');
            }
        });
    },
    
    /* trigger search funtion after entering 3 characters */
    handlesearchKeyChange: function(component, event, helper) {
        helper.searchByText(component, event); 
    },
    
    /* Method invoked on click of the next button to view next paginated page */
    next: function(component, event, helper) {
        var start = component.get("v.start");
        start = +start + +component.find("pageSize").get("v.value");
        component.set("v.start", start);
        
        var page = component.get("v.page");
        page = page + 1;
        component.set("v.page", page);
        helper.displayP28Logs(component);
    },
    
    /* Method invoked on click of the previous button to view previous paginated page */
    previous: function(component, event, helper) {
        var start = component.get("v.start");
        var pageSize = component.find("pageSize").get("v.value");
        if(start - pageSize === 0) {
            start = 0;
        } else {
            start = start - pageSize;
        }
        component.set("v.start", start);
        
        var page = component.get("v.page");
        page = page - 1;
        component.set("v.page", page);
        helper.displayP28Logs(component);
    },
    
    first: function(component, event, helper) {
        component.set("v.start", 0);
        component.set("v.page", 1);
        helper.displayP28Logs(component);
    },
    
    onSelectChange: function(component, event, helper) {
        component.set("v.start", 0);
        component.set("v.page", 1);
        helper.displayP28Logs(component);
    }
})