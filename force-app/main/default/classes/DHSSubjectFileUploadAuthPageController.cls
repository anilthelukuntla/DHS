/**
 * @description Authenticates subject access before DHS document upload.
 */
@SuppressWarnings('PMD.UnusedMethod')
public without sharing class DHSSubjectFileUploadAuthPageController {
    /** @description Provides this DHS API member. */
    public string caseId {get;set;}
    /** @description Provides this DHS API member. */
    public DHS_Case__c caseRecord {get;set;}
    /** @description Provides this DHS API member. */
    public DHS_Contact__c contactRecord {get;set;}
    /** @description Provides this DHS API member. */
    public string ssnUserInput{get;set;
        
    }
    public boolean showsuccessfailuremessage{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean isAuthenticatedSuccess {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public DHSSubjectFileUploadAuthPageController(){
    	String requestedCaseId = apexpages.currentpage().getparameters().get('id');
        caseId = String.isBlank(requestedCaseId)
            ? null
            : String.valueOf(Id.valueOf(requestedCaseId));
        fetchCaseInformation();
        isAuthenticatedSuccess = false;
        showsuccessfailuremessage =false;
    }
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public pagereference authMethod(){
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
                  WITH USER_MODE ORDER BY CreatedDate ASC
                  LIMIT 1
              ];
              if (!caseLeads.isEmpty()) {
                  documentRequest.DHS_Lead__c = caseLeads[0].Id;
              }
              documentRequest.Expiration_Date__c = system.now().addDays(1);    
        	  //documentRequest.To_Address__c = leadRecord.DHS_Contact__r.Email__c;
              Database.insert(documentRequest, AccessLevel.USER_MODE);
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
    /** @description Provides this DHS API member. */
    public void fetchCaseInformation(){
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
        list<DHS_Case__c> cases = database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE);
        if(!cases.isEmpty()){
            caseRecord = cases[0];
            if(caseRecord.DHS_Contact__c != Null){
                contactRecord = [Select Id, First_Name__c, Last_Name__c, Email__c, SSN__c from DHS_Contact__c where Id=: caseRecord.DHS_Contact__c WITH USER_MODE]; 
            }   
        }    
    }
        

}
