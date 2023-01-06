/*******************************************************************************************************
* 
* @ Name        :   IFv2_GenerateChallanController
* @ Purpose     :   generating challan
* @ Author      :   Naga Sai
* @ Test Class  :   IFv2_GenerateChallanControllerTest
*
*   Date        |  Developer Name                   |  Version      |  Changes
* ======================================================================================================
*   09-05-2019  |  nagasai.chalamalasetti@absyz.com |  1.0          |  Initial Version
*   27-06-2019  |  external.debasmita.rawooth@seg-automotive.com    |  Removed TIN from pdf
*   02-12-2019  |  external.debasmita.rawooth@seg-automotive.com    |  Made changes for Supplier/Customer details without SAP Code
********************************************************************************************************/

public class IFv2_GenerateChallanController {
    public static LIST<IFv2_PrintableViewLayout__mdt> printableViewLayoutList = new LIST<IFv2_PrintableViewLayout__mdt>();
    public static MAP<String,IFv2_PrintableViewLayout__mdt> sectionPrintableView = new MAP<String,IFv2_PrintableViewLayout__mdt>();
    public static string requestid;
    //this is defined as we are using standard controller in visual force page
    public IFv2_GenerateChallanController(apexpages.StandardController RequestStandardController){
        requestid = ApexPages.currentPage().getParameters().get('id');
        printableViewLayoutList =[select DeveloperName,HorizonatalLine__c,Division__c,Table__c,TableCellLabel__c,TableCellValue__c,TableRow__c,ImageSourceTag__c ,HTMLTag__c,ImageSpecsTag__c  from IFv2_PrintableViewLayout__mdt];
        for(IFv2_PrintableViewLayout__mdt printableLayout : printableViewLayoutList){
            sectionPrintableView.put(printableLayout.DeveloperName,printableLayout);
        }
        
    } //it generates html string to be displayed on challan
    public static string getchallanHTML(){
        //fetching id from page parameters
        
        if(requestid!=Null){
            //querying for request and its detail object material
            IFv2_Request__c request = [SELECT Id,Name,
                                       AddresswithPINcode__c,
                                       DueDateofReturn__c,
                                       RequestExtension1__r.Purpose__c,
                                       RequestExtension1__r.EwayBillno__c,
                                       RequestExtension1__r.CarrierName__c,
                                       RequestExtension1__r.DriverName__c,
                                       RequestExtension1__r.VehicleNumber__c,
                                       RequestExtension1__r.GrossWeight__c,
                                       RequestExtension1__r.NoofPackages__c,
                                       RequestExtension1__r.ChallanNo__c,
                                       RequestExtension1__r.ContactNumber__c,
                                       RequestExtension1__r.RemarksLogistics__c,
                                       SupplierCustomerNo__r.Name,
                                       SupplierCustomerNo__r.Phone,
                                       TotalAmountMGP__c,
                                       GSTIN__c,
                                       SAPVendorCode__c,
                                       ApplicantFirstName__c,
                                       ApplicantLastName__c,
                                       ApplicantDepartment__c,
                                       ApplicantPhone__c,
                                       Customer_Name__c,
                                       Customer_Address__c,
                                       CustomerGSTIN__c,
                                       CustomerPhone__c
                                       
                                       FROM IFv2_Request__c WHERE Id =:requestid];
            LIST<Account> materialLIST = [SELECT Id,IFv2_PartNumber__c,IFv2_DescriptionMGP__c,IFv2_HSN__c,IFv2_Quantity__c,IFv2_Units__c 
                                          FROM Account WHERE IFv2_ContentType__c ='Material' AND IFv2_Request__c=:requestid];
           System.debug('material list>>'+materialLIST);
            //initating variable that holds entire table html string
            String table ='';
            //forming the table using colspan and row span wherever necessary and also doing null checks
            String tr = sectionPrintableView.get('ChallanHeader').TableCellLabel__c + '<output>'+label.CLIFv20203+'</output>'+'<output>'+request.RequestExtension1__r.ChallanNo__c+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            tr+=sectionPrintableView.get('ChallanHeader').TableCellValue__c;
            String imgUrl = PageReference.forResource(Label.CLIFv20241).getUrl();
            tr+=sectionPrintableView.get('ChallanHeader').Division__c   +
                sectionPrintableView.get('ChallanHeader').ImageSourceTag__c+ imgUrl + sectionPrintableView.get('ChallanHeader').ImageSpecsTag__c+
                sectionPrintableView.get('EndTagsChallan').Division__c+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
            tr='';
            tr+=sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'1'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20208+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan5').TableCellLabel__c+'<output>'+label.CLIFv20201+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
            tr='';
            tr+=sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'2'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20209+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan2').TableCellLabel__c+String.valueOf(Date.today())+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan4').TableCellLabel__c+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
            
            /* if(request.SupplierCustomerNo__r.Name!=null)
{
tr='';
tr+=sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20210+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+SectionPrintableView.get('TDwithcolspan4').TableCellLabel__c+'<output>'+request.SupplierCustomerNo__r.Name+'</output>'+sectionPrintableView.get('BreakTag').HTMLTag__c+(request.AddresswithPINcode__c==Null?'':'<output>'+request.AddresswithPINcode__c+'</output>')+
sectionPrintableView.get('BreakTag').HTMLTag__c+'Phone:'+'<output>'+request.SupplierCustomerNo__r.Phone+'</output>'+(request.GSTIN__c==Null?'':sectionPrintableView.get('BreakTag').HTMLTag__c+' GSTIN:' +'<output>'+request.GSTIN__c+'</output>')+(request.SAPVendorCode__c==Null?'':sectionPrintableView.get('BreakTag').HTMLTag__c+'SAP Vendor Code:'+'<output>'+request.SAPVendorCode__c +'</output>')+ sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c;
table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
tr='';
} */
            if(request.SupplierCustomerNo__r.Name!=null)
            {
                tr='';
                tr+=sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20210+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+SectionPrintableView.get('TDwithcolspan4').TableCellLabel__c+'<output>'+request.SupplierCustomerNo__r.Name+'</output>'+sectionPrintableView.get('BreakTag').HTMLTag__c+(request.AddresswithPINcode__c==Null?'':'<output>'+request.AddresswithPINcode__c+'</output>')+
                    (request.SupplierCustomerNo__r.Phone==Null?'':sectionPrintableView.get('BreakTag').HTMLTag__c+' Phone:' +'<output>'+request.SupplierCustomerNo__r.Phone+'</output>')+(request.GSTIN__c==Null?'':sectionPrintableView.get('BreakTag').HTMLTag__c+' GSTIN:' +'<output>'+request.GSTIN__c+'</output>')+(request.SAPVendorCode__c==Null?'':sectionPrintableView.get('BreakTag').HTMLTag__c+'SAP Vendor Code:'+'<output>'+request.SAPVendorCode__c +'</output>')+ sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c;
                table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
                tr='';
            }
            
            if(request.Customer_Name__c!=Null && request.SupplierCustomerNo__r.Name==null){
                tr='';
                tr+=sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20210+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+SectionPrintableView.get('TDwithcolspan4').TableCellLabel__c+'<output>'+request.Customer_Name__c+'</output>'+sectionPrintableView.get('BreakTag').HTMLTag__c+(request.Customer_Address__c==Null?'':'<output>'+request.Customer_Address__c+'</output>')+
                    (request.CustomerPhone__c==Null?'':sectionPrintableView.get('BreakTag').HTMLTag__c+' Phone:' +'<output>'+request.CustomerPhone__c+'</output>')+(request.CustomerGSTIN__c==null?'':sectionPrintableView.get('BreakTag').HTMLTag__c+' GSTIN:' +'<output>'+request.CustomerGSTIN__c+'</output>')+(request.SAPVendorCode__c==Null?'':sectionPrintableView.get('BreakTag').HTMLTag__c+'SAP Vendor Code:'+'<output>'+request.SAPVendorCode__c +'</output>')+ sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c;
                table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
                tr='';
            }
            String DueDateofReturn;
            if(request.DueDateofReturn__c != NULL)
            DueDateofReturn = string.valueof(request.DueDateofReturn__c);
            else
            DueDateofReturn = 'NON';    
            tr+=sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'3'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20211+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan2').TableCellLabel__c+(DueDateofReturn==Null?'':'<output>'+DueDateofReturn+'</output>')+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan4').TableCellLabel__c+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
            tr='';
            String name =(request.ApplicantFirstName__c==Null?'':'<output>'+request.ApplicantFirstName__c+'</output>') +' '+(request.ApplicantLastName__c==Null?'':'<output>'+request.ApplicantLastName__c+'</output>');
            tr+=sectionPrintableView.get('TDwithrowspan2').TableCellLabel__c+'4'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20212+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan2').TableCellLabel__c+(request.ApplicantFirstName__c==Null?'':'<output>'+request.ApplicantFirstName__c+'</output>')+' '+(request.ApplicantLastName__c==Null?'':'<output>'+request.ApplicantLastName__c+'</output>')+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan4').TableCellLabel__c+(request.ApplicantDepartment__c==Null?'':'<output>'+request.ApplicantDepartment__c+'</output>')+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
            tr='';
            tr+=sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20213+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan2').TableCellLabel__c+(request.RequestExtension1__r.ContactNumber__c==Null?'':'<output>'+request.RequestExtension1__r.ContactNumber__c+'</output>')+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan4').TableCellLabel__c+'<output>'+request.Name+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
            tr='';
            tr+=sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'5'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20214+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan5').TableCellLabel__c+(request.RequestExtension1__r.Purpose__c==Null?'':'<output>'+request.RequestExtension1__r.Purpose__c+'</output>')+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
            tr='';
            Integer rowspan =materialLIST.size()+1;
            tr+=sectionPrintableView.get('MaterialsRowSpanTagChallan').TableCellLabel__c+rowspan+sectionPrintableView.get('MaterialsRowSpanTagChallan').TableCellvalue__c+'6'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('MaterialsRowSpanTagChallan').TableCellLabel__c+rowspan+sectionPrintableView.get('MaterialsRowSpanTagChallan').TableCellvalue__c+'<output>'+label.CLIFv20215+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20216+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20217+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20218+'</output>'+ sectionPrintableView.get('EndTagsChallan').TableCellLabel__c +sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20219+'</output>'+ sectionPrintableView.get('EndTagsChallan').TableCellLabel__c +sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20220+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
            tr='';
            for(Account material:materialLIST){
                System.debug('mat des>'+material.IFv2_DescriptionMGP__c);
                tr+=sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+(material.IFv2_PartNumber__c==Null?'':material.IFv2_PartNumber__c)+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+(material.IFv2_DescriptionMGP__c==Null?'':material.IFv2_DescriptionMGP__c)+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+(material.IFv2_HSN__c==Null?'':material.IFv2_HSN__c)+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+(string.valueof(material.IFv2_Quantity__c)==Null?'':string.valueof(material.IFv2_Quantity__c))+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+(material.IFv2_Units__c==Null?'':material.IFv2_Units__c)+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
                table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
                tr='';
            }
            tr='';
            tr+=sectionPrintableView.get('TDwithrowspan2').TableCellLabel__c+'7'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20221+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan3').TableCellLabel__c + (string.valueof(request.RequestExtension1__r.GrossWeight__c)==Null?'':'<output>'+string.valueof(request.RequestExtension1__r.GrossWeight__c)+'</output>')  +sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan2').TableCellLabel__c +sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
            tr='';
            tr+=sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c +'<output>'+label.CLIFv20222+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan3').TableCellLabel__c  +(string.valueof(request.RequestExtension1__r.NoofPackages__c)==Null?'':'<output>'+string.valueof(request.RequestExtension1__r.NoofPackages__c)+'</output>') +sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan2').TableCellLabel__c +sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
            
            tr='';   
            tr+=sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'8'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20223+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan3').TableCellLabel__c+(string.valueof(request.TotalAmountMGP__c)==Null?'':'<output>'+string.valueof(request.TotalAmountMGP__c)+'</output>')+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan2').TableCellLabel__c+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
            tr='';
            tr+=sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'9'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20224+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan3').TableCellLabel__c+(request.RequestExtension1__r.CarrierName__c==Null?'':'<output>'+request.RequestExtension1__r.CarrierName__c+'</output>')+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan2').TableCellLabel__c+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
            tr='';
            tr+=sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'10'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20225+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan3').TableCellLabel__c+(request.RequestExtension1__r.VehicleNumber__c==Null?'':'<output>'+request.RequestExtension1__r.VehicleNumber__c+'</output>')+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan2').TableCellLabel__c+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
            tr='';
            tr+=sectionPrintableView.get('TDwithrowspan2').TableCellLabel__c+'11'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20226+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan3').TableCellLabel__c+(request.RequestExtension1__r.DriverName__c==Null?'':'<output>'+request.RequestExtension1__r.DriverName__c+'</output>')+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan2').TableCellLabel__c+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            table+=sectionPrintableView.get('PlainTableAttributes').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
            tr='';
            //space is for signature
            tr+=sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20227+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan3').TableCellLabel__c+  sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan2').TableCellLabel__c  +'   '+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            table+=sectionPrintableView.get('TRWithStyleChallan').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c ;
            tr='';
            tr+=sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'12'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20228+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan5').TableCellLabel__c+(request.RequestExtension1__r.EwayBillno__c==Null?'':'<output>'+request.RequestExtension1__r.EwayBillno__c+'</output>')+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            table+=sectionPrintableView.get('TRWithStyleChallan').TableRow__c  +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
            tr='';
            tr+=sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'13'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('PlainTableAttributes').TableCellLabel__c+'<output>'+label.CLIFv20240+'</output>'+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c+sectionPrintableView.get('TDwithcolspan5').TableCellLabel__c+(request.RequestExtension1__r.RemarksLogistics__c==Null?'':'<output>'+request.RequestExtension1__r.RemarksLogistics__c+'</output>')+sectionPrintableView.get('EndTagsChallan').TableCellLabel__c;
            table+=sectionPrintableView.get('TRWithStyleChallan').TableRow__c +tr +sectionPrintableView.get('EndTagsChallan').TableRow__c;
            
            return sectionPrintableView.get('TableWithStyleChallan').Table__c+table+sectionPrintableView.get('EndTagsChallan').HTMLTag__c;
        }
        else
            return sectionPrintableView.get('EndTagsChallan').HTMLTag__c+'There is no id parameter in the url'+sectionPrintableView.get('EndTagsChallan').HTMLTag__c;
    }
}