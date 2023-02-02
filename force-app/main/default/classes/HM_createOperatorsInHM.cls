/*
* Name               : HM_createOperatorsInHM
* Description        : Apex Class - Create a Operator whenever a new user in created in SF
* Author             : Darshana Dange (Futran Solutions)
* Created On         : 09 August 2022
* Test Class         : HM_Test_HM_createOperatorsInHM
* Change Log History :
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Darshana Dange     | 09 Aug 2022 | Initial Version of Apex Class   |
*  |------------------------------------------------------------------------------|
*/

public class HM_createOperatorsInHM {
    
    @InvocableMethod(label='Create Operators in HM' description='Create Operators in HM' category= 'User')
    public static void HM_CreateOperatorsInHM(List<string> lstUserIds){
        
        if(lstUserIds == null || lstUserIds.size() <= 0){
            return;
        }
        
        //Check whether syncing user with HM Operators is Enabled if the user are created/deactivated in SF
        string isSynced = HM_Integration_Helper.syncUsersWithHMOperators();
        
        if(isSynced == 'false'){
            return;
        }   
        
        Map<String, object> mapJsonData = new Map<String, object>();
        List<User> lstUsers = new List<User>();
        string sQuery, sSerializedData, sStatusCode, sJSONResponse;
        
        //Create a dynamic query to get related user details
        sQuery = 'Select Id, FirstName, LastName, Email, MobilePhone from User where Id IN :lstUserIds';
        system.debug('sQuery ==> ' + sQuery);
        
        //Fetch all the user details using the dynamic query
        lstUsers = Database.query(sQuery);
        
        if(lstUsers == null || lstUsers.size() <= 0){
            return;
        }        
        
        //Create List to store all wrapper instances
        List<UpdateWrapper> lstUpdateWrapper = new List<UpdateWrapper>();
                
        //Traverse through All the list of users
        for(User objUser : lstUsers){
            
            //Create JSON Request Body
            if(string.isNotBlank(objUser.FirstName)){
                mapJsonData.put('first', objUser.FirstName);
            }
            if(string.isNotBlank(objUser.LastName)){
                mapJsonData.put('last', objUser.LastName);
            }
            if(string.isNotBlank(objUser.MobilePhone)){
                mapJsonData.put('mobile', objUser.MobilePhone);
            }
            if(string.isNotBlank(objUser.Email)){
                mapJsonData.put('email', objUser.Email);
            }
            
            //Json Body is Null
            if(mapJsonData == null || mapJsonData.size() <= 0){
                HM_Integration_Helper.create_HMLogs('Operator Creation from SF to HM', 'Error', '', 'Outbound', 'Json Body is NULL', ' ', ' ');
                return;
            }
            
            //serialize the case details as a JSON Body
            sSerializedData = JSON.serialize(mapJsonData);
            System.debug('Data in Map:: '+ JSON.serializepretty(mapJsonData));
            
            //Get Case Integration details from HM_Integration Metadata
            HM_Integration__mdt objUserAPI = [Select Id, DeveloperName, API_Key__c, HM_End_Point_URL__c 
                                              from HM_Integration__mdt 
                                              where DeveloperName = 'HM_User_Creation'];  
            
            if(string.isBlank(objUserAPI.HM_End_Point_URL__c) || string.isBlank(objUserAPI.API_Key__c)){
                HM_Integration_Helper.create_HMLogs('Operator Creation from SF to HM', 'Error', '', 'Outbound', 'Either the End Point url or API Key is blank. Contact the system admin!', ' ', ' ');
                return;
            }
            
            //HTTP Request
            Http http = new Http();    
            
            HttpRequest httpReq = HM_Integration_Helper.getHttpRequest('POST', objUserAPI.HM_End_Point_URL__c, objUserAPI.API_Key__c, ' ', sSerializedData);
            
            HttpResponse httpResponse = new HttpResponse();
            
            try{
                
                //Create Wrapper instance
                UpdateWrapper objUW = new UpdateWrapper();
                objUW.sHMUserId = objUser.Id;
                
                httpResponse = http.send(HttpReq);
                sStatusCode = string.valueOf(httpResponse.getStatusCode());
                system.debug('Status Code ==> ' + sStatusCode );
                
                //Map Staus Code and Response body 
                objUW.sSerializedData = sSerializedData;
                objUW.sStatusCode = sStatusCode;
                objUW.sJSONResponse = httpResponse.getBody();
                
                if(sStatusCode == '201' || sStatusCode == '200'){
                    
                    sJSONResponse = httpResponse.getBody();
                    
                    Map<String, Object> mapHMResponse = (Map<String, Object>)JSON.deserializeUntyped(sJSONResponse);
                    system.debug('mapHMResponse ==> ' + mapHMResponse);
                    
                    //Update related Case details
                    if(mapHMResponse != null && mapHMResponse.size() > 0){
                        if(mapHMResponse.get('id') != null){
                            objUW.sHMOperatorId = (string)mapHMResponse.get('id');
                        }
                    }
                    
                }
                else{
                    
                    //Create Error Log Entry
                    objUW.bSuccess = false;                     
                }
                
                lstUpdateWrapper.add(objUW);
            } 
            catch(Exception e){
                
                System.debug('The following exception has occurred: ' + e.getMessage());            
                
                //Create a Exception Log Entry record
                HM_Integration_Helper.create_HMLogs('Operator Creation from SF to HM', 'Error', '0', 'Outbound', sSerializedData, e.getMessage(), ' ');
            }
        }
        
        //Update Operator Id on Users
        if(lstUpdateWrapper.size() > 0){
            for(UpdateWrapper objUW : lstUpdateWrapper){
                for(User objUser : lstUsers){
                    if(objUser.Id == objUW.sHMUserId){
                        objUser.HM_Operator_Id__c = objUW.sHMOperatorId;
                        if(objUW.bSuccess){
                            //Create a Success Log Entry record
                            HM_Integration_Helper.create_HMLogs('Operator Creation from SF to HM', 'Success', objUW.sStatusCode, 'Outbound', objUW.sSerializedData, objUW.sJSONResponse, ' ');
                        }
                        else{
                            //Create a Error Log Entry record
                            HM_Integration_Helper.create_HMLogs('Operator Creation from SF to HM', 'Error', objUW.sStatusCode, 'Outbound', objUW.sSerializedData, objUW.sJSONResponse, ' ');
                        }
                        break;
                    }
                }
            }
            
            update lstUsers;
        }
        
    }
    
    //Create a Wrapper Class 
     public class UpdateWrapper{
        public string sHMOperatorId;
        public string sHMUserId;
        public boolean bSuccess; 
        public string sSerializedData;
        public string sJSONResponse;
        public string sStatusCode;
        
        public UpdateWrapper(){
            sHMOperatorId = '';
            sHMUserId = '';
            bSuccess = true;
            sSerializedData = '';
            sJSONResponse = '';
            sStatusCode = '';
        }
    }
    
}