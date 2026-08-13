trigger DHSDocumentRequestTrigger on DHS_Document_Request__c (before insert, after insert) { // NOPMD
    if(trigger.isInsert && trigger.isBefore){
        for(DHS_Document_Request__c dr: Trigger.New){
            dr.Expiration_Date__c = system.now().addHours(1);    
        } 
   
    }
    
    if (trigger.isAfter && trigger.isInsert){
        List<String> recipients = new List<String>();
        String documentRequestId = '';
        String notes = '';
        for (DHS_Document_Request__c dr: Trigger.new){
            recipients.add(dr.To_Address__c);
            if(dr.Additional_To_Address__c != Null)
            recipients.add(dr.Additional_To_Address__c); // NOPMD
            documentRequestId = dr.id;
            notes = dr.Investigator_Comments__c;

        }
       
        String encodedId = encodeURLParams(documentRequestId);
        String encodedUrl = 'https://insight-isn-usda-sites.cs32.force.com/SPortal/apex/DHSSubjectDocumentsUpload?id='+encodedId;

        String emailSubject = 'Testing';
        String htmlBody = 'Hello, <br/><br/>'+notes+'<br/><br/><a href="'+encodedUrl+'" target="_blank">Upload Docs</a><br/><br/>';
        
        DHSMailUtilities.sendHTMLEmail(recipients, emailSubject, htmlBody, null);
    }

    private String encodeURLParams(String inputString){
        // create a blob from our parameter value before we send it as part of the url
        Blob beforeblob = Blob.valueOf(inputString);
   
        // base64 encode the blob that contains our url param value
        String paramvalue = EncodingUtil.base64Encode(beforeblob);
   
        // print out the encoded value to the debug log so we can see it before/after base64 encode
        System.debug(inputString + ' is now encoded as: ' + paramvalue); // NOPMD
       
        return paramValue;   
    }
    
     private String decodeURLParams(String encodedString){
    
         // take the base64 encoded parameter and create base64 decoded Blob from it   
         Blob afterblob = EncodingUtil.base64Decode(encodedString);
   
         // Convert the blob back to a string and print it in the debug log
         System.debug(encodedString + 'is now decoded as: ' + afterblob.toString()); // NOPMD
         
         return afterblob.toString();
        
    }
}