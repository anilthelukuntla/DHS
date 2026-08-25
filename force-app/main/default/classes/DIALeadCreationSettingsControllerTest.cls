@isTest
public class DIALeadCreationSettingsControllerTest {
	testMethod private static void TestDIALeadCreationSettingsController(){ 
    	Auto_Lead_Generation_Template__c temp = new Auto_Lead_Generation_Template__c(Name__c='Test');
        insert temp;
        Auto_Lead_Generation_Setting__c setting = new Auto_Lead_Generation_Setting__c();
        setting.Auto_Lead_Generation_Template__c =temp.id;
        setting.Coverage_Type__c = 'Personal';
        setting.Item_number__c = 1;
        setting.Lead_Type__c = 'UnEmployment';
        insert setting;
        DIALeadCreationSettingsController ctrl = new DIALeadCreationSettingsController();
        ctrl.selectedTemplate = temp.id;
        ctrl.FetchSettingsOfTemplate();
        ctrl.CreateNewTemplate();
        ctrl.newTemplate.name__c = 'Test2';
        ctrl.Savetemplate();
        ctrl.addsetting();
        list<DIALeadCreationSettingsController.SettingRecord> settingRecords = ctrl.autoLeadGenerationSettings;
        
        integer i = 0;
        for(DIALeadCreationSettingsController.SettingRecord sr: settingRecords){
            Auto_Lead_Generation_Setting__c setting1 = sr.setting;
            setting1.Coverage_Type__c = 'Personal';
            setting1.Item_number__c = i;
            setting1.Lead_Type__c = 'UnEmployment';
            i++;
        }
        ctrl.SaveSettings();
        
        
    }
}