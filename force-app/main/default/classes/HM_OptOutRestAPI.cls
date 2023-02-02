/*
* Name               : HM_OptOutRestAPI
* Description        : Apex REST Resource for setting Opt Out--API Endpoint to set 'Is Opted In' field equal to false in Salesforce when a User replies 'STOP' in Hi Marley.
* Author             : Rohit (Futran Solutions)
* Created On         : 5 Aug 2022
* Test Class         : HM_Test_OptIn_OptOut
* Change Log History :
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Rohit              |  5 Aug 2022 | Initial Version of Apex Class---|
*  |------------------------------------------------------------------------------|
*/
@RestResource(urlMapping='/setOptOut/*')
global class HM_OptOutRestAPI {
    
    @HttpPost
    global static String optOut(){ 
        RestContext objRestContext;
        return HM_OptIn_OptOut_Helper.handleJSON(objRestContext , false);
    }
    
}