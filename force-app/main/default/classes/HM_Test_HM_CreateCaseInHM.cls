/*
* Class Name               : HM_Test_HM_CreateCaseInHM
* Description              : Apex Test Class - Test Coverage for Class HM_CreateCaseInHM
* Author                   : Darshana Dange (Futran Solutions)
* Created On               : 11 August 2022
* Change Log History       :
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Darshana Dange   | 11/08/2022 | Initial Version of Class             |
*  |--------------------------------------------------------------------------------|
*/

@isTest
public class HM_Test_HM_CreateCaseInHM {
    
    public class HM_Mock_ResponseSuccess implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/pdf');
            response.setBody('{"primaryContact": {"last": "string","mobile": "string","first": "string","email": "string"},' +
                             '"customer": {"last": "string","mobile": "string","first": "string","email": "string"},'+
                             '"caseData": {"statusDescription": "string","brand": "string", "id": "string"},'+
                             '"caseType": "claim","privacy": "public","languagePreference": "en", ' +
                             '"secondaryOperators": [{"email": "Test@testt.com"}]}');
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
    public static void test_createCaseInHM(){        
        
        Profile objProfile = [Select Id from profile where Name = 'Standard User'];
        
        User sysUser = [Select Id, Name from User where profile.Name = 'System Administrator' and isActive = true Limit 1];
        
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
        
        User sUser2 = new User();
        sUser2.FirstName = 'Test';
        sUser2.LastName = 'S';
        sUser2.Email = 'Test@testt.com';
        sUser2.Username = 'sUser2@abc.com';
        sUser2.ProfileId = objProfile.Id;
        sUser2.EmailEncodingKey = 'UTF-8';
        sUser2.LanguageLocaleKey = 'en_US';
        sUser2.TimeZoneSidKey = 'America/Los_Angeles';
        sUser2.LocaleSidKey = 'en_US';
        sUser2.Alias = 'TestS';
        insert sUser2;
        
        //Create a Test Contact Data
        Contact objCon = new Contact();
        objCon.FirstName = 'Jane';
        objCon.LastName = 'Smith';
        objCon.MobilePhone = 'string';
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
        objCase.HM_Send_Create_Request__c = false;
        insert objCase;
        
        system.runas(sysUser){
            //Create Case Team Role
            CaseTeamRole role = new CaseTeamRole();
            role.Name = 'Agent';
            role.AccessLevel = 'Read';
            insert role;
            
            //Add Case Team members
            CaseTeamMember objCaseTeamMember = new CaseTeamMember();
            objCaseTeamMember.MemberId = sUser2.Id;
            objCaseTeamMember.ParentId = objCase.Id;
            objCaseTeamMember.TeamRoleId = role.Id;
            insert objCaseTeamMember;
        }
        
        //Create Settings for Integration Logs
        HM_Integration_Logs__c CSLogs = new HM_Integration_Logs__c();
        CSLogs.Name = 'HM Logs';
        CSLogs.Enable_HM_Logs__c = true;
        insert CSLogs;
        
        //Create Settings for Contact Mobile
        HM_User_Mobile_Field_Mapping__c CSMobile = new HM_User_Mobile_Field_Mapping__c();
        CSMobile.Name = 'mobile';
        CSMobile.HM_SF_Field__c = 'MobilePhone';
        insert CSMobile;
        
        //Custom Setting : Create Case Privacy record
        HM_Case_Privacy__c objHMCasePrivacy = new HM_Case_Privacy__c();
        objHMCasePrivacy.Name = 'privacy';
        objHMCasePrivacy.HM_Privacy__c = 'public';
        insert objHMCasePrivacy;
        
        //Custom Setting : Create Case Branding check
        HM_Branding__c objHMCaseBranding = new HM_Branding__c();
        objHMCaseBranding.Name = 'Branding';
        objHMCaseBranding.HM_Enable_Branding__c = true;
        insert objHMCaseBranding;
        
        //Custom Setting : Create Case Field mapping records
        HM_Case_Fields_Mapping__c objCS_Brand = new HM_Case_Fields_Mapping__c();
        objCS_Brand.Name = 'caseData.brand';
        objCS_Brand.HM_API_Sub_Object_Name__c = 'caseData';
        objCS_Brand.HM_SF_Field__c = 'HM_Brand__c';
        insert objCS_Brand;        
        
        HM_Case_Fields_Mapping__c objCS_ContactFirstName = new HM_Case_Fields_Mapping__c();
        objCS_ContactFirstName.Name = 'customer.first';
        objCS_ContactFirstName.HM_API_Sub_Object_Name__c = 'customer';
        objCS_ContactFirstName.HM_SF_Object__c = 'Contact';
        objCS_ContactFirstName.HM_SF_Field__c = 'Contact.FirstName';
        insert objCS_ContactFirstName;
        
        HM_Case_Fields_Mapping__c objCS_ContactMobile = new HM_Case_Fields_Mapping__c();
        objCS_ContactMobile.Name = 'customer.mobile';
        objCS_ContactMobile.HM_API_Sub_Object_Name__c = 'customer';
        objCS_ContactMobile.HM_SF_Object__c = 'Contact';
        objCS_ContactMobile.HM_SF_Field__c = 'Contact.MobilePhone';
        insert objCS_ContactMobile;
        
        HM_Case_Fields_Mapping__c objCS_userFirstName = new HM_Case_Fields_Mapping__c();
        objCS_userFirstName.Name = 'primaryContact.first';
        objCS_userFirstName.HM_API_Sub_Object_Name__c = 'primaryContact';
        objCS_userFirstName.HM_SF_Object__c = 'Owner';
        objCS_userFirstName.HM_SF_Field__c = 'Owner.FirstName';
        insert objCS_userFirstName;
        
        HM_Case_Fields_Mapping__c objCS_userEmail = new HM_Case_Fields_Mapping__c();
        objCS_userEmail.Name = 'primaryContact.email';
        objCS_userEmail.HM_API_Sub_Object_Name__c = 'primaryContact';
        objCS_userEmail.HM_SF_Object__c = 'Owner';
        objCS_userEmail.HM_SF_Field__c = 'Owner.Email';
        insert objCS_userEmail;
        
        objCase.HM_Send_Create_Request__c = true;
        update objCase;
        
        List<string> lstCaseIds = new List<string>();
        lstCaseIds.add(objCase.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HM_Mock_ResponseSuccess()); 
        HM_CreateCaseInHM.HM_CreateCaseInHM(lstCaseIds);
        Test.stopTest();
    }
    
