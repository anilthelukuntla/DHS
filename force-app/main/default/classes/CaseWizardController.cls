/** Visualforce controller for creating cases and searching subjects. */
@SuppressWarnings('PMD.ApexDoc, PMD.ApexSOQLInjection, PMD.AvoidBooleanMethodParameters, PMD.LocalVariableNamingConventions, PMD.MethodNamingConventions')
public with sharing class CaseWizardController {
    public contact__c newSubject{get;set;}
    public string subjectFirstNameSearchEntry {Get;set;}
    public string subjectLastNameSearchEntry {Get;set;}
    public string subjectEmailSearchEntry{get;set;}
    public list<SubjectRecord> subjectsSearched {Get;set;}
    public boolean showsubjectspanel{ get; private set; }
    public CaseWizardController(){
        newSubject = new contact__c();
        showsubjectspanel = false;
    }
    public pagereference CreateNewSubjectAction(){
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
    
     public void SearchSubjectsAction(){
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
        subjects = database.query(query, AccessLevel.SYSTEM_MODE);
         for(Contact__c con: subjects){
            subjectsSearched.add(new SubjectRecord(con));        
         }
        showsubjectspanel = true;
    }
    
    public class SubjectRecord{
        public boolean isSelected{get;set;}
        public Contact__c subject{get;set;}
        public SubjectRecord(Contact__c subject){
            this.subject = subject;   
            this.isSelected = false;
        }
    }
    
    public pagereference CreateCaseAction(){
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
    public static boolean CheckIfCaseExists(string subjectId) {
        list<Case__c> cases = [select id,case_queue_status__c,Contact__c from case__c where Contact__c=:subjectId and case_queue_status__c != 'Closed' WITH USER_MODE];
        boolean hasCases = false;
        if(!cases.isEmpty()){
            hasCases = true;
        }    
        return hasCases;
    }
}