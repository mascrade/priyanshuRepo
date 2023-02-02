/*
* Class Name               : HM_Test_HM_trigger_Case
* Description              : Apex Test Class for trigger - HM_trigger_Case
* Author                   : Darshana Dange (Futran Solutions)
* Created On               : 22 Dec 2022
* Change Log History       :
*  |----------------------------------------------------------------------------------|
*  | Version | Modified By      | Date        | Comment                               |
*  |----------------------------------------------------------------------------------|
*  | 0.1     | Darshana Dange   | 22/12/2022 | Initial Version of Class               |
*  |----------------------------------------------------------------------------------|
*/

@IsTest
public class HM_Test_HM_trigger_Case {
    
    @IsTest
    public static void test_case(){
        
        //Create a Test Case Data
        Case objCase = new Case();
        objCase.Origin = 'Phone';
        objCase.HM_Brand__c = 'Brand 1';
        objCase.HM_Case_Status__c = 'open';
        objCase.HM_Case_Type__c = 'case';
        objCase.HM_Text_Language__c = 'en';
        objCase.HM_Send_Create_Request__c = false;
        insert objCase;
        
        objCase.HM_Send_Create_Request__c = true;
        update objCase;
    }
    
    @IsTest
    public static void test_case2(){
        
        Profile objProfile = [Select Id from profile where Name = 'Standard User'];
        
        User sysUser = [Select Id, Name from User where profile.Name = 'System Administrator' and isActive = true Limit 1];
        
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
        
        //Create a Test Case Data
        Case objCase = new Case();
        objCase.Origin = 'Phone';
        objCase.HM_Brand__c = 'Brand 1';
        objCase.HM_Case_Status__c = 'open';
        objCase.HM_Case_Type__c = 'case';
        objCase.HM_Text_Language__c = 'en';
        objCase.HM_Case_Id__c = 'Test12345';
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
        
        objCase.HM_Sync_Secondary_Operators_in_Hi_Marley__c = true;
        update objCase;
    }
    
    @IsTest
    public static void test_case3(){
        
        //Create a Test Case Data
        Case objCase = new Case();
        objCase.Origin = 'Phone';
        objCase.HM_Brand__c = 'Brand 1';
        objCase.HM_Case_Status__c = 'open';
        objCase.HM_Case_Type__c = 'case';
        objCase.HM_Text_Language__c = 'en';
        objCase.HM_Case_Id__c = 'Test12345';
        objCase.HM_Enable_Notifications__c = true;
        objCase.HM_Case_Status__c = 'Open';
        insert objCase;
        delete objCase;
        
        //Create a Test Case Data
        Case objCase2 = new Case();
        objCase2.Origin = 'Phone';
        objCase2.HM_Brand__c = 'Brand 1';
        objCase2.HM_Case_Status__c = 'open';
        objCase2.HM_Case_Type__c = 'case';
        objCase2.HM_Text_Language__c = 'en';
        objCase2.HM_Case_Id__c = 'Test12345';
        objCase2.HM_Enable_Notifications__c = false;
        objCase2.HM_Case_Status__c = 'Open';
        insert objCase2;
        delete objCase2;
    }
    
    @IsTest
    public static void test_case4(){
        
        //Create a Test Case Data
        Case objCase = new Case();
        objCase.Origin = 'Phone';
        objCase.HM_Brand__c = 'Brand 1';
        objCase.HM_Case_Status__c = 'open';
        objCase.HM_Case_Type__c = 'case';
        objCase.HM_Text_Language__c = 'en';
        objCase.HM_Resend_Welcome_Message__c = false;
        insert objCase;
        
        objCase.HM_Resend_Welcome_Message__c = true;
        update objCase;
    }
    
    @IsTest
    public static void test_case5(){
        
        //Create a Test Case Data
        Case objCase = new Case();
        objCase.Origin = 'Phone';
        objCase.HM_Brand__c = 'Brand 1';
        objCase.HM_Case_Status__c = 'open';
        objCase.HM_Case_Type__c = 'case';
        objCase.HM_Text_Language__c = 'en';
        objCase.HM_Case_Id__c = 'Test12345';
        objCase.HM_Secondary_Operators_Present_in_HM__c = 'Test123@gmail.com,';
        insert objCase;
        
        objCase.HM_Sync_Secondary_Operators_in_Hi_Marley__c = true;
        update objCase;
    }
    
    
}