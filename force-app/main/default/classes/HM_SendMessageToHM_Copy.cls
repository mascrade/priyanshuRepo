/*
* Class Name               : HM_SendMessageToHM_Copy
* Description              : Apex Class(Outbound) - This Class calls the Send Message API Endpoint to send 
*							 a message to Hi Marley whenever a User hits the 'Send' button on Chat box on Case.  
*                            A ChatLog record in Salesforce will also be created on successful delivery of the
*                            message to Hi Marley.
* Author                   : Team Futran 
* Created On               : 22 August 2022
* Test Class               : HM_Test_SendMessageToHM
* Change Log History       : 
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Team Futran    | 22/08/2022 | Initial Version of Class               |
*  |--------------------------------------------------------------------------------|
*/
public class HM_SendMessageToHM_Copy {
    
    
    @AuraEnabled
    public static string sendMessage(String sMessage, String sCaseId){
        
        string sChatCreated = '';
        String sEndpoint, sTemplateId, sSerializedData, sStatusCode, sJSONResponse;
        HM_Chat_Log__c objChatLog;
        
        //get Current Logged In User or Operator
        User objUser = [select id,Name, FirstName, LastName from User where id =: UserInfo.getUserId()];
        
        //message or Case Id is null or blank
        if(String.isBlank(sMessage) || String.isBlank(sCaseId)){
            return sChatCreated;
        }
        
        //Get Integration details from HM_Integration Metadata
        HM_Integration__mdt objSendMsg = [Select Id, DeveloperName, API_Key__c, HM_End_Point_URL__c 
                                          from HM_Integration__mdt 
                                          where DeveloperName = 'HM_Send_SMS_Messages']; 
        
        //End Point URL or API Key is blank or null
        if(objSendMsg == null || String.isBlank(objSendMsg.HM_End_Point_URL__c) || String.isBlank(objSendMsg.API_Key__c)){
            return sChatCreated;
        }
        
        //use HM Message Template Id custom setting to fetch value of Template Id
        Map<String , HM_Message_Template_Id__c> mapMsgTemplate = 
            (Map<String, HM_Message_Template_Id__c>)HM_Message_Template_Id__c.getAll();
        
        if(mapMsgTemplate == null){
            return sChatCreated;
        }
        
        //Append Template Id to Endpoint Url if not null
        sTemplateId = mapMsgTemplate.get('hi marley template').Value__c;
        sEndpoint = objSendMsg.HM_End_Point_URL__c + sTemplateId;
        
        //Find Case with given sCaseId and get it's Parent Contact info
        List<Case> lstCase = [select id, HM_Case_Id__c, HM_Reference_ID__c, ContactId, Contact.Name 
                              from Case where Id =: sCaseId limit 1];
        
        //if there is no Case wih given sCaseId
        if(lstCase == null || lstCase.size() == 0){
            return sChatCreated;
        }
        
        //create ChatLog
        objChatLog = new HM_Chat_Log__c();
        objChatLog.HM_Case__c = lstCase[0].Id;	//establish M-D with Case
        objChatLog.HM_Contact__c = lstCase[0].ContactId;	//establish lookup with Contact
        objChatLog.HM_To__c = lstCase[0].Contact.Name;	//Contact or Customer's Name
        objChatLog.HM_From__c = objUser.Name;	//Current logged in user's Name or Operator
        objChatLog.HM_Author_First_Name__c = objUser.FirstName;
        objChatLog.HM_Author_Last_Name__c	 = objUser.LastName;
        objChatLog.HM_Origin__c = 'SFDC'; //from SF
        objChatLog.HM_Message_Type__c = 'text';
        objChatLog.HM_Channel_Source__c = 'marley';	//<---
        objChatLog.HM_Message_Data__c = sMessage;
        
        //Create json request body
        Map<String, object> mapJsonData = new Map<String, object>();
        mapJsonData.put('caseId',lstCase[0].HM_Case_Id__c); 
        mapJsonData.put('templateValues',new Map<String, object>{
            'message' => sMessage
                });	
        mapJsonData.put('source','assigned');	
        
        System.debug('mapJsonData = '+mapJsonData);
        
        //serialize json request body
        sSerializedData = JSON.serialize(mapJsonData);
        
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
            
            sJSONResponse = httpResponse.getBody();
            
            //after Response is received, insert ChatLog only if Msg Delivery was successful
            if(sStatusCode == '200' || sStatusCode == '201'){
                Map<String, Object> mapHMResponse = (Map<String, Object>)JSON.deserializeUntyped(sJSONResponse);
                
                // Msg id
                objChatLog.HM_Message_Id__c = (String) mapHMResponse.get('_id');
                
                // Created At : convert string to Date time before assigning to DateTime field
                Datetime createdAtDate = Datetime.valueOf(mapHMResponse.get('createdAt').toString().replace('T',' '));
                objChatLog.HM_Created_At__c = createdAtDate;
                
                //Author id
                objChatLog.HM_Author_Id__c = (String) mapHMResponse.get('authorId');
                
                //create Integration Log
                HM_Integration_Helper.create_HMLogs('Successful Message Delivery from SF to HM', 'Success', sStatusCode, 'Outbound', sSerializedData, sJSONResponse,'');
            }
            else{
                Map<String, Object> mapHMResponse = HM_Integration_Helper.getErrorDetails(sJSONResponse);
                              
                if(mapHMResponse != null || mapHMResponse.keySet().size() > 0){
                    
                    // update the error details on the chat log  
                    objChatLog.HM_Error_Details__c = (String) mapHMResponse.get('detail');
                    objChatLog.HM_Created_At__c = System.now();
                }
                
                //create Integration Log
                HM_Integration_Helper.create_HMLogs('Message Delivery from SF to HM failed', 'Failed', sStatusCode, 'Outbound', sSerializedData, sJSONResponse,'');
            }
            insert objChatLog;     
            sChatCreated = 'success';
        }
        catch(Exception e){
                        
            //Create an Error log Entry record
            HM_Integration_Helper.create_HMLogs('Failed Message Delivery from SF to HM', 'Error', '0', 'Outbound', sSerializedData, e.getMessage(),'');
        }
        
        return sChatCreated;
    }
    
}