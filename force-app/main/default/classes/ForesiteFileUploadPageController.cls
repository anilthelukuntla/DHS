/** Handles the standard attachment upload flow for a PPF case. */
@SuppressWarnings('PMD.ApexDoc, PMD.ApexCRUDViolation, PMD.ApexXSSFromURLParam')
public without sharing class ForesiteFileUploadPageController {
    public string caseid;
    public case__c caseRecord {get;set;}
    public ApexPages.StandardController controller; // NOPMD - legacy structure retained to preserve behavior
    public ForesiteFileUploadPageController (ApexPages.StandardController controller) {
        this.controller = controller;
        String requestedCaseId = apexpages.currentpage().getparameters().get('caseid');
        caseId = String.isBlank(requestedCaseId)
            ? null
            : String.valueOf(Id.valueOf(requestedCaseId));
        List<Case__c> cases = [Select Subject_Type__c,Case_Number__c ,case_type__c, Contact__r.SSN__c from Case__c where Id=: caseId];
        if(!cases.isEMpty()){
           caseRecord = cases[0];
        }
    } 
    public PageReference saveAndRedirect() {
         Attachment d = (Attachment) controller.getRecord();
         Document__c document = new Document__c();
         document.added_by__c = [Select Id,Name from user where id=:userinfo.getuserid()].Name;
         document.case__c = caseId;
         document.Name__c = d.Name;
         insert document;
         String modifiedFileName;
         if(caseRecord.Subject_Type__c == 'Applicant'){
            modifiedFileName = 'A'; 
         }else if(caseRecord.Subject_Type__c == 'Contractor'){
            modifiedFileName = 'A'; 
         }
         modifiedFileName = modifiedFileName + caseRecord.Contact__r.SSN__c+'Att00_'+d.Name;
         d.name=modifiedFileName;
         d.parentid=document.id;

        controller.save();
        PageReference redirect = new PageReference('/apex/casedetail?id='+caseId+'&tab=Documents');
        redirect.setRedirect(true);
        return redirect;
    }
  
   }