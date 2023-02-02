/*
* Name               : HM_Test_Inbound_SMS_Creation
* Description        : This Test Class covers HM_Inbound_SMS_Creation Apex Class.
* Author             : Team Futran 
* Created On         : 19 Aug 2022
* Test Class         : HM_Test_Create_ChatLog_In_SF
* Change Log History :
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Team Futran        | 19 Aug 2022 | Initial Version of Apex Class---|
*  |------------------------------------------------------------------------------|
*/
@isTest
public class HM_Test_Inbound_SMS_Creation {
    
    @testSetup 
    public static void testData() {
        
        //get User
        User objUser = [select id, Name,Profile.Name from User where Profile.Name = 'System Administrator' limit 1];
        
        //create Custom Setting data
        List<HM_Message_Fields_Mapping_Inbound__c> lstMsgField = new List<HM_Message_Fields_Mapping_Inbound__c>();
        
        //HM Case Id : id : caseData
        HM_Message_Fields_Mapping_Inbound__c objMsgField1 = new HM_Message_Fields_Mapping_Inbound__c(
            Name = 'id',
            HM_JSON_Sub_Object_Name__c = 'caseData',
            HM_SF_Field__c = 'HM_Case_Id__c',
            HM_SF_Object_Name__c = 'Case');
        lstMsgField.add(objMsgField1);
        
        //HM Customer Id : id : customer
        HM_Message_Fields_Mapping_Inbound__c objMsgField2 = new HM_Message_Fields_Mapping_Inbound__c(
            Name = 'customerId',
            HM_JSON_Sub_Object_Name__c = 'customer',
            HM_SF_Field__c = 'HM_User_Id__c',
            HM_SF_Object_Name__c = 'Contact');
        lstMsgField.add(objMsgField2);
        
        //messageId : id : messages
        HM_Message_Fields_Mapping_Inbound__c objMsgField3 = new HM_Message_Fields_Mapping_Inbound__c(
            Name = 'messageId',
            HM_JSON_Sub_Object_Name__c = 'messages',
            HM_SF_Field__c = 'HM_Message_Id__c	',
            HM_SF_Object_Name__c = 'Chat Log');
        lstMsgField.add(objMsgField3);
        
        //type : messages
        HM_Message_Fields_Mapping_Inbound__c objMsgField4 = new HM_Message_Fields_Mapping_Inbound__c(
            Name = 'type',
            HM_JSON_Sub_Object_Name__c = 'messages',
            HM_SF_Field__c = 'HM_Message_Type__c',
            HM_SF_Object_Name__c = 'Chat Log');
        lstMsgField.add(objMsgField4);
        
        //formatting : messages
        HM_Message_Fields_Mapping_Inbound__c objMsgField5 = new HM_Message_Fields_Mapping_Inbound__c(
            Name = 'formatting',
            HM_JSON_Sub_Object_Name__c = 'messages',
            HM_SF_Field__c = 'HM_Formatting__c',
            HM_SF_Object_Name__c = 'Chat Log');
        lstMsgField.add(objMsgField5);
        
        //data : messages
        HM_Message_Fields_Mapping_Inbound__c objMsgField6 = new HM_Message_Fields_Mapping_Inbound__c(
            Name = 'data',
            HM_SF_Field__c = 'HM_Message_Data__c',
            HM_SF_Object_Name__c = 'Chat Log',
            HM_JSON_Sub_Object_Name__c = 'messages');
        lstMsgField.add(objMsgField6);
        
        //channelSource : messages
        HM_Message_Fields_Mapping_Inbound__c objMsgField7 = new HM_Message_Fields_Mapping_Inbound__c(
            Name = 'channelSource',
            HM_SF_Field__c = 'HM_Channel_Source__c',
            HM_SF_Object_Name__c = 'Chat Log',
            HM_JSON_Sub_Object_Name__c = 'messages');
        lstMsgField.add(objMsgField7);
        
        //id : author
        HM_Message_Fields_Mapping_Inbound__c objMsgField8 = new HM_Message_Fields_Mapping_Inbound__c(
            Name = '_id',
            HM_SF_Field__c = 'HM_Author_Id__c	',
            HM_SF_Object_Name__c = 'Chat Log',
            HM_JSON_Sub_Object_Name__c = 'author');
        lstMsgField.add(objMsgField8);
        
        //firstName : profile
        HM_Message_Fields_Mapping_Inbound__c objMsgField9 = new HM_Message_Fields_Mapping_Inbound__c(
            Name = 'firstName',
            HM_SF_Field__c = 'HM_Author_First_Name__c',
            HM_SF_Object_Name__c = 'Chat Log',
            HM_JSON_Sub_Object_Name__c = 'profile');
        lstMsgField.add(objMsgField9);
        
        //lastName : profile
        HM_Message_Fields_Mapping_Inbound__c objMsgField10 = new HM_Message_Fields_Mapping_Inbound__c(
            Name = 'lastName',
            HM_SF_Field__c = 'HM_Author_Last_Name__c',
            HM_SF_Object_Name__c = 'Chat Log',
            HM_JSON_Sub_Object_Name__c = 'profile');
        lstMsgField.add(objMsgField10);
        
        //createdAt : messages
        HM_Message_Fields_Mapping_Inbound__c objMsgField11 = new HM_Message_Fields_Mapping_Inbound__c(
            Name = 'createdAt',
            HM_SF_Field__c = 'HM_Created_At__c',
            HM_SF_Object_Name__c = 'Chat Log',
            HM_JSON_Sub_Object_Name__c = 'messages');
        lstMsgField.add(objMsgField11);
        
        //dateFormatted : messages
        HM_Message_Fields_Mapping_Inbound__c objMsgField12 = new HM_Message_Fields_Mapping_Inbound__c(
            Name = 'dateFormatted',
            HM_SF_Field__c = 'HM_Date_Formatted__c',
            HM_SF_Object_Name__c = 'Chat Log',
            HM_JSON_Sub_Object_Name__c = 'messages');
        lstMsgField.add(objMsgField12);
        
        //timeFormatted : messages
        HM_Message_Fields_Mapping_Inbound__c objMsgField13 = new HM_Message_Fields_Mapping_Inbound__c(
            Name = 'timeFormatted',
            HM_SF_Field__c = 'HM_Time_Formatted__c',
            HM_SF_Object_Name__c = 'Chat Log',
            HM_JSON_Sub_Object_Name__c = 'messages');
        lstMsgField.add(objMsgField13);
        
        insert lstMsgField;
        
        //1. Create test Contact
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
        
        
    }
   
