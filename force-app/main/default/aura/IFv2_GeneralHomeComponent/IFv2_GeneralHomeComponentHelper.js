({
    /* Generic method to call the server */
    callToServer : function(component, method, callback, params, storable) {
        var action = component.get(method);
        if(storable) {
            action.setStorable(true);
        }
        if(params) {
            action.setParams(params);
        }
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                callback.call(this, response.getReturnValue());
            } else if(state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.alertMessage", $A.get("$Label.c.CLIFv20032") + " " + errors[0].message);
                        component.set("v.isAlertError", true);
                    }
                }
            } else {
                component.set("v.alertMessage", $A.get("$Label.c.CLIFv20057"));
                component.set("v.isAlertError", true);
            }
        });
        $A.enqueueAction(action);
    },
    /* Fetching apps infomation from apex */
    fetchHomeScreenTabs : function(component){
        
        this.callToServer(
            component,
            "c.getHomeScreenTabs",
            function(response){
                
                var allRecords = response;
                var favoriteLIST = [];
                var nonFavoriteLIST = [];
                for(var i=0;i<allRecords.length;i++) {
                    /* To add favorites to a list*/
                    if(allRecords[i].Starred__c){
                        favoriteLIST.push(allRecords[i]);
                    } 
                    /* To add all apps to a list */
                    nonFavoriteLIST.push(allRecords[i]);
                }
                component.set("v.tabList",favoriteLIST);
                component.set("v.tabListnonFavorite",nonFavoriteLIST);
                component.set("v.searchTabsFavorite",favoriteLIST);
                component.set("v.searchTabsNonFavorite",nonFavoriteLIST);
                component.set("v.showSpinner", false);
            },
            {},
            true);
        
    },
    
    /* triggers this logic to handle sorting */
    sortData: function (component, fieldName, sortDirection) {
        var data = component.get("v.tabList");
        var dataNonFavorite = component.get("v.tabListnonFavorite");
        var reverse = sortDirection !== "asc";
        
        if(data !== undefined && data !== null) {
            data.sort(this.sortBy(fieldName, reverse))
        }
        if(dataNonFavorite !== undefined && dataNonFavorite !== null) {
            dataNonFavorite.sort(this.sortBy(fieldName, reverse))
        }
        component.set("v.tabList", data);
        component.set("v.tabListnonFavorite", dataNonFavorite);
        
    },
    /* column to sort by logic (case-insensitive) */
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x.hasOwnProperty(field) ? 
                                       (typeof x[field] === 'string' ? x[field].toLowerCase() : x[field]) : 'aaa')} :
        function(x) {return x.hasOwnProperty(field) ? 
            (typeof x[field] === 'string' ? x[field].toLowerCase() : x[field]) : 'aaa'};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {            
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    /* Filtering apps */
    filterTabs:function(component){
        // Searching favorite tabs
        var MainTabs=component.get("v.searchTabsFavorite");
        var searchKey=component.get("v.searchkey").toUpperCase();
        var searchResult=[];
        if(searchKey !== undefined && MainTabs !== undefined)
        {
            for(let i=0;i<MainTabs.length;i++)
            {
                if(MainTabs[i].Name__c === undefined )
                {
                    MainTabs[i].Name__c = '';
                } else if( MainTabs[i].AppOldName__c === undefined) {
                      MainTabs[i].AppOldName__c = '';  
                } else if( MainTabs[i].Description__c === undefined ) {
                    MainTabs[i].Description__c= '';
                }
                
                if( MainTabs[i].Name__c.toUpperCase().includes(searchKey)|| 
                   MainTabs[i].AppOldName__c.toUpperCase().includes(searchKey) ||
                   MainTabs[i].Description__c.toUpperCase().includes(searchKey)
                  )
                {
                    searchResult.push(MainTabs[i]);
                }
            }
            component.set("v.tabList",searchResult);
        }
        else
        {
            component.set("v.tabList",MainTabs);
        }
        
        // Searching non favorite tabs
        var MainTabsTwo=component.get("v.searchTabsNonFavorite");
        var searchKey=component.get("v.searchkey").toUpperCase();
        var searchResultTwo=[];
        if(searchKey !== undefined && MainTabsTwo !== undefined)
        {
            for(let i=0;i<MainTabsTwo.length;i++)
            {
                if(MainTabsTwo[i].Name__c === undefined )
                {
                    MainTabsTwo[i].Name__c = '';
                } else if( MainTabsTwo[i].AppOldName__c === undefined) {
                      MainTabsTwo[i].AppOldName__c = '';  
                } else if( MainTabsTwo[i].Description__c === undefined ) {
                    MainTabsTwo[i].Description__c= '';
                }
                if( MainTabsTwo[i].Name__c.toUpperCase().includes(searchKey)|| 
                   MainTabsTwo[i].AppOldName__c.toUpperCase().includes(searchKey) ||
                   MainTabsTwo[i].Description__c.toUpperCase().includes(searchKey)
                  )
                {
                    searchResultTwo.push(MainTabsTwo[i]);
                }
            }
            component.set("v.tabListnonFavorite",searchResultTwo);
        }
        else
        {
            component.set("v.tabListnonFavorite",MainTabsTwo);
        }
    }
})