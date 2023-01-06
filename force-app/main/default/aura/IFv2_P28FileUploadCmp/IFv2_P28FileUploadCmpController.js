({
    /**force closes the modal window and refreshed the current page through event**/
    closeModal : function(component, event, helper) {
        helper.cancel(component);
    },
    
    /**stores csv file in file attribute**/
    storecsv:function(component, event, helper) {
        component.set("v.isRequiredEmpty", false);
        var file= event.getSource().get("v.files");//holds uploaded file
        var filename = file[0].name;
        component.set("v.fileName",filename);
        component.set("v.file",file);//storing the file in an attribute
        //validation of csv file type  
        if(!filename.includes(".csv")){
            component.set("v.alertMessage", "Please Upload CSV File");
            component.set("v.isRequiredEmpty", true);
        } else if(file[0].size>4000000) {
            component.set("v.alertMessage", "Please Upload CSV File less than 4MB");
            component.set("v.isRequiredEmpty", true);
            component.set("v.file", null);
        }
    },
    
    /**reads csv file and inserts it into salesforce**/
    readCSV: function(component, event, helper) {
        var file= component.get("v.file");
        var description = component.get("v.descriptionText");
        var filename = component.get("v.fileName");
        component.set("v.isRequiredEmpty", false);
        //validation check of description 
        if(description===undefined || description==="") {
            component.set("v.alertMessage", "Please Enter Description");
            component.set("v.isRequiredEmpty", true);
        } else if(description.length > 1000) {
            component.set("v.alertMessage", "Please Enter Description within 1000 characters");
            component.set("v.isRequiredEmpty", true);
        } else if(file===null || file===undefined){
            component.set("v.alertMessage", "Please Upload CSV File");
            component.set("v.isRequiredEmpty", true);
        } else if(file.length === 0) {
            component.set("v.alertMessage", "Please Upload CSV File");
            component.set("v.isRequiredEmpty", true);
        } else if(!file[0].name.includes(".csv")) { //validation check for file type
            component.set("v.alertMessage", "Please Upload CSV File");
            component.set("v.isRequiredEmpty", true);
        } else if(filename==='success.csv' || filename==='failure.csv') { //validation check for file type
            component.set("v.alertMessage", "Please do not use success or failure keywords");
            component.set("v.isRequiredEmpty", true);
        } else {
            //using filereader to read the blob and convert to string
            component.set("v.showSpinner", true);
            var reader = new FileReader();
            reader.onload = function() {
                var text = reader.result; /*Get the data stored in file*/
                helper.sendFileToServer(component, text, filename, description);
            };
            
            if (file[0] !== undefined && file[0] !== null && file[0] !== '') {
                reader.readAsText(file[0]);
            }
        }
    }
})