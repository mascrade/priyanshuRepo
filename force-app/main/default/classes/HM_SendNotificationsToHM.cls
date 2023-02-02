/*
* Class Name               : HM_SendNotificationsToHM
* Description              : Apex Class(Outbound) - This Class calls the Send Message API Endpoint to send 
*							 a message to Hi Marley. A ChatLog record in Salesforce will also be created 
							 on successful delivery of the message to Hi Marley. This class doesn't use
							 template id to send message from Salesforce to Hi Marley.
* Author                   : Team Futran 
* Created On               : 16 December 2022
* Test Class               : HM_SendNotificationsToHM
* Change Log History       : 
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Team Futran    | 16/12/2022 | Initial Version of Class               |
*  |--------------------------------------------------------------------------------|
*/
public class HM_SendNotificationsToHM {
    
    public static HM_SendNotificationsToHM.Wrapper_SendNotifications sendMessage(String sMessage, String sCaseId){
        
        System.debug('sCaseId => ' + sCaseId);
        //Message or Case Id is null or blank
        if(String.isBlank(sMessage) || String.isBlank(sCaseId)){
            system.debug('SMS Blank - Return!');
            return null;
        }  
        
        Map<string, Wrapper_SendNotifications> mapCaseIdvsWrapper = new Map<string, Wrapper_SendNotifications>();
        Wrapper_SendNotifications objWrapper = new Wrapper_SendNotifications();
        
        string sChatCreated = '';
        String sEndpoint, sTemplateId, sSerializedData, sStatusCode, sJSONResponse;
        HM_Chat_Log__c objChatLog;
        
        //Find Case with given sCaseId and get it's Parent Contact info
        List<Case> lstCase = [select id, HM_Case_Id__c, HM_Reference_ID__c, ContactId, Contact.Name 
                              from Case where Id = :sCaseId limit 1];
        
        System.debug('lstCase = ' + lstCase.size());
        
        //if there is no Case wih given sCaseId
        if(lstCase == null || lstCase.size() <= 0){
            System.debug('Case list is empty');
            return null;
        }
        
        // store the case details in a local variable
        Case objCase = lstCase[0];
        
        if(objCase == null){
            return null;
        }
        
        //Get Integration details from HM_Integration Metadata
        HM_Integration__mdt objSendMsg = [Select Id, DeveloperName, API_Key__c, HM_End_Point_URL__c 
                                          from HM_Integration__mdt 
                                          where DeveloperName = 'HM_Send_SMS_Messages_without_template']; 
        
        //End Point URL or API Key is blank or null
        if(objSendMsg == null || String.isBlank(objSendMsg.HM_End_Point_URL__c) || String.isBlank(objSendMsg.API_Key__c)){
            if(System.Label.HM_IM_Generic_1 != null){
                objCase.HM_Integration_Message__c = System.Label.HM_IM_Generic_1;
            }
            return null;
        }
        
        sEndpoint = objSendMsg.HM_End_Point_URL__c;
        System.debug('sEndpoint : ' + sEndpoint);
        
        //create ChatLog
        objChatLog = new HM_Chat_Log__c();
        objChatLog.HM_Case__c = objCase.Id;	//establish M-D with Case
        objChatLog.HM_Contact__c = objCase.ContactId;	//establish lookup with Contact
        objChatLog.HM_To__c = objCase.Contact.Name;	//Contact or Customer's Name
        objChatLog.HM_From__c = 'Marley';	//HM 
        objChatLog.HM_Author_First_Name__c = 'Marley';
        objChatLog.HM_Origin__c = 'SFDC'; //from SF
        objChatLog.HM_Message_Type__c = 'text';
        objChatLog.HM_Channel_Source__c = 'ai';	//<---
        objChatLog.HM_Message_Data__c = sMessage;
        
        //Create json request body
        Map<String, object> mapJsonData = new Map<String, object>();
        mapJsonData.put('caseId', objCase.HM_Case_Id__c);
        mapJsonData.put('messageBody', sMessage);
        mapJsonData.put('source', 'ai');
        
        System.debug('mapJsonData => ' + mapJsonData.size());
        
        if(mapJsonData.size() <= 0){
            return null;
        }
        
        //serialize json request body
        sSerializedData = JSON.serialize(mapJsonData);
        System.debug('Data in Map = '+ JSON.serializepretty(mapJsonData));
        
        //call Hi Marley endpoint
        //1. HTTP Request
        Http http = new Http();
        
        HttpRequest httpReq = HM_Integration_Helper.getHttpRequest('POST', sEndpoint, objSendMsg.API_Key__c, '', sSerializedData);
        
        //2. HTTP Response
        HttpResponse httpResponse = new HttpResponse();
        
        try{
            
            //send request
            httpResponse = http.send(httpReq);
            
            //receive Response from HM
            sStatusCode = string.valueOf(httpResponse.getStatusCode());
            system.debug('Status Code ==> ' + sStatusCode ); 
            
            sJSONResponse = httpResponse.getBody();
            
            //after Response is received, insert ChatLog only if Msg Delivery was successful
            if(sStatusCode == '200' || sStatusCode == '201'){
                
                Map<String, Object> mapHMResponse = (Map<String, Object>)JSON.deserializeUntyped(sJSONResponse);
                System.debug('mapHMResponse ==> ' + mapHMResponse);
                
                // Msg id
                objChatLog.HM_Message_Id__c = (String) mapHMResponse.get('_id');
                
                // Created At : convert string to Date time before assigning to DateTime field
                Datetime createdAtDate = Datetime.valueOf(mapHMResponse.get('createdAt').toString().replace('T',' '));
                objChatLog.HM_Created_At__c = createdAtDate;
                
                //Author id
                objChatLog.HM_Author_Id__c = (String) mapHMResponse.get('authorId');
                
                //create Integration Log
                objWrapper.objIntegLog = create_HMLogs('Successful Message Delivery from SF to HM', 'Success', sStatusCode, 'Outbound', sSerializedData, sJSONResponse,'');
                
                objWrapper.msgSent = true;
                objWrapper.successOrErrorDetails = 'Successful Message Delivery from SF to HM';
                objWrapper.objWrapChatLog = objChatLog; // ChatLog stores Success
                return objWrapper;
                
            }else{
                
                //Error - Code Other than 200/201
                System.debug('in else code not 200/1 => ');
                Map<String, Object> mapHMResponse = HM_Integration_Helper.getErrorDetails(sJSONResponse);                
                System.debug('mapHMResponse code not 200/1 => ' + mapHMResponse);
                
                if(mapHMResponse != null && mapHMResponse.keySet().size() > 0){
                    // update the error details on the chat log  
                    objChatLog.HM_Error_Details__c = (String) mapHMResponse.get('detail');
                    objChatLog.HM_Created_At__c = System.now();
                    
                }
                
                //create Integration Log
                objWrapper.objIntegLog = create_HMLogs('Message Delivery from SF to HM failed', 'Failed', sStatusCode, 'Outbound', sSerializedData, sJSONResponse,'');
                
                objWrapper.msgSent = false;
                objWrapper.successOrErrorDetails = sJSONResponse;
                objWrapper.objWrapChatLog = objChatLog;
                return objWrapper;
            }
            
        }
        catch(Exception e){
            
            System.debug('The following exception has occurred: ' + e.getMessage());            
            
            //Create an Error log Entry record
            objWrapper.objIntegLog = create_HMLogs('Failed Message Delivery from SF to HM', 'Error', '0', 'Outbound', sSerializedData, e.getMessage(),'');
            objWrapper.msgSent = false;
            objWrapper.successOrErrorDetails = e.getMessage();
            return objWrapper;
        }
    }
    
