/**
 * @description Builds the DHS ROI report data model for a selected case.
 */
@SuppressWarnings('PMD.ApexSOQLInjection,PMD.AvoidDeeplyNestedIfStmts,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessivePublicCount,PMD.NcssCount,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity')
public with sharing class DHSROIReportController {
    /** @description Provides this DHS API member. */
    public string caseId {get;set;}
    /** @description Provides this DHS API member. */
    public DHS_Case__c caseRecord {get;set;}
    /** @description Provides this DHS API member. */
    public List<DHS_Lead__c> leads {get;set;}
    /** @description Provides this DHS API member. */
    public user currentUser{get;set;}
    /** @description Provides this DHS API member. */
    public integer totalLeads {get;set;}
    /** @description Provides this DHS API member. */
    public String investigationDates {get;set;}
    /** @description Provides this DHS API member. */
    public String investigators {get;set;}
    /** @description Provides this DHS API member. */
    public map<string,integer> leadsCountMap {get;set;}
    /** @description Provides this DHS API member. */
    public map<string,DHS_Lead__c> leadsMap {get;set;}
    /** @description Provides this DHS API member. */
    public List<String> subjectInterviewList {get;set;}
    /** @description Provides this DHS API member. */
    public List<String> subjectContactList {get;set;}
    /** @description Provides this DHS API member. */
    public Map<String,Map<String,List<String>>> employmentMap {get;set;}
    /** @description Provides this DHS API member. */
    public Map<String,Map<String,List<String>>> educationMap {get;set;}
    /** @description Provides this DHS API member. */
    public Map<String,Map<String,List<String>>> medicalMap {get;set;}
    /** @description Provides this DHS API member. */
    public List<String> residenceList {get;set;}
    /** @description Provides this DHS API member. */
    public List<String> referencesList {get;set;}
    /** @description Provides this DHS API member. */
    public List<String> generalLeadsList {get;set;}
    /** @description Provides this DHS API member. */
    public List<String> formerSpouseList {get;set;}
    /** @description Provides this DHS API member. */
    public List<String> unEmploymentList {get;set;}
    /** @description Provides this DHS API member. */
    public List<String> lawEnforcementList {get;set;}
    /** @description Provides this DHS API member. */
    public List<String> financialList {get;set;}
    /** @description Provides this DHS API member. */
    public List<String> employmentList {get;set;}
    /** @description Provides this DHS API member. */
    public List<String> educationList {get;set;}
    /** @description Provides this DHS API member. */
    public List<String> medicalList {get;set;}
    
    

    /** @description Provides this DHS API member. */
    public DHSROIReportController(){
        currentUser = [Select Id, User_Type__c FROM User where Id=:userinfo.getUserId() WITH SECURITY_ENFORCED];
        caseId = String.valueOf(Id.valueOf(ApexPages.currentPage().getParameters().get('id').escapeHtml4()));
        leadsCountMap = new map<string,integer>();
        totalLeads= 0;
        fetchCaseInformation();
        fetchLeadInformation();
    }
    
    /** @description Provides this DHS API member. */
    public void fetchCaseInformation(){
        List<string> caseFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        caseFields = DHSApexUtil.FetchFields('DHS_Case__c');
        caseFields.add('DHS_Contact__r.First_Name__c');
        caseFields.add('DHS_Contact__r.Last_Name__c');
        caseFields.add('DHS_Contact__r.Email__c');
        caseFields.add('DHS_Contact__r.Address__c');
        caseFields.add('DHS_Contact__r.City__c');
        caseFields.add('DHS_Contact__r.State__c');
        caseFields.add('DHS_Contact__r.Zip__c');
        caseFields.add('DHS_Contact__r.SSN__c');
        String query = 'Select '+string.join(caseFields, ',') + ' From DHS_Case__c ';
        
        if(String.isNotBlank(caseId)){
            whereCriteria.add(new DHSApexUtil.Criteria('Id',caseId,'='));
        }
        
        String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCond+ ' WITH SECURITY_ENFORCED'; 
        // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
        list<DHS_Case__c> cases = database.query(query);
        if(!cases.isEmpty()){
            caseRecord = cases[0];
            if(caseRecord.Investigations_Review_Date__c != Null && caseRecord.QA_and_Review_Date__c != Null){
                DateTime fromDate = DateTime.newInstance(caseRecord.Investigations_Review_Date__c.year(), caseRecord.Investigations_Review_Date__c.month(),caseRecord.Investigations_Review_Date__c.day());
                String fromDateFormatted = fromDate.format('MM/dd/yyyy');
                DateTime toDate = DateTime.newInstance(caseRecord.QA_and_Review_Date__c.year(), caseRecord.QA_and_Review_Date__c.month(),caseRecord.QA_and_Review_Date__c.day());
                String toDateFormatted = toDate.format('MM/dd/yyyy');
                investigationDates = fromDateFormatted +' to '+ toDateFormatted;  
            } 
        }    
    }
    
    /** @description Provides this DHS API member. */
    PUBLIC Map<String, DHS_Lead_RTA_Extension__c> subjectInterviewNLeadRTAExtension {get;set;}
    /** @description Provides this DHS API member. */
    public void fetchLeadInformation(){
        leadsMap = new Map<String,DHS_Lead__c>();
        subjectInterviewNLeadRTAExtension = new Map<String, DHS_Lead_RTA_Extension__c>();
        leads = new List<DHS_Lead__c> ();
        List<string> leadFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        leadFields = DHSApexUtil.FetchFields('DHS_Lead__c');  
        leadFields.add('DHS_Contact__r.First_Name__c');    
        leadFields.add('DHS_Contact__r.Last_Name__c');   
        String query = 'Select '+string.join(leadFields, ',') + ' From DHS_Lead__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c',caseId,'='));
        }
        
        String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCond+ ' WITH SECURITY_ENFORCED ORDER BY LeadType__c Asc'; 
        
        // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
        leads = database.query(query);
        List<string> esiLeadIds = new List<String>();
        for(DHS_Lead__c lc: leads){
            if(lc.LeadType__c == 'Subject Interview (ESI/TESI)'){
                esiLeadIds.add(lc.id);
            }
        }
        
        List<DHS_Lead_RTA_Extension__c> leadRTAExtensions = [Select Id, DHS_Lead__c, Foreign_Activities__c, Foreign_Contacts__c, Foreign_Travel1__c, Foreign_Travel2__c
                                                         FROM DHS_Lead_RTA_Extension__c
                                                         WHERE DHS_Lead__c IN:esiLeadIds WITH SECURITY_ENFORCED];
        
        for(DHS_Lead_RTA_Extension__c lrta: leadRTAExtensions){
            subjectInterviewNLeadRTAExtension.put(lrta.DHS_Lead__c, lrta);
        }  
        
        for(String str: esiLeadIds){
            if(!subjectInterviewNLeadRTAExtension.keyset().contains(str)){
                subjectInterviewNLeadRTAExtension.put(str, new DHS_Lead_RTA_Extension__c());
            }
        }                                                
        
        for(DHS_Lead__c l: leads){
            if(!leadsCountMap.containsKey(l.LeadType__c)){
                leadsCountMap.put(l.LeadType__c, 1);    
            }else{
                leadsCountMap.put(l.LeadType__c, leadsCountMap.get(l.LeadType__c)+1);    
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
        
        for(DHS_Lead__c l: leads){
            if(l.LeadType__c == 'Employment (EMPL)'){
                employmentList.add(l.id);
            }
            if(l.LeadType__c == 'Education (EDUC)'){
                educationList.add(l.id);
            }
             if(l.LeadType__c == 'Medical (MEDI)'){
                medicalList.add(l.id);
            }
            if(l.LeadType__c == 'Subject Interview (ESI/TESI)'){
                subjectInterviewList.add(l.id);
            }
            if(l.LeadType__c == 'Subject Recontact (SUBC)'){
                subjectContactList.add(l.id);
            }
            
            if(l.LeadType__c == 'Residence (RESI)'){
                residenceList.add(l.id);
            }
            if(l.LeadType__c == 'References (REFE)'){
                referencesList.add(l.id);
            }
            if(l.LeadType__c == 'General (GENL)'){
                generalLeadsList.add(l.id);
            }
            if(l.LeadType__c == 'Former Spouse (FMSP)'){
                formerSpouseList.add(l.id);
            }
            if(l.LeadType__c == 'Unemployment'){
                unEmploymentList.add(l.id);
            }
            if(l.LeadType__c == 'Law Enforcement (LAWE)'){
                lawEnforcementList.add(l.id);
            }
            if(l.LeadType__c == 'Financial (FINL)'){
                financialList.add(l.id);
            }
       
        }

    }
}
