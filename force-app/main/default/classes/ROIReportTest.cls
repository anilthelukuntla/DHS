@IsTest
/** Verifies the legacy ROI report page can load an ordered report. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
public class ROIReportTest {
    @IsTest
    static void buildsOrderedRoiReportForCase() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            Contact__c subjectRecord = new Contact__c(
                First_Name__c = 'ROI',
                Last_Name__c = 'Subject',
                Email__c = 'roi.subject@example.com',
                SSN__c = '123-45-6789'
            );
            insert subjectRecord;
            Case__c caseRecord = new Case__c(
                Contact__c = subjectRecord.Id,
                Subject_Type__c = 'Applicant',
                Assigned_To__c = UserInfo.getUserId(),
                Customer_Delivery_Date__c = Date.today()
            );
            insert caseRecord;
            Lead__c leadRecord = new Lead__c(
                Case__c = caseRecord.Id,
                Item_Number__c = 1,
                LeadType__c = 'Subject Interview (ESI/TESI)',
                Coverage_Type__c = 'Personal',
                Status__c = 'Completed'
            );
            insert leadRecord;
            List<String> leadTypes = new List<String>{
                'Subject contact (SUBC)', 'Residence (RESI)',
                'Employment (EMPL)', 'Education (EDUC)', 'Medical (MEDI)',
                'References (REFE)', 'General (GENL)',
                'Former Spouse (FMSP)', 'Law Enforcement (LAWE)',
                'Financial (FINL)'
            };
            List<Lead__c> additionalLeads = new List<Lead__c>();
            Integer itemNumber = 2;
            for (String leadType : leadTypes) {
                additionalLeads.add(new Lead__c(
                    Case__c = caseRecord.Id,
                    Item_Number__c = itemNumber,
                    LeadType__c = leadType,
                    Coverage_Type__c = leadType == 'General (GENL)'
                        ? 'General Record' : 'Personal',
                    Status__c = 'Completed',
                    Was_the_record_obtained__c = leadType == 'General (GENL)'
                        ? 'Yes' : null
                ));
                itemNumber++;
            }
            insert additionalLeads;
            ROI_Report_Order__c sequenceRecord = new ROI_Report_Order__c(
                Case__c = caseRecord.Id,
                ROI_Report_Order__c = '1,2,3,4,5,6,7,8,9,10,11',
                HideTitles__c = '4'
            );
            insert sequenceRecord;

            Test.setCurrentPage(Page.ROIReportV2);
            ApexPages.currentPage().getParameters().put('id', caseRecord.Id);
            ApexPages.currentPage().getParameters().put(
                'sequenceid', sequenceRecord.Id
            );
            ApexPages.currentPage().getParameters().put('download', 'true');

            Test.startTest();
            ROIReportControllerV2 controllerValue =
                new ROIReportControllerV2();
            Test.stopTest();

            System.assertEquals(caseRecord.Id, controllerValue.caseId, 'Assertion failed in ROIReportTest at source line 73');
            System.assertEquals(11, controllerValue.totalLeads, 'Assertion failed in ROIReportTest at source line 74');
            System.assertEquals(true, controllerValue.hasSubjectInterview, 'Assertion failed in ROIReportTest at source line 75');
            System.assertEquals(true, controllerValue.hasSubjectRecontact, 'Assertion failed in ROIReportTest at source line 76');
            System.assertEquals(true, controllerValue.hasResidence, 'Assertion failed in ROIReportTest at source line 77');
            System.assertEquals(
                null,
                ROIReportControllerV2.findClosest(new List<Integer>(), 1)
            , 'Assertion failed in ROIReportTest at source line 78');

            Test.setCurrentPage(Page.ROIReport);
            ApexPages.currentPage().getParameters().put('id', caseRecord.Id);
            ROIReportController legacyController = new ROIReportController();
            System.assertEquals(caseRecord.Id, legacyController.caseId, 'Assertion failed in ROIReportTest at source line 86');
            System.assertEquals(11, legacyController.totalLeads, 'Assertion failed in ROIReportTest at source line 87');
            System.assertEquals(1, legacyController.subjectInterviewList.size(), 'Assertion failed in ROIReportTest at source line 88');
            System.assertEquals(1, legacyController.employmentList.size(), 'Assertion failed in ROIReportTest at source line 89');
            System.assertEquals(1, legacyController.educationList.size(), 'Assertion failed in ROIReportTest at source line 90');
            System.assertEquals(1, legacyController.medicalList.size(), 'Assertion failed in ROIReportTest at source line 91');
        }
    }
}