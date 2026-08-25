public class DIALeadCreationSettingsController {
    public list<Auto_Lead_Generation_Template__c> leadTemplates {get;set;}
	public list<selectoption> leadTemplateOptions {get;set;}    
    public list<SettingRecord> autoLeadGenerationSettings {get;set;}
    public DIALeadCreationSettingsController(){
        FetchLeadGenerationTemplates();
        showSettingsPanel = false;
        showtemplatecreatepanel = false;
        selectedTemplate = apexpages.currentpage().getparameters().get('templateid');
        if(string.isNotBlank(selectedTemplate)){
        	showSettingsPanel = true; 
            FetchSettingsOfTemplate();
        }
    }
    
    
    public void FetchLeadGenerationTemplates(){
    	leadTemplates = new list<Auto_Lead_Generation_Template__c>();
        leadTemplates = [select Id,Name__c from Auto_Lead_Generation_Template__c];
        leadTemplateOptions = new list<selectoption>();
        leadTemplateOptions.add(new selectoption('','--None--'));
        for(Auto_Lead_Generation_Template__c template: leadTemplates){
        	leadTemplateOptions.add(new selectoption(template.id,template.Name__c));    
        }
    }
    public string selectedTemplate {get;set;}
    public boolean showSettingsPanel{get;set;}
    public void FetchSettingsOfTemplate(){
        showSettingsPanel = true;
        if(string.isBlank(selectedTemplate)) showSettingsPanel = false;
    	autoLeadGenerationSettings = new list<SettingRecord>();
        List<string> autoLeadGenerationSettingsFields = new List<string>();
        autoLeadGenerationSettingsFields = ApexUtil.FetchFields('Auto_Lead_Generation_Setting__c');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(autoLeadGenerationSettingsFields, ',') + ' From Auto_Lead_Generation_Setting__c WHERE Auto_Lead_Generation_Template__c =:selectedTemplate Order by Item_Number__c ';
        System.debug('query...'+query);
        list<Auto_Lead_Generation_Setting__c> autoLeadGenerationSettingrecords = database.query(query);
        System.debug('autoLeadGenerationSettingrecords...'+autoLeadGenerationSettingrecords);
        for(Auto_Lead_Generation_Setting__c algs: autoLeadGenerationSettingrecords){
        	autoLeadGenerationSettings.add(new SettingRecord(algs,true));	   
        }        
    }
    public Auto_Lead_Generation_Template__c newTemplate {get;set;}
    public boolean showtemplatecreatepanel {Get;set;}
    public void CreateNewTemplate(){
        showtemplatecreatepanel = true;
        showSettingsPanel = false; 
     	newTemplate = new  Auto_Lead_Generation_Template__c(); 
        selectedTemplate = null;
    }
    public void Savetemplate(){
        showtemplatecreatepanel = false;
    	insert newTemplate;
        FetchLeadGenerationTemplates();
        selectedTemplate = newTemplate.id;
        FetchSettingsOfTemplate();
    }
    
    /*public void FetchSettings(){
    	autoLeadGenerationSettings = new list<SettingRecord>();
        List<string> autoLeadGenerationSettingsFields = new List<string>();
        autoLeadGenerationSettingsFields = ApexUtil.FetchFields('Auto_Lead_Generation_Setting__c');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(autoLeadGenerationSettingsFields, ',') + ' From Auto_Lead_Generation_Setting__c WITH SECURITY_ENFORCED Order by Item_Number__c ';
        System.debug('query...'+query);
        list<Auto_Lead_Generation_Setting__c> autoLeadGenerationSettingrecords = database.query(query);
        System.debug('autoLeadGenerationSettingrecords...'+autoLeadGenerationSettingrecords);
        for(Auto_Lead_Generation_Setting__c algs: autoLeadGenerationSettingrecords){
        	autoLeadGenerationSettings.add(new SettingRecord(algs,true));	   
        }    
    }*/
    public void addsetting(){
        autoLeadGenerationSettings.add(new SettingRecord(new Auto_Lead_Generation_Setting__c(Auto_Lead_Generation_Template__c = selectedTemplate),false));	   
	}
	public Integer settingIndex {get; set;}
	public void removesetting(){
        System.debug('settingIndex...'+settingIndex);
		settingIndex = Integer.valueOf(ApexPages.currentPage().getParameters().get('settingIndex'));
		autoLeadGenerationSettings.remove(settingIndex);
	}
    
    public void UpdateAutoLeadGenerationSettings(){
        list<Auto_Lead_Generation_Setting__c> algsToUpdate = new list<Auto_Lead_Generation_Setting__c>();
        for(settingRecord sr: autoLeadGenerationSettings){
        	algsToUpdate.add(sr.setting);    
        }
        update algsToUpdate;
    }
    
    public void SaveSettings(){
		list<Auto_Lead_Generation_Setting__c> algsToUpsert = new list<Auto_Lead_Generation_Setting__c>();
        for(settingRecord sr: autoLeadGenerationSettings){
        	algsToUpsert.add(sr.setting);    
        }
        upsert algsToUpsert;
        FetchSettingsOfTemplate();
	}
    public string settingIdToDelete {Get;set;}
    public void DeleteSetting(){
   		system.debug('settingIdToDelete....'+settingIdToDelete);
        delete [select id from Auto_Lead_Generation_Setting__c where id=:settingIdToDelete];
        FetchSettingsOfTemplate();
    }
    public class SettingRecord{
        public Auto_Lead_Generation_Setting__c setting {get;set;}
        public boolean recordCreated {get;set;}
        public SettingRecord(Auto_Lead_Generation_Setting__c setting,boolean recordCreated){
        	this.setting = setting;
            this.recordCreated = recordCreated;
        }
    }
}