/*
* Name               : HM_DeleteOperatorsInHM
* Description        : Apex Class - Delete Operator whenever a user is deactivated in SF
* Author             : Darshana Dange (Futran Solutions)
* Created On         : 09 August 2022
* Test Class         : HM_Test_HM_DeleteOperatorsInHM
* Change Log History :
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Darshana Dange     | 09 Aug 2022 | Initial Version of Apex Class   |
*  |------------------------------------------------------------------------------|
*/

public class HM_DeleteOperatorsInHM {
    
    @InvocableMethod(label='Delete Operators in HM' description='Delete Operators in HM' category= 'User')
    public static void HM_DeleteOperatorsInHM(List<string> lstUserIds){
        
        if(lstUserIds == null || lstUserIds.size() <= 0){
            return;
        }
        
        //Check whether syncing user with HM Operators is Enabled if the user are created/deactivated in SF
        string isSynced = HM_Integration_Helper.syncUsersWithHMOperators();
        
        if(isSynced == 'false'){
            return;
        }        
        
        List<User> lstUsers = new List<User>();
        string sUserId, sQuery, sSerializedData, sEndpoint, sStatusCode, sJSONResponse;
        
        //Create a dynamic query to get related user details
        sQuery = 'Select Id, FirstName, LastName, Email, MobilePhone, HM_Operator_Id__c from User where Id IN :lstUserIds';
        system.debug('sQuery ==> ' + sQuery);
        
        //Fetch all the user details using the dynamic query
        lstUsers = Database.query(sQuery);
        
        if(lstUsers == null || lstUsers.size() <= 0){
            return;
        }
        
        //Get the Integration details from CUstom metadata of user deletion
        HM_Integration__mdt objUserAPI = [Select Id, DeveloperName, API_Key__c, HM_End_Point_URL__c 
                                          from HM_Integration__mdt 
                                          where DeveloperName = 'HM_User_Deletion'];  
        
        if(string.isBlank(objUserAPI.HM_End_Point_URL__c) || string.isBlank(objUserAPI.API_Key__c)){
            HM_Integration_Helper.create_HMLogs('Delete Operator from HM', 'Error', '', 'Outbound', 'Either the End Point url or API Key is blank. Contact the system admin!', ' ', ' ');
            return;
        }
        
        //Callout to delete Opertors
        
        //Create List to store all wrapper instances
        List<UpdateWrapper> lstUpdateWrapper = new List<UpdateWrapper>();
        
        for(User objUser : lstUsers){  
            
            sEndpoint = objUserAPI.HM_End_Point_URL__c + objUser.HM_Operator_Id__c;
            system.debug('sEndpoint ==> ' + sEndpoint);
            
            //HTTP Request
            Http http = new Http();    
            
            Httprequest httpReq = HM_Integration_Helper.getHttpRequest('DELETE', sEndpoint, objUserAPI.API_Key__c, ' ', ' ');
            
            HttpResponse httpResponse = new HttpResponse();
            
            try{
                
                //Create Wrapper instance
                UpdateWrapper objUW = new UpdateWrapper();
                
                httpResponse = http.send(HttpReq);
                sStatusCode = string.valueOf(httpResponse.getStatusCode());
                system.debug('Status Code ==> ' + sStatusCode );
                
                //Map Staus Code and Response body 
                objUW.sStatusCode = sStatusCode;
                objUW.sJSONResponse = httpResponse.getBody();
                
                if(sStatusCode == '201' || sStatusCode == '200'){
                    sJSONResponse = httpResponse.getBody();
                    system.debug('responseBody: ' + sJSONResponse);
                    
                    Map<String, Object> mapHMResponse = (Map<String, Object>)JSON.deserializeUntyped(sJSONResponse);
                    system.debug('mapHMResponse ==> ' + mapHMResponse);
                    
                }
                else{
                    
                    sJSONResponse = httpResponse.getBody();
                    system.debug('responseBody: ' + sJSONResponse);
                    objUW.bSuccess = false;                    
                }
                
            } 
            catch(Exception e){
                
                System.debug('The following exception has occurred: ' + e.getMessage());
                
                //Create a Error log Entry record
                HM_Integration_Helper.create_HMLogs('Delete Operator from HM', 'Error', '0', 'Outbound', '', e.getMessage(), ' ');            
            }
        }
        
        //Update Operator Id on Users
        if(lstUpdateWrapper.size() > 0){
            for(UpdateWrapper objUW : lstUpdateWrapper){
                if(objUW.bSuccess){
                   //Create a Success log Entry record
                    HM_Integration_Helper.create_HMLogs('Delete Operator from HM', 'Success', objUW.sStatusCode, 'Outbound', '', objUW.sJSONResponse, ' ');
                }
                else{
                    //Create a Error log Entry record
                    HM_Integration_Helper.create_HMLogs('Delete Operator from HM', 'Error', objUW.sStatusCode,  'Outbound', '', objUW.sJSONResponse, ' ');                   
                }
            }
        }
       
    }
    
    //Create a Wrapper Class 
    public class UpdateWrapper{
        public boolean bSuccess; 
        public string sJSONResponse;
        public string sStatusCode;
        
        public UpdateWrapper(){
            bSuccess = true;
            sJSONResponse = '';
            sStatusCode = '';
        }
    }
}