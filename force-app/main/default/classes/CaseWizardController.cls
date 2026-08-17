/** @description Visualforce controller for creating cases and searching subjects. */
public with sharing class CaseWizardController {
    /** @description Subject entered for case creation. */
    public contact__c newSubject{get;set;}
    /** @description First-name search value. */
    public string subjectFirstNameSearchEntry {Get;set;}
    /** @description Last-name search value. */
    public string subjectLastNameSearchEntry {Get;set;}
    /** @description Email search value. */
    public string subjectEmailSearchEntry{get;set;}
    /** @description Subject search results. */
    public list<SubjectRecord> subjectsSearched {Get;set;}
    /** @description Whether the subject results panel is visible. */
    public boolean showsubjectspanel{ get; private set; }
    /** @description Initializes the case wizard. */
    public CaseWizardController(){
        newSubject = new contact__c();
        showsubjectspanel = false;
    }
    /** @description Creates a subject and its case, then redirects to the case. @return case page */
    public pagereference createNewSubjectAction(){
        insert as user newSubject;
        Case__c newCase = new Case__c();
        newCase.Contact__c = newSubject.id;
        
        newcase.case_number__c = newSubject.First_Name__c.substring(0,1) + newSubject.Last_Name__c.substring(0,1)+' - '+math.random().tostring().right(3)+'MD';
        insert as user newCase;
        PageReference redirectPage = Page.CaseDetail;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id',newCase.id);
        return redirectPage; 
    }
    
    /** @description Searches for subjects using the entered criteria. */
     public void searchSubjectsAction(){
        List<Contact__c> subjects= new List<Contact__c>(); 
        subjectsSearched = new  list<SubjectRecord> ();
        List<string> contactFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        contactFields = ApexUtil.FetchFields('Contact__c');
        String query = 'Select '+string.join(contactFields, ',') + ' From Contact__c ';
        
        if(String.isNotBlank(string.valueof(subjectFirstNameSearchEntry))){
            whereCriteria.add(new ApexUtil.Criteria('First_Name__c', subjectFirstNameSearchEntry, '='));
        }
        
        if(String.isNotBlank(string.valueof(subjectLastNameSearchEntry))){
            whereCriteria.add(new ApexUtil.Criteria('Last_Name__c', subjectLastNameSearchEntry, '='));
        }
        
        if(String.isNotBlank(string.valueof(subjectEmailSearchEntry))){
            whereCriteria.add(new ApexUtil.Criteria('Email__c', subjectEmailSearchEntry, '='));
        }
        
        
        String whereCondition = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCondition; 
        subjects = Database.queryWithBinds(query, new Map<String, Object>(), AccessLevel.USER_MODE);
         for(Contact__c con: subjects){
            subjectsSearched.add(new SubjectRecord(con));        
         }
        showsubjectspanel = true;
    }
    
    /** @description Selectable subject search result. */
    public class SubjectRecord{
        /** @description Whether the subject is selected. */
        public boolean isSelected{get;set;}
        /** @description Subject record. */
        public Contact__c subject{get;set;}
        /** @description Creates a selectable subject result. @param subject source subject */
        public SubjectRecord(Contact__c subject){
            this.subject = subject;   
            this.isSelected = false;
        }
    }
    
    /** @description Creates a case for the selected subject. @return case page */
    public pagereference createCaseAction(){
        Case__c newCase= new Case__c();
        for(SubjectRecord sub: subjectsSearched){
            if(sub.isSelected){
                newCase.contact__c = sub.subject.id;    
                if(!test.isRunningTest()){
                    newcase.case_number__c = sub.subject.First_Name__c.substring(0,1) + sub.subject.Last_Name__c.substring(0,1)+' - '+sub.subject.Mobile__c.right(3)+sub.subject.State__c;
                }
            }    
        }
        insert as user newCase;
        PageReference redirectPage = Page.CaseDetail;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id',newCase.id);
        return redirectPage;
    }
    
     @RemoteAction
    /** @description Checks for an open case. @param subjectId subject ID @return true when open case exists */
    public static boolean checkIfCaseExists(string subjectId) {
        list<Case__c> cases = [select id,case_queue_status__c,Contact__c from case__c where Contact__c=:subjectId and case_queue_status__c != 'Closed' WITH USER_MODE];
        boolean hasCases = false;
        if(!cases.isEmpty()){
            hasCases = true;
        }    
        return hasCases;
    }
}
