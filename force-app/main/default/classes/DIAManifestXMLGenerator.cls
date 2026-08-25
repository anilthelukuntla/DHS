public with sharing class DIAManifestXMLGenerator {
    public static string LoadReleasesXML(String caseId){
        return null;
    }
    public static string LoadReleasesXML(List<String> caseRecordIds, String versionNumber){
        String caseList;
        List<DIA_Case__c> cases = new List<DIA_Case__c>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        List<string> caseFields = new List<string>();
        caseFields = ApexUtil.FetchFields('DIA_Case__c');
        caseFields.add('contact__r.First_Name__c');
        caseFields.add('contact__r.SSN__c');
        caseFields.add('contact__r.Last_Name__c');
        caseFields.add('contact__r.Email__c');
        caseFields.add('Assigned_to__r.FirstName');
        caseFields.add('Assigned_to__r.LastName');
        caseFields.add('Assigned_to__r.Email');
        caseFields.add('owner.email');
        
        String query = 'Select '+string.join(caseFields, ',') + ' From DIA_Case__c WHERE ID IN:caseRecordIds WITH SECURITY_ENFORCED';
        
        System.debug('query...'+query);
        cases = database.query(query);
        
        Map<String,String> documentIdnCaseIdMap = new Map<String,String>();
        
        List<DIA_document__c> documents = new List<DIA_document__c> ();
        List<string> documentFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria2 = new List<ApexUtil.Criteria>();
        documentFields = ApexUtil.FetchFields('DIA_document__c');      
        String query2 = 'Select '+string.join(documentFields, ',') + ' From DIA_document__c WHERE CASE__c IN:caseRecordIds WITH SECURITY_ENFORCED';
      
        documents = database.query(query2);
        
        List<string> documentIds = new List<string>();
        Map<String,DIA_document__c> documentsMap = new Map<String,DIA_document__c>();
        for(DIA_document__c doc: documents){
            documentIds.add(doc.id);
            documentIdnCaseIdMap.put(doc.id,doc.case__c);
            documentsMap.put(doc.id,doc);
        }
        List<attachment> attachments = new List<attachment>();
        Map<String,List<Attachment>> mapofCaseIdnAttachments = new Map<String,List<Attachment>>();  
        attachments = [Select id, parentid, BodyLength, Name from attachment where parentid in: documentIds WITH SECURITY_ENFORCED];
        
        Map<String,String> documentNattachmentMap = new Map<String,String>();
        for(attachment att: attachments){
            documentNattachmentMap.put(att.parentid, att.id);
            if(!mapofCaseIdnAttachments.containsKey(documentIdnCaseIdMap.get(att.parentid))){
                mapofCaseIdnAttachments.put(documentIdnCaseIdMap.get(att.parentid), new List<Attachment>{att});
            }else{
                List<attachment> atts = new List<attachment>();
                atts = mapofCaseIdnAttachments.get(documentIdnCaseIdMap.get(att.parentid));
                atts.add(att);
                mapofCaseIdnAttachments.put(documentIdnCaseIdMap.get(att.parentid), atts);
            } 
        }

        String xmlstring;
        String currentDateTime = System.now().format('yyyy-MM-dd\'T\'HH:mm:ss');
        DOM.Document doc = new DOM.Document();
        dom.XmlNode manifestNode = doc.createRootElement('manifest', null, null);
        manifestNode.setAttribute('datetime',currentDateTime);
        manifestNode.setAttribute('schemaVersion','1.0');
        manifestNode.setAttribute('sequence','1');
        manifestNode.setAttribute('filecount',String.valueof(attachments.size()));
        for(DIA_Case__c c: Cases){
           
            String applicantType;
            String ssnFormatted;
            if(c.Subject_Type__c == 'Applicant'){
                applicantType = 'A';
            }
            if(c.Subject_Type__c == 'Contractor'){
                applicantType = 'C';
            }
            if(c.Contact__r.SSN__c != Null){
                ssnFormatted = c.Contact__r.SSN__c.replaceAll('-','');
            }
            
            dom.xmlNode filesNode = manifestNode.addChildElement('files', null, null); 
            Integer i = 00;    
            if(mapofCaseIdnAttachments.get(c.id)!= Null){
                for(Attachment att: mapofCaseIdnAttachments.get(c.id)){
                    System.debug('documentsMap.get(att.parentid).Name__c ...'+documentsMap.get(att.parentid));
                    if(documentsMap.get(att.parentid).Name__c == 'ROIReport'){
                        string fileNameFormatted;
                        if(integer.valueof(versionNumber) < 10){
                            fileNameFormatted = applicantType + ssnFormatted + 'Rev0'+versionNumber+'.pdf';
                        }else{
                            fileNameFormatted = applicantType + ssnFormatted + 'Rev'+versionNumber+'.pdf';
                        }
                        dom.xmlNode fileNode = filesNode.addChildElement('file', null, null);    
                        dom.xmlNode fileNameNode = fileNode.addChildElement('filename', null, null).addTextNode(fileNameFormatted); 
                        dom.xmlNode fileSizeNode = fileNode.addChildElement('filesize', null, null).addTextNode(String.valueof(att.BodyLength)); 
                         
                       
                    }else{
                        string fileNameFormatted;
                        if(i<10){
                            fileNameFormatted = applicantType + ssnFormatted + 'Att0'+i+'.pdf';
                        }else{
                            fileNameFormatted = applicantType + ssnFormatted + 'Att'+i+'.pdf';
                        }
                        dom.xmlNode fileNode = filesNode.addChildElement('file', null, null);    
                        dom.xmlNode fileNameNode = fileNode.addChildElement('filename', null, null).addTextNode(fileNameFormatted);   
                        dom.xmlNode fileSizeNode = fileNode.addChildElement('filesize', null, null).addTextNode(String.valueof(att.BodyLength)); 
                        i++;
                    }
                }
            }
        }
        xmlstring = doc.toXmlString();
        System.debug('xmlstring...'+xmlstring);
        return xmlString;
    }
}