    @isTest
    public static void test_createCaseInHMError(){        
        
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
        
        User sUser2 = new User();
        sUser2.FirstName = 'Test';
        sUser2.LastName = 'S';
        sUser2.Email = 'Test@testt.com';
        sUser2.Username = 'sUser2@abc.com';
        sUser2.ProfileId = objProfile.Id;
        sUser2.EmailEncodingKey = 'UTF-8';
        sUser2.LanguageLocaleKey = 'en_US';
        sUser2.TimeZoneSidKey = 'America/Los_Angeles';
        sUser2.LocaleSidKey = 'en_US';
        sUser2.Alias = 'TestS';
        insert sUser2;
        
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
        objCase.HM_Send_Create_Request__c = false;
        insert objCase;
        
        //Custom Setting : Create Case Privacy record
        HM_Case_Privacy__c objHMCasePrivacy = new HM_Case_Privacy__c();
        objHMCasePrivacy.Name = 'privacy';
        objHMCasePrivacy.HM_Privacy__c = 'public';
        insert objHMCasePrivacy;
        
        //Custom Setting : Create Case Branding check
        HM_Branding__c objHMCaseBranding = new HM_Branding__c();
        objHMCaseBranding.Name = 'Branding';
        objHMCaseBranding.HM_Enable_Branding__c = true;
        insert objHMCaseBranding;
        
        //Custom Setting : Create Case Field mapping records
        HM_Case_Fields_Mapping__c objCS_Brand = new HM_Case_Fields_Mapping__c();
        objCS_Brand.Name = 'caseData.brand';
        objCS_Brand.HM_API_Sub_Object_Name__c = 'caseData';
        objCS_Brand.HM_SF_Field__c = 'HM_Brand__c';
        insert objCS_Brand;
        
        HM_Case_Fields_Mapping__c objCS_ContactFirstName = new HM_Case_Fields_Mapping__c();
        objCS_ContactFirstName.Name = 'customer.first';
        objCS_ContactFirstName.HM_API_Sub_Object_Name__c = 'customer';
        objCS_ContactFirstName.HM_SF_Object__c = 'Contact';
        objCS_ContactFirstName.HM_SF_Field__c = 'Contact.FirstName';
        insert objCS_ContactFirstName;
        
        HM_Case_Fields_Mapping__c objCS_ContactMobile = new HM_Case_Fields_Mapping__c();
        objCS_ContactMobile.Name = 'customer.mobile';
        objCS_ContactMobile.HM_API_Sub_Object_Name__c = 'customer';
        objCS_ContactMobile.HM_SF_Object__c = 'Contact';
        objCS_ContactMobile.HM_SF_Field__c = 'Contact.MobilePhone';
        insert objCS_ContactMobile;
        
        HM_Case_Fields_Mapping__c objCS_userFirstName = new HM_Case_Fields_Mapping__c();
        objCS_userFirstName.Name = 'primaryContact.first';
        objCS_userFirstName.HM_API_Sub_Object_Name__c = 'primaryContact';
        objCS_userFirstName.HM_SF_Object__c = 'Owner';
        objCS_userFirstName.HM_SF_Field__c = 'Owner.FirstName';
        insert objCS_userFirstName;
        
        HM_Case_Fields_Mapping__c objCS_userEmail = new HM_Case_Fields_Mapping__c();
        objCS_userEmail.Name = 'primaryContact.email';
        objCS_userEmail.HM_API_Sub_Object_Name__c = 'primaryContact';
        objCS_userEmail.HM_SF_Object__c = 'Owner';
        objCS_userEmail.HM_SF_Field__c = 'Owner.Email';
        insert objCS_userEmail;
        
        objCase.HM_Send_Create_Request__c = true;
        update objCase;
        
        List<string> lstCaseIds = new List<string>();
        lstCaseIds.add(objCase.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HM_Mock_ResponseError()); 
        HM_CreateCaseInHM.HM_CreateCaseInHM(lstCaseIds);
        Test.stopTest();
    }
    
