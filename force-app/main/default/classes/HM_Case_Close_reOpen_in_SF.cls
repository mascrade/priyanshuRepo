/*
* Name               : HM_Case_Close_reOpen_in_SF
* Description        : Apex REST Resource for Case Closure or Reopen - API Endpoint to Update a case in Salesforce when a Case is Closed/Opened in Hi Marley.
* Author             : Rohit (Futran Solutions)
* Created On         : 05 August 2022
* Test Class         : HM_Test_HM_Create_CaseIn_SF
* Change Log History : 
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Rohit              | 05 Aug 2022 | Initial Version of Apex Class---|
*  |------------------------------------------------------------------------------|
*/

@RestResource(urlMapping='/HM_Case_Close_reOpen_in_SF/*')
global class HM_Case_Close_reOpen_in_SF {
    @HttpPost
    global Static string Close_OR_ReopenCASE(){
        
        //Case Response Message
        CaseResponseMsg caseResponse = new CaseResponseMsg();
        string jSONRequestBody;
        //define new instance of Map<String, Object> to save the deserialized list
        Map<String, Object> Map_RequestBody = new Map<String, Object>();
        
        try {
            //get the body from request
            RestRequest req = RestContext.request;
            RestResponse res = Restcontext.response;
            jSONRequestBody = req.requestBody.tostring().trim();
            System.debug('jSONRequestBody-->>'+jSONRequestBody);
            
            //Deserialize the specified JSON string into collections of primitive data types.
            Map_RequestBody = (Map<String, Object>)JSON.deserializeUntyped(jSONRequestBody);
            
            //get caseData from Map_RequestBody
            Map<String, Object> Map_caseData = (Map<String, Object>)Map_RequestBody.get('caseData');
            
            // get HM case id from Map_caseData, and state from Map_RequestBody
            String HMCaseId = Map_caseData.get('id').toString();
            String HMCaseStatus = Map_RequestBody.get('state').toString();
            
            //get list of Case where id = HMCaseId with Limit 1
            List<Case> lstCaseToUpdate = [SELECT Id, HM_Case_Id__c, HM_Case_Status__c 
                                          FROM Case 
                                          WHERE HM_Case_Id__c =: HMCaseId AND HM_Case_Id__c != null LIMIT 1];
            //null check
            if(lstCaseToUpdate != null && lstCaseToUpdate.size() > 0 && string.isNotBlank(HMCaseId)){
                for(Case objCase:lstCaseToUpdate){
                    if(HMCaseStatus != null){
                        //update case status field
                        objCase.HM_Case_Status__c = HMCaseStatus;
                        if(HMCaseStatus == 'closed'){
                            objCase.HM_Integration_Message__c = System.Label.HM_Case_Closure_HM_to_SF;
                        }else if(HMCaseStatus == 'open'){
                            objCase.HM_Integration_Message__c = System.Label.HM_Case_ReOpen_HM_to_SF;
                        }
                    }
                } 
                //update list
                update lstCaseToUpdate;
                caseResponse.Status = 'Success';
                caseResponse.Message = 'Case updated successfully'+HMCaseStatus;
                HM_Integration_Helper.create_HMLogs(caseResponse.Message, 'Success', '200','Inbound' , jSONRequestBody, 'NA', '');
            }
            else {
                HM_Integration_Helper.create_HMLogs('Case not Found', 'Failure', '0','Inbound' , jSONRequestBody, 'NA','');
                //return caseResponse;
                return caseResponse.Status+' - '+caseResponse.Message;
            } 
        }
        catch(Exception e) {
            caseResponse.Status = 'Fail';
            caseResponse.Message = e.getMessage();
            HM_Integration_Helper.create_HMLogs('Error: '+e.getMessage(), 'Failure', '0','Inbound' , jSONRequestBody, 'NA','');
        }
        //return caseResponse;
        return caseResponse.Status+' - '+caseResponse.Message;
    }
    
    //Inner Class For Case Response Message
    global class CaseResponseMsg {
        global String Status;
        global String message;
        global sObject CreatedCaseRecord;
    }
}