/*
* Name               : HM_smsChatController
* Description        : Apex Controller for Custom Chat UI
* Created On         : Sep 2022
* Test Class         : HM_Test_smsChatController
* Change Log History :
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Team Futran        | Sep 2022 | Initial Version of Apex Class      |
*  |------------------------------------------------------------------------------|
*/

public class HM_smsChatController {
    
    //Get the chat log count related to the case
    @AuraEnabled(cacheable=true)
    public static Integer getChat_Count(string sCaseId){
        
        Integer chat_Count = 0;
        
        if(string.isNotBlank(sCaseId)){           
            AggregateResult aggregateChats = [Select COUNT(Id) chatCount from HM_Chat_Log__c where HM_Case__c = :sCaseId];                       
            if(aggregateChats != null){
                chat_Count = (Integer)aggregateChats.get('chatCount');
            }            
        }
        
        system.debug('chat_Count ==> ' + chat_Count);
        return chat_Count;
    }   
    
    //Get the Today chat log count related to the case
    @AuraEnabled(cacheable=true)
    public static Integer getTodayChat_Count(string sCaseId){
        
        Integer chat_Count = 0;
        
        if(string.isNotBlank(sCaseId)){           
            AggregateResult aggregateChats = [Select COUNT(Id) chatCount from HM_Chat_Log__c where HM_Case__c = :sCaseId and HM_Created_At__c = TODAY];                       
            if(aggregateChats != null){
                chat_Count = (Integer)aggregateChats.get('chatCount');
            }            
        }
        
        system.debug('chat_Count ==> ' + chat_Count);
        return chat_Count;
    }
    
    //Get the case details 
    @AuraEnabled(cacheable=true)
    public static List<wrapper_CaseDetails> getCaseDetails(string sCaseId){
        
        List<wrapper_CaseDetails> lstWrapper_CaseDetails = new List<wrapper_CaseDetails>();
        string sTime;
        string sMonth;
        string sDay;
        
        if(string.isNotBlank(sCaseId)){
            List<Case> lstCases = [Select Id, Contact.Name, Contact.FirstName, Contact.HM_Is_Opted_In__c, Contact.HM_Opt_Status_Detail__c,
                                   Contact.HM_Opt_In_Date__c, HM_Text_Language__c, IsClosed, HM_Case_Id__c
                                   from Case 
                                   where Id = :sCaseId];            
            
            if(lstCases != null && lstCases.size() > 0){
                for(Case objCase : lstCases){
                    wrapper_CaseDetails objWrapper_CaseDetail = new wrapper_CaseDetails();
                    objWrapper_CaseDetail.sContactFirstName = objCase.Contact.FirstName;
                    objWrapper_CaseDetail.sContactName = objCase.Contact.Name;
                    objWrapper_CaseDetail.bIsOptedIn = objCase.Contact.HM_Is_Opted_In__c;
                    objWrapper_CaseDetail.sOptInStatus = objCase.Contact.HM_Opt_Status_Detail__c;
                    objWrapper_CaseDetail.sTextLanguage = objCase.HM_Text_Language__c;
                    objWrapper_CaseDetail.bIsClosed = objCase.IsClosed;
                    objWrapper_CaseDetail.sHMCaseId = objCase.HM_Case_Id__c;
                    if(objCase.Contact.HM_Opt_In_Date__c != null){
                        sTime = objCase.Contact.HM_Opt_In_Date__c.format('HH:mm a');
                        sMonth = objCase.Contact.HM_Opt_In_Date__c.format('MMM');
                        sDay = string.valueOf(objCase.Contact.HM_Opt_In_Date__c.day());
                        objWrapper_CaseDetail.sOptInDate = sMonth + ' ' + sDay;
                        objWrapper_CaseDetail.sOptInTime = sTime;
                    }
                    lstWrapper_CaseDetails.add(objWrapper_CaseDetail);
                } 
            }            
        }
        
        system.debug('lstWrapper_CaseDetails ==> ' + lstWrapper_CaseDetails.size());
        return lstWrapper_CaseDetails;
    }
    
