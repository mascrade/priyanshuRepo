/*
* Class Name               : HM_syncSecondaryOpertorsInCase
* Description              : Apex Class - Apex Class to to add/update secondary Operators in related Hi Marley Case 
* Author                   : Darshana Dange (Futran Solutions)
* Created On               : 08 Aug 2022
* Test Class               : HM_Test_HM_syncSecondaryOperatorsInCase
* Change Log History       :
*  |-------------------------------------------------------------------------------------------|
*  | Version | Modified By      | Date       | Comment                                         |
*  |-------------------------------------------------------------------------------------------|
*  | 0.1     | Darshana Dange   | 08/08/2022 | Initial Version of Class                        |
*  | 0.2     | Darshana Dange   | 18/08/2022 | Updated the logic of adding secondary operators |
*  |-------------------------------------------------------------------------------------------|
*/

public class HM_syncSecondaryOpertorsInCase {
    
    @InvocableMethod(label='Sync Secondary Operators in Case HM' description='Sync Secondary Operators in Case HM' category= 'Case')
    public static void HM_sync_SecondaryOperators(List<string> lstCaseIds){
        
        if(lstCaseIds == null || lstCaseIds.size() <= 0){
            return;
        }
        
        //Create Variables to store the details 
        List<Case> lstCases = new List<Case>();
        Map<String, object> mapJsonData = new Map<String, object>();
        List<Map<String, object>> lstMapSecondaryOperators = new List<Map<String, object>>();
        string sCaseId, sQuery, sEndPointUrl, sSerializedData, sStatusCode, sJSONResponse;
        
        if(string.isBlank(lstCaseIds[0])){
            return;
        }
        
        sCaseId = lstCaseIds[0];
        
        //Create a dynamic query to get related case details
        sQuery = 'Select Id, HM_Case_Id__c, HM_Sync_Secondary_Operators_in_Hi_Marley__c, HM_Secondary_Operators_Present_in_HM__c, HM_Integration_Message__c from Case where Id = ' + '\'' + sCaseId + '\'';
        system.debug('sQuery ==> ' + sQuery);
        
        //Fetch all the case details using the dynamic query
        lstCases = Database.query(sQuery);
        
        if(lstCases == null || lstCases.size() <= 0){
            return;
        }
        
        Case objCase = lstCases[0];
        
        if(objCase == null){
            return;
        }
        
        //Create JSON Request Body using field mappings of the custom setting        
        //Get the Case Team Members from the related Case        
        lstMapSecondaryOperators = HM_Integration_Helper.getSecondaryOperatorsFromCaseTeams(sCaseId);
        
        if(lstMapSecondaryOperators.size() > 0){
            mapJsonData.put('secondaryOperators', lstMapSecondaryOperators);
        }
        else{
            mapJsonData.put('secondaryOperators', lstMapSecondaryOperators);
        }
        
        if(mapJsonData == null || mapJsonData.size() <= 0){
            return;
        }
        
        //serialize the case details as a JSON Body
        sSerializedData = JSON.serialize(mapJsonData);
        System.debug('Data in Map:: '+ JSON.serializepretty(mapJsonData));        
        
        //Get Case Integration details from HM_Integration Metadata
        HM_Integration__mdt objCaseUpdateAPI = [Select Id, DeveloperName, API_Key__c, HM_End_Point_URL__c 
                                                from HM_Integration__mdt 
                                                where DeveloperName = 'HM_Case_Updation'];  
        
        if(string.isBlank(objCaseUpdateAPI.HM_End_Point_URL__c) || string.isBlank(objCaseUpdateAPI.API_Key__c)){
            objCase.HM_Sync_Secondary_Operators_in_Hi_Marley__c = false; 
            if(System.Label.HM_IM_Generic_1 != null){
                objCase.HM_Integration_Message__c = System.Label.HM_IM_Generic_1;
            }
            update objCase;
            return;
        }
        
        //Append HI Marley Case ID at end of Case Update API
        sEndPointUrl = objCaseUpdateAPI.HM_End_Point_URL__c + objCase.HM_Case_Id__c;
        
        //HTTP Request
        Http http = new Http();    
        
        HttpRequest httpReq = HM_Integration_Helper.getHttpRequest('PUT', sEndPointUrl, objCaseUpdateAPI.API_Key__c, ' ', sSerializedData);
        
        HttpResponse httpResponse = new HttpResponse();
        
        try{
            
            httpResponse = http.send(httpReq);
            sStatusCode = string.valueOf(httpResponse.getStatusCode());
            system.debug('Status Code ==> ' + sStatusCode );
            
            if(sStatusCode == '201' || sStatusCode == '200'){
                
                sJSONResponse = httpResponse.getBody();
                
                Map<String, Object> mapHMResponse = (Map<String, Object>)JSON.deserializeUntyped(sJSONResponse);
                system.debug('mapHMResponse ==> ' + mapHMResponse);
                
                //Get Case Details from Hi Marley
                Map<String, Object> mapCaseData = (Map<String, Object>)mapHMResponse.get('caseData');
                
                //Get list of Email Ids of Secondary Operators Present in Hi Marley Case
                string sEmailIds = HM_Integration_Helper.updateSecondaryOperators(mapHMResponse);             
                system.debug('sEmailIds : ' + sEmailIds);
                
                //Update related Case details
                if(mapHMResponse != null && mapHMResponse.size() > 0){
                    if(mapCaseData.get('id') == objCase.HM_Case_Id__c){
                        objCase.HM_Sync_Secondary_Operators_in_Hi_Marley__c = false;
                        if(System.Label.HM_Sync_Secondary_Operators != null){
                            objCase.HM_Integration_Message__c = System.Label.HM_Sync_Secondary_Operators;
                        }
                        objCase.HM_Secondary_Operators_Present_in_HM__c = '';
                        if(string.isNotBlank(sEmailIds)){
                            objCase.HM_Secondary_Operators_Present_in_HM__c = sEmailIds;
                        }
                        update objCase;
                    }
                }
                
                //Create Success Log Entry record
                HM_Integration_Helper.create_HMLogs('Sync Secondary Opertors', 'Success', sStatusCode, 'Outbound', sSerializedData, sJSONResponse, ' ');
                
            }
            else{
                
                sJSONResponse = httpResponse.getBody();
                
                Map<string, Object> mapErrorDetails = HM_Integration_Helper.getErrorDetails(sJSONResponse);
                
                if(mapErrorDetails != null && mapErrorDetails.size() > 0){
                    objCase.HM_Sync_Secondary_Operators_in_Hi_Marley__c = false;
                    objCase.HM_Integration_Message__c = mapErrorDetails.get('code') + '\r\n' + mapErrorDetails.get('detail');
                    update objCase;
                }
                
                //Create a Error Log Entry record
                HM_Integration_Helper.create_HMLogs('Sync Secondary Opertors', 'Error', sStatusCode, 'Outbound', sSerializedData, sJSONResponse, ' ');
            }
        } 
        catch(Exception e){
            
            System.debug('The following exception has occurred: ' + e.getMessage());
            
            if(System.Label.HM_Sync_Secondary_Operator_failure != null){
                objCase.HM_Integration_Message__c = System.Label.HM_Sync_Secondary_Operator_failure;
            }
            objCase.HM_Sync_Secondary_Operators_in_Hi_Marley__c = false;            
            update objCase;
            
            //Create a Exception Log Entry record
            HM_Integration_Helper.create_HMLogs('Sync Secondary Opertors', 'Error', '0', 'Outbound', sSerializedData, e.getMessage(), ' ');
        }
        
    }
    
}