public class IFv2_TStringUtils {
    public static Map<String,List<String>> GetDependentOptions(String pObjName, String pControllingFieldName, String pDependentFieldName){
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        //get the string to sobject global map
        Map<String,Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
        if (!Schema.getGlobalDescribe().containsKey(pObjName))
            return objResults;
        system.debug('objResults----'+objResults);
        //get the type being dealt with
        Schema.SObjectType pType = Schema.getGlobalDescribe().get(pObjName);
        system.debug('pType----'+pType);
        return GetDependentOptionsImpl(pType,pControllingFieldName,pDependentFieldName);        
    }
    public static Map<String,List<String>> GetDependentOptionsImpl(Schema.SObjectType pType, String pControllingFieldName, String pDependentFieldName){
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        if (pType==null)
            return objResults;
        IFv2_DependentPicklist BitSetInstance = new IFv2_DependentPicklist();
        Map<String, Schema.SObjectField> objFieldMap = pType.getDescribe().fields.getMap(); 
        //verify field names
        if (!objFieldMap.containsKey(pControllingFieldName) || !objFieldMap.containsKey(pDependentFieldName))
            return objResults;     
        //get the control values   
        List<Schema.PicklistEntry> ctrl_ple = objFieldMap.get(pControllingFieldName).getDescribe().getPicklistValues();
        //get the dependent values
        List<Schema.PicklistEntry> dep_ple = objFieldMap.get(pDependentFieldName).getDescribe().getPicklistValues();
        objFieldMap = null;
        List<Integer> lstControllingIndexes = new List<Integer>();
        //iterate through the values and get the ones valid for the controlling field name
        //set up the results
        for(Integer pControllingIndex=0; pControllingIndex<ctrl_ple.size(); pControllingIndex++){        	
            //get the pointer to the entry
            Schema.PicklistEntry ctrl_entry = ctrl_ple[pControllingIndex];
            //get the label
            String pControllingLabel = ctrl_entry.getLabel();
            //create the entry with the label
            objResults.put(pControllingLabel,new List<String>());
            //keep track of the controlling indexes
            lstControllingIndexes.add(pControllingIndex);
        }
        //cater for null and empty
        objResults.put('',new List<String>());
        objResults.put(null,new List<String>());
        //load all dep entries
        List<Schema.PicklistEntry> objEntries = new List<Schema.PicklistEntry>();
        List<IFv2_TPicklistEntry> objDS_Entries = new List<IFv2_TPicklistEntry>();
        //add all entries
        for(Integer pDependentIndex=0; pDependentIndex<dep_ple.size(); pDependentIndex++){        	
            //get the pointer to the dependent index
            Schema.PicklistEntry dep_entry = dep_ple[pDependentIndex];
            objEntries.add(dep_entry);
            
        } 
        system.debug('objEntries:'+objEntries);
        //serialize once        
        objDS_Entries = (List<IFv2_TPicklistEntry>)JSON.deserialize(JSON.serialize(objEntries), List<IFv2_TPicklistEntry>.class);
        system.debug('objDS_Entries:'+objDS_Entries);
        List<Integer> validIndexes;
        for (IFv2_TPicklistEntry objDepPLE : objDS_Entries){
            //if valid for is empty, skip    
            if (objDepPLE.validFor==null || objDepPLE.validFor==''){
                continue;
            }
            //get the test for the controlling indexes
            validIndexes = BitSetInstance.testBits(objDepPLE.validFor,lstControllingIndexes);
            for (Integer validIndex : validIndexes){            	
                //get the label
                String pControllingLabel = ctrl_ple[validIndex].getLabel();
                objResults.get(pControllingLabel).add(objDepPLE.label);
            }
        }
        objEntries = null;
        objDS_Entries = null;
        system.debug('objResults----'+objResults);
        return objResults;
    }
}