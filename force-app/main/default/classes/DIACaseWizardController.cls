public with sharing class DIACaseWizardController {
    public DIA_contact__c newSubject{get;set;}
    public string subjectFirstNameSearchEntry {Get;set;}
    public string subjectLastNameSearchEntry {Get;set;}
    public string subjectEmailSearchEntry{get;set;}
    public list<SubjectRecord> subjectsSearched {Get;set;}
    public boolean showsubjectspanel{get;set;}
    public string errorMsg{get;set;}
    public DIACaseWizardController(){
        newSubject = new DIA_contact__c();
        showsubjectspanel = false;
    }
    public pagereference CreateNewSubjectAction(){
        Savepoint sp = Database.setSavepoint();
        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_Case__c');
        if(Schema.SobjectType.DIA_contact__c.iscreateable()){
            Database.SaveResult sr = database.insert(newSubject, false, AccessLevel.USER_MODE);
        }else{
            errorMsg = system.Label.Error_Message;
        }
        DIA_Case__c newCase = new DIA_Case__c();
        newCase.Contact__c = newSubject.id;
        newCase.Case_Origin__c = 'Case Intake';
        System.debug('newSubject.First_Name__c..'+newSubject.First_Name__c);
        System.debug('newSubject.Last_Name__c..'+newSubject.Last_Name__c);
        System.debug('newSubject.Phone__c..'+newSubject.Phone__c);
        System.debug('newSubject.State__c..'+newSubject.State__c);
        newcase.case_number__c = newSubject.First_Name__c.substring(0,1) + newSubject.Last_Name__c.substring(0,1)+' - '+newSubject.Phone__c.right(3)+newSubject.State__c;
        
        if(Schema.SobjectType.DIA_Case__c.iscreateable() && fields.get('Contact__c').getDescribe().isAccessible() 
          && fields.get('case_number__c').getDescribe().isAccessible()){
              
            Database.SaveResult dsr = database.insert(newCase, false, AccessLevel.USER_MODE);
              if(dsr.isSuccess()){
                //Notification on case creation
                string emailBody = 'Hello,<br/><br/>A case has been created with case number# <b>'+newCase.case_number__c+'</b> in ForeSite on '+DateTime.now().format()+'.';
                emailBody = emailBody + '<br/><br/>Thanks,<br/>ISN Corporation';
              
                Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
                semail.setToAddresses(system.label.CaseIntakeNotificationEmail .split(','));
                if(boolean.valueof(system.label.CaseIntakeNotificationUseCCAddress)){
                    semail.setCCAddresses(new list<string>{userinfo.getuseremail()});    
                }
               
                string emailSubject = 'Case creation via Case Intake'+' - ' + system.now().date().format();
               
                semail.setSubject(emailSubject);
                semail.sethtmlBody(emailBody);
                semail.setSaveAsActivity(true);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {semail});  
                  
                  
                  
                  
                PageReference redirectPage = Page.BICaseDetail;
                redirectPage.setRedirect(true);
                redirectPage.getParameters().put('id',dsr.getId());
                return redirectPage;
              }else{
                  for(Database.Error err : dsr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
                Database.rollback(sp);
                return null;
              }
            
        }else{
            errorMsg = system.Label.Error_Message;
            return null;
        }
    }
    
     public void SearchSubjectsAction(){
        List<DIA_contact__c> subjects= new List<DIA_contact__c>(); 
        subjectsSearched = new  list<SubjectRecord> ();
        List<string> contactFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        contactFields = ApexUtil.FetchFields('DIA_contact__c');
        String query = 'Select '+String.escapeSingleQuotes(string.join(contactFields, ',')) + ' From DIA_contact__c ';
        
        if(String.isNotBlank(string.valueof(subjectFirstNameSearchEntry))){
            whereCriteria.add(new ApexUtil.Criteria('First_Name__c', subjectFirstNameSearchEntry, '='));
        }
        
        if(String.isNotBlank(string.valueof(subjectLastNameSearchEntry))){
            whereCriteria.add(new ApexUtil.Criteria('Last_Name__c', subjectLastNameSearchEntry, '='));
        }
        
        if(String.isNotBlank(string.valueof(subjectEmailSearchEntry))){
            whereCriteria.add(new ApexUtil.Criteria('Email__c', subjectEmailSearchEntry, '='));
        }
        
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED '; 
        System.debug('query...'+query);
        subjects = database.query(query);
         for(DIA_contact__c con: subjects){
            subjectsSearched.add(new SubjectRecord(false,con));        
         }
        showsubjectspanel = true;
    }
    
    public class SubjectRecord{
        public boolean isSelected{get;set;}
        public DIA_contact__c subject{get;set;}
        public SubjectRecord(boolean isSelected,DIA_contact__c subject){
            this.subject = subject;   
            this.isSelected = false;
        }
    }
    
    public pagereference CreateCaseAction(){
        Map<String, Schema.SObjectField> MapofField = ApexUtil.getObjectFieldsDescribe('DIA_Case__c');
        DIA_Case__c newCase= new DIA_Case__c();
        for(SubjectRecord sub: subjectsSearched){
            if(sub.isSelected){
                newCase.contact__c = sub.subject.id;    
                if(!test.isRunningTest()){
                    newcase.case_number__c = sub.subject.First_Name__c.substring(0,1) + sub.subject.Last_Name__c.substring(0,1)+' - '+sub.subject.Mobile__c.right(3)+sub.subject.State__c;
                    System.debug('newcase.case_number__c..'+newcase.case_number__c );
                }
            }    
        }
        if(Schema.SobjectType.DIA_Case__c.iscreateable() && MapofField.get('Contact__c').getDescribe().isAccessible() 
          && MapofField.get('case_number__c').getDescribe().isAccessible()){
            Database.SaveResult dsr = database.insert(newCase, false, AccessLevel.USER_MODE);
            if(dsr.isSuccess()){
                PageReference redirectPage = Page.BICaseDetail;
                redirectPage.setRedirect(true);
                redirectPage.getParameters().put('id',dsr.getId());
                return redirectPage;
            }else{
                for(Database.Error err : dsr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
                return null;
            }
          }else{
            errorMsg = system.Label.Error_Message;
            return null;
          }
        
        
    }
    
     @RemoteAction
    public static boolean CheckIfCaseExists(string subjectId) {
        list<DIA_Case__c> cases = [select id,case_queue_status__c,Contact__c from DIA_Case__c where Contact__c=:subjectId and case_queue_status__c != 'Closed'  WITH SECURITY_ENFORCED];
        boolean hasCases = false;
        if(!cases.isEmpty()){
            hasCases = true;
        }    
        return hasCases;
    }
    
}