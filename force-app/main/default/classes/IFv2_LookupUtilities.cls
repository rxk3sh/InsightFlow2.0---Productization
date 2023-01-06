/*******************************************************************************************************
* 
* @ Name :IFv2_LookupUtilities
* @ Purpose : 
* @ Author: Anoop Ravindran
*
*   Date        |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   03-11-2018      |  anoop.ravindran@absyz.com	|  1.0          |  Initial Version
*******************************************************************************************************/

public class IFv2_LookupUtilities {
    private static FINAL String MY_NAMESPACE = [SELECT NamespacePrefix FROM ApexClass WHERE Name = 'IFv2_LookupUtilities' LIMIT 1].NamespacePrefix;
    public static FINAL String NAMESPACE = String.isBlank(MY_NAMESPACE) ? '' : MY_NAMESPACE;
    public static FINAL String NAMESPACE_API = String.isBlank(MY_NAMESPACE) ? '' : MY_NAMESPACE + '__';
    
    public static String serializeWithoutNamespace(Object myObject) {
        return JSON.serialize(myObject).replaceAll(IFv2_LookupUtilities.NAMESPACE_API, '');
    }
    
    public static Map<String, Object> convertObjectToMap(Object myObject) {
        return (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(myObject));
    }
}