    //Create HM Logs to maintain success and error Logs
    public static HM_Logs__c create_HMLogs(string sMethodName, string sStatus, string sStatusCode, string integrationType, string sRequestBody, string sResponseBody, string sSubscription_ID){
        
        //Get Feature Flagging for creating HM Logs
        Map<string, HM_Integration_Logs__c> mapCase_checkHMLogs = HM_Integration_Logs__c.getAll();
        System.debug('mapCase_checkHMLogs = '+mapCase_checkHMLogs);
        
        //Create a Log Entry record
        if(mapCase_checkHMLogs != null && mapCase_checkHMLogs.size() > 0){
            if(mapCase_checkHMLogs.get('HM Logs').Enable_HM_Logs__c){    
                
                HM_Logs__c objHMLog = new HM_Logs__c();
                
                if(sMethodName.length() > 255){
                    objHMLog.HM_Method_Name__c = sMethodName.substring(0, 250); 
                }
                else{
                    objHMLog.HM_Method_Name__c = sMethodName;                   
                }
                
                objHMLog.HM_Status__c = sStatus;
                objHMLog.HM_Status_Code__c = sStatusCode;
                objHMLog.Type_of_Integration__c = integrationType;
                
                if(string.isNotBlank(sSubscription_ID)){
                    objHMLog.HM_Webhook_Subscription_Id__c = sSubscription_ID;
                }
                
                if(sRequestBody.length() > 130100){
                    objHMLog.HM_Request_Body__c = sRequestBody.substring(0, 130100);    
                }
                else{
                    objHMLog.HM_Request_Body__c = sRequestBody;        
                }                
                
                if(sResponseBody.length() > 130100){
                    objHMLog.HM_Response_Body__c = sResponseBody.substring(0, 130100);    
                }
                else{
                    objHMLog.HM_Response_Body__c = sResponseBody;        
                }
                
                return objHMLog; 
            }
        }
        return null;
    }
    
    
    public class Wrapper_SendNotifications {
        public Boolean msgSent;
        public String successOrErrorDetails;
        public HM_Chat_Log__c objWrapChatLog;
        public HM_Logs__c objIntegLog;
    }
}