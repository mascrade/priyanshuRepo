/*
* Name               : HM_Test_HM_Create_CaseIn_SF
* Description        : Apex test class covers Code Coverage of below Apex Classes.
					   (HM_Create_CaseIn_SF, HM_Case_Close_reOpen_in_SF)
* Author             : Rohit (Futran Solutions)
* Created On         : 03 August 2022
* Change Log History : 
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Rohit              | 03 Aug 2022 | Initial Version of Apex Class---|
*  |------------------------------------------------------------------------------|
*/

@isTest
public class HM_Test_HM_Create_CaseIn_SF {
    
    @isTest
    public static void CreateCaseTestClass(){
        
        Contact objContact = new Contact(
        FirstName = 'mno',
        LastName = 'Abc',
        Title = 'VP',
        MobilePhone = '+1962365233');
        insert objContact;
        
        //insert Custom Setting
        List<HM_Case_Fields_Mapping_Inbound__c> lstCaseFieldMapping = new List<HM_Case_Fields_Mapping_Inbound__c>();
        
        HM_Case_Fields_Mapping_Inbound__c brand = new HM_Case_Fields_Mapping_Inbound__c(Name='brand',HM_SF_Field__c='HM_Brand__c',HM_SF_Object_Name__c='Case',HM_API_sub_Object_Name__c='caseData');
        HM_Case_Fields_Mapping_Inbound__c archived = new HM_Case_Fields_Mapping_Inbound__c(Name='archived',HM_SF_Field__c='HM_Archived__c',HM_SF_Object_Name__c='Case',HM_API_sub_Object_Name__c='caseData');
        HM_Case_Fields_Mapping_Inbound__c caseType = new HM_Case_Fields_Mapping_Inbound__c(Name='caseType',HM_SF_Field__c='HM_Case_Type__c',HM_SF_Object_Name__c='Case',HM_API_sub_Object_Name__c='caseType');
        HM_Case_Fields_Mapping_Inbound__c claimNumber = new HM_Case_Fields_Mapping_Inbound__c(Name='claimNumber',HM_SF_Field__c='HM_Claim_Number__c',HM_SF_Object_Name__c='Case',HM_API_sub_Object_Name__c='caseData');
        HM_Case_Fields_Mapping_Inbound__c ContactId = new HM_Case_Fields_Mapping_Inbound__c(Name='ContactId',HM_SF_Field__c='ContactId',HM_SF_Object_Name__c='Case',HM_API_sub_Object_Name__c='customer');
        HM_Case_Fields_Mapping_Inbound__c dateOfLoss = new HM_Case_Fields_Mapping_Inbound__c(Name='dateOfLoss',HM_SF_Field__c='HM_Date_of_Loss__c',HM_SF_Object_Name__c='Case',HM_API_sub_Object_Name__c='caseData');
        HM_Case_Fields_Mapping_Inbound__c objId= new HM_Case_Fields_Mapping_Inbound__c(Name='id',HM_SF_Field__c='HM_Case_Id__c',HM_SF_Object_Name__c='Case',HM_API_sub_Object_Name__c='caseData');
        HM_Case_Fields_Mapping_Inbound__c state = new HM_Case_Fields_Mapping_Inbound__c(Name='state',HM_SF_Field__c='HM_Case_Status__c',HM_SF_Object_Name__c='Case',HM_API_sub_Object_Name__c='state');
       
        lstCaseFieldMapping.add(brand);
        lstCaseFieldMapping.add(archived);
        lstCaseFieldMapping.add(caseType);
        lstCaseFieldMapping.add(claimNumber);
        lstCaseFieldMapping.add(ContactId);
        lstCaseFieldMapping.add(dateOfLoss);
        lstCaseFieldMapping.add(objId);
        lstCaseFieldMapping.add(state);
        insert lstCaseFieldMapping;
        system.debug('lstCaseFieldMapping--'+lstCaseFieldMapping);
        
        HM_Branding__c objbranding = new HM_Branding__c();
        objbranding.Name = 	'Branding';
        objbranding.HM_Enable_Branding__c = true;
        insert objbranding;
        
        HM_User_Mobile_Field_Mapping__c objMobFieldMapping = new HM_User_Mobile_Field_Mapping__c();
        objMobFieldMapping.Name = 'mobile';
        objMobFieldMapping.HM_SF_Field__c='MobilePhone';
        insert objMobFieldMapping;
        
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
        sUser.HM_Operator_Id__c = '123456799-ABC';
        insert sUser;
        
        RestRequest CaseCreationRequest = new RestRequest(); 
        RestResponse CaseCreationResponse = new RestResponse();
        String jsonMsg = '{"caseData": {"claimNumber": "956472","dateOfLoss": "2021-10-01T16:00:00.000Z","brand": "Brand 1","id": "66666666","archived": true},"state": "closed","caseType": "claim","customer": {"id": "5555555","first": "Optimus","last": "Prime","email":"bhushan@sampleinsurance.com","mobile": "+1962365233","role": "enduser","optStatus": true,"optStatusDetail": "OPTED_IN"},"primaryContact": {"id": "123456799-ABC","first": "Carrier","last": "Adjuster","email": "carrier.adjuster@carrier.org","role": "operator"}}';
        CaseCreationRequest.requestBody = Blob.valueof(jsonMsg);
        
        CaseCreationRequest.requestURI = '/services/apexrest/HM_Create_CaseIn_SF/';
        CaseCreationRequest.httpMethod = 'POST';
        
        RestContext.request = CaseCreationRequest;
        RestContext.response= CaseCreationResponse;
        
        Test.startTest();
        HM_Create_CaseIn_SF.createCASE();
        HM_Case_Close_reOpen_in_SF.Close_OR_ReopenCASE();
        HM_Update_Case_And_Contact.updateCASE();
        Test.stopTest();
    } 
}