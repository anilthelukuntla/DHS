/** Retains the existing DHSUploadMultiFileUpload integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc,PMD.ApexSharingViolations,PMD.AvoidHardcodingId,PMD.UnusedMethod')
public class DHSUploadMultiFileUpload {
    public string caseId {get;set;}
    public string recordId {get;set;}
    public DHSUploadMultiFileUpload(){
        caseId = String.valueOf(Id.valueOf(ApexPages.currentPage().getParameters().get('caseid').escapeHtml4()));
        recordId = 'a02cn000000xbhtAAA';
    }
        
    @RemoteAction
    public static String processUploadedFiles(string caseId,string fileName) {
		caseId = String.valueOf(Id.valueOf(caseId.escapeHtml4()));
		fileName = fileName.escapeHtml4();
		DHS_Document__c doc = New DHS_Document__c();
		doc.Added_By__c = [Select Id,Name from user where id=:userinfo.getuserid()].Name;
		doc.DHS_Case__c = caseId;
		doc.Name__c = fileName;
        Database.insert(doc, AccessLevel.USER_MODE);
        return doc.Id;
    }
}
