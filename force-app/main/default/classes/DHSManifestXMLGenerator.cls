/**
 * @description Retains the existing DHSManifestXMLGenerator integration and application behavior.
 */
@SuppressWarnings('PMD.ApexSOQLInjection,PMD.ApexSharingViolations,PMD.AvoidDeeplyNestedIfStmts,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.NcssCount,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity,PMD.UnusedMethod')
public class DHSManifestXMLGenerator {
    /**
     * @description Provides this DHS API member.
     * @param caseId Method parameter.
     * @return The requested result.
     */
    public static string loadReleasesXML(String caseId){
        return null;
    }
    /**
     * @description Provides this DHS API member.
     * @param caseRecordIds Method parameter.
     * @param versionNumber Method parameter.
     * @return The requested result.
     */
    public static string loadReleasesXML(List<String> caseRecordIds, String versionNumber){
        List<DHS_Case__c> cases = new List<DHS_Case__c>();
        List<string> caseFields = new List<string>();
        caseFields = DHSApexUtil.FetchFields('DHS_Case__c');
        caseFields.add('DHS_Contact__r.First_Name__c');
        caseFields.add('DHS_Contact__r.SSN__c');
        caseFields.add('DHS_Contact__r.Last_Name__c');
        caseFields.add('DHS_Contact__r.Email__c');
        caseFields.add('DHS_Assigned_To__r.FirstName');
        caseFields.add('DHS_Assigned_To__r.LastName');
        caseFields.add('DHS_Assigned_To__r.Email');
        caseFields.add('owner.email');

        String query = 'Select '+string.join(caseFields, ',') + ' From DHS_Case__c WHERE ID IN:caseRecordIds';

        // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
        cases = database.query(query);

        Map<String,String> documentIdnCaseIdMap = new Map<String,String>();

        List<DHS_Document__c> documents = new List<DHS_Document__c> ();
        List<string> documentFields = new List<string>();
        documentFields = DHSApexUtil.FetchFields('DHS_Document__c');
        String query2 = 'Select '+string.join(documentFields, ',') + ' From DHS_Document__c WHERE DHS_Case__c IN:caseRecordIds';

        // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
        documents = database.query(query2);

        List<string> documentIds = new List<string>();
        Map<String,DHS_Document__c> documentsMap = new Map<String,DHS_Document__c>();
        for(DHS_Document__c doc: documents){
            documentIds.add(doc.id);
            documentIdnCaseIdMap.put(doc.id,doc.DHS_Case__c);
            documentsMap.put(doc.id,doc);
        }
        List<attachment> attachments = new List<attachment>();
        Map<String,List<Attachment>> mapofCaseIdnAttachments = new Map<String,List<Attachment>>();
        attachments = [Select id, parentid, BodyLength, Name from attachment where parentid in: documentIds WITH USER_MODE ];

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
        for(DHS_Case__c c: Cases){

            String applicantType;
            String ssnFormatted;
            if(c.Subject_Type__c == 'Applicant'){
                applicantType = 'A';
            }
            if(c.Subject_Type__c == 'Contractor'){
                applicantType = 'C';
            }
            if(c.DHS_Contact__r.SSN__c != Null){
                ssnFormatted = c.DHS_Contact__r.SSN__c.replaceAll('-','');
            }

            dom.xmlNode filesNode = manifestNode.addChildElement('files', null, null);
            Integer i = 00;
            if(mapofCaseIdnAttachments.get(c.id)!= Null){
                for(Attachment att: mapofCaseIdnAttachments.get(c.id)){
                    if(documentsMap.get(att.parentid).Name__c == 'ROIReport'){
                        string fileNameFormatted;
                        if(integer.valueof(versionNumber) < 10){
                            fileNameFormatted = applicantType + ssnFormatted + 'Rev0'+versionNumber+'.pdf';
                        }else{
                            fileNameFormatted = applicantType + ssnFormatted + 'Rev'+versionNumber+'.pdf';
                        }
                        dom.xmlNode fileNode = filesNode.addChildElement('file', null, null);
                        fileNode.addChildElement('filename', null, null).addTextNode(fileNameFormatted);
                        fileNode.addChildElement('filesize', null, null).addTextNode(String.valueof(att.BodyLength));


                    }else{
                        string fileNameFormatted;
                        if(i<10){
                            fileNameFormatted = applicantType + ssnFormatted + 'Att0'+i+'.pdf';
                        }else{
                            fileNameFormatted = applicantType + ssnFormatted + 'Att'+i+'.pdf';
                        }
                        dom.xmlNode fileNode = filesNode.addChildElement('file', null, null);
                        fileNode.addChildElement('filename', null, null).addTextNode(fileNameFormatted);
                        fileNode.addChildElement('filesize', null, null).addTextNode(String.valueof(att.BodyLength));
                        i++;
                    }
                }
            }
        }
        xmlstring = doc.toXmlString();
        return xmlString;
    }
}
