/*
* Class Name               : HM_Integration_Helper
* Description              : Apex Class - Helper Class for all the Inbound and Outbound Integration 
* Author                   : Team Futran
* Created On               : 01 Aug 2022
* Test Class               : 
* Change Log History       :
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Team Futran     | 01/08/2022 | Initial Version of Apex Class         |
*  |--------------------------------------------------------------------------------|
*/

public class HM_Integration_Helper {
    
    //Create HM Logs to maintain success and error Logs
    public static void create_HMLogs(string sMethodName, string sStatus, string sStatusCode, string integrationType, string sRequestBody, string sResponseBody, string sSubscription_ID){
        
        //Get Feature Flagging for creating HM Logs
        Map<string, HM_Integration_Logs__c> mapCase_checkHMLogs = HM_Integration_Logs__c.getAll();
        
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
                
                insert objHMLog; 
            }
        }
    }
    
    //Get HTTP Request 
    public static HttpRequest getHttpRequest(string sMethodName, string sEndPointUrl, string sAPIKey, string acceptedFileFormat, string sRequestBody){
        
        HttpRequest httpReq = new HttpRequest();
        HttpReq.setMethod(sMethodName);
        HttpReq.setEndpoint(sEndPointUrl); 
        HttpReq.setHeader('Content-Type','application/json'); 
        HttpReq.setHeader('x-api-key', sAPIKey);
        HttpReq.setTimeout(120000); // timeout in milliseconds
        if(string.isNotBlank(acceptedFileFormat)){
            HttpReq.setHeader('accept', acceptedFileFormat);
        }
        if(string.isNOtBlank(sRequestBody)){
            HttpReq.setBody(sRequestBody);
        }
        
        return httpReq;
    }
    
    //Get Error Details
    public static Map<string, object> getErrorDetails(string sJSONResponse){
        Map<string, Object> mapErrorDetails = new Map<string, object>();
        
        if(string.isNotBlank(sJSONResponse)){
            Map<String, Object> mapHMErrorResponse = (Map<String, Object>)JSON.deserializeUntyped(sJSONResponse);
            system.debug('mapHMErrorResponse ==> ' + mapHMErrorResponse.get('errors'));
            
            if(mapHMErrorResponse != null && mapHMErrorResponse.size() > 0){
                for(Object objError : (List<Object>)mapHMErrorResponse.get('errors')){
                    mapErrorDetails = (Map<string, Object>)objError;
                }
            }
        }
        
        return mapErrorDetails;
    }
    
    //Get Case related Contact details
    public static string getContact(Map<String, Object> mapCustomerData) {
        
        string sContactId = '';
        
        if(mapCustomerData == null || mapCustomerData.size() <= 0){
            return sContactId;
        }
        
        string sMobileField, sMobileNumber, sOptStatusDetail, sUserId;
        Boolean sOptIn;
        
        /*

Map<String, HM_User_Mobile_Field_Mapping__c> map_HM_SFmobile = HM_User_Mobile_Field_Mapping__c.getAll();

if(map_HM_SFmobile == null || map_HM_SFmobile.size() <= 0){
return sContactId;
}

if(map_HM_SFmobile.get('mobile') != null){
if(string.isNotBlank(map_HM_SFmobile.get('mobile').HM_SF_Field__c)){
sMobileField = map_HM_SFmobile.get('mobile').HM_SF_Field__c;
}
}

*/
        
        if(mapCustomerData.get('mobile') != null){
            sMobileNumber = string.valueOf(mapCustomerData.get('mobile'));
            sOptIn = (Boolean)mapCustomerData.get('optStatus');
            sOptStatusDetail = (string)mapCustomerData.get('optStatusDetail');
            sUserId = (string)mapCustomerData.get('id');
        }
        
        system.debug('sMobileNumber1' + sMobileNumber);
        
        //Create a dynamic query to get related Contact details
        string sQuery = 'SELECT Id, HM_Opt_out_user__c, HM_User_Id__c, HM_Is_Opted_In__c, HM_Opt_Status_Detail__c, HM_Opt_In_Date__c, '+
            'HM_Opt_Out_Date__c FROM Contact where HM_MobileNumber__c = ' + '\'' + sMobileNumber + '\'' ;
        system.debug('sQuery ==> ' + sQuery);
        
        //Fetch all the case details using the dynamic query
        List<Contact> lstContact = Database.query(sQuery);
        system.debug('lstContact ==> ' + lstContact.size());
        
        if(lstContact != null && lstContact.size() > 0){
            for(Contact objContact : lstContact){
                objContact.HM_User_Id__c = sUserId;
                objContact.HM_Is_Opted_In__c = Boolean.valueOf(sOptIn);
                objContact.HM_Opt_Status_Detail__c = sOptStatusDetail;
                if(Boolean.valueOf(sOptIn) == true){
                    if(objContact.HM_Opt_In_Date__c == null){
                        objContact.HM_Opt_In_Date__c = system.now();
                    }
                }
                else if(Boolean.valueOf(sOptIn) == false && objContact.HM_Opt_Status_Detail__c != 'REQUESTED'){
                    objContact.HM_Opt_Out_Date__c = system.now();
                    objContact.HM_Opt_out_user__c = false;
                }
            }
            
            update lstContact;
            sContactId = lstContact[0].Id;
        }
        
        return sContactId;
    }
    
    //Create a Transcript Pdf in related Files section on Case
    public static void createTranscriptPDF(Blob blobData, Case sCaseDetails){
        
        if(blobData != null && sCaseDetails != null){
            
            //Create a pdf file using the blob response
            ContentVersion objContentVersion = new ContentVersion(); 
            objContentVersion.Title = 'Transcript ' + system.now(); 
            objContentVersion.IsMajorVersion = true;
            objContentVersion.VersionData = blobData;
            objContentVersion.PathOnClient = 'Transcript.pdf' ;
            insert objContentVersion;
            
            //Get Content Documents Id
            Id sContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: objContentVersion.Id].ContentDocumentId;
            
            //Tag the pdf in related Files section on Case
            ContentDocumentLink objCDL = new ContentDocumentLink();
            objCDL.ContentDocumentId = sContentDocumentId;
            objCDL.LinkedEntityId = sCaseDetails.Id; 
            objCDL.ShareType = 'V';
            objCDL.Visibility = 'AllUsers';
            insert objCDL;
            
            //Update the Success Integration Message on case after Case Transcript is Uploaded
            sCaseDetails.HM_Download_Case_Transcript__c = false;
            if(System.Label.HM_Download_Case_Transcript_Success_Msg != null){
                sCaseDetails.HM_Integration_Message__c = System.Label.HM_Download_Case_Transcript_Success_Msg;
            }
            
            update sCaseDetails;
        }
    }
    
    //Update secondary Operators Emails Present in Hi Marley Case
    public static string updateSecondaryOperators(Map<string, object> mapHMResponse){
        
        string sEmail = '';
        
        if(mapHMResponse == null || mapHMResponse.size() <= 0){
            return sEmail;
        }
        
        //Get Secondary Operator from Case
        List<Map<String, Object>> mapSecondaryOperators = new List<Map<String, Object>>();
        for(Object objOperators : (List<Object>)mapHMResponse.get('secondaryOperators')){
            mapSecondaryOperators.add((Map<String, Object>)objOperators);
        }        
        
        system.debug('mapSecondaryOperators' + mapSecondaryOperators.size());
        if(mapSecondaryOperators != null && mapSecondaryOperators.size() > 0){
            for(Map<string, Object> sEmailId : mapSecondaryOperators){
                sEmail += sEmailId.get('email') + ',';
            }
        }
        else{
            sEmail = '';
        }
        
        return sEmail;
    }
    
    //Check whether syncing/creating/Deletion operators in HM is Enabled if the user are created/deactivated in SF
    public static string syncUsersWithHMOperators(){
        
        Map<string, HM_Sync_Users_with_HM_Operators__c> mapSyncUsers = HM_Sync_Users_with_HM_Operators__c.getAll();
        
        string isSynced;
        
        if(mapSyncUsers == null || mapSyncUsers.size() <= 0){
            isSynced = 'false';
        }
        
        if(mapSyncUsers.get('Sync SF Users with HM Operators') != null){
            if(!mapSyncUsers.get('Sync SF Users with HM Operators').HM_Sync_SF_Users_with_HM_Operators__c){
                isSynced = 'false';
            }
        }
        
        return isSynced;
    }
    
    //Get All Case Team Members(Secondary Operators) tagged against Case
    public static List<Map<String, object>> getSecondaryOperatorsFromCaseTeams(string sCaseId){
        
        List<Map<String, object>> lstMapSecondaryOperators = new List<Map<String, object>>();
        
        if(string.isBlank(sCaseId)){
            return lstMapSecondaryOperators;
        }
        
        List<CaseTeamMember> lstCaseTeamMembers = [Select MemberId, Member.Name, Member.Email from CaseTeamMember 
                                                   where ParentId = :sCaseId Order by CreatedDate];
        
        //Add the Case Team Members a secondary Operators in JSON Mapping
        if(lstCaseTeamMembers != null && lstCaseTeamMembers.size() > 0){
            string sMemberId;
            for(CaseTeamMember objCaseTeamMember : lstCaseTeamMembers){
                sMemberId = objCaseTeamMember.MemberId;
                if(sMemberId.startsWith('005')){
                    Map<String, object> mapCaseSecondaryOperators = new Map<String, object>();
                    mapCaseSecondaryOperators.put('email', objCaseTeamMember.Member.Email);
                    lstMapSecondaryOperators.add(mapCaseSecondaryOperators);
                }
            }
        }
        
        return lstMapSecondaryOperators;
    }    
    
    //Create New Contact using Map customer Data if no Contact is found
    public static string createAndGetContact(Map<String, Object> mapCustomerData, Id ContactOwnerId) {
        system.debug('in Create and Get Contact method of integration helper');
        string snewContactId = '';
        
        if(mapCustomerData == null || mapCustomerData.size() <= 0){
            return snewContactId;
        }
        
        Contact objContact = new Contact();
        
        if(mapCustomerData.get('mobile') != null){
            
            objContact.FirstName = (string)mapCustomerData.get('first');
            objContact.LastName = (string)mapCustomerData.get('last');
            objContact.Email = (string)mapCustomerData.get('email');
            objContact.MobilePhone = (string)mapCustomerData.get('mobile');
            objContact.HM_Is_Opted_In__c = (Boolean)mapCustomerData.get('optStatus');
            objContact.HM_Opt_Status_Detail__c = (string)mapCustomerData.get('optStatusDetail');
            objContact.HM_User_Id__c = (string)mapCustomerData.get('id');
            
            if(ContactOwnerId!=null && String.isNotBlank(ContactOwnerId)){
                objContact.OwnerId = ContactOwnerId;
            }
            
            system.debug('objContact----'+objContact);
            
            insert objContact;
            snewContactId = objContact.Id;
            system.debug('snewContactId----'+snewContactId);
            
        }else{
            return snewContactId;
        }
        if(snewContactId == null){
            return snewContactId;
        }
        system.debug('at end snewContactId----'+snewContactId);
        return snewContactId;
    }
    
    //Update Contact using Map customer Data if Contact is found
    public static string updateContact(Map<String, Object> mapCustomerData) {
        
        string sUpdateContactId = '';
        
        if(mapCustomerData == null || mapCustomerData.size() <= 0){
            return sUpdateContactId;
        }
        
        string MobileNumber = String.valueOf(mapCustomerData.get('mobile'));
        List<Contact> lstObjContact;
        if(MobileNumber != null){
            lstObjContact = [SELECT Id, FirstName, LastName, Email, MobilePhone, HM_Is_Opted_In__c, HM_Opt_Status_Detail__c, HM_User_Id__c
                             FROM Contact WHERE HM_MobileNumber__c =: MobileNumber];
            
            system.debug('lstObjContact--'+lstObjContact.size());
        }
        
        if(lstObjContact == null || lstObjContact.size() <= 0){
            return sUpdateContactId;
        }
        
        if(mapCustomerData.get('mobile') != null && lstObjContact != null && lstObjContact.size() > 0){
            
            for(Contact objContact : lstObjContact){
                objContact.HM_User_Id__c = (string)mapCustomerData.get('id');
                objContact.FirstName = (string)mapCustomerData.get('first');
                objContact.LastName = (string)mapCustomerData.get('last');
                objContact.Email = (string)mapCustomerData.get('email');
                //objContact.MobilePhone = (string)mapCustomerData.get('mobile');
                objContact.HM_Is_Opted_In__c = (Boolean)mapCustomerData.get('optStatus');
                objContact.HM_Opt_Status_Detail__c = (string)mapCustomerData.get('optStatusDetail');
            }
            update lstObjContact;
            sUpdateContactId = lstObjContact[0].Id;
        }else{
            return sUpdateContactId;
        }
        return sUpdateContactId;
    }
    
    @future
    //Create Chat Log record for newly created Case from HM using Temp Chats records 
    public static void createChatLog(string HMCaseId, string SFCaseId){
        
        system.debug('Calling in Future Method *****************');
        system.debug('HMCaseId --- '+HMCaseId);
        system.debug('SFCaseId --- '+SFCaseId);
        
        if(string.isNotBlank(HMCaseId) && string.isNotBlank(SFCaseId)){
            
            List<Case> lstCase = [Select Id, ContactId from Case where HM_Case_Id__c = :HMCaseId Limit 1];
            
            if(lstCase != null && lstCase.size() > 0){
                
                List<HM_Chat_Log__c> lstChatLogs = new List<HM_Chat_Log__c>();
                
                List<HM_Temp_Chat_Log__c> lstTempChats = [Select Id, HM_Case_Id__c, HM_Message_Id__c, HM_Message_Type__c, HM_Media_URL__c,
                                                          HM_Message_Data__c, HM_Translated_Message__c, HM_Unread__c, HM_Image_Public_Url__c,
                                                          HM_Author_Id__c, HM_Author_First_Name__c, HM_Author_Last_Name__c, HM_To__c,
                                                          HM_From__c, HM_Contact__c, HM_Channel_Source__c, HM_Created_At__c,
                                                          HM_Date_Formatted__c, HM_Time_Formatted__c, HM_Milliseconds__c
                                                          from HM_Temp_Chat_Log__c where HM_Case_Id__c = :HMCaseId];
                
                if(lstTempChats != null && lstTempChats.size() > 0){
                    for(HM_Temp_Chat_Log__c objTempChat:lstTempChats){
                        
                        HM_Chat_Log__c objChatLog = new HM_Chat_Log__c();
                        
                        objChatLog.HM_Case_Id__c = objTempChat.HM_Case_Id__c;
                        objChatLog.HM_Case__c = SFCaseId;
                        objChatLog.HM_Message_Id__c = objTempChat.HM_Message_Id__c;
                        objChatLog.HM_Message_Type__c = objTempChat.HM_Message_Type__c;
                        objChatLog.HM_Media_URL__c = objTempChat.HM_Media_URL__c;
                        objChatLog.HM_Message_Data__c = objTempChat.HM_Message_Data__c;
                        objChatLog.HM_Translated_Message__c = objTempChat.HM_Translated_Message__c;
                        objChatLog.HM_Unread__c = objTempChat.HM_Unread__c;
                        objChatLog.HM_Image_Public_Url__c = objTempChat.HM_Image_Public_Url__c;
                        objChatLog.HM_Author_Id__c = objTempChat.HM_Author_Id__c;
                        objChatLog.HM_Author_First_Name__c = objTempChat.HM_Author_First_Name__c;
                        objChatLog.HM_Author_Last_Name__c = objTempChat.HM_Author_Last_Name__c;
                        objChatLog.HM_To__c = objTempChat.HM_To__c;
                        objChatLog.HM_From__c = objTempChat.HM_From__c;
                        objChatLog.HM_Contact__c = lstCase[0].ContactId;
                        objChatLog.HM_Channel_Source__c = objTempChat.HM_Channel_Source__c;
                        objChatLog.HM_Created_At__c = objTempChat.HM_Created_At__c;
                        objChatLog.HM_Milliseconds__c = objTempChat.HM_Milliseconds__c;
                        objChatLog.HM_Date_Formatted__c = objTempChat.HM_Date_Formatted__c;
                        objChatLog.HM_Time_Formatted__c = objTempChat.HM_Time_Formatted__c;  
                        lstChatLogs.add(objChatLog);
                    }
                }
                
                system.debug('In lstChatLogs: ' + lstChatLogs.size());
                if(lstChatLogs.size() > 0){
                    insert lstChatLogs;
                    delete lstTempChats;
                }  
            }
        }
    }
    
    public static Map<string, string> getMergedMessage(string sTemplateId, string sRecordID, string sObjectName){
        
        string sFields = '';
        Set<string> setQueryFields = new Set<string>();
        Map<string, string> mapContactIdMessage = new Map<string, string>();
        string sQuery, sMessage;
        
        if(string.isBlank(sTemplateId)){
            //Create an Error log Entry record
            HM_Integration_Helper.create_HMLogs('HM_Notifications', 'Error', '0', 'Outbound', '', 'Template Id Not Found!','');
        }
        
        system.debug('sTemplateId = ' + sTemplateId);
        List<HM_SMS_Template__c> lstSMSTemplate = [Select Id, HM_Template_Body__c, HM_Contact_API_Name__c from HM_SMS_Template__c 
                                                   where Name = :sTemplateId Limit 1];
        
        system.debug('lstSMSTemplate ' + lstSMSTemplate.size());
        
        if(lstSMSTemplate == null && lstSMSTemplate.size() <= 0){            
            system.debug('Template Not Found!');
            HM_Integration_Helper.create_HMLogs('HM_Notifications', 'Error', '0', 'Outbound', '', 'Template Not Found!','');
        }
        
        if(string.isBlank(lstSMSTemplate[0].HM_Contact_API_Name__c) || string.isBlank(lstSMSTemplate[0].HM_Template_Body__c)){
            system.debug('Template Body or Contact Not Found!');
            HM_Integration_Helper.create_HMLogs('HM_Notifications', 'Error', '0', 'Outbound', '', 'Template Body or Contact Not Found!!','');
        }
        
        //Get API Names from Template Message Body
        String summaryQuery = lstSMSTemplate[0].HM_Template_Body__c;
        Pattern patternInBrackets = Pattern.compile('\\{(.*?)\\}');
        Matcher summaryQueryMatcher = patternInBrackets.matcher(summaryQuery);
        while(summaryQueryMatcher.find()) { // returns false when no more matches
            //system.debug(summaryQueryMatcher.group());
            //system.debug(summaryQueryMatcher.group(1)); // just the text between the brackets   
            if(!sFields.contains(summaryQueryMatcher.group(1))){
                sFields += summaryQueryMatcher.group(1) + ', ';
                setQueryFields.add(summaryQueryMatcher.group(1));
            }
        }
        
        
        //Check if Object is Policy Or NOT	
        if(string.isNotBlank(lstSMSTemplate[0].HM_Contact_API_Name__c) && 
           !sFields.contains(lstSMSTemplate[0].HM_Contact_API_Name__c) &&
           lstSMSTemplate[0].HM_Contact_API_Name__c != 'ReportsTo'){
            sFields += lstSMSTemplate[0].HM_Contact_API_Name__c + ', ';
        }
        
        //To remove ', ' from query string's end
        if(string.isNotBlank(sFields)){
            sFields = sFields.removeEnd(', ');
        }
        else{
            // return as the fields are blank
        }   
        
        //Get Related Fields data from 
        sQuery = 'Select Id, ' + sFields + ' from ' + sObjectName + ' where Id = ' + '\'' + sRecordID + '\' Limit 1';                                     
        system.debug('sQuery ==> ' + sQuery);       
        
        List<sObject> lstsObject = Database.query(sQuery);
        system.debug('lstsObject -> ' + lstsObject);
        
        if(lstsObject.size() <= 0){
            system.debug('lstsObject Null - Return!');
            HM_Integration_Helper.create_HMLogs('HM_Notifications', 'Error', '0', 'Outbound', '', 'Related Object Data Not Found!','');
        }
        
        //Store the API fields and their values in the Map
        Map<string, Object> mapAPIFieldValues = new Map<string, Object>();
        
        for(string sAPIField : setQueryFields){            
            if(sAPIField.contains('.')){
                string [] sAld = sAPIField.split('\\.');
                mapAPIFieldValues.put(sAPIField, lstsObject[0].getSobject(sAld[0]).get(sAld[1]));                
            }
            else{
                mapAPIFieldValues.put(sAPIField, lstsObject[0].get(sAPIField));
            }                              
        }  
        
        //Replace All API fields with the values
        string sAPIField;
        for(string sKey : mapAPIFieldValues.keySet()){
            system.debug('sKey' + sKey);
            sAPIField = '{' + sKey + '}';
            if(mapAPIFieldValues.get(sKey) != null){
                summaryQuery = summaryQuery.replace(sAPIField, string.valueOf(mapAPIFieldValues.get(sKey)));  
            }
            else{
                summaryQuery = summaryQuery.replace(sAPIField, '{ISBLANK}');  
            }
            
        }
        
        //Set Message Content 
        sObject sObj;
        string sContactField;
        set<string> setContactIds = new set<string>();
        for(sObject obj : lstsObject){
            if(sObjectName == 'Contact'){
                sObj = new Contact();
                sContactField = obj.Id;
            }
            else{
                if(lstSMSTemplate[0].HM_Contact_API_Name__c == 'Contact'){
                    sContactField = string.valueOf(obj.get('ContactId'));  
                }
                else{
                    sContactField = string.valueOf(obj.get(lstSMSTemplate[0].HM_Contact_API_Name__c)); 
                }           
            }
        }
        
        mapContactIdMessage.put(sContactField, summaryQuery);
        return mapContactIdMessage;
    }
    
}