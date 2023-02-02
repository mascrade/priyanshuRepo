/*
* Class Name               : HM_sendOptOutRequest
* Description              : Apex Class - Apex Class to send Opt-out request to HM
* Author                   : Rohit Korake (Futran Solutions)
* Created On               : 03 Aug 2022
* Test Class               : HM_Test_HM_sendOptOutRequest
* Change Log History       :
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Rohit Korake    | 03/08/2022 | Initial Version of Class              |
*  |--------------------------------------------------------------------------------|
*/

public class HM_sendOptOutRequest {

    @InvocableMethod(label='Opt-out User/Contact' description='Opt-out on behalf of the user' category= 'Contact')
    public static void send_OptOutRequest(List<string> lstContactIds){
        
        if(lstContactIds == null || lstContactIds.size() <= 0){
            return;
        }
        
        List<Contact> lstContacts = new List<Contact>();
        string sMobileNumber, sContactId, sQuery, sEndPointUrl, sStatusCode, sJSONResponse;
        
        if(string.isBlank(lstContactIds[0])){
            return;
        }
        
        sContactId = lstContactIds[0];
        
        Map<string, HM_User_Mobile_Field_Mapping__c> map_getUserMobileField = HM_User_Mobile_Field_Mapping__c.getAll();
        
        if(map_getUserMobileField != null && map_getUserMobileField.size() > 0){
            if(map_getUserMobileField.get('mobile') != null){
                if(string.isNotBlank(map_getUserMobileField.get('mobile').HM_SF_Field__c)){
                    sMobileNumber = map_getUserMobileField.get('mobile').HM_SF_Field__c;
                }
            }
        }
        
        if(string.isNotBlank(sMobileNumber) && string.isNotBlank(sContactId)){
            
            //Get related fields from Contact
            sQuery = 'Select Id, HM_Opt_out_user__c, HM_Is_Opted_In__c, HM_Opt_Status_Detail__c, HM_Opt_Out_Date__c, ' + 
                	 sMobileNumber + ' from Contact'  + ' where Id = ' + '\'' + sContactId + '\'';
            system.debug('sQuery' + sQuery);
            
            //Fetch all the contact details using the dynamic query
            lstContacts = Database.query(sQuery);
            
        }
        
        if(lstContacts == null || lstContacts.size() <= 0){
            return;
        }
        
        Contact objContact = lstContacts[0];
        
        if(objContact == null){
            return;
        }
        
        //Get Case Integration details from HM_Integration Metadata
        HM_Integration__mdt objContact_OptOutAPI = [Select Id, DeveloperName, API_Key__c, HM_End_Point_URL__c 
                                                    from HM_Integration__mdt 
                                                    where DeveloperName = 'HM_Opt_out_User'];  
        
        if(string.isBlank(objContact_OptOutAPI.HM_End_Point_URL__c) || string.isBlank(objContact_OptOutAPI.API_Key__c) || 
           lstContacts[0].get(sMobileNumber) == null){
            return;
        }
        
        sEndPointUrl = objContact_OptOutAPI.HM_End_Point_URL__c + lstContacts[0].get(sMobileNumber);
        system.debug('sEndPointUrl ==>' + sEndPointUrl);
        
        //HTTP Request
        Http http = new Http();    
        
        Httprequest httpReq = HM_Integration_Helper.getHttpRequest('PUT', sEndPointUrl, objContact_OptOutAPI.API_Key__c, ' ', ' ');
   
        HttpResponse httpResponse = new HttpResponse();
        
         try{
            
            httpResponse = http.send(HttpReq);
            sStatusCode = string.valueOf(httpResponse.getStatusCode());
            system.debug('Status Code ==> ' + sStatusCode );
            
            if(sStatusCode == '201' || sStatusCode == '200'){
                
                sJSONResponse = httpResponse.getBody();
                
                Map<String, Object> mapHMResponse = (Map<String, Object>)JSON.deserializeUntyped(sJSONResponse);
                system.debug('mapHMResponse ==> ' + mapHMResponse);
             
                if(mapHMResponse == null || mapHMResponse.size() <= 0 ){
                    return;
                }
                
                //Update the Contact Details
                HM_Integration_Helper.getContact(mapHMResponse);
                
                //Create a Success Log Entry record
                HM_Integration_Helper.create_HMLogs('Opt-Out User from SF to HM', 'Success', sStatusCode, 'Outbound', '', sJSONResponse, '');
                
            }
            else{
                
                sJSONResponse = httpResponse.getBody();
                system.debug('responseBody: ' + sJSONResponse);
                
                //Update Contact Opt-out checkbox as false to again opt-out
                objContact.HM_Opt_out_user__c = false;
                update objContact;
                
                //Create a Error Log Entry record
                HM_Integration_Helper.create_HMLogs('Opt-Out User from SF to HM', 'Error', sStatusCode,  'Outbound', '', sJSONResponse, '');
                
            }
            
        } 
        catch(Exception e){
            
            system.debug('The following exception has occurred: ' + e.getMessage());
            
            //Update Contact Opt-out checkbox as false to again opt-out
            objContact.HM_Opt_out_user__c = false;
            update objContact;
            
            //Create a Exception Log Entry record
            HM_Integration_Helper.create_HMLogs('Opt-Out User from SF to HM', 'Error', '0', 'Outbound', '', e.getMessage(), '');            
        }

    }
}