    //Get All chat logs related to the case
    @AuraEnabled(cacheable=true)
    public static List<wrapper_ChatLog> getChatLogs(string sCaseId){
        
        List<wrapper_ChatLog> lstWrapper_ChatLog = new List<wrapper_ChatLog>();
        string sTime;
        string sMonth;
        string sDay;
        Integer offset;
        Datetime localCreateAt;

        if(string.isNotBlank(sCaseId)){
            List<HM_Chat_Log__c> lstChatLogs = [Select Id, HM_Case__c, HM_Case__r.Contact.HM_Is_Opted_In__c, HM_Author_First_Name__c, 
                                                HM_Author_Last_Name__c, HM_Message_Type__c, HM_Case__r.Contact.HM_Opt_Status_Detail__c,
                                                HM_Channel_Source__c, HM_Message_Data__c, CreatedDate, HM_Message_Id__c, HM_Image_Public_Url__c,
                                                HM_Author_Initials__c, HM_Unread__c, HM_Translated_Message__c, HM_Created_At__c, HM_Error_Details__c
                                                from HM_Chat_Log__c 
                                                where HM_Case__c = :sCaseId
                                                Order by HM_Created_At__c, HM_Time_Formatted__c, HM_Milliseconds__c ASC];            
            
            if(lstChatLogs != null && lstChatLogs.size() > 0){
                
                for(HM_Chat_Log__c objChatLog : lstChatLogs){
                    wrapper_ChatLog objWrapper_ChatLog = new wrapper_ChatLog();
                    objWrapper_ChatLog.sChatLogId = objChatLog.Id;
                    if(string.isNotBlank(objChatLog.HM_Author_First_Name__c) && string.isNotBlank(objChatLog.HM_Author_Last_Name__c)){
                        objWrapper_ChatLog.sAuthorName = objChatLog.HM_Author_First_Name__c + ' ' + objChatLog.HM_Author_Last_Name__c;
                    }
                    else if(string.isBlank(objChatLog.HM_Author_Last_Name__c)){
                        objWrapper_ChatLog.sAuthorName = objChatLog.HM_Author_First_Name__c;
                    }
                    else{
                        objWrapper_ChatLog.sAuthorName = objChatLog.HM_Author_Last_Name__c;
                    }
                    objWrapper_ChatLog.sAuthorInitials = objChatLog.HM_Author_Initials__c;
                    objWrapper_ChatLog.sMessage = objChatLog.HM_Message_Data__c;
                    objWrapper_ChatLog.sMessageId = objChatLog.HM_Message_Id__c;
                    objWrapper_ChatLog.bIsUnread = objChatLog.HM_Unread__c;
                    objWrapper_ChatLog.sMessageType = objChatLog.HM_Message_Type__c;
                    objWrapper_ChatLog.sChannelSource = objChatLog.HM_Channel_Source__c;
                    //Get CreatedAt Date in users locale time
                    offset = UserInfo.getTimezone().getOffset(objChatLog.HM_Created_At__c);
                    localCreateAt = objChatLog.HM_Created_At__c.addSeconds(offset/1000);
                    objWrapper_ChatLog.dtCreatedDtTime = Date.valueOf(localCreateAt);
                    objWrapper_ChatLog.sTranslatedMessage = objChatLog.HM_Translated_Message__c;
                    objWrapper_ChatLog.bIsOptedIn = objChatLog.HM_Case__r.Contact.HM_Is_Opted_In__c;
                    objWrapper_ChatLog.sOptStatus = objChatLog.HM_Case__r.Contact.HM_Opt_Status_Detail__c;
                    objWrapper_ChatLog.sImagePublicUrl = objChatLog.HM_Image_Public_Url__c;
                    objWrapper_ChatLog.sErrorDetails = objChatLog.HM_Error_Details__c;
                    if(objChatLog.HM_Created_At__c != null){
                        sTime = objChatLog.HM_Created_At__c.format('hh:mm a');
                        sMonth = objChatLog.HM_Created_At__c.format('MMM dd');
                        sDay = string.valueOf(objChatLog.HM_Created_At__c.day());
                        objWrapper_ChatLog.dtCreatedDate = sMonth;
                        objWrapper_ChatLog.dtCreatedTime = sTime;
                    }
                    
                    lstWrapper_ChatLog.add(objWrapper_ChatLog);
                } 
            }            
        }
        
        system.debug('lstWrapper_ChatLog ==> ' + lstWrapper_ChatLog.size());
        return lstWrapper_ChatLog;
    }
    
    //Fetch the related Text Language Picklist Lables and values from Case object
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getLanguageValues(String objApiName, String fieldName){
        
        List<Map<String, String>> options = new List<Map<String, String>>();
        Map<String, Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objApiName);
        
