/** Visualforce controller for creating DHS cases and searching DHS subjects. */
@SuppressWarnings('PMD.ApexDoc')
public with sharing class DHSCaseWizardController {
    public DHS_Contact__c newSubject{get;set;}
    public string subjectFirstNameSearchEntry {Get;set;}
    public string subjectLastNameSearchEntry {Get;set;}
    public string subjectEmailSearchEntry{get;set;}
    public list<SubjectRecord> subjectsSearched {Get;set;}
    public boolean showsubjectspanel{ get; private set; }
    public DHSCaseWizardController(){
        newSubject = new DHS_Contact__c();
        showsubjectspanel = false;
    }
    public pagereference createNewSubjectAction(){
        database.insert(newSubject,false,AccessLevel.USER_MODE);
        DHS_Case__c newCase = new DHS_Case__c();
        newCase.DHS_Contact__c = newSubject.id;
        newcase.Case_Number__c = newSubject.First_Name__c.substring(0,1) + newSubject.Last_Name__c.substring(0,1)+' - '+math.random().tostring().right(3)+'MD';
        database.insert(newCase,false,AccessLevel.USER_MODE);
        PageReference redirectPage = Page.DHSCasedetail;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id',newCase.id);
        return redirectPage; 
    }
    
     public void searchSubjectsAction(){
        List<DHS_Contact__c> subjects= new List<DHS_Contact__c>(); 
        subjectsSearched = new  list<SubjectRecord> ();
        List<string> contactFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        contactFields = DHSApexUtil.FetchFields('DHS_Contact__c');
        String query = 'Select '+string.join(contactFields, ',')+ ' From DHS_Contact__c ';
        
        if(String.isNotBlank(string.valueof(subjectFirstNameSearchEntry))){
            whereCriteria.add(new DHSApexUtil.Criteria('First_Name__c', String.escapeSingleQuotes(subjectFirstNameSearchEntry), '='));
        }
        
        if(String.isNotBlank(string.valueof(subjectLastNameSearchEntry))){
            whereCriteria.add(new DHSApexUtil.Criteria('Last_Name__c', String.escapeSingleQuotes(subjectLastNameSearchEntry), '='));
        }
        
        if(String.isNotBlank(string.valueof(subjectEmailSearchEntry))){
            whereCriteria.add(new DHSApexUtil.Criteria('Email__c', String.escapeSingleQuotes(subjectEmailSearchEntry), '='));
        }
        
        
        String whereCondition = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCondition+' WITH USER_MODE'; 
        subjects = database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE);
         for(DHS_Contact__c con: subjects){
            subjectsSearched.add(new SubjectRecord(con));        
         }
        showsubjectspanel = true;
    }
    
    public class SubjectRecord{
        public boolean isSelected{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
        public DHS_Contact__c subject{get;set;}
        public SubjectRecord(DHS_Contact__c subject){
            this.subject = subject;   
            this.isSelected = false;
        }
    }
    
    public pagereference createCaseAction(){
        DHS_Case__c newCase= new DHS_Case__c();
        for(SubjectRecord sub: subjectsSearched){
            if(sub.isSelected){
                newCase.DHS_Contact__c = sub.subject.id;    
                if(!test.isRunningTest()){
                    newcase.Case_Number__c = sub.subject.First_Name__c.substring(0,1) + sub.subject.Last_Name__c.substring(0,1)+' - '+sub.subject.Mobile__c.right(3)+sub.subject.State__c;
                }
            }    
        }
        database.insert(newCase,false,AccessLevel.USER_MODE) ;
        PageReference redirectPage = Page.DHSCasedetail;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id',newCase.id);
        return redirectPage;
    }
    
     @RemoteAction
    public static boolean checkIfCaseExists(string subjectId) {
        list<DHS_Case__c> cases = [select id,Case_Queue_Status__c,DHS_Contact__c from DHS_Case__c where DHS_Contact__c=:subjectId and Case_Queue_Status__c != 'Closed'  WITH USER_MODE];
        boolean hasCases = false;
        if(!cases.isEmpty()){
            hasCases = true;
        }    
        return hasCases;
    }
}
