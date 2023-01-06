/*******************************************************************************************************
* 
* @ Name :IFv2_LookupUtilities
* @ Purpose : 
* @ Author: Anoop Ravindran
*
*   Date        |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   03-11-2018  |  anoop.ravindran@absyz.com	|  1.0          |  Initial Version
*******************************************************************************************************/

public class IFv2_LookupResponseData {
public Boolean isSuccess;
    public Map<String, Object> results;
    public String errMsg;

    public IFv2_LookupResponseData() {
        this.isSuccess = true;
        this.results = new Map<String, Object>();
    }

    public void addError(String errMsg){
        this.errMsg = errMsg;
        this.isSuccess = false;
    }

    public String getJsonString() {
        return IFv2_LookupUtilities.serializeWithoutNamespace(this);
    }
}