        if (objType == null) {
            return options;
        }
        
        Schema.DescribeSObjectResult sobjectDescribe = objType.getDescribe();
        
        Map<String, Schema.SObjectField> fieldMap = sobjectDescribe.fields.getMap();
        
        if (fieldMap.get(fieldName) == null) {
            return options;
        }
        
        List<Schema.PicklistEntry> pickListValues = fieldMap.get(fieldName).getDescribe().getPickListValues();
        
        for(Schema.PicklistEntry f : pickListValues) {
            Map<String, String> values = new Map <String, String>{
                'label' => f.getLabel(),
                'value' => f.getValue()
            };
                
            options.add(values);
        }
        
        return options;
    }
    
    //To update the Text Language on case whenever the Agent change the value from Chat UI
    @AuraEnabled(Cacheable=false)
    public static void updateTextLanguageOnCase(string sCaseId, string textLanguage){
        if(string.isNotBlank(sCaseId)){           
            Case objCase = [Select Id,  HM_Text_Language__c from Case where Id = :sCaseId];           
            objCase.HM_Text_Language__c = textLanguage;            
            update objCase;           
        }
    }
    
    //To update the Unread Message Count on Case and To mark Chat Log as Read
    @AuraEnabled(Cacheable=false)
    public static void updateUnreadMessageCount(string sCaseId){
        
        if(string.isNotEmpty(sCaseId)){
            
            Case objCases = [Select Id, HM_Count_of_Unread_Messages__c from Case where Id = :sCaseId];
            
            List<HM_Chat_Log__c> lstChatLogs = [Select Id, HM_Unread__c from HM_Chat_Log__c where HM_Case__c = :sCaseId and HM_Unread__c = true];
          
            if(lstChatLogs != null && lstChatLogs.size() > 0){
                for(HM_Chat_Log__c objChatLog : lstChatLogs){
                    objChatLog.HM_Unread__c = false;
                }  
                update lstChatLogs;
            }
            
            if(objCases != null){
                objCases.HM_Count_of_Unread_Messages__c = 0;
                update objCases;
            }
            
        }        
    }
    
    //Start Conversation - Create Case in Hi Marley
    //Mark Create Case in Hi Marley checkbox as true
    @AuraEnabled(Cacheable=false)
    public static string updateCreateCaseInHM(string sCaseId){
        string sResult = '';
        if(string.isNotBlank(sCaseId)){           
            Case objCase = [Select Id, HM_Send_Create_Request__c from Case where Id = :sCaseId];           
            objCase.HM_Send_Create_Request__c = true;     
            try{
                update objCase;
                sResult = 'Success'; 
            }
            catch(Exception Ex){
                system.debug('Error!!');
            }                       
        }        
        return sResult;
    }
        
    
    public class wrapper_CaseDetails{
        @AuraEnabled
        public string sContactFirstName;
        @AuraEnabled
        public string sContactName;
        @AuraEnabled
        public boolean bIsOptedIn;
        @AuraEnabled
        public string sOptInStatus;
        @AuraEnabled
        public string sOptInDate;
        @AuraEnabled
        public string sOptInTime;
        @AuraEnabled
        public string sTextLanguage;
        @AuraEnabled
        public boolean bIsClosed;
        @AuraEnabled
        public string sHMCaseId;
    }
    
    public class wrapper_ChatLog{
        @AuraEnabled 
        public string sChatLogId;
        @AuraEnabled 
        public string sAuthorName;
        @AuraEnabled
        public string sAuthorInitials;
        @AuraEnabled
        public string sMessage;
        @AuraEnabled
        public string sMessageId;
        @AuraEnabled
        public boolean bIsUnread;
        @AuraEnabled
        public string sMessageType;
        @AuraEnabled
        public string sChannelSource;
        @AuraEnabled
        public string dtCreatedDate;
        @AuraEnabled
        public string dtCreatedTime;
        @AuraEnabled
        public Date dtCreatedDtTime;
        @AuraEnabled
        public string sTranslatedMessage;
        @AuraEnabled
        public boolean bIsOptedIn;
        @AuraEnabled
        public string sOptStatus;
        @AuraEnabled
        public string sImagePublicUrl;
        @AuraEnabled
        public string sErrorDetails;
    }
    
}