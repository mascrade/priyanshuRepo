/*
* Class Name               : HM_Test_HM_sendOptOutRequest
* Description              : Apex Test Class - Test Coverage for HM_sendOptOutRequest
* Author                   : Darshana Dange (Futran Solutions)
* Created On               : 08 Aug 2022
* Change Log History       :
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Darshana Dange   | 08/08/2022 | Initial Version of Class             |
*  |--------------------------------------------------------------------------------|
*/


@isTest
public class HM_Test_HM_sendOptOutRequest{
    
    public class HM_Mock_responseSuccess implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"customer": {"last": "string","mobile": "string","id": "string","first": "string","email": "string","optStatus": false,"role": "enduser"}}');
            response.setStatusCode(200);
            return response; 
        }
    }
    
    public class HM_Mock_responseError implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('');
            response.setStatusCode(400);
            return response; 
        }
    }
    
    @isTest
    public static void test_HM_sendOptOutRequest(){
        
        Contact objContact = new Contact();
        objContact.MobilePhone = '1122334455';
        objContact.FirstName = 'ABC';
        objContact.LastName = 'Test';
        insert objContact;
        
        List<string> lstContactIds = new List<string>();
        lstContactIds.add(objContact.Id);
        
        HM_User_Mobile_Field_Mapping__c CSMobile = new HM_User_Mobile_Field_Mapping__c();
        CSMobile.Name = 'mobile';
        CSMobile.HM_SF_Field__c = 'MobilePhone';
        insert CSMobile;
        
        List<string> lstContactIds2 = new List<string>();
        
        Test.startTest();
		Test.setMock(HttpCalloutMock.class, new HM_Mock_responseSuccess()); 
        HM_sendOptOutRequest.send_OptOutRequest(lstContactIds2);
        HM_sendOptOutRequest.send_OptOutRequest(lstContactIds);
        Test.stopTest();
    }
    
    @isTest
    public static void test_HM_sendOptOutRequestError(){
        
        Contact objContact = new Contact();
        objContact.MobilePhone = '1122334455';
        objContact.FirstName = 'ABC';
        objContact.LastName = 'Test';
        insert objContact;
        
        List<string> lstContactIds = new List<string>();
        lstContactIds.add(objContact.Id);
        
        HM_User_Mobile_Field_Mapping__c CSMobile = new HM_User_Mobile_Field_Mapping__c();
        CSMobile.Name = 'mobile';
        CSMobile.HM_SF_Field__c = 'MobilePhone';
        insert CSMobile;
     
        Test.startTest();
		Test.setMock(HttpCalloutMock.class, new HM_Mock_responseError()); 
        HM_sendOptOutRequest.send_OptOutRequest(lstContactIds);
        Test.stopTest();
    }
    
     @isTest
    public static void test_HM_sendOptOutRequestException(){
        
        Contact objContact = new Contact();
        objContact.MobilePhone = '1122334455';
        objContact.FirstName = 'ABC';
        objContact.LastName = 'Test';
        insert objContact;
        
        List<string> lstContactIds = new List<string>();
        lstContactIds.add(objContact.Id);
        
        HM_User_Mobile_Field_Mapping__c CSMobile = new HM_User_Mobile_Field_Mapping__c();
        CSMobile.Name = 'mobile';
        CSMobile.HM_SF_Field__c = 'MobilePhone';
        insert CSMobile;
     
        Test.startTest(); 
        HM_sendOptOutRequest.send_OptOutRequest(lstContactIds);
        Test.stopTest();
    }
    
}