/** Authenticates subject access before DHS document upload. */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexDoc, PMD.ApexSOQLInjection, PMD.ApexXSSFromURLParam, PMD.AvoidBooleanMethodParameters, PMD.MethodNamingConventions')
public without sharing class DHSSubjectFileUploadAuthPageController {
    public string caseId {get;set;}
    public DHS_Case__c caseRecord {get;set;}
    public DHS_Contact__c contactRecord {get;set;}
    public string ssnUserInput{get;set;
        
    }
    public boolean showsuccessfailuremessage{get;set;}
    public boolean isAuthenticatedSuccess {get;set;}
    public DHSSubjectFileUploadAuthPageController(){
    	String requestedCaseId = apexpages.currentpage().getparameters().get('id');
        caseId = String.isBlank(requestedCaseId)
            ? null
            : String.valueOf(Id.valueOf(requestedCaseId));
        FetchCaseInformation();
        isAuthenticatedSuccess = false;
        showsuccessfailuremessage =false;
    }
    public pagereference AuthMethod(){
        String contactSSNlast4characters = contactRecord.SSN__c.right(4);
        if(contactSSNlast4characters == ssnUserInput){
        	isAuthenticatedSuccess = true;	    
        }    
        showsuccessfailuremessage = true;
        if(isAuthenticatedSuccess){
              DHS_Document_Request__c documentRequest = new DHS_Document_Request__c();
              documentRequest.Status__c = 'Documents Requested';
              documentRequest.DHS_Case__c = caseId;
              List<DHS_Lead__c> caseLeads = [
                  SELECT Id FROM DHS_Lead__c
                  WHERE DHS_Case__c = :caseId
                  ORDER BY CreatedDate ASC
                  LIMIT 1
              ];
              if (!caseLeads.isEmpty()) {
                  documentRequest.DHS_Lead__c = caseLeads[0].Id;
              }
              documentRequest.Expiration_Date__c = system.now().addDays(1);    
        	  //documentRequest.To_Address__c = leadRecord.DHS_Contact__r.Email__c;
              insert documentRequest;
              String encodedId = encodeURLParams(documentRequest.id);
         	  PageReference redirectPage = Page.DHSSubjectDocumentsUpload;
              redirectPage.setRedirect(true);
              redirectPage.getParameters().put('id',encodedId);
              return redirectPage;   
        }else{
            return null;
        }
    }
    
    private String encodeURLParams(String inputString){
        // create a blob from our parameter value before we send it as part of the url
        Blob beforeblob = Blob.valueOf(inputString);
   
        // base64 encode the blob that contains our url param value
        String paramvalue = EncodingUtil.base64Encode(beforeblob);
   
        // print out the encoded value to the debug log so we can see it before/after base64 encode
       
        return paramValue;   
    }
    
     private String decodeURLParams(String encodedString){
    
         // take the base64 encoded parameter and create base64 decoded Blob from it   
         Blob afterblob = EncodingUtil.base64Decode(encodedString);
   
         // Convert the blob back to a string and print it in the debug log
         
         return afterblob.toString();
        
    }
    public void FetchCaseInformation(){
        List<string> caseFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        caseFields = DHSApexUtil.FetchFields('DHS_Case__c');
        caseFields.add('DHS_Contact__r.First_Name__c');
        caseFields.add('DHS_Contact__r.SSN__c');
        caseFields.add('DHS_Contact__r.Last_Name__c');
        caseFields.add('DHS_Contact__r.Email__c');
        caseFields.add('DHS_Assigned_To__r.FirstName');
        caseFields.add('DHS_Assigned_To__r.LastName');
        caseFields.add('DHS_Assigned_To__r.Email');
        caseFields.add('owner.email');
        string systemFields = 'createddate,createdbyid,lastmodifieddate,lastmodifiedbyid,systemmodstamp,lastvieweddate,lastreferenceddate';
        for(string field : systemFields.split(',')){
            caseFields.remove(caseFields.indexOf(field));
        }
        String query = 'Select '+string.join(caseFields, ',') + ' From DHS_Case__c ';
        
        if(String.isNotBlank(caseId)){
            whereCriteria.add(new DHSApexUtil.Criteria('Id',caseId,'='));
        }
        
        String whereCondition = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCondition; 
        list<DHS_Case__c> cases = database.query(query);
        if(!cases.isEmpty()){
            caseRecord = cases[0];
            if(caseRecord.DHS_Contact__c != Null){
                contactRecord = [Select Id, First_Name__c, Last_Name__c, Email__c, SSN__c from DHS_Contact__c where Id=: caseRecord.DHS_Contact__c WITH SECURITY_ENFORCED]; 
            }   
        }    
    }
        

}