({
    /* Method to be called on page load */
    doInit : function(component, event, helper) {
        component.set("v.showSpinner", true);
        document.title = "SEG Applications";
        helper.fetchHomeScreenTabs(component);
    },
    /* Method to handle search */
    searchKeyChange : function(component, event, helper) {
        helper.filterTabs(component);
    },
    showAllNonFavorite : function(component, event, helper) {
        var showAll=component.get("v.ShowAllNonFavorite");
        var source=event.getSource();
        if(showAll===false)
        {
            component.set("v.ShowAllNonFavorite",true);
            source.set('v.label',$A.get("$Label.c.CLIFv20311"));
        }
        else
        {
            component.set("v.ShowAllNonFavorite",false);
            source.set('v.label',$A.get("$Label.c.CLIFv20310"));
        }
                   
    },
    /* Method to sort apps */
    sortApps : function(component, event, helper) {
        var fieldName = component.get("v.sortedBy");
        var sortDirection = component.get("v.sortedDirection");
        
        helper.sortData(component, fieldName, sortDirection);
        if(sortDirection === 'asc') {
            component.set("v.sortedDirection",'desc');
            
        } else {
            component.set("v.sortedDirection",'asc');
        }
        var buttonstate = component.get('v.toggleButton');
        component.set('v.toggleButton', !buttonstate);
    },
    /* Method to update update favorite apps */
    updateFavorite : function(component, event, helper) {
        //component.set("v.showSpinner", true);
        var index = event.getParam("index");
        var starred = event.getParam("starred");
        var listType = event.getParam("ListType");
        /* Adding to favorite list */
        if(starred) {
            var nonFavoriteLIST =[];
            nonFavoriteLIST = component.get("v.tabListnonFavorite");
            var message = nonFavoriteLIST[index];
            var favoriteLIST = [];
            favoriteLIST = component.get("v.tabList");
            message.Starred__c = true;
            favoriteLIST.push(message);
            component.set("v.tabList", favoriteLIST);
            var fieldName = component.get("v.sortedBy");
            component.set("v.tabListnonFavorite",nonFavoriteLIST);
        } else if(listType === 'nonFavoriteList') {
            var nonFavoriteLIST =[];
            nonFavoriteLIST = component.get("v.tabListnonFavorite");
            var message = nonFavoriteLIST[index];
            var favoriteLIST = [];
            favoriteLIST = component.get("v.tabList");
            var appIndex;
            for(var i=0;i<favoriteLIST.length;i++) {
                if(favoriteLIST[i].Name__c === message.Name__c) {
                   appIndex = i;
                }
            }
            favoriteLIST.splice(appIndex,1);
            message.Starred__c = false;
            component.set("v.tabList", favoriteLIST);
            var fieldName = component.get("v.sortedBy");
            component.set("v.tabListnonFavorite",nonFavoriteLIST);
            
        } else {
            /* Adding to non favorite list */            
            var favoriteLIST = [];
            favoriteLIST = component.get("v.tabList");
            var message = favoriteLIST[index];
            favoriteLIST.splice(index,1);
            component.set("v.tabList",favoriteLIST);
            
            /* Updating non favorite list */
            var nonFavoriteLIST =[];
            nonFavoriteLIST = component.get("v.tabListnonFavorite");
            message.Starred__c = false;
            
            for(var i=0;i<nonFavoriteLIST.length;i++) {
                if(nonFavoriteLIST[i].Name__c === message.Name__c) {
                    nonFavoriteLIST[i].Starred__c = false;
                }
            }
            component.set("v.tabListnonFavorite",nonFavoriteLIST);
        }
        
    }
})