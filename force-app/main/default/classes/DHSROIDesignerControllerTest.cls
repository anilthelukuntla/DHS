@IsTest
/** Exercises the existing DHSROIDesignerController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ExcessiveParameterList')
private class DHSROIDesignerControllerTest {

    @TestSetup
    static void setupData() {
        PPFDHSTestUserFactory.createPmoUser();
        insert new Account(Name = 'ISN');

        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = 'Designer',
            Last_Name__c = 'Subject',
            Email__c = 'designer.subject@example.com',
            Contact_Type__c = 'Subject'
        );
        insert subject;

        insert new List<DHS_Case__c>{
            new DHS_Case__c(
                DHS_Contact__c = subject.Id,
                Case_Number__c = 'DESIGN-001',
                Customer_Case_Number__c = 'CUSTOMER-001'
            ),
            new DHS_Case__c(
                DHS_Contact__c = subject.Id,
                Case_Number__c = 'NO-LEADS-001'
            )
        };
    }

    private static DHS_Case__c getCase(String caseNumber) {
        return [
            SELECT Id,
                   Name,
                   Case_Number__c,
                   Customer_Case_Number__c,
                   DHS_Contact__c
            FROM DHS_Case__c
            WHERE Case_Number__c = :caseNumber
            LIMIT 1
        ];
    }

    @IsTest
    static void exercisesDesignerValueObjects() {
        Test.startTest();

        DHSROIDesignerController.FieldOption field =
            new DHSROIDesignerController.FieldOption(
                'Case Number',
                'DHS_Case__c.Case_Number__c',
                'case'
            );

        DHSROIDesignerController.CaseOption caseOption =
            new DHSROIDesignerController.CaseOption(
                null,
                'Test Case'
            );

        DHSROIDesignerController.PicklistOption picklist =
            new DHSROIDesignerController.PicklistOption(
                'General',
                'General (GENL)'
            );

        Test.stopTest();

        System.assertEquals('Case Number', field.label, 'Assertion failed in DHSROIDesignerControllerTest at source line 70');
        System.assertEquals(
            'DHS_Case__c.Case_Number__c',
            field.value
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 71');
        System.assertEquals('case', field.scope, 'Assertion failed in DHSROIDesignerControllerTest at source line 75');

        System.assertEquals(null, caseOption.value, 'Assertion failed in DHSROIDesignerControllerTest at source line 77');
        System.assertEquals('Test Case', caseOption.label, 'Assertion failed in DHSROIDesignerControllerTest at source line 78');

        System.assertEquals('General', picklist.label, 'Assertion failed in DHSROIDesignerControllerTest at source line 80');
        System.assertEquals(
            'General (GENL)',
            picklist.value
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 81');
    }

    @IsTest
    static void getsMergeFields() {
        Test.startTest();

        List<DHSROIDesignerController.FieldOption> fields =
            DHSROIDesignerController.getMergeFields();

        Test.stopTest();

        System.assertNotEquals(null, fields, 'Assertion failed in DHSROIDesignerControllerTest at source line 96');
        System.assert(
            !fields.isEmpty(),
            'Accessible merge fields should be returned.'
        );

        Boolean caseFieldFound = false;
        Boolean contactFieldFound = false;
        Boolean leadFieldFound = false;

        for (
            DHSROIDesignerController.FieldOption field :
            fields
        ) {
            System.assertNotEquals(null, field.label, 'Assertion failed in DHSROIDesignerControllerTest at source line 110');
            System.assertNotEquals(null, field.value, 'Assertion failed in DHSROIDesignerControllerTest at source line 111');
            System.assertNotEquals(null, field.scope, 'Assertion failed in DHSROIDesignerControllerTest at source line 112');

            if (field.value.startsWith('DHS_Case__c.')) {
                caseFieldFound = true;
            } else if (
                field.value.startsWith('DHS_Contact__r.')
            ) {
                contactFieldFound = true;
            } else if (
                field.value.startsWith('DHS_Lead__c.')
            ) {
                leadFieldFound = true;
            }
        }

        System.assertEquals(true, caseFieldFound, 'Assertion failed in DHSROIDesignerControllerTest at source line 127');
        System.assertEquals(true, contactFieldFound, 'Assertion failed in DHSROIDesignerControllerTest at source line 128');
        System.assertEquals(true, leadFieldFound, 'Assertion failed in DHSROIDesignerControllerTest at source line 129');
    }

    @IsTest
    static void searchesCasesByCaseNumber() {
        Test.startTest();

        List<DHSROIDesignerController.CaseOption> results =
            DHSROIDesignerController.searchCases('DESIGN');

        Test.stopTest();

        System.assertEquals(1, results.size(), 'Assertion failed in DHSROIDesignerControllerTest at source line 141');
        System.assertEquals(
            getCase('DESIGN-001').Id,
            results[0].value
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 142');
        System.assert(
            results[0].label.contains('DESIGN-001')
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 146');
        System.assert(
            results[0].label.contains('CUSTOMER-001')
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 149');
        System.assert(
            results[0].label.contains('Designer Subject')
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 152');
    }

    @IsTest
    static void searchesCasesWithBlankTerm() {
        Test.startTest();

        List<DHSROIDesignerController.CaseOption> results =
            DHSROIDesignerController.searchCases(null);

        Test.stopTest();

        System.assertNotEquals(null, results, 'Assertion failed in DHSROIDesignerControllerTest at source line 166');
        System.assert(
            results.size() >= 2
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 167');
    }

    @IsTest
    static void getsValidPicklistValues() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        Test.startTest();

        List<DHSROIDesignerController.PicklistOption> values =
            DHSROIDesignerController.getPicklistValues(
                'DHS_Lead__c.LeadType__c'
            );

        Test.stopTest();

        System.assertNotEquals(null, values, 'Assertion failed in DHSROIDesignerControllerTest at source line 184');
        System.assert(
            !values.isEmpty(),
            'Lead type picklist values should be returned.'
        );

        for (
            DHSROIDesignerController.PicklistOption option :
            values
        ) {
            System.assertNotEquals(null, option.label, 'Assertion failed in DHSROIDesignerControllerTest at source line 194');
            System.assertNotEquals(null, option.value, 'Assertion failed in DHSROIDesignerControllerTest at source line 195');
        }
        }
    }

    @IsTest
    static void returnsEmptyForInvalidOrNonPicklistField() {
        Test.startTest();

        List<DHSROIDesignerController.PicklistOption>
            invalidField =
                DHSROIDesignerController.getPicklistValues(
                    'Invalid_Object__c.Invalid_Field__c'
                );

        List<DHSROIDesignerController.PicklistOption>
            nonPicklistField =
                DHSROIDesignerController.getPicklistValues(
                    'DHS_Case__c.Case_Number__c'
                );

        List<DHSROIDesignerController.PicklistOption>
            blankField =
                DHSROIDesignerController.getPicklistValues(
                    null
                );

        Test.stopTest();

        System.assertEquals(0, invalidField.size(), 'Assertion failed in DHSROIDesignerControllerTest at source line 224');
        System.assertEquals(0, nonPicklistField.size(), 'Assertion failed in DHSROIDesignerControllerTest at source line 225');
        System.assertEquals(0, blankField.size(), 'Assertion failed in DHSROIDesignerControllerTest at source line 226');
    }

    @IsTest
    static void getsTemplateLeadTypes() {
        Test.startTest();

        List<DHSROIDesignerController.PicklistOption> options =
            DHSROIDesignerController.getTemplateLeadTypes();

        Test.stopTest();

        System.assertNotEquals(null, options, 'Assertion failed in DHSROIDesignerControllerTest at source line 238');
        System.assert(options.size() >= 5, 'Assertion failed in DHSROIDesignerControllerTest at source line 239');

        Set<String> values = new Set<String>();

        for (
            DHSROIDesignerController.PicklistOption option :
            options
        ) {
            values.add(option.value);
        }

        System.assert(values.contains('Header'), 'Assertion failed in DHSROIDesignerControllerTest at source line 250');
        System.assert(values.contains('Disclaimer'), 'Assertion failed in DHSROIDesignerControllerTest at source line 251');
        System.assert(values.contains('PAEI'), 'Assertion failed in DHSROIDesignerControllerTest at source line 252');
        System.assert(values.contains('Summary'), 'Assertion failed in DHSROIDesignerControllerTest at source line 253');
        System.assert(values.contains('Report Table'), 'Assertion failed in DHSROIDesignerControllerTest at source line 254');
    }

    @IsTest
    static void getsCaseLevelCoverageType() {
        Test.startTest();

        List<DHSROIDesignerController.PicklistOption> options =
            DHSROIDesignerController.getTemplateCoverageTypes('Header');

        Test.stopTest();

        System.assertEquals(1, options.size(), 'Assertion failed in DHSROIDesignerControllerTest at source line 266');
        System.assertEquals('Header', options[0].label, 'Assertion failed in DHSROIDesignerControllerTest at source line 267');
        System.assertEquals('Header', options[0].value, 'Assertion failed in DHSROIDesignerControllerTest at source line 268');
    }

    @IsTest
    static void getsDefaultLeadCoverageTypes() {
        Test.startTest();

        List<DHSROIDesignerController.PicklistOption>
            subjectInterview =
                DHSROIDesignerController.getTemplateCoverageTypes(
                        'Subject Interview (ESI/TESI)'
                    );

        List<DHSROIDesignerController.PicklistOption>
            general =
                DHSROIDesignerController.getTemplateCoverageTypes(
                        'General (GENL)'
                    );

        List<DHSROIDesignerController.PicklistOption>
            unsupported =
                DHSROIDesignerController.getTemplateCoverageTypes(
                        'Unsupported Lead Type'
                    );

        List<DHSROIDesignerController.PicklistOption>
            blank =
                DHSROIDesignerController.getTemplateCoverageTypes(null);

        Test.stopTest();

        System.assertEquals(1, subjectInterview.size(), 'Assertion failed in DHSROIDesignerControllerTest at source line 299');
        System.assertEquals(
            'Subject Interview',
            subjectInterview[0].value
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 300');

        Set<String> generalValues = new Set<String>();

        for (
            DHSROIDesignerController.PicklistOption option :
            general
        ) {
            generalValues.add(option.value);
        }

        System.assert(generalValues.contains('Record'), 'Assertion failed in DHSROIDesignerControllerTest at source line 314');
        System.assert(generalValues.contains('Personal'), 'Assertion failed in DHSROIDesignerControllerTest at source line 315');
        System.assertEquals(0, unsupported.size(), 'Assertion failed in DHSROIDesignerControllerTest at source line 316');
        System.assertEquals(0, blank.size(), 'Assertion failed in DHSROIDesignerControllerTest at source line 317');
    }

    @IsTest
    static void saveConfigRejectsBlankJSON() {
        assertSaveConfigFails(
            null,
            'General (GENL)',
            'Personal'
        );
    }

    @IsTest
    static void saveConfigRequiresTemplateSelection() {
        assertSaveConfigFails(
            '{"elements":[]}',
            null,
            'Personal'
        );

        assertSaveConfigFails(
            '{"elements":[]}',
            'General (GENL)',
            null
        );
    }

    @IsTest
    static void saveConfigRejectsInvalidJSON() {
        assertSaveConfigFails(
            '{"elements":[',
            'General (GENL)',
            'Personal'
        );
    }

    @IsTest
    static void savesAndLoadsConfiguration() {
        String config = JSON.serialize(
            new Map<String, Object>{
                'elements' => new List<Object>{
                    new Map<String, Object>{
                        'id' => 'case-number',
                        'type' => 'text',
                        'scope' => 'case',
                        'text' =>
                            'Case {{Case Number}}',
                        'tokens' => new List<Object>{
                            new Map<String, Object>{
                                'label' => 'Case Number',
                                'fieldPath' =>
                                    'DHS_Case__c.Case_Number__c'
                            }
                        },
                        'page' => 1,
                        'x' => 10,
                        'y' => 10,
                        'width' => 300,
                        'height' => 40
                    }
                }
            }
        );

        Test.startTest();

        String saveResult =
            DHSROIDesignerController.saveConfig(
                config,
                'General (GENL)',
                'Personal'
            );

        String loadedConfig =
            DHSROIDesignerController.getConfig(
                'General (GENL)',
                'Personal'
            );

        Test.stopTest();

        System.assertEquals('Saved', saveResult, 'Assertion failed in DHSROIDesignerControllerTest at source line 398');
        System.assertEquals(config, loadedConfig, 'Assertion failed in DHSROIDesignerControllerTest at source line 399');
    }

    @IsTest
    static void savesNewVersionOfExistingConfiguration() {
        String firstConfig = '{"elements":[]}';

        String secondConfig = JSON.serialize(
            new Map<String, Object>{
                'elements' => new List<Object>{
                    new Map<String, Object>{
                        'type' => 'section',
                        'text' => 'Updated configuration'
                    }
                }
            }
        );

        DHSROIDesignerController.saveConfig(
            firstConfig,
            'General (GENL)',
            'Record'
        );

        Test.startTest();

        String result =
            DHSROIDesignerController.saveConfig(
                secondConfig,
                'General (GENL)',
                'Record'
            );

        String loadedConfig =
            DHSROIDesignerController.getConfig(
                'General (GENL)',
                'Record'
            );

        Test.stopTest();

        System.assertEquals('Saved', result, 'Assertion failed in DHSROIDesignerControllerTest at source line 440');
        System.assertEquals(secondConfig, loadedConfig, 'Assertion failed in DHSROIDesignerControllerTest at source line 441');

        Account isnAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'ISN'
            LIMIT 1
        ];

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :isnAccount.Id
        ];

        System.assertEquals(1, links.size(), 'Assertion failed in DHSROIDesignerControllerTest at source line 456');

        System.assertEquals(
            2,
            [
                SELECT COUNT()
                FROM ContentVersion
                WHERE ContentDocumentId =
                    :links[0].ContentDocumentId
            ]
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 458');
    }

    @IsTest
    static void loadsDefaultWhenNoSavedConfigExists() {
        Test.startTest();

        String config =
            DHSROIDesignerController.getConfig(
                'Subject Interview (ESI/TESI)',
                'Subject Interview'
            );

        Test.stopTest();

        System.assertNotEquals(null, config, 'Assertion failed in DHSROIDesignerControllerTest at source line 481');

        Map<String, Object> parsedConfig =
            (Map<String, Object>)
                JSON.deserializeUntyped(config);

        System.assert(
            parsedConfig.containsKey('elements')
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 487');
    }

    @IsTest
    static void rendersNoCaseSelectedPreview() {
        Test.startTest();

        String preview =
            DHSROIDesignerController.renderCasePreview(null);

        Test.stopTest();

        System.assert(
            preview.contains('No case was selected')
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 501');
    }

    @IsTest
    static void rendersCaseWithoutLeads() {
        DHS_Case__c caseRecord = getCase('NO-LEADS-001');

        Test.startTest();

        String preview =
            DHSROIDesignerController.renderCasePreview(
                caseRecord.Id
            );

        Test.stopTest();

        System.assert(
            preview.contains('No leads were found')
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 519');
    }

    @IsTest
    static void rendersBlankConfiguration() {
        Test.startTest();

        String preview =
            DHSROIDesignerController.renderPreview(
                null,
                null
            );

        Test.stopTest();

        System.assertNotEquals(null, preview, 'Assertion failed in DHSROIDesignerControllerTest at source line 536');
        System.assert(
            preview.startsWith(
                '<div class="roi-preview-document">'
            )
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 537');
    }

    @IsTest
    static void rendersComplexPreview() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        DHS_Case__c caseRecord = getCase('DESIGN-001');

        DHS_Lead__c lead = new DHS_Lead__c(
            DHS_Case__c = caseRecord.Id,
            DHS_Contact__c = caseRecord.DHS_Contact__c,
            DHS_Assigned_To__c = UserInfo.getUserId(),
            LeadType__c = 'General (GENL)',
            Coverage_Type__c = 'Personal',
            Status__c = 'Assigned',
            Item_number__c = 1,
            Investigators_Notes__c =
                'Completed investigator notes'
        );
        insert lead;

        String config = buildComplexConfiguration();

        Test.startTest();

        String preview =
            DHSROIDesignerController.renderPreview(
                config,
                caseRecord.Id
            );

        Test.stopTest();

        System.assertNotEquals(null, preview, 'Assertion failed in DHSROIDesignerControllerTest at source line 574');
        System.assert(
            preview.contains('REPORT OF INVESTIGATION')
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 575');
        System.assert(
            preview.contains('DESIGN-001')
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 578');
        System.assert(
            preview.contains('Completed investigator notes')
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 581');
        System.assert(
            preview.contains('roi-signature')
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 584');
        System.assert(
            preview.contains('<hr/>')
        , 'Assertion failed in DHSROIDesignerControllerTest at source line 587');
        }
    }

    @IsTest
    static void rendersDefaultTemplatesAcrossLeadContexts() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        DHS_Case__c caseRecord = getCase('DESIGN-001');
        List<DHS_Lead__c> leads = new List<DHS_Lead__c>{
            new DHS_Lead__c(
                DHS_Case__c = caseRecord.Id,
                DHS_Contact__c = caseRecord.DHS_Contact__c,
                DHS_Assigned_To__c = UserInfo.getUserId(),
                LeadType__c = 'Subject Interview (ESI/TESI)',
                Coverage_Type__c = 'Subject Interview',
                Status__c = 'Assigned', Item_number__c = 1,
                Investigators_Notes__c = 'Interview completed'
            ),
            new DHS_Lead__c(
                DHS_Case__c = caseRecord.Id,
                DHS_Contact__c = caseRecord.DHS_Contact__c,
                DHS_Assigned_To__c = UserInfo.getUserId(),
                LeadType__c = 'Residence (RESI)',
                Coverage_Type__c = 'Personal',
                Status__c = 'Assigned', Item_number__c = 2,
                Investigators_Notes__c = 'Residence completed'
            ),
            new DHS_Lead__c(
                DHS_Case__c = caseRecord.Id,
                DHS_Contact__c = caseRecord.DHS_Contact__c,
                DHS_Assigned_To__c = UserInfo.getUserId(),
                LeadType__c = 'General (GENL)',
                Coverage_Type__c = 'Record',
                Status__c = 'Assigned', Item_number__c = 3,
                Investigators_Notes__c = 'Record completed'
            ),
            new DHS_Lead__c(
                DHS_Case__c = caseRecord.Id,
                DHS_Contact__c = caseRecord.DHS_Contact__c,
                DHS_Assigned_To__c = UserInfo.getUserId(),
                LeadType__c = 'References (REFE)',
                Coverage_Type__c = 'Personal',
                Status__c = 'Assigned', Item_number__c = 4,
                Investigators_Notes__c = 'Reference completed'
            )
        };
        insert leads;

        DHSROIDesignerController.resetDefaultTemplates();
        saveDefaultTemplate('Header', 'Header');
        saveDefaultTemplate('Disclaimer', 'Disclaimer');
        saveDefaultTemplate('PAEI', 'PAEI');
        saveDefaultTemplate('Summary', 'Summary');
        saveDefaultTemplate('Report Table', 'Report Table');
        saveDefaultTemplate('Subject Interview (ESI/TESI)', 'Subject Interview');
        saveDefaultTemplate('Residence (RESI)', 'Personal');
        saveDefaultTemplate('General (GENL)', 'Record');
        saveDefaultTemplate('References (REFE)', 'Personal');
        String preview = DHSROIDesignerController.renderCasePreview(
            caseRecord.Id
        );

        System.assertNotEquals(null, preview, 'Assertion failed in DHSROIDesignerControllerTest at source line 651');
        System.assert(preview.contains('roi-preview-document'), 'Assertion failed in DHSROIDesignerControllerTest at source line 652');
        }
    }

    private static void saveDefaultTemplate(String leadType, String coverageType) {
        DHSROIDesignerController.saveConfig(
            DHSROIDesignerController.getConfig(leadType, coverageType),
            leadType,
            coverageType
        );
    }

    private static String buildComplexConfiguration() {
        List<Object> elements = new List<Object>{
            createElement(
                'section',
                'REPORT OF INVESTIGATION',
                'case',
                10
            ),
            createElement(
                'group',
                'Case details',
                'case',
                70
            ),
            createElement(
                'divider',
                '',
                'case',
                120
            ),
            createElement(
                'signature',
                'Investigator Signature',
                'case',
                150
            ),
            new Map<String, Object>{
                'type' => 'field',
                'scope' => 'case',
                'label' => 'Case Number',
                'fieldPath' =>
                    'DHS_Case__c.Case_Number__c',
                'page' => 1,
                'x' => 10,
                'y' => 220,
                'width' => 300,
                'height' => 40
            },
            new Map<String, Object>{
                'type' => 'text',
                'scope' => 'lead',
                'leadType' => 'General (GENL)',
                'coverageType' => 'Personal',
                'text' =>
                    'Notes: {{Lead Notes}}',
                'tokens' => new List<Object>{
                    new Map<String, Object>{
                        'label' => 'Lead Notes',
                        'fieldPath' =>
                            'DHS_Lead__c.Investigators_Notes__c'
                    }
                },
                'page' => 1,
                'x' => 10,
                'y' => 270,
                'width' => 500,
                'height' => 50
            },
            new Map<String, Object>{
                'type' => 'table',
                'scope' => 'case',
                'tableHeaderLabel' => 'Field',
                'tableHeaderValue' => 'Value',
                'tableRows' => new List<Object>{
                    new Map<String, Object>{
                        'label' => 'Case Number',
                        'fieldPath' =>
                            'DHS_Case__c.Case_Number__c'
                    }
                },
                'page' => 1,
                'x' => 10,
                'y' => 340,
                'width' => 500,
                'height' => 100
            },
            createElement(
                'spacer',
                '',
                'case',
                460
            ),
            createElement(
                'pageBreak',
                '',
                'case',
                500
            )
        };

        return JSON.serialize(
            new Map<String, Object>{
                'elements' => elements
            }
        );
    }

    private static Map<String, Object> createElement(
        String type,
        String text,
        String scope,
        Integer y
    ) {
        return new Map<String, Object>{
            'type' => type,
            'text' => text,
            'scope' => scope,
            'page' => 1,
            'x' => 10,
            'y' => y,
            'width' => 500,
            'height' => 40,
            'alignment' => 'left',
            'fontSize' => 14,
            'padding' => 6
        };
    }

    private static void assertSaveConfigFails(
        String config,
        String leadType,
        String coverageType
    ) {
        Boolean exceptionThrown = false;

        try {
            DHSROIDesignerController.saveConfig(
                config,
                leadType,
                coverageType
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Invalid configuration input should be rejected.'
        );
    }
}