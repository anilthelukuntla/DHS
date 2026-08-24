/** Handles the standard attachment upload flow for a DHS case. */
@SuppressWarnings('PMD.ApexDoc,PMD.UnusedMethod')
public without sharing class DHSForesiteFileUploadPageController {
    public string caseid;
    public DHS_Case__c caseRecord {get;set;}
    public ApexPages.StandardController controller;
    public DHSForesiteFileUploadPageController (ApexPages.StandardController controller) {
        this.controller = controller;
        String requestedCaseId = apexpages.currentpage().getparameters().get('caseid');
        caseId = String.isBlank(requestedCaseId)
            ? null
            : String.valueOf(Id.valueOf(requestedCaseId));
        List<DHS_Case__c> cases = [Select Subject_Type__c,Case_Number__c ,Case_Type__c, DHS_Contact__r.SSN__c from DHS_Case__c where Id=: caseId WITH USER_MODE];
        if(!cases.isEMpty()){
           caseRecord = cases[0];
        }
    } 
    public PageReference saveAndRedirect() {
         Attachment d = (Attachment) controller.getRecord();
         DHS_Document__c document = new DHS_Document__c();
         document.Added_By__c = [Select Id,Name from user where id=:userinfo.getuserid() WITH USER_MODE].Name;
         document.DHS_Case__c = caseId;
         document.Name__c = d.Name;
         database.insert(document,false,AccessLevel.USER_MODE);
         String modifiedFileName;
         if(caseRecord.Subject_Type__c == 'Applicant'){
            modifiedFileName = 'A'; 
         }else if(caseRecord.Subject_Type__c == 'Contractor'){
            modifiedFileName = 'A'; 
         }
         modifiedFileName = modifiedFileName + caseRecord.DHS_Contact__r.SSN__c+'Att00_'+d.Name;
         d.name=modifiedFileName;
         d.parentid=document.id;

        controller.save();
        PageReference redirect = new PageReference('/apex/DHSCasedetail?id='+caseId+'&tab=Documents');
        redirect.setRedirect(true);
        return redirect;
    }
  
   }