    @isTest
    public static void test_createCaseInHMException(){        
        
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
        
        User sUser2 = new User();
        sUser2.FirstName = 'Test';
        sUser2.LastName = 'S';
        sUser2.Email = 'Test@testt.com';
        sUser2.Username = 'sUser2@abc.com';
        sUser2.ProfileId = objProfile.Id;
        sUser2.EmailEncodingKey = 'UTF-8';
        sUser2.LanguageLocaleKey = 'en_US';
        sUser2.TimeZoneSidKey = 'America/Los_Angeles';
        sUser2.LocaleSidKey = 'en_US';
        sUser2.Alias = 'TestS';
        insert sUser2;
        
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
        objCase.HM_Send_Create_Request__c = false;
        insert objCase;
        
        //Custom Setting : Create Case Privacy record
        HM_Case_Privacy__c objHMCasePrivacy = new HM_Case_Privacy__c();
        objHMCasePrivacy.Name = 'privacy';
        objHMCasePrivacy.HM_Privacy__c = 'public';
        insert objHMCasePrivacy;
        
        //Custom Setting : Create Case Branding check
        HM_Branding__c objHMCaseBranding = new HM_Branding__c();
        objHMCaseBranding.Name = 'Branding';
        objHMCaseBranding.HM_Enable_Branding__c = true;
        insert objHMCaseBranding;
        
        //Custom Setting : Create Case Field mapping records
        HM_Case_Fields_Mapping__c objCS_Brand = new HM_Case_Fields_Mapping__c();
        objCS_Brand.Name = 'caseData.brand';
        objCS_Brand.HM_API_Sub_Object_Name__c = 'caseData';
        objCS_Brand.HM_SF_Field__c = 'HM_Brand__c';
        insert objCS_Brand;
        
        HM_Case_Fields_Mapping__c objCS_ContactFirstName = new HM_Case_Fields_Mapping__c();
        objCS_ContactFirstName.Name = 'customer.first';
        objCS_ContactFirstName.HM_API_Sub_Object_Name__c = 'customer';
        objCS_ContactFirstName.HM_SF_Object__c = 'Contact';
        objCS_ContactFirstName.HM_SF_Field__c = 'Contact.FirstName';
        insert objCS_ContactFirstName;
        
        HM_Case_Fields_Mapping__c objCS_ContactMobile = new HM_Case_Fields_Mapping__c();
        objCS_ContactMobile.Name = 'customer.mobile';
        objCS_ContactMobile.HM_API_Sub_Object_Name__c = 'customer';
        objCS_ContactMobile.HM_SF_Object__c = 'Contact';
        objCS_ContactMobile.HM_SF_Field__c = 'Contact.MobilePhone';
        insert objCS_ContactMobile;
        
        HM_Case_Fields_Mapping__c objCS_userFirstName = new HM_Case_Fields_Mapping__c();
        objCS_userFirstName.Name = 'primaryContact.first';
        objCS_userFirstName.HM_API_Sub_Object_Name__c = 'primaryContact';
        objCS_userFirstName.HM_SF_Object__c = 'Owner';
        objCS_userFirstName.HM_SF_Field__c = 'Owner.FirstName';
        insert objCS_userFirstName;
        
        HM_Case_Fields_Mapping__c objCS_userEmail = new HM_Case_Fields_Mapping__c();
        objCS_userEmail.Name = 'primaryContact.email';
        objCS_userEmail.HM_API_Sub_Object_Name__c = 'primaryContact';
        objCS_userEmail.HM_SF_Object__c = 'Owner';
        objCS_userEmail.HM_SF_Field__c = 'Owner.Email';
        insert objCS_userEmail;
        
        objCase.HM_Send_Create_Request__c = true;
        update objCase;
        
        List<string> lstCaseIds = new List<string>();
        lstCaseIds.add(objCase.Id);
        
        Test.startTest();
        HM_CreateCaseInHM.HM_CreateCaseInHM(lstCaseIds);
        Test.stopTest();
    }
}