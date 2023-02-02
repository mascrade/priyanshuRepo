/*
* Name               : HM_Select_SMS_Template
* Description        : Apex Controller of Add/Edit LWC and SMS template Creation LWC
* Author             : Rohit (Futran Solutions)
* Created On         : 29 August 2022
* Test Class         : HM_Test_HM_SMSTempApexController
* Change Log History : 
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Rohit              | 29 Aug 2022 |-Initial Version of Apex Class---|
*  |------------------------------------------------------------------------------|
*/
public with sharing class HM_Select_SMS_Template {
    
    @AuraEnabled(cacheable=true)
    public static List<TemplateWrapper> GetAllSMSTemplates() {
        
        List<HM_SMS_Template__c> lstTemplates = [SELECT Id, HM_Is_Active__c,HM_Template_Body__c , HM_Name__c, Name, HM_Object_Name__c
                                                 FROM HM_SMS_Template__c 
                                                 WHERE HM_Is_Active__c = true and
                                                 HM_Object_Name__c = 'Case' WITH SECURITY_ENFORCED];
        //system.debug('lstTemplates-----------'+lstTemplates);
        
        List<TemplateWrapper> lstTempWrapper= new List<TemplateWrapper>();
        
        if(lstTemplates != null && lstTemplates.size() >0){
            for (HM_SMS_Template__c objTemp:lstTemplates){
                TemplateWrapper objTempWrapper= new TemplateWrapper();
                objTempWrapper.TemplateId = objTemp.Id;
                objTempWrapper.IsActive = objTemp.HM_Is_Active__c;
                objTempWrapper.TemplateName = objTemp.HM_Name__c;
                objTempWrapper.objName = objTemp.HM_Object_Name__c;
                
                if(objTemp.HM_Template_Body__c == '' || objTemp.HM_Template_Body__c == null || string.isBlank(objTemp.HM_Template_Body__c)){
                    objTempWrapper.Body = '';
                }else{
                    objTempWrapper.Body = objTemp.HM_Template_Body__c;
                }
                
                lstTempWrapper.add(objTempWrapper);
            }
        }
        return lstTempWrapper;
    }
    
    @AuraEnabled(cacheable=true)
    public static SObject getDataForUpdateTemplate(string objId, string QueryString, String objName) {
        
        //system.debug('-------------In Apex Controller HM_Select_SMS_Template ----getCaseDataForUpdateTemplate-------------'); 
        system.debug('objId-->'+objId);
        system.debug('objName-->'+objName);
        system.debug('QueryString-->'+QueryString);
        string queryStr = 'SELECT '+QueryString+' FROM '+objName+' WHERE Id =:objId';
        system.debug('queryStr-->'+queryStr);

      //  SObjectType sObjName = ((SObject) Type.forName(objName).newInstance()).getSObjectType();
      //  System.debug('sObjName = '+sObjName);

        SObject queryResult;   //<---
        try{
            queryResult = Database.query(queryStr);
            system.debug('Database.query(query)-----------'+queryResult);
            return queryResult;
        }
        catch(Exception e){
            system.debug('Exception Message in HM_Select_SMS_Template-----------'+e.getMessage());
            return queryResult;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Case getCaseDataForUpdateTemplate(string CaseId, string QueryString) {
        
        //system.debug('-------------In Apex Controller HM_Select_SMS_Template ----getCaseDataForUpdateTemplate-------------'); 
        system.debug('CaseId-->'+CaseId);
        system.debug('QueryString-->'+QueryString);
        string queryStr = 'SELECT '+QueryString+' FROM Case WHERE Id =:CaseId';
        system.debug('queryStr-->'+queryStr);
        Case queryResult;
        try{
            queryResult = Database.query(queryStr);
            system.debug('Database.query(query)-----------'+queryResult);
            return queryResult;
        }
        catch(Exception e){
            system.debug('Exception Message in HM_Select_SMS_Template-----------'+e.getMessage());
            return queryResult;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static User getOwnerDataForUpdateTemplate(string CaseId, string QueryString) {
        //system.debug('-------------In Apex Controller HM_Select_SMS_Template ----For Owner Details-------------'); 
        system.debug('CaseId-->'+CaseId);
        system.debug('QueryString for User/Owner details-->'+QueryString);
        
        Case objCase = [SELECT Id, OwnerId FROM Case WHERE Id=:CaseId];
        string UserId = objCase.OwnerId;
        string queryUserStr = 'SELECT '+QueryString+' FROM User WHERE Id =:UserId';
        system.debug('queryUserStr for User-->'+queryUserStr);
        User queryUserResult;
        try{
            queryUserResult = Database.query(queryUserStr);
            system.debug('Database.query(queryUserStr) -----------'+queryUserResult);
            return queryUserResult;
        }
        catch(Exception e){
            system.debug('Exception Message in HM_Select_SMS_Template-----------'+e.getMessage());
            return queryUserResult;
        }
    }
    
    
    // wrapper class for Template related fields
    public class TemplateWrapper{
        @AuraEnabled
        public string TemplateId;
        @AuraEnabled
        public string TemplateName;
        @AuraEnabled
        public boolean IsActive;
        @AuraEnabled
        public string Body;
        @AuraEnabled
        public string objName;
        
    }

}