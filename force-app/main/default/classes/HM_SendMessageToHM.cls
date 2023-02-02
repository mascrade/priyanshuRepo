/*
* Class Name               : HM_SendMessageToHM
* Description              : Apex Class(Outbound) - This Class calls the Send Message API Endpoint to send 
*							 a message to Hi Marley whenever a User hits the 'Send' button on Chat box on Case.  
*                            A ChatLog record in Salesforce will also be created on successful delivery of the
*                            message to Hi Marley. This is a copied version that doesn't use template id to send message 
							 from Salesforce to Hi Marley.
* Author                   : Team Futran 
* Created On               : 20 September 2022
* Test Class               : HM_Test_SendMessageToHM
* Change Log History       : 
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Team Futran    | 22/09/2022 | Initial Version of Class               |
*  |--------------------------------------------------------------------------------|
*/
public class HM_SendMessageToHM {
    
    
    @AuraEnabled
    public static string sendMessage(String sMessage, String sCaseId){
        
        System.debug('sCaseId = '+sCaseId);
        string sChatCreated = '';
        String sEndpoint, sTemplateId, sSerializedData, sStatusCode, sJSONResponse;
        HM_Chat_Log__c objChatLog;
        
        //Message or Case Id is null or blank
        if(String.isBlank(sMessage) || String.isBlank(sCaseId)){
            system.debug('SMS Blank - Return!');
            return sChatCreated;
        }        
        
        //Get Current Logged In User or Operator
        User objUser = [select id,Name, FirstName, LastName, Email from User where id =: UserInfo.getUserId()];
        System.debug('objUser = ' + objUser);
        
        //Find Case with given sCaseId and get it's Parent Contact info
        List<Case> lstCase = [select id, HM_Case_Id__c, HM_Reference_ID__c, ContactId, Contact.Name, Owner.Email 
                              from Case where Id = :sCaseId limit 1];
        
        System.debug('lstCase = '+lstCase);
        
        //if there is no Case wih given sCaseId
        if(lstCase == null || lstCase.size() == 0){
            System.debug('Case list is empty');
            return sChatCreated;
        }
        
        // store the case details in a local variable
        Case objCase = lstCase[0];
        
        if(objCase == null){
            return sChatCreated;
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
            update objCase;
            return sChatCreated;
        }
        
        sEndpoint = objSendMsg.HM_End_Point_URL__c;
        System.debug('sEndpoint : ' + sEndpoint);
        
        //create ChatLog
        objChatLog = new HM_Chat_Log__c();
        objChatLog.HM_Case__c = objCase.Id;	//establish M-D with Case
        objChatLog.HM_Contact__c = objCase.ContactId;	//establish lookup with Contact
        objChatLog.HM_To__c = objCase.Contact.Name;	//Contact or Customer's Name
        objChatLog.HM_From__c = objUser.Name;	//Current logged in user's Name or Operator
        objChatLog.HM_Author_First_Name__c = objUser.FirstName;
        objChatLog.HM_Author_Last_Name__c	 = objUser.LastName;
        objChatLog.HM_Origin__c = 'SFDC'; //from SF
        objChatLog.HM_Message_Type__c = 'text';
        objChatLog.HM_Channel_Source__c = 'marley';	//<---
        objChatLog.HM_Message_Data__c = sMessage;
        
        //Create json request body
        Map<String, object> mapJsonData = new Map<String, object>();
        mapJsonData.put('caseId', objCase.HM_Case_Id__c);
        mapJsonData.put('messageBody', sMessage);
        System.debug('mapJsonData = '+mapJsonData);
      
        if(objCase.Owner.Email != objUser.Email){
            mapJsonData.put('source',new Map<String, object>{
                'email' => objUser.Email
                    });  
        }else{
            mapJsonData.put('source', 'assigned');	
        }
      
        System.debug('mapJsonData => ' + mapJsonData.size());
        
        if(mapJsonData.size() <= 0){
            return sChatCreated;
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
                HM_Integration_Helper.create_HMLogs('Successful Message Delivery from SF to HM', 'Success', sStatusCode, 'Outbound', sSerializedData, sJSONResponse,'');
            }
            else{
                
                Map<String, Object> mapHMResponse = HM_Integration_Helper.getErrorDetails(sJSONResponse);                
                System.debug('mapHMResponse = '+mapHMResponse);
                
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
            
            System.debug('The following exception has occurred: ' + e.getMessage());            
            
            //Create an Error log Entry record
            HM_Integration_Helper.create_HMLogs('Failed Message Delivery from SF to HM', 'Error', '0', 'Outbound', sSerializedData, e.getMessage(),'');
        }
        
        return sChatCreated;
    }
    
    
}