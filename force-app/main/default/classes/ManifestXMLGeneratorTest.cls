@IsTest
/** Exercises PPF manifest naming for ROI and attachment documents. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class ManifestXMLGeneratorTest {
    @IsTest
    static void buildsApplicantAndContractorManifestFiles() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            List<Contact__c> contacts = new List<Contact__c>{
                new Contact__c(
                    First_Name__c = 'Applicant', Last_Name__c = 'Coverage',
                    Email__c = 'ppf-applicant@example.com', SSN__c = '111-22-3333',
                    Contact_Type__c = 'Subject'
                ),
                new Contact__c(
                    First_Name__c = 'Contractor', Last_Name__c = 'Coverage',
                    Email__c = 'ppf-contractor@example.com', SSN__c = '444-55-6666',
                    Contact_Type__c = 'Subject'
                )
            };
            insert contacts;
            List<Case__c> cases = new List<Case__c>{
                new Case__c(
                    Contact__c = contacts[0].Id,
                    Assigned_To__c = UserInfo.getUserId(),
                    Subject_Type__c = 'Applicant'
                ),
                new Case__c(
                    Contact__c = contacts[1].Id,
                    Assigned_To__c = UserInfo.getUserId(),
                    Subject_Type__c = 'Contractor'
                )
            };
            insert cases;
            List<Document__c> documents = new List<Document__c>();
            for (Case__c caseRecord : cases) {
                documents.add(new Document__c(
                    Case__c = caseRecord.Id, Name__c = 'ROIReport'
                ));
                documents.add(new Document__c(
                    Case__c = caseRecord.Id, Name__c = 'Attachment'
                ));
            }
            insert documents;
            List<Attachment> attachments = new List<Attachment>();
            for (Document__c documentRecord : documents) {
                attachments.add(new Attachment(
                    ParentId = documentRecord.Id,
                    Name = documentRecord.Name__c + '.pdf',
                    Body = Blob.valueOf('manifest coverage')
                ));
            }
            insert attachments;

            String versionOne = ManifestXMLGenerator.LoadReleasesXML(
                new List<String>{ cases[0].Id, cases[1].Id }, '1'
            );
            String versionTen = ManifestXMLGenerator.LoadReleasesXML(
                new List<String>{ cases[0].Id, cases[1].Id }, '10'
            );

            System.assert(versionOne.contains('A111223333Rev01.pdf'), 'Assertion failed in ManifestXMLGeneratorTest at source line 62');
            System.assert(versionOne.contains('C444556666Att00.pdf'), 'Assertion failed in ManifestXMLGeneratorTest at source line 63');
            System.assert(versionTen.contains('Rev10.pdf'), 'Assertion failed in ManifestXMLGeneratorTest at source line 64');
            System.assertEquals(null, ManifestXMLGenerator.LoadReleasesXML(cases[0].Id), 'Assertion failed in ManifestXMLGeneratorTest at source line 65');
        }
    }
}