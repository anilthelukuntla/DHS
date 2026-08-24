/** Saves a subject-uploaded file as a DHS case document. */
@SuppressWarnings('PMD.ApexDoc,PMD.UnusedMethod')
public without sharing class DHSSubjectFileUploadPageController {
    public string caseId{get;set;}
    public string caseRecordIDforDocUpload{get;set;}
    public ApexPages.StandardController controller;
    public DHSSubjectFileUploadPageController(){
    	String requestedCaseId = apexpages.currentpage().getparameters().get('caseid');
        caseId = String.isBlank(requestedCaseId)
            ? null
            : String.valueOf(Id.valueOf(requestedCaseId));
        caseRecordIDforDocUpload = caseId;    
    }
     public DHSSubjectFileUploadPageController (ApexPages.StandardController controller) {
        this.controller = controller;
     }
    
     public PageReference saveAndRedirect() {
         DHS_Case__c caseRecord;
         List<DHS_Case__c> cases = [Select Subject_Name__c,Subject_Type__c,Case_Number__c ,Case_Type__c, DHS_Contact__r.SSN__c from DHS_Case__c where Id=: caseId WITH USER_MODE ];
        if(!cases.isEMpty()){
           caseRecord = cases[0];
        }
         Attachment d = (Attachment) controller.getRecord();
         DHS_Document__c document = new DHS_Document__c();
         document.Added_By__c = caseRecord.Subject_Name__c;
         document.DHS_Case__c = caseId;
         document.Name__c = d.Name;
		Database.insert(document, AccessLevel.USER_MODE);
	         d.parentid=document.id;
      
              controller.save();
         return null;
     }
}