    @isTest
    public static void testMethod1(){
        
        //covers SUCCESS channelSource is mobile
        String sJsonMsg = '{ "caseData":{ "id": "abc123"}, "customer": { "id": "pqr123"}, "messages":[{"id": "aaa","type": "text","formatting": "standard","data": "hello","channelSource": "mobile","author":{ "_id": "bbb", "profile":{ "firstName": "Smith", "lastName": "John"}},"createdAt": "2021-08-12T15:18:51.580Z","dateFormatted": "08-12-2021","timeFormatted": "11:18:51 AM EDT"}],"primaryContact":{"id": "9fd6268f-ffec-49b7-8447-6ee247efad7a","first": "Gene","last": "Tetreault","email": "gene.tetreault@himarley.com","role": "operator"}}';
        callCreateChatLog(sJsonMsg);
        
        //covers SUCCESS channelSource is mobile
        String sJsonMsgMarley = '{ "caseData":{ "id": "abc123"}, "customer": { "id": "pqr123"}, "messages":[{"id": "aaa","type": "text","translatedText":"hola","formatting": "standard","data": "hello","channelSource": "marley","author":{ "_id": "bbb", "profile":{ "firstName": "Smith", "lastName": "John"}},"createdAt": "2021-08-12T15:18:51.580Z","dateFormatted": "08-12-2021","timeFormatted": "11:18:51 AM EDT"}],"primaryContact":{"id": "9fd6268f-ffec-49b7-8447-6ee247efad7a","first": "Gene","last": "Tetreault","email": "gene.tetreault@himarley.com","role": "operator"}}';
        callCreateChatLog(sJsonMsgMarley);
        
        //covers FAILURE
        String sEmptyJsonMsg = '{}';
        //callCreateChatLog(sEmptyJsonMsg);
        
        //covers FAILURE
        String sWrongCustomerIdJsonMsg = '{ "caseData":{ "id": "abc123"}, "customer": { "id": "mno"}, "messages":[{"id": "aaa","type": "text","formatting": "standard","data": "hello","channelSource": "mobile","author":{ "_id": "bbb", "profile":{ "firstName": "Smith", "lastName": "John"}},"createdAt": "2021-08-12T15:18:51.580Z","dateFormatted": "08-12-2021","timeFormatted": "11:18:51 AM EDT"}],"primaryContact":{"id": "9fd6268f-ffec-49b7-8447-6ee247efad7a","first": "Gene","last": "Tetreault","email": "gene.tetreault@himarley.com","role": "operator"}}';
        //callCreateChatLog(sWrongCustomerIdJsonMsg);
        
        //covers FAILURE
        String sEmptyCustomerIdJsonMsg = '{ "caseData":{ "id": "abc123"}, "customer": { "id": ""}, "messages":[{"id": "aaa","type": "text","formatting": "standard","data": "hello","channelSource": "mobile","author":{ "_id": "bbb", "profile":{ "firstName": "Smith", "lastName": "John"}},"createdAt": "2021-08-12T15:18:51.580Z","dateFormatted": "08-12-2021","timeFormatted": "11:18:51 AM EDT"}],"primaryContact":{"id": "9fd6268f-ffec-49b7-8447-6ee247efad7a","first": "Gene","last": "Tetreault","email": "gene.tetreault@himarley.com","role": "operator"}}';
        callCreateChatLog(sEmptyCustomerIdJsonMsg);
        
        //covers FAILURE
        String sWrongCaseIdJsonMsg = '{ "caseData":{ "id": "jkl"}, "customer": { "id": "pqr123"}, "messages":[{"id": "aaa","type": "text","formatting": "standard","data": "hello","channelSource": "mobile","author":{ "_id": "bbb", "profile":{ "firstName": "Smith", "lastName": "John"}},"createdAt": "2021-08-12T15:18:51.580Z","dateFormatted": "08-12-2021","timeFormatted": "11:18:51 AM EDT"}],"primaryContact":{"id": "9fd6268f-ffec-49b7-8447-6ee247efad7a","first": "Gene","last": "Tetreault","email": "gene.tetreault@himarley.com","role": "operator"}}';
        callCreateChatLog(sWrongCaseIdJsonMsg);
        
        //covers FAILURE
        String sEmptyCaseIdJsonMsg = '{ "caseData":{ "id": ""}, "customer": { "id": "pqr123"}, "messages":[{"id": "aaa","type": "text","formatting": "standard","data": "hello","channelSource": "mobile","author":{ "_id": "bbb", "profile":{ "firstName": "Smith", "lastName": "John"}},"createdAt": "2021-08-12T15:18:51.580Z","dateFormatted": "08-12-2021","timeFormatted": "11:18:51 AM EDT"}],"primaryContact":{"id": "9fd6268f-ffec-49b7-8447-6ee247efad7a","first": "Gene","last": "Tetreault","email": "gene.tetreault@himarley.com","role": "operator"}}';
        callCreateChatLog(sEmptyCaseIdJsonMsg);
        
    }	
    @future(callout = true)
    public static void callCreateChatLog(String sJsonMsg){
        RestRequest objRequest = new RestRequest(); 
        RestResponse objResponse = new RestResponse();
        
        objRequest.requestBody = Blob.valueof(sJsonMsg);
        
        objRequest.requestURI = '/services/apexrest/TextMessageService/';
        objRequest.httpMethod = 'POST';
        
        RestContext.request = objRequest;
        RestContext.response = objResponse;
        
        //call endpoint
        Test.setMock(HttpCalloutMock.class, new HM_Mock_ResponseImage());
        HM_Inbound_SMS_Creation.createChatLog();
     
    }
     
