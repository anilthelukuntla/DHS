/** Retains the existing DHSUploadMultiFileUpload integration and application behavior. */
@SuppressWarnings('PMD.ApexSharingViolations, PMD.ApexDoc, PMD.DebugsShouldUseLoggingLevel, PMD.AvoidHardcodingId, PMD.ApexXSSFromURLParam, PMD.ApexCRUDViolation')
public class DHSUploadMultiFileUpload {
    public string caseId {get;set;}
    public string recordId {get;set;}
    public DHSUploadMultiFileUpload(){
        caseId = apexpages.currentpage().getparameters().get('caseid');
        recordId = 'a02cn000000xbhtAAA';
    }
        
    @RemoteAction
    public static String processUploadedFiles(string caseId,string fileName) {
		DHS_Document__c doc = New DHS_Document__c();
		doc.Added_By__c = [Select Id,Name from user where id=:userinfo.getuserid()].Name;
		doc.DHS_Case__c = caseId;
		doc.Name__c = fileName;
        insert doc;
        return doc.Id;
    }
}