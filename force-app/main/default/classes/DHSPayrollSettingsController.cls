/**
 * @description Controls display and update of DHS payroll settings.
 */

public with sharing class DHSPayrollSettingsController {
    /** @description Provides this DHS API member. */
    public list<DHS_PayrollSetting__c> payrollSettings {get;set;}
    /** @description Provides this DHS API member. */
    public DHSPayrollSettingsController(){
        fetchPayrollSettings();   
    }
    /** @description Provides this DHS API member. */
    public void fetchPayrollSettings(){
        payrollSettings = new list<DHS_PayrollSetting__c>();
        List<string> payrollSettingsFields = new List<string>();
        payrollSettingsFields = DHSApexUtil.FetchFields('DHS_PayrollSetting__c');
        String query = 'Select '+string.join(payrollSettingsFields, ',') + ' From DHS_PayrollSetting__c Order by Order__c';
        payrollSettings = database.query(query, AccessLevel.USER_MODE);
    }
    
    /** @description Provides this DHS API member. */
    public void updatePayrollSettings(){
        database.update(payrollSettings,false,AccessLevel.USER_MODE);
    }
}