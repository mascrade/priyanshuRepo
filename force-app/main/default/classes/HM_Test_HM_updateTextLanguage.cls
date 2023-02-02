/*
* Class Name               : HM_Test_HM_updateTextLanguage
* Description              : Apex Test Class - Test Coverage for Class HM_updateTextLanguageInHM
* Author                   : Darshana Dange (Futran Solutions)
* Created On               : 15 Sep 2022
* Change Log History       :
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Darshana Dange   | 15/09/2022 | Initial Version of Class             |
*  |--------------------------------------------------------------------------------|
*/

@IsTest
public class HM_Test_HM_updateTextLanguage {
    
    public class HM_Mock_ResponseSuccess implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"languagePreference": "en"}');
            response.setStatusCode(200);
            return response; 
        }
    }
    
    public class HM_Mock_ResponseError implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"errors":[{"code":"PolicyExists","category":"DataIntegrityError","retryable":false,"status":400,"detail":"Policy already exists for your requests customer mobile and policy number combination."}]}');
            response.setStatusCode(400);
            return response; 
        }
    }
    
    @isTest
    public static void test_updateTextLanguage(){        
        
        Profile objProfile = [Select Id from profile where Name = 'Standard User'];
        
        User sUser = new User();
        sUser.FirstName = 'Anne';
        sUser.LastName = 'S';
        sUser.Email = 'AnneS@testt.com';
        sUser.Username = 'anne@test.com';
        sUser.ProfileId = objProfile.Id;
        sUser.EmailEncodingKey = 'UTF-8';
        sUser.LanguageLocaleKey = 'en_US';
        sUser.TimeZoneSidKey = 'America/Los_Angeles';
        sUser.LocaleSidKey = 'en_US';
        sUser.Alias = 'AnneS';
        insert sUser;
        
        //Create a Test Contact Data
        Contact objCon = new Contact();
        objCon.FirstName = 'Jane';
        objCon.LastName = 'Smith';
        objCon.MobilePhone = '8899556644';
        objCon.email = 'abc@test.com';
        insert objCon;
        
        //Create a Test Case Data
        Case objCase = new Case();
        objCase.Origin = 'Phone';
        objCase.HM_Brand__c = 'Brand 1';
        objCase.HM_Case_Status__c = 'open';
        objCase.HM_Case_Type__c = 'case';
        objCase.HM_Text_Language__c = 'en';
        objCase.ContactId = objCon.Id;
        objCase.OwnerId = sUser.Id;
        objCase.HM_Case_Id__c = 'string';
        objCase.HM_Resend_Welcome_Message__c = false;
        insert objCase;
       
        List<string> lstCaseIds = new List<string>();
        lstCaseIds.add(objCase.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HM_Mock_ResponseSuccess()); 
        HM_updateTextLanguageInHM.HM_update_TextLanguageInHM(lstCaseIds);
        Test.stopTest();
    }
    
    @isTest
    public static void test_updateTextLanguageError(){        
        
        Profile objProfile = [Select Id from profile where Name = 'Standard User'];
        
        User sUser = new User();
        sUser.FirstName = 'Anne';
        sUser.LastName = 'S';
        sUser.Email = 'AnneS@testt.com';
        sUser.Username = 'anne@test.com';
        sUser.ProfileId = objProfile.Id;
        sUser.EmailEncodingKey = 'UTF-8';
        sUser.LanguageLocaleKey = 'en_US';
        sUser.TimeZoneSidKey = 'America/Los_Angeles';
        sUser.LocaleSidKey = 'en_US';
        sUser.Alias = 'AnneS';
        insert sUser;
        
        //Create a Test Contact Data
        Contact objCon = new Contact();
        objCon.FirstName = 'Jane';
        objCon.LastName = 'Smith';
        objCon.MobilePhone = '8899556644';
        objCon.email = 'abc@test.com';
        insert objCon;
        
        //Create a Test Case Data
        Case objCase = new Case();
        objCase.Origin = 'Phone';
        objCase.HM_Brand__c = 'Brand 1';
        objCase.HM_Case_Status__c = 'open';
        objCase.HM_Case_Type__c = 'case';
        objCase.HM_Text_Language__c = 'en';
        objCase.ContactId = objCon.Id;
        objCase.OwnerId = sUser.Id;
        objCase.HM_Case_Id__c = 'string';
        objCase.HM_Resend_Welcome_Message__c = false;
        insert objCase;
        
        List<string> lstCaseIds = new List<string>();
        lstCaseIds.add(objCase.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HM_Mock_ResponseError()); 
        HM_updateTextLanguageInHM.HM_update_TextLanguageInHM(lstCaseIds);

        Test.stopTest();
    }
    
    @isTest
    public static void test_updateTextLanguageException(){        
        
        Profile objProfile = [Select Id from profile where Name = 'Standard User'];
        
        User sUser = new User();
        sUser.FirstName = 'Anne';
        sUser.LastName = 'S';
        sUser.Email = 'AnneS@testt.com';
        sUser.Username = 'anne@test.com';
        sUser.ProfileId = objProfile.Id;
        sUser.EmailEncodingKey = 'UTF-8';
        sUser.LanguageLocaleKey = 'en_US';
        sUser.TimeZoneSidKey = 'America/Los_Angeles';
        sUser.LocaleSidKey = 'en_US';
        sUser.Alias = 'AnneS';
        insert sUser;
        
        //Create a Test Contact Data
        Contact objCon = new Contact();
        objCon.FirstName = 'Jane';
        objCon.LastName = 'Smith';
        objCon.MobilePhone = '8899556644';
        objCon.email = 'abc@test.com';
        insert objCon;
        
        //Create a Test Case Data
        Case objCase = new Case();
        objCase.Origin = 'Phone';
        objCase.HM_Brand__c = 'Brand 1';
        objCase.HM_Case_Status__c = 'open';
        objCase.HM_Case_Type__c = 'case';
        objCase.HM_Text_Language__c = 'en';
        objCase.ContactId = objCon.Id;
        objCase.OwnerId = sUser.Id;
        objCase.HM_Case_Id__c = 'test';
        objCase.HM_Resend_Welcome_Message__c = false;
        insert objCase;
      
        List<string> lstCaseIds = new List<string>();
        lstCaseIds.add(objCase.Id);
        
        Test.startTest();
        HM_updateTextLanguageInHM.HM_update_TextLanguageInHM(lstCaseIds);
        Test.stopTest();
    }
}