    @isTest
    public static void testMethod2(){
        //covers SUCCESS channelSource is ai
        String sJsonMsgAI = '{ "caseData":{ "id": "abc123"}, "customer": { "id": "pqr123"}, "messages":[{"id": "aaa","type": "text","formatting": "standard","data": "hello","channelSource": "ai","author":{ "_id": "bbb", "profile":{ "firstName": "Smith", "lastName": "John"}},"createdAt": "2021-08-12T15:18:51.580Z","dateFormatted": "08-12-2021","timeFormatted": "11:18:51 AM EDT"}],"primaryContact":{"id": "9fd6268f-ffec-49b7-8447-6ee247efad7a","first": "Gene","last": "Tetreault","email": "gene.tetreault@himarley.com","role": "operator"}}';
        callCreateChatLog(sJsonMsgAI);
    }
    
	@isTest
    public static void testMethod3(){
        //img
        String sJsonMsgImg = '{ "caseData":{ "id": "abc123"}, "customer": { "id": "pqr123"}, "messages":[{"id": "aaa","type": "image","formatting": "standard","data": "https://example.com/example/test","channelSource": "mobile","author":{ "_id": "bbb", "profile":{ "firstName": "Smith", "lastName": "John"}},"createdAt": "2021-08-12T15:18:51.580Z","dateFormatted": "08-12-2021","timeFormatted": "11:18:51 AM EDT"}],"primaryContact":{"id": "9fd6268f-ffec-49b7-8447-6ee247efad7a","first": "Gene","last": "Tetreault","email": "gene.tetreault@himarley.com","role": "operator"}}';
        callCreateChatLog(sJsonMsgImg);
    }    
    

    public class HM_Mock_ResponseImage implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
         //   response.setBody('abc');
            response.setBodyAsBlob(Blob.valueOf('abcdfgjkl;;jhjk'));
          
            return response; 
        }
    }	
}