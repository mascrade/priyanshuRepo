/*
* Class Name               : HM_Notifications
* Description              : Apex Class - This is test class for HM_Notifications Class.
* Author                   : Team Futran 
* Created On               : 12 Dec 2022
* Change Log History       : 
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Team Futran    | 12/12/2022 | Initial Version of Class               |
*  |--------------------------------------------------------------------------------|
*/

@IsTest
public class HM_Test_HM_Notifications {
    
    public class HM_Mock_ResponseSuccess implements HttpCalloutMock{
        
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"_id": "ae6c6e96-92f7-4bb2-bccb-5aaea559bd13","createdAt": "2022-08-24T00:20:26.943Z","authorId": "2e83408d-0d46-40d7-bb5a-7888518488ad"}');
            response.setStatusCode(200);
            return response; 
        }
    }
    
    public class HM_Mock_ResponseError implements HttpCalloutMock{
        
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{}');
            response.setStatusCode(400);
            return response; 
        }
    }
    
    
    @isTest
    public static void test_Notifications(){ 
        
        //Create a Test Contact Data
        Contact objCon = new Contact();
        objCon.FirstName = 'Jane';
        objCon.LastName = 'Smith';
        objCon.MobilePhone = 'string';
        objCon.email = 'abc@test.com';
        objCon.HM_Is_Opted_In__c = true;
        objCon.HM_Opt_Status_Detail__c = 'OPTED_IN';
        insert objCon;
        
        //Create a Test Case Data
        Case objCase = new Case();
        objCase.Origin = 'Phone';
        objCase.HM_Brand__c = 'Brand 1';
        objCase.HM_Case_Status__c = 'open';
        objCase.HM_Case_Type__c = 'case';
        objCase.HM_Text_Language__c = 'en';
        objCase.ContactId = objCon.Id;
        objCase.HM_Send_Create_Request__c = false;
        objCase.HM_Enable_Notifications__c = true;
        insert objCase;
        
        //Create Test Policy Data
        HM_Policy__c objPolicy = new HM_Policy__c();
        objPolicy.HM_Contact__c = objCon.Id;
        objPolicy.HM_Policy_Number__c = 'Test23232';
        objPolicy.HM_Renewal_Date__c = System.today() + 1;
        insert objPolicy;
        
        //Create a Test Data for SMS Template
        HM_SMS_Template__c objSMS = new HM_SMS_Template__c();
        objSMS.HM_Name__c = 'Test';
        ObjSMS.HM_Object_Name__c = 'policy';
        ObjSMS.HM_Contact_API_Name__c = 'HM_Contact__c';
        ObjSMS.HM_Template_Body__c = 'Hi Test, your bill for policy #{HM_Policy_Number__c} is due on {HM_Renewal_Date_FR__c}.' +
            'Visit www.lovableinsurance.com/pay to make a payment. ' +
            'If youve already made your payment please disregard this text.';
        insert ObjSMS;
        
        HM_SMS_Template__c objSMS1 = [Select Id, Name from HM_SMS_Template__c where Id = :ObjSMS.Id];
        
        HM_Notifications.FlowInputs flowinput = new HM_Notifications.FlowInputs();
        flowinput.RecordId = objPolicy.Id;
        flowinput.SMS_Template_No = objSMS1.Name;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HM_Mock_ResponseSuccess()); 
        HM_Notifications.HM_Notifications(new List<HM_Notifications.FlowInputs>{flowinput});
        Test.stopTest();
    }

}