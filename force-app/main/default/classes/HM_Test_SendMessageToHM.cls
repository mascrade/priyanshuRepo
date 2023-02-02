/*
* Class Name               : HM_Test_SendMessageToHM
* Description              : Test Class of HM_SendMessageToHM
* Author                   : Team Futran 
* Created On               : 24 August 2022
* Change Log History       :
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date          | Comment                            |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Team Futran    | 24 August 2022 | Initial Version of Class           |
*  |--------------------------------------------------------------------------------|
*/
@isTest
public class HM_Test_SendMessageToHM {
    
    //get User
    public static User objUser = [select id, Name, FirstName, LastName,Profile.Name from User where Profile.Name = 'System Administrator' and isActive = true limit 1];
    
    @testSetup 
    public static void setup() {
        
        //1. Create test Contact2
        Contact objContact1 = new Contact(
            FirstName = 'mno',
            LastName = 'Abc',
            Title = 'VP',
            MobilePhone = '999999',
            HM_User_Id__c = 'pqr123');
        insert objContact1;
        
        //2. create Case
        Case objCase = new Case(
            Status = 'Open',
            Origin = 'Web',
            HM_Case_Id__c = 'abc123');
        insert objCase;
        
        //create custom setting
        HM_Message_Template_Id__c objMsgTemplate = new HM_Message_Template_Id__c();
        objMsgTemplate.Name = 'hi marley template';	
        objMsgTemplate.Value__c = 'FULL_MESSAGE';
        insert objMsgTemplate;
    }
    
    @isTest
    public static void test1(){
        
        Case objCase = [select id from Case];
        
        Test.startTest();
		Test.setMock(HttpCalloutMock.class, new HM_Mock_ResponseSuccess()); 
        
        System.runas(objUser){	
        HM_SendMessageToHM.sendMessage('hello',objCase.Id);
        HM_SendMessageToHM.sendMessage('',objCase.Id);
        HM_SendMessageToHM.sendMessage('hello','abc');    
        }
        Test.stopTest();
    }
    
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
}