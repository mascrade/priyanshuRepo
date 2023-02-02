@RestResource(urlMapping='/createLogEntry/*')
global class HM_IntegrationHelper {
    @HttpPost
    global static void createLog(string Category, string Origin, string Message) {
        
        try{
            if(string.isNotBlank(Category) && string.isNotBlank(Origin) && string.isNotBlank(Message)){
                
                HM_Logs__c objLogEntry = new HM_Logs__c();
                objLogEntry.HM_Method_Name__c = Category;
                objLogEntry.HM_Status__c = Origin;
                objLogEntry.HM_Response_Body__c = Message;
                insert objLogEntry;
                
                RestContext.response.responseBody = Blob.valueOf('New Log Entry has been created successfully!');
            }
        }
        Catch(Exception e){
            //RestContext.response.responseBody = Blob.valueOf('Error : ' + e.getMessage());
        } 
        
    }
    
}