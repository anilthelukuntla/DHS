public class ROIReportController {
    public string caseId {get;set;}
    public Case__c caseRecord {get;set;}
    public List<Lead__c> leads {get;set;}
    public user currentUser{get;set;}
    public integer totalLeads {get;set;}
    public String investigationDates {get;set;}
    public String investigators {get;set;}
    public map<string,integer> leadsCountMap {get;set;}
    public map<string,Lead__c> leadsMap {get;set;}
    public List<String> subjectInterviewList {get;set;}
    public List<String> subjectContactList {get;set;}
    public Map<String,Map<String,List<String>>> employmentMap {get;set;}
    public Map<String,Map<String,List<String>>> educationMap {get;set;}
    public Map<String,Map<String,List<String>>> medicalMap {get;set;}
    public List<String> residenceList {get;set;}
    public List<String> referencesList {get;set;}
    public List<String> generalLeadsList {get;set;}
    public List<String> formerSpouseList {get;set;}
    public List<String> unEmploymentList {get;set;}
    public List<String> lawEnforcementList {get;set;}
    public List<String> financialList {get;set;}
    public List<String> employmentList {get;set;}
    public List<String> educationList {get;set;}
    public List<String> medicalList {get;set;}
    
    

    public ROIReportController(){
        currentUser = [Select Id, User_Type__c FROM User where Id=:userinfo.getUserId()];
        caseId = apexpages.currentpage().getparameters().get('id');
        leadsCountMap = new map<string,integer>();
        totalLeads= 0;
        FetchCaseInformation();
        FetchLeadInformation();
    }
    
    public void FetchCaseInformation(){
        List<string> caseFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        caseFields = ApexUtil.FetchFields('Case__c');
        caseFields.add('contact__r.First_Name__c');
        caseFields.add('contact__r.Last_Name__c');
        caseFields.add('contact__r.Email__c');
        caseFields.add('contact__r.Address__c');
        caseFields.add('contact__r.City__c');
        caseFields.add('contact__r.State__c');
        caseFields.add('contact__r.Zip__c');
        caseFields.add('contact__r.SSN__c');
        String query = 'Select '+string.join(caseFields, ',') + ' From Case__c ';
        
        if(String.isNotBlank(caseId)){
            whereCriteria.add(new ApexUtil.Criteria('Id',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond; 
        System.debug('query...'+query);
        list<case__c> cases = database.query(query);
        if(!cases.isEmpty()){
            caseRecord = cases[0];
            if(caseRecord.investigations_review_Date__c != Null && caseRecord.QA_and_review_Date__c != Null){
                DateTime fromDate = DateTime.newInstance(caseRecord.investigations_review_Date__c.year(), caseRecord.investigations_review_Date__c.month(),caseRecord.investigations_review_Date__c.day());
                String fromDateFormatted = fromDate.format('MM/dd/yyyy');
                DateTime toDate = DateTime.newInstance(caseRecord.QA_and_review_Date__c.year(), caseRecord.QA_and_review_Date__c.month(),caseRecord.QA_and_review_Date__c.day());
                String toDateFormatted = toDate.format('MM/dd/yyyy');
                investigationDates = fromDateFormatted +' to '+ toDateFormatted;  
            } 
        }    
    }
    
    PUBLIC Map<String, Lead_RTA_Extension__c> subjectInterviewNLeadRTAExtension {get;set;}
    public void FetchLeadInformation(){
        leadsMap = new Map<String,Lead__c>();
        subjectInterviewNLeadRTAExtension = new Map<String, Lead_RTA_Extension__c>();
        leads = new List<Lead__c> ();
        List<string> leadFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        leadFields = ApexUtil.FetchFields('Lead__c');  
        leadFields.add('contact__r.First_Name__c');    
        leadFields.add('contact__r.Last_Name__c');   
        String query = 'Select '+string.join(leadFields, ',') + ' From Lead__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new ApexUtil.Criteria('case__c',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+ 'ORDER BY LeadType__c Asc'; 
        
        leads = database.query(query);
        System.debug('leads...'+leads);
        List<string> esiLeadIds = new List<String>();
        for(Lead__c lc: leads){
            if(lc.LeadType__c == 'Subject Interview (ESI/TESI)'){
                esiLeadIds.add(lc.id);
            }
        }
        
        List<Lead_RTA_Extension__c> leadRTAExtensions = [Select Id, Lead__c, Foreign_Activities__c, Foreign_Contacts__c, Foreign_Travel1__c, Foreign_Travel2__c
                                                         FROM Lead_RTA_Extension__c
                                                         WHERE Lead__c IN:esiLeadIds];
        
        for(Lead_RTA_Extension__c lrta: leadRTAExtensions){
            subjectInterviewNLeadRTAExtension.put(lrta.lead__c, lrta);
        }  
        
        for(String str: esiLeadIds){
            if(!subjectInterviewNLeadRTAExtension.keyset().contains(str)){
                subjectInterviewNLeadRTAExtension.put(str, new Lead_RTA_Extension__c());
            }
        }                                                
        
        for(lead__c l: leads){
            if(!leadsCountMap.containsKey(l.leadtype__c)){
                leadsCountMap.put(l.leadtype__c, 1);    
            }else{
                leadsCountMap.put(l.leadtype__c, leadsCountMap.get(l.leadtype__c)+1);    
            }
            totalLeads++;
            
            string assignedDate;
            if(l.Assignee_Date__c != Null){
             assignedDate = l.Assignee_Date__c.year()+'-'+l.Assignee_Date__c.month()+'-'+l.Assignee_Date__c.day();
            }
            string completedDate;
            if(l.Completed_Date__c != Null){
             completedDate= l.Completed_Date__c.year()+'-'+l.Completed_Date__c.month()+'-'+l.Completed_Date__c.day();
            }
            
            /*if(investigationDates != Null){
                investigationDates =investigationDates+','+assignedDate+' to '+completedDate;
            }else{
                investigationDates =assignedDate+' to '+completedDate;
            }*/
            if(investigators != Null){
                if(l.Assigned_To_Name__c != Null){
                    if(!investigators.contains(l.Assigned_To_Name__c)){
                        investigators = investigators +', '+l.Assigned_To_Name__c;
                    }
                }
            }else{
                investigators = l.Assigned_To_Name__c;
            }
            leadsMap.put(l.id,l);
        }
         employmentMap = new Map<String,Map<String,List<String>>>();
        educationMap = new Map<String,Map<String,List<String>>>();
        medicalMap = new Map<String,Map<String,List<String>>> ();
        subjectInterviewList = new List<String>();
        subjectContactList = new List<String>();
        residenceList = new List<String>();
        referencesList = new List<String>();
        generalLeadsList = new List<String>();
        formerSpouseList = new List<String>();
        unEmploymentList = new List<String>();
        lawEnforcementList = new List<String>();
        financialList = new List<String>();
        employmentList = new list<string>();
        educationList= new list<string>();
        medicalList= new list<string>();
        
        for(lead__c l: leads){
            if(l.leadType__c == 'Employment (EMPL)'){
                employmentList.add(l.id);
            }
            if(l.leadType__c == 'Education (EDUC)'){
                educationList.add(l.id);
            }
             if(l.leadType__c == 'Medical (MEDI)'){
                medicalList.add(l.id);
            }
            if(l.leadType__c == 'Subject Interview (ESI/TESI)'){
                subjectInterviewList.add(l.id);
            }
            if(l.leadType__c == 'Subject contact (SUBC)'){
                subjectContactList.add(l.id);
            }
            
            if(l.leadType__c == 'Residence (RESI)'){
                residenceList.add(l.id);
            }
            if(l.leadType__c == 'References (REFE)'){
                referencesList.add(l.id);
            }
            if(l.leadType__c == 'General (GENL)'){
                generalLeadsList.add(l.id);
            }
            if(l.leadType__c == 'Former Spouse (FMSP)'){
                formerSpouseList.add(l.id);
            }
            if(l.leadType__c == 'Unemployment'){
                unEmploymentList.add(l.id);
            }
            if(l.leadType__c == 'Law Enforcement (LAWE)'){
                lawEnforcementList.add(l.id);
            }
            if(l.leadType__c == 'Financial (FINL)'){
                financialList.add(l.id);
            }
       
        }

    }
}