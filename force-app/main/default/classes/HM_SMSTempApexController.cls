/*
* Name               : HM_SMSTempApexController
* Description        : Apex Controller of Add/Edit LWC and SMS template Creation LWC
* Author             : Rohit (Futran Solutions)
* Created On         : 18 August 2022
* Test Class         : HM_Test_HM_SMSTempApexController 
* Change Log History : 
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Rohit              | 18 Aug 2022 |-Initial Version of Apex Class---|
*  |------------------------------------------------------------------------------|
*/

public with sharing class HM_SMSTempApexController {
    
    @AuraEnabled(cacheable=true)
    public static List<TemplateWrapper> GetAllSMSTemplates() {
        List<HM_SMS_Template__c> lstTemplates;
        
        lstTemplates = [SELECT Id, HM_Is_Active__c,HM_Template_Body__c,
                        HM_Name__c, Name,CreatedBy.Name, CreatedDate,HM_Contact_API_Name__c,
                        LastModifiedBy.Name, LastModifiedDate, HM_Object_Name__c
                        FROM HM_SMS_Template__c];
        //system.debug('lstTemplates-----------'+lstTemplates);
        
        
        List<TemplateWrapper> lstTempWrapper= new List<TemplateWrapper>();
        
        if(lstTemplates != null && lstTemplates.size() >0){
            for (HM_SMS_Template__c objTemp:lstTemplates){
                TemplateWrapper objTempWrapper= new TemplateWrapper();
                objTempWrapper.TemplateId = objTemp.Id;
                objTempWrapper.IsActive = objTemp.HM_Is_Active__c;
                objTempWrapper.TemplateName= objTemp.HM_Name__c;
                
                if(objTemp.HM_Template_Body__c == '' || objTemp.HM_Template_Body__c == null || string.isBlank(objTemp.HM_Template_Body__c)){
                    objTempWrapper.Body = '';
                }else{
                    objTempWrapper.Body = objTemp.HM_Template_Body__c;
                }

                objTempWrapper.ObjName= objTemp.HM_Object_Name__c;
                objTempWrapper.CreatedByName= objTemp.CreatedBy.Name;
                objTempWrapper.CreatedDate= objTemp.CreatedDate.format('dd MMM YYYY');
                objTempWrapper.CreatedTime= objTemp.CreatedDate.format('hh:mm a');
                objTempWrapper.LastModifiedByName= objTemp.LastModifiedBy.Name;
                objTempWrapper.LastModifiedDate= objTemp.LastModifiedDate.format('dd MMM YYYY');
                objTempWrapper.LastModifiedTime= objTemp.LastModifiedDate.format('hh:mm a');
                objTempWrapper.contactLkName= objTemp.HM_Contact_API_Name__c;
                lstTempWrapper.add(objTempWrapper);
                //system.debug('lstTempWrapper-----------'+lstTempWrapper);
            }
        }
        return lstTempWrapper;
    }
        
        //GetFieldAPInames method will be called by handle_sObjectPicklist_Selection from js
        @AuraEnabled(cacheable=true)
        public static List<Map<String,String>> GetFieldAPInames(String SFObj) { 
//    public static Map<String,String> GetFieldAPInames(String SFObj) { 
        System.debug('SFObj = '+SFObj);
        SObjectType sObjName = ((SObject) Type.forName(SFObj).newInstance()).getSObjectType();
        System.debug('sObjName = '+sObjName);
        
        Map<String,String> mapsObjLabelvsAPInames = new Map<String,String>();
        Map<String,String> mapParentLabelvsLookUp = new Map<String,String>();
        Set<String> setParentNames = new Set<String>();
        List<Map<String,String>> lstToSerialize = new List<Map<String,String>>();

        for(Schema.SObjectField apiName: sObjName.getDescribe().fields.getMap().values()){
            
            //if the field is a 'reference' i.e. a parent of the sObject, store parent names in a set
            if(apiName.getDescribe().getType() == Schema.DisplayType.REFERENCE){
             
            String sObj = apiName.getDescribe().getReferenceTo()+''; 
            sObj = sObj.replace('(','');
            sObj = sObj.replace(')','');
            sObj = sObj.substringBefore(',');

            if(sObj != SFObj){
                if(sObj == 'User'){
                   sObj = 'Owner';     
                }
            setParentNames.add(sObj);     
            }
            system.debug('apiName parent = '+String.valueOf(apiName));

            string label = apiName.getDescribe().getLabel();
            string api = String.valueOf(apiName);
            
            if(sObj != 'Group'){
            mapParentLabelvsLookUp.put(sObj,String.valueOf(apiName));
            }
           
            }   

            string label = apiName.getDescribe().getLabel();
            string api = String.valueOf(apiName);
            
            mapsObjLabelvsAPInames.put(label,api);
        }

          system.debug('mapParentLabelvsLookUp = '+mapParentLabelvsLookUp);  
       
        //traverse set that contains Parent names and add them to map   
        if(setParentNames != null && setParentNames.size() > 0){
        for(String sParentName : setParentNames){   //sParentName stores the api name of sobject
           if(sParentName != 'Group'){
           string label = sParentName + ' >';
           mapsObjLabelvsAPInames.put(label,sParentName);
        }
      /*  if(sParentName == 'User'){
           string label = 'Owner' + ' >';
           mapsObjLabelvsAPInames.put(label,sParentName);
        }   */
        }
        }
        lstToSerialize.add(mapsObjLabelvsAPInames);   
        lstToSerialize.add(mapParentLabelvsLookUp);

        String sListOfMaps = JSON.serialize(lstToSerialize);
      //  System.debug('sListOfMaps = '+sListOfMaps);
      
      return lstToSerialize;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String,String> GetCaseFieldAPInames() {
        
        Map<String,String> mapCaseLabelvsAPInames = new  Map<String,String>();
        
        for(Schema.SObjectField apiName: Case.SObjectType.getDescribe().fields.getMap().values()){
            //System.debug('Label ---------------'+apiName.getDescribe().getLabel());
            //System.debug('apiName >> '+apiName);
            string label = apiName.getDescribe().getLabel();
            string api = String.valueOf(apiName);
            mapCaseLabelvsAPInames.put(label,api);
        }
        
        return mapCaseLabelvsAPInames;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String,String> GetContactFieldAPInames() {
        
        Map<String,String> mapContactLabelvsAPInames = new  Map<String,String>();
        
        for(Schema.SObjectField apiName: Contact.SObjectType.getDescribe().fields.getMap().values()){
            //System.debug('Label ---------------'+apiName.getDescribe().getLabel());
            //System.debug('apiName >> '+apiName);
            string label = apiName.getDescribe().getLabel();
            string api = String.valueOf(apiName);
            mapContactLabelvsAPInames.put(label,api);
        }
        
        return mapContactLabelvsAPInames;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static Map<String,String> GetUserFieldAPInames() {
        
        Map<String,String> mapUserLabelvsAPInames = new  Map<String,String>();
        
        for(Schema.SObjectField apiName: User.SObjectType.getDescribe().fields.getMap().values()){
            //System.debug('Label ---------------'+apiName.getDescribe().getLabel());
            //System.debug('apiName >> '+apiName);
            string label = apiName.getDescribe().getLabel();
            string api = String.valueOf(apiName);
            mapUserLabelvsAPInames.put(label,api);
        }
        
        return mapUserLabelvsAPInames;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String,String> GetAccountFieldAPInames() {
        
        Map<String,String> mapAccountLabelvsAPInames = new  Map<String,String>();
        
        for(Schema.SObjectField apiName: Account.SObjectType.getDescribe().fields.getMap().values()){
            //System.debug('Label ---------------'+apiName.getDescribe().getLabel());
            //System.debug('apiName >> '+apiName);
            string label = apiName.getDescribe().getLabel();
            string api = String.valueOf(apiName);
            mapAccountLabelvsAPInames.put(label,api);
        }
        
        return mapAccountLabelvsAPInames;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,String> GetCustomSettingObjectNames() {    
        //this method is used to query & fetch object names stored in custom settings
        Map<String,String> mapCustomSettingNamevsAPInames = new  Map<String,String>();

        List<sObject_Picklist__c> lstCustomSetting = sObject_Picklist__c.getall().values();
        System.debug('lstCustomSetting : '+lstCustomSetting);
        
        for(sObject_Picklist__c objCustomSetting: lstCustomSetting){
            string label = objCustomSetting.Name;
            string api = objCustomSetting.sObject_API_Name__c;
            
            mapCustomSettingNamevsAPInames.put(label,api);
        }
        System.debug('mapCustomSettingNamevsAPInames = '+mapCustomSettingNamevsAPInames);
        return mapCustomSettingNamevsAPInames;
    }    
    
    @AuraEnabled
    public static string deleteRecord(string TemplateIdToDelete) {
        //system.debug('TemplateIdToDelete : '+TemplateIdToDelete);
        try{
            if( string.isNotBlank(TemplateIdToDelete)){
                HM_SMS_Template__c objSMSTemplate = [SELECT Id, HM_Is_Active__c, Name 
                FROM HM_SMS_Template__c 
                WHERE Id =: TemplateIdToDelete];
                //system.debug('objQLI' +objSMSTemplate);
                if(objSMSTemplate != null){
                    Delete objSMSTemplate;
                }
            }
            return '** Record deleted successfully **';
        }
        catch(Exception e){
            //system.debug(e.getMessage());
            return '** Delete operation failed **';
        }
    }    
    
    @AuraEnabled
    public static string SaveTemplate(string TemplateIdToEdit, string TemplateName,Boolean IsActive,string Body, String selectedObject, String contactLookUpName){
        
        System.debug('Body = '+Body);
        System.debug('selectedObject = '+selectedObject);
        System.debug('TemplateIdToEdit = '+TemplateIdToEdit);
        System.debug('contactLookUpName = '+contactLookUpName);
        
        try{
            HM_SMS_Template__c objSMSTemplate = new HM_SMS_Template__c();
            objSMSTemplate.Id = TemplateIdToEdit;
            objSMSTemplate.HM_Name__c = TemplateName;
            objSMSTemplate.HM_Template_Body__c = Body;
            System.debug('objSMSTemplate.HM_Template_Body__c = '+objSMSTemplate.HM_Template_Body__c);
            system.debug('ISActive ===='+IsActive);
            objSMSTemplate.HM_Is_Active__c = IsActive;
            objSMSTemplate.HM_Object_Name__c = selectedObject;
            objSMSTemplate.HM_Contact_API_Name__c = contactLookUpName;

            if(String.isBlank(objSMSTemplate.HM_Template_Body__c)){
                System.debug('Template Body is Blank');
                return 'Template Body is Blank';
            }

            if(String.isBlank(objSMSTemplate.HM_Object_Name__c)){
                return 'Object Name is Blank';
            }

            if(String.isBlank(objSMSTemplate.HM_Contact_API_Name__c)){
                return 'Contact LookUp Name is Blank';
            }
            
            system.debug('objSMSTemplate.Id : '+objSMSTemplate.Id);
            
            //system.debug('objSMSTemplate to Insert / Update--' +objSMSTemplate);
            if(objSMSTemplate != null && objSMSTemplate.Id == null){
                system.debug('before insert');
                insert objSMSTemplate;
            }
            else if(objSMSTemplate != null && objSMSTemplate.Id != null){
                system.debug('before update');
                update objSMSTemplate;
            }
            return 'Success';
        }
        catch(Exception e){
            system.debug(e.getMessage());
            return e.getMessage();
        }
        //return 'Success';
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
        public string CreatedByName;
        @AuraEnabled
        public string CreatedDate;
        @AuraEnabled
        public string CreatedTime;
        @AuraEnabled
        public string LastModifiedByName;
        @AuraEnabled
        public string LastModifiedDate;
        @AuraEnabled
        public string LastModifiedTime;
        @AuraEnabled
        public string ObjName;
        @AuraEnabled
        public string contactLkName;
         
    }

}