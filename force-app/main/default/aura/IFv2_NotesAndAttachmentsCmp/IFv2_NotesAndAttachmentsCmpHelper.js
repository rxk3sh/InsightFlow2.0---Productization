({
    /* Generic call to server */
    callToServer: function(component, method, callback, params, storable) {
        component.set("v.showSpinner", true);
        var action = component.get(method);
        if (params) {
            action.setParams(params);
        }
        if(storable) {
            //  action.setStorable();
        }
        action.setCallback(this, function(response) {
            component.set("v.showSpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                callback.call(this, response.getReturnValue());
            } else if(state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        /* Iteration 3 change - removed AlertApplication event Start */
                        component.set("v.alertMessage", "Error message: " + errors[0].message);
                        component.set("v.isAlert", true);
                    }
                }
            } else {
                component.set("v.alertMessage", "ERROR: Unknown Error");
                component.set("v.isAlert", true);
            }
            /* Iteration 3 change - removed AlertApplication event END */
        });
        $A.enqueueAction(action);
    },
    
    /** Display all attachments in a modal **/    
    displayModal : function(component) {
        
        // for Display Model,set the "isOpen" attribute to "true"
        component.set("v.isOpen", true);
        
        var recordId = component.get("v.recordId");
        var self = this;
        
        /* Fetch the records */
        self.callToServer(
            component,
            "c.fetchAttachmentList", /* server method */
            function(response) {
                var responseVar = response;
                var allAttachments = responseVar.allAttachments;
                var requestStatus = responseVar.requestRecord;
                
                /* function to convert file size into human readable form */
                function readableBytes(bytes) {
                    var i = Math.floor(Math.log(bytes) / Math.log(1024)),
                        sizes = ['B', 'KB', 'MB'];
                    
                    return (bytes / Math.pow(1024, i)).toFixed(0) * 1 + ' ' + sizes[i];
                }
                
                for(var i=0; i<allAttachments.length; i++) {
                    allAttachments[i].ContentDocument.ContentSize = readableBytes(allAttachments[i].ContentDocument.ContentSize);
                    //allAttachments[i].CreatedDate = allAttachments[i].ContentDocument.CreatedDate;
                    if(allAttachments[i].ContentDocument.FileExtension == "xls" || 
                       allAttachments[i].ContentDocument.FileExtension == "xlsx") {
                        allAttachments[i].attachmentIcon = "doctype:excel";
                    } else if(allAttachments[i].ContentDocument.FileExtension == "doc" || 
                              allAttachments[i].ContentDocument.FileExtension == "docx") {
                        allAttachments[i].attachmentIcon = "doctype:word";
                    } else if(allAttachments[i].ContentDocument.FileExtension == "ppt" || 
                              allAttachments[i].ContentDocument.FileExtension == "pptx") {
                        allAttachments[i].attachmentIcon = "doctype:ppt";
                    } else if(allAttachments[i].ContentDocument.FileExtension == "pdf") {
                        allAttachments[i].attachmentIcon = "doctype:pdf";
                    } else if(allAttachments[i].ContentDocument.FileExtension == "txt") {
                        allAttachments[i].attachmentIcon = "doctype:txt";
                    } else if(allAttachments[i].ContentDocument.FileExtension == "html") {
                        allAttachments[i].attachmentIcon = "doctype:html";
                    } else if(allAttachments[i].ContentDocument.FileExtension == "csv") {
                        allAttachments[i].attachmentIcon = "doctype:csv";
                    } else if(allAttachments[i].ContentDocument.FileExtension == "zip" || 
                              allAttachments[i].ContentDocument.FileExtension == "rar") {
                        allAttachments[i].attachmentIcon = "doctype:zip";
                    } else if(allAttachments[i].ContentDocument.FileExtension == "xml") {
                        allAttachments[i].attachmentIcon = "doctype:xml";
                    } else if(allAttachments[i].ContentDocument.FileExtension == "png" || 
                              allAttachments[i].ContentDocument.FileExtension == "jpg" || 
                              allAttachments[i].ContentDocument.FileExtension == "jpeg" || 
                              allAttachments[i].ContentDocument.FileExtension == "bmp" || 
                              allAttachments[i].ContentDocument.FileExtension == "gif") {
                        allAttachments[i].attachmentIcon = "doctype:image";
                    } else { 
                        allAttachments[i].attachmentIcon = "doctype:attachment";
                    }
                }
                
                component.set("v.requestStatus", requestStatus.Status__c);
                component.set("v.extendedRelatedListCount", allAttachments.length);
            },
            {
                //params
                "recordId" : recordId
            },
            false
        );
    },
    
    /** Gets the data on load **/    
    getAttachments : function(component) {
        var recordId = component.get("v.recordId");
        var self = this;
        
        /* Fetch the records */
        self.callToServer(
            component,
            "c.fetchAttachmentList", /* server method */
            function(response) {
                var responseVar = response;
                var allAttachments = responseVar.allAttachments;
                var requestStatus = responseVar.requestRecord;
                
                /* function to convert file size into human readable form */
                function readableBytes(bytes) {
                    var i = Math.floor(Math.log(bytes) / Math.log(1024)),
                        sizes = ['B', 'KB', 'MB'];
                    return (bytes / Math.pow(1024, i)).toFixed(0) * 1 + ' ' + sizes[i];
                }
                
                for(var i=0; i<allAttachments.length; i=i+1) {
                    if(allAttachments[i] !== null && allAttachments[i] !== undefined && allAttachments[i] !== " ") {
                        allAttachments[i].ContentDocument.ContentSize = readableBytes(allAttachments[i].ContentDocument.ContentSize);
                        //allAttachments[i].CreatedDate = allAttachments[i].ContentDocument.CreatedDate;
                        if(allAttachments[i].ContentDocument.FileExtension == "xls" || 
                           allAttachments[i].ContentDocument.FileExtension == "xlsx") {
                            allAttachments[i].attachmentIcon = "doctype:excel";
                        } else if(allAttachments[i].ContentDocument.FileExtension == "doc" || 
                                  allAttachments[i].ContentDocument.FileExtension == "docx") {
                            allAttachments[i].attachmentIcon = "doctype:word";
                        } else if(allAttachments[i].ContentDocument.FileExtension == "ppt" || 
                                  allAttachments[i].ContentDocument.FileExtension == "pptx") {
                            allAttachments[i].attachmentIcon = "doctype:ppt";
                        } else if(allAttachments[i].ContentDocument.FileExtension == "pdf") {
                            allAttachments[i].attachmentIcon = "doctype:pdf";
                        } else if(allAttachments[i].ContentDocument.FileExtension == "txt") {
                            allAttachments[i].attachmentIcon = "doctype:txt";
                        } else if(allAttachments[i].ContentDocument.FileExtension == "html") {
                            allAttachments[i].attachmentIcon = "doctype:html";
                        } else if(allAttachments[i].ContentDocument.FileExtension == "csv") {
                            allAttachments[i].attachmentIcon = "doctype:csv";
                        } else if(allAttachments[i].ContentDocument.FileExtension == "zip" || 
                                  allAttachments[i].ContentDocument.FileExtension == "rar") {
                            allAttachments[i].attachmentIcon = "doctype:zip";
                        } else if(allAttachments[i].ContentDocument.FileExtension == "xml") {
                            allAttachments[i].attachmentIcon = "doctype:xml";
                        } else if(allAttachments[i].ContentDocument.FileExtension == "png" || 
                                  allAttachments[i].ContentDocument.FileExtension == "jpg" || 
                                  allAttachments[i].ContentDocument.FileExtension == "jpeg" || 
                                  allAttachments[i].ContentDocument.FileExtension == "bmp" || 
                                  allAttachments[i].ContentDocument.FileExtension == "gif") {
                            allAttachments[i].attachmentIcon = "doctype:image";
                        } else { 
                            allAttachments[i].attachmentIcon = "doctype:attachment";
                        }
                    }
                }
                if(allAttachments.length == 0) {
                    component.set("v.hasFiles",false);
                } else if(allAttachments.length > 2) {
                    component.set("v.relatedListCount", "2+");
                    component.set("v.hasFiles",true);
                } else {
                    component.set("v.relatedListCount", allAttachments.length);
                    component.set("v.hasFiles",true);
                }
                
                component.set("v.requestStatus", requestStatus.Status__c);
                component.set("v.AllRecordList", allAttachments);
                if(requestStatus.Status__c === "Draft") {
                    component.set("v.isDraft", true);
                } else {
                    component.set("v.isNotDraft", true);
                }  
            },
            {
                //params
                "recordId" : recordId
            },
            false
        );
    },
    
    /** Display all attachments in a modal **/    
    navigateToStandardRelatedList : function(component) {
        var relatedListEvent = $A.get("e.force:navigateToRelatedList"); 
        relatedListEvent.setParams({
            "relatedListId": "CombinedAttachments",
            "parentRecordId": component.get("v.recordId")
        });
        relatedListEvent.fire();
    }
})