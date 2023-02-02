/*
* Class Name               : HM_CreateCaseInHM
* Description              : Apex Queueable Class - Apex Class to call the Case Creation 
*                            API Endpoint to create a case in Hi Marley.
* Author                   : Darshana Dange (Futran Solutions)
* Created On               : 26 July 2022
* Test Class               : HM_Test_HM_CreateCaseInHM
* Change Log History       :
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Darshana Dange   | 26/07/2022 | Initial Version of Queueable Class   |
*  | 0.2     | Darshana Dange   | 04/08/2022 | Updated Additional Checks for        |
*  |                                           branding and creation for HM Logs    |
*  |--------------------------------------------------------------------------------|
*/

public class HM_CreateCaseInHM{
    
    @InvocableMethod(label='Create Case in HM' description='Create a Case in HM' category= 'Case')
    public static void HM_CreateCaseInHM(List<string> lstCaseIds){
        
        if(lstCaseIds == null || lstCaseIds.size() <= 0){
            return;
        }
        
        //Create Variables to store the details 
        List<Case> lstCases = new List<Case>();
        Map<String, object> mapJsonData = new Map<String, object>();
        Map<string, Map<string, Object>> mapAPISubObjects = new Map<string, Map<string, Object>>();
        Map<String, object> mapAPIObjectDetails = new Map<String, object>();
        List<Map<String, object>> lstMapSecondaryOperators = new List<Map<String, object>>();
        set<string> setContactIds = new set<string>();
        string sCaseId, sQuery;
        string sFieldLabel, sAPIName;
        string sSerializedData, sStatusCode, sJSONResponse;
        string sCaseFields = '';
        
        if(string.isBlank(lstCaseIds[0])){
            return;
        }        
        
        sCaseId = lstCaseIds[0];
        
        //Get all Case fields mapping details
        Map<string, HM_Case_Fields_Mapping__c> mapCase_HMFieldsSFFields = HM_Case_Fields_Mapping__c.getAll();     
        
        //Get Feature Flagging for creating HM Logs
        Map<string, HM_Branding__c> map_Branding = HM_Branding__c.getAll();
        
        //Get all SF Fields to query on related case
        if(mapCase_HMFieldsSFFields != null && mapCase_HMFieldsSFFields.size() > 0){
            for(HM_Case_Fields_Mapping__c objCaseMdt : mapCase_HMFieldsSFFields.values()){
                if(string.isNotBlank(objCaseMdt.HM_SF_Field__c)){
                    if(!sCaseFields.contains(objCaseMdt.HM_SF_Field__c)){
                        sCaseFields += objCaseMdt.HM_SF_Field__c + ', ';
                    }
                }
            }
        }
        
        //To remove ', ' from query string's end
        if(string.isNotBlank(sCaseFields)){
            sCaseFields = sCaseFields.removeEnd(', ');
        }
        else{
            // return as the case fields are blank
            return;
        }
        
        //Create a dynamic query to get related case details
        sQuery = 'Select Id, HM_Case_Id__c, HM_Send_Create_Request__c, HM_Integration_Message__c, HM_Case_Status__c, HM_Reference_ID__c, ' +
                 'HM_Secondary_Operators_Present_in_HM__c, ' + sCaseFields + ' from Case where Id = ' + '\'' + sCaseId + '\'';
        
        system.debug('sQuery ==> ' + sQuery);
        
        //Fetch all the case details using the dynamic query
        lstCases = Database.query(sQuery);
        
        if(lstCases == null || lstCases.size() <= 0){
            return;
        }
        
        // store the case details in a local variable
        Case objCase = lstCases[0];
        
        if(objCase == null){
            return;
        }
        
        //Create JSON Request Body using field mappings of the custom setting 
        if(mapCase_HMFieldsSFFields != null && mapCase_HMFieldsSFFields.size() > 0){
            for(string sKey : mapCase_HMFieldsSFFields.keySet()){                
                if(string.isNotBlank(sKey)){
                    if(sKey.contains('brand')){
                        if(map_Branding.get('Branding') != null && map_Branding.get('Branding').HM_Enable_Branding__c){
                            if(string.isNotBlank(mapCase_HMFieldsSFFields.get(sKey).HM_API_Sub_Object_Name__c)){
                                if(skey.contains(mapCase_HMFieldsSFFields.get(sKey).HM_API_Sub_Object_Name__c)){
                                    
                                    if(mapAPISubObjects.containsKey(mapCase_HMFieldsSFFields.get(sKey).HM_API_Sub_Object_Name__c)){
                                        mapAPIObjectDetails = mapAPISubObjects.get(mapCase_HMFieldsSFFields.get(sKey).HM_API_Sub_Object_Name__c);
                                    }
                                    else{
                                        mapAPIObjectDetails = new Map<string, Object>();
                                    }
                                    
                                    sFieldLabel = skey.remove(mapCase_HMFieldsSFFields.get(sKey).HM_API_Sub_Object_Name__c + '.');
                                    
                                    if(string.isNotBlank(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Object__c) && 
                                       string.isNotBlank(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Field__c)){
                                           sAPIName = mapCase_HMFieldsSFFields.get(sKey).HM_SF_Field__c;
                                           sAPIName = sAPIName.remove(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Object__c + '.'); 
                                       }
                                    
                                    if(string.isNotBlank(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Object__c)){
                                        if(objCase.getSobject(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Object__c).get(sAPIName) != null){
                                            mapAPIObjectDetails.put(sFieldLabel, objCase.getSobject(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Object__c).get(sAPIName));
                                        }
                                    }
                                    else{
                                        if(objCase.get(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Field__c) != null){
                                            mapAPIObjectDetails.put(sFieldLabel, objCase.get(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Field__c));
                                        }
                                    }
                                    
                                    mapAPISubObjects.put(mapCase_HMFieldsSFFields.get(sKey).HM_API_Sub_Object_Name__c, mapAPIObjectDetails);
                                }
                            }  
                        }
                    }
                    else{
                        if(string.isNotBlank(mapCase_HMFieldsSFFields.get(sKey).HM_API_Sub_Object_Name__c)){
                            if(skey.contains(mapCase_HMFieldsSFFields.get(sKey).HM_API_Sub_Object_Name__c)){
                                
                                if(mapAPISubObjects.containsKey(mapCase_HMFieldsSFFields.get(sKey).HM_API_Sub_Object_Name__c)){
                                    mapAPIObjectDetails = mapAPISubObjects.get(mapCase_HMFieldsSFFields.get(sKey).HM_API_Sub_Object_Name__c);
                                }
                                else{
                                    mapAPIObjectDetails = new Map<string, Object>();
                                }
                                
                                sFieldLabel = skey.remove(mapCase_HMFieldsSFFields.get(sKey).HM_API_Sub_Object_Name__c + '.');
                                
                                if(string.isNotBlank(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Object__c) && 
                                   string.isNotBlank(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Field__c)){
                                       sAPIName = mapCase_HMFieldsSFFields.get(sKey).HM_SF_Field__c;
                                       sAPIName = sAPIName.remove(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Object__c + '.'); 
                                   }
                                
                                if(string.isNotBlank(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Object__c)){
                                    if(objCase.getSobject(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Object__c) != null){
                                        if(objCase.getSobject(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Object__c).get(sAPIName) != null){
                                            mapAPIObjectDetails.put(sFieldLabel, objCase.getSobject(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Object__c).get(sAPIName));
                                        }
                                    }
                                }
                                else{
                                    if(objCase.get(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Field__c) != null){
                                        mapAPIObjectDetails.put(sFieldLabel, objCase.get(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Field__c));
                                    }    
                                }
                                
                                mapAPISubObjects.put(mapCase_HMFieldsSFFields.get(sKey).HM_API_Sub_Object_Name__c, mapAPIObjectDetails);
                            }
                        }                        
                        else{
                            if(string.isNotBlank(mapCase_HMFieldsSFFields.get(sKey).HM_SF_field__c)){
                                if(objCase.get(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Field__c) != null){
                                    mapJsonData.put(skey, objCase.get(mapCase_HMFieldsSFFields.get(sKey).HM_SF_Field__c));
                                }
                            }
                        }
                        
                    }
                }
            }
        }
        
        //Add Salesforce Case Id as reference Id in Hi Marley Case
        if(string.isBlank(objCase.HM_Reference_ID__c)){
            mapJsonData.put('referenceId', objCase.Id);
        }
        
        //Add related nodes in JSON Mapping
        if(mapAPISubObjects != null && mapAPISubObjects.size() > 0){
            for(string sKey : mapAPISubObjects.keySet()){
                mapJsonData.put(skey, mapAPISubObjects.get(skey));
            }
        }
        
        //Get the Case Team Members from the related Case
        lstMapSecondaryOperators = HM_Integration_Helper.getSecondaryOperatorsFromCaseTeams(sCaseId);
        
        if(lstMapSecondaryOperators.size() > 0){
            mapJsonData.put('secondaryOperators', lstMapSecondaryOperators);
        }
        
        if(mapJsonData == null || mapJsonData.size() <= 0){
            return;
        }
        
        //serialize the case details as a JSON Body
        sSerializedData = JSON.serialize(mapJsonData);
        System.debug('Data in Map:: '+ JSON.serializepretty(mapJsonData));        
        
        //Get Case Integration details from HM_Integration Metadata
        HM_Integration__mdt objCaseAPI = [Select Id, DeveloperName, API_Key__c, HM_End_Point_URL__c 
                                          from HM_Integration__mdt 
                                          where DeveloperName = 'HM_Case_Creation'];  
        
        if(string.isBlank(objCaseAPI.HM_End_Point_URL__c) || string.isBlank(objCaseAPI.API_Key__c)){
            objCase.HM_Send_Create_Request__c = false; 
            if(System.Label.HM_IM_Generic_1 != null){
                objCase.HM_Integration_Message__c = System.Label.HM_IM_Generic_1;
            }
            update objCase;
            return;
        }
        
        //HTTP Request
        Http http = new Http();    
        
        HttpRequest httpReq = HM_Integration_Helper.getHttpRequest('POST', objCaseAPI.HM_End_Point_URL__c, objCaseAPI.API_Key__c, ' ', sSerializedData);
        
        HttpResponse httpResponse = new HttpResponse();
        
        try{
            
            httpResponse = http.send(httpReq);
            sStatusCode = string.valueOf(httpResponse.getStatusCode());
            system.debug('Status Code ==> ' + sStatusCode );
            
            if(sStatusCode == '201' || sStatusCode == '200'){
                
                sJSONResponse = httpResponse.getBody();
              
                Map<String, Object> mapHMResponse = (Map<String, Object>)JSON.deserializeUntyped(sJSONResponse);
                system.debug('mapHMResponse ==> ' + mapHMResponse);
                
                //Get Case Details and End Customer Details 
                Map<String, Object> mapCaseData = (Map<String, Object>)mapHMResponse.get('caseData');
                Map<String, Object> mapCustomerData = (Map<String, Object>)mapHMResponse.get('customer');
                
                //Get list of Email Ids of Secondary Operators Present in Hi Marley Case
                string sEmailIds = HM_Integration_Helper.updateSecondaryOperators(mapHMResponse);
                
                //Update related Case details
                if(mapHMResponse != null && mapHMResponse.size() > 0){
                    if(mapCaseData.get('id') != null){
                        objCase.HM_Case_Id__c = string.valueOf(mapCaseData.get('id'));
                        objCase.HM_Case_Status__c = 'Open';
                        objCase.HM_Send_Create_Request__c = false;
                        if(System.Label.HM_Case_Creation_SF_to_HM != null){
                            objCase.HM_Integration_Message__c = System.Label.HM_Case_Creation_SF_to_HM;
                        }
                        if(string.isNotBlank(sEmailIds)){
                            objCase.HM_Secondary_Operators_Present_in_HM__c = sEmailIds;
                        } 
                        update objCase;
                    }
                }
                
                //Update related Contact details
                if(mapCustomerData != null && mapCustomerData.size() > 0){
                    HM_Integration_Helper.getContact(mapCustomerData);
                }
                
                //Create a Success Log Entry record
                HM_Integration_Helper.create_HMLogs('Case Creation from SF to HM', 'Success', sStatusCode, 'Outbound', sSerializedData, sJSONResponse, '');
                
            }
            else{
                
                sJSONResponse = httpResponse.getBody();
                
                Map<string, Object> mapErrorDetails = HM_Integration_Helper.getErrorDetails(sJSONResponse);
                
                if(mapErrorDetails != null && mapErrorDetails.size() > 0){
                    objCase.HM_Send_Create_Request__c = false;
                    objCase.HM_Integration_Message__c = mapErrorDetails.get('code') + '\r\n' + mapErrorDetails.get('detail');
                    update objCase;
                }
                
                //Create a Error log Entry record
                HM_Integration_Helper.create_HMLogs('Case Creation from SF to HM', 'Error', sStatusCode, 'Outbound', sSerializedData, sJSONResponse, '');
            }
        } 
        catch(Exception e){
            
            System.debug('The following exception has occurred: ' + e.getMessage());
            
            if(System.Label.HM_Case_Creation_failure != null){
                objCase.HM_Integration_Message__c = System.Label.HM_Case_Creation_failure;
            }
            objCase.HM_Send_Create_Request__c = false;            
            update objCase;
            
            //Create a Exception log Entry record
            HM_Integration_Helper.create_HMLogs('Case Creation from SF to HM', 'Error', '0', 'Outbound', sSerializedData, e.getMessage(), '');
        }
        
    